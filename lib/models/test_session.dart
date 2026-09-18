class TestSession {
  final String id;
  final String testId;
  final String userId;
  final DateTime startTime;
  final DateTime? endTime;
  final int currentQuestionIndex;
  final List<String> answers;
  final bool isCompleted;
  final Map<String, dynamic>? results;

  TestSession({
    required this.id,
    required this.testId,
    required this.userId,
    required this.startTime,
    this.endTime,
    this.currentQuestionIndex = 0,
    this.answers = const [],
    this.isCompleted = false,
    this.results,
  });

  TestSession copyWith({
    String? id,
    String? testId,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    int? currentQuestionIndex,
    List<String>? answers,
    bool? isCompleted,
    Map<String, dynamic>? results,
  }) {
    return TestSession(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      isCompleted: isCompleted ?? this.isCompleted,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'testId': testId,
      'userId': userId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'currentQuestionIndex': currentQuestionIndex,
      'answers': answers,
      'isCompleted': isCompleted,
      'results': results,
    };
  }

  factory TestSession.fromJson(Map<String, dynamic> json) {
    return TestSession(
      id: json['id'],
      testId: json['testId'],
      userId: json['userId'],
      startTime: DateTime.parse(json['startTime']),
      endTime: json['endTime'] != null ? DateTime.parse(json['endTime']) : null,
      currentQuestionIndex: json['currentQuestionIndex'] ?? 0,
      answers: List<String>.from(json['answers'] ?? []),
      isCompleted: json['isCompleted'] ?? false,
      results: json['results'],
    );
  }
}
