#!/usr/bin/env dart
// Test script to validate all routes used in the drawer are properly defined

import 'lib/routes/app_routes.dart';

void main() {
  print('🧪 PHASE 5: TESTS DE VALIDATION DES ROUTES');
  print('=' * 50);

  // Routes utilisées dans le menu latéral du HomeScreen
  final drawerRoutes = [
    // Paiements
    AppRoutes.mobileMoneyPayment,
    AppRoutes.paymentConfirmation,
    AppRoutes.paymentVerificationScreen,

    // Simulations
    AppRoutes.simulation,

    // Tests spéciaux
    AppRoutes.testTaking,
    AppRoutes.testResults,

    // Examens spéciaux
    AppRoutes.examTaking,
    AppRoutes.examResults,

    // Limites & Flux
    AppRoutes.freeTestsLimit,
    AppRoutes.integrationFlowScreen,

    // Administration
    AppRoutes.admin,
  ];

  // Routes utilisées dans les boutons principaux du HomeScreen
  final mainButtonRoutes = [
    AppRoutes.userProfile,
    AppRoutes.examBlanc,
    AppRoutes.testCategory,
    AppRoutes.testLibraryDashboard,
    AppRoutes.progressTracking,
    AppRoutes.simulationSelection,
    AppRoutes.examScreen,
    AppRoutes.activationScreen,
    AppRoutes.admin, // accès admin
  ];

  print('📋 VÉRIFICATION DES ROUTES DU MENU LATÉRAL');
  print('-' * 40);

  bool allDrawerRoutesValid = true;
  for (final route in drawerRoutes) {
    if (AppRoutes.routes.containsKey(route)) {
      print('✅ $route - VALIDE');
    } else {
      print('❌ $route - MANQUANTE dans AppRoutes');
      allDrawerRoutesValid = false;
    }
  }

  print('\n📋 VÉRIFICATION DES ROUTES DES BOUTONS PRINCIPAUX');
  print('-' * 40);

  bool allMainRoutesValid = true;
  for (final route in mainButtonRoutes) {
    if (AppRoutes.routes.containsKey(route)) {
      print('✅ $route - VALIDE');
    } else {
      print('❌ $route - MANQUANTE dans AppRoutes');
      allMainRoutesValid = false;
    }
  }

  print('\n📊 RÉSULTATS DES TESTS');
  print('=' * 30);

  final totalRoutes = drawerRoutes.length + mainButtonRoutes.length;
  final validRoutes = (allDrawerRoutesValid ? drawerRoutes.length : 0) +
                     (allMainRoutesValid ? mainButtonRoutes.length : 0);

  print('Routes du menu latéral: ${drawerRoutes.length}');
  print('Routes des boutons principaux: ${mainButtonRoutes.length}');
  print('Total des routes testées: $totalRoutes');
  print('Routes valides: $validRoutes');

  if (allDrawerRoutesValid && allMainRoutesValid) {
    print('\n🎉 SUCCÈS: TOUTES LES ROUTES SONT VALIDES!');
    print('✅ Navigation prête pour les tests end-to-end');
  } else {
    print('\n❌ ÉCHEC: Certaines routes sont manquantes');
    print('🔧 Corriger les routes manquantes avant les tests');
  }

  print('\n🏁 PHASE 5 TERMINÉE');
}
