import 'dart:convert';

class Question {
  final int id;
  final int testId;
  final String questionText;
  final String questionType;
  final List<String> options;
  final String correctAnswer;
  final String? explanation;
  final int points;
  final int? timeLimit;
  final String? imageUrl;

  Question({
    required this.id,
    required this.testId,
    required this.questionText,
    required this.questionType,
    required this.options,
    required this.correctAnswer,
    this.explanation,
    required this.points,
    this.timeLimit,
    this.imageUrl,
  });

  factory Question.fromMap(Map<String, dynamic> map) {
    List<String> parsedOptions = [];
    try {
      parsedOptions = List<String>.from(json.decode(map['options'] ?? '[]'));
    } catch (e) {
      parsedOptions = [];
    }

    return Question(
      id: map['id'] ?? 0,
      testId: map['test_id'] ?? 0,
      questionText: map['question_text'] ?? '',
      questionType: map['question_type'] ?? 'multiple_choice',
      options: parsedOptions,
      correctAnswer: map['correct_answer'] ?? '',
      explanation: map['explanation'],
      points: map['points'] ?? 1,
      timeLimit: map['time_limit'],
      imageUrl: map['image_url'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'test_id': testId,
      'question_text': questionText,
      'question_type': questionType,
      'options': json.encode(options),
      'correct_answer': correctAnswer,
      'explanation': explanation,
      'points': points,
      'time_limit': timeLimit,
      'image_url': imageUrl,
    };
  }

  Question copyWith({
    int? id,
    int? testId,
    String? questionText,
    String? questionType,
    List<String>? options,
    String? correctAnswer,
    String? explanation,
    int? points,
    int? timeLimit,
    String? imageUrl,
  }) {
    return Question(
      id: id ?? this.id,
      testId: testId ?? this.testId,
      questionText: questionText ?? this.questionText,
      questionType: questionType ?? this.questionType,
      options: options ?? this.options,
      correctAnswer: correctAnswer ?? this.correctAnswer,
      explanation: explanation ?? this.explanation,
      points: points ?? this.points,
      timeLimit: timeLimit ?? this.timeLimit,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
