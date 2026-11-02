
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

//Classe per gestionar els habits i actualitzar les estadistiques
class HabitosService {

  //Convertim les dates guardades en una llista
  static List<String> _llegirDates(Object? valor) {
    if (valor == null) return [];

    return List<String>.from(
      jsonDecode(valor.toString()) as List,
    );
  }

  //Calculem la ratxa actual i el total de dies completats
  static Map<String, int> _calcularEstadistiques(
      List<String> dates,
      ) {
    final dies = <DateTime>{};

    for (final text in dates) {
      final data = DateTime.tryParse(text);

      if (data != null) {
        final local = data.toLocal();

        dies.add(
          DateTime(local.year, local.month, local.day),
        );
      }
    }

    final avui = DateTime.now();
    final diaAvui = DateTime(
      avui.year,
      avui.month,
      avui.day,
    );

    var dia = diaAvui;

    //Si avui no esta completat, comencem per ahir
    if (!dies.contains(dia)) {
      dia = dia.subtract(const Duration(days: 1));
    }

    int ratxa = 0;

    //Comptem els dies consecutius
    while (dies.contains(dia)) {
      ratxa++;

      dia = dia.subtract(const Duration(days: 1));
    }

    return {
      'racha_actual': ratxa,
      'total_dias': dies.length,
    };
  }

  //Creem o actualitzem les estadistiques d'un habit
  static Future<void> _actualitzarEstadistiques(
      Transaction txn,
      int idHabit,
      List<String> dates,
      ) async {
    final valors = _calcularEstadistiques(dates);

    //Comprovem si ja existeixen estadistiques
    final existents = await txn.query(
      'estadisticas',
      columns: ['id_habit'],
      where: 'id_habit = ?',
      whereArgs: [idHabit],
      limit: 1,
    );

    if (existents.isEmpty) {

      //Creem les estadistiques si no existeixen
      await txn.insert(
        'estadisticas',
        {
          'id_habit': idHabit,
          ...valors,
        },
      );

    } else {

      //Actualitzem les estadistiques existents
      await txn.update(
        'estadisticas',
        valors,
        where: 'id_habit = ?',
        whereArgs: [idHabit],
      );
    }
  }

  //Recuperem les estadistiques que faltin sense modificar les existents
  static Future<void> sincronitzarEstadistiques() async {
    final db = await DatabaseService.obtenirDatabase();

    await db.transaction((txn) async {

      //Obtenim tots els habits guardats
      final habits = await txn.query('habitos');

      for (final habit in habits) {
        final idHabit = habit['id_habit'] as int;

        //Comprovem si aquest habit ja te estadistiques
        final existents = await txn.query(
          'estadisticas',
          columns: ['id_habit'],
          where: 'id_habit = ?',
          whereArgs: [idHabit],
          limit: 1,
        );

        //Si ja existeixen, no les modifiquem
        if (existents.isNotEmpty) {
          continue;
        }

        //Recuperem les dates completades
        final dates = _llegirDates(
          habit['fechas_completadas'],
        );

        //Creem nomes les estadistiques que falten
        await _actualitzarEstadistiques(
          txn,
          idHabit,
          dates,
        );
      }
    });
  }

  //Obtenim tots els habits d'un usuari
  static Future<List<Map<String, Object?>>> obtenirHabits(
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.query(
      'habitos',
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );
  }

  //Obtenim un habit concret d'un usuari
  static Future<Map<String, Object?>?> obtenirHabit(
      int idHabit,
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    final resultat = await db.query(
      'habitos',
      where: 'id_habit = ? AND id_usuario = ?',
      whereArgs: [idHabit, idUsuari],
    );

    return resultat.isEmpty ? null : resultat.first;
  }

  //Creem un habit i les seves estadistiques inicials
  static Future<int> crearHabit(
      int idUsuari,
      String nom,
      int color,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.transaction((txn) async {

      //Guardem l'habit a SQLite
      final idHabit = await txn.insert(
        'habitos',
        {
          'id_usuario': idUsuari,
          'nombre': nom,
          'color': color,
          'fechas_completadas': '[]',
        },
      );

      //Creem les estadistiques inicials a zero
      await _actualitzarEstadistiques(
        txn,
        idHabit,
        [],
      );

      return idHabit;
    });
  }

  //Modifiquem el nom i el color d'un habit
  static Future<int> editarHabit(
      int idHabit,
      int idUsuari,
      String nom,
      int color,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.update(
      'habitos',
      {
        'nombre': nom,
        'color': color,
      },
      where: 'id_habit = ? AND id_usuario = ?',
      whereArgs: [idHabit, idUsuari],
    );
  }

  //Eliminem un habit i les seves estadistiques
  static Future<int> eliminarHabit(
      int idHabit,
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.transaction((txn) async {

      //Comprovem que l'habit pertanyi a l'usuari
      final habit = await txn.query(
        'habitos',
        columns: ['id_habit'],
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );

      if (habit.isEmpty) return 0;

      //Eliminem les estadistiques de l'habit
      await txn.delete(
        'estadisticas',
        where: 'id_habit = ?',
        whereArgs: [idHabit],
      );

      //Eliminem l'habit
      return txn.delete(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );
    });
  }

  //Completem un habit una sola vegada al dia
  static Future<bool> completarHabit(
      int idHabit,
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.transaction((txn) async {

      //Busquem l'habit de l'usuari
      final resultat = await txn.query(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );

      if (resultat.isEmpty) return false;

      //Recuperem les dates completades
      final dates = _llegirDates(
        resultat.first['fechas_completadas'],
      );

      final ara = DateTime.now();

      //Comprovem si ja esta completat avui
      final completatAvui = dates.any((text) {
        final dia = DateTime.parse(text).toLocal();

        return dia.year == ara.year &&
            dia.month == ara.month &&
            dia.day == ara.day;
      });

      //Evitem completar dues vegades el mateix dia
      if (completatAvui) return false;

      //Afegim la data actual
      dates.add(ara.toIso8601String());

      //Guardem les dates actualitzades a SQLite
      await txn.update(
        'habitos',
        {
          'fechas_completadas': jsonEncode(dates),
        },
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );

      //Recalculem les estadistiques segons les dates reals
      await _actualitzarEstadistiques(
        txn,
        idHabit,
        dates,
      );

      return true;
    });
  }

  //Desmarquem un habit completat avui
  static Future<bool> desmarcarHabit(
      int idHabit,
      int idUsuari,
      ) async {
    final db = await DatabaseService.obtenirDatabase();

    return db.transaction((txn) async {

      //Busquem l'habit de l'usuari
      final resultat = await txn.query(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );

      if (resultat.isEmpty) return false;

      //Recuperem les dates completades
      final dates = _llegirDates(
        resultat.first['fechas_completadas'],
      );

      final ara = DateTime.now();
      final quantitatAnterior = dates.length;

      //Eliminem la data actual de la llista
      dates.removeWhere((text) {
        final dia = DateTime.parse(text).toLocal();

        return dia.year == ara.year &&
            dia.month == ara.month &&
            dia.day == ara.day;
      });

      //Si no estava completat avui, no fem res
      if (dates.length == quantitatAnterior) {
        return false;
      }

      //Guardem les dates actualitzades
      await txn.update(
        'habitos',
        {
          'fechas_completadas': jsonEncode(dates),
        },
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );

      //Recalculem les estadistiques segons les dates reals
      await _actualitzarEstadistiques(
        txn,
        idHabit,
        dates,
      );

      return true;
    });
  }

  //Obtenim tots els habits per a l'administrador
  static Future<List<Map<String, Object?>>> obtenirTotsHabits() async {
    final db = await DatabaseService.obtenirDatabase();

    return db.query('habitos');
  }
}
