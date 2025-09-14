import 'dart:convert';
import '../models/question.dart';

enum TestStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  abandoned
}

enum TestType {
  mixed,        // Toutes catégories mélangées
  specific,     // Une catégorie spécifique
  adaptive,     // Adaptatif selon les performances
  timed,        // Test chronométré
  practice      // Mode entraînement
}

class TestSession {
  final String id;
  final List<Question> questions;
  final Map<int, String> userAnswers; // questionId -> réponse utilisateur
  final Map<int, int> answerTimes;    // questionId -> temps en secondes
  final TestType type;
  final DateTime startTime;
  final String? category;
  final String? level;
  final int totalTimeLimit; // en secondes, 0 = pas de limite
  final int questionTimeLimit; // en secondes par question, 0 = pas de limite
  
  TestStatus status;
  int currentQuestionIndex;
  DateTime? endTime;
  DateTime? lastAnswerTime;

  TestSession({
    required this.id,
    required this.questions,
    required this.type,
    required this.startTime,
    this.category,
    this.level,
    this.totalTimeLimit = 0,
    this.questionTimeLimit = 0,
    this.status = TestStatus.notStarted,
    this.currentQuestionIndex = 0,
    this.endTime,
    this.lastAnswerTime,
    Map<int, String>? userAnswers,
    Map<int, int>? answerTimes,
  }) : userAnswers = userAnswers ?? {},
       answerTimes = answerTimes ?? {};

  // Getters utilitaires
  Question get currentQuestion => questions[currentQuestionIndex];
  bool get isCompleted => status == TestStatus.completed;
  bool get isInProgress => status == TestStatus.inProgress;
  bool get hasNext => currentQuestionIndex < questions.length - 1;
  bool get hasPrevious => currentQuestionIndex > 0;
  int get totalQuestions => questions.length;
  int get answeredCount => userAnswers.length;
  double get progressPercent => answeredCount / totalQuestions;

  // Gestion des réponses
  void answerQuestion(String answer) {
    final questionId = currentQuestion.id;
    userAnswers[questionId] = answer;
    
    // Calcul du temps de réponse
    final now = DateTime.now();
    if (lastAnswerTime != null) {
      final responseTime = now.difference(lastAnswerTime!).inSeconds;
      answerTimes[questionId] = responseTime;
    } else {
      final responseTime = now.difference(startTime).inSeconds;
      answerTimes[questionId] = responseTime;
    }
    
    lastAnswerTime = now;
  }

  // Navigation
  bool nextQuestion() {
    if (hasNext) {
      currentQuestionIndex++;
      return true;
    }
    return false;
  }

  bool previousQuestion() {
    if (hasPrevious) {
      currentQuestionIndex--;
      return true;
    }
    return false;
  }

  void goToQuestion(int index) {
    if (index >= 0 && index < questions.length) {
      currentQuestionIndex = index;
    }
  }

  // Gestion du statut
  void start() {
    status = TestStatus.inProgress;
  }

  void pause() {
    status = TestStatus.paused;
  }

  void resume() {
    status = TestStatus.inProgress;
  }

  void complete() {
    status = TestStatus.completed;
    endTime = DateTime.now();
  }

  void abandon() {
    status = TestStatus.abandoned;
    endTime = DateTime.now();
  }

  // Calculs et résultats
  TestResult calculateResult() {
    return TestResult.fromSession(this);
  }

  Duration get totalDuration {
    final end = endTime ?? DateTime.now();
    return end.difference(startTime);
  }

  // Temps moyen par question
  double get averageTimePerQuestion {
    if (answerTimes.isEmpty) return 0.0;
    final totalTime = answerTimes.values.reduce((a, b) => a + b);
    return totalTime / answerTimes.length;
  }

  // Sérialisation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questions': questions.map((q) => q.toJson()).toList(),
      'userAnswers': userAnswers,
      'answerTimes': answerTimes,
      'type': type.toString(),
      'startTime': startTime.toIso8601String(),
      'category': category,
      'level': level,
      'totalTimeLimit': totalTimeLimit,
      'questionTimeLimit': questionTimeLimit,
      'status': status.toString(),
      'currentQuestionIndex': currentQuestionIndex,
      'endTime': endTime?.toIso8601String(),
      'lastAnswerTime': lastAnswerTime?.toIso8601String(),
    };
  }

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: json['id'],
      questions: (json['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList(),
      userAnswers: Map<int, String>.from(json['userAnswers'] ?? {}),
      answerTimes: Map<int, int>.from(json['answerTimes'] ?? {}),
      type: TestType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => TestType.mixed,
      ),
      startTime: DateTime.parse(json['startTime']),
      category: json['category'],
      level: json['level'],
      totalTimeLimit: json['totalTimeLimit'] ?? 0,
      questionTimeLimit: json['questionTimeLimit'] ?? 0,
      status: TestStatus.values.firstWhere(
        (e) => e.toString() == json['status'],
        orElse: () => TestStatus.notStarted,
      ),
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      lastAnswerTime: json['lastAnswerTime'] != null 
          ? DateTime.parse(json['lastAnswerTime']) 
          : null,
    );
  }
}

class TestResult {
  final String sessionId;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredQuestions;
  final Duration totalDuration;
  final Map<String, CategoryResult> categoryResults;
  final List<QuestionResult> questionResults;
  final double score; // Pourcentage
  final String level;
  final DateTime completedAt;

  TestResult({
    required this.sessionId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    required this.totalDuration,
    required this.categoryResults,
    required this.questionResults,
    required this.score,
    required this.level,
    required this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'test_id': null,
      'score': score,
      'total_questions': totalQuestions,
      'correct_answers': correctAnswers,
      'time_taken': totalDuration.inSeconds,
      'completed_at': completedAt.toIso8601String(),
      'answers_data': json.encode({
        'questionResults': questionResults.map((q) => q.toJson()).toList(),
        'categoryResults': categoryResults.map((k, v) => MapEntry(k, v.toJson())),
        'level': level,
      }),
    };
  }

  factory TestResult.fromSession(TestSession session) {
    final questionResults = <QuestionResult>[];
    final categoryStats = <String, CategoryStats>{};
    int correct = 0;
    int incorrect = 0;

    // Analyser chaque question
    for (final question in session.questions) {
      final userAnswer = session.userAnswers[question.id];
      final responseTime = session.answerTimes[question.id] ?? 0;
      final isCorrect = userAnswer == question.reponse;

      if (userAnswer != null) {
        if (isCorrect) {
          correct++;
        } else {
          incorrect++;
        }
      }

      questionResults.add(QuestionResult(
        question: question,
        userAnswer: userAnswer,
        isCorrect: isCorrect,
        responseTime: responseTime,
      ));

      // Statistiques par catégorie
      if (!categoryStats.containsKey(question.categorie)) {
        categoryStats[question.categorie] = CategoryStats();
      }
      categoryStats[question.categorie]!.total++;
      if (userAnswer != null) {
        if (isCorrect) {
          categoryStats[question.categorie]!.correct++;
        } else {
          categoryStats[question.categorie]!.incorrect++;
        }
      }
    }

    // Convertir les stats en résultats par catégorie
    final categoryResults = <String, CategoryResult>{};
    categoryStats.forEach((category, stats) {
      categoryResults[category] = CategoryResult(
        category: category,
        totalQuestions: stats.total,
        correctAnswers: stats.correct,
        incorrectAnswers: stats.incorrect,
        score: stats.correct / stats.total,
      );
    });

    final unanswered = session.totalQuestions - correct - incorrect;
    final score = session.totalQuestions > 0 
        ? (correct / session.totalQuestions) * 100 
        : 0.0;

    return TestResult(
      sessionId: session.id,
      totalQuestions: session.totalQuestions,
      correctAnswers: correct,
      incorrectAnswers: incorrect,
      unansweredQuestions: unanswered,
      totalDuration: session.totalDuration,
      categoryResults: categoryResults,
      questionResults: questionResults,
      score: score,
      level: _calculateLevel(score),
      completedAt: session.endTime ?? DateTime.now(),
    );
  }

  static String _calculateLevel(double score) {
    if (score >= 80) return 'Excellent';
    if (score >= 65) return 'Bon';
    if (score >= 50) return 'Moyen';
    return 'À améliorer';
  }

  // Getters utilitaires
  bool get isPassed => score >= 50; // Seuil de réussite à 50%
  String get formattedScore => '${score.toStringAsFixed(1)}%';
  String get formattedDuration {
    final minutes = totalDuration.inMinutes;
    final seconds = totalDuration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  // Computed fields for UI compatibility
  DateTime get endTime => completedAt;
  DateTime get startTime => completedAt.subtract(totalDuration);
  bool get isCompleted => true;
  String get testType => categoryResults.isEmpty ? 'mixte' : categoryResults.keys.first;
  Duration get duration => totalDuration;
  int get currentQuestionIndex => totalQuestions - unansweredQuestions;
  List<String> get categories => categoryResults.keys.toList();

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unansweredQuestions': unansweredQuestions,
      'totalDuration': totalDuration.inMilliseconds,
      'categoryResults': categoryResults.map((k, v) => MapEntry(k, v.toJson())),
      'questionResults': questionResults.map((q) => q.toJson()).toList(),
      'score': score,
      'level': level,
      'completedAt': completedAt.toIso8601String(),
    };
  }
}

class CategoryResult {
  final String category;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double score;

  CategoryResult({
    required this.category,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.score,
  });

  String get formattedScore => '${(score * 100).toStringAsFixed(1)}%';

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'score': score,
    };
  }
}

class QuestionResult {
  final Question question;
  final String? userAnswer;
  final bool isCorrect;
  final int responseTime; // en secondes

  QuestionResult({
    required this.question,
    required this.userAnswer,
    required this.isCorrect,
    required this.responseTime,
  });

  bool get wasAnswered => userAnswer != null;
  String get formattedTime => '${responseTime}s';

  Map<String, dynamic> toJson() {
    return {
      'question': question.toJson(),
      'userAnswer': userAnswer,
      'isCorrect': isCorrect,
      'responseTime': responseTime,
    };
  }
}

class CategoryStats {
  int total = 0;
  int correct = 0;
  int incorrect = 0;
}
