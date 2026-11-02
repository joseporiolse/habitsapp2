
import 'package:flutter/material.dart';
import 'services/preferencies_service.dart';
import 'services/habitos_service.dart';
import 'screens/login_page.dart';
import 'services/database_service.dart';

Future<void> main() async {
  //Inicialitzem Flutter abans de carregar les dades
  WidgetsFlutterBinding.ensureInitialized();

  //Obrim la base de dades SQLite
  final db = await DatabaseService.obtenirDatabase();

  //Comprovem les taules que tenim creades
  final taules = await db.rawQuery(
    "SELECT name FROM sqlite_master WHERE type = 'table'",
  );

  debugPrint(taules.toString());

  //Sincronitzem les estadistiques de tots els habits
  //També recuperem les estadistiques dels habits antics
  await HabitosService.sincronitzarEstadistiques();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PreferenciesService preferencies = PreferenciesService();

  //Guardem la configuracio visual de l'aplicacio
  bool temaFosc = false;
  double midaLletra = 1;
  bool ocultarCompletats = false;
  bool carregant = true;

  @override
  void initState() {
    super.initState();

    //Carreguem els ajustos quan s'inicia l'aplicacio
    carregarAjustos();
  }

  //Recuperem la configuracio guardada
  Future<void> carregarAjustos() async {
    try {
      final temaGuardat =
      await preferencies.obtenirTemaFosc();

      final midaGuardada =
      await preferencies.obtenirMidaLletra();

      final ocultarGuardat =
      await preferencies.obtenirOcultarCompletats();

      if (!mounted) return;

      setState(() {
        temaFosc = temaGuardat;
        midaLletra = midaGuardada;
        ocultarCompletats = ocultarGuardat;
        carregant = false;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        carregant = false;
      });

      debugPrint('Error en carregar els ajustos: $error');
    }
  }

  //Guardem els canvis de configuracio
  Future<void> guardarAjustos(
      bool nouTema,
      double novaMida,
      bool nouOcultar,
      ) async {
    //Guardem els ajustos a SharedPreferences
    await preferencies.guardarTemaFosc(nouTema);
    await preferencies.guardarMidaLletra(novaMida);
    await preferencies.guardarOcultarCompletats(nouOcultar);

    if (!mounted) return;

    //Actualitzem la pantalla
    setState(() {
      temaFosc = nouTema;
      midaLletra = novaMida;
      ocultarCompletats = nouOcultar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit App',
      debugShowCheckedModeBanner: false,

      //Apliquem el tema clar o fosc
      themeMode: temaFosc
          ? ThemeMode.dark
          : ThemeMode.light,

      //Configuracio del tema clar
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        iconTheme: IconThemeData(
          size: 24 * midaLletra,
        ),
      ),

      //Configuracio del tema fosc
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(
          size: 24 * midaLletra,
        ),
      ),

      //Ajustem la mida dels textos de tota l'aplicacio
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(midaLletra),
          ),
          child: child ?? const SizedBox(),
        );
      },

      //Esperem que es carreguin les preferencies
      home: carregant
          ? const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      )

      //Obrim el login per identificar l'usuari
          : LoginPage(
        guardarAjustos: guardarAjustos,
      ),
    );
  }
}
