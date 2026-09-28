import 'dart:io';
import 'dart:math' as math;

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class UbicacionCatalogo {
  const UbicacionCatalogo({
    required this.estado,
    required this.municipio,
    required this.localidad,
    required this.distanciaMetros,
    required this.confianza,
  });

  final String estado;
  final String municipio;
  final String localidad;
  final double distanciaMetros;
  final String confianza;
}

/// Acceso de sólo lectura al catálogo INEGI incluido con la aplicación.
///
/// La base se mantiene separada de reportes.db para poder actualizarla
/// de forma segura e independiente.
///
/// IMPORTANTE:
/// - La primera instalación/actualización valida el SHA-256 completo.
/// - Una vez validado, se guarda una marca local.
/// - En las siguientes aperturas NO se vuelve a calcular el SHA-256
///   de los ~94 MB, salvo que cambie la versión/hash o falte la marca.
class CatalogoMaestroService {
  CatalogoMaestroService._();

  static const _assetDb =
      'assets/catalogo/catalogo_maestro.db';

  static const _assetSha =
      'assets/catalogo/catalogo_maestro.db.sha256';

  static const _archivoLocal =
      'catalogo_maestro_v2.1.0.db';

  static const _tamanoEsperado =
  94253056;

  static const _gridSize =
  0.05;

  static Database? _db;

  static Future<Database>? _abriendo;

  /// Cacheamos el SHA esperado durante la ejecución actual.
  static String? _shaEsperadoCache;

  //==============================================================
  // DATABASE
  //==============================================================

  static Future<Database> get database {
    if (_db != null) {
      return Future.value(_db!);
    }

    return _abriendo ??=
        _abrir().catchError(
              (Object error, StackTrace stack) {
            _abriendo = null;
            Error.throwWithStackTrace(
              error,
              stack,
            );
          },
        );
  }

  //==============================================================
  // ABRIR CATÁLOGO
  //==============================================================

  static Future<Database> _abrir() async {
    final soporte =
    await getApplicationSupportDirectory();

    final archivo = File(
      join(
        soporte.path,
        _archivoLocal,
      ),
    );

    final archivoMarca = File(
      join(
        soporte.path,
        '$_archivoLocal.validado',
      ),
    );

    final shaEsperado =
    await _obtenerShaEsperado();

    //----------------------------------------------------------------
    // Verificamos que el catálogo exista y tenga el tamaño esperado.
    //
    // Esta comprobación es muy barata comparada con calcular SHA-256
    // de los ~94 MB.
    //----------------------------------------------------------------

    final archivoExiste =
    await archivo.exists();

    final tamanoCorrecto =
        archivoExiste &&
            await archivo.length() ==
                _tamanoEsperado;

    //----------------------------------------------------------------
    // Si existe la marca de validación y coincide con el SHA esperado,
    // NO volvemos a leer los 94 MB.
    //----------------------------------------------------------------

    bool catalogoValido = false;

    if (tamanoCorrecto &&
        await archivoMarca.exists()) {
      try {
        final shaMarcado =
        (await archivoMarca.readAsString())
            .trim()
            .toLowerCase();

        catalogoValido =
            shaMarcado ==
                shaEsperado.toLowerCase();
      } catch (_) {
        catalogoValido = false;
      }
    }

    //----------------------------------------------------------------
    // Si no existe una marca válida:
    //
    // 1. Si ya existe el archivo, hacemos UNA validación SHA.
    // 2. Si no es válido, copiamos el catálogo desde assets.
    //----------------------------------------------------------------

    if (!catalogoValido) {
      bool archivoValido = false;

      //----------------------------------------------------------------
      // Intentamos validar el archivo existente.
      //
      // Esto solamente ocurrirá:
      // - la primera vez después de instalar esta versión;
      // - si desapareció la marca;
      // - si cambió la versión/hash;
      // - si el archivo cambió de tamaño.
      //----------------------------------------------------------------

      if (tamanoCorrecto) {
        archivoValido =
        await _esValido(
          archivo,
          shaEsperado,
        );
      }

      //----------------------------------------------------------------
      // Si el archivo existente es válido, solamente reconstruimos
      // la marca. No necesitamos volver a copiar los 94 MB.
      //----------------------------------------------------------------

      if (archivoValido) {
        await archivoMarca.writeAsString(
          shaEsperado,
          flush: true,
        );

        catalogoValido = true;
      }

      //----------------------------------------------------------------
      // Si no existe o está corrupto/incompleto, instalamos nuevamente.
      //----------------------------------------------------------------

      if (!catalogoValido) {
        final datos =
        await rootBundle.load(_assetDb);

        final bytes =
        datos.buffer.asUint8List(
          datos.offsetInBytes,
          datos.lengthInBytes,
        );

        final temporal =
        File('${archivo.path}.tmp');

        try {
          //----------------------------------------------------------------
          // Eliminamos una marca anterior porque todavía no tenemos
          // un catálogo validado.
          //----------------------------------------------------------------

          if (await archivoMarca.exists()) {
            await archivoMarca.delete();
          }

          //----------------------------------------------------------------
          // Escribimos primero en archivo temporal.
          //----------------------------------------------------------------

          await temporal.writeAsBytes(
            bytes,
            flush: true,
          );

          //----------------------------------------------------------------
          // Validamos el archivo temporal antes de reemplazar el
          // catálogo que ya pudiera existir.
          //----------------------------------------------------------------

          if (!await _esValido(
            temporal,
            shaEsperado,
          )) {
            throw StateError(
              'El catálogo maestro no superó '
                  'la validación SHA-256.',
            );
          }

          //----------------------------------------------------------------
          // Reemplazo seguro.
          //----------------------------------------------------------------

          if (await archivo.exists()) {
            await archivo.delete();
          }

          await temporal.rename(
            archivo.path,
          );

          //----------------------------------------------------------------
          // La validación ya terminó correctamente.
          // Guardamos la marca para que NO tengamos que volver a
          // calcular SHA-256 en las siguientes aperturas.
          //----------------------------------------------------------------

          await archivoMarca.writeAsString(
            shaEsperado,
            flush: true,
          );

          catalogoValido = true;
        } catch (_) {
          if (await temporal.exists()) {
            await temporal.delete();
          }

          rethrow;
        }
      }
    }

    //----------------------------------------------------------------
    // Seguridad final.
    //----------------------------------------------------------------

    if (!catalogoValido) {
      throw StateError(
        'No fue posible validar el catálogo maestro.',
      );
    }

    //----------------------------------------------------------------
    // Abrimos SQLite solamente después de tener el archivo validado.
    //----------------------------------------------------------------

    _db = await openDatabase(
      archivo.path,
      readOnly: true,
      singleInstance: true,
      onOpen: (db) =>
          db.execute(
            'PRAGMA query_only = ON',
          ),
    );

    return _db!;
  }

  //==============================================================
  // SHA ESPERADO
  //==============================================================

  static Future<String> _obtenerShaEsperado() async {
    if (_shaEsperadoCache != null) {
      return _shaEsperadoCache!;
    }

    _shaEsperadoCache =
        (await rootBundle.loadString(
          _assetSha,
        )).trim();

    return _shaEsperadoCache!;
  }

  //==============================================================
  // VALIDAR ARCHIVO
  //==============================================================

  static Future<bool> _esValido(
      File archivo,
      String shaEsperado,
      ) async {
    if (!await archivo.exists()) {
      return false;
    }

    final tamano =
    await archivo.length();

    if (tamano != _tamanoEsperado) {
      return false;
    }

    final digest =
    await sha256
        .bind(archivo.openRead())
        .first;

    return digest
        .toString()
        .toLowerCase() ==
        shaEsperado
            .toLowerCase();
  }

  //==============================================================
  // ESTADOS
  //==============================================================

  static Future<List<String>> obtenerEstados() async {
    final db = await database;

    final filas =
    await db.rawQuery('''
      SELECT Nombre
      FROM Estados

      UNION

      SELECT NombreEstado AS Nombre
      FROM LocalidadesEspeciales

      ORDER BY Nombre
    ''');

    return filas
        .map(
          (fila) =>
      fila['Nombre'] as String,
    )
        .toList();
  }

  //==============================================================
  // MUNICIPIOS
  //==============================================================

  static Future<List<String>> obtenerMunicipios(
      String estado,
      ) async {
    final db = await database;

    final filas =
    await db.rawQuery(
      '''
      SELECT m.Nombre
      FROM Municipios m
      INNER JOIN Estados e
        ON e.Id = m.EstadoId
      WHERE e.Nombre = ?

      UNION

      SELECT NombreMunicipio AS Nombre
      FROM LocalidadesEspeciales
      WHERE NombreEstado = ?

      ORDER BY Nombre
      ''',
      [
        estado,
        estado,
      ],
    );

    return filas
        .map(
          (fila) =>
      fila['Nombre'] as String,
    )
        .toList();
  }

  //==============================================================
  // LOCALIDADES
  //==============================================================

  static Future<List<String>> obtenerLocalidades(
      String estado,
      String municipio,
      ) async {
    final db = await database;

    final filas =
    await db.rawQuery(
      '''
      SELECT l.Nombre
      FROM Localidades l
      INNER JOIN Municipios m
        ON m.Id = l.MunicipioId
      INNER JOIN Estados e
        ON e.Id = m.EstadoId
      WHERE e.Nombre = ?
        AND m.Nombre = ?

      UNION

      SELECT NombreLocalidad AS Nombre
      FROM LocalidadesEspeciales
      WHERE NombreEstado = ?
        AND NombreMunicipio = ?

      ORDER BY Nombre
      ''',
      [
        estado,
        municipio,
        estado,
        municipio,
      ],
    );

    return filas
        .map(
          (fila) =>
      fila['Nombre'] as String,
    )
        .where(
          (nombre) =>
      nombre.trim().isNotEmpty,
    )
        .toList();
  }

  //==============================================================
  // RESOLVER COORDENADAS
  //==============================================================

  /// Encuentra la localidad INEGI más cercana dentro de 25 km.
  ///
  /// La confianza expresa cercanía a una localidad,
  /// no una validación de polígono estatal.
  static Future<UbicacionCatalogo?>
  resolverCoordenadas({
    required double latitud,
    required double longitud,
  }) async {
    final db = await database;

    final gridX =
    (latitud / _gridSize).floor();

    final gridY =
    (longitud / _gridSize).floor();

    const radioCeldas = 5;

    final filas =
    await db.rawQuery(
      '''
      SELECT
        e.Nombre AS estado,
        m.Nombre AS municipio,
        l.Nombre AS localidad,
        l.Latitud AS latitud,
        l.Longitud AS longitud
      FROM Localidades l
      INNER JOIN Municipios m
        ON m.Id = l.MunicipioId
      INNER JOIN Estados e
        ON e.Id = m.EstadoId
      WHERE l.GridX BETWEEN ? AND ?
        AND l.GridY BETWEEN ? AND ?
        AND l.Latitud IS NOT NULL
        AND l.Longitud IS NOT NULL

      UNION ALL

      SELECT
        s.NombreEstado AS estado,
        s.NombreMunicipio AS municipio,
        s.NombreLocalidad AS localidad,
        s.Latitud AS latitud,
        s.Longitud AS longitud
      FROM LocalidadesEspeciales s
      WHERE s.GridX BETWEEN ? AND ?
        AND s.GridY BETWEEN ? AND ?
        AND s.Latitud IS NOT NULL
        AND s.Longitud IS NOT NULL
      ''',
      [
        gridX - radioCeldas,
        gridX + radioCeldas,
        gridY - radioCeldas,
        gridY + radioCeldas,

        gridX - radioCeldas,
        gridX + radioCeldas,
        gridY - radioCeldas,
        gridY + radioCeldas,
      ],
    );

    Map<String, dynamic>? mejor;

    var distanciaMenor =
        double.infinity;

    for (final fila in filas) {
      final distancia =
      _distanciaMetros(
        latitud,
        longitud,
        (fila['latitud'] as num)
            .toDouble(),
        (fila['longitud'] as num)
            .toDouble(),
      );

      if (distancia < distanciaMenor) {
        distanciaMenor = distancia;
        mejor = fila;
      }
    }

    if (mejor == null ||
        distanciaMenor > 25000) {
      return null;
    }

    return UbicacionCatalogo(
      estado:
      mejor['estado'] as String,
      municipio:
      mejor['municipio'] as String,
      localidad:
      mejor['localidad'] as String,
      distanciaMetros:
      distanciaMenor,
      confianza:
      distanciaMenor <= 2000
          ? 'alta'
          : distanciaMenor <= 10000
          ? 'media'
          : 'baja',
    );
  }

  //==============================================================
  // DISTANCIA GPS
  //==============================================================

  static double _distanciaMetros(
      double latitudA,
      double longitudA,
      double latitudB,
      double longitudB,
      ) {
    const radioTierra =
    6371000.0;

    final dLat =
    _radianes(
      latitudB - latitudA,
    );

    final dLon =
    _radianes(
      longitudB - longitudA,
    );

    final a =
        _sinCuadrado(
          dLat / 2,
        ) +
            _cos(
              _radianes(
                latitudA,
              ),
            ) *
                _cos(
                  _radianes(
                    latitudB,
                  ),
                ) *
                _sinCuadrado(
                  dLon / 2,
                );

    return radioTierra *
        2 *
        _atan2Sqrt(a);
  }

  //==============================================================
  // FUNCIONES MATEMÁTICAS
  //==============================================================

  static double _radianes(
      double grados,
      ) =>
      grados *
          0.017453292519943295;

  static double _sinCuadrado(
      double valor,
      ) {
    final seno =
    _sin(valor);

    return seno * seno;
  }

  static double _sin(
      double valor,
      ) =>
      math.sin(valor);

  static double _cos(
      double valor,
      ) =>
      math.cos(valor);

  static double _atan2Sqrt(
      double a,
      ) =>
      math.atan2(
        math.sqrt(a),
        math.sqrt(1 - a),
      );
}