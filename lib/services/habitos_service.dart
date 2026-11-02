import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

// Classe per gestionar els hàbits i actualitzar les estadístiques automàticament.
class HabitosService {
  // Convertim les dates guardades en una llista.
  static List<String> _llegirDates(Object? valor) {
    if (valor == null) return [];
    return List<String>.from(jsonDecode(valor.toString()) as List);
  }

  // Calculem la ratxa actual i el nombre total de dies diferents completats.
  static Map<String, int> _calcularEstadistiques(List<String> dates) {
    final dies = <DateTime>{};
    for (final text in dates) {
      final data = DateTime.tryParse(text);
      if (data != null) {
        final local = data.toLocal();
        dies.add(DateTime(local.year, local.month, local.day));
      }
    }

    final avui = DateTime.now();
    final diaAvui = DateTime(avui.year, avui.month, avui.day);
    var dia = diaAvui;
    // Si avui encara no s'ha completat, permetem continuar la ratxa d'ahir.
    if (!dies.contains(dia)) {
      dia = dia.subtract(const Duration(days: 1));
    }

    int ratxa = 0;
    while (dies.contains(dia)) {
      ratxa++;
      dia = dia.subtract(const Duration(days: 1));
    }
    return {'racha_actual': ratxa, 'total_dias': dies.length};
  }

  // Creem o actualitzem les estadístiques a partir de les dates de l'hàbit.
  static Future<void> _actualitzarEstadistiques(
      Transaction txn,
      int idHabit,
      List<String> dates,
      ) async {
    final valors = _calcularEstadistiques(dates);
    final existents = await txn.query(
      'estadisticas',
      columns: ['id_habit'],
      where: 'id_habit = ?',
      whereArgs: [idHabit],
      limit: 1,
    );
    if (existents.isEmpty) {
      await txn.insert('estadisticas', {'id_habit': idHabit, ...valors});
    } else {
      await txn.update(
        'estadisticas',
        valors,
        where: 'id_habit = ?',
        whereArgs: [idHabit],
      );
    }
  }

  // Recuperem estadístiques que faltin dels hàbits ja creats.
  static Future<void> sincronitzarEstadistiques() async {
    final db = await DatabaseService.obtenirDatabase();
    await db.transaction((txn) async {
      final habits = await txn.query('habitos');
      for (final habit in habits) {
        await _actualitzarEstadistiques(
          txn,
          habit['id_habit'] as int,
          _llegirDates(habit['fechas_completadas']),
        );
      }
    });
  }

  // Obtenim tots els hàbits d'un usuari.
  static Future<List<Map<String, Object?>>> obtenirHabits(int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.query('habitos', where: 'id_usuario = ?', whereArgs: [idUsuari]);
  }

  // Obtenim un hàbit concret d'un usuari.
  static Future<Map<String, Object?>?> obtenirHabit(int idHabit, int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();
    final resultat = await db.query(
      'habitos',
      where: 'id_habit = ? AND id_usuario = ?',
      whereArgs: [idHabit, idUsuari],
    );
    return resultat.isEmpty ? null : resultat.first;
  }

  // Creem l'hàbit i les seves estadístiques inicials en una sola operació.
  static Future<int> crearHabit(int idUsuari, String nom, int color) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.transaction((txn) async {
      final idHabit = await txn.insert('habitos', {
        'id_usuario': idUsuari,
        'nombre': nom,
        'color': color,
        'fechas_completadas': '[]',
      });
      await _actualitzarEstadistiques(txn, idHabit, []);
      return idHabit;
    });
  }

  // Modifiquem el nom i el color de l'hàbit.
  static Future<int> editarHabit(int idHabit, int idUsuari, String nom, int color) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.update(
      'habitos',
      {'nombre': nom, 'color': color},
      where: 'id_habit = ? AND id_usuario = ?',
      whereArgs: [idHabit, idUsuari],
    );
  }

  // Eliminem les estadístiques i després l'hàbit.
  static Future<int> eliminarHabit(int idHabit, int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.transaction((txn) async {
      final habit = await txn.query(
        'habitos',
        columns: ['id_habit'],
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );
      if (habit.isEmpty) return 0;
      await txn.delete('estadisticas', where: 'id_habit = ?', whereArgs: [idHabit]);
      return txn.delete(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );
    });
  }

  // Completem l'hàbit una sola vegada al dia i actualitzem estadístiques.
  static Future<bool> completarHabit(int idHabit, int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.transaction((txn) async {
      final resultat = await txn.query(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );
      if (resultat.isEmpty) return false;
      final dates = _llegirDates(resultat.first['fechas_completadas']);
      final ara = DateTime.now();
      final completatAvui = dates.any((text) {
        final dia = DateTime.parse(text).toLocal();
        return dia.year == ara.year && dia.month == ara.month && dia.day == ara.day;
      });
      if (completatAvui) return false;
      dates.add(ara.toIso8601String());
      await txn.update(
        'habitos',
        {'fechas_completadas': jsonEncode(dates)},
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );
      await _actualitzarEstadistiques(txn, idHabit, dates);
      return true;
    });
  }

  // Desmarquem el dia actual i recalculem les estadístiques.
  static Future<bool> desmarcarHabit(int idHabit, int idUsuari) async {
    final db = await DatabaseService.obtenirDatabase();
    return db.transaction((txn) async {
      final resultat = await txn.query(
        'habitos',
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
        limit: 1,
      );
      if (resultat.isEmpty) return false;
      final dates = _llegirDates(resultat.first['fechas_completadas']);
      final ara = DateTime.now();
      final quantitatAnterior = dates.length;
      dates.removeWhere((text) {
        final dia = DateTime.parse(text).toLocal();
        return dia.year == ara.year && dia.month == ara.month && dia.day == ara.day;
      });
      if (dates.length == quantitatAnterior) return false;
      await txn.update(
        'habitos',
        {'fechas_completadas': jsonEncode(dates)},
        where: 'id_habit = ? AND id_usuario = ?',
        whereArgs: [idHabit, idUsuari],
      );
      await _actualitzarEstadistiques(txn, idHabit, dates);
      return true;
    });
  }

  // Obtenim tots els hàbits per a l'administrador.
  static Future<List<Map<String, Object?>>> obtenirTotsHabits() async {
    final db = await DatabaseService.obtenirDatabase();
    return db.query('habitos');
  }
}