import 'package:flutter/material.dart';

class ConfiguracioScreen extends StatefulWidget {
  final bool temaFosc;
  final double midaLletra;
  final bool ocultarCompletats;
  final Future<void> Function(bool, double, bool) guardarAjustos;

  const ConfiguracioScreen({
    super.key,
    required this.temaFosc,
    required this.midaLletra,
    required this.ocultarCompletats,
    required this.guardarAjustos,
  });

  @override
  State<ConfiguracioScreen> createState() =>
      _ConfiguracioScreenState();
}

class _ConfiguracioScreenState extends State<ConfiguracioScreen> {
  late bool temaFosc;
  late double midaLletra;
  late bool ocultarCompletats;

  @override //Carreguem la configuracio que l'usuari té configurada
  void initState() {
    super.initState();
    temaFosc = widget.temaFosc;
    midaLletra = widget.midaLletra;
    ocultarCompletats = widget.ocultarCompletats;
  }

  Future<void> actualitzarAjustos() async {
    //Guardem els ajustos modificats
    await widget.guardarAjustos(
      temaFosc,
      midaLletra,
      ocultarCompletats,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuració'),
      ),

      body: ListView( //Organitzem en una llista
        padding: const EdgeInsets.all(20),
        children: [
          //Activar el tema fosc
          SwitchListTile(
            title: const Text('Tema fosc'),
            subtitle: const Text('Activar el mode fosc'),
            secondary: const Icon(Icons.dark_mode),
            value: temaFosc,
            onChanged: (valor) {
              setState(() {
                temaFosc = valor;
              });
              actualitzarAjustos();
            },
          ),

          const Divider(),

          //Control per modificar la mida de la lletra i els iconos
          const Text(
            'Mida de la lletra i les icones',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          //Ajustem la mida
          Slider(
            value: midaLletra,
            min: 0.8, //80%
            max: 1.5, //150%
            divisions: 7,
            label: '${(midaLletra * 100).round()}%',
            onChanged: (valor) {
              setState(() {
                midaLletra = valor;
              });
              actualitzarAjustos();
            },
          ),

          Text(
            'Mida seleccionada: ${(midaLletra * 100).round()}%',
          ),

          const Divider(),

          //Ocultar els hàbits completats
          SwitchListTile(
            title: const Text('Ocultar hàbits completats'),
            subtitle: const Text(
              'Amagar els hàbits que ja has completat avui',
            ),
            secondary: const Icon(Icons.visibility_off),
            value: ocultarCompletats,
            onChanged: (valor) {
              setState(() {
                ocultarCompletats = valor;
              });
              actualitzarAjustos();
            },
          ),
        ],
      ),
    );
  }
}
