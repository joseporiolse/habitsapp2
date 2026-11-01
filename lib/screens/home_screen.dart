import 'benvinguda_screen.dart';
import 'package:flutter/material.dart';
import '../models/habitos.dart';
import '../services/preferencies_service.dart';
import 'estadistiques_screen.dart';
import 'configuracio_screen.dart';
import 'editar_habit_screen.dart';
import '../widgets/targeta_habit.dart';
import 'login_page.dart';

class HomeScreen extends StatefulWidget {
  final bool temaFosc;
  final double midaLletra;
  final bool ocultarCompletats;
  final Future<void> Function(bool, double, bool)? guardarAjustos;
  final String? nomInicial;
  final int? objectiuInicial;

  const HomeScreen({
    super.key,
    this.temaFosc = false,
    this.midaLletra = 1.0,
    this.ocultarCompletats = false,
    this.guardarAjustos,
    this.nomInicial,
    this.objectiuInicial,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PreferenciesService preferencies = PreferenciesService();

  // Guardem les dades de l'usuari i l'estat de la pantalla
  String nom = '';
  int objectiu = 0; //Objectiu establert per l'usuari
  bool carregant = true;
  bool ocultarCompletats = false;

  // Hàbits inicials de l'aplicació
  List<Habit> habits = [
    Habit(
      id: 1,
      nom: 'Beure aigua',
      color: Colors.blue.toARGB32(),
      datesCompletades: [],
    ),
    Habit(
      id: 2,
      nom: 'Fer exercici',
      color: Colors.orange.toARGB32(),
      datesCompletades: [],
    ),
    Habit(
      id: 3,
      nom: 'Llegir',
      color: Colors.green.toARGB32(),
      datesCompletades: [],
    ),
  ];

  // Carreguem les dades quan s'inicia la pantalla
  @override
  void initState() {
    super.initState();
    carregarDades();
  }




  Future<void> carregarDades() async {
    // Carreguem el nom, l'objectiu i els hàbits guardats

    try {
      final nomGuardat = await preferencies.obtenirNom();
      // Recuperem el nom guardat

      final objectiuGuardat =
      await preferencies.obtenirObjectiu();

      // Utilitzem les dades de Benvinguda si s'han rebut
      final nomUsuari = widget.nomInicial ?? nomGuardat ?? '';
      final objectiuUsuari =
          widget.objectiuInicial ?? objectiuGuardat ?? 0;

      // Recuperem si volem ocultar els hàbits completats
      final ocultarGuardat =
      await preferencies.obtenirOcultarCompletats();

      final existeixen =
      await preferencies.existeixenHabitsGuardats();

      if (existeixen) {
        // Recuperem els hàbits, encara que la llista sigui buida
        final habitsGuardats =
        await preferencies.obtenirHabits();

        if (!mounted) return;

        setState(() {
          nom = nomUsuari;
          objectiu = objectiuUsuari;
          habits = habitsGuardats;
          ocultarCompletats = ocultarGuardat;
          carregant = false;
        });
      } else {
        // Guardem els hàbits inicials només la primera vegada
        await preferencies.guardarHabits(habits);

        if (!mounted) return;

        setState(() {
          nom = nomUsuari;
          objectiu = objectiuUsuari;
          ocultarCompletats = ocultarGuardat;
          carregant = false;
        });
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        carregant = false;
      });
        // Si hi ha algun error, deixem de carregar i mostrem un avís
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error en carregar les dades'),
        ),
      );
    }
  }


  String obtenirDataAvui() {
    // Obtenim la data actual sense l'hora

    final avui = DateTime.now();

    return '${avui.year}-${avui.month}-${avui.day}';
  }

  bool estaCompletatAvui(Habit habit) {
    // Comprovem si l'hàbit està completat avui

    return habit.datesCompletades.contains(obtenirDataAvui());
  }

  int calcularHabitsCompletats() {
    // Comptem els hàbits completats avui

    return habits.where((habit) {
      return estaCompletatAvui(habit);
    }).length;
  }

  Future<void> canviarEstatHabit(
      Habit habit,
      bool completat,
      ) async {
    // Marquem o desmarquem un hàbit del dia actual

    final dataAvui = obtenirDataAvui();

    setState(() {
      if (completat) {
        if (!habit.datesCompletades.contains(dataAvui)) {
          habit.datesCompletades.add(dataAvui);
        }
      } else {
        habit.datesCompletades.remove(dataAvui);
      }
    });

    // Guardem els canvis
    await preferencies.guardarHabits(habits);
  }

  int obtenirSeguentId() {
    // Busquem un identificador que no estigui repetit

    if (habits.isEmpty) {
      return 1;
    }

    int idMaxim = 0;

    for (final habit in habits) {
      if (habit.id > idMaxim) {
        idMaxim = habit.id;
      }
    }

    return idMaxim + 1;
  }

  Future<void> mostrarFormulariHabit({Habit? habitEditar}) async {
    // Obrim una pantalla independent per crear o editar l'hàbit.
    final resultat = await Navigator.push<ResultatEdicioHabit>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarHabitScreen(
          nomInicial: habitEditar?.nom ?? '',
          colorInicial: habitEditar?.color ?? Colors.blue.toARGB32(), //Convertim el color seleccionat en un enter per poder guardar-lo
          esNou: habitEditar == null,
        ),
      ),
    );

    // Si l'usuari cancel·la o torna enrere, no fem cap canvi.
    if (!mounted || resultat == null) return;

    setState(() {
      if (habitEditar == null) { // Si és un hàbit nou l'afegim, si no actualitzem l'existent
        habits.add(
          Habit(
            id: obtenirSeguentId(),
            nom: resultat.nom,
            color: resultat.color,
            datesCompletades: [],
          ),
        );
      } else {
        // Conservem l'identificador i les dates completades.
        habitEditar.nom = resultat.nom;
        habitEditar.color = resultat.color;
      }
    });

    // Persistim els canvis amb el servei existent.
    await preferencies.guardarHabits(habits);
  }

  Future<void> eliminarHabit(Habit habit) async {
    // Demanem confirmació abans d'eliminar un hàbit

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eliminar hàbit'),

          content: Text(
            'Estàs segur que vols eliminar "${habit.nom}"?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel·lar'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    // Si l'usuari cancel·la, no eliminem res
    if (confirmar != true || !mounted) return;

    // Eliminem l'hàbit de la llista
    setState(() {
      habits.removeWhere((element) => element.id == habit.id);
    });

    // Guardem la llista actualitzada
    await preferencies.guardarHabits(habits);
  }

  Future<void> obrirConfiguracio() async {
    // Obrim la pantalla de configuració

    final temaActual = await preferencies.obtenirTemaFosc();
    final midaActual = await preferencies.obtenirMidaLletra();
    final ocultarActual = await preferencies.obtenirOcultarCompletats();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfiguracioScreen(
          temaFosc: temaActual,
          midaLletra: midaActual,
          ocultarCompletats: ocultarActual,
          guardarAjustos: (tema, mida, ocultar) async {
            // Guardem els ajustos de l'usuari

            if (widget.guardarAjustos != null) {
              await widget.guardarAjustos!(tema, mida, ocultar);
            } else {
              await preferencies.guardarTemaFosc(tema);
              await preferencies.guardarMidaLletra(mida);
              await preferencies.guardarOcultarCompletats(ocultar);
            }

            if (!mounted) return;

            setState(() {
              ocultarCompletats = ocultar;
            });
          },
        ),
      ),
    );
  }

  Future<void> reiniciarApp() async {

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restablir App'),
          // Demanem confirmació abans d'esborrar totes les dades
          content: const Text(
              'Estas segur de que vols esborrar totes les dades? '
                  'Es perderà tot tipus de informació. '
                  'Aquesta acció no es pot desfer.'
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Cancel·lar'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Esborrar dades'),
            ),
          ],
        );
      },
    );

    if(confirmar != true || !mounted) return;

    // Eliminem totes les dades guardades de l'aplicació
    await preferencies.esborrarTotalDades();

    if(!mounted) return;

    // Tornem a la benvinguda i eliminem les pantalles anteriors
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const Benvinguda(),
      ),
          (route) => false,
    );
  }


//Tanquem la sessió i tornem a la pantalla de login
  Future<void> tancarSessio() async {
    //Tornem i eliminem les pantalles anteriors
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => const LoginPage(),
      ),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    // Construïm la pantalla principal

    final habitsCompletats = calcularHabitsCompletats();

    // Filtrem els hàbits segons la configuració
    final habitsVisibles = ocultarCompletats
        ? habits.where((habit) => !estaCompletatAvui(habit)).toList()
        : habits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Els meus hàbits'),

        actions: [
          // Botó per mostrar les estadístiques
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadístiques',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EstadistiquesScreen(
                    habits: habits,
                  ),
                ),
              );
            },
          ),

          // Botó per obrir la configuració
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuració',
            onPressed: obrirConfiguracio,
          ),

          // Botó per restablir l'aplicació
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restablir aplicació',
            onPressed: reiniciarApp,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Tancar sessió',
            onPressed: tancarSessio,
          ),
        ],
      ),

      floatingActionButton: carregant
          ? null
          : FloatingActionButton(
        onPressed: () {
          mostrarFormulariHabit();
        },
        tooltip: 'Afegir hàbit',
        child: const Icon(Icons.add),
      ),

      body: carregant
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : Column(
        children: [
          const SizedBox(height: 20),

          Text(
            'Benvingut, $nom!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          Text(
            '$habitsCompletats de $objectiu hàbits completats',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          //Mostrem els hàbits i permetem completar-los, editar-los o eliminar-los.
          Expanded(
            child: habits.isEmpty
                ? const Center(
              child: Text('Encara no tens cap hàbit creat'),
            )
                : ListView.builder(
              itemCount: habitsVisibles.length,
              itemBuilder: (context, index) {
                final habit = habitsVisibles[index];

                return TargetaHabit(
                  nom: habit.nom,
                  completat: estaCompletatAvui(habit),
                  color: Color(habit.color),

                  onChanged: (valor) {
                    if (valor != null) {
                      canviarEstatHabit(habit, valor);
                    }
                  },

                  onEditar: () {
                    mostrarFormulariHabit(habitEditar: habit);
                  },

                  onEliminar: () {
                    eliminarHabit(habit);
                  },
                );
              },
            ),
          ),

        ],
      ),
    );
  }
}
