import 'package:flutter/material.dart';

class BotonPrincipal extends StatelessWidget {
  final String texto;
  final VoidCallback accion;

  const BotonPrincipal({
    super.key,
    required this.texto,
    required this.accion,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8), //fiquem espais
      child: ElevatedButton( //fiquem el boto
        onPressed: accion,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.all(16), //El boto tindra espai de 16 pixels per dins
          textStyle: const TextStyle(
            fontSize: 18, //tamany de text
          ),
        ),
        child: Text(texto),
      ),
    );
  }
}
