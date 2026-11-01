import 'package:flutter/material.dart';

class CampoTextoApp extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final bool ocultar;
  final TextInputType tipusTeclat; // Tipus de teclat que volem mostrar

  const CampoTextoApp({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.ocultar = false,
    this.tipusTeclat = TextInputType.text, // Per defecte mostrem el teclat de text
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8), //Fiquem espais de 8 píxels al voltant
      child: TextField(
        controller: controlador,
        obscureText: ocultar,
        keyboardType: tipusTeclat, //Mostrem el teclat segons el tipus indicat
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(), //Fiquem borde
        ),
      ),
    );
  }
}
