import 'package:flutter/material.dart';
import '../widgets/campo_texto_app.dart';
import '../widgets/boton_principal.dart';

//Dades que retornem a la pantalla principal quan guardem un hàbit
class ResultatEdicioHabit {
  final String nom;
  final int color;

  const ResultatEdicioHabit({
    required this.nom,
    required this.color,
  });
}

class EditarHabitScreen extends StatefulWidget { //Rebem el nom i el color inicials, i indiquem si estem creant un hàbit nou
  final String nomInicial;
  final int colorInicial;
  final bool esNou;

  const EditarHabitScreen({
    super.key,
    required this.nomInicial,
    required this.colorInicial,
    this.esNou = false,
  });

  @override
  State<EditarHabitScreen> createState() => _EditarHabitScreenState();
}

class _EditarHabitScreenState extends State<EditarHabitScreen> {
  late final TextEditingController controladorNom;
  late Color colorSeleccionat;

  final List<Color> colorsDisponibles = [
    Colors.blue,
    Colors.green,
    Colors.orange,
  ];

  //Carreguem el nom i el color actuals perquè es puguin modificar
  @override
  void initState() {
    super.initState();
    controladorNom = TextEditingController(text: widget.nomInicial);
    colorSeleccionat = Color(widget.colorInicial);
  }

  @override
  void dispose() {
    controladorNom.dispose();
    super.dispose();
  }

  String obtenirNomColor(Color color) { //Convertim el color seleccionat en un nom per mostrar-lo a la pantalla
    if (color.toARGB32() == Colors.blue.toARGB32()) return 'Blau';
    if (color.toARGB32() == Colors.green.toARGB32()) return 'Verd';
    if (color.toARGB32() == Colors.orange.toARGB32()) return 'Taronja';
    if (color.toARGB32() == Colors.red.toARGB32()) return 'Vermell';
    if (color.toARGB32() == Colors.purple.toARGB32()) return 'Lila';
    return 'Personalitzat';
  }

  void guardarHabit() { //Comprovem que el nom sigui vàlid i retornem les dades modificades
    final nom = controladorNom.text.trim();
    if (nom.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Introdueix un nom per a l\'hàbit')),
      );
      return;
    }

    Navigator.pop(
      context,
      ResultatEdicioHabit(nom: nom, color: colorSeleccionat.toARGB32()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.esNou ? 'Afegir hàbit' : 'Editar hàbit'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Nom de l\'hàbit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            // Utilitzem el component reutilitzable per introduir el nom
            CampoTextoApp(
              etiqueta: 'Nom de l\'hàbit',
              controlador: controladorNom,
            ),
            const SizedBox(height: 30),
            const Text(
              'Selecciona un color',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            Row( //Mostrem els colors disponibles i marquem el que està seleccionat
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: colorsDisponibles.map((color) {
                final seleccionat =
                    colorSeleccionat.toARGB32() == color.toARGB32();
                return InkWell(
                  onTap: () => setState(() => colorSeleccionat = color),
                  borderRadius: BorderRadius.circular(50),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: color,
                    child: seleccionat
                        ? const Icon(Icons.check, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'Color seleccionat: ${obtenirNomColor(colorSeleccionat)}',
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 40),

            Row( //Permetem cancel·lar o guardar les dades de l'hàbit
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel·lar'),
                ),
                // Utilitzem el botó reutilitzable per guardar l'hàbit
                BotonPrincipal(
                  texto: 'Guardar',
                  accion: guardarHabit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
