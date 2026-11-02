
import 'package:flutter/material.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';
import '../services/usuarios_service.dart';

class RegistroPage extends StatefulWidget {
  const RegistroPage({super.key});

  @override
  State<RegistroPage> createState() => _RegistroPageState();
}

class _RegistroPageState extends State<RegistroPage> {

  //Obtenim les dades que introdueix l'usuari
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController nombreController = TextEditingController();
  final TextEditingController apellidosController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController objetivoController = TextEditingController();

  String mensajeError = '';
  bool registrando = false;

  //Comprovem les dades i registrem l'usuari a la base de dades
  Future<void> registrarUsuario() async {

    //Comprovem que tots els camps estiguin omplerts
    if (usuarioController.text.trim().isEmpty ||
        nombreController.text.trim().isEmpty ||
        apellidosController.text.trim().isEmpty ||
        correoController.text.trim().isEmpty ||
        passwordController.text.isEmpty ||
        objetivoController.text.trim().isEmpty) {
      setState(() {
        mensajeError = 'Has d\'omplir tots els camps';
      });
      return;
    }

    //Convertim l'objectiu a un numero
    int? objetivo = int.tryParse(objetivoController.text.trim());

    //Comprovem que l'objectiu sigui correcte
    if (objetivo == null || objetivo <= 0) {
      setState(() {
        mensajeError = 'L\'objectiu ha de ser un número més gran que 0';
      });
      return;
    }

    //Evitem registrar dues vegades mentre es guarden les dades
    if (registrando) return;

    setState(() {
      registrando = true;
      mensajeError = '';
    });

    try {
      //Guardem l'usuari i el seu objectiu a la base de dades
      await UsuariosService.registrarUsuari(
        usuarioController.text.trim(),
        nombreController.text.trim(),
        apellidosController.text.trim(),
        correoController.text.trim(),
        passwordController.text,
        objetivo,
      );

      if (!mounted) return;

      //Mostrem un missatge quan el registre s'ha fet correctament
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Usuari registrat correctament'),
        ),
      );

      //Tornem al login per iniciar sessio
      Navigator.pop(context);

    } catch (e) {
      if (!mounted) return;

      //Mostrem un error si no s'ha pogut registrar
      setState(() {
        mensajeError = 'No s\'ha pogut registrar l\'usuari';
      });
    } finally {
      if (mounted) {
        setState(() {
          registrando = false;
        });
      }
    }
  }

  //Tornem a la pantalla de login
  void volverLogin() {
    Navigator.pop(context);
  }

  @override
  void dispose() {
    usuarioController.dispose();
    nombreController.dispose();
    apellidosController.dispose();
    correoController.dispose();
    passwordController.dispose();
    objetivoController.dispose();
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

                //Camp del nom
                CampoTextoApp(
                  etiqueta: 'Nom',
                  controlador: nombreController,
                ),

                //Camp dels cognoms
                CampoTextoApp(
                  etiqueta: 'Cognoms',
                  controlador: apellidosController,
                ),

                //Camp del correu electronic
                CampoTextoApp(
                  etiqueta: 'Correu electrònic',
                  controlador: correoController,
                ),

                //Camp de la contrasenya
                CampoTextoApp(
                  etiqueta: 'Contrasenya',
                  controlador: passwordController,
                  ocultar: true,
                ),

                //Camp per indicar quants habits vol completar cada dia
                CampoTextoApp(
                  etiqueta: 'Objectiu diari d\'hàbits',
                  controlador: objetivoController,
                  tipusTeclat: TextInputType.number,
                ),

                //Mostrem els errors del registre
                if (mensajeError.isNotEmpty)
                  Text(
                    mensajeError,
                    style: const TextStyle(color: Colors.red),
                  ),

                const SizedBox(height: 10),

                //Boto per registrar l'usuari
                BotonPrincipal(
                  texto: registrando ? 'Registrant...' : 'Registrar-se',
                  accion: registrarUsuario,
                ),

                //Tornem a l'inici de sessio
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
