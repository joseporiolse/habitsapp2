import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseService {

  //Guardem la base de dades per no crear una nova connexio cada vegada
  static Database? _database;

  static Future<Database> obtenirDatabase() async {

    //Si ja tenim la base de dades la retornem
    if (_database != null) {
      return _database!;
    }

    //Busquem la ruta on es guardara la base de dades
    String ruta = await getDatabasesPath();

    String rutaCompleta = join(ruta, 'habitosapp.db');

    //Obrim la base de dades i si no existeix la creem
    _database = await openDatabase(
      rutaCompleta,
      version: 2,

      //Activem les claus foranes per relacionar les taules
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },

      //Creem les taules quan es crea la base de dades per primera vegada
      onCreate: (db, version) async {

        //Creem la taula usuarios per guardar les dades dels usuaris
        await db.execute('''
          CREATE TABLE usuarios (
            id_usuario INTEGER PRIMARY KEY AUTOINCREMENT,
            usuario TEXT NOT NULL UNIQUE,
            nombre TEXT NOT NULL,
            apellidos TEXT NOT NULL,
            email TEXT NOT NULL UNIQUE,
            contrasena TEXT NOT NULL,
            fecha_creacion TEXT NOT NULL,
            objetivo_diario INTEGER NOT NULL DEFAULT 3,
            rol TEXT NOT NULL DEFAULT 'usuario'
              CHECK (rol IN ('usuario', 'administrador'))
          )
        ''');

        await db.execute('''
          CREATE TABLE habitos (
            id_habit INTEGER PRIMARY KEY AUTOINCREMENT,
            id_usuario INTEGER NOT NULL,
            nombre TEXT NOT NULL,
            color INTEGER NOT NULL,
            fechas_completadas TEXT NOT NULL DEFAULT '[]',

            FOREIGN KEY (id_usuario)
              REFERENCES usuarios(id_usuario)
              ON DELETE CASCADE
          )
        ''');

        await db.execute('''
          CREATE TABLE estadisticas (
            id_estadistica INTEGER PRIMARY KEY AUTOINCREMENT,
            id_habit INTEGER NOT NULL UNIQUE,
            racha_actual INTEGER NOT NULL DEFAULT 0,
            total_dias INTEGER NOT NULL DEFAULT 0,

            FOREIGN KEY (id_habit)
              REFERENCES habitos(id_habit)
              ON DELETE CASCADE
          )
        ''');
      },

      //Actualitzem la base de dades si ja existia
      onUpgrade: (db, oldVersion, newVersion) async {

        //Afegim l'objectiu diari als usuaris de la versio anterior
        if (oldVersion < 2) {
          await db.execute('''
            ALTER TABLE usuarios
            ADD COLUMN objetivo_diario INTEGER NOT NULL DEFAULT 3
          ''');
        }
      },
    );

    //Retornem la base de dades per utilitzar-la en altres serveis
    return _database!;
  }

  //Eliminem tota la base de dades per restablir l'aplicacio
  static Future<void> restablirBaseDades() async {

    //Tanquem la connexio actual si esta oberta
    if (_database != null) {
      await _database!.close();
      _database = null;
    }

    //Obtenim la ruta de la base de dades
    final ruta = await getDatabasesPath();
    final rutaCompleta = join(ruta, 'habitosapp.db');

    //Eliminem la base de dades amb tots els seus registres
    await deleteDatabase(rutaCompleta);

    //Creem de nou les taules buides
    await obtenirDatabase();
  }
}
