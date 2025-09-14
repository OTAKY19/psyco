import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question_model.dart';
import '../models/test_model.dart';
import '../models/test_session.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'psychotest_plus.db');
    
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Table des catégories
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        icon_name TEXT,
        color TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Table des tests
    await db.execute('''
      CREATE TABLE tests (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        title TEXT NOT NULL,
        description TEXT,
        difficulty TEXT,
        duration INTEGER,
        question_count INTEGER,
        is_premium BOOLEAN DEFAULT 0,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Table des questions
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id INTEGER,
        question_text TEXT NOT NULL,
        question_type TEXT,
        options TEXT,
        correct_answer TEXT,
        explanation TEXT,
        points INTEGER DEFAULT 1,
        time_limit INTEGER,
        image_url TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (test_id) REFERENCES tests (id)
      )
    ''');

    // Table des résultats de test
    await db.execute('''
      CREATE TABLE test_results (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        test_id INTEGER,
        score REAL,
        total_questions INTEGER,
        correct_answers INTEGER,
        time_taken INTEGER,
        completed_at TEXT DEFAULT CURRENT_TIMESTAMP,
        answers_data TEXT,
        FOREIGN KEY (test_id) REFERENCES tests (id)
      )
    ''');

    // Table de progression utilisateur
    await db.execute('''
      CREATE TABLE user_progress (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category_id INTEGER,
        completion_percentage REAL DEFAULT 0,
        best_score REAL DEFAULT 0,
        total_tests_taken INTEGER DEFAULT 0,
        updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (category_id) REFERENCES categories (id)
      )
    ''');

    // Insérer les données initiales
    await _insertInitialData(db);
  }

  Future<void> _insertInitialData(Database db) async {
    // Insérer les catégories
    await db.insert('categories', {
      'name': 'Tests de Logique',
      'description': 'Développez votre raisonnement logique avec des séquences, analogies et déductions.',
      'icon_name': 'psychology',
      'color': '#1565C0'
    });

    await db.insert('categories', {
      'name': 'Tests de Mémoire',
      'description': 'Entraînez votre mémoire visuelle et auditive avec des exercices ciblés.',
      'icon_name': 'memory',
      'color': '#0277BD'
    });

    await db.insert('categories', {
      'name': 'Tests d\'Attention',
      'description': 'Améliorez votre concentration et capacité d\'observation des détails.',
      'icon_name': 'visibility',
      'color': '#0288D1'
    });

    await db.insert('categories', {
      'name': 'Tests de Calcul',
      'description': 'Maîtrisez les calculs mentaux, pourcentages et problèmes arithmétiques.',
      'icon_name': 'calculate',
      'color': '#039BE5'
    });

    await db.insert('categories', {
      'name': 'Tests Spatiaux',
      'description': 'Développez votre intelligence spatiale et géométrique.',
      'icon_name': 'view_in_ar',
      'color': '#03A9F4'
    });

    await db.insert('categories', {
      'name': 'Tests Verbaux',
      'description': 'Perfectionnez votre compréhension verbale et vocabulaire.',
      'icon_name': 'spellcheck',
      'color': '#29B6F6'
    });

    // Insérer des tests pour chaque catégorie
    await _insertTestsAndQuestions(db);
  }

  Future<void> _insertTestsAndQuestions(Database db) async {
    // TEST DE LOGIQUE - Suite de nombres
    int testId = await db.insert('tests', {
      'category_id': 1,
      'title': 'Suites Numériques',
      'description': 'Trouvez le nombre suivant dans la suite logique.',
      'difficulty': 'Facile',
      'duration': 15,
      'question_count': 10,
      'is_premium': 0
    });

    // Questions de logique - Suites numériques
    var logiqueQuestions = [
      {
        'question_text': 'Quelle est la suite logique ?\n2, 4, 6, 8, ?',
        'options': '["8", "10", "12", "14"]',
        'correct_answer': '10',
        'explanation': 'Chaque nombre augmente de 2. Après 8, vient 10.',
      },
      {
        'question_text': 'Complétez la suite :\n1, 4, 9, 16, ?',
        'options': '["20", "25", "30", "36"]',
        'correct_answer': '25',
        'explanation': 'Il s\'agit des carrés parfaits : 1², 2², 3², 4², 5² = 25.',
      },
      {
        'question_text': 'Trouvez le nombre suivant :\n3, 6, 12, 24, ?',
        'options': '["36", "48", "50", "60"]',
        'correct_answer': '48',
        'explanation': 'Chaque nombre est multiplié par 2. 24 × 2 = 48.',
      },
      {
        'question_text': 'Quelle est la suite ?\n1, 1, 2, 3, 5, ?',
        'options': '["6", "7", "8", "9"]',
        'correct_answer': '8',
        'explanation': 'Suite de Fibonacci : chaque nombre est la somme des deux précédents. 3 + 5 = 8.',
      },
      {
        'question_text': 'Complétez :\n100, 81, 64, 49, ?',
        'options': '["36", "35", "25", "16"]',
        'correct_answer': '36',
        'explanation': 'Carrés décroissants : 10², 9², 8², 7², 6² = 36.',
      }
    ];

    for (var question in logiqueQuestions) {
      await db.insert('questions', {
        'test_id': testId,
        'question_text': question['question_text'],
        'question_type': 'multiple_choice',
        'options': question['options'],
        'correct_answer': question['correct_answer'],
        'explanation': question['explanation'],
        'points': 2,
        'time_limit': 90
      });
    }

    // TEST DE MÉMOIRE
    testId = await db.insert('tests', {
      'category_id': 2,
      'title': 'Mémoire Visuelle',
      'description': 'Mémorisez et reproduisez des séquences visuelles.',
      'difficulty': 'Moyen',
      'duration': 20,
      'question_count': 8,
      'is_premium': 0
    });

    var memoireQuestions = [
      {
        'question_text': 'Mémorisez cette séquence de lettres :\nK-M-P-R-T\nQuelle lettre vient après R ?',
        'options': '["S", "T", "U", "V"]',
        'correct_answer': 'T',
        'explanation': 'Dans la séquence K-M-P-R-T, la lettre après R est T.',
      },
      {
        'question_text': 'Séquence à mémoriser :\n7-3-9-1-5\nQuel est le troisième nombre ?',
        'options': '["3", "7", "9", "1"]',
        'correct_answer': '9',
        'explanation': 'Dans la séquence 7-3-9-1-5, le troisième nombre est 9.',
      },
    ];

    for (var question in memoireQuestions) {
      await db.insert('questions', {
        'test_id': testId,
        'question_text': question['question_text'],
        'question_type': 'multiple_choice',
        'options': question['options'],
        'correct_answer': question['correct_answer'],
        'explanation': question['explanation'],
        'points': 3,
        'time_limit': 120
      });
    }

    // TEST D'ATTENTION
    testId = await db.insert('tests', {
      'category_id': 3,
      'title': 'Attention Sélective',
      'description': 'Identifiez rapidement les éléments différents.',
      'difficulty': 'Facile',
      'duration': 10,
      'question_count': 15,
      'is_premium': 0
    });

    var attentionQuestions = [
      {
        'question_text': 'Parmi ces mots, lequel est différent ?\nCHAT - CHIEN - OISEAU - VOITURE',
        'options': '["CHAT", "CHIEN", "OISEAU", "VOITURE"]',
        'correct_answer': 'VOITURE',
        'explanation': 'VOITURE est le seul qui n\'est pas un animal.',
      },
      {
        'question_text': 'Trouvez l\'intrus :\n15 - 23 - 31 - 42 - 47',
        'options': '["15", "23", "31", "42"]',
        'correct_answer': '42',
        'explanation': '42 est le seul nombre pair, tous les autres sont impairs.',
      },
    ];

    for (var question in attentionQuestions) {
      await db.insert('questions', {
        'test_id': testId,
        'question_text': question['question_text'],
        'question_type': 'multiple_choice',
        'options': question['options'],
        'correct_answer': question['correct_answer'],
        'explanation': question['explanation'],
        'points': 1,
        'time_limit': 60
      });
    }

    // TEST DE CALCUL
    testId = await db.insert('tests', {
      'category_id': 4,
      'title': 'Calcul Mental Rapide',
      'description': 'Effectuez des calculs mentaux rapidement et précisément.',
      'difficulty': 'Moyen',
      'duration': 25,
      'question_count': 20,
      'is_premium': 0
    });

    var calculQuestions = [
      {
        'question_text': 'Calculez :\n15 × 8 = ?',
        'options': '["110", "120", "125", "130"]',
        'correct_answer': '120',
        'explanation': '15 × 8 = (10 × 8) + (5 × 8) = 80 + 40 = 120.',
      },
      {
        'question_text': 'Quel est 30% de 250 ?',
        'options': '["65", "70", "75", "80"]',
        'correct_answer': '75',
        'explanation': '30% de 250 = 0,30 × 250 = 75.',
      },
    ];

    for (var question in calculQuestions) {
      await db.insert('questions', {
        'test_id': testId,
        'question_text': question['question_text'],
        'question_type': 'multiple_choice',
        'options': question['options'],
        'correct_answer': question['correct_answer'],
        'explanation': question['explanation'],
        'points': 2,
        'time_limit': 75
      });
    }

    // Initialiser la progression utilisateur
    for (int categoryId = 1; categoryId <= 6; categoryId++) {
      await db.insert('user_progress', {
        'category_id': categoryId,
        'completion_percentage': 0.0,
        'best_score': 0.0,
        'total_tests_taken': 0
      });
    }
  }

  // CRUD Operations pour les questions
  Future<List<Question>> getQuestionsByTestId(int testId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'test_id = ?',
      whereArgs: [testId],
    );

    return List.generate(maps.length, (i) => Question.fromMap(maps[i]));
  }

  // CRUD Operations pour les tests
  Future<List<TestModel>> getTestsByCategory(int categoryId) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'tests',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    return List.generate(maps.length, (i) => TestModel.fromMap(maps[i]));
  }

  // Sauvegarder résultat de test
  Future<int> saveTestResult(TestResult result) async {
    final db = await database;
    return await db.insert('test_results', result.toMap());
  }

  // Mettre à jour la progression
  Future<void> updateUserProgress(int categoryId, double percentage, double score) async {
    final db = await database;
    await db.update(
      'user_progress',
      {
        'completion_percentage': percentage,
        'best_score': score > 0 ? score : null,
        'total_tests_taken': 'total_tests_taken + 1',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
  }

  // Récupérer statistiques utilisateur
  Future<Map<String, dynamic>> getUserStats() async {
    final db = await database;
    
    // Nombre total de tests complétés
    final testCount = await db.rawQuery('SELECT COUNT(*) as count FROM test_results');
    final totalTests = testCount.first['count'] as int;
    
    // Score moyen
    final avgScore = await db.rawQuery('SELECT AVG(score) as avg FROM test_results');
    final averageScore = (avgScore.first['avg'] as double?) ?? 0.0;
    
    return {
      'testsCompleted': totalTests,
      'averageScore': averageScore,
      'studyStreak': totalTests > 0 ? (totalTests / 3).ceil() : 0, // Simulation
    };
  }

  // Récupérer progression par catégorie
  Future<double> getCategoryProgress(int categoryId) async {
    final db = await database;
    final result = await db.query(
      'user_progress',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );
    
    if (result.isNotEmpty) {
      return result.first['completion_percentage'] as double;
    }
    return 0.0;
  }

  Future<void> close() async {
    final db = await database;
    db.close();
  }
}
