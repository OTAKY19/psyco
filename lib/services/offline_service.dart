import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/question.dart';
import 'database_service.dart';

class OfflineService {
  static const String _offlineModeKey = 'offline_mode_enabled';
  static const String _cachedQuestionsKey = 'cached_questions';
  static const String _pendingResultsKey = 'pending_results';
  
  final DatabaseService _databaseService = DatabaseService();
  
  // Vérifier si le mode hors-ligne est activé
  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlineModeKey) ?? false;
  }
  
  // Activer/désactiver le mode hors-ligne
  Future<void> setOfflineMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlineModeKey, enabled);
    
    if (enabled) {
      await _cacheEssentialData();
    }
  }
  
  // Vérifier la connectivité
  Future<bool> isConnected() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return !connectivityResult.every((r) => r == ConnectivityResult.none);
  }
  
  // Mettre en cache les données essentielles
  Future<void> _cacheEssentialData() async {
    try {
      // Mettre en cache les questions les plus utilisées
      final questions = await _databaseService.getRandomQuestions(limit: 100);
      final prefs = await SharedPreferences.getInstance();
      
      final questionsJson = questions.map((q) => {
        'id': q.id,
        'question': q.question,
        'options': q.options,
        'reponse': q.reponse,
        'explication': q.explication,
        'categorie': q.categorie,
        'niveau': q.niveau,
        'imagePath': q.imagePath,
      }).toList();
      
      await prefs.setString(_cachedQuestionsKey, questionsJson.toString());
    } catch (e) {
      debugPrint('Erreur lors de la mise en cache: $e');
    }
  }
  
  // Récupérer les questions en cache
  Future<List<Question>> getCachedQuestions({int limit = 15}) async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(_cachedQuestionsKey);
    
    if (cachedData == null) {
      // Fallback vers la base de données locale
      return await _databaseService.getRandomQuestions(limit: limit);
    }
    
    try {
      // Parser le JSON des questions mises en cache
      final List<dynamic> questionsJson = json.decode(cachedData);
      final List<Question> questions = questionsJson
          .map((json) => Question.fromJson(json as Map<String, dynamic>))
          .toList();
      
      // Mélanger et limiter les questions
      questions.shuffle();
      return questions.take(limit).toList();
      
    } catch (e) {
      debugPrint('Erreur parsing questions offline: $e');
      // Fallback vers la base de données locale en cas d'erreur
      return await _databaseService.getRandomQuestions(limit: limit);
    }
  }
  
  // Sauvegarder les résultats en attente de synchronisation
  Future<void> savePendingResult(Map<String, dynamic> result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final pendingResults = prefs.getStringList(_pendingResultsKey) ?? [];
      
      // Ajouter timestamp et ID unique pour la synchronisation
      final resultWithMetadata = {
        ...result,
        'timestamp': DateTime.now().toIso8601String(),
        'syncId': DateTime.now().millisecondsSinceEpoch.toString(),
      };
      
      // Encoder en JSON au lieu d'utiliser toString()
      pendingResults.add(json.encode(resultWithMetadata));
      await prefs.setStringList(_pendingResultsKey, pendingResults);
      
      debugPrint('Résultat sauvé pour synchronisation: ${resultWithMetadata['syncId']}');
    } catch (e) {
      debugPrint('Erreur sauvegarde résultat offline: $e');
    }
  }
  
  // Synchroniser les résultats en attente
  Future<void> syncPendingResults() async {
    if (!await isConnected()) return;
    
    final prefs = await SharedPreferences.getInstance();
    final pendingResults = prefs.getStringList(_pendingResultsKey) ?? [];
    
    for (final result in pendingResults) {
      try {
        // TODO: Envoyer vers le serveur
        debugPrint('Synchronisation du résultat: $result');
      } catch (e) {
        debugPrint('Erreur de synchronisation: $e');
      }
    }
    
    // Nettoyer les résultats synchronisés
    await prefs.remove(_pendingResultsKey);
  }
  
  // Obtenir le statut du mode hors-ligne
  Future<Map<String, dynamic>> getOfflineStatus() async {
    final isEnabled = await isOfflineModeEnabled();
    final isConnected = await this.isConnected();
    final prefs = await SharedPreferences.getInstance();
    final pendingCount = (prefs.getStringList(_pendingResultsKey) ?? []).length;
    
    return {
      'enabled': isEnabled,
      'connected': isConnected,
      'pendingResults': pendingCount,
      'canSync': isConnected && pendingCount > 0,
    };
  }
}
