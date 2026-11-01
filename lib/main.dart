import 'package:flutter/material.dart';
import 'services/preferencies_service.dart';
import 'screens/home_screen.dart';
import 'screens/benvinguda_screen.dart';
import 'screens/login_page.dart';

Future<void> main() async { // Inicialitzem Flutter per poder accedir a les preferències abans d'obrir l'app

  WidgetsFlutterBinding.ensureInitialized();

  final preferencies = PreferenciesService();  // Registrem cada vegada que s'obre l'aplicació

  await preferencies.registrarObertura();

  runApp(const MyApp());
}

// Comprovem si l'usuari ja ha introduït el nom i un objectiu vàlid

Future<bool> teDadesGuardades() async {
  final preferencies = PreferenciesService();

  final nom = await preferencies.obtenirNom();
  final objectiu = await preferencies.obtenirObjectiu();

  return nom != null &&
      nom.isNotEmpty &&
      objectiu != null &&
      objectiu > 0;
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final PreferenciesService preferencies = PreferenciesService();

  bool temaFosc = false;
  double midaLletra = 1.0;
  bool ocultarCompletats = false;

  late Future<bool> dadesGuardades;

  @override
  void initState() {
    super.initState();

    // Comprovem les dades inicials una sola vegada i carreguem els ajustos

    dadesGuardades = teDadesGuardades();
    carregarAjustos();
  }

  Future<void> carregarAjustos() async { // Recuperem la configuració que l'usuari havia guardat

    final temaGuardat = await preferencies.obtenirTemaFosc();
    final midaGuardada = await preferencies.obtenirMidaLletra();
    final ocultarGuardat =
    await preferencies.obtenirOcultarCompletats();

    if (!mounted) return;

    setState(() {
      temaFosc = temaGuardat;
      midaLletra = midaGuardada;
      ocultarCompletats = ocultarGuardat;
    });
  }

  Future<void> guardarAjustos(
      bool nouTema,
      double novaMida,
      bool nouOcultar,
      ) async {

    // Actualitzem la pantalla amb els nous ajustos

    if (!mounted) return;

    setState(() {
      temaFosc = nouTema;
      midaLletra = novaMida;
      ocultarCompletats = nouOcultar;
    });

    // Guardem els ajustos perquè es mantinguin en tornar a obrir l'app

    await preferencies.guardarTemaFosc(nouTema);
    await preferencies.guardarMidaLletra(novaMida);
    await preferencies.guardarOcultarCompletats(nouOcultar);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit App',
      debugShowCheckedModeBanner: false,

      // Apliquem el tema clar o fosc segons la configuració

      themeMode: temaFosc ? ThemeMode.dark : ThemeMode.light,

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
        ),
        iconTheme: IconThemeData(
          size: 24 * midaLletra,
        ),
      ),

      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(
          size: 24 * midaLletra,
        ),
      ),

      // Ajustem la mida dels textos de tota l'aplicació

      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(midaLletra),
          ),
          child: child!,
        );
      },

      // Decidim si cal mostrar la benvinguda o entrar directament a la principal

      home: FutureBuilder<bool>(
        future: dadesGuardades,
        builder: (context, resultat) {
          if (resultat.connectionState ==
              ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (resultat.hasError) {
            return const Scaffold(
              body: Center(
                child: Text('Error en carregar les dades'),
              ),
            );
          }

          if (resultat.data == true) {
            return HomeScreen(
              temaFosc: temaFosc,
              midaLletra: midaLletra,
              ocultarCompletats: ocultarCompletats,
              guardarAjustos: guardarAjustos,
            );
          }

          //Si no tenim dades guardades, mostrem la pantalla de login
          return const LoginPage();
        },
      ),
    );
  }
}
