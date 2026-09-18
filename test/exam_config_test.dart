import 'package:flutter_test/flutter_test.dart';

import 'package:psychotest_plus/models/exam_config.dart';

// ET4 : le blanc d'examen est 25 questions / 25 minutes / 60 s par question,
// et fromMap/toMap respectent ce contrat (avec défauts sur map null ou partielle).
void main() {
  group('blancStandard (ET4)', () {
    test('25 questions / 25 min / 60 s par question', () {
      const config = ExamConfig.blancStandard;
      expect(config.name, 'ExamBlanc');
      expect(config.questionCount, 25);
      expect(config.timeLimitMinutes, 25);
      expect(config.secondsPerQuestion, 60);
      expect(config.duration, const Duration(minutes: 25));
      expect(config.questionDuration, const Duration(seconds: 60));
    });
  });

  group('fromMap', () {
    test('map null ou vide → défauts blancStandard', () {
      final fromNull = ExamConfig.fromMap(null);
      expect(fromNull.questionCount, 25);
      expect(fromNull.timeLimitMinutes, 25);
      expect(fromNull.secondsPerQuestion, 60);

      final fromEmpty = ExamConfig.fromMap(<String, dynamic>{});
      expect(fromEmpty.name, 'ExamBlanc');
      expect(fromEmpty.questionCount, 25);
      expect(fromEmpty.timeLimitMinutes, 25);
      expect(fromEmpty.secondsPerQuestion, 60);
    });

    test('map partielle → valeurs fournies, défauts sinon', () {
      final config = ExamConfig.fromMap({
        'type': 'Rattrapage',
        'questionCount': 30,
      });
      expect(config.name, 'Rattrapage');
      expect(config.questionCount, 30);
      expect(config.timeLimitMinutes, 25); // défaut
      expect(config.secondsPerQuestion, 60); // défaut
    });
  });

  group('toMap', () {
    test('blancStandard sérialise montant/minutes et durées', () {
      final map = ExamConfig.blancStandard.toMap();
      expect(map['type'], 'ExamBlanc');
      expect(map['questionCount'], 25);
      expect(map['timeLimit'], 25 * 60);
      expect(map['secondsPerQuestion'], 60);
    });
  });
}