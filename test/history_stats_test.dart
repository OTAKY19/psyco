import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psychotest_plus/services/test_service.dart';

// E5 (IA filières) : historique et stats réels — aucune donnée simulée.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Historique et stats', () {
    test('vide au départ, pas de simulation', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = TestService();
      expect(await svc.getTestHistory(), isEmpty);
      final stats = await svc.getUserStats();
      expect(stats['totalTests'], 0);
    });

    test('enregistre puis calcule moyenne et meilleur', () async {
      SharedPreferences.setMockInitialValues({});
      final svc = TestService();
      await svc.recordCompletedTest(
        testId: 't1',
        category: 'logique',
        correctAnswers: 8,
        totalQuestions: 10,
        durationSeconds: 600,
      );
      await svc.recordCompletedTest(
        testId: 't2',
        category: 'numerique',
        correctAnswers: 5,
        totalQuestions: 10,
        durationSeconds: 300,
      );
      final history = await svc.getTestHistory();
      expect(history.length, 2);
      expect(history.first['testId'], 't2');
      final stats = await svc.getUserStats();
      expect(stats['totalTests'], 2);
      expect(stats['averageScore'], 65.0);
      expect(stats['bestScore'], 80.0);
      expect(stats['totalTimeMinutes'], 15);
      expect(stats['categoriesCompleted'], 2);
    });
  });
}
