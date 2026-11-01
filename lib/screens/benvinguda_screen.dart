import 'package:flutter/material.dart';
import '../services/preferencies_service.dart';
import 'home_screen.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

class Benvinguda extends StatefulWidget { //Rebem les preferencies actuals per a mantenir la configuració de l'aplicació
  final bool temaFosc;
  final double midaLletra;
  final bool ocultarCompletats;
  final Future<void> Function(bool, double, bool)? guardarAjustos;

  const Benvinguda({
    super.key,
    this.temaFosc = false,
    this.midaLletra = 1.0,
    this.ocultarCompletats = false,
    this.guardarAjustos,
  });

  @override
  State<Benvinguda> createState() => _BenvingudaState();
}

class _BenvingudaState extends State<Benvinguda> {
  //Controladors per obtenir el text que introdueix l'usuari
  final TextEditingController nomController = TextEditingController();
  final TextEditingController objectiuController = TextEditingController();

  final PreferenciesService preferencies = PreferenciesService();

  Future<void> guardarDades() async {
    final String nom = nomController.text.trim();
    final int? objectiu = int.tryParse(objectiuController.text.trim());

    if (nom.isEmpty || objectiu == null || objectiu <= 0) { //nom no estigui buit i que l'objectiu sigui un número positiu
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introdueix un nom i un número vàlids'),
        ),
      );
      return;
    }

    //Guardem les dades per a no introduirles cada vegada
    await preferencies.guardarNom(nom);
    await preferencies.guardarObjectiu(objectiu);

    if (!mounted) return;

    Navigator.pushReplacement( //Obrim la pantalla principal amb les dades introduïdes i substituïm la benvinguda
      context,
      MaterialPageRoute(
        builder: (context) => HomeScreen(
          nomInicial: nom,
          objectiuInicial: objectiu,
          temaFosc: widget.temaFosc,
          midaLletra: widget.midaLletra,
          ocultarCompletats: widget.ocultarCompletats,
          guardarAjustos: widget.guardarAjustos,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold( //Pantalla de benvinguda amb una barra superior i el contingut principal
      appBar: AppBar(
        title: const Text('Habit App'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: SingleChildScrollView( //Desplacem el contingut si no hi cap tot
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Benvingut a Habit App, on els teus hàbits sumen punts',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 30),
                // Camp reutilitzable per introduir el nom
                CampoTextoApp(
                  etiqueta: 'Nom',
                  controlador: nomController,
                ),
                const SizedBox(height: 20),
                //Introduir l'objectiu diari
                CampoTextoApp(
                  etiqueta: 'Objectiu diari',
                  controlador: objectiuController,
                  tipusTeclat: TextInputType.number,
                ),
                const SizedBox(height: 30),
                //Botó que comprova i guarda les dades
                BotonPrincipal(
                  texto: 'Continuar',
                  accion: guardarDades,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() { //Lliberem els controladors quan es tanca aquesta pantalla
    nomController.dispose();
    objectiuController.dispose();
    super.dispose();
  }
}
