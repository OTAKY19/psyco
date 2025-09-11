/// Model representing test results and performance data
class TestResultModel {
  final String id;
  final String testId;
  final String userId;
  final String testTitle;
  final String testCategory;
  final int totalQuestions;
  final int answeredQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final int skippedQuestions;
  final double scorePercentage;
  final int timeTaken; // in seconds
  final DateTime completedAt;
  final Map<String, dynamic> detailedResults; // Question-by-question results
  final Map<String, dynamic>? metadata;
  final String status; // 'completed', 'abandoned', 'in_progress'

  TestResultModel({
    required this.id,
    required this.testId,
    required this.userId,
    required this.testTitle,
    required this.testCategory,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.skippedQuestions,
    required this.scorePercentage,
    required this.timeTaken,
    required this.completedAt,
    this.detailedResults = const {},
    this.metadata,
    this.status = 'completed',
  });

  /// Create TestResultModel from JSON
  factory TestResultModel.fromJson(Map<String, dynamic> json) {
    return TestResultModel(
      id: json['id'] ?? '',
      testId: json['testId'] ?? '',
      userId: json['userId'] ?? '',
      testTitle: json['testTitle'] ?? '',
      testCategory: json['testCategory'] ?? '',
      totalQuestions: json['totalQuestions'] ?? 0,
      answeredQuestions: json['answeredQuestions'] ?? 0,
      correctAnswers: json['correctAnswers'] ?? 0,
      incorrectAnswers: json['incorrectAnswers'] ?? 0,
      skippedQuestions: json['skippedQuestions'] ?? 0,
      scorePercentage: (json['scorePercentage'] ?? 0.0).toDouble(),
      timeTaken: json['timeTaken'] ?? 0,
      completedAt: json['completedAt'] != null 
          ? DateTime.parse(json['completedAt']) 
          : DateTime.now(),
      detailedResults: json['detailedResults'] as Map<String, dynamic>? ?? {},
      metadata: json['metadata'] as Map<String, dynamic>?,
      status: json['status'] ?? 'completed',
    );
  }

  /// Convert TestResultModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'userId': userId,
      'testTitle': testTitle,
      'testCategory': testCategory,
      'totalQuestions': totalQuestions,
      'answeredQuestions': answeredQuestions,
      'correctAnswers': correctAnswers,
      'incorrectAnswers': incorrectAnswers,
      'skippedQuestions': skippedQuestions,
      'scorePercentage': scorePercentage,
      'timeTaken': timeTaken,
      'completedAt': completedAt.toIso8601String(),
      'detailedResults': detailedResults,
      'metadata': metadata,
      'status': status,
    };
  }

  /// Get performance grade based on score
  String get performanceGrade {
    if (scorePercentage >= 90) return 'A+';
    if (scorePercentage >= 80) return 'A';
    if (scorePercentage >= 70) return 'B+';
    if (scorePercentage >= 60) return 'B';
    if (scorePercentage >= 50) return 'C+';
    if (scorePercentage >= 40) return 'C';
    return 'D';
  }

  /// Get performance color for UI
  String get performanceColor {
    if (scorePercentage >= 80) return '#4CAF50'; // Green
    if (scorePercentage >= 60) return '#FF9800'; // Orange
    return '#F44336'; // Red
  }

  /// Get time taken in formatted string
  String get formattedTime {
    final minutes = timeTaken ~/ 60;
    final seconds = timeTaken % 60;
    return '${minutes}m ${seconds}s';
  }

  /// Calculate accuracy rate
  double get accuracyRate {
    if (answeredQuestions == 0) return 0.0;
    return (correctAnswers / answeredQuestions * 100);
  }

  /// Check if test was passed (typically 60% or above)
  bool get isPassed {
    return scorePercentage >= 60.0;
  }

  /// Get completion rate
  double get completionRate {
    if (totalQuestions == 0) return 0.0;
    return (answeredQuestions / totalQuestions * 100);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TestResultModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'TestResultModel(id: $id, testTitle: $testTitle, score: ${scorePercentage.toStringAsFixed(1)}%)';
  }
}
