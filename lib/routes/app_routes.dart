import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../presentation/test_taking_screen/test_taking_screen.dart';
import '../presentation/test_category_screen/test_category_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/progress_tracking_screen/progress_tracking_screen.dart';
import '../presentation/test_results_screen/test_results_screen.dart';
import '../presentation/test_library_dashboard/test_library_dashboard.dart';
import '../presentation/payment_verification_screen/payment_verification_screen.dart';
import '../presentation/integration_flow_screen/integration_flow_screen.dart';
import '../presentation/free_tests_limit_screen/free_tests_limit_screen.dart';
import '../presentation/mobile_money_payment_screen/mobile_money_payment_screen.dart';
import '../presentation/payment_confirmation_screen/payment_confirmation_screen.dart';
import '../presentation/simulation_selection_screen/simulation_selection_screen.dart';
import '../presentation/simulation_screen/simulation_screen.dart';
import '../presentation/exam_blanc_screen/exam_blanc_screen.dart';
import '../presentation/exam_taking_screen/exam_taking_screen.dart';
import '../presentation/exam_results_screen/exam_results_screen.dart';
import '../presentation/progress_exam_results_screen.dart';
import '../presentation/payment_screen/payment_screen.dart';
import '../presentation/admin_screen/admin_screen.dart';
import '../presentation/exam_screen/exam_screen.dart';
import '../presentation/activation_screen/activation_screen.dart';
import '../presentation/subscription_screen/subscription_screen.dart';
import '../presentation/mtn_payment_screen/mtn_payment_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String paymentVerificationScreen =
      '/payment-verification-screen';
  static const String integrationFlowScreen = '/integration-flow-screen';
  static const String testTaking = '/test-taking-screen';
  static const String testCategory = '/test-category-screen';
  static const String userProfile = '/user-profile-screen';
  static const String progressTracking = '/progress-tracking-screen';
  static const String testResults = '/test-results-screen';
  static const String testLibraryDashboard = '/test-library-dashboard';
  static const String freeTestsLimit = '/free-tests-limit-screen';
  static const String mobileMoneyPayment = '/mobile-money-payment-screen';
  static const String paymentConfirmation = '/payment-confirmation-screen';
  static const String simulationSelection = '/simulation-selection-screen';
  static const String simulation = '/simulation-screen';
  static const String examBlanc = '/exam-blanc-screen';
  static const String examTaking = '/exam-taking-screen';
  static const String examResults = '/exam-results-screen';
  static const String progressExamResults = '/progress-exam-results-screen';
  static const String payment = '/payment-screen';
  static const String admin = '/admin-screen';
  static const String examScreen = '/exam-screen';
  static const String activationScreen = '/activation-screen';
  static const String subscriptionScreen = '/subscription-screen';
  static const String mtnPaymentScreen = '/mtn-payment-screen';

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const HomeScreen(),
    paymentVerificationScreen: (context) => const PaymentVerificationScreen(),
    integrationFlowScreen: (context) => const IntegrationFlowScreen(),
    testTaking: (context) => const TestTakingScreen(),
    testCategory: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TestCategoryScreen(
        categoryName: args?['categoryName'],
        categoryId: args?['categoryId'],
      );
    },
    userProfile: (context) => const UserProfileScreen(),
    progressTracking: (context) => const ProgressTrackingScreen(),
    testResults: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TestResultsScreen(testResults: args);
    },
    testLibraryDashboard: (context) => const TestLibraryDashboard(),
    freeTestsLimit: (context) => const FreeTestsLimitScreen(),
    mobileMoneyPayment: (context) => const MobileMoneyPaymentScreen(),
    paymentConfirmation: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PaymentConfirmationScreen(paymentResult: args);
    },
    simulationSelection: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SimulationSelectionScreen(userId: args?['userId'] ?? '');
    },
    simulation: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return SimulationScreen(
        userId: args?['userId'] ?? '',
        simulation: args?['simulation'],
      );
    },
    examBlanc: (context) => const ExamBlancScreen(),
    examTaking: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ExamTakingScreen(session: args?['session']);
    },
    testTaking: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return TestTakingScreen(testData: args);
    },
    examResults: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ExamResultsScreen(
        result: args?['result'],
      );
    },
    progressExamResults: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ProgressExamResultsScreen(arguments: args);
    },
    payment: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PaymentScreen(
        amount: args?['amount'] ?? 0.0,
        description: args?['description'] ?? '',
        onPaymentSuccess: args?['onPaymentSuccess'],
      );
    },
    admin: (context) => const AdminScreen(),
    examScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ExamScreen(examConfig: args);
    },
    activationScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return ActivationScreen(examResults: args);
    },
    subscriptionScreen: (context) => SubscriptionScreen(),
    mtnPaymentScreen: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return MtnPaymentScreen(
        amount: args?['amount'] ?? 0.0,
        description: args?['description'] ?? '',
        onPaymentSuccess: args?['onPaymentSuccess'],
        onPaymentCancel: args?['onPaymentCancel'],
      );
    },
  };
}
