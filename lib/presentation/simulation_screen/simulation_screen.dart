import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/simulation_model.dart';
import '../../services/simulation_service.dart';
import 'widgets/simulation_timer_widget.dart';
import 'widgets/simulation_question_widget.dart';
import 'widgets/simulation_progress_widget.dart';
import 'widgets/simulation_navigation_widget.dart';

class SimulationScreen extends StatefulWidget {
  final String userId;
  final SimulationModel? simulation;

  const SimulationScreen({
    Key? key,
    required this.userId,
    this.simulation,
  }) : super(key: key);

  @override
  State<SimulationScreen> createState() => _SimulationScreenState();
}

class _SimulationScreenState extends State<SimulationScreen> {
  final SimulationService _simulationService = SimulationService();
  late SimulationSession _session;
  Timer? _timer;
  Timer? _questionTimer;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initializeSimulation();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _questionTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeSimulation() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      _session = await _simulationService.createSimulationSession(widget.userId);
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _showStartDialog();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Erreur lors de l\'initialisation: $e';
        });
      }
    }
  }

  void _showStartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Simulation Test Douane Bénin'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('• 40 questions à répondre'),
            Text('• Durée totale: 40 minutes'),
            Text('• 1 minute par question'),
            Text('• Pas de retour en arrière possible'),
            SizedBox(height: 16),
            Text('Êtes-vous prêt à commencer ?', 
              style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _abandonSimulation();
            },
            child: Text('Abandonner'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startSimulation();
            },
            child: Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _startSimulation() {
    setState(() {
      _session = _simulationService.startSimulation(_session);
    });
    _startTimers();
  }

  void _startTimers() {
    // Timer principal (40 minutes)
    _timer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_session.status != SimulationStatus.inProgress) {
        timer.cancel();
        return;
      }

      final remainingTime = _session.remainingTime - Duration(seconds: 1);
      
      if (remainingTime.inSeconds <= 0) {
        _handleTimeUp();
        return;
      }

      setState(() {
        _session = _simulationService.updateRemainingTime(
          _session,
          remainingTime,
          _session.currentQuestionRemainingTime - Duration(seconds: 1),
        );
      });
    });

    // Timer par question (1 minute)
    _questionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (_session.status != SimulationStatus.inProgress) {
        timer.cancel();
        return;
      }

      final questionRemainingTime = _session.currentQuestionRemainingTime - Duration(seconds: 1);
      
      if (questionRemainingTime.inSeconds <= 0) {
        _handleQuestionTimeUp();
        return;
      }

      setState(() {
        _session = _simulationService.updateRemainingTime(
          _session,
          _session.remainingTime,
          questionRemainingTime,
        );
      });
    });
  }

  void _handleTimeUp() {
    _timer?.cancel();
    _questionTimer?.cancel();
    
    setState(() {
      _session = _simulationService.completeSimulationByTimeUp(_session);
    });
    
    _showTimeUpDialog();
  }

  void _handleQuestionTimeUp() {
    // Passer automatiquement à la question suivante
    _nextQuestion();
  }

  void _nextQuestion() {
    if (_session.currentQuestionIndex >= _session.questions.length - 1) {
      _completeSimulation();
      return;
    }

    setState(() {
      _session = _simulationService.nextQuestion(_session);
    });
  }

  void _answerQuestion(String selectedOption) {
    final currentQuestion = _simulationService.getCurrentQuestion(_session);
    if (currentQuestion == null) return;

    final timeSpent = _session.questionDuration - _session.currentQuestionRemainingTime;
    
    setState(() {
      _session = _simulationService.recordAnswer(
        _session,
        currentQuestion.id.toString(),
        selectedOption,
        timeSpent,
      );
    });

    // Passer à la question suivante après un court délai
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        _nextQuestion();
      }
    });
  }

  void _completeSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();
    
    setState(() {
      _session = _simulationService.completeSimulation(_session);
    });
    
    _showResults();
  }

  void _abandonSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();
    
    setState(() {
      _session = _session.copyWith(
        status: SimulationStatus.abandoned,
        endTime: DateTime.now(),
      );
    });
    
    Navigator.of(context).pop();
  }

  void _showTimeUpDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Temps écoulé !'),
        content: Text('Le temps de 40 minutes est écoulé. Votre simulation est terminée.'),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _showResults();
            },
            child: Text('Voir les résultats'),
          ),
        ],
      ),
    );
  }

  void _showResults() {
    final result = _simulationService.calculateSimulationResult(_session);
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => SimulationResultsScreen(
          result: result,
          session: _session,
        ),
      ),
    );
  }

  void _pauseSimulation() {
    _timer?.cancel();
    _questionTimer?.cancel();
    
    setState(() {
      _session = _simulationService.pauseSimulation(_session);
    });
    
    _showPauseDialog();
  }

  void _resumeSimulation() {
    setState(() {
      _session = _simulationService.resumeSimulation(_session);
    });
    _startTimers();
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Simulation en pause'),
        content: Text('Voulez-vous reprendre la simulation ?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _abandonSimulation();
            },
            child: Text('Abandonner'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _resumeSimulation();
            },
            child: Text('Reprendre'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Chargement de la simulation...'),
            ],
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _initializeSimulation,
                child: Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        if (_session.status == SimulationStatus.inProgress) {
          _pauseSimulation();
          return false;
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Simulation Test Douane'),
          automaticallyImplyLeading: false,
          actions: [
            if (_session.status == SimulationStatus.inProgress)
              IconButton(
                onPressed: _pauseSimulation,
                icon: Icon(Icons.pause),
                tooltip: 'Pause',
              ),
          ],
        ),
        body: Column(
          children: [
            // Timer et progression
            SimulationTimerWidget(
              session: _session,
              onTimeUp: _handleTimeUp,
            ),
            
            // Barre de progression
            SimulationProgressWidget(session: _session),
            
            // Question actuelle
            Expanded(
              child: SimulationQuestionWidget(
                session: _session,
                onAnswer: _answerQuestion,
                onQuestionTimeUp: _handleQuestionTimeUp,
              ),
            ),
            
            // Navigation
            SimulationNavigationWidget(
              session: _session,
              onNext: _nextQuestion,
            ),
          ],
        ),
      ),
    );
  }
}

// Écran de résultats (simplifié pour l'exemple)
class SimulationResultsScreen extends StatelessWidget {
  final SimulationResult result;
  final SimulationSession session;

  const SimulationResultsScreen({
    Key? key,
    required this.result,
    required this.session,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats de la simulation'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Score final', style: Theme.of(context).textTheme.headlineSmall),
                    SizedBox(height: 8),
                    Text('${result.formattedScore}', 
                      style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                        color: result.score >= 0.6 ? Colors.green : Colors.red,
                      )),
                    SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard('Correctes', result.correctAnswers.toString(), Colors.green),
                        _buildStatCard('Incorrectes', result.incorrectAnswers.toString(), Colors.red),
                        _buildStatCard('Non répondues', result.unansweredQuestions.toString(), Colors.orange),
                      ],
                    ),
                    SizedBox(height: 16),
                    Text('Temps total: ${result.formattedTime}'),
                    Text('Niveau: ${result.level}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Retour à l\'accueil'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12)),
      ],
    );
  }
}
