import 'package:flutter/material.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {

  //Obtenir les dades introduïdes
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String mensajeError = '';

  //Comprovem
  void registrarUsuario() {
    if (usuarioController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        passwordController.text.isEmpty) {
      setState(() {
        mensajeError = 'Has d\'omplir tots els camps';
      });
      return;
    }

    final DateTime fechaCreacion = DateTime.now(); //Generem data automaticament

    setState(() {
      mensajeError = 'Falta connectar el servei de registre';
    });
  }

  void volverLogin() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    usuarioController.dispose();
    correoController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registre'),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                const Text(
                  'Crear un compte',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 20),

                //Camp del nom d'usuari
                CampoTextoApp(
                  etiqueta: 'Usuari',
                  controlador: usuarioController,
                ),

                CampoTextoApp(
                  etiqueta: 'Correu electrònic',
                  controlador: correoController,
                ),

                CampoTextoApp(
                  etiqueta: 'Contrasenya',
                  controlador: passwordController,
                  ocultar: true,
                ),

                //Mostrem els errors del registre
                if (mensajeError.isNotEmpty)
                  Text(
                    mensajeError,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),

                //Botó per registrar l'usuari
                BotonPrincipal(
                  texto: 'Registrar-se',
                  accion: registrarUsuario,
                ),

                //Tornem a l'inici de sessió
                TextButton(
                  onPressed: volverLogin,
                  child: const Text('Ja tens compte? Inicia sessió'),
                ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
