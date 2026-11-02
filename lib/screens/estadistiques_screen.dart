
import 'package:flutter/material.dart';
import '../models/habitos.dart';
import '../services/preferencies_service.dart';
import '../widgets/dato_estadistica.dart';

class EstadistiquesScreen extends StatefulWidget {
  final int idUsuari;
  final List<Habit> habits;

  const EstadistiquesScreen({
    super.key,
    required this.idUsuari,
    required this.habits,
  });

  @override
  State<EstadistiquesScreen> createState() =>
      _EstadistiquesScreenState();
}

class _EstadistiquesScreenState extends State<EstadistiquesScreen> {

  final PreferenciesService preferencies = PreferenciesService();

  //Guardem les apertures, l'última entrada i l'estat de càrrega
  int apertures = 0;
  DateTime? ultimaObertura;
  bool carregant = true;

  //Carreguem les estadístiques quan s'obre la pantalla
  @override
  void initState() {
    super.initState();
    carregarEstadistiques();
  }

  //Recuperem les estadístiques de l'usuari actual
  Future<void> carregarEstadistiques() async {

    //Obtenim les apertures d'aquest usuari
    final totalApertures =
    await preferencies.obtenirApertures(widget.idUsuari);

    //Obtenim la seva última entrada
    final ultimaData =
    await preferencies.obtenirUltimaObertura(widget.idUsuari);

    if (!mounted) return;

    setState(() {
      apertures = totalApertures;
      ultimaObertura = ultimaData;
      carregant = false;
    });
  }

  //Convertim una data guardada en un objecte DateTime
  DateTime? convertirData(String data) {
    final parts = data.split('-');

    if (parts.length != 3) return null;

    final any = int.tryParse(parts[0]);
    final mes = int.tryParse(parts[1]);
    final dia = int.tryParse(parts[2]);

    if (any == null || mes == null || dia == null) {
      return null;
    }

    final resultat = DateTime(any, mes, dia);

    //Comprovem que la data sigui vàlida
    if (resultat.year != any ||
        resultat.month != mes ||
        resultat.day != dia) {
      return null;
    }

    return resultat;
  }

  //Convertim una data al format dels hàbits
  String formatData(DateTime data) {
    return '${data.year}-${data.month}-${data.day}';
  }

  //Calculem el total de dies diferents completats
  int calcularDiesCompletats(Habit habit) {
    return habit.datesCompletades.toSet().length;
  }

  //Calculem la ratxa de dies consecutius
  int calcularRatxaActual(Habit habit) {

    final dates = habit.datesCompletades.toSet();

    final ara = DateTime.now();
    final avui = DateTime(ara.year, ara.month, ara.day);

    DateTime dataActual = avui;

    //Si avui no està completat, comencem per ahir
    if (!dates.contains(formatData(avui))) {
      dataActual = avui.subtract(const Duration(days: 1));
    }

    int ratxa = 0;

    //Comptem els dies consecutius completats
    while (dates.contains(formatData(dataActual))) {
      ratxa++;

      dataActual = DateTime(
        dataActual.year,
        dataActual.month,
        dataActual.day - 1,
      );
    }

    return ratxa;
  }

  //Mostrem la data i hora de l'última entrada
  String formatDataHora(DateTime? data) {

    if (data == null) {
      return 'Encara no hi ha dades';
    }

    final dia = data.day.toString().padLeft(2, '0');
    final mes = data.month.toString().padLeft(2, '0');
    final any = data.year;

    final hora = data.hour.toString().padLeft(2, '0');
    final minut = data.minute.toString().padLeft(2, '0');

    return '$dia/$mes/$any $hora:$minut';
  }

  @override
  Widget build(BuildContext context) {

    //Mostrem les estadístiques generals i les de cada hàbit
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadístiques'),
      ),

      body: carregant
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : ListView(
        padding: const EdgeInsets.all(20),
        children: [

          const Text(
            'Estadístiques generals',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          //Mostrem les apertures de l'usuari actual
          Card(
            child: ListTile(
              leading: const Icon(Icons.login),
              title: const Text(
                'Vegades que has obert l\'app',
              ),
              trailing: Text('$apertures'),
            ),
          ),

          //Mostrem l'última entrada de l'usuari
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Última obertura'),
              subtitle: Text(
                formatDataHora(ultimaObertura),
              ),
            ),
          ),

          const SizedBox(height: 25),

          const Text(
            'Estadístiques dels hàbits',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 15),

          //Missatge quan no hi ha hàbits
          if (widget.habits.isEmpty)
            const Text('Encara no tens hàbits creats.'),

          //Mostrem una targeta per cada hàbit
          ...widget.habits.map((habit) {

            final ratxa = calcularRatxaActual(habit);
            final dies = calcularDiesCompletats(habit);

            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(habit.color),
                ),

                title: Text(habit.nom),

                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    const SizedBox(height: 8),

                    //Mostrem la ratxa actual
                    DatoEstadistica(
                      etiqueta: 'Ratxa actual',
                      valor: '$ratxa dies',
                      icono: Icons.local_fire_department,
                      color: Colors.orange,
                    ),

                    //Mostrem els dies completats
                    DatoEstadistica(
                      etiqueta: 'Total de dies completats',
                      valor: '$dies',
                      icono: Icons.calendar_today,
                      color: Colors.green,
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
