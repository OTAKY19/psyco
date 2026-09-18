import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/question.dart';
import '../services/memory_question_service.dart';
import '../utils/memory_question_utils.dart';
import '../widgets/operator_logo_widget.dart';
import '../core/app_export.dart';

/// Widget de test pour valider les questions mémoire sur mobile
class MemoryTestRunner extends StatefulWidget {
  const MemoryTestRunner({super.key});

  @override
  State<MemoryTestRunner> createState() => _MemoryTestRunnerState();
}

class _MemoryTestRunnerState extends State<MemoryTestRunner> {
  final MemoryQuestionService _memoryService = MemoryQuestionService();
  bool _isLoading = true;
  Map<String, dynamic> _testResults = {};

  @override
  void initState() {
    super.initState();
    _runTests();
  }

  Future<void> _runTests() async {
    setState(() => _isLoading = true);

    try {
      final jsonString = await rootBundle.loadString('assets/data/questions_consolidees.json');
      final List<dynamic> questionsJson = json.decode(jsonString);
      
      int total = 0, valid = 0, invalid = 0;
      Map<String, int> types = {};
      Map<String, int> errors = {};

      for (final questionData in questionsJson) {
        final question = Question.fromJson(questionData);
        
        if (MemoryQuestionUtils.isMemoryQuestion(question.question)) {
          total++;
          final analysis = _memoryService.analyzeQuestion(question);
          
          if (analysis.isValid) {
            valid++;
          } else {
            invalid++;
            for (final error in analysis.errors) {
              errors[error] = (errors[error] ?? 0) + 1;
            }
          }
          
          final type = analysis.sequenceType.toString().split('.').last;
          types[type] = (types[type] ?? 0) + 1;
        }
      }

      setState(() {
        _testResults = {
          'total': total,
          'valid': valid,
          'invalid': invalid,
          'types': types,
          'errors': errors,
        };
        _isLoading = false;
      });

    } catch (e) {
      setState(() {
        _testResults = {'error': e.toString()};
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Questions Mémoire'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _buildResults(),
    );
  }

  Widget _buildResults() {
    if (_testResults.containsKey('error')) {
      return Center(
        child: Text('Erreur: ${_testResults['error']}'),
      );
    }

    final total = _testResults['total'] ?? 0;
    final valid = _testResults['valid'] ?? 0;
    final invalid = _testResults['invalid'] ?? 0;
    final validityRate = total > 0 ? (valid / total * 100) : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          // Résumé
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  const Text('📊 RÉSULTATS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: AppSpacing.lg),
                  Text('Total: $total questions'),
                  Text('Valides: $valid', style: const TextStyle(color: Colors.green)),
                  Text('Invalides: $invalid', style: const TextStyle(color: Colors.red)),
                  Text('Taux: ${validityRate.toStringAsFixed(1)}%'),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Test opérateurs
          const Card(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Column(
                children: [
                  Text('📱 LOGOS OPÉRATEURS', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  SizedBox(height: AppSpacing.lg),
                  OperatorsRowWidget(
                    operatorIds: ['mtn', 'moov', 'orange'],
                    showLabels: true,
                    logoSize: 60,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: AppSpacing.xxl),
          
          // Actions
          ElevatedButton(
            onPressed: _runTests,
            child: const Text('Relancer le test'),
          ),
        ],
      ),
    );
  }
}
