class Habit { //Representem un hàbit amb el seu id, nom, color i dies completats
  int id;
  String nom;
  int color;
  List<String> datesCompletades;

  Habit({
    required this.id,
    required this.nom,
    required this.color,
    required this.datesCompletades,
  });

  Map<String, dynamic> toJson() { //Convertim l'hàbit a un mapa per poder guardar-lo com a JSON
    return {
      'id': id,
      'nom': nom,
      'color': color,
      'datesCompletades': datesCompletades,
    };
  }

  factory Habit.fromJson(Map<String, dynamic> json) { //Recuperem les dades JSON i les convertim en un objecte Habit

    return Habit(
      id: json['id'] as int,
      nom: json['nom'] as String,
      color: json['color'] as int,
      datesCompletades: List<String>.from(json['datesCompletades']),
    );
  }
}
