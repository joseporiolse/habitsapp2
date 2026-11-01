import 'package:flutter/material.dart';

// Pantalla exclusiva per a l'administrador
class AdministracionPage extends StatelessWidget {
  const AdministracionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administració'),
      ),
      body: const Center(
        child: Text('Panell d\'administració'),
      ),
    );
  }
}
