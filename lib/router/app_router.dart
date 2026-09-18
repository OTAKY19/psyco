import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../design/app_radii.dart';
import '../design/app_spacing.dart';
import '../design/app_text_styles.dart';

import '../presentation/splash_screen/splash_screen.dart';
import '../presentation/onboarding_screen/onboarding_screen.dart';
import '../presentation/home_tab/home_tab_content.dart';
import '../presentation/test_taking_screen/test_taking_screen.dart';
import '../presentation/test_category_screen/test_category_screen.dart';
import '../presentation/user_profile_screen/user_profile_screen.dart';
import '../presentation/progress_tracking_screen/progress_tracking_screen.dart';
import '../presentation/test_results_screen/test_results_screen.dart';
import '../presentation/test_library_dashboard/test_library_dashboard.dart';
import '../presentation/payment_confirmation_screen/payment_confirmation_screen.dart';
import '../presentation/mobile_money_payment_screen/mobile_money_payment_screen.dart';
import '../presentation/simulation_selection_screen/simulation_selection_screen.dart';
import '../presentation/simulation_screen/simulation_screen.dart';
import '../presentation/exam_blanc_screen/exam_blanc_screen.dart';
import '../presentation/exam_taking_screen/exam_taking_screen.dart';
import '../presentation/exam_results_screen/exam_results_screen.dart';
import '../presentation/progress_exam_results_screen.dart';
import '../presentation/payment_screen/payment_screen.dart';
import '../presentation/exam_screen/premium_exam_screen.dart';
import '../presentation/activation_screen/activation_screen.dart';
import '../presentation/subscription_screen/subscription_screen.dart';
import '../presentation/mtn_payment_screen/mtn_payment_screen.dart';
import '../presentation/subject_screen/subject_screen.dart';
import '../presentation/demo_exam_screen/demo_exam_screen.dart';
import 'app_routes.dart';
import 'route_extras.dart';

GoRouter? _router;

GoRouter get appRouter {
  _router ??= _createRouter();
  return _router!;
}

GoRouter _createRouter() {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _HomeShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                name: 'home',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeTabContent(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.testLibraryDashboard,
                name: 'testLibraryDashboard',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: TestLibraryDashboard(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.userProfile,
                name: 'userProfile',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: UserProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.testTaking,
        name: 'testTaking',
        builder: (context, state) {
          final extra = state.extra as QuizRouteExtra?;
          return TestTakingScreen(testData: extra?.categoryData);
        },
      ),
      GoRoute(
        path: AppRoutes.testCategory,
        name: 'testCategory',
        builder: (context, state) {
          final extra = state.extra as QuizRouteExtra?;
          return TestCategoryScreen(categoryData: extra?.categoryData);
        },
      ),
      GoRoute(
        path: AppRoutes.testResults,
        name: 'testResults',
        builder: (context, state) {
          final extra = state.extra as TestResultRouteExtra?;
          return TestResultsScreen(testResults: extra?.testResults);
        },
      ),
      GoRoute(
        path: AppRoutes.progressTracking,
        name: 'progressTracking',
        builder: (context, state) => const ProgressTrackingScreen(),
      ),
      GoRoute(
        path: AppRoutes.examBlanc,
        name: 'examBlanc',
        builder: (context, state) => const ExamBlancScreen(),
      ),
      GoRoute(
        path: AppRoutes.examTaking,
        name: 'examTaking',
        builder: (context, state) {
          final extra = state.extra as ExamSessionExtra;
          return ExamTakingScreen(session: extra.session);
        },
      ),
      GoRoute(
        path: AppRoutes.examResults,
        name: 'examResults',
        builder: (context, state) {
          final extra = state.extra as ExamResultRouteExtra;
          return ExamResultsScreen(result: extra.result!);
        },
      ),
      GoRoute(
        path: AppRoutes.exam,
        name: 'exam',
        builder: (context, state) {
          final extra = state.extra as QuizRouteExtra?;
          return PremiumExamScreen(examConfig: extra?.examConfig);
        },
      ),
      GoRoute(
        path: AppRoutes.demoExam,
        name: 'demoExam',
        builder: (context, state) {
          final extra = state.extra as DemoExamRouteExtra?;
          return DemoExamScreen(
            onDemoCompleted: extra?.onDemoCompleted ?? () {},
            onUpgradeNow: extra?.onUpgradeNow ?? () {},
          );
        },
      ),
      GoRoute(
        path: AppRoutes.simulationSelection,
        name: 'simulationSelection',
        builder: (context, state) {
          final extra = state.extra as SimulationRouteExtra;
          return SimulationSelectionScreen(userId: extra.userId);
        },
      ),
      GoRoute(
        path: AppRoutes.simulation,
        name: 'simulation',
        builder: (context, state) {
          final extra = state.extra as SimulationRouteExtra;
          return SimulationScreen(
            userId: extra.userId,
            simulation: extra.simulation,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.payment,
        name: 'payment',
        builder: (context, state) {
          final extra = state.extra as PaymentRouteExtra;
          return PaymentScreen(
            amount: extra.amount,
            description: extra.description,
            onPaymentSuccess: extra.onPaymentSuccess ?? () {},
          );
        },
      ),
      GoRoute(
        path: AppRoutes.paymentConfirmation,
        name: 'paymentConfirmation',
        builder: (context, state) {
          final extra = state.extra as TestResultRouteExtra?;
          return PaymentConfirmationScreen(paymentResult: extra?.paymentResult);
        },
      ),
      GoRoute(
        path: AppRoutes.mobileMoneyPayment,
        name: 'mobileMoneyPayment',
        builder: (context, state) => const MobileMoneyPaymentScreen(),
      ),
      GoRoute(
        path: AppRoutes.mtnPayment,
        name: 'mtnPayment',
        builder: (context, state) {
          final extra = state.extra as PaymentRouteExtra;
          return MtnPaymentScreen(
            amount: extra.amount,
            description: extra.description,
            onPaymentSuccess: extra.onPaymentSuccess,
            onPaymentCancel: extra.onPaymentCancel,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.activation,
        name: 'activation',
        builder: (context, state) {
          final extra = state.extra as ExamResultRouteExtra?;
          return ActivationScreen(examResults: extra?.examResults);
        },
      ),
      GoRoute(
        path: AppRoutes.subscription,
        name: 'subscription',
        builder: (context, state) => const SubscriptionScreen(),
      ),
      GoRoute(
        path: AppRoutes.progressExamResults,
        name: 'progressExamResults',
        builder: (context, state) {
          final extra = state.extra as ExamResultRouteExtra?;
          return ProgressExamResultsScreen(arguments: extra?.arguments);
        },
      ),
      GoRoute(
        path: AppRoutes.subject,
        name: 'subject',
        builder: (context, state) {
          final extra = state.extra as QuizRouteExtra?;
          return SubjectScreen(subjectData: extra?.subjectData);
        },
      ),
    ],
    redirect: (context, state) {
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route inconnue: ${state.matchedLocation}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text("Retour à l'accueil"),
            ),
          ],
        ),
      ),
    ),
  );
}

class _HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const _HomeShell({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
          border: Border(
            top: BorderSide(
              color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShellNavItem(
                  icon: Icons.home_rounded,
                  label: 'Accueil',
                  isSelected: navigationShell.currentIndex == 0,
                  onTap: () => navigationShell.goBranch(0),
                ),
                _ShellNavItem(
                  icon: Icons.quiz_rounded,
                  label: 'Épreuves',
                  isSelected: navigationShell.currentIndex == 1,
                  onTap: () => navigationShell.goBranch(1),
                ),
                _ShellNavItem(
                  icon: Icons.person_rounded,
                  label: 'Profil',
                  isSelected: navigationShell.currentIndex == 2,
                  onTap: () => navigationShell.goBranch(2),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShellNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ShellNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final primary = colorScheme.primary;
    final onSurface = colorScheme.onSurface;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        // Cible tactile >= 44px (T9) : icône 22 + padding vertical 11×2.
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
        decoration: BoxDecoration(
          color: isSelected
              ? primary.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadii.xl),
        ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color:
                      isSelected ? primary : onSurface.withValues(alpha: 0.5),
                ),
                if (isSelected) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    label,
                    style: AppTextStyles.labelLarge.copyWith(color: primary),
                  ),
                ],
              ],
            ),
      ),
    );
  }
}
