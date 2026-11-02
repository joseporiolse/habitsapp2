
import 'package:flutter/material.dart';
import '../models/habitos.dart';
import '../services/preferencies_service.dart';
import '../services/estadisticas_service.dart';
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

  //Guardem les apertures i l'ultima entrada
  int apertures = 0;
  DateTime? ultimaObertura;
  bool carregant = true;

  //Guardem les estadistiques de cada habit
  Map<int, Map<String, Object?>> estadistiquesHabits = {};

  //Carreguem les estadistiques quan obrim la pantalla
  @override
  void initState() {
    super.initState();
    carregarEstadistiques();
  }

  //Recuperem les estadistiques de l'usuari i dels seus habits
  Future<void> carregarEstadistiques() async {

    //Obtenim les apertures d'aquest usuari
    final totalApertures =
    await preferencies.obtenirApertures(widget.idUsuari);

    //Obtenim la seva ultima entrada
    final ultimaData =
    await preferencies.obtenirUltimaObertura(widget.idUsuari);

    //Creem un mapa per guardar les estadistiques dels habits
    final Map<int, Map<String, Object?>> resultat = {};

    //Recorrem els habits de l'usuari actual
    for (final habit in widget.habits) {

      //Busquem les estadistiques de cada habit a SQLite
      final dades =
      await EstadisticasService.obtenirEstadistiques(habit.id);

      if (dades != null) {
        resultat[habit.id] = dades;
      }
    }

    if (!mounted) return;

    //Actualitzem les dades de la pantalla
    setState(() {
      apertures = totalApertures;
      ultimaObertura = ultimaData;
      estadistiquesHabits = resultat;
      carregant = false;
    });
  }

  //Mostrem la data i hora de l'ultima entrada
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

          //Mostrem l'ultima entrada de l'usuari
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

          //Missatge quan no hi ha habits
          if (widget.habits.isEmpty)
            const Text('Encara no tens hàbits creats.'),

          //Mostrem les estadistiques de cada habit
          ...widget.habits.map((habit) {

            //Recuperem les dades de SQLite
            final dades = estadistiquesHabits[habit.id];

            //Obtenim la ratxa actual
            final int ratxa =
                dades?['racha_actual'] as int? ?? 0;

            //Obtenim el total de dies completats
            final int dies =
                dades?['total_dias'] as int? ?? 0;

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

                    //Mostrem la ratxa actual de SQLite
                    DatoEstadistica(
                      etiqueta: 'Ratxa actual',
                      valor: '$ratxa dies',
                      icono: Icons.local_fire_department,
                      color: Colors.orange,
                    ),

                    //Mostrem els dies completats de SQLite
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
