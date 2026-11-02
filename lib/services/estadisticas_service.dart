import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

class EstadisticasService {

  //Obtenim les estadistiques d'un habit
  static Future<Map<String, Object?>?> obtenirEstadistiques(int idHabit) async {
    final db = await DatabaseService.obtenirDatabase();

    //Busquem les estadistiques que pertanyen a aquest habit
    final resultat = await db.query(
      'estadisticas',
      where: 'id_habit = ?',
      whereArgs: [idHabit],
    );

    if (resultat.isEmpty) {
      return null;
    }

    return resultat.first;
  }

  //Creem les estadistiques inicials d'un habit
  static Future<int> crearEstadistiques(int idHabit) async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.insert(
      'estadisticas',
      {
        'id_habit': idHabit,
        'racha_actual': 0,
        'total_dias': 0,
      },
    );
  }

  //Actualitzem la ratxa i els dies completats d'un habit
  static Future<int> actualitzarEstadistiques(
      int idHabit,
      int rachaActual,
      int totalDias,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.update(
      'estadisticas',
      {
        'racha_actual': rachaActual,
        'total_dias': totalDias,
      },
      where: 'id_habit = ?',
      whereArgs: [idHabit],
    );
  }

  //Eliminem les estadistiques d'un habit
  static Future<int> eliminarEstadistiques(int idHabit) async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.delete(
      'estadisticas',
      where: 'id_habit = ?',
      whereArgs: [idHabit],
    );
  }

  //Obtenim totes les estadistiques per a l'administrador
  static Future<List<Map<String, Object?>>> obtenirTotesEstadistiques() async {
    final db = await DatabaseService.obtenirDatabase();

    return await db.query('estadisticas');
  }
}
