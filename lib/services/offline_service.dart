import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'local_db.dart';
import 'background_sync_scheduler.dart';

class OfflineService {

  static const _uuid = Uuid();

  static Future<int> guardarReporte(

      Map<String, dynamic> data) async {

    final db = await LocalDB.database;

    final id = await db.insert(
      'reportes',
      {
        'uuid': _uuid.v4(),

        'tipoPlaga':
        data['tipoPlaga']?.toString() ?? '',

        'descripcion':
        data['descripcion']?.toString() ?? '',

        'latitud':
        (data['latitud'] as num?)?.toDouble() ?? 0,

        'longitud':
        (data['longitud'] as num?)?.toDouble() ?? 0,

        'estado':
        data['estado']?.toString() ?? '',

        'municipio':
        data['municipio']?.toString() ?? '',

        'localidad':
        data['localidad']?.toString() ?? '',

        'cantidadArboles':
        (data['cantidadArboles'] as num?)?.toInt() ?? 0,

        'imagenes':
        data['imagenes'] is String
            ? data['imagenes']
            : jsonEncode(data['imagenes'] ?? []),

        'fecha':
        data['fecha']?.toString() ??
            DateTime.now().toIso8601String(),

        'status': 'pendiente',

        'fechaSincronizacion': null,

        'intentos': 0,

        'ultimoError': null,

        'sincronizando': 0,

        'folio': null,

        'proximoIntento': null,
      },

      conflictAlgorithm:
      ConflictAlgorithm.replace,
    );

//==============================================================
// PROGRAMAR SINCRONIZACIÓN EN BACKGROUND
//==============================================================
//
// Android conservará esta tarea aunque la aplicación se cierre.
// WorkManager esperará hasta que exista una conexión de red.
//
//==============================================================

    await BackgroundSyncScheduler.programar();

    return id;
  }

  static Future<Map<String, dynamic>?> obtenerReportePorId(int id) async {

    final db = await LocalDB.database;

    final resultado = await db.query(
      'reportes',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (resultado.isEmpty) {
      return null;
    }

    return resultado.first;
  }

  static Future<List<Map<String, dynamic>>>
  obtenerPendientes() async {

    final db = await LocalDB.database;

    return db.query(

      'reportes',

      where:
      '''status = ? AND sincronizando = 0
         AND (proximoIntento IS NULL OR proximoIntento <= ?)''',

      whereArgs: ['pendiente', DateTime.now().toIso8601String()],

      orderBy: 'fecha ASC',
    );
  }

  static Future<void> marcarSincronizando(
      int id) async {

    final db = await LocalDB.database;

    await db.update(

      'reportes',

      {

        'sincronizando': 1,

      },

      where: 'id=?',

      whereArgs: [id],
    );
  }

  static Future<void> marcarPendiente(
      int id,
      String error,
      ) async {

    final db = await LocalDB.database;

    final actual = await db.query(
      'reportes',
      columns: ['intentos'],
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    final intentosActuales = (actual.firstOrNull?['intentos'] as int?) ?? 0;
    final nuevosIntentos = intentosActuales + 1;
    // 1, 2, 4, 8... minutos; máximo una hora. Evita ciclos de reintento
    // cuando la cobertura aparece y desaparece.
    final minutos = 1 << (nuevosIntentos - 1).clamp(0, 6).toInt();

    await db.update(
      'reportes',
      {
        'status': 'pendiente',
        'sincronizando': 0,
        'intentos': nuevosIntentos,
        'ultimoError': error,
        'proximoIntento': DateTime.now()
            .add(Duration(minutes: minutos))
            .toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  static Future<void> marcarEnviado(
      int id, {String? folio}) async {

    final db = await LocalDB.database;

    await db.update(

      'reportes',

      {

        'status': 'enviado',

        'sincronizando': 0,

        'fechaSincronizacion':
        DateTime.now().toIso8601String(),

        'ultimoError': null,

        'folio': folio,

        'proximoIntento': null,

      },

      where: 'id=?',

      whereArgs: [id],
    );
  }

  static Future<List<Map<String, dynamic>>>
  obtenerTodos() async {

    final db = await LocalDB.database;

    return db.query(

      'reportes',

      orderBy: 'fecha DESC',
    );
  }

  static Future<void> eliminarReporte(
      int id) async {

    final db = await LocalDB.database;

    await db.delete(

      'reportes',

      where: 'id=?',

      whereArgs: [id],
    );
  }

  static Future<int> pendientes() async {

    final db = await LocalDB.database;

    final r = Sqflite.firstIntValue(

      await db.rawQuery(

          'SELECT COUNT(*) FROM reportes WHERE status="pendiente"'),
    );

    return r ?? 0;
  }

  static Future<int> enviados() async {

    final db = await LocalDB.database;

    final r = Sqflite.firstIntValue(

      await db.rawQuery(

          'SELECT COUNT(*) FROM reportes WHERE status="enviado"'),
    );

    return r ?? 0;
  }

  /// Libera registros que quedaron marcados como sincronizando si Android
  /// cerró el proceso durante un envío. Se ejecuta sólo al iniciar la app.
  static Future<void> liberarSincronizacionesInterrumpidas() async {
    final db = await LocalDB.database;
    await db.update(
      'reportes',
      {'sincronizando': 0},
      where: 'status = ? AND sincronizando = 1',
      whereArgs: ['pendiente'],
    );
  }

  static Future<void> limpiarEnviados() async {

    final db = await LocalDB.database;

    await db.delete(

      'reportes',

      where: 'status=?',

      whereArgs: ['enviado'],
    );
  }

  static Future<void> guardarCatalogo(
      List<dynamic> catalogo) async {

    final db = await LocalDB.database;

    final batch = db.batch();

    batch.delete("catalogo_plagas");

    for (final item in catalogo) {

      batch.insert(

        "catalogo_plagas",

        {

          "id": item.id,

          "nombre": item.nombre,

        },
        conflictAlgorithm: ConflictAlgorithm.replace,

      );

    }

    await batch.commit(noResult: true);

    await guardarConfiguracion(

      "catalogo_plagas_fecha",

      DateTime.now().toIso8601String(),

    );



  }

  static Future<bool> necesitaActualizarCatalogo() async {

    final fecha =
    await obtenerConfiguracion(
        "catalogo_plagas_fecha");

    if (fecha == null) {

      return true;

    }

    final ultima =
    DateTime.tryParse(fecha);

    if (ultima == null) {

      return true;

    }

    final ahora = DateTime.now();

    return ahora.difference(ultima).inHours >= 24;

  }


  /// Obtiene el catálogo almacenado localmente
  static Future<List<Map<String,dynamic>>>
  obtenerCatalogo() async {

    final db = await LocalDB.database;

    return await db.query(

      "catalogo_plagas",

      orderBy: "nombre",

    );

  }

  static Future<bool> existeCatalogo() async {

    final db = await LocalDB.database;

    final cantidad = Sqflite.firstIntValue(

      await db.rawQuery(

        'SELECT COUNT(*) FROM catalogo_plagas',

      ),

    );

    return (cantidad ?? 0) > 0;

  }

  static Future<void> limpiarCatalogo() async {

    final db = await LocalDB.database;

    await db.delete('catalogo_plagas');

  }

  static Future<void> guardarConfiguracion(
      String clave,
      String valor) async {

    final db = await LocalDB.database;

    await db.insert(

      'configuracion',

      {

        'clave': clave,

        'valor': valor,

      },

      conflictAlgorithm: ConflictAlgorithm.replace,

    );

  }

  static Future<String?> obtenerConfiguracion(
      String clave) async {

    final db = await LocalDB.database;

    final resultado = await db.query(

      'configuracion',

      where: 'clave=?',

      whereArgs: [clave],

      limit: 1,

    );

    if (resultado.isEmpty) {

      return null;

    }

    return resultado.first["valor"] as String?;

  }




}
