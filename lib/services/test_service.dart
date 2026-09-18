import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/question.dart';
import '../models/test_session.dart';

class TestService extends ChangeNotifier {
  List<Question> _questions = [];
  TestSession? _currentSession;
  bool _isLoading = false;

  List<Question> get questions => _questions;
  TestSession? get currentSession => _currentSession;
  bool get isLoading => _isLoading;

  void startTest(String testId, String userId) {
    _currentSession = TestSession(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      testId: testId,
      userId: userId,
      startTime: DateTime.now(),
    );
    notifyListeners();
  }

  void submitAnswer(String answer) {
    if (_currentSession != null) {
      final updatedAnswers = List<String>.from(_currentSession!.answers);
      updatedAnswers.add(answer);

      _currentSession = _currentSession!.copyWith(
        answers: updatedAnswers,
        currentQuestionIndex: _currentSession!.currentQuestionIndex + 1,
      );
      notifyListeners();
    }
  }

  void completeTest() {
    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        isCompleted: true,
        endTime: DateTime.now(),
      );
      notifyListeners();
    }
  }

  void loadQuestions(List<Question> questions) {
    _questions = questions;
    notifyListeners();
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void reset() {
    _questions = [];
    _currentSession = null;
    _isLoading = false;
    notifyListeners();
  }

  static const String _historyKey = 'test_history_v1';
  static const int _historyCap = 50;

  /// Enregistre un test terminé (T3/IA filières : données réelles, pas de simulation).
  Future<void> recordCompletedTest({
    required String testId,
    required String category,
    required int correctAnswers,
    required int totalQuestions,
    required int durationSeconds,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final List<Map<String, dynamic>> history = await getTestHistory();
    history.insert(0, {
      'testId': testId,
      'category': category,
      'correctAnswers': correctAnswers,
      'totalQuestions': totalQuestions,
      'durationSeconds': durationSeconds,
      'completedAt': DateTime.now().toIso8601String(),
    });
    final capped = history.take(_historyCap).toList();
    await prefs.setString(
        _historyKey, jsonEncode(capped));
    notifyListeners();
  }

  Future<List<Map<String, dynamic>>> getTestHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List;
      return list
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>> getUserStats() async {
    final history = await getTestHistory();
    if (history.isEmpty) {
      return {
        'totalTests': 0,
        'averageScore': 0.0,
        'bestScore': 0.0,
        'totalTimeMinutes': 0,
        'categoriesCompleted': 0,
      };
    }
    double sumPct = 0;
    double best = 0;
    int totalSeconds = 0;
    final categories = <String>{};
    for (final h in history) {
      final total = (h['totalQuestions'] as num?)?.toInt() ?? 0;
      final correct = (h['correctAnswers'] as num?)?.toInt() ?? 0;
      final pct = total > 0 ? correct / total * 100 : 0.0;
      sumPct += pct;
      if (pct > best) best = pct;
      totalSeconds += (h['durationSeconds'] as num?)?.toInt() ?? 0;
      final cat = h['category']?.toString() ?? '';
      if (cat.isNotEmpty) categories.add(cat);
    }
    return {
      'totalTests': history.length,
      'averageScore': sumPct / history.length,
      'bestScore': best,
      'totalTimeMinutes': totalSeconds ~/ 60,
      'categoriesCompleted': categories.length,
    };
  }
}
