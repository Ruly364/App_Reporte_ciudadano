import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import '../models/resultado_envio.dart';
import 'offline_service.dart';
import 'notification_service.dart';

class SyncService {
  //==============================================================
  // CONFIGURACIÓN
  //==============================================================

  static const Duration _timeoutEnvio =
  Duration(seconds: 30);

  static const Duration _esperaAntesDeSincronizar =
  Duration(seconds: 2);

  //==============================================================
  // ESTADO GLOBAL
  //==============================================================

  static bool _sincronizando = false;

  static StreamSubscription<ConnectivityResult>?
  _connectivitySubscription;

  static Timer? _autoSyncTimer;

  static bool _automaticoInicializado = false;

  //==============================================================
  // CONECTIVIDAD
  //==============================================================

  /// Comprueba si el dispositivo tiene algún tipo de conexión.
  ///
  /// IMPORTANTE:
  /// connectivity_plus solamente indica que existe una interfaz
  /// de red. No garantiza que Internet o la API estén disponibles.
  /// La petición HTTP sigue siendo la comprobación definitiva.
  static Future<bool> hayRedDisponible() async {
    try {
      final resultado =
      await Connectivity().checkConnectivity();

      return resultado != ConnectivityResult.none;
    } catch (e) {
      debugPrint(
        'Error comprobando conectividad: $e',
      );

      return false;
    }
  }



  //==============================================================
// INTENTAR SINCRONIZACIÓN AUTOMÁTICA
//==============================================================

  static Future<void> intentarSincronizacionAutomatica() async {
    if (_sincronizando) {
      return;
    }

    final hayConexion = await hayRedDisponible();

    if (!hayConexion) {
      return;
    }

    try {
      final enviados = await sincronizarPendientes();

      if (enviados > 0) {
        debugPrint(
          'Sincronización automática: '
              '$enviados reporte(s) enviado(s).',
        );
      }
    } catch (e) {
      debugPrint(
        'Error en sincronización automática: $e',
      );
    }
  }



// INICIALIZAR SINCRONIZACIÓN AUTOMÁTICA
//==============================================================

  /// Inicia el monitor de conectividad.
  ///
  /// Debe llamarse una sola vez, idealmente cuando la aplicación
  /// ya tiene disponible la sesión del usuario.
  static void inicializarSincronizacionAutomatica() {
    if (_automaticoInicializado) {
      return;
    }

    _automaticoInicializado = true;

    _connectivitySubscription =
        Connectivity()
            .onConnectivityChanged
            .listen(
              (resultado) {
            final hayConexion =
                resultado != ConnectivityResult.none;

            if (!hayConexion) {
              return;
            }

            _programarSincronizacionAutomatica();
          },
        );

    // También intentamos una sincronización inicial.
    _programarSincronizacionAutomatica();
  }

  //==============================================================
  // PROGRAMAR SINCRONIZACIÓN
  //==============================================================

  static void _programarSincronizacionAutomatica() {
    _autoSyncTimer?.cancel();

    _autoSyncTimer = Timer(
      _esperaAntesDeSincronizar,
          () async {
        try {
          await intentarSincronizacionAutomatica();
        } catch (e) {
          debugPrint(
            'Error en sincronización automática: $e',
          );
        }
      },
    );
  }

  //==============================================================
  // DETENER SINCRONIZACIÓN AUTOMÁTICA
  //==============================================================

  static Future<void> detenerSincronizacionAutomatica() async {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;

    await _connectivitySubscription?.cancel();

    _connectivitySubscription = null;

    _automaticoInicializado = false;
  }

  //==============================================================
  // SINCRONIZAR TODOS LOS PENDIENTES
  //==============================================================

  static Future<int> sincronizarPendientes() async {
    if (_sincronizando) {
      return 0;
    }

    if (!await hayRedDisponible()) {
      return 0;
    }

    _sincronizando = true;

    int enviados = 0;

    try {
      final pendientes =
      await OfflineService.obtenerPendientes();

      debugPrint(
        'Pendientes encontrados: ${pendientes.length}',
      );

      for (final reporte in pendientes) {
        // Si durante la cola perdimos completamente
        // la conectividad, detenemos el proceso.
        if (!await hayRedDisponible()) {
          debugPrint(
            'Conectividad perdida durante sincronización.',
          );

          break;
        }

        final resultado =
        await _enviarUnoInterno(reporte);

        if (resultado.enviado) {
          enviados++;

          if (resultado.folio != null &&
              resultado.folio!.isNotEmpty) {
            await NotificationService
                .mostrarReporteEnviado(
              resultado.folio,
            );
          }
        } else {
          // Si fue un problema de conectividad,
          // detenemos la cola. Los demás quedan pendientes.
          if (_esProblemaDeRed(resultado.mensaje)) {
            break;
          }
        }
      }

      return enviados;
    } finally {
      _sincronizando = false;
    }
  }

  //==============================================================
  // SINCRONIZAR UN REPORTE POR ID
  //==============================================================

  static Future<ResultadoEnvio> sincronizarReporte(
      int id,
      ) async {
    if (_sincronizando) {
      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'Ya existe una sincronización en proceso.',
      );
    }

    if (!await hayRedDisponible()) {
      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'No hay conexión o la señal es inestable. '
            'El reporte se guardó localmente y '
            'se enviará automáticamente cuando haya señal.',
      );
    }

    _sincronizando = true;

    try {
      final reporte =
      await OfflineService.obtenerReportePorId(id);

      if (reporte == null) {
        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'No se encontró el reporte pendiente.',
        );
      }

      return await _enviarUnoInterno(reporte);
    } finally {
      _sincronizando = false;
    }
  }

  //==============================================================
  // ENVÍO MANUAL DE UN REPORTE
  //==============================================================

  static Future<ResultadoEnvio> enviarUno(
      Map<String, dynamic> reporte,
      ) async {
    // IMPORTANTE:
    // Antes enviarUno() no activaba _sincronizando.
    // Eso permitía varios POST simultáneos al pulsar
    // repetidamente el botón.
    if (_sincronizando) {
      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'El reporte ya se está enviando. '
            'Espera un momento.',
      );
    }

    if (!await hayRedDisponible()) {
      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'No hay conexión o la señal es inestable. '
            'El reporte se guardó localmente y '
            'se enviará automáticamente cuando haya señal.',
      );
    }

    _sincronizando = true;

    try {
      return await _enviarUnoInterno(reporte);
    } finally {
      _sincronizando = false;
    }
  }

  //==============================================================
  // ENVÍO REAL
  //==============================================================

  static Future<ResultadoEnvio> _enviarUnoInterno(
      Map<String, dynamic> reporte,
      ) async {
    final id = reporte['id'] as int;

    try {
      //==========================================================
      // TOKEN
      //==========================================================

      final prefs =
      await SharedPreferences.getInstance();

      final token = prefs.getString('token');

      if (token == null || token.isEmpty) {
        await OfflineService.marcarPendiente(
          id,
          'No existe una sesión activa.',
        );

        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'La sesión ya no está disponible. '
              'Inicia sesión nuevamente para enviar el reporte.',
        );
      }

      //==========================================================
      // MARCAR COMO SINCRONIZANDO
      //==========================================================

      await OfflineService.marcarSincronizando(id);

      debugPrint(
        '===== INICIANDO ENVÍO DEL REPORTE =====',
      );

      debugPrint(
        'Reporte ID local: $id',
      );

      debugPrint(
        'ClienteUuid: ${reporte["uuid"]}',
      );

      //==========================================================
      // REQUEST
      //==========================================================

      final request = http.MultipartRequest(
        'POST',
        Uri.parse(
          '${ApiConfig.baseUrl}/reportes',
        ),
      );

      request.headers['Authorization'] =
      'Bearer $token';

      //==========================================================
      // CAMPOS
      //==========================================================

      request.fields['TipoPlaga'] =
          reporte['tipoPlaga']?.toString() ?? '';

      request.fields['Descripcion'] =
          reporte['descripcion']?.toString() ?? '';

      request.fields['Latitud'] =
          reporte['latitud']?.toString() ?? '';

      request.fields['Longitud'] =
          reporte['longitud']?.toString() ?? '';

      request.fields['EstadoUbicacion'] =
          reporte['estado']?.toString() ?? '';

      request.fields['Municipio'] =
          reporte['municipio']?.toString() ?? '';

      request.fields['Localidad'] =
          reporte['localidad']?.toString() ?? '';

      request.fields['CantidadArboles'] =
          reporte['cantidadArboles']?.toString() ?? '0';

      // Identificador único generado localmente.
      request.fields['ClienteUuid'] =
          reporte['uuid']?.toString() ?? '';

      //==========================================================
      // FOTOGRAFÍAS
      //==========================================================

      final List<String> imagenes =
      _obtenerImagenes(reporte);

      if (imagenes.isEmpty) {
        await OfflineService.marcarPendiente(
          id,
          'Reporte sin fotografías.',
        );

        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'El reporte no contiene fotografías.',
        );
      }

      debugPrint(
        'Fotografías encontradas: ${imagenes.length}',
      );

      int fotografiasAgregadas = 0;

      for (final ruta in imagenes) {
        final archivo = File(ruta);

        if (!await archivo.exists()) {
          debugPrint(
            'Fotografía no encontrada: $ruta',
          );

          continue;
        }

        request.files.add(
          await http.MultipartFile.fromPath(
            'Imagenes',
            ruta,
          ),
        );

        fotografiasAgregadas++;
      }

      if (fotografiasAgregadas == 0) {
        await OfflineService.marcarPendiente(
          id,
          'No se encontraron las fotografías locales.',
        );

        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'No se encontraron las fotografías '
              'guardadas en el dispositivo.',
        );
      }

      //==========================================================
      // ENVÍO
      //==========================================================

      debugPrint(
        'Enviando reporte al servidor...',
      );

      final response = await request
          .send()
          .timeout(_timeoutEnvio);

      final body =
      await response.stream.bytesToString();

      debugPrint(
        'Código HTTP: ${response.statusCode}',
      );

      debugPrint(
        'Respuesta API: $body',
      );

      //==========================================================
      // ÉXITO
      //==========================================================

      if (response.statusCode == 200 ||
          response.statusCode == 201) {
        Map<String, dynamic>? respuesta;

        try {
          final decoded = jsonDecode(body);

          if (decoded is Map<String, dynamic>) {
            respuesta = decoded;
          }
        } catch (_) {
          respuesta = null;
        }

        final folio =
        respuesta?['folio']?.toString();

        //========================================================
        // MARCAR ENVIADO
        //========================================================

        await OfflineService.marcarEnviado(
          id,
          folio: folio,
        );

        //========================================================
        // ELIMINAR FOTOGRAFÍAS LOCALES
        // SOLO DESPUÉS DEL ÉXITO
        //========================================================

        for (final ruta in imagenes) {
          final archivo = File(ruta);

          if (await archivo.exists()) {
            try {
              await archivo.delete();
            } catch (e) {
              debugPrint(
                'No se pudo eliminar imagen local: $e',
              );
            }
          }
        }

        return ResultadoEnvio(
          enviado: true,
          folio: folio,
          mensaje:
          respuesta?['mensaje']?.toString() ??
              (folio != null && folio.isNotEmpty
                  ? 'Reporte enviado correctamente. '
                  'Folio: $folio'
                  : 'Reporte enviado correctamente.'),
        );
      }

      //==========================================================
      // ERROR HTTP
      //==========================================================

      await OfflineService.marcarPendiente(
        id,
        'HTTP ${response.statusCode}',
      );

      // Errores 5xx: normalmente son temporales.
      if (response.statusCode >= 500) {
        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'El servidor no está disponible en este momento. '
              'El reporte permanece guardado y '
              'se volverá a enviar automáticamente.',
        );
      }

      // Error de autenticación.
      if (response.statusCode == 401) {
        return const ResultadoEnvio(
          enviado: false,
          mensaje:
          'La sesión ya no es válida. '
              'Inicia sesión nuevamente para enviar el reporte.',
        );
      }

      // Error de validación.
      return ResultadoEnvio(
        enviado: false,
        mensaje:
        'El servidor rechazó el reporte '
            '(${response.statusCode}). '
            'El reporte permanece guardado.',
      );
    }

    //============================================================
    // TIMEOUT
    //============================================================

    on TimeoutException {
      await _marcarPendienteSeguro(
        id,
        'Tiempo de espera agotado.',
      );

      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'La conexión es demasiado lenta o inestable. '
            'El reporte se guardó localmente y '
            'se enviará automáticamente cuando haya señal.',
      );
    }

    //============================================================
    // SOCKET EXCEPTION
    //============================================================

    on SocketException {
      await _marcarPendienteSeguro(
        id,
        'Conexión interrumpida.',
      );

      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'No hay conexión o la señal es inestable. '
            'El reporte se guardó localmente y '
            'se enviará automáticamente cuando haya señal.',
      );
    }

    //============================================================
    // HTTP CLIENT EXCEPTION
    //============================================================

    on http.ClientException {
      await _marcarPendienteSeguro(
        id,
        'No fue posible establecer comunicación con el servidor.',
      );

      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'No hay conexión o la señal es inestable. '
            'El reporte se guardó localmente y '
            'se enviará automáticamente cuando haya señal.',
      );
    }

    //============================================================
    // OTROS ERRORES
    //============================================================

    catch (e, stack) {
      debugPrint(
        '========== ERROR DE SINCRONIZACIÓN ==========',
      );

      debugPrint(
        'Reporte ID: $id',
      );

      debugPrint(
        'Tipo: ${e.runtimeType}',
      );

      debugPrint(
        'Mensaje: $e',
      );

      debugPrint(
        stack.toString(),
      );

      debugPrint(
        '=============================================',
      );

      await _marcarPendienteSeguro(
        id,
        'Error inesperado durante la sincronización.',
      );

      return const ResultadoEnvio(
        enviado: false,
        mensaje:
        'No fue posible enviar el reporte en este momento. '
            'El reporte permanece guardado localmente y '
            'se intentará nuevamente cuando haya conexión.',
      );
    }
  }

  //==============================================================
  // OBTENER IMÁGENES
  //==============================================================

  static List<String> _obtenerImagenes(
      Map<String, dynamic> reporte,
      ) {
    final valor = reporte['imagenes'];

    if (valor == null) {
      return [];
    }

    if (valor is List) {
      return valor
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    if (valor is String) {
      try {
        final decoded = jsonDecode(valor);

        if (decoded is List) {
          return decoded
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList();
        }
      } catch (_) {}

      return [];
    }

    return [];
  }

  //==============================================================
  // MARCAR PENDIENTE DE FORMA SEGURA
  //==============================================================

  static Future<void> _marcarPendienteSeguro(
      int id,
      String motivo,
      ) async {
    try {
      await OfflineService.marcarPendiente(
        id,
        motivo,
      );
    } catch (e) {
      debugPrint(
        'No se pudo marcar reporte como pendiente: $e',
      );
    }
  }

  //==============================================================
  // IDENTIFICAR ERROR DE RED
  //==============================================================

  static bool _esProblemaDeRed(
      String mensaje,
      ) {
    final texto = mensaje.toLowerCase();

    return texto.contains('conexión') ||
        texto.contains('conexion') ||
        texto.contains('señal') ||
        texto.contains('red') ||
        texto.contains('internet') ||
        texto.contains('tiempo de espera') ||
        texto.contains('servidor no está disponible');
  }
}