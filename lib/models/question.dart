class Question {
  final int id;
  final String categorie;
  final String question;
  final List<String> options;
  final String reponse;
  final String explication;
  final String niveau;
  final double probaSimple;
  final String? imagePath;

  Question({
    required this.id,
    required this.categorie,
    required this.question,
    required this.options,
    required this.reponse,
    required this.explication,
    required this.niveau,
    required this.probaSimple,
    this.imagePath,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as int,
      categorie: json['categorie'] as String,
      question: json['question'] as String,
      options: List<String>.from(json['options']),
      reponse: json['reponse'] as String,
      explication: json['explication'] as String,
      niveau: json['niveau'] as String,
      probaSimple: (json['proba_simple'] as num).toDouble(),
      imagePath: json['image'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'categorie': categorie,
      'question': question,
      'options': options,
      'reponse': reponse,
      'explication': explication,
      'niveau': niveau,
      'proba_simple': probaSimple,
      'image': imagePath,
    };
  }

  Map<String, dynamic> toDatabase() {
    return {
      'id': id,
      'categorie': categorie,
      'question': question,
      'options': options.join('|'), // Sérialisé comme string
      'reponse': reponse,
      'explication': explication,
      'niveau': niveau,
      'proba_simple': probaSimple,
      'image_path': imagePath,
    };
  }

  factory Question.fromDatabase(Map<String, dynamic> map) {
    return Question(
      id: map['id'] as int,
      categorie: map['categorie'] as String,
      question: map['question'] as String,
      options: (map['options'] as String).split('|'),
      reponse: map['reponse'] as String,
      explication: map['explication'] as String,
      niveau: map['niveau'] as String,
      probaSimple: (map['proba_simple'] as num).toDouble(),
      imagePath: map['image_path'] as String?,
    );
  }

  // Méthodes utilitaires
  bool get hasFacileLevel => niveau == 'facile';
  bool get hasMoyenLevel => niveau == 'moyen';
  bool get hasDifficileLevel => niveau == 'difficile';
  bool get hasImage => imagePath != null && imagePath!.isNotEmpty;

  // Catégories disponibles
  static const List<String> categories = [
    'raisonnement_logique',
    'aptitude_numerique', 
    'aptitude_verbale',
    'raisonnement_spatial',
    'memoire_attention',
    'rapidite_personnalite'
  ];

  static const List<String> niveaux = ['facile', 'moyen', 'difficile'];

  // Couleurs par catégorie (optionnel pour l'UI)
  static const Map<String, int> categoryColors = {
    'raisonnement_logique': 0xFF2196F3, // Bleu
    'aptitude_numerique': 0xFF4CAF50,   // Vert
    'aptitude_verbale': 0xFF9C27B0,     // Violet
    'raisonnement_spatial': 0xFFFF9800, // Orange
    'memoire_attention': 0xFFF44336,    // Rouge
    'rapidite_personnalite': 0xFF607D8B // Bleu-gris
  };

  @override
  String toString() {
    return 'Question{id: $id, categorie: $categorie, niveau: $niveau}';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Question && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
