import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/exam_blanc_service.dart';
import '../../services/subscription_service.dart';
import '../exam_taking_screen/exam_taking_screen.dart';
import '../activation_screen/activation_screen.dart';
import 'widgets/exam_card_widget.dart';
import 'widgets/exam_stats_widget.dart';

class ExamBlancScreen extends StatefulWidget {
  const ExamBlancScreen({super.key});

  @override
  State<ExamBlancScreen> createState() => _ExamBlancScreenState();
}

class _ExamBlancScreenState extends State<ExamBlancScreen> {
  final ExamBlancService _examService = ExamBlancService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  List<ExamBlanc> _exams = [];
  bool _isLoading = true;
  String? _error;
  Map<String, ExamBlancResult> _userResults = {};

  @override
  void initState() {
    super.initState();
    _loadExams();
  }

  Future<void> _loadExams() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final exams = await _examService.loadAllExams();
      
      setState(() {
        _exams = exams;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _startExam(ExamBlanc exam) async {
    try {
      // Vérifier si l'utilisateur peut faire un test
      final canTakeTest = await _subscriptionService.canTakeTest();
      
      if (!canTakeTest) {
        // Afficher la popup d'activation
        _showActivationPrompt(exam);
        return;
      }

      // Créer et démarrer la session d'examen
      final session = await _examService.createExamSession(exam.id, 'current_user');
      
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ExamTakingScreen(session: session),
          ),
        ).then((result) {
          if (result != null && result is ExamBlancResult) {
            setState(() {
              _userResults[exam.id] = result;
            });
          }
        });
      }
    } catch (e) {
      _showErrorDialog('Erreur lors du démarrage de l\'examen: $e');
    }
  }

  void _showActivationPrompt(ExamBlanc exam) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.lock, color: Colors.orange),
            SizedBox(width: 8),
            Text('Activation requise'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vous avez atteint la limite de tests gratuits.'),
            SizedBox(height: 16),
            Text('Pour continuer à utiliser l\'application, veuillez l\'activer.'),
            SizedBox(height: 16),
            Text('Avantages de l\'activation:', style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            _buildBenefitItem('✓ Accès illimité à tous les examens blancs'),
            _buildBenefitItem('✓ Corrections détaillées avec explications'),
            _buildBenefitItem('✓ Statistiques de progression avancées'),
            _buildBenefitItem('✓ Mode hors ligne'),
            _buildBenefitItem('✓ Support prioritaire'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ActivationScreen(examResults: null),
                ),
              );
            },
            child: Text('Activer l\'app'),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Text(text, style: TextStyle(fontSize: 12.sp)),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Erreur'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Examens Blancs'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadExams,
            icon: Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Chargement des examens...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error, size: 64, color: Colors.red),
            SizedBox(height: 16),
            Text('Erreur: $_error'),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadExams,
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }

    if (_exams.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Aucun examen disponible'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadExams,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Statistiques
            ExamStatsWidget(
              totalExams: _exams.length,
              completedExams: _userResults.length,
              averageScore: _calculateAverageScore(),
            ),
            
            SizedBox(height: 24),
            
            // Liste des examens
            Text(
              'Examens Disponibles',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: _exams.length,
              itemBuilder: (context, index) {
                final exam = _exams[index];
                final result = _userResults[exam.id];
                
                return ExamCardWidget(
                  exam: exam,
                  result: result,
                  onStart: () => _startExam(exam),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  double _calculateAverageScore() {
    if (_userResults.isEmpty) return 0.0;
    
    final totalScore = _userResults.values
        .map((result) => result.scorePercentage)
        .reduce((a, b) => a + b);
    
    return totalScore / _userResults.length;
  }
}
