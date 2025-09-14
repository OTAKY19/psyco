
class SimulationModel {
  final String id;
  final String title;
  final String description;
  final int totalQuestions;
  final Duration totalDuration; // 40 minutes
  final Duration questionDuration; // 1 minute par question
  final List<String> categories;
  final String difficulty;
  final DateTime createdAt;
  final bool isActive;

  SimulationModel({
    required this.id,
    required this.title,
    required this.description,
    required this.totalQuestions,
    required this.totalDuration,
    required this.questionDuration,
    required this.categories,
    required this.difficulty,
    required this.createdAt,
    this.isActive = true,
  });

  factory SimulationModel.fromMap(Map<String, dynamic> map) {
    return SimulationModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      totalQuestions: map['totalQuestions'] ?? 40,
      totalDuration: Duration(minutes: map['totalDurationMinutes'] ?? 40),
      questionDuration: Duration(seconds: map['questionDurationSeconds'] ?? 60),
      categories: List<String>.from(map['categories'] ?? []),
      difficulty: map['difficulty']?.toString() ?? 'moyen',
      createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'totalQuestions': totalQuestions,
      'totalDurationMinutes': totalDuration.inMinutes,
      'questionDurationSeconds': questionDuration.inSeconds,
      'categories': categories,
      'difficulty': difficulty,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  SimulationModel copyWith({
    String? id,
    String? title,
    String? description,
    int? totalQuestions,
    Duration? totalDuration,
    Duration? questionDuration,
    List<String>? categories,
    String? difficulty,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return SimulationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      totalDuration: totalDuration ?? this.totalDuration,
      questionDuration: questionDuration ?? this.questionDuration,
      categories: categories ?? this.categories,
      difficulty: difficulty ?? this.difficulty,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class SimulationQuestion {
  final int id;
  final String categorie;
  final String question;
  final List<String> options;
  final String reponse;
  final String explication;
  final String niveau;
  final double probaSimple;
  final bool imageRequired;
  final String? image;

  SimulationQuestion({
    required this.id,
    required this.categorie,
    required this.question,
    required this.options,
    required this.reponse,
    required this.explication,
    required this.niveau,
    required this.probaSimple,
    required this.imageRequired,
    this.image,
  });

  factory SimulationQuestion.fromMap(Map<String, dynamic> map) {
    return SimulationQuestion(
      id: map['id'] ?? 0,
      categorie: map['categorie']?.toString() ?? '',
      question: map['question']?.toString() ?? '',
      options: List<String>.from(map['options'] ?? []),
      reponse: map['reponse']?.toString() ?? '',
      explication: map['explication']?.toString() ?? '',
      niveau: map['niveau']?.toString() ?? 'facile',
      probaSimple: (map['proba_simple'] ?? 0.0).toDouble(),
      imageRequired: map['image_required'] ?? false,
      image: map['image']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'categorie': categorie,
      'question': question,
      'options': options,
      'reponse': reponse,
      'explication': explication,
      'niveau': niveau,
      'proba_simple': probaSimple,
      'image_required': imageRequired,
      'image': image,
    };
  }
}

class SimulationSession {
  final String id;
  final String simulationId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration totalDuration;
  final Duration questionDuration;
  final List<SimulationQuestion> questions;
  final List<SimulationAnswer> answers;
  final SimulationStatus status;
  final int currentQuestionIndex;
  final Duration remainingTime;
  final Duration currentQuestionRemainingTime;

  SimulationSession({
    required this.id,
    required this.simulationId,
    required this.userId,
    required this.startTime,
    this.endTime,
    required this.totalDuration,
    required this.questionDuration,
    required this.questions,
    required this.answers,
    required this.status,
    required this.currentQuestionIndex,
    required this.remainingTime,
    required this.currentQuestionRemainingTime,
  });

  factory SimulationSession.fromMap(Map<String, dynamic> map) {
    return SimulationSession(
      id: map['id']?.toString() ?? '',
      simulationId: map['simulationId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      startTime: DateTime.tryParse(map['startTime']?.toString() ?? '') ?? DateTime.now(),
      endTime: map['endTime'] != null ? DateTime.tryParse(map['endTime']?.toString() ?? '') : null,
      totalDuration: Duration(minutes: map['totalDurationMinutes'] ?? 40),
      questionDuration: Duration(seconds: map['questionDurationSeconds'] ?? 60),
      questions: (map['questions'] as List<dynamic>?)
          ?.map((q) => SimulationQuestion.fromMap(q))
          .toList() ?? [],
      answers: (map['answers'] as List<dynamic>?)
          ?.map((a) => SimulationAnswer.fromMap(a))
          .toList() ?? [],
      status: SimulationStatus.values.firstWhere(
        (e) => e.toString() == 'SimulationStatus.${map['status']}',
        orElse: () => SimulationStatus.notStarted,
      ),
      currentQuestionIndex: map['currentQuestionIndex'] ?? 0,
      remainingTime: Duration(seconds: map['remainingTimeSeconds'] ?? 2400), // 40 minutes
      currentQuestionRemainingTime: Duration(seconds: map['currentQuestionRemainingTimeSeconds'] ?? 60),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'simulationId': simulationId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'totalDurationMinutes': totalDuration.inMinutes,
      'questionDurationSeconds': questionDuration.inSeconds,
      'questions': questions.map((q) => q.toMap()).toList(),
      'answers': answers.map((a) => a.toMap()).toList(),
      'status': status.toString().split('.').last,
      'currentQuestionIndex': currentQuestionIndex,
      'remainingTimeSeconds': remainingTime.inSeconds,
      'currentQuestionRemainingTimeSeconds': currentQuestionRemainingTime.inSeconds,
    };
  }

  SimulationSession copyWith({
    String? id,
    String? simulationId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    Duration? totalDuration,
    Duration? questionDuration,
    List<SimulationQuestion>? questions,
    List<SimulationAnswer>? answers,
    SimulationStatus? status,
    int? currentQuestionIndex,
    Duration? remainingTime,
    Duration? currentQuestionRemainingTime,
  }) {
    return SimulationSession(
      id: id ?? this.id,
      simulationId: simulationId ?? this.simulationId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      totalDuration: totalDuration ?? this.totalDuration,
      questionDuration: questionDuration ?? this.questionDuration,
      questions: questions ?? this.questions,
      answers: answers ?? this.answers,
      status: status ?? this.status,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      currentQuestionRemainingTime: currentQuestionRemainingTime ?? this.currentQuestionRemainingTime,
    );
  }
}

class SimulationAnswer {
  final String id;
  final String questionId;
  final String selectedOption;
  final bool isCorrect;
  final Duration timeSpent;
  final DateTime answeredAt;

  SimulationAnswer({
    required this.id,
    required this.questionId,
    required this.selectedOption,
    required this.isCorrect,
    required this.timeSpent,
    required this.answeredAt,
  });

  factory SimulationAnswer.fromMap(Map<String, dynamic> map) {
    return SimulationAnswer(
      id: map['id']?.toString() ?? '',
      questionId: map['questionId']?.toString() ?? '',
      selectedOption: map['selectedOption']?.toString() ?? '',
      isCorrect: map['isCorrect'] ?? false,
      timeSpent: Duration(seconds: map['timeSpentSeconds'] ?? 0),
      answeredAt: DateTime.tryParse(map['answeredAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'questionId': questionId,
      'selectedOption': selectedOption,
      'isCorrect': isCorrect,
      'timeSpentSeconds': timeSpent.inSeconds,
      'answeredAt': answeredAt.toIso8601String(),
    };
  }
}

enum SimulationStatus {
  notStarted,
  inProgress,
  paused,
  completed,
  timeUp,
  abandoned,
}

class SimulationResult {
  final String id;
  final String simulationId;
  final String userId;
  final DateTime completedAt;
  final Duration totalTimeSpent;
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int unansweredQuestions;
  final double score;
  final Map<String, int> categoryScores;
  final List<SimulationAnswer> answers;
  final String level;

  SimulationResult({
    required this.id,
    required this.simulationId,
    required this.userId,
    required this.completedAt,
    required this.totalTimeSpent,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.unansweredQuestions,
    required this.score,
    required this.categoryScores,
    required this.answers,
    required this.level,
  });

  factory SimulationResult.fromMap(Map<String, dynamic> map) {
    return SimulationResult(
      id: map['id']?.toString() ?? '',
      simulationId: map['simulationId']?.toString() ?? '',
      userId: map['userId']?.toString() ?? '',
      completedAt: DateTime.tryParse(map['completedAt']?.toString() ?? '') ?? DateTime.now(),
      totalTimeSpent: Duration(seconds: map['totalTimeSpentSeconds'] ?? 0),
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      incorrectAnswers: map['incorrectAnswers'] ?? 0,
      unansweredQuestions: map['unansweredQuestions'] ?? 0,
      score: (map['score'] ?? 0.0).toDouble(),
      categoryScores: Map<String, int>.from(map['categoryScores'] ?? {}),
      answers: (map['answers'] as List<dynamic>?)
          ?.map((a) => SimulationAnswer.fromMap(a))
          .toList() ?? [],
      level: map['level']?.toString() ?? 'débutant',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'simulationId': simulationId,
      'userId': userId,
      'completedAt': completedAt.toIso8601String(),
      'totalTimeSpentSeconds': totalTimeSpent.inSeconds,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'unansweredQuestions': unansweredQuestions,
      'score': score,
      'categoryScores': categoryScores,
      'answers': answers.map((a) => a.toMap()).toList(),
      'level': level,
    };
  }

  String get formattedScore => '${(score * 100).toStringAsFixed(1)}%';
  String get formattedTime => '${totalTimeSpent.inMinutes}:${(totalTimeSpent.inSeconds % 60).toString().padLeft(2, '0')}';
}
