import 'package:flutter/material.dart';

// Component reutilitzable
class DatoEstadistica extends StatelessWidget {
  final String etiqueta;
  final String valor;
  final IconData icono;
  final Color color;

  const DatoEstadistica({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.icono,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Mostrem la icona amb el color indicat
          Icon(
            icono,
            color: color,
            size: 30,
          ),

          const SizedBox(width: 10),

          // Mostrem el nom de la dada i el seu valor
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                etiqueta,
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),

              Text(
                valor,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold, //remarquem amb negreta
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
