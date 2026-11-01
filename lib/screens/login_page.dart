import 'package:flutter/material.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import 'registro_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  //Obtenir les dades dels camps
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String mensajeError = '';

  //Comprovem que els camps no estiguin buits
  void iniciarSesion() {
    if (usuarioController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        mensajeError = 'Has de omplir tots els camps';
      });
      return;
    }

    setState(() {
      mensajeError = 'Usuari o contrasenya incorrectes';
    });
  }

  // Obrim la pantalla de registre
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

                // Camp per introduir l'usuari
                CampoTextoApp(
                  etiqueta: 'Usuari',
                  controlador: usuarioController,
                ),

                CampoTextoApp(
                  etiqueta: 'Contrasenya',
                  controlador: passwordController,
                  ocultar: true,
                ),

                if (mensajeError.isNotEmpty)
                  Text(
                    mensajeError,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),

                //Botó per iniciar sessió
                BotonPrincipal(
                  texto: 'Iniciar sessió',
                  accion: iniciarSesion,
                ),

                //Botó per anar al registre
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
