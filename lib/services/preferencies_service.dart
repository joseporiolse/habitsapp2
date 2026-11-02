import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/habitos.dart';

//Gestionem les dades que es guarden localment a l'aplicació
class PreferenciesService {

  //Claus per identificar les diferents dades guardades
  static const String clauNom = 'nom';
  static const String clauObjectiu = 'objectiu';
  static const String clauHabits = 'habits';
  static const String clauApertures = 'apertures';
  static const String clauHistorialApertures = 'historial_apertures';
  static const String clauTemaFosc = 'tema_fosc';
  static const String clauMidaLletra = 'mida_lletra';
  static const String clauOcultarCompletats = 'ocultar_completats';

  //Guardem el nom de l'usuari
  Future<void> guardarNom(String nom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(clauNom, nom);
  }

  //Guardem l'objectiu diari
  Future<void> guardarObjectiu(int objectiu) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(clauObjectiu, objectiu);
  }

  //Recuperem el nom guardat
  Future<String?> obtenirNom() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(clauNom);
  }

  //Recuperem l'objectiu diari
  Future<int?> obtenirObjectiu() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(clauObjectiu);
  }

  //Guardem els hàbits en format JSON
  Future<void> guardarHabits(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();

    final llistaJson = habits.map((habit) => habit.toJson()).toList();
    final textJson = jsonEncode(llistaJson);

    await prefs.setString(clauHabits, textJson);
  }

  //Comprovem si existeixen hàbits guardats
  Future<bool> existeixenHabitsGuardats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(clauHabits);
  }

  //Recuperem els hàbits guardats
  Future<List<Habit>> obtenirHabits() async {
    final prefs = await SharedPreferences.getInstance();
    final textJson = prefs.getString(clauHabits);

    if (textJson == null) {
      return [];
    }

    final llistaJson = jsonDecode(textJson) as List<dynamic>;

    return llistaJson.map((element) {
      return Habit.fromJson(element as Map<String, dynamic>);
    }).toList();
  }

  //Esborrem totes les dades de SharedPreferences
  Future<void> esborrarTotalDades() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  //Registrem una entrada per a un usuari concret
  Future<void> registrarObertura(int idUsuari) async {
    final prefs = await SharedPreferences.getInstance();

    final clauUsuari = '${clauApertures}_$idUsuari';
    final clauHistorial = '${clauHistorialApertures}_$idUsuari';

    //Augmentem el comptador d'aquest usuari
    final aperturesActuals = prefs.getInt(clauUsuari) ?? 0;
    await prefs.setInt(clauUsuari, aperturesActuals + 1);

    //Guardem la data i hora de l'entrada
    final historial = prefs.getStringList(clauHistorial) ?? [];

    historial.add(DateTime.now().toIso8601String());

    await prefs.setStringList(clauHistorial, historial);
  }

  //Recuperem les apertures d'un usuari concret
  Future<int> obtenirApertures(int idUsuari) async {
    final prefs = await SharedPreferences.getInstance();

    final clauUsuari = '${clauApertures}_$idUsuari';

    return prefs.getInt(clauUsuari) ?? 0;
  }

  //Recuperem l'última entrada d'un usuari concret
  Future<DateTime?> obtenirUltimaObertura(int idUsuari) async {
    final prefs = await SharedPreferences.getInstance();

    final clauHistorial = '${clauHistorialApertures}_$idUsuari';

    final historial = prefs.getStringList(clauHistorial) ?? [];

    if (historial.isEmpty) {
      return null;
    }

    return DateTime.tryParse(historial.last);
  }

  //Guardem el tema fosc
  Future<void> guardarTemaFosc(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(clauTemaFosc, valor);
  }

  //Recuperem el tema fosc
  Future<bool> obtenirTemaFosc() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(clauTemaFosc) ?? false;
  }

  //Guardem la mida de la lletra
  Future<void> guardarMidaLletra(double valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(clauMidaLletra, valor);
  }

  //Recuperem la mida de la lletra
  Future<double> obtenirMidaLletra() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(clauMidaLletra) ?? 1.0;
  }

  //Guardem si volem ocultar els hàbits completats
  Future<void> guardarOcultarCompletats(bool valor) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(clauOcultarCompletats, valor);
  }

  //Recuperem si volem ocultar els hàbits completats
  Future<bool> obtenirOcultarCompletats() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(clauOcultarCompletats) ?? false;
  }
}
