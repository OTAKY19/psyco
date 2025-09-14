import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import '../models/simulation_model.dart';

class SimulationService {
  static const String _questionsAssetPath = 'assets/data/questions_douane_benin_500.json';
  
  // Simulation par défaut : 40 questions en 40 minutes, 1 minute par question
  static final SimulationModel defaultSimulation = SimulationModel(
    id: 'simulation_douane_benin',
    title: 'Simulation Test Douane Bénin',
    description: 'Test de simulation officiel avec 40 questions en 40 minutes',
    totalQuestions: 40,
    totalDuration: Duration(minutes: 40),
    questionDuration: Duration(seconds: 60),
    categories: [
      'culture_generale',
      'francais',
      'droit_douane',
      'mathematiques',
      'logique',
      'ethique_personnalite',
    ],
    difficulty: 'moyen',
    createdAt: DateTime.now(),
  );

  /// Charge les questions depuis le fichier JSON
  Future<List<SimulationQuestion>> loadQuestions() async {
    try {
      final String jsonString = await rootBundle.loadString(_questionsAssetPath);
      final List<dynamic> jsonList = json.decode(jsonString);
      
      return jsonList.map((json) => SimulationQuestion.fromMap(json)).toList();
    } catch (e) {
      print('Erreur lors du chargement des questions: $e');
      return [];
    }
  }

  /// Sélectionne 40 questions aléatoires pour la simulation
  Future<List<SimulationQuestion>> selectQuestionsForSimulation() async {
    final allQuestions = await loadQuestions();
    
    if (allQuestions.isEmpty) {
      return [];
    }

    // Mélanger toutes les questions
    final shuffledQuestions = List<SimulationQuestion>.from(allQuestions);
    shuffledQuestions.shuffle(math.Random());

    // Prendre les 40 premières questions
    return shuffledQuestions.take(40).toList();
  }

  /// Crée une nouvelle session de simulation
  Future<SimulationSession> createSimulationSession(String userId) async {
    final questions = await selectQuestionsForSimulation();
    final now = DateTime.now();
    
    return SimulationSession(
      id: 'sim_${now.millisecondsSinceEpoch}',
      simulationId: defaultSimulation.id,
      userId: userId,
      startTime: now,
      totalDuration: defaultSimulation.totalDuration,
      questionDuration: defaultSimulation.questionDuration,
      questions: questions,
      answers: [],
      status: SimulationStatus.notStarted,
      currentQuestionIndex: 0,
      remainingTime: defaultSimulation.totalDuration,
      currentQuestionRemainingTime: defaultSimulation.questionDuration,
    );
  }

  /// Démarre la simulation
  SimulationSession startSimulation(SimulationSession session) {
    return session.copyWith(
      status: SimulationStatus.inProgress,
      startTime: DateTime.now(),
    );
  }

  /// Met en pause la simulation
  SimulationSession pauseSimulation(SimulationSession session) {
    return session.copyWith(
      status: SimulationStatus.paused,
    );
  }

  /// Reprend la simulation
  SimulationSession resumeSimulation(SimulationSession session) {
    return session.copyWith(
      status: SimulationStatus.inProgress,
    );
  }

  /// Enregistre une réponse
  SimulationSession recordAnswer(
    SimulationSession session,
    String questionId,
    String selectedOption,
    Duration timeSpent,
  ) {
    final question = session.questions.firstWhere(
      (q) => q.id.toString() == questionId,
      orElse: () => session.questions.first,
    );

    final isCorrect = selectedOption == question.reponse;
    
    final answer = SimulationAnswer(
      id: 'ans_${DateTime.now().millisecondsSinceEpoch}',
      questionId: questionId,
      selectedOption: selectedOption,
      isCorrect: isCorrect,
      timeSpent: timeSpent,
      answeredAt: DateTime.now(),
    );

    final updatedAnswers = List<SimulationAnswer>.from(session.answers);
    updatedAnswers.add(answer);

    return session.copyWith(
      answers: updatedAnswers,
      currentQuestionIndex: session.currentQuestionIndex + 1,
    );
  }

  /// Passe à la question suivante
  SimulationSession nextQuestion(SimulationSession session) {
    if (session.currentQuestionIndex >= session.questions.length - 1) {
      return completeSimulation(session);
    }

    return session.copyWith(
      currentQuestionIndex: session.currentQuestionIndex + 1,
      currentQuestionRemainingTime: session.questionDuration,
    );
  }

  /// Met à jour le temps restant
  SimulationSession updateRemainingTime(
    SimulationSession session,
    Duration remainingTime,
    Duration currentQuestionRemainingTime,
  ) {
    return session.copyWith(
      remainingTime: remainingTime,
      currentQuestionRemainingTime: currentQuestionRemainingTime,
    );
  }

  /// Vérifie si le temps est écoulé
  bool isTimeUp(SimulationSession session) {
    return session.remainingTime.inSeconds <= 0;
  }

  /// Vérifie si le temps de la question actuelle est écoulé
  bool isQuestionTimeUp(SimulationSession session) {
    return session.currentQuestionRemainingTime.inSeconds <= 0;
  }

  /// Termine la simulation
  SimulationSession completeSimulation(SimulationSession session) {
    return session.copyWith(
      status: SimulationStatus.completed,
      endTime: DateTime.now(),
    );
  }

  /// Termine la simulation par manque de temps
  SimulationSession completeSimulationByTimeUp(SimulationSession session) {
    return session.copyWith(
      status: SimulationStatus.timeUp,
      endTime: DateTime.now(),
    );
  }

  /// Calcule le résultat de la simulation
  SimulationResult calculateSimulationResult(SimulationSession session) {
    final correctAnswers = session.answers.where((a) => a.isCorrect).length;
    final totalQuestions = session.questions.length;
    final incorrectAnswers = session.answers.where((a) => !a.isCorrect).length;
    final unansweredQuestions = totalQuestions - session.answers.length;
    final score = totalQuestions > 0 ? correctAnswers / totalQuestions : 0.0;

    // Calculer les scores par catégorie
    final Map<String, int> categoryScores = {};
    for (final question in session.questions) {
      final answer = session.answers.firstWhere(
        (a) => a.questionId == question.id.toString(),
        orElse: () => SimulationAnswer(
          id: '',
          questionId: question.id.toString(),
          selectedOption: '',
          isCorrect: false,
          timeSpent: Duration.zero,
          answeredAt: DateTime.now(),
        ),
      );
      
      categoryScores[question.categorie] = (categoryScores[question.categorie] ?? 0) + (answer.isCorrect ? 1 : 0);
    }

    // Déterminer le niveau
    String level;
    if (score >= 0.8) {
      level = 'excellent';
    } else if (score >= 0.6) {
      level = 'bien';
    } else if (score >= 0.4) {
      level = 'moyen';
    } else {
      level = 'débutant';
    }

    return SimulationResult(
      id: 'result_${DateTime.now().millisecondsSinceEpoch}',
      simulationId: session.simulationId,
      userId: session.userId,
      completedAt: DateTime.now(),
      totalTimeSpent: session.endTime != null 
          ? session.endTime!.difference(session.startTime)
          : Duration.zero,
      totalQuestions: totalQuestions,
      correctAnswers: correctAnswers,
      incorrectAnswers: incorrectAnswers,
      unansweredQuestions: unansweredQuestions,
      score: score,
      categoryScores: categoryScores,
      answers: session.answers,
      level: level,
    );
  }

  /// Obtient la question actuelle
  SimulationQuestion? getCurrentQuestion(SimulationSession session) {
    if (session.currentQuestionIndex >= session.questions.length) {
      return null;
    }
    return session.questions[session.currentQuestionIndex];
  }

  /// Obtient le progrès de la simulation
  double getProgress(SimulationSession session) {
    return session.questions.isNotEmpty 
        ? session.currentQuestionIndex / session.questions.length 
        : 0.0;
  }

  /// Obtient le pourcentage de temps restant
  double getTimeProgress(SimulationSession session) {
    return session.totalDuration.inSeconds > 0 
        ? session.remainingTime.inSeconds / session.totalDuration.inSeconds 
        : 0.0;
  }

  /// Obtient le pourcentage de temps restant pour la question actuelle
  double getQuestionTimeProgress(SimulationSession session) {
    return session.questionDuration.inSeconds > 0 
        ? session.currentQuestionRemainingTime.inSeconds / session.questionDuration.inSeconds 
        : 0.0;
  }

  /// Formate le temps restant
  String formatTime(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  /// Obtient les statistiques de la simulation
  Map<String, dynamic> getSimulationStats(SimulationSession session) {
    final correctAnswers = session.answers.where((a) => a.isCorrect).length;
    final totalAnswered = session.answers.length;
    final remainingQuestions = session.questions.length - session.currentQuestionIndex;
    
    return {
      'correctAnswers': correctAnswers,
      'totalAnswered': totalAnswered,
      'remainingQuestions': remainingQuestions,
      'progress': getProgress(session),
      'timeProgress': getTimeProgress(session),
      'currentQuestion': session.currentQuestionIndex + 1,
      'totalQuestions': session.questions.length,
    };
  }
}
