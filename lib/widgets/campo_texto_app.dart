import 'package:flutter/material.dart';

// Component reutilitzable per als camps de text
class CampoTextoApp extends StatelessWidget {
  final String etiqueta;
  final TextEditingController controlador;
  final bool ocultar;

  const CampoTextoApp({
    super.key,
    required this.etiqueta,
    required this.controlador,
    this.ocultar = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8), //fiquem espais de 8 pixels alrededor
      child: TextField(
        controller: controlador,
        obscureText: ocultar,
        decoration: InputDecoration(
          labelText: etiqueta,
          border: const OutlineInputBorder(), //fiquem borde
        ),
      ),
    );
  }
}
