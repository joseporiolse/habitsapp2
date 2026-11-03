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

  @override
  void initState() {
    super.initState();
    carregarEstadistiques();
  }

  //Recuperem les estadistiques de l'usuari i dels seus habits
  Future<void> carregarEstadistiques() async {

    final totalApertures =
    await preferencies.obtenirApertures(widget.idUsuari);

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

          if (widget.habits.isEmpty)
            const Text('Encara no tens hàbits creats.'),

          ...widget.habits.map((habit) {

            final dades = estadistiquesHabits[habit.id];

            final int ratxa =
                dades?['racha_actual'] as int? ?? 0;

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
