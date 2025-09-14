import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/exam_blanc_service.dart';
import '../../services/subscription_service.dart';
import '../exam_results_screen/exam_results_screen.dart';
import '../activation_screen/activation_screen.dart';
import 'widgets/exam_header_widget.dart';
import 'widgets/exam_question_widget.dart';
import 'widgets/exam_navigation_widget.dart';

class ExamTakingScreen extends StatefulWidget {
  final ExamBlancSession session;

  const ExamTakingScreen({
    super.key,
    required this.session,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen>
    with TickerProviderStateMixin {
  late ExamBlancSession _session;
  late Timer _examTimer;
  late Timer _questionTimer;
  final SubscriptionService _subscriptionService = SubscriptionService();
  
  int _remainingTimeInSeconds = 0;
  int _questionRemainingTime = 0;
  bool _isPaused = false;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _remainingTimeInSeconds = _session.exam.duration.inSeconds;
    _questionRemainingTime = _session.exam.questionDuration.inSeconds;
    
    _startExam();
  }

  @override
  void dispose() {
    _examTimer.cancel();
    _questionTimer.cancel();
    super.dispose();
  }

  void _startExam() {
    _session.start();
    _startTimers();
  }

  void _startTimers() {
    // Timer principal de l'examen
    _examTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted) {
        setState(() {
          _remainingTimeInSeconds--;
        });
        
        if (_remainingTimeInSeconds <= 0) {
          _completeExam();
        }
      }
    });

    // Timer par question
    _questionTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      if (!_isPaused && !_isCompleted) {
        setState(() {
          _questionRemainingTime--;
        });
        
        if (_questionRemainingTime <= 0) {
          _autoNextQuestion();
        }
      }
    });
  }

  void _answerQuestion(int optionIndex) {
    setState(() {
      _session.answerQuestion(optionIndex);
    });
    
    // Vibration pour feedback
    HapticFeedback.lightImpact();
    
    // Auto-sauvegarde
    _saveProgress();
  }

  void _nextQuestion() {
    if (_session.hasNext) {
      setState(() {
        _session.nextQuestion();
        _questionRemainingTime = _session.exam.questionDuration.inSeconds;
      });
    } else {
      _completeExam();
    }
  }

  void _previousQuestion() {
    if (_session.hasPrevious) {
      setState(() {
        _session.previousQuestion();
        _questionRemainingTime = _session.exam.questionDuration.inSeconds;
      });
    }
  }

  void _autoNextQuestion() {
    if (_session.hasNext) {
      _nextQuestion();
    } else {
      _completeExam();
    }
  }

  void _pauseExam() {
    setState(() {
      _isPaused = !_isPaused;
    });
    
    if (_isPaused) {
      _showPauseDialog();
    }
  }

  void _showPauseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Examen en pause'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Votre examen est en pause.'),
            SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Temps restant:'),
                Text(_formatTime(_remainingTimeInSeconds)),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Question:'),
                Text('${_session.currentQuestionIndex + 1}/${_session.exam.totalQuestions}'),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _pauseExam();
            },
            child: Text('Reprendre'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _completeExam();
            },
            child: Text('Terminer'),
          ),
        ],
      ),
    );
  }

  void _completeExam() {
    _isCompleted = true;
    _examTimer.cancel();
    _questionTimer.cancel();
    
    _session.complete();
    
    // Calculer le résultat
    final result = ExamBlancService().calculateResult(_session);
    
    // Vérifier si l'utilisateur est activé pour afficher les réponses complètes
    _checkSubscriptionAndShowResults(result);
  }

  Future<void> _checkSubscriptionAndShowResults(ExamBlancResult result) async {
    final isPremium = await _subscriptionService.isPremiumUser();
    
    // Marquer qu'un test gratuit a été utilisé si l'utilisateur n'est pas premium
    if (!isPremium) {
      await _subscriptionService.markFreeTestUsed();
    }
    
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => ExamResultsScreen(
            result: result,
          ),
        ),
      );
    }
  }

  void _saveProgress() {
    // Ici, vous pourriez sauvegarder le progrès dans SharedPreferences
    // ou dans une base de données locale
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Color _getTimerColor() {
    if (_remainingTimeInSeconds <= 300) return Colors.red; // 5 minutes
    if (_remainingTimeInSeconds <= 600) return Colors.orange; // 10 minutes
    return Colors.green;
  }

  Color _getQuestionTimerColor() {
    if (_questionRemainingTime <= 10) return Colors.red;
    if (_questionRemainingTime <= 30) return Colors.orange;
    return Colors.blue;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        _showExitDialog();
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        body: Column(
          children: [
            // En-tête avec timer et navigation
            ExamHeaderWidget(
              currentQuestion: _session.currentQuestionIndex + 1,
              totalQuestions: _session.exam.totalQuestions,
              examTimeRemaining: _formatTime(_remainingTimeInSeconds),
              questionTimeRemaining: _formatTime(_questionRemainingTime),
              examTimerColor: _getTimerColor(),
              questionTimerColor: _getQuestionTimerColor(),
              isPaused: _isPaused,
              onPause: _pauseExam,
            ),
            
            // Contenu de la question
            Expanded(
              child: ExamQuestionWidget(
                question: _session.currentQuestion,
                selectedAnswer: _session.userAnswers[_session.currentQuestionIndex],
                onAnswerSelected: _answerQuestion,
              ),
            ),
            
            // Navigation
            ExamNavigationWidget(
              hasPrevious: _session.hasPrevious,
              hasNext: _session.hasNext,
              isLastQuestion: !_session.hasNext,
              onPrevious: _previousQuestion,
              onNext: _nextQuestion,
              onComplete: _completeExam,
            ),
          ],
        ),
      ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Quitter l\'examen'),
        content: Text('Êtes-vous sûr de vouloir quitter l\'examen ? Votre progrès sera perdu.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: Text('Quitter'),
          ),
        ],
      ),
    );
  }
}
