import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'offline_service.dart';
import 'sync_service.dart';

/// ===============================================================
/// SYNC COORDINATOR
/// ===============================================================
///
/// Único coordinador de sincronización automática de la aplicación.
///
/// Responsabilidades:
///
/// 1. Escuchar cambios de conectividad.
/// 2. Esperar a que la conexión se estabilice.
/// 3. Sincronizar pendientes al iniciar la aplicación.
/// 4. Volver a intentar cuando la aplicación regresa al primer plano.
/// 5. Evitar múltiples sincronizaciones simultáneas.
/// 6. No realizar polling agresivo de la red.
///
/// ===============================================================

class SyncCoordinator with WidgetsBindingObserver {
  //==============================================================
  // SINGLETON
  //==============================================================

  static final SyncCoordinator _instance =
  SyncCoordinator._internal();

  factory SyncCoordinator() => _instance;

  SyncCoordinator._internal();

  //==============================================================
  // CONECTIVIDAD
  //==============================================================

  StreamSubscription<ConnectivityResult>? _subscription;

  //==============================================================
  // DEBOUNCE
  //==============================================================

  Timer? _debounce;

  //==============================================================
  // ESTADO
  //==============================================================

  bool _iniciado = false;

  bool _sincronizando = false;

  //==============================================================
  // INICIAR
  //==============================================================

  static Future<void> iniciar() async {
    await _instance._iniciar();
  }

  Future<void> _iniciar() async {
    if (_iniciado) {
      return;
    }

    _iniciado = true;

    //============================================================
    // OBSERVAR CICLO DE VIDA DE LA APP
    //============================================================

    WidgetsBinding.instance.addObserver(this);

    //============================================================
    // LIBERAR SINCRONIZACIONES INTERRUMPIDAS
    //============================================================

    await OfflineService
        .liberarSincronizacionesInterrumpidas();

    //============================================================
    // ESCUCHAR CAMBIOS DE CONECTIVIDAD
    //============================================================

    _subscription =
        Connectivity()
            .onConnectivityChanged
            .listen(
              (resultado) {
            // Sin conexión.
            if (resultado == ConnectivityResult.none) {
              return;
            }

            debugPrint(
              'SyncCoordinator: conectividad detectada.',
            );

            _programarSincronizacion();
          },
        );

    //============================================================
    // SINCRONIZACIÓN INICIAL
    //============================================================
    //
    // Esto permite que:
    //
    // App cerrada
    //    ↓
    // había reportes pendientes
    //    ↓
    // usuario abre la app
    //    ↓
    // se intenta sincronizar automáticamente
    //
    //============================================================

    _programarSincronizacion();
  }

  //==============================================================
  // CICLO DE VIDA
  //==============================================================

  @override
  void didChangeAppLifecycleState(
      AppLifecycleState state,
      ) {
    if (!_iniciado) {
      return;
    }

    //============================================================
    // APP REGRESA AL PRIMER PLANO
    //============================================================
    //
    // Este caso es muy importante.
    //
    // Si el usuario:
    //
    // - pierde Internet
    // - deja la app en segundo plano
    // - recupera Internet
    // - vuelve a la aplicación
    //
    // aquí volvemos a comprobar la cola.
    //
    // También cubre el caso en que el teléfono continúa
    // conectado al mismo Wi-Fi y connectivity_plus no generó
    // un nuevo evento.
    //
    //============================================================

    if (state == AppLifecycleState.resumed) {
      debugPrint(
        'SyncCoordinator: aplicación reanudada.',
      );

      _programarSincronizacion();
    }
  }

  //==============================================================
  // PROGRAMAR SINCRONIZACIÓN
  //==============================================================

  void _programarSincronizacion() {
    // Cancelamos cualquier intento programado anteriormente.
    //
    // Esto evita que varios eventos de conectividad generen
    // múltiples procesos de sincronización.
    _debounce?.cancel();

    _debounce = Timer(
      const Duration(seconds: 3),
          () async {
        await _ejecutarSincronizacion();
      },
    );
  }

  //==============================================================
  // EJECUTAR SINCRONIZACIÓN
  //==============================================================

  Future<void> _ejecutarSincronizacion() async {
    // Protección adicional.
    if (_sincronizando) {
      debugPrint(
        'SyncCoordinator: ya existe una sincronización activa.',
      );

      return;
    }

    _sincronizando = true;

    try {
      debugPrint(
        'SyncCoordinator: iniciando sincronización automática...',
      );

      final enviados =
      await SyncService.sincronizarPendientes();

      if (enviados > 0) {
        debugPrint(
          'SyncCoordinator: $enviados reporte(s) sincronizado(s).',
        );
      } else {
        debugPrint(
          'SyncCoordinator: no hubo reportes enviados.',
        );
      }
    } catch (error, stack) {
      //==========================================================
      // IMPORTANTE
      //==========================================================
      //
      // Un error de red NO debe romper la aplicación.
      //
      // Los reportes permanecen en la cola local y se volverán
      // a intentar cuando exista una nueva oportunidad.
      //
      //==========================================================

      debugPrint(
        'SyncCoordinator: no fue posible sincronizar la cola.',
      );

      debugPrint(
        'Error: $error',
      );

      debugPrintStack(
        stackTrace: stack,
      );
    } finally {
      _sincronizando = false;
    }
  }

  //==============================================================
  // CERRAR
  //==============================================================

  static Future<void> cerrar() async {
    await _instance._cerrar();
  }

  Future<void> _cerrar() async {
    _debounce?.cancel();

    _debounce = null;

    await _subscription?.cancel();

    _subscription = null;

    WidgetsBinding.instance.removeObserver(this);

    _iniciado = false;

    _sincronizando = false;
  }
}