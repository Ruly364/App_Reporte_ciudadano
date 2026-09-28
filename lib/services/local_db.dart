import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

class LocalDB {
  static Database? _db;

  static Future<Database> get database async {
    if (_db != null) return _db!;

    final path = join(await getDatabasesPath(), 'reportes.db');

    _db = await openDatabase(
      path,
      version: 6,

      onCreate: (db, version) async {
        await _crearTablas(db);
      },

      onUpgrade: (db, oldVersion, newVersion) async {

        //----------------------------------------------------
        // Migración a versión 3
        //----------------------------------------------------

        if (oldVersion < 3) {

          await db.execute('''
      ALTER TABLE reportes
      ADD COLUMN uuid TEXT
    ''');

          await db.execute('''
      ALTER TABLE reportes
      ADD COLUMN fechaSincronizacion TEXT
    ''');

          await db.execute('''
      ALTER TABLE reportes
      ADD COLUMN intentos INTEGER DEFAULT 0
    ''');

          await db.execute('''
      ALTER TABLE reportes
      ADD COLUMN ultimoError TEXT
    ''');

          await db.execute('''
      ALTER TABLE reportes
      ADD COLUMN sincronizando INTEGER DEFAULT 0
    ''');

        }

        //----------------------------------------------------
        // Migración a versión 4
        //----------------------------------------------------

        if (oldVersion < 4) {

          await db.execute('''

      CREATE TABLE IF NOT EXISTS catalogo_plagas(

        id INTEGER PRIMARY KEY,

        nombre TEXT

      )

    ''');

          await db.execute('''

      CREATE TABLE IF NOT EXISTS configuracion(

        clave TEXT PRIMARY KEY,

        valor TEXT

      )

    ''');

        }

        //----------------------------------------------------
// Migración a versión 5
//----------------------------------------------------

        if (oldVersion < 5) {

          await db.execute('''
    CREATE TABLE IF NOT EXISTS estados(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      nombre TEXT NOT NULL UNIQUE
    )
  ''');

          await db.execute('''
    CREATE TABLE IF NOT EXISTS municipios(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      estado TEXT NOT NULL,
      nombre TEXT NOT NULL,
      UNIQUE(estado,nombre)
      
    )
  ''');

          await db.execute('''
    CREATE TABLE IF NOT EXISTS localidades(
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      estado TEXT NOT NULL,
      municipio TEXT NOT NULL,
      nombre TEXT NOT NULL
    )
  ''');

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_municipios_estado ON municipios(estado)',
          );

          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_localidades_municipio ON localidades(estado, municipio)',
          );
        }

        // Datos necesarios para una cola de sincronización tolerante a cortes
        // de red. La migración no elimina reportes que ya existan en campo.
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE reportes ADD COLUMN folio TEXT');
          await db.execute('ALTER TABLE reportes ADD COLUMN proximoIntento TEXT');
        }







        await db.execute(

          'CREATE INDEX IF NOT EXISTS idx_status ON reportes(status)',

        );

      },
    );

    return _db!;
  }

  static Future<void> _crearTablas(Database db) async {

    await db.execute('''

CREATE TABLE reportes(

id INTEGER PRIMARY KEY AUTOINCREMENT,

uuid TEXT,

tipoPlaga TEXT,

descripcion TEXT,

latitud REAL,

longitud REAL,

estado TEXT,

municipio TEXT,

localidad TEXT,

cantidadArboles INTEGER,

imagenes TEXT,

fecha TEXT,

status TEXT,

fechaSincronizacion TEXT,

intentos INTEGER DEFAULT 0,

ultimoError TEXT,

sincronizando INTEGER DEFAULT 0,

folio TEXT,

proximoIntento TEXT

)

''');

    await db.execute('''

CREATE TABLE catalogo_plagas(

id INTEGER PRIMARY KEY,

nombre TEXT

)

''');

    await db.execute('''

CREATE TABLE configuracion(

clave TEXT PRIMARY KEY,

valor TEXT

)

''');

    await db.execute(

        'CREATE INDEX IF NOT EXISTS idx_status ON reportes(status)',

    );
    await db.execute('''
CREATE TABLE estados(

id INTEGER PRIMARY KEY AUTOINCREMENT,

nombre TEXT NOT NULL UNIQUE

)
''');

    await db.execute('''
CREATE TABLE municipios(

id INTEGER PRIMARY KEY AUTOINCREMENT,

estado TEXT NOT NULL,

nombre TEXT NOT NULL,

UNIQUE(estado,nombre)

)
''');

    await db.execute('''
CREATE TABLE localidades(

id INTEGER PRIMARY KEY AUTOINCREMENT,

estado TEXT NOT NULL,

municipio TEXT NOT NULL,

nombre TEXT NOT NULL,

UNIQUE(estado,municipio,nombre)

)
''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_municipios_estado ON municipios(estado)',
    );

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_localidades_municipio ON localidades(estado, municipio)',
    );

  }
  static Future<bool> existeCatalogoGeografico() async {

    final db = await database;

    final resultado = await db.rawQuery(

      'SELECT COUNT(*) total FROM estados',

    );

    return (resultado.first['total'] as int) > 0;

  }

}
