import 'package:flutter/material.dart';
import '../presentation/test_taking_screen/test_taking_screen.dart';
import '../presentation/test_category_screen/test_category_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/progress_tracking_screen/progress_tracking_screen.dart';
import '../presentation/test_results_screen/test_results_screen.dart';
import '../presentation/test_library_dashboard/test_library_dashboard.dart';
import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/login_screen/login_screen.dart';
import '../presentation/registration_screen/registration_screen.dart';
import '../presentation/payment_verification_screen/payment_verification_screen.dart';
import '../presentation/integration_flow_screen/integration_flow_screen.dart';
import '../presentation/free_tests_limit_screen/free_tests_limit_screen.dart';
import '../presentation/mobile_money_payment_screen/mobile_money_payment_screen.dart';
import '../presentation/payment_confirmation_screen/payment_confirmation_screen.dart';

class AppRoutes {
  static const String initial = '/';
  static const String splashScreen = '/splash-screen';
  static const String loginScreen = '/login-screen';
  static const String registrationScreen = '/registration-screen';
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

  static Map<String, WidgetBuilder> routes = {
    initial: (context) => const SplashScreen(),
    splashScreen: (context) => const SplashScreen(),
    loginScreen: (context) => const LoginScreen(),
    registrationScreen: (context) => const RegistrationScreen(),
    paymentVerificationScreen: (context) => const PaymentVerificationScreen(),
    integrationFlowScreen: (context) => const IntegrationFlowScreen(),
    testTaking: (context) => const TestTakingScreen(),
    testCategory: (context) => const TestCategoryScreen(),
    userProfile: (context) => const UserProfileScreen(),
    progressTracking: (context) => const ProgressTrackingScreen(),
    testResults: (context) => const TestResultsScreen(),
    testLibraryDashboard: (context) => const TestLibraryDashboard(),
    freeTestsLimit: (context) => const FreeTestsLimitScreen(),
    mobileMoneyPayment: (context) => const MobileMoneyPaymentScreen(),
    paymentConfirmation: (context) {
      final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      return PaymentConfirmationScreen(paymentResult: args);
    },
  };
}
