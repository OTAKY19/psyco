import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import '../models/exam_config.dart';
import '../models/question.dart';
import 'database_service.dart';

class ExamBlancService {
  static const String _examBlancsPath = 'assets/data/examens_blancs.json';
  static const String _examBlancs6Path = 'assets/data/examens_blancs_6.json';
  
  // Configuration des examens blancs
  static const ExamConfig config = ExamConfig.blancStandard;
  static const int examDurationMinutes = 25;
  static const int questionDurationSeconds = 60;
  static const int totalQuestions = 25;
  
  // Instance du service de base de données
  final DatabaseService _databaseService = DatabaseService();
  
  // Singleton
  static final ExamBlancService _instance = ExamBlancService._internal();
  factory ExamBlancService() => _instance;
  ExamBlancService._internal();

  /// Génère un examen blanc dynamique avec des questions aléatoirement sélectionnées
  Future<ExamBlanc> generateDynamicExamBlanc(int examNumber, {String? series}) async {
    try {
      // Sélectionner les questions aléatoirement depuis la base de données
      final allQuestions = await _databaseService.getRandomQuestions(limit: totalQuestions);

      if (allQuestions.length < totalQuestions) {
        throw Exception('Pas assez de questions disponibles dans la base de données');
      }

      final examId = series != null ? 'exam_${examNumber}_$series' : 'exam_$examNumber';
      final title = series != null
          ? 'Examen Blanc $examNumber (Série $series)'
          : 'Examen Blanc $examNumber';

      return ExamBlanc(
        id: examId,
        title: title,
        description: 'Examen blanc généré dynamiquement - ${allQuestions.length} questions en $examDurationMinutes minutes',
        questions: allQuestions,
        duration: const Duration(minutes: examDurationMinutes),
        questionDuration: const Duration(seconds: questionDurationSeconds),
        totalQuestions: allQuestions.length,
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Erreur lors de la génération de l\'examen dynamique: $e');
      // Fallback vers les examens statiques
      return await _generateFallbackExam(examNumber);
    }
  }

  /// Génère un examen de secours si la génération dynamique échoue
  Future<ExamBlanc> _generateFallbackExam(int examNumber) async {
    final fallbackQuestions = await _databaseService.getRandomQuestions(limit: totalQuestions);

    return ExamBlanc(
      id: 'fallback_exam_$examNumber',
      title: 'Examen Blanc $examNumber (Mode de secours)',
      description: 'Examen de secours - ${fallbackQuestions.length} questions',
      questions: fallbackQuestions,
      duration: const Duration(minutes: examDurationMinutes),
      questionDuration: const Duration(seconds: questionDurationSeconds),
      totalQuestions: fallbackQuestions.length,
      createdAt: DateTime.now(),
    );
  }

  /// Charge tous les examens blancs disponibles (statiques + dynamiques)
  Future<List<ExamBlanc>> loadAllExams() async {
    try {
      final List<ExamBlanc> allExams = [];

      // 1. Charger les examens statiques depuis les fichiers JSON
      await _loadStaticExams(allExams);

      // 2. Générer des examens dynamiques supplémentaires
      await _generateDynamicExams(allExams);

      return allExams;
    } catch (e) {
      debugPrint('Erreur lors du chargement des examens blancs: $e');
      return [];
    }
  }

  /// Charge les examens statiques depuis les fichiers JSON
  Future<void> _loadStaticExams(List<ExamBlanc> allExams) async {
    try {
      // Charger examens_blancs.json
      final String examBlancsJson = await rootBundle.loadString(_examBlancsPath);
      final Map<String, dynamic> examBlancsData = json.decode(examBlancsJson);

      for (String examKey in examBlancsData.keys) {
        final List<dynamic> questionsData = examBlancsData[examKey];
        final List<Question> questions = questionsData.map((q) => _convertExamQuestionToQuestion(q)).toList();

        allExams.add(ExamBlanc(
          id: examKey,
          title: 'Examen Blanc ${examKey.split('_').last} (Statique)',
          description: 'Test d\'entraînement officiel - ${questions.length} questions en $examDurationMinutes minutes',
          questions: questions,
          duration: const Duration(minutes: examDurationMinutes),
          questionDuration: const Duration(seconds: questionDurationSeconds),
          totalQuestions: questions.length,
          createdAt: DateTime.now(),
        ));
      }

      // Charger examens_blancs_6.json
      final String examBlancs6Json = await rootBundle.loadString(_examBlancs6Path);
      final Map<String, dynamic> examBlancs6Data = json.decode(examBlancs6Json);

      for (String examKey in examBlancs6Data.keys) {
        final List<dynamic> questionsData = examBlancs6Data[examKey];
        final List<Question> questions = questionsData.map((q) => _convertExamQuestionToQuestion(q)).toList();

        allExams.add(ExamBlanc(
          id: '${examKey}_6',
          title: 'Examen Blanc ${examKey.split('_').last} (Série 6 - Statique)',
          description: 'Test d\'entraînement officiel - ${questions.length} questions en $examDurationMinutes minutes',
          questions: questions,
          duration: const Duration(minutes: examDurationMinutes),
          questionDuration: const Duration(seconds: questionDurationSeconds),
          totalQuestions: questions.length,
          createdAt: DateTime.now(),
        ));
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des examens statiques: $e');
    }
  }

  /// Génère des examens dynamiques
  Future<void> _generateDynamicExams(List<ExamBlanc> allExams) async {
    try {
      // Générer 10 examens dynamiques (exam_1 à exam_10)
      for (int i = 1; i <= 10; i++) {
        final dynamicExam = await generateDynamicExamBlanc(i);
        allExams.add(dynamicExam);
      }

      // Générer des séries supplémentaires si nécessaire
      for (int series = 1; series <= 3; series++) {
        for (int exam = 1; exam <= 5; exam++) {
          final dynamicExam = await generateDynamicExamBlanc(exam, series: series.toString());
          allExams.add(dynamicExam);
        }
      }

      debugPrint('✅ ${allExams.length} examens blancs générés au total');
    } catch (e) {
      debugPrint('Erreur lors de la génération des examens dynamiques: $e');
    }
  }

  /// Récupère un examen blanc spécifique par son ID
  Future<ExamBlanc?> getExamById(String examId) async {
    final allExams = await loadAllExams();
    try {
      return allExams.firstWhere((exam) => exam.id == examId);
    } catch (e) {
      return null;
    }
  }

  /// Crée une session d'examen blanc
  Future<ExamBlancSession> createExamSession(String examId, String userId) async {
    final exam = await getExamById(examId);
    if (exam == null) {
      throw Exception('Examen non trouvé: $examId');
    }

    return ExamBlancSession(
      id: '${examId}_${DateTime.now().millisecondsSinceEpoch}',
      examId: examId,
      userId: userId,
      exam: exam,
      startTime: DateTime.now(),
      status: ExamBlancStatus.notStarted,
      currentQuestionIndex: 0,
      userAnswers: {},
      questionStartTimes: {},
    );
  }

  /// Calcule le résultat d'un examen blanc
  ExamBlancResult calculateResult(ExamBlancSession session) {
    int correctAnswers = 0;
    int totalAnswered = session.userAnswers.length;
    
    for (int i = 0; i < session.exam.questions.length; i++) {
      final userAnswer = session.userAnswers[i];
      if (userAnswer != null) {
        final question = session.exam.questions[i];
        if (question.options[userAnswer] == question.reponse) {
          correctAnswers++;
        }
      }
    }
    
    final scorePercentage = (correctAnswers / session.exam.totalQuestions) * 100;
    final timeSpent = session.endTime?.difference(session.startTime) ?? Duration.zero;
    
    return ExamBlancResult(
      sessionId: session.id,
      examId: session.examId,
      userId: session.userId,
      totalQuestions: session.exam.totalQuestions,
      answeredQuestions: totalAnswered,
      correctAnswers: correctAnswers,
      incorrectAnswers: totalAnswered - correctAnswers,
      skippedQuestions: session.exam.totalQuestions - totalAnswered,
      scorePercentage: scorePercentage,
      timeSpent: timeSpent,
      completedAt: session.endTime ?? DateTime.now(),
      detailedResults: _generateDetailedResults(session),
    );
  }

  /// Génère les résultats détaillés question par question
  Map<String, dynamic> _generateDetailedResults(ExamBlancSession session) {
    final Map<String, dynamic> results = {};

    for (int i = 0; i < session.exam.questions.length; i++) {
      final question = session.exam.questions[i];
      final userAnswerIndex = session.userAnswers[i];

      results['question_$i'] = {
        'questionId': question.id,
        'questionText': question.question,
        'options': question.options, // Ajout des vraies options
        'userAnswer': userAnswerIndex != null ? question.options[userAnswerIndex] : null,
        'userAnswerIndex': userAnswerIndex, // Ajout de l'index pour UnifiedResultsWidget
        'correctAnswer': question.reponse,
        'correctAnswerIndex': question.options.indexOf(question.reponse), // Index de la bonne réponse
        'isCorrect': userAnswerIndex != null && question.options[userAnswerIndex] == question.reponse,
        'explanation': question.explication,
        'category': question.categorie,
        'difficulty': question.niveau,
      };
    }

    return results;
  }

  /// Convertit une question d'examen blanc au format Question standard
  Question _convertExamQuestionToQuestion(Map<String, dynamic> examQuestion) {
    return Question(
      id: examQuestion['id'] as int,
      categorie: examQuestion['categorie'] as String,
      question: examQuestion['question'] as String,
      options: List<String>.from(examQuestion['options']),
      reponse: examQuestion['reponse'] as String,
      explication: examQuestion['explication'] as String,
      niveau: examQuestion['niveau'] as String,
      probaSimple: (examQuestion['proba_simple'] as num).toDouble(),
      imagePath: examQuestion['image'] as String?,
    );
  }
}

/// Modèle pour un examen blanc
class ExamBlanc {
  final String id;
  final String title;
  final String description;
  final List<Question> questions;
  final Duration duration;
  final Duration questionDuration;
  final int totalQuestions;
  final DateTime createdAt;

  ExamBlanc({
    required this.id,
    required this.title,
    required this.description,
    required this.questions,
    required this.duration,
    required this.questionDuration,
    required this.totalQuestions,
    required this.createdAt,
  });
}

/// Modèle pour une session d'examen blanc
class ExamBlancSession {
  final String id;
  final String examId;
  final String userId;
  final ExamBlanc exam;
  final DateTime startTime;
  ExamBlancStatus status;
  int currentQuestionIndex;
  final Map<int, int> userAnswers; // questionIndex -> optionIndex
  final Map<int, DateTime> questionStartTimes; // questionIndex -> startTime
  DateTime? endTime;

  ExamBlancSession({
    required this.id,
    required this.examId,
    required this.userId,
    required this.exam,
    required this.startTime,
    required this.status,
    required this.currentQuestionIndex,
    required this.userAnswers,
    required this.questionStartTimes,
    this.endTime,
  });

  Question get currentQuestion => exam.questions[currentQuestionIndex];
  bool get isCompleted => status == ExamBlancStatus.completed;
  bool get isInProgress => status == ExamBlancStatus.inProgress;
  bool get hasNext => currentQuestionIndex < exam.questions.length - 1;
  bool get hasPrevious => currentQuestionIndex > 0;
  int get answeredCount => userAnswers.length;
  double get progressPercent => answeredCount / exam.totalQuestions;

  void start() {
    status = ExamBlancStatus.inProgress;
    questionStartTimes[currentQuestionIndex] = DateTime.now();
  }

  void answerQuestion(int optionIndex) {
    userAnswers[currentQuestionIndex] = optionIndex;
  }

  void nextQuestion() {
    if (hasNext) {
      currentQuestionIndex++;
      questionStartTimes[currentQuestionIndex] = DateTime.now();
    }
  }

  void previousQuestion() {
    if (hasPrevious) {
      currentQuestionIndex--;
    }
  }

  void complete() {
    status = ExamBlancStatus.completed;
    endTime = DateTime.now();
  }

  void abandon() {
    status = ExamBlancStatus.abandoned;
    endTime = DateTime.now();
  }
}

/// Statut d'une session d'examen blanc
enum ExamBlancStatus {
  notStarted,
  inProgress,
  completed,
  abandoned,
}

/// Modèle pour le résultat d'un examen blanc
class ExamBlancResult {
  final String sessionId;
  final String examId;
  final String userId;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;
  final double scorePercentage;
  final Duration timeSpent;
  final DateTime completedAt;
  final Map<String, dynamic> detailedResults;

  ExamBlancResult({
    required this.sessionId,
    required this.examId,
    required this.userId,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedQuestions,
    required this.scorePercentage,
    required this.timeSpent,
    required this.completedAt,
    required this.detailedResults,
  });

  String get performanceGrade {
    if (scorePercentage >= 90) return 'A+';
    if (scorePercentage >= 80) return 'A';
    if (scorePercentage >= 70) return 'B+';
    if (scorePercentage >= 60) return 'B';
    if (scorePercentage >= 50) return 'C+';
    if (scorePercentage >= 40) return 'C';
    return 'D';
  }

  String get performanceColor {
    if (scorePercentage >= 80) return 'green';
    if (scorePercentage >= 60) return 'orange';
    return 'red';
  }
}
