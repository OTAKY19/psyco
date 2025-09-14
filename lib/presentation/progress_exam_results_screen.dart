import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../widgets/progress_results_widget.dart';
import '../widgets/payment_suggestion_widget.dart';
import '../services/user_state_service.dart';
import '../routes/app_routes.dart';

class ProgressExamResultsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ProgressExamResultsScreen({super.key, this.arguments});

  @override
  State<ProgressExamResultsScreen> createState() => _ProgressExamResultsScreenState();
}

class _ProgressExamResultsScreenState extends State<ProgressExamResultsScreen> {
  late List<Map<String, dynamic>> results;
  late int totalQuestions;
  late int correctAnswers;
  late int timeSpent;

  @override
  void initState() {
    super.initState();
    _initializeData();
    _checkDemoCompletion();
  }

  void _initializeData() {
    final args = widget.arguments ?? {};
    results = List<Map<String, dynamic>>.from(args['results'] ?? []);
    totalQuestions = args['totalQuestions'] ?? 40;
    correctAnswers = args['correctAnswers'] ?? 0;
    timeSpent = args['timeSpent'] ?? 0;
  }

  Future<void> _checkDemoCompletion() async {
    // Attendre un peu pour que l'écran se charge complètement
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      // Vérifier si c'est une démo terminée
      final userStateService = UserStateService();
      final userState = await userStateService.getUserState();

      // Si la démo vient d'être terminée et l'utilisateur n'est pas activé
      if (userState.hasCompletedDemo && !userState.isActivated) {
        // Afficher la pop-up de suggestion d'activation
        _showPaymentSuggestion();
      }
    }
  }

  void _showPaymentSuggestion() {
    PaymentSuggestionWidget.show(
      context,
      () {
        // Rediriger vers l'écran d'activation
        Navigator.pushNamed(context, AppRoutes.activationScreen);
      },
      () {
        // Fermer simplement
        Navigator.pop(context);
      },
    );
  }

  void _onActivatePressed() {
    // Naviguer vers l'écran d'activation
    Navigator.pushNamed(context, AppRoutes.activationScreen);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats de l\'Examen'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showShareDialog(),
            icon: const Icon(Icons.share),
          ),
        ],
      ),
      body: ProgressResultsWidget(
        allResults: results,
        totalQuestions: totalQuestions,
        onActivatePressed: _onActivatePressed,
      ),
    );
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Partager le résultat'),
        content: Text('Score: $correctAnswers/$totalQuestions (${(correctAnswers / totalQuestions * 100).round()}%)'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}
