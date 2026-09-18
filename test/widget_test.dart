import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:psychotest_plus/presentation/onboarding_screen/onboarding_screen.dart';

// Smoke test first-run (T3) : l'onboarding s'affiche et pagine sans erreur.
void main() {
  testWidgets('Onboarding affiche 3 slides et pagine', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: OnboardingScreen()),
    );

    expect(
      find.text('Entraînez-vous en conditions réelles'),
      findsOneWidget,
    );
    expect(find.text('Suivant'), findsOneWidget);

    await tester.tap(find.text('Suivant'));
    await tester.pumpAndSettle();

    expect(find.text('Comprenez chaque erreur'), findsOneWidget);
  });
}
