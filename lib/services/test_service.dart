import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/test_session.dart';
import '../services/database_service.dart';
import '../services/subscription_service.dart';
import '../services/user_data_service.dart';

class TestService {
  static final TestService _instance = TestService._internal();
  factory TestService() => _instance;
  TestService._internal();

  final DatabaseService _databaseService = DatabaseService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  TestSession? _currentSession;
  Timer? _sessionTimer;
  Timer? _questionTimer;

  // Events streams
  final StreamController<TestSession> _sessionController = StreamController<TestSession>.broadcast();
  final StreamController<int> _timerController = StreamController<int>.broadcast();
  final StreamController<int> _questionTimerController = StreamController<int>.broadcast();

  Stream<TestSession> get sessionStream => _sessionController.stream;
  Stream<int> get timerStream => _timerController.stream;
  Stream<int> get questionTimerStream => _questionTimerController.stream;

  TestSession? get currentSession => _currentSession;
  bool get hasActiveSession => _currentSession != null && !_currentSession!.isCompleted;

  /// Vérifie si l'utilisateur peut créer un nouveau test
  Future<bool> canCreateTest() async {
    return await _subscriptionService.canTakeTest();
  }

  /// Récupère les informations de limitation
  Future<Map<String, dynamic>> getTestLimitations() async {
    return await _subscriptionService.getSubscriptionInfo();
  }

  // Création de sessions de test

  Future<TestSession> createMixedTest({
    int questionCount = 20,
    int? totalTimeLimit,
    int? questionTimeLimit,
    bool bypassLimitations = false,
  }) async {
    // Vérifier les limitations sauf si bypassé
    if (!bypassLimitations) {
      final canCreate = await canCreateTest();
      if (!canCreate) {
        throw TestLimitationException('Limite de tests gratuits atteinte. Passez au premium pour continuer.');
      }
    }
    
    final questions = await _databaseService.getRandomQuestions(limit: questionCount);
    
    final session = TestSession(
      id: _generateSessionId(),
      questions: questions,
      type: TestType.mixed,
      startTime: DateTime.now(),
      totalTimeLimit: totalTimeLimit ?? 0,
      questionTimeLimit: questionTimeLimit ?? 0,
    );

    return session;
  }

  Future<TestSession> createCategoryTest({
    required String category,
    int questionCount = 15,
    String? level,
    int? totalTimeLimit,
    int? questionTimeLimit,
    bool bypassLimitations = false,
  }) async {
    // Vérifier les limitations sauf si bypassé
    if (!bypassLimitations) {
      final canCreate = await canCreateTest();
      if (!canCreate) {
        throw TestLimitationException('Limite de tests gratuits atteinte. Passez au premium pour continuer.');
      }
    }
    List<Question> questions;
    
    if (level != null) {
      // Filtrer par catégorie et niveau
      final allQuestions = await _databaseService.getQuestionsByCategory(category);
      questions = allQuestions.where((q) => q.niveau == level).toList();
      questions.shuffle();
      questions = questions.take(questionCount).toList();
    } else {
      questions = await _databaseService.getRandomQuestions(
        limit: questionCount,
        category: category,
      );
    }

    final session = TestSession(
      id: _generateSessionId(),
      questions: questions,
      type: TestType.specific,
      startTime: DateTime.now(),
      category: category,
      level: level,
      totalTimeLimit: totalTimeLimit ?? 0,
      questionTimeLimit: questionTimeLimit ?? 0,
    );

    return session;
  }

  Future<TestSession> createAdaptiveTest({
    int initialQuestionCount = 10,
    int? totalTimeLimit,
    bool bypassLimitations = false,
  }) async {
    // Vérifier les limitations sauf si bypassé
    if (!bypassLimitations) {
      final canCreate = await canCreateTest();
      if (!canCreate) {
        throw TestLimitationException('Limite de tests gratuits atteinte. Passez au premium pour continuer.');
      }
    }
    // Commencer avec des questions faciles
    final questions = await _databaseService.getRandomQuestions(
      limit: initialQuestionCount,
      level: 'facile',
    );

    final session = TestSession(
      id: _generateSessionId(),
      questions: questions,
      type: TestType.adaptive,
      startTime: DateTime.now(),
      totalTimeLimit: totalTimeLimit ?? 0,
    );

    return session;
  }

  Future<TestSession> createPracticeTest({
    String? category,
    String? level,
    int questionCount = 10,
  }) async {
    // Les tests d'entraînement restent gratuits et sans limitation
    final questions = await _databaseService.getRandomQuestions(
      limit: questionCount,
      category: category,
      level: level,
    );

    final session = TestSession(
      id: _generateSessionId(),
      questions: questions,
      type: TestType.practice,
      startTime: DateTime.now(),
    );

    return session;
  }

  // Gestion des sessions

  Future<void> startSession(TestSession session) async {
    _currentSession = session;
    _currentSession!.start();
    
    _sessionController.add(_currentSession!);
    
    // Incrémenter le compteur de tests gratuits utilisés
    // seulement pour les tests non-pratiques
    if (session.type != TestType.practice) {
      final isPremium = await _subscriptionService.isPremiumUser();
      if (!isPremium) {
        await _subscriptionService.incrementFreeTestsUsed();
        print('[TestService] Test gratuit comptabilisé. Session ID: ${session.id}');
      }
    }
    
    // Démarrer les timers si nécessaire
    if (session.totalTimeLimit > 0) {
      _startSessionTimer(session.totalTimeLimit);
    }
    
    if (session.questionTimeLimit > 0) {
      _startQuestionTimer(session.questionTimeLimit);
    }

    // Sauvegarder l'état
    await _saveSessionState();
  }

  Future<void> pauseSession() async {
    if (_currentSession == null || !_currentSession!.isInProgress) return;
    
    _currentSession!.pause();
    _stopTimers();
    _sessionController.add(_currentSession!);
    
    await _saveSessionState();
  }

  Future<void> resumeSession() async {
    if (_currentSession == null || _currentSession!.status != TestStatus.paused) return;
    
    _currentSession!.resume();
    _sessionController.add(_currentSession!);
    
    // Redémarrer les timers avec le temps restant
    // TODO: Calculer le temps restant
    
    await _saveSessionState();
  }

  Future<TestResult> completeSession() async {
    if (_currentSession == null) throw Exception('Aucune session active');
    
    _currentSession!.complete();
    _stopTimers();
    
    final result = _currentSession!.calculateResult();
    
    // Sauvegarder le résultat
    await _saveTestResult(result);
    
    // Nettoyer la session courante
    final completedSession = _currentSession!;
    _currentSession = null;
    
    _sessionController.add(completedSession);
    
    // Vérifier si l'utilisateur a atteint la limite de tests gratuits
    await _checkFreeTestLimit();
    
    return result;
  }

  Future<void> abandonSession() async {
    if (_currentSession == null) return;
    
    _currentSession!.abandon();
    _stopTimers();
    
    final abandonedSession = _currentSession!;
    _currentSession = null;
    
    _sessionController.add(abandonedSession);
    await _clearSessionState();
  }

  // Navigation et réponses

  Future<void> answerCurrentQuestion(String answer) async {
    if (_currentSession == null || !_currentSession!.isInProgress) return;
    
    _currentSession!.answerQuestion(answer);
    _sessionController.add(_currentSession!);
    
    await _saveSessionState();
    
    // Adapter la difficulté si c'est un test adaptatif
    if (_currentSession!.type == TestType.adaptive) {
      await _adaptDifficulty();
    }

    // Redémarrer le timer de question si configuré
    if (_currentSession!.questionTimeLimit > 0) {
      _startQuestionTimer(_currentSession!.questionTimeLimit);
    }
  }

  Future<bool> nextQuestion() async {
    if (_currentSession == null) return false;
    
    final hasNext = _currentSession!.nextQuestion();
    if (hasNext) {
      _sessionController.add(_currentSession!);
      
      // Redémarrer le timer de question
      if (_currentSession!.questionTimeLimit > 0) {
        _startQuestionTimer(_currentSession!.questionTimeLimit);
      }
      
      await _saveSessionState();
    }
    
    return hasNext;
  }

  Future<bool> previousQuestion() async {
    if (_currentSession == null) return false;
    
    final hasPrevious = _currentSession!.previousQuestion();
    if (hasPrevious) {
      _sessionController.add(_currentSession!);
      
      // Redémarrer le timer de question
      if (_currentSession!.questionTimeLimit > 0) {
        _startQuestionTimer(_currentSession!.questionTimeLimit);
      }
      
      await _saveSessionState();
    }
    
    return hasPrevious;
  }

  Future<void> goToQuestion(int index) async {
    if (_currentSession == null) return;
    
    _currentSession!.goToQuestion(index);
    _sessionController.add(_currentSession!);
    
    // Redémarrer le timer de question
    if (_currentSession!.questionTimeLimit > 0) {
      _startQuestionTimer(_currentSession!.questionTimeLimit);
    }
    
    await _saveSessionState();
  }

  // Timers

  void _startSessionTimer(int totalSeconds) {
    _stopSessionTimer();
    
    var remainingTime = totalSeconds;
    _timerController.add(remainingTime);
    
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingTime--;
      _timerController.add(remainingTime);
      
      if (remainingTime <= 0) {
        timer.cancel();
        // Auto-compléter la session quand le temps est écoulé
        completeSession();
      }
    });
  }

  void _startQuestionTimer(int seconds) {
    _stopQuestionTimer();
    
    var remainingTime = seconds;
    _questionTimerController.add(remainingTime);
    
    _questionTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      remainingTime--;
      _questionTimerController.add(remainingTime);
      
      if (remainingTime <= 0) {
        timer.cancel();
        // Passer automatiquement à la question suivante
        nextQuestion();
      }
    });
  }

  void _stopTimers() {
    _stopSessionTimer();
    _stopQuestionTimer();
  }

  void _stopSessionTimer() {
    _sessionTimer?.cancel();
    _sessionTimer = null;
  }

  void _stopQuestionTimer() {
    _questionTimer?.cancel();
    _questionTimer = null;
  }

  // Adaptativité

  Future<void> _adaptDifficulty() async {
    if (_currentSession == null || _currentSession!.type != TestType.adaptive) return;
    
    final currentAnswered = _currentSession!.answeredCount;
    if (currentAnswered < 5) return; // Attendre au moins 5 réponses
    
    // Calculer le taux de réussite récent
    final recentAnswers = _currentSession!.userAnswers.values.take(5).toList();
    final recentQuestions = _currentSession!.questions.take(currentAnswered).take(5).toList();
    
    int correctRecent = 0;
    for (int i = 0; i < recentQuestions.length; i++) {
      if (recentQuestions[i].reponse == recentAnswers[i]) {
        correctRecent++;
      }
    }
    
    final successRate = correctRecent / recentQuestions.length;
    
    // Adapter selon le taux de réussite
    String targetLevel;
    if (successRate >= 0.8) {
      targetLevel = 'difficile';
    } else if (successRate >= 0.6) {
      targetLevel = 'moyen';
    } else {
      targetLevel = 'facile';
    }
    
    // Ajouter des questions du niveau approprié si nécessaire
    if (_currentSession!.questions.length < 20) {
      final additionalQuestions = await _databaseService.getRandomQuestions(
        limit: 5,
        level: targetLevel,
      );
      
      _currentSession!.questions.addAll(additionalQuestions);
    }
  }

  // Persistance

  Future<void> _saveSessionState() async {
    if (_currentSession == null) return;
    
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = json.encode(_currentSession!.toJson());
    await prefs.setString('current_test_session', sessionJson);
  }

  Future<void> _clearSessionState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_test_session');
  }

  Future<void> loadSavedSession() async {
    final prefs = await SharedPreferences.getInstance();
    final sessionJson = prefs.getString('current_test_session');
    
    if (sessionJson != null) {
      try {
        final sessionMap = json.decode(sessionJson);
        _currentSession = TestSession.fromJson(sessionMap);
        
        // Vérifier si la session est encore valide
        if (_currentSession!.isInProgress) {
          _sessionController.add(_currentSession!);
        } else {
          _clearSessionState();
          _currentSession = null;
        }
      } catch (e) {
        print('Erreur lors du chargement de la session sauvegardée: \$e');
        _clearSessionState();
      }
    }
  }

  Future<void> _saveTestResult(TestResult result) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Charger les résultats existants
    final existingResults = prefs.getStringList('test_results') ?? [];
    
    // Ajouter le nouveau résultat
    existingResults.add(json.encode(result.toJson()));
    
    // Garder seulement les 50 derniers résultats
    if (existingResults.length > 50) {
      existingResults.removeRange(0, existingResults.length - 50);
    }
    
    await prefs.setStringList('test_results', existingResults);
    
    // Mettre à jour les statistiques utilisateur
    await _updateUserStatistics(result);
  }

  Future<List<TestResult>> getTestHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final resultStrings = prefs.getStringList('test_results') ?? [];
    
    return resultStrings.map((resultString) {
      final resultMap = json.decode(resultString);
      return TestResult(
        sessionId: resultMap['sessionId'],
        totalQuestions: resultMap['totalQuestions'],
        correctAnswers: resultMap['correctAnswers'],
        incorrectAnswers: resultMap['incorrectAnswers'],
        unansweredQuestions: resultMap['unansweredQuestions'],
        totalDuration: Duration(milliseconds: resultMap['totalDuration']),
        categoryResults: (resultMap['categoryResults'] as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, CategoryResult(
              category: v['category'],
              totalQuestions: v['totalQuestions'],
              correctAnswers: v['correctAnswers'],
              incorrectAnswers: v['incorrectAnswers'],
              score: v['score'],
            ))),
        questionResults: [], // Pas besoin de charger tous les détails pour l'historique
        score: resultMap['score'],
        level: resultMap['level'],
        completedAt: DateTime.parse(resultMap['completedAt']),
      );
    }).toList()..sort((a, b) => b.completedAt.compareTo(a.completedAt));
  }

  // Statistiques

  Future<Map<String, dynamic>> getUserStats() async {
    final history = await getTestHistory();
    
    if (history.isEmpty) {
      return {
        'totalTests': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'totalTimeSpent': Duration.zero,
        'categoryStats': <String, dynamic>{},
      };
    }
    
    final totalTests = history.length;
    final averageScore = history.map((r) => r.score).reduce((a, b) => a + b) / totalTests;
    final bestScore = history.map((r) => r.score).reduce(math.max);
    final totalTime = history.map((r) => r.totalDuration).reduce((a, b) => a + b);
    
    // Statistiques par catégorie
    final categoryStats = <String, Map<String, dynamic>>{};
    for (final result in history) {
      result.categoryResults.forEach((category, categoryResult) {
        if (!categoryStats.containsKey(category)) {
          categoryStats[category] = {
            'totalQuestions': 0,
            'correctAnswers': 0,
            'averageScore': 0.0,
          };
        }
        
        categoryStats[category]!['totalQuestions'] = 
            (categoryStats[category]!['totalQuestions'] as int) + categoryResult.totalQuestions;
        categoryStats[category]!['correctAnswers'] = 
            (categoryStats[category]!['correctAnswers'] as int) + categoryResult.correctAnswers;
      });
    }
    
    // Calculer les scores moyens par catégorie
    categoryStats.forEach((category, stats) {
      final total = stats['totalQuestions'] as int;
      final correct = stats['correctAnswers'] as int;
      stats['averageScore'] = total > 0 ? (correct / total) * 100 : 0.0;
    });
    
    return {
      'totalTests': totalTests,
      'averageScore': averageScore,
      'bestScore': bestScore,
      'totalTimeSpent': totalTime,
      'categoryStats': categoryStats,
    };
  }

  // Utilitaires

  String _generateSessionId() {
    final now = DateTime.now();
    return '${now.millisecondsSinceEpoch}';
  }

  void dispose() {
    _stopTimers();
    _sessionController.close();
    _timerController.close();
    _questionTimerController.close();
  }

  // Vérifier la limite de tests gratuits et afficher le prompt si nécessaire
  Future<void> _checkFreeTestLimit() async {
    try {
      final isPremium = await _subscriptionService.isPremiumUser();
      if (isPremium) return; // Pas de vérification pour les utilisateurs premium
      
      final remainingTests = await _subscriptionService.getRemainingFreeTests();
      
      // Si l'utilisateur a utilisé ses 2 tests gratuits, on peut déclencher une action
      // (par exemple, afficher une notification ou un flag pour l'UI)
      if (remainingTests <= 0) {
        print('[TestService] Utilisateur a atteint la limite de tests gratuits');
        // Le prompt sera affiché par l'écran de résultats
      }
    } catch (e) {
      print('[TestService] Erreur lors de la vérification des tests gratuits: $e');
    }
  }

  /// Met à jour les statistiques utilisateur après un test
  Future<void> _updateUserStatistics(TestResult result) async {
    try {
      final userDataService = UserDataService();
      
      // Calculer le score en pourcentage
      final scorePercentage = result.totalQuestions > 0 
          ? (result.correctAnswers / result.totalQuestions) * 100 
          : 0.0;
      
      // Mettre à jour le nombre de tests complétés
      final currentProgress = await userDataService.getUserProgress();
      final newTestsCompleted = (currentProgress['testsCompleted'] as int) + 1;
      
      // Calculer le nouveau score moyen
      final currentAverage = currentProgress['averageScore'] as double;
      final totalTests = newTestsCompleted;
      final newAverage = totalTests > 1 
          ? ((currentAverage * (totalTests - 1)) + scorePercentage) / totalTests
          : scorePercentage;
      
      // Calculer la série d'étude (simulation basée sur les tests récents)
      final studyStreak = await _calculateStudyStreak();
      
      // Sauvegarder les statistiques générales
      await userDataService.saveUserProgress({
        'testsCompleted': newTestsCompleted,
        'averageScore': newAverage,
        'studyStreak': studyStreak,
      });
      
      // Mettre à jour les progrès par catégorie
      await _updateCategoryProgress(result, scorePercentage);
      
    } catch (e) {
      print('Erreur lors de la mise à jour des statistiques: $e');
    }
  }

  /// Met à jour les progrès par catégorie
  Future<void> _updateCategoryProgress(TestResult result, double overallScore) async {
    try {
      final userDataService = UserDataService();
      
      // Mettre à jour chaque catégorie basée sur les résultats
      for (final categoryResult in result.categoryResults.values) {
        final categoryId = _getCategoryIdFromName(categoryResult.category);
        if (categoryId != null) {
          // Calculer le score de cette catégorie
          final categoryScore = categoryResult.totalQuestions > 0 
              ? (categoryResult.correctAnswers / categoryResult.totalQuestions) * 100 
              : 0.0;
          
          // Obtenir le progrès actuel de cette catégorie
          final currentProgress = await userDataService.getCategoryProgress(categoryId);
          
          // Calculer le nouveau progrès (moyenne pondérée)
          final newProgress = _calculateWeightedProgress(currentProgress, categoryScore);
          
          // Sauvegarder le nouveau progrès
          await userDataService.updateCategoryProgress(categoryId, newProgress);
        }
      }
    } catch (e) {
      print('Erreur lors de la mise à jour des progrès de catégorie: $e');
    }
  }

  /// Calcule un progrès pondéré basé sur l'historique
  double _calculateWeightedProgress(double currentProgress, double newScore) {
    // Si c'est le premier test, utiliser directement le score
    if (currentProgress == 0.0) {
      return newScore;
    }
    
    // Sinon, calculer une moyenne pondérée (70% historique, 30% nouveau score)
    return (currentProgress * 0.7) + (newScore * 0.3);
  }

  /// Convertit le nom de catégorie en ID
  String? _getCategoryIdFromName(String categoryName) {
    final categoryMap = {
      'Logique': '1',
      'Mémoire': '2', 
      'Attention': '3',
      'Calcul': '4',
      'Spatial': '5',
      'Verbal': '6',
    };
    return categoryMap[categoryName];
  }

  /// Calcule la série d'étude basée sur les tests récents
  Future<int> _calculateStudyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final resultStrings = prefs.getStringList('test_results') ?? [];
      
      if (resultStrings.isEmpty) return 0;
      
      // Analyser les dates des tests pour calculer la série
      final now = DateTime.now();
      int streak = 0;
      
      // Vérifier les 30 derniers jours
      for (int i = 0; i < 30; i++) {
        final checkDate = now.subtract(Duration(days: i));
        final hasTestOnDate = resultStrings.any((resultString) {
          try {
            final resultMap = json.decode(resultString);
            final testDate = DateTime.parse(resultMap['completedAt']);
            return testDate.year == checkDate.year &&
                   testDate.month == checkDate.month &&
                   testDate.day == checkDate.day;
          } catch (e) {
            return false;
          }
        });
        
        if (hasTestOnDate) {
          streak++;
        } else if (i > 0) { // Ne pas casser la série le jour même
          break;
        }
      }
      
      return streak;
    } catch (e) {
      return 0;
    }
  }
}

/// Exception levée quand l'utilisateur a atteint sa limite de tests gratuits
class TestLimitationException implements Exception {
  final String message;
  
  const TestLimitationException(this.message);
  
  @override
  String toString() => 'TestLimitationException: $message';
}
