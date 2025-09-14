import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/test_session.dart';
import '../services/test_service.dart';

class TestScreen extends StatefulWidget {
  final TestType testType;
  final String? category;
  final String? level;
  final int questionCount;
  final int? timeLimit;

  const TestScreen({
    super.key,
    required this.testType,
    this.category,
    this.level,
    this.questionCount = 10,
    this.timeLimit,
  });

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final TestService _testService = TestService();
  TestSession? _currentSession;
  String? _selectedAnswer;
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeTest();
  }

  Future<void> _initializeTest() async {
    setState(() => _isLoading = true);
    
    try {
      TestSession session;
      
      switch (widget.testType) {
        case TestType.mixed:
          session = await _testService.createMixedTest(
            questionCount: widget.questionCount,
            totalTimeLimit: widget.timeLimit,
          );
          break;
        case TestType.specific:
          session = await _testService.createCategoryTest(
            category: widget.category!,
            questionCount: widget.questionCount,
            level: widget.level,
            totalTimeLimit: widget.timeLimit,
          );
          break;
        case TestType.practice:
          session = await _testService.createPracticeTest(
            category: widget.category,
            level: widget.level,
            questionCount: widget.questionCount,
          );
          break;
        default:
          session = await _testService.createMixedTest(
            questionCount: widget.questionCount,
          );
      }
      
      await _testService.startSession(session);
      
      setState(() {
        _currentSession = session;
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Erreur lors de l\'initialisation du test: \$e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Future<void> _answerQuestion() async {
    if (_selectedAnswer == null || _currentSession == null) return;
    
    await _testService.answerCurrentQuestion(_selectedAnswer!);
    
    setState(() {
      _selectedAnswer = null;
    });
    
    // Attendre un peu pour permettre à l'utilisateur de voir la réponse
    await Future.delayed(const Duration(milliseconds: 500));
    
    if (_currentSession!.hasNext) {
      final hasNext = await _testService.nextQuestion();
      if (!hasNext) {
        _completeTest();
      }
    } else {
      _completeTest();
    }
  }

  Future<void> _completeTest() async {
    try {
      final result = await _testService.completeSession();
      
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TestResultScreen(result: result),
          ),
        );
      }
    } catch (e) {
      _showError('Erreur lors de la finalisation du test: \$e');
    }
  }

  Widget _buildProgressIndicator() {
    if (_currentSession == null) return const SizedBox.shrink();
    
    final progress = (_currentSession!.currentQuestionIndex + 1) / 
                    _currentSession!.totalQuestions;
    
    return Column(
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.grey[300],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
        ),
        const SizedBox(height: 8),
        Text(
          'Question ${_currentSession!.currentQuestionIndex + 1} sur ${_currentSession!.totalQuestions}',
          style: const TextStyle(fontSize: 14, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    if (_currentSession == null) return const SizedBox.shrink();
    
    final question = _currentSession!.currentQuestion;
    
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Catégorie et niveau
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(
                    question.categorie.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 12),
                  ),
                  backgroundColor: Color(Question.categoryColors[question.categorie] ?? 0xFF2196F3),
                ),
                Chip(
                  label: Text(question.niveau.toUpperCase()),
                  backgroundColor: _getLevelColor(question.niveau),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Question
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Options
            ...question.options.asMap().entries.map((entry) {
              final index = entry.key;
              final option = entry.value;
              final optionLetter = String.fromCharCode(65 + index); // A, B, C, D
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => setState(() => _selectedAnswer = option),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _selectedAnswer == option 
                            ? Colors.blue 
                            : Colors.grey[300]!,
                        width: _selectedAnswer == option ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                      color: _selectedAnswer == option 
                          ? Colors.blue[50] 
                          : Colors.transparent,
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 12,
                          backgroundColor: _selectedAnswer == option 
                              ? Colors.blue 
                              : Colors.grey[300],
                          child: Text(
                            optionLetter,
                            style: TextStyle(
                              color: _selectedAnswer == option 
                                  ? Colors.white 
                                  : Colors.black,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            
            const SizedBox(height: 20),
            
            // Bouton de validation
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _answerQuestion : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Valider ma réponse',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(String niveau) {
    switch (niveau) {
      case 'facile': return Colors.green[100]!;
      case 'moyen': return Colors.orange[100]!;
      case 'difficile': return Colors.red[100]!;
      default: return Colors.grey[100]!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test en cours'),
        actions: [
          // Timer si configuré
          StreamBuilder<int>(
            stream: _testService.timerStream,
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox.shrink();
              
              final minutes = snapshot.data! ~/ 60;
              final seconds = snapshot.data! % 60;
              
              return Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: Text(
                    '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: snapshot.data! < 60 ? Colors.red : Colors.white,
                    ),
                  ),
                ),
              );
            },
          ),
          
          // Menu d'options
          PopupMenuButton<String>(
            onSelected: (value) async {
              switch (value) {
                case 'pause':
                  await _testService.pauseSession();
                  // TODO: Afficher écran de pause
                  break;
                case 'abandon':
                  _showAbandonDialog();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'pause',
                child: Row(
                  children: [
                    Icon(Icons.pause),
                    SizedBox(width: 8),
                    Text('Mettre en pause'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'abandon',
                child: Row(
                  children: [
                    Icon(Icons.close, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Abandonner', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildProgressIndicator(),
                Expanded(
                  child: SingleChildScrollView(
                    child: _buildQuestion(),
                  ),
                ),
              ],
            ),
    );
  }

  void _showAbandonDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Abandonner le test'),
        content: const Text(
          'Êtes-vous sûr de vouloir abandonner ce test ? Votre progression sera perdue.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _testService.abandonSession();
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Abandonner'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// Écran de résultats (exemple basique)
class TestResultScreen extends StatelessWidget {
  final TestResult result;

  const TestResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Résultats du test'),
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Score principal
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Text(
                      result.formattedScore,
                      style: TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: result.isPassed ? Colors.green : Colors.red,
                      ),
                    ),
                    Text(
                      result.level,
                      style: const TextStyle(fontSize: 24),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.correctAnswers} bonnes réponses sur ${result.totalQuestions}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    Text(
                      'Temps: ${result.formattedDuration}',
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Détails par catégorie
            Expanded(
              child: ListView.builder(
                itemCount: result.categoryResults.length,
                itemBuilder: (context, index) {
                  final category = result.categoryResults.keys.elementAt(index);
                  final categoryResult = result.categoryResults[category]!;
                  
                  return Card(
                    child: ListTile(
                      title: Text(category.replaceAll('_', ' ').toUpperCase()),
                      subtitle: Text(
                        '${categoryResult.correctAnswers}/${categoryResult.totalQuestions}',
                      ),
                      trailing: Text(
                        categoryResult.formattedScore,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: categoryResult.score >= 0.5 ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Boutons d'action
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Retour au menu'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Recommencer un test
                      Navigator.pop(context);
                    },
                    child: const Text('Recommencer'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
