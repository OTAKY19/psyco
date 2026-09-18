import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:psychotest_plus/models/question.dart';
import 'package:psychotest_plus/presentation/test_taking_screen/test_taking_screen.dart';
import 'package:psychotest_plus/services/test_service.dart';

// E5 (T11) : sauvegarde partielle + reprise d'un entraînement.
// Si ces tests cassent, une sortie accidentelle fait perdre le test.
Question _q(int id, String text) => Question(
      id: id,
      categorie: 'logique',
      question: text,
      options: const ['A1', 'B1'],
      reponse: 'A1',
      explication: 'exp',
      niveau: 'facile',
      probaSimple: 0.5,
    );

Future<void> _pumpTaking(
  WidgetTester tester,
  TestService svc,
) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ChangeNotifierProvider<TestService>.value(
        value: svc,
        child: const TestTakingScreen(testData: null),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Reprise entraînement', () {
    testWidgets('répondre persiste une sauvegarde partielle',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final svc = TestService()
        ..loadQuestions([_q(1, 'Première ?'), _q(2, 'Deuxième ?')]);
      await _pumpTaking(tester, svc);

      await tester.tap(find.text('A1').first);
      await tester.pump();

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('training_partial');
      expect(raw, isNotNull);
      final map = Map<String, dynamic>.from(jsonDecode(raw!) as Map);
      expect(map['testId'], 'default_test');
      expect(map['index'], 0);

      // Dispose propre (coupe le timer périodique).
      await tester.pumpWidget(Container());
    });

    testWidgets('relance propose Reprendre et restaure la question',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'training_partial': jsonEncode({
          'testId': 'default_test',
          'index': 1,
          'answers': ['A1', null],
          'remaining': 1500,
          'at': DateTime.now().toIso8601String(),
        }),
      });
      final svc = TestService()
        ..loadQuestions([_q(1, 'Première ?'), _q(2, 'Deuxième ?')]);
      await _pumpTaking(tester, svc);

      expect(find.text('Reprendre le test ?'), findsOneWidget);
      await tester.tap(find.text('Reprendre'));
      await tester.pumpAndSettle();

      // Index 1 restauré : la deuxième question est affichée.
      expect(find.text('Deuxième ?'), findsOneWidget);

      await tester.pumpWidget(Container());
    });
  });
}
