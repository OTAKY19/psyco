import 'package:shared_preferences/shared_preferences.dart';

class UserDataService {
  static const String _userProgressKey = 'user_progress';
  static const String _userPreferencesKey = 'user_preferences';
  static const String _completedTestsKey = 'completed_tests';
  static const String _averageScoreKey = 'average_score';
  static const String _studyStreakKey = 'study_streak';
  static const String _lastSyncKey = 'last_sync';

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
