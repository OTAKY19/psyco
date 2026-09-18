class ExamConfig {
  final String name;
  final int questionCount;
  final int timeLimitMinutes;
  final int secondsPerQuestion;

  const ExamConfig({
    required this.name,
    required this.questionCount,
    required this.timeLimitMinutes,
    required this.secondsPerQuestion,
  });

  static const ExamConfig blancStandard = ExamConfig(
    name: 'ExamBlanc',
    questionCount: 25,
    timeLimitMinutes: 25,
    secondsPerQuestion: 60,
  );

  Duration get duration => Duration(minutes: timeLimitMinutes);
  Duration get questionDuration => Duration(seconds: secondsPerQuestion);

  factory ExamConfig.fromMap(Map<String, dynamic>? map) {
    if (map == null) return blancStandard;
    return ExamConfig(
      name: map['type']?.toString() ?? blancStandard.name,
      questionCount: (map['questionCount'] as num?)?.toInt() ??
          blancStandard.questionCount,
      timeLimitMinutes: (map['timeLimit'] as num?)?.toInt() ??
          blancStandard.timeLimitMinutes,
      secondsPerQuestion: (map['secondsPerQuestion'] as num?)?.toInt() ??
          blancStandard.secondsPerQuestion,
    );
  }

  Map<String, dynamic> toMap() => {
        'type': name,
        'questionCount': questionCount,
        'timeLimit': timeLimitMinutes * 60,
        'secondsPerQuestion': secondsPerQuestion,
      };
}