import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/question.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'douanetest_questions.db');

    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE questions (
        id INTEGER PRIMARY KEY,
        categorie TEXT NOT NULL,
        question TEXT NOT NULL,
        options TEXT NOT NULL,
        reponse TEXT NOT NULL,
        explication TEXT NOT NULL,
        niveau TEXT NOT NULL,
        proba_simple REAL NOT NULL,
        image_path TEXT,
        created_at DATETIME DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_questions_categorie ON questions(categorie);
    ''');

    await db.execute('''
      CREATE INDEX idx_questions_niveau ON questions(niveau);
    ''');

    // Charger les questions initiales
    await _loadInitialQuestions(db);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Gestion des mises à jour de schéma si nécessaire
    if (oldVersion < newVersion) {
      // Exemple : ajout d'une colonne
      // await db.execute('ALTER TABLE questions ADD COLUMN new_field TEXT');
    }
  }

  Future<void> _loadInitialQuestions(Database db) async {
    try {
      // Charger les questions depuis le fichier JSON des assets
      final jsonString = await rootBundle.loadString('assets/data/questions_balanced.json');
      final List<dynamic> questionsJson = json.decode(jsonString);
      
      final batch = db.batch();
      
      for (final questionJson in questionsJson) {
        final question = Question.fromJson(questionJson);
        batch.insert('questions', question.toDatabase());
      }
      
      await batch.commit(noResult: true);
      print('✅ ${questionsJson.length} questions chargées avec succès');
    } catch (e) {
      print('❌ Erreur lors du chargement des questions: \$e');
    }
  }

  // CRUD Operations
  
  Future<List<Question>> getAllQuestions() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('questions');
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }

  Future<List<Question>> getQuestionsByCategory(String category) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'categorie = ?',
      whereArgs: [category],
    );
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }

  Future<List<Question>> getQuestionsByLevel(String level) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'niveau = ?',
      whereArgs: [level],
    );
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }

  Future<List<Question>> getRandomQuestions({
    int limit = 10, 
    String? category, 
    String? level
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<String> whereArgs = [];
    
    if (category != null) {
      whereClause += 'categorie = ?';
      whereArgs.add(category);
    }
    
    if (level != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'niveau = ?';
      whereArgs.add(level);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'RANDOM()',
      limit: limit,
    );
    
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }

  Future<Question?> getQuestionById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isNotEmpty) {
      return Question.fromDatabase(maps.first);
    }
    return null;
  }

  Future<int> insertQuestion(Question question) async {
    final db = await database;
    return await db.insert('questions', question.toDatabase());
  }

  Future<int> updateQuestion(Question question) async {
    final db = await database;
    return await db.update(
      'questions',
      question.toDatabase(),
      where: 'id = ?',
      whereArgs: [question.id],
    );
  }

  Future<int> deleteQuestion(int id) async {
    final db = await database;
    return await db.delete(
      'questions',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Statistiques et informations
  
  Future<int> getTotalQuestionsCount() async {
    final db = await database;
    final result = await db.rawQuery('SELECT COUNT(*) as count FROM questions');
    return Sqflite.firstIntValue(result) ?? 0;
  }

  Future<Map<String, int>> getQuestionCountByCategory() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT categorie, COUNT(*) as count FROM questions GROUP BY categorie'
    );
    
    Map<String, int> categoryCount = {};
    for (final row in result) {
      categoryCount[row['categorie'] as String] = row['count'] as int;
    }
    return categoryCount;
  }

  Future<Map<String, int>> getQuestionCountByLevel() async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT niveau, COUNT(*) as count FROM questions GROUP BY niveau'
    );
    
    Map<String, int> levelCount = {};
    for (final row in result) {
      levelCount[row['niveau'] as String] = row['count'] as int;
    }
    return levelCount;
  }

  // Gestion avancée
  
  Future<List<Question>> searchQuestions(String searchTerm) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: 'question LIKE ? OR explication LIKE ?',
      whereArgs: ['%\$searchTerm%', '%\$searchTerm%'],
    );
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }

  Future<void> resetDatabase() async {
    final db = await database;
    await db.delete('questions');
    await _loadInitialQuestions(db);
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
    _database = null;
  }

  // Méthodes utilitaires pour les tests
  
  Future<List<Question>> createTestSession({
    required int questionCount,
    String? category,
    String? level,
    List<String>? excludedCategories,
  }) async {
    final db = await database;
    
    String whereClause = '';
    List<String> whereArgs = [];
    
    if (category != null) {
      whereClause += 'categorie = ?';
      whereArgs.add(category);
    }
    
    if (level != null) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'niveau = ?';
      whereArgs.add(level);
    }
    
    if (excludedCategories != null && excludedCategories.isNotEmpty) {
      if (whereClause.isNotEmpty) whereClause += ' AND ';
      whereClause += 'categorie NOT IN (${excludedCategories.map((_) => '?').join(',')})';
      whereArgs.addAll(excludedCategories);
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'questions',
      where: whereClause.isEmpty ? null : whereClause,
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'RANDOM()',
      limit: questionCount,
    );
    
    return List.generate(maps.length, (i) => Question.fromDatabase(maps[i]));
  }
}
