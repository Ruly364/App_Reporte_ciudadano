import 'package:sqflite/sqflite.dart';

import 'local_db.dart';

class GeografiaService {

  //---------------------------------------------------------
  // Estados
  //---------------------------------------------------------

  static Future<List<String>> obtenerEstados() async {

    final db = await LocalDB.database;

    final resultado = await db.query(
      'estados',
      orderBy: 'nombre',
    );

    return resultado
        .map((e) => e["nombre"] as String)
        .toList();
  }

  //---------------------------------------------------------
  // Municipios
  //---------------------------------------------------------

  static Future<List<String>> obtenerMunicipios(
      String estado) async {

    final db = await LocalDB.database;

    final resultado = await db.query(
      'municipios',
      where: 'estado = ?',
      whereArgs: [estado],
      orderBy: 'nombre',
    );

    return resultado
        .map((e) => e["nombre"] as String)
        .toList();
  }

  //---------------------------------------------------------
  // Localidades
  //---------------------------------------------------------

  static Future<List<String>> obtenerLocalidades(
      String estado,
      String municipio) async {

    final db = await LocalDB.database;

    final resultado = await db.query(
      'localidades',
      where: 'estado = ? AND municipio = ?',
      whereArgs: [
        estado,
        municipio,
      ],
      orderBy: 'nombre',
    );

    final lista = resultado
        .map((e) => e["nombre"] as String)
        .toList();

    return [

      "Ninguno",

      ...lista,

    ];
  }

  //---------------------------------------------------------
  // Insertar Estado
  //---------------------------------------------------------

  static Future<void> insertarEstado(
      String nombre) async {

    final db = await LocalDB.database;

    await db.insert(

      "estados",

      {

        "nombre": nombre,

      },

      conflictAlgorithm:
      ConflictAlgorithm.ignore,

    );

  }

  //---------------------------------------------------------
  // Insertar Municipio
  //---------------------------------------------------------

  static Future<void> insertarMunicipio({

    required String estado,

    required String nombre,

  }) async {

    final db = await LocalDB.database;

    await db.insert(

      "municipios",

      {

        "estado": estado,

        "nombre": nombre,

      },

      conflictAlgorithm:
      ConflictAlgorithm.ignore,

    );

  }

  //---------------------------------------------------------
  // Insertar Localidad
  //---------------------------------------------------------

  static Future<void> insertarLocalidad({

    required String estado,

    required String municipio,

    required String nombre,

  }) async {

    final db = await LocalDB.database;

    await db.insert(

      "localidades",

      {

        "estado": estado,

        "municipio": municipio,

        "nombre": nombre,

      },

      conflictAlgorithm:
      ConflictAlgorithm.ignore,

    );

  }

  //---------------------------------------------------------
  // Vaciar catálogo
  //---------------------------------------------------------

  static Future<void> limpiarCatalogo() async {

    final db = await LocalDB.database;

    await db.delete("estados");

    await db.delete("municipios");

    await db.delete("localidades");

  }

  //---------------------------------------------------------

  static Future<int> totalEstados() async {

    final db = await LocalDB.database;

    final r = await db.rawQuery(
        'SELECT COUNT(*) total FROM estados');

    return Sqflite.firstIntValue(r) ?? 0;

  }

//---------------------------------------------------------

  static Future<int> totalMunicipios() async {

    final db = await LocalDB.database;

    final r = await db.rawQuery(
        'SELECT COUNT(*) total FROM municipios');

    return Sqflite.firstIntValue(r) ?? 0;

  }

//---------------------------------------------------------

  static Future<int> totalLocalidades() async {

    final db = await LocalDB.database;

    final r = await db.rawQuery(
        'SELECT COUNT(*) total FROM localidades');

    return Sqflite.firstIntValue(r) ?? 0;

  }


}