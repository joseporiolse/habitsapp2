import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class UsuariosService {

  static Future<int> registrarUsuari(
      String usuari,
      String nom,
      String cognoms,
      String email,
      String contrasena,
      int objetivo,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    //Comprovem que l'objectiu sigui correcte
    if (objetivo <= 0) {
      throw ArgumentError('L\'objectiu ha de ser més gran que 0');
    }

    //Comprovem si es el primer usuari
    return await db.transaction((txn) async {

      //Comptem quants usuaris hi ha registrats
      final resultat = await txn.rawQuery(
        'SELECT COUNT(*) AS total FROM usuarios',
      );

      int total = Sqflite.firstIntValue(resultat) ?? 0;

      //Si es el primer usuari sera administrador
      String rol = total == 0 ? 'administrador' : 'usuario';

      //Guardem les dades del nou usuari
      return await txn.insert(
        'usuarios',
        {
          'usuario': usuari,
          'nombre': nom,
          'apellidos': cognoms,
          'email': email,
          'contrasena': contrasena,
          'fecha_creacion': DateTime.now().toIso8601String(),
          'objetivo_diario': objetivo,
          'rol': rol,
        },
      );
    });
  }

  //Busquem un usuari pel seu nom d'usuari
  static Future<Map<String, Object?>?> obtenirUsuari(
      String usuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    final resultat = await db.query(
      'usuarios',
      where: 'usuario = ?',
      whereArgs: [usuari],
    );

    if (resultat.isEmpty) {
      return null;
    }

    return resultat.first;
  }

  static Future<Map<String, Object?>?> obtenirUsuariPerId(
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    final resultat = await db.query(
      'usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );

    if (resultat.isEmpty) {
      return null;
    }

    return resultat.first;
  }

  //Comprovem les dades per iniciar sessio
  static Future<Map<String, Object?>?> iniciarSessio(
      String usuari,
      String contrasena,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    final resultat = await db.query(
      'usuarios',
      where: 'usuario = ? AND contrasena = ?',
      whereArgs: [usuari, contrasena],
    );

    //Si les dades no son correctes retornem null
    if (resultat.isEmpty) {
      return null;
    }

    return resultat.first;
  }

  //Modifiquem les dades d'un usuari
  static Future<int> editarUsuari(
      int idUsuari,
      String usuari,
      String nom,
      String cognoms,
      String email,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.update(
      'usuarios',
      {
        'usuario': usuari,
        'nombre': nom,
        'apellidos': cognoms,
        'email': email,
      },
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );
  }

  static Future<int> editarObjetivo(
      int idUsuari,
      int objetivo,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    //Comprovem que l'objectiu sigui correcte
    if (objetivo <= 0) {
      throw ArgumentError('L\'objectiu ha de ser més gran que 0');
    }

    //Guardem el nou objectiu
    return await db.update(
      'usuarios',
      {
        'objetivo_diario': objetivo,
      },
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );
  }

  static Future<int> obtenirObjetivo(int idUsuari) async {
    final usuari = await obtenirUsuariPerId(idUsuari);

    if (usuari == null) {
      throw StateError('Usuari no trobat');
    }

    return usuari['objetivo_diario'] as int;
  }

  //Eliminem un usuari de la base de dades
  static Future<int> eliminarUsuari(int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.delete(
      'usuarios',
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );
  }

  //Obtenim tots els usuaris per a l'administrador
  static Future<List<Map<String, Object?>>> obtenirTotsUsuaris() async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.query('usuarios');
  }

  //Comprovem si un usuari es administrador
  static Future<bool> esAdministrador(int idUsuari) async {
    final usuari = await obtenirUsuariPerId(idUsuari);

    if (usuari == null) {
      return false;
    }

    return usuari['rol'] == 'administrador';
  }
}
