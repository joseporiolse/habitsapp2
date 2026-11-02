import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/database_service.dart';
import '../models/habitos.dart';
import '../services/preferencies_service.dart';
import '../services/usuarios_service.dart';
import '../services/habitos_service.dart';
import 'estadistiques_screen.dart';
import 'configuracio_screen.dart';
import 'editar_habit_screen.dart';
import 'administracion_page.dart';
import 'login_page.dart';
import '../widgets/targeta_habit.dart';

class HomeScreen extends StatefulWidget {

  //Identifiquem l'usuari que ha iniciat sessio
  final int idUsuari;
  final String rol;

  //Configuracio visual de l'aplicacio
  final bool temaFosc;
  final double midaLletra;
  final bool ocultarCompletats;

  //Funcio que rebem de main.dart per guardar els ajustos
  final Future<void> Function(bool, double, bool) guardarAjustos;

  final String? nomInicial;
  final int? objectiuInicial;

  const HomeScreen({
    super.key,
    required this.idUsuari,
    required this.rol,
    this.temaFosc = false,
    this.midaLletra = 1,
    this.ocultarCompletats = false,
    required this.guardarAjustos,
    this.nomInicial,
    this.objectiuInicial,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {

  final PreferenciesService preferencies = PreferenciesService();

  //Guardem les dades de l'usuari i l'estat de la pantalla
  String nom = '';
  int objectiu = 0;
  bool carregant = true;
  bool ocultarCompletats = false;

  //Els habits es recuperen de SQLite
  List<Habit> habits = [];

  @override
  void initState() {
    super.initState();

    //Carreguem la configuracio inicial
    ocultarCompletats = widget.ocultarCompletats;

    carregarDades();
  }

  //Mostrem missatges a l'usuari
  void mostrarMissatge(String missatge) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(missatge),
      ),
    );
  }

  //Convertim les dades de SQLite en objectes Habit
  Habit convertirHabit(Map<String, Object?> dades) {
    List<String> dates = [];

    //Les dates es guarden en format JSON a SQLite
    final valorDates = dades['fechas_completadas'];

    if (valorDates is String && valorDates.isNotEmpty) {
      final llista = jsonDecode(valorDates) as List<dynamic>;

      dates = llista.map((data) {
        //Conservem nomes la data per comprovar el dia
        return data.toString().split('T').first;
      }).toList();
    }

    return Habit(
      id: dades['id_habit'] as int,
      nom: dades['nombre'] as String,
      color: dades['color'] as int,
      datesCompletades: dates,
    );
  }

  //Carreguem les dades de l'usuari des de SQLite
  Future<void> carregarDades() async {
    if (mounted) {
      setState(() {
        carregant = true;
      });
    }

    try {
      //Busquem l'usuari que ha iniciat sessio
      final usuari = await UsuariosService.obtenirUsuariPerId(
        widget.idUsuari,
      );

      if (usuari == null) {
        if (!mounted) return;

        mostrarMissatge('No s\'ha trobat l\'usuari');
        await tancarSessio();
        return;
      }

      //Recuperem els habits que pertanyen a aquest usuari
      final habitsGuardats = await HabitosService.obtenirHabits(
        widget.idUsuari,
      );

      //Convertim els registres en objectes Habit
      List<Habit> llistaHabits = [];

      for (final dades in habitsGuardats) {
        llistaHabits.add(convertirHabit(dades));
      }

      //Recuperem si hem d'ocultar els habits completats
      final ocultarGuardat =
      await preferencies.obtenirOcultarCompletats();

      if (!mounted) return;

      setState(() {
        nom = usuari['nombre']?.toString() ?? '';
        objectiu = usuari['objetivo_diario'] as int? ?? 3;
        habits = llistaHabits;
        ocultarCompletats = ocultarGuardat;
        carregant = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        carregant = false;
      });

      mostrarMissatge('Error en carregar les dades');
    }
  }

  //Obtenim la data actual sense l'hora
  String obtenirDataAvui() {
    final avui = DateTime.now();

    final mes = avui.month.toString().padLeft(2, '0');
    final dia = avui.day.toString().padLeft(2, '0');

    return '${avui.year}-$mes-$dia';
  }

  //Comprovem si l'habit esta completat avui
  bool estaCompletatAvui(Habit habit) {
    return habit.datesCompletades.contains(
      obtenirDataAvui(),
    );
  }

  //Comptem els habits completats avui
  int calcularHabitsCompletats() {
    return habits.where((habit) {
      return estaCompletatAvui(habit);
    }).length;
  }

  //Marquem o desmarquem un habit a SQLite
  Future<void> canviarEstatHabit(
      Habit habit,
      bool completat,
      ) async {
    try {
      if (completat) {
        //Guardem la data en que completem l'habit
        await HabitosService.completarHabit(
          habit.id,
          widget.idUsuari,
        );
      } else {
        //Eliminem la marca del dia actual
        await HabitosService.desmarcarHabit(
          habit.id,
          widget.idUsuari,
        );
      }

      //Tornem a carregar els habits actualitzats
      await carregarDades();
    } catch (error) {
      mostrarMissatge('Error en actualitzar l\'hàbit');
    }
  }

  //Obrim la pantalla per crear o editar habits
  Future<void> mostrarFormulariHabit({
    Habit? habitEditar,
  }) async {
    final resultat = await Navigator.push<ResultatEdicioHabit>(
      context,
      MaterialPageRoute(
        builder: (context) => EditarHabitScreen(
          nomInicial: habitEditar?.nom ?? '',
          colorInicial:
          habitEditar?.color ?? Colors.blue.toARGB32(),
          esNou: habitEditar == null,
        ),
      ),
    );

    //Si cancel·lem, no fem cap canvi
    if (!mounted || resultat == null) return;

    try {
      if (habitEditar == null) {
        //Creem un habit nou per a l'usuari connectat
        await HabitosService.crearHabit(
          widget.idUsuari,
          resultat.nom,
          resultat.color,
        );
      } else {
        //Modifiquem nomes els habits del nostre usuari
        await HabitosService.editarHabit(
          habitEditar.id,
          widget.idUsuari,
          resultat.nom,
          resultat.color,
        );
      }

      //Actualitzem la llista de la pantalla
      await carregarDades();
    } catch (error) {
      mostrarMissatge('Error en guardar l\'hàbit');
    }
  }

  //Eliminem un habit de SQLite
  Future<void> eliminarHabit(Habit habit) async {
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

    if (confirmar != true || !mounted) return;

    try {
      //Eliminem l'habit del nostre usuari
      await HabitosService.eliminarHabit(
        habit.id,
        widget.idUsuari,
      );

      //Actualitzem la llista
      await carregarDades();

      mostrarMissatge('Hàbit eliminat correctament');
    } catch (error) {
      mostrarMissatge('Error en eliminar l\'hàbit');
    }
  }

  //Obrim la pantalla de configuracio
  Future<void> obrirConfiguracio() async {
    //Recuperem els ajustos guardats
    final temaActual = await preferencies.obtenirTemaFosc();
    final midaActual = await preferencies.obtenirMidaLletra();
    final ocultarActual =
    await preferencies.obtenirOcultarCompletats();

    if (!mounted) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ConfiguracioScreen(
          temaFosc: temaActual,
          midaLletra: midaActual,
          ocultarCompletats: ocultarActual,

          //Enviem els canvis a MyApp per actualitzar tota l'aplicacio
          guardarAjustos: (tema, mida, ocultar) async {
            await widget.guardarAjustos(
              tema,
              mida,
              ocultar,
            );

            if (!mounted) return;

            //Actualitzem els habits visibles
            setState(() {
              ocultarCompletats = ocultar;
            });
          },
        ),
      ),
    );

    //Actualitzem les dades quan tornem
    if (mounted) {
      await carregarDades();
    }
  }

  //Obrim el panell d'administracio
  Future<void> obrirAdministracio() async {
    //Comprovem el rol real de l'usuari
    final esAdmin = await UsuariosService.esAdministrador(
      widget.idUsuari,
    );

    if (!mounted) return;

    if (!esAdmin) {
      mostrarMissatge('No tens permisos d\'administrador');
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AdministracionPage(
          idAdministrador: widget.idUsuari,
        ),
      ),
    );

    //Actualitzem els habits en tornar del panell
    if (mounted) {
      await carregarDades();
    }
  }

  //Restablim tota l'aplicacio com si fos nova
  Future<void> reiniciarApp() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restablir aplicació'),
          content: const Text(
            'Estàs segur que vols restablir l\'aplicació? '
                'S\'eliminaran tots els usuaris, hàbits, estadístiques '
                'i preferències. Aquesta acció no es pot desfer.',
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
              child: const Text('Restablir'),
            ),
          ],
        );
      },
    );

    //Si cancel·lem, no eliminem res
    if (confirmar != true || !mounted) return;

    try {
      //Restablim el tema, la lletra i els habits visibles
      await widget.guardarAjustos(false, 1, false);

      //Eliminem totes les preferencies i estadistiques d'apertures
      await preferencies.esborrarTotalDades();

      //Eliminem tots els usuaris, habits i estadistiques de SQLite
      await DatabaseService.restablirBaseDades();

      if (!mounted) return;

      //Tornem al login sense conservar les pantalles anteriors
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (context) => LoginPage(
            guardarAjustos: widget.guardarAjustos,
          ),
        ),
            (route) => false,
      );

    } catch (error) {
      if (!mounted) return;

      mostrarMissatge('Error en restablir l\'aplicació');
    }
  }

  //Tanquem la sessio i tornem al login
  Future<void> tancarSessio() async {
    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          guardarAjustos: widget.guardarAjustos,
        ),
      ),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    //Comptem els habits completats avui
    final habitsCompletats = calcularHabitsCompletats();

    //Filtrem els habits segons la configuracio
    final habitsVisibles = ocultarCompletats
        ? habits.where((habit) {
      return !estaCompletatAvui(habit);
    }).toList()
        : habits;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Els meus hàbits'),
        actions: [

          //Mostrem el boto d'administracio nomes als administradors
          if (widget.rol == 'administrador')
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Administració',
              onPressed: obrirAdministracio,
            ),

          //Obrim les estadistiques
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Estadístiques',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EstadistiquesScreen(
                    idUsuari: widget.idUsuari,
                    habits: habits,
                  ),
                ),
              );
            },
          ),

          //Obrim la configuracio
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuració',
            onPressed: obrirConfiguracio,
          ),

          //Restablim la configuracio
          IconButton(
            icon: const Icon(Icons.restart_alt),
            tooltip: 'Restablir configuració',
            onPressed: reiniciarApp,
          ),

          //Tanquem la sessio
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Tancar sessió',
            onPressed: tancarSessio,
          ),
        ],
      ),

      //Boto per crear habits
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

          //Mostrem el nom de l'usuari
          Text(
            'Benvingut, $nom!',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          //Mostrem els habits completats i l'objectiu
          Text(
            '$habitsCompletats de $objectiu hàbits completats',
            style: const TextStyle(fontSize: 18),
          ),

          const SizedBox(height: 20),

          //Mostrem els habits de l'usuari
          Expanded(
            child: habits.isEmpty
                ? const Center(
              child: Text(
                'Encara no tens cap hàbit creat',
              ),
            )
                : habitsVisibles.isEmpty
                ? const Center(
              child: Text(
                'Tots els hàbits estan completats',
              ),
            )
                : ListView.builder(
              itemCount: habitsVisibles.length,
              itemBuilder: (context, index) {
                final habit = habitsVisibles[index];

                return TargetaHabit(
                  nom: habit.nom,
                  completat: estaCompletatAvui(habit),
                  color: Color(habit.color),

                  //Marquem o desmarquem l'habit
                  onChanged: (valor) {
                    if (valor != null) {
                      canviarEstatHabit(
                        habit,
                        valor,
                      );
                    }
                  },

                  //Editem l'habit
                  onEditar: () {
                    mostrarFormulariHabit(
                      habitEditar: habit,
                    );
                  },

                  //Eliminem l'habit
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
