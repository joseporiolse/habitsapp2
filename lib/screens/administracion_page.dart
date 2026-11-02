import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/usuarios_service.dart';
import '../services/database_service.dart';
import '../services/habitos_service.dart';
import '../services/estadisticas_service.dart';

//Pantalla exclusiva per a l'administrador
class AdministracionPage extends StatefulWidget {
  final int idAdministrador;

  const AdministracionPage({
    super.key,
    required this.idAdministrador,
  });

  @override
  State<AdministracionPage> createState() => _AdministracionPageState();
}

class _AdministracionPageState extends State<AdministracionPage> {

  int apartat = 0;
  bool carregant = true;
  bool autoritzat = false;

  List<Map<String, Object?>> usuaris = [];
  List<Map<String, Object?>> habits = [];
  List<Map<String, Object?>> estadistiques = [];

  @override
  void initState() {
    super.initState();
    carregarDades();
  }

  //Comprovem si l'usuari es administrador i carreguem les dades
  Future<void> carregarDades() async {
    try {
      bool admin = await UsuariosService.esAdministrador(
        widget.idAdministrador,
      );

      if (!admin) {
        if (mounted) {
          setState(() {
            autoritzat = false;
            carregant = false;
          });
        }
        return;
      }

      final llistaUsuaris =
      await UsuariosService.obtenirTotsUsuaris();
      final llistaHabits =
      await HabitosService.obtenirTotsHabits();
      final llistaEstadistiques =
      await EstadisticasService.obtenirTotesEstadistiques();

      if (!mounted) return;

      setState(() {
        autoritzat = true;
        carregant = false;
        usuaris = llistaUsuaris;
        habits = llistaHabits;
        estadistiques = llistaEstadistiques;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        carregant = false;
      });
      mostrarMissatge('Error en carregar les dades');
    }
  }

  //Mostrem un missatge a la pantalla
  void mostrarMissatge(String missatge) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(missatge)),
    );
  }

  //Canviem el rol d'un usuari directament a SQLite
  Future<void> canviarRol(int idUsuari, String nouRol) async {
    if (nouRol != 'administrador' && nouRol != 'usuario') {
      throw Exception('Rol no valid');
    }

    //Comprovem els permisos abans de modificar la base de dades
    final esAdmin = await UsuariosService.esAdministrador(
      widget.idAdministrador,
    );
    if (!esAdmin) throw Exception('Acces denegat');

    final db = await DatabaseService.obtenirDatabase();
    await db.update(
      'usuarios',
      {'rol': nouRol},
      where: 'id_usuario = ?',
      whereArgs: [idUsuari],
    );
  }

  //Obrim un formulari per crear o editar un usuari
  Future<void> formulariUsuari([
    Map<String, Object?>? usuari,
  ]) async {
    final nomUsuari = TextEditingController(
      text: usuari?['usuario']?.toString() ?? '',
    );
    final nom = TextEditingController(
      text: usuari?['nombre']?.toString() ?? '',
    );
    final cognoms = TextEditingController(
      text: usuari?['apellidos']?.toString() ?? '',
    );
    final email = TextEditingController(
      text: usuari?['email']?.toString() ?? '',
    );
    final contrasena = TextEditingController();
    final objectiu = TextEditingController(
      text: usuari?['objetivo_diario']?.toString() ?? '3',
    );

    String rolSeleccionat = usuari?['rol'] == 'administrador'
        ? 'administrador'
        : 'usuario';

    //El formulari retorna les dades; el guardat es fa fora del dialeg
    final dades = await showDialog<Map<String, Object>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualitzarDialeg) {
            return AlertDialog(
              title: Text(usuari == null ? 'Crear usuari' : 'Editar usuari'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nomUsuari,
                      decoration: const InputDecoration(labelText: 'Usuari'),
                    ),
                    TextField(
                      controller: nom,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    TextField(
                      controller: cognoms,
                      decoration: const InputDecoration(labelText: 'Cognoms'),
                    ),
                    TextField(
                      controller: email,
                      decoration: const InputDecoration(
                        labelText: 'Correu electronic',
                      ),
                    ),
                    //En crear es obligatoria; en editar es opcional.
                    TextField(
                      controller: contrasena,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: usuari == null
                            ? 'Contrasenya'
                            : 'Nova contrasenya (opcional)',
                      ),
                    ),
                    TextField(
                      controller: objectiu,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Objectiu diari',
                      ),
                    ),
                    //L'administrador pot canviar el rol de qualsevol usuari
                    DropdownButtonFormField<String>(
                      value: rolSeleccionat,
                      decoration: const InputDecoration(labelText: 'Rol'),
                      items: const [
                        DropdownMenuItem(
                          value: 'usuario',
                          child: Text('Usuari'),
                        ),
                        DropdownMenuItem(
                          value: 'administrador',
                          child: Text('Administrador'),
                        ),
                      ],
                      onChanged: (valor) {
                        if (valor != null) {
                          actualitzarDialeg(() {
                            rolSeleccionat = valor;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel·lar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final numero = int.tryParse(objectiu.text);
                    if (nomUsuari.text.trim().isEmpty ||
                        nom.text.trim().isEmpty ||
                        cognoms.text.trim().isEmpty ||
                        email.text.trim().isEmpty ||
                        numero == null ||
                        numero <= 0 ||
                        (usuari == null && contrasena.text.isEmpty)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Revisa els camps')),
                      );
                      return;
                    }

                    Navigator.pop(dialogContext, <String, Object>{
                      'usuario': nomUsuari.text.trim(),
                      'nombre': nom.text.trim(),
                      'apellidos': cognoms.text.trim(),
                      'email': email.text.trim(),
                      'contrasena': contrasena.text,
                      'objetivo': numero,
                      'rol': rolSeleccionat,
                    });
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    //Esperem que acabi l'animacio abans d'alliberar els controladors
    await Future<void>.delayed(const Duration(milliseconds: 350));
    nomUsuari.dispose();
    nom.dispose();
    cognoms.dispose();
    email.dispose();
    contrasena.dispose();
    objectiu.dispose();

    if (dades == null || !mounted) return;

    try {
      if (!await UsuariosService.esAdministrador(widget.idAdministrador)) {
        mostrarMissatge('Acces denegat');
        return;
      }

      final rol = dades['rol'] as String;
      if (usuari == null) {
        //Creem l'usuari i despres li assignem el rol seleccionat
        await UsuariosService.registrarUsuari(
          dades['usuario'] as String,
          dades['nombre'] as String,
          dades['apellidos'] as String,
          dades['email'] as String,
          dades['contrasena'] as String,
          dades['objetivo'] as int,
        );
        final creat = await UsuariosService.obtenirUsuari(
          dades['usuario'] as String,
        );
        if (creat == null) throw Exception('Usuari no trobat');
        await canviarRol(creat['id_usuario'] as int, rol);
      } else {
        final id = usuari['id_usuario'] as int;
        await UsuariosService.editarUsuari(
          id,
          dades['usuario'] as String,
          dades['nombre'] as String,
          dades['apellidos'] as String,
          dades['email'] as String,
        );
        await UsuariosService.editarObjetivo(id, dades['objetivo'] as int);
        await canviarRol(id, rol);
        //Nomes canviem la contrasenya si se n'ha escrit una de nova.
        final novaContrasena = dades['contrasena'] as String;
        if (novaContrasena.isNotEmpty) {
          if (!await UsuariosService.esAdministrador(widget.idAdministrador)) {
            throw Exception('Acces denegat');
          }
          final db = await DatabaseService.obtenirDatabase();
          await db.update(
            'usuarios',
            {'contrasena': novaContrasena},
            where: 'id_usuario = ?',
            whereArgs: [id],
          );
        }
      }

      await carregarDades();
      mostrarMissatge('Usuari guardat correctament');
    } catch (error) {
      mostrarMissatge('Error en guardar l\'usuari: $error');
    }
  }

  //Eliminem un usuari despres de confirmar
  Future<void> eliminarUsuari(int id) async {
    bool? confirmar = await confirmarEliminacio();

    if (confirmar != true) return;

    if (id == widget.idAdministrador) {
      mostrarMissatge('No pots eliminar el teu propi compte');
      return;
    }

    try {
      if (!await UsuariosService.esAdministrador(
        widget.idAdministrador,
      )) return;

      await UsuariosService.eliminarUsuari(id);
      await carregarDades();
      mostrarMissatge('Usuari eliminat');
    } catch (e) {
      mostrarMissatge('Error en eliminar l\'usuari');
    }
  }

  //Mostrem la darrera data i hora registrada de l'habit
  String obtenirDataHoraHabit(Map<String, Object?> habit) {
    final valor = habit['fechas_completadas'];
    if (valor == null || valor.toString().isEmpty) {
      return 'Encara no s\'ha completat';
    }

    try {
      final dates = jsonDecode(valor.toString()) as List<dynamic>;
      if (dates.isEmpty) return 'Encara no s\'ha completat';

      final valides = <DateTime>[];
      for (final data in dates) {
        final convertida = DateTime.tryParse(data.toString());
        if (convertida != null) valides.add(convertida);
      }
      if (valides.isEmpty) return 'Data no disponible';
      valides.sort();
      final ultima = valides.last;
      final dia = ultima.day.toString().padLeft(2, '0');
      final mes = ultima.month.toString().padLeft(2, '0');
      final hora = ultima.hour.toString().padLeft(2, '0');
      final minut = ultima.minute.toString().padLeft(2, '0');
      final textOriginal = dates.last.toString();
      //No inventem una hora quan SQLite nomes guarda el dia
      final teHora = textOriginal.contains('T') || textOriginal.contains(' ');
      return teHora
          ? '$dia/$mes/${ultima.year} $hora:$minut'
          : '$dia/$mes/${ultima.year} (hora no registrada)';
    } catch (e) {
      return 'Data no disponible';
    }
  }

  //Creem o editem un habit de qualsevol usuari
  Future<void> formulariHabit([
    Map<String, Object?>? habit,
  ]) async {
    if (usuaris.isEmpty) {
      mostrarMissatge('Primer has de crear un usuari');
      return;
    }

    final nom = TextEditingController(
      text: habit?['nombre']?.toString() ?? '',
    );

    //Seleccionem el propietari a partir dels usuaris de SQLite.
    int? idUsuariSeleccionat = habit?['id_usuario'] as int?;
    final idsDisponibles = usuaris.map((u) => u['id_usuario'] as int).toList();
    if (!idsDisponibles.contains(idUsuariSeleccionat)) {
      idUsuariSeleccionat = idsDisponibles.first;
    }

    final colorsDisponibles = <String, int>{
      'Blau': Colors.blue.toARGB32(),
      'Verd': Colors.green.toARGB32(),
      'Taronja': Colors.orange.toARGB32(),
    };
    int colorSeleccionat = habit?['color'] as int? ?? Colors.blue.toARGB32();
    if (!colorsDisponibles.containsValue(colorSeleccionat)) {
      colorsDisponibles['Color actual'] = colorSeleccionat;
    }

    bool guardat = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, actualitzarDialog) => AlertDialog(
            title: Text(habit == null ? 'Crear hàbit' : 'Editar hàbit'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nom,
                    decoration: const InputDecoration(
                      labelText: 'Nom de l\'hàbit',
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: idUsuariSeleccionat,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Usuari'),
                    items: usuaris.map((usuari) {
                      final id = usuari['id_usuario'] as int;
                      final nomUsuari = usuari['usuario']?.toString() ?? '';
                      return DropdownMenuItem<int>(
                        value: id,
                        child: Text('$nomUsuari (ID: $id)',
                            overflow: TextOverflow.ellipsis),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      actualitzarDialog(() {
                        idUsuariSeleccionat = valor;
                      });
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: colorSeleccionat,
                    decoration: const InputDecoration(labelText: 'Color de l\'hàbit'),
                    items: colorsDisponibles.entries.map((opcio) {
                      return DropdownMenuItem<int>(
                        value: opcio.value,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: Color(opcio.value)),
                            const SizedBox(width: 8),
                            Text(opcio.key),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (valor) {
                      if (valor != null) {
                        actualitzarDialog(() {
                          colorSeleccionat = valor;
                        });
                      }
                    },
                  ),
                  if (habit != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        'Última vegada completat: ${obtenirDataHoraHabit(habit)}',
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel·lar'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final id = idUsuariSeleccionat;
                  if (nom.text.trim().isEmpty || id == null) {
                    mostrarMissatge('Revisa els camps');
                    return;
                  }
                  try {
                    if (!await UsuariosService.esAdministrador(widget.idAdministrador)) {
                      mostrarMissatge('Acces denegat');
                      return;
                    }
                    if (habit == null) {
                      await HabitosService.crearHabit(
                        id, nom.text.trim(), colorSeleccionat,
                      );
                    } else {
                      //Actualitzem el nom, el color i el propietari.
                      final db = await DatabaseService.obtenirDatabase();
                      await db.update(
                        'habitos',
                        {
                          'id_usuario': id,
                          'nombre': nom.text.trim(),
                          'color': colorSeleccionat,
                        },
                        where: 'id_habit = ?',
                        whereArgs: [habit['id_habit'] as int],
                      );
                    }
                    guardat = true;
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (e) {
                    mostrarMissatge('Error en guardar l\'hàbit');
                  }
                },
                child: const Text('Guardar'),
              ),
            ],
          ),
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    nom.dispose();
    if (guardat && mounted) {
      await carregarDades();
      mostrarMissatge('Hàbit guardat correctament');
    }
  }

  //Marquem o desmarquem habits de qualsevol usuari.
  Future<void> canviarEstatHabitAdmin(Map<String, Object?> habit) async {
    try {
      if (!await UsuariosService.esAdministrador(widget.idAdministrador)) {
        mostrarMissatge('Acces denegat');
        return;
      }
      final idHabit = habit['id_habit'] as int;
      final idUsuari = habit['id_usuario'] as int;
      final avui = DateTime.now();
      final dataAvui = '${avui.year}-${avui.month.toString().padLeft(2, '0')}-${avui.day.toString().padLeft(2, '0')}';
      final dates = <String>[];
      final valor = habit['fechas_completadas'];
      if (valor is String && valor.isNotEmpty) {
        for (final data in jsonDecode(valor) as List<dynamic>) {
          dates.add(data.toString().split('T').first);
        }
      }
      if (dates.contains(dataAvui)) {
        await HabitosService.desmarcarHabit(idHabit, idUsuari);
      } else {
        await HabitosService.completarHabit(idHabit, idUsuari);
      }
      if (!mounted) return;
      await carregarDades();
      mostrarMissatge('Estat de l\'hàbit actualitzat');
    } catch (e) {
      mostrarMissatge('Error en actualitzar l\'hàbit');
    }
  }

  //Eliminem un habit
  Future<void> eliminarHabit(Map<String, Object?> habit) async {
    bool? confirmar = await confirmarEliminacio();

    if (confirmar != true) return;

    try {
      if (!await UsuariosService.esAdministrador(
        widget.idAdministrador,
      )) return;

      await HabitosService.eliminarHabit(
        habit['id_habit'] as int,
        habit['id_usuario'] as int,
      );

      await carregarDades();
      mostrarMissatge('Hàbit eliminat');
    } catch (e) {
      mostrarMissatge('Error en eliminar l\'hàbit');
    }
  }

  //Creem o editem les estadistiques d'un habit
  Future<void> formulariEstadistiques([
    Map<String, Object?>? estadistica,
  ]) async {
    final idHabit = TextEditingController(
      text: estadistica?['id_habit']?.toString() ?? '',
    );
    final racha = TextEditingController(
      text: estadistica?['racha_actual']?.toString() ?? '0',
    );
    final total = TextEditingController(
      text: estadistica?['total_dias']?.toString() ?? '0',
    );

    bool guardat = false;

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            estadistica == null
                ? 'Crear estadístiques'
                : 'Editar estadístiques',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idHabit,
                keyboardType: TextInputType.number,
                enabled: estadistica == null,
                decoration: const InputDecoration(
                  labelText: 'ID de l\'hàbit',
                ),
              ),
              TextField(
                controller: racha,
                keyboardType: TextInputType.number,
                enabled: estadistica != null,
                decoration: const InputDecoration(
                  labelText: 'Ratxa actual',
                ),
              ),
              TextField(
                controller: total,
                keyboardType: TextInputType.number,
                enabled: estadistica != null,
                decoration: const InputDecoration(
                  labelText: 'Total de dies',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              onPressed: () async {
                int? id = int.tryParse(idHabit.text);
                int? ratxaActual = int.tryParse(racha.text);
                int? totalDies = int.tryParse(total.text);

                if (id == null ||
                    ratxaActual == null ||
                    totalDies == null ||
                    ratxaActual < 0 ||
                    totalDies < 0) {
                  mostrarMissatge('Revisa els camps');
                  return;
                }

                try {
                  if (!await UsuariosService.esAdministrador(
                    widget.idAdministrador,
                  )) return;

                  if (estadistica == null) {
                    //Creem les estadistiques de l'habit
                    await EstadisticasService.crearEstadistiques(id);
                  } else {
                    //Modifiquem les estadistiques
                    await EstadisticasService.actualitzarEstadistiques(
                      id,
                      ratxaActual,
                      totalDies,
                    );
                  }

                  guardat = true;
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  mostrarMissatge('Error en guardar estadístiques');
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );

    await Future<void>.delayed(const Duration(milliseconds: 350));
    idHabit.dispose();
    racha.dispose();
    total.dispose();

    if (guardat) {
      await carregarDades();
      mostrarMissatge('Estadístiques guardades');
    }
  }

  //Eliminem les estadistiques
  Future<void> eliminarEstadistiques(int idHabit) async {
    bool? confirmar = await confirmarEliminacio();

    if (confirmar != true) return;

    try {
      if (!await UsuariosService.esAdministrador(
        widget.idAdministrador,
      )) return;

      await EstadisticasService.eliminarEstadistiques(idHabit);
      await carregarDades();
      mostrarMissatge('Estadístiques eliminades');
    } catch (e) {
      mostrarMissatge('Error en eliminar estadístiques');
    }
  }

  //Demanem confirmacio abans d'eliminar dades
  Future<bool?> confirmarEliminacio() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Confirmar eliminació'),
          content: const Text(
            'Segur que vols eliminar aquest registre?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel·lar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );
  }

  //Mostrem tots els usuaris
  Widget llistaUsuaris() {
    if (usuaris.isEmpty) {
      return const Center(child: Text('No hi ha usuaris'));
    }

    return ListView.builder(
      itemCount: usuaris.length,
      itemBuilder: (context, index) {
        final usuari = usuaris[index];

        return ListTile(
          leading: const Icon(Icons.person),
          title: Text(usuari['usuario'].toString()),
          subtitle: Text(
            '${usuari['nombre']} ${usuari['apellidos']}\n'
                '${usuari['email']}\n'
                'Rol: ${usuari['rol']} · '
                'Objectiu: ${usuari['objetivo_diario']}',
          ),
          isThreeLine: true,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => formulariUsuari(usuari),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => eliminarUsuari(
                  usuari['id_usuario'] as int,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //Mostrem tots els habits
  Widget llistaHabits() {
    if (habits.isEmpty) {
      return const Center(child: Text('No hi ha hàbits'));
    }

    return ListView.builder(
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];

        return ListTile(
          leading: Icon(
            Icons.circle,
            color: Color(habit['color'] as int? ?? Colors.blue.toARGB32()),
          ),
          title: Text(habit['nombre'].toString()),
          subtitle: Text(
            'ID hàbit: ${habit['id_habit']}\n'
                'ID usuari: ${habit['id_usuario']}\n'
                'Última vegada completat: ${obtenirDataHoraHabit(habit)}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check_circle_outline),
                tooltip: 'Completar o desmarcar avui',
                onPressed: () => canviarEstatHabitAdmin(habit),
              ),
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => formulariHabit(habit),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => eliminarHabit(habit),
              ),
            ],
          ),
        );
      },
    );
  }

  //Busquem el nom de l'habit utilitzant el seu identificador
  String obtenirNomHabit(int idHabit) {
    for (final habit in habits) {
      if (habit['id_habit'] == idHabit) {
        return habit['nombre']?.toString() ?? 'Hàbit $idHabit';
      }
    }
    return 'Hàbit $idHabit';
  }

  //Mostrem totes les estadistiques
  Widget llistaEstadistiques() {
    if (estadistiques.isEmpty) {
      return const Center(
        child: Text('No hi ha estadístiques'),
      );
    }

    return ListView.builder(
      itemCount: estadistiques.length,
      itemBuilder: (context, index) {
        final estadistica = estadistiques[index];

        return ListTile(
          leading: const Icon(Icons.bar_chart),
          title: Text(
            obtenirNomHabit(estadistica['id_habit'] as int),
          ),
          subtitle: Text(
            'Ratxa actual: ${estadistica['racha_actual']}\n'
                'Total de dies: ${estadistica['total_dias']}',
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () =>
                    formulariEstadistiques(estadistica),
              ),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () => eliminarEstadistiques(
                  estadistica['id_habit'] as int,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  //Mostrem el contingut de l'apartat seleccionat
  Widget contingutActual() {
    if (apartat == 0) return llistaUsuaris();
    if (apartat == 1) return llistaHabits();
    return llistaEstadistiques();
  }

  //Obrim el formulari de l'apartat seleccionat
  void afegirRegistre() {
    if (apartat == 0) {
      formulariUsuari();
    } else if (apartat == 1) {
      formulariHabit();
    } else {
      formulariEstadistiques();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administració'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: carregarDades,
          ),
        ],
      ),
      body: carregant
          ? const Center(child: CircularProgressIndicator())
          : !autoritzat
          ? const Center(
        child: Text('Accés només per a administradors'),
      )
          : Column(
        children: [
          //Botons per canviar entre els tres apartats
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        apartat = 0;
                      });
                    },
                    child: const Text('Usuaris'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        apartat = 1;
                      });
                    },
                    child: const Text('Hàbits'),
                  ),
                ),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        apartat = 2;
                      });
                    },
                    child: const Text('Estadístiques'),
                  ),
                ),
              ],
            ),
          ),

          //Mostrem les dades de l'apartat
          Expanded(
            child: contingutActual(),
          ),
        ],
      ),
      floatingActionButton: autoritzat
          ? FloatingActionButton(
        onPressed: afegirRegistre,
        child: const Icon(Icons.add),
      )
          : null,
    );
  }
}