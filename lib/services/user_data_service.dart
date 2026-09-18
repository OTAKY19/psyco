import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _completedTestsKey = 'completed_tests';
  static const String _averageScoreKey = 'average_score';
  static const String _studyStreakKey = 'study_streak';
  static const String _lastSyncKey = 'last_sync';
  static const String _totalStudyTimeKey = 'total_study_time';
  static const String _lastStudyDateKey = 'last_study_date';
  static const String _currentStreakKey = 'current_streak';

  // Singleton pattern
  static final UserDataService _instance = UserDataService._internal();
  factory UserDataService() => _instance;
  UserDataService._internal();

  /// Sauvegarde les progrès de l'utilisateur
  Future<void> saveUserProgress(Map<String, dynamic> progress) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder les statistiques générales
      if (progress.containsKey('testsCompleted')) {
        await prefs.setInt(_completedTestsKey, progress['testsCompleted']);
      }
      
      if (progress.containsKey('averageScore')) {
        await prefs.setDouble(_averageScoreKey, progress['averageScore']);
      }
      
      if (progress.containsKey('studyStreak')) {
        await prefs.setInt(_studyStreakKey, progress['studyStreak']);
      }
      
      // Mettre à jour la date de synchronisation
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des progrès: $e');
    }
  }

  /// Récupère les progrès de l'utilisateur
  Future<Map<String, dynamic>> getUserProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      return {
        'testsCompleted': prefs.getInt(_completedTestsKey) ?? 0,
        'averageScore': prefs.getDouble(_averageScoreKey) ?? 0.0,
        'studyStreak': prefs.getInt(_studyStreakKey) ?? 0,
        'lastSync': prefs.getString(_lastSyncKey),
      };
    } catch (e) {
      // Retourner valeurs par défaut en cas d'erreur
      return {
        'testsCompleted': 0,
        'averageScore': 0.0,
        'studyStreak': 0,
        'lastSync': null,
      };
    }
  }

  /// Sauvegarde les préférences utilisateur
  Future<void> saveUserPreferences(Map<String, dynamic> preferences) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Sauvegarder chaque préférence individuellement
      for (String key in preferences.keys) {
        final value = preferences[key];
        if (value is String) {
          await prefs.setString('pref_$key', value);
        } else if (value is int) {
          await prefs.setInt('pref_$key', value);
        } else if (value is double) {
          await prefs.setDouble('pref_$key', value);
        } else if (value is bool) {
          await prefs.setBool('pref_$key', value);
        } else if (value is List<String>) {
          await prefs.setStringList('pref_$key', value);
        }
      }
      
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde des préférences: $e');
    }
  }

  /// Récupère les préférences utilisateur
  Future<Map<String, dynamic>> getUserPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('pref_'));
      
      Map<String, dynamic> preferences = {};
      for (String key in keys) {
        String cleanKey = key.replaceFirst('pref_', '');
        preferences[cleanKey] = prefs.get(key);
      }
      
      // Valeurs par défaut si aucune préférence
      if (preferences.isEmpty) {
        return {
          'studyPreferences': <String>[],
          'notificationsEnabled': true,
          'weeklyGoal': 5,
          'difficultyLevel': 'Moyen',
        };
      }
      
      return preferences;
    } catch (e) {
      // Retourner valeurs par défaut en cas d'erreur
      return {
        'studyPreferences': <String>[],
        'notificationsEnabled': true,
        'weeklyGoal': 5,
        'difficultyLevel': 'Moyen',
      };
    }
  }

  /// Met à jour le score d'une catégorie spécifique
  Future<void> updateCategoryProgress(String categoryId, double percentage) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('category_progress_$categoryId', percentage);
      
      // Recalculer le score moyen général
      await _recalculateAverageScore();
      
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du progrès: $e');
    }
  }

  /// Récupère le progrès d'une catégorie spécifique
  Future<double> getCategoryProgress(String categoryId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getDouble('category_progress_$categoryId') ?? 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  /// Marque l'onboarding comme terminé
  Future<void> completeOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de l\'onboarding: $e');
    }
  }

  /// L'utilisateur a-t-il déjà vu l'onboarding first-run ?
  Future<bool> isOnboardingCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Recalcule le score moyen basé sur tous les progrès de catégories
  Future<void> _recalculateAverageScore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('category_progress_'));
      
      if (keys.isEmpty) return;
      
      double total = 0.0;
      for (String key in keys) {
        total += prefs.getDouble(key) ?? 0.0;
      }
      
      double average = total / keys.length;
      await prefs.setDouble(_averageScoreKey, average);
      
    } catch (e) {
      // Ignore les erreurs de recalcul
    }
  }

  /// Réinitialise toutes les données utilisateur
  Future<void> resetUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keysToRemove = prefs.getKeys().where((key) => 
        key.startsWith('user_') || 
        key.startsWith('pref_') || 
        key.startsWith('category_') ||
        key == _completedTestsKey ||
        key == _averageScoreKey ||
        key == _studyStreakKey
      ).toList();
      
      for (String key in keysToRemove) {
        await prefs.remove(key);
      }
      
    } catch (e) {
      throw Exception('Erreur lors de la réinitialisation: $e');
    }
  }

  /// Enregistre un test terminé avec ses détails
  Future<void> saveTestResult(Map<String, dynamic> testResult) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Créer un ID unique pour ce test
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';

      // Sauvegarder les détails du test
      await prefs.setString('test_result_$testId', testResult.toString());

      // Mettre à jour les statistiques générales
      final currentTests = prefs.getInt(_completedTestsKey) ?? 0;
      await prefs.setInt(_completedTestsKey, currentTests + 1);

      // Mettre à jour le score moyen
      final currentAverage = prefs.getDouble(_averageScoreKey) ?? 0.0;
      final newScore = testResult['score'] ?? 0.0;
      final newAverage = ((currentAverage * currentTests) + newScore) / (currentTests + 1);
      await prefs.setDouble(_averageScoreKey, newAverage);

      // Mettre à jour la série d'étude
      await _updateStudyStreak();

      // Mettre à jour le temps total d'étude
      final studyTime = (testResult['duration'] ?? 0) as int;
      final currentTotalTime = prefs.getInt(_totalStudyTimeKey) ?? 0;
      await prefs.setInt(_totalStudyTimeKey, currentTotalTime + studyTime);

    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde du résultat: $e');
    }
  }

  /// Récupère tous les résultats de tests
  Future<List<Map<String, dynamic>>> getAllTestResults() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('test_result_'));

      List<Map<String, dynamic>> results = [];
      for (String key in keys) {
        final resultString = prefs.getString(key);
        if (resultString != null) {
          // Ici on pourrait parser le JSON, mais pour simplifier on retourne une liste basique
          results.add({
            'id': key.replaceFirst('test_result_', ''),
            'data': resultString,
          });
        }
      }

      return results;
    } catch (e) {
      return [];
    }
  }

  /// Met à jour la série d'étude
  Future<void> _updateStudyStreak() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final lastStudyDateString = prefs.getString(_lastStudyDateKey);
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;

      if (lastStudyDateString != null) {
        final lastStudyDate = DateTime.parse(lastStudyDateString);
        final lastStudyDay = DateTime(lastStudyDate.year, lastStudyDate.month, lastStudyDate.day);

        if (lastStudyDay == today) {
          // Déjà étudié aujourd'hui, ne rien changer
          return;
        } else if (lastStudyDay == today.subtract(const Duration(days: 1))) {
          // Étudié hier, augmenter la série
          await prefs.setInt(_currentStreakKey, currentStreak + 1);
        } else {
          // Série rompue, recommencer à 1
          await prefs.setInt(_currentStreakKey, 1);
        }
      } else {
        // Premier jour d'étude
        await prefs.setInt(_currentStreakKey, 1);
      }

      // Mettre à jour la date du dernier jour d'étude
      await prefs.setString(_lastStudyDateKey, today.toIso8601String());

      // Mettre à jour la série maximale si nécessaire
      final maxStreak = prefs.getInt(_studyStreakKey) ?? 0;
      final newStreak = prefs.getInt(_currentStreakKey) ?? 0;
      if (newStreak > maxStreak) {
        await prefs.setInt(_studyStreakKey, newStreak);
      }

    } catch (e) {
      // Ignore les erreurs de mise à jour de série
    }
  }

  /// Récupère les statistiques détaillées de progression
  Future<Map<String, dynamic>> getDetailedProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      final basicProgress = await getUserProgress();
      final totalStudyTime = prefs.getInt(_totalStudyTimeKey) ?? 0;
      final currentStreak = prefs.getInt(_currentStreakKey) ?? 0;
      final lastStudyDate = prefs.getString(_lastStudyDateKey);

      // Calculer des statistiques supplémentaires
      final testResults = await getAllTestResults();
      final categoryProgress = await _getAllCategoryProgress();

      return {
        ...basicProgress,
        'totalStudyTime': totalStudyTime,
        'currentStreak': currentStreak,
        'lastStudyDate': lastStudyDate,
        'totalTestResults': testResults.length,
        'categoryProgress': categoryProgress,
        'studyTimeFormatted': _formatStudyTime(totalStudyTime),
      };
    } catch (e) {
      return await getUserProgress();
    }
  }

  /// Récupère les progrès de toutes les catégories
  Future<Map<String, double>> _getAllCategoryProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('category_progress_'));

      Map<String, double> progress = {};
      for (String key in keys) {
        final categoryId = key.replaceFirst('category_progress_', '');
        progress[categoryId] = prefs.getDouble(key) ?? 0.0;
      }

      return progress;
    } catch (e) {
      return {};
    }
  }

  /// Formate le temps d'étude en format lisible
  String _formatStudyTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;

    if (hours > 0) {
      return '${hours}h ${minutes}min';
    } else {
      return '${minutes}min';
    }
  }

  /// Enregistre une session d'étude
  Future<void> saveStudySession(Map<String, dynamic> sessionData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';

      // Sauvegarder les données de session
      await prefs.setString('study_session_$sessionId', sessionData.toString());

      // Mettre à jour les statistiques
      final duration = (sessionData['duration'] ?? 0) as int;
      final currentTotalTime = prefs.getInt(_totalStudyTimeKey) ?? 0;
      await prefs.setInt(_totalStudyTimeKey, currentTotalTime + duration);

      await _updateStudyStreak();

    } catch (e) {
      throw Exception('Erreur lors de la sauvegarde de la session: $e');
    }
  }

  /// Récupère l'historique des sessions d'étude
  Future<List<Map<String, dynamic>>> getStudySessionsHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith('study_session_'));

      List<Map<String, dynamic>> sessions = [];
      for (String key in keys) {
        final sessionString = prefs.getString(key);
        if (sessionString != null) {
          sessions.add({
            'id': key.replaceFirst('study_session_', ''),
            'data': sessionString,
          });
        }
      }

      // Trier par date (ID contient le timestamp)
      sessions.sort((a, b) => b['id'].compareTo(a['id']));

      return sessions;
    } catch (e) {
      return [];
    }
  }

  /// Synchronise les données avec le serveur (simulation)
  Future<bool> syncWithServer() async {
    try {
      // Simulation d'une synchronisation avec le serveur
      await Future.delayed(const Duration(seconds: 2));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());

      return true;
    } catch (e) {
      return false;
    }
  }
}
