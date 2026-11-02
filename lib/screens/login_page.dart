
import 'package:flutter/material.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import '../services/usuarios_service.dart';
import '../services/preferencies_service.dart';
import 'registro_page.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {

  //Funció que rebem de main.dart per actualitzar els ajustos
  final Future<void> Function(bool, double, bool) guardarAjustos;

  const LoginPage({
    super.key,
    required this.guardarAjustos,
  });

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //Obtenim les dades dels camps
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String mensajeError = '';
  bool iniciandoSesion = false;

  //Comprovem les dades i iniciem sessio
  Future<void> iniciarSesion() async {

    //Comprovem que els camps no estiguin buits
    if (usuarioController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        mensajeError = 'Has d\'omplir tots els camps';
      });
      return;
    }

    //Evitem iniciar sessio dues vegades
    if (iniciandoSesion) return;

    setState(() {
      iniciandoSesion = true;
      mensajeError = '';
    });

    try {

      //Busquem l'usuari a la base de dades SQLite
      final usuari = await UsuariosService.iniciarSessio(
        usuarioController.text.trim(),
        passwordController.text,
      );

      if (!mounted) return;

      //Si les dades no son correctes mostrem un error
      if (usuari == null) {
        setState(() {
          mensajeError = 'Usuari o contrasenya incorrectes';
        });
        return;
      }

      //Obtenim l'identificador i el rol de l'usuari
      final int idUsuari = usuari['id_usuario'] as int;
      final String rol = usuari['rol'] as String;

      //Registrem una apertura nomes per a aquest usuari
      final preferencies = PreferenciesService();
      await preferencies.registrarObertura(idUsuari);

      //Recuperem els ajustos guardats
      final bool temaFosc = await preferencies.obtenirTemaFosc();
      final double midaLletra = await preferencies.obtenirMidaLletra();
      final bool ocultarCompletats =
      await preferencies.obtenirOcultarCompletats();

      if (!mounted) return;

      //Obrim la pantalla principal i passem la funcio dels ajustos
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(
            idUsuari: idUsuari,
            rol: rol,
            temaFosc: temaFosc,
            midaLletra: midaLletra,
            ocultarCompletats: ocultarCompletats,
            guardarAjustos: widget.guardarAjustos,
          ),
        ),
      );

    } catch (e) {
      if (!mounted) return;

      //Mostrem un error si falla el login
      setState(() {
        mensajeError = 'Error en iniciar sessió';
      });
    } finally {
      if (mounted) {
        setState(() {
          iniciandoSesion = false;
        });
      }
    }
  }

  //Obrim la pantalla de registre
  void abrirRegistro() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistroPage(),
      ),
    );
  }

  @override
  void dispose() {
    usuarioController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sessió'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  'Benvingut!',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                //Camp per introduir l'usuari
                CampoTextoApp(
                  etiqueta: 'Usuari',
                  controlador: usuarioController,
                ),

                //Camp per introduir la contrasenya
                CampoTextoApp(
                  etiqueta: 'Contrasenya',
                  controlador: passwordController,
                  ocultar: true,
                ),

                //Mostrem els errors del login
                if (mensajeError.isNotEmpty)
                  Text(
                    mensajeError,
                    style: const TextStyle(
                      color: Colors.red,
                    ),
                  ),

                const SizedBox(height: 10),

                //Boto per iniciar sessio
                BotonPrincipal(
                  texto: iniciandoSesion
                      ? 'Iniciant sessió...'
                      : 'Iniciar sessió',
                  accion: iniciarSesion,
                ),

                //Boto per anar al registre
                TextButton(
                  onPressed: abrirRegistro,
                  child: const Text('Crear un compte'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
