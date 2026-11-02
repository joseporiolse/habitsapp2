
import 'package:flutter/material.dart';
import 'login_page.dart';
import 'registro_page.dart';

//Pantalla de benvinguda de l'aplicacio
class Benvinguda extends StatelessWidget {

  //Rebem les preferencies visuals de l'aplicacio
  final bool temaFosc;
  final double midaLletra;
  final bool ocultarCompletats;

  //Funcio que rebem de main.dart per guardar els ajustos
  final Future<void> Function(bool, double, bool) guardarAjustos;

  const Benvinguda({
    super.key,
    this.temaFosc = false,
    this.midaLletra = 1,
    this.ocultarCompletats = false,
    required this.guardarAjustos,
  });

  //Obrim la pantalla per iniciar sessio
  void obrirLogin(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LoginPage(
          guardarAjustos: guardarAjustos,
        ),
      ),
    );
  }

  //Obrim la pantalla per registrar un usuari nou
  void obrirRegistre(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RegistroPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habit App'),
      ),

      //Mostrem la pantalla de benvinguda
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                //Titol principal de l'aplicacio
                const Text(
                  'Benvingut a Habit App, on els teus hàbits sumen punts',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                //Expliquem breument l'aplicacio
                const Text(
                  'Organitza els teus hàbits, completa els teus objectius '
                      'diaris i consulta el teu progrés.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 30),

                //Boto per iniciar sessio
                ElevatedButton(
                  onPressed: () {
                    obrirLogin(context);
                  },
                  child: const Text('Iniciar sessió'),
                ),

                const SizedBox(height: 10),

                //Boto per crear un compte nou
                ElevatedButton(
                  onPressed: () {
                    obrirRegistre(context);
                  },
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
