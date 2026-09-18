import 'package:flutter/foundation.dart';
import 'one_time_purchase_service.dart';

/// Notificateur d'état premium simplifié pour paiement unique de 3000 FCFA
class PremiumStateNotifier extends ChangeNotifier {
  static final PremiumStateNotifier _instance = PremiumStateNotifier._internal();
  factory PremiumStateNotifier() => _instance;
  PremiumStateNotifier._internal();

  // État du premium
  bool _isPremium = false;
  bool _isLoading = false;
  DateTime? _purchaseDate;
  String? _transactionId;
  Map<String, dynamic>? _premiumInfo;

  // Service de paiement unique
  final OneTimePurchaseService _purchaseService = OneTimePurchaseService();

  // ===========================================
  // GETTERS
  // ===========================================

  /// Indique si l'utilisateur a l'accès premium
  bool get isPremium => _isPremium;

  /// Indique si une opération est en cours
  bool get isLoading => _isLoading;

  /// Date d'achat premium (si disponible)
  DateTime? get purchaseDate => _purchaseDate;

  /// ID de transaction premium (si disponible)
  String? get transactionId => _transactionId;

  /// Informations complètes du premium
  Map<String, dynamic>? get premiumInfo => _premiumInfo;

  /// Prix fixe du premium
  double get premiumPrice => OneTimePurchaseService.fixedPrice;

  /// Prix formaté pour affichage
  String get formattedPrice => _purchaseService.getFormattedPrice();

  // ===========================================
  // INITIALISATION
  // ===========================================

  /// Initialise l'état premium au démarrage de l'application
  Future<void> initialize() async {
    await _updatePremiumStatus();
  }

  /// Met à jour le statut premium depuis le stockage local
  Future<void> _updatePremiumStatus() async {
    if (_isLoading) return; // Éviter les appels multiples

    _isLoading = true;
    notifyListeners();

    try {
      // Vérifier le statut premium
      final hasPremium = await _purchaseService.hasPremiumAccess();

      if (hasPremium) {
        // Récupérer les informations détaillées
        final info = await _purchaseService.getPremiumInfo();

        _isPremium = true;
        _premiumInfo = info;
        _purchaseDate = info?['purchase_date'];
        _transactionId = info?['transaction_id'];

        if (kDebugMode) {
          debugPrint('✅ État premium: Actif (Transaction: $_transactionId)');
        }
      } else {
        _isPremium = false;
        _premiumInfo = null;
        _purchaseDate = null;
        _transactionId = null;

        if (kDebugMode) {
          debugPrint('ℹ️ État premium: Inactif');
        }
      }
    } catch (e) {
      debugPrint('❌ Erreur mise à jour statut premium: $e');
      // En cas d'erreur, considérer comme non-premium pour la sécurité
      _isPremium = false;
      _premiumInfo = null;
      _purchaseDate = null;
      _transactionId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ===========================================
  // MÉTHODES PUBLIQUES
  // ===========================================

  /// Rafraîchit le statut premium manuellement
  Future<void> refresh() async {
    await _updatePremiumStatus();
  }

  /// Active le statut premium après un paiement réussi
  Future<void> activatePremium(String transactionId) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Confirmer le paiement
      final result = await _purchaseService.confirmPayment(transactionId);

      if (result['success']) {
        // Mettre à jour l'état local
        await _updatePremiumStatus();

        if (kDebugMode) {
          debugPrint('🎉 Premium activé avec succès: $transactionId');
        }
      } else {
        throw Exception(result['error'] ?? 'Échec de l\'activation premium');
      }
    } catch (e) {
      debugPrint('❌ Erreur activation premium: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Vérifie si une fonctionnalité spécifique est accessible
  bool canAccess(String feature) {
    // Si premium, tout est accessible
    if (_isPremium) return true;

    // Fonctionnalités gratuites toujours accessibles
    const freeFeatures = [
      'demo_tests',           // Tests de démonstration (15 questions)
      'basic_results',        // Résultats de base
      'app_navigation',       // Navigation dans l'app
      'settings',            // Paramètres de base
      'help',                // Aide et FAQ
    ];

    return freeFeatures.contains(feature);
  }

  /// Vérifie si l'utilisateur peut voir tous les résultats
  bool get canViewFullResults => _isPremium;

  /// Vérifie si l'utilisateur peut faire des tests illimités
  bool get canTakeUnlimitedTests => _isPremium;

  /// Vérifie si l'utilisateur peut accéder aux statistiques détaillées
  bool get canViewDetailedStats => _isPremium;

  /// Vérifie si l'utilisateur peut accéder à toutes les catégories
  bool get canAccessAllCategories => _isPremium;

  /// Nombre de questions accessibles selon le statut
  int get maxQuestionsPerTest => _isPremium ? 40 : 15;

  /// Message à afficher pour encourager l'upgrade
  String get upgradeMessage {
    if (_isPremium) return '';

    return 'Débloque les 40 questions complètes et toutes les fonctionnalités pour seulement $formattedPrice !';
  }

  // ===========================================
  // MÉTHODES DE DÉVELOPPEMENT/DEBUG
  // ===========================================

  /// Active manuellement le premium (pour tests ou support)
  Future<void> activateManually() async {
    if (!kDebugMode) {
      throw Exception('Activation manuelle disponible uniquement en mode debug');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _purchaseService.activatePremiumManually();
      await _updatePremiumStatus();

      debugPrint('🔧 Premium activé manuellement en mode debug');
    } catch (e) {
      debugPrint('❌ Erreur activation manuelle: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Désactive le premium (pour tests uniquement)
  Future<void> resetPremiumForTesting() async {
    if (!kDebugMode) {
      throw Exception('Reset disponible uniquement en mode debug');
    }

    try {
      _isLoading = true;
      notifyListeners();

      await _purchaseService.resetPremiumStatus();
      await _updatePremiumStatus();

      debugPrint('🔄 Statut premium réinitialisé pour tests');
    } catch (e) {
      debugPrint('❌ Erreur reset premium: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Obtient des informations de debug sur l'état premium
  Map<String, dynamic> getDebugInfo() {
    return {
      'is_premium': _isPremium,
      'is_loading': _isLoading,
      'purchase_date': _purchaseDate?.toIso8601String(),
      'transaction_id': _transactionId,
      'premium_price': premiumPrice,
      'max_questions': maxQuestionsPerTest,
      'premium_info': _premiumInfo,
      'debug_mode': kDebugMode,
    };
  }

  // ===========================================
  // UTILITAIRES
  // ===========================================

  /// Formate une date pour l'affichage
  String formatDate(DateTime? date) {
    if (date == null) return 'Non disponible';

    return '${date.day.toString().padLeft(2, '0')}/'
           '${date.month.toString().padLeft(2, '0')}/'
           '${date.year}';
  }

  /// Obtient un résumé textuel du statut premium
  String get statusSummary {
    if (_isLoading) return 'Vérification en cours...';

    if (_isPremium) {
      final dateStr = formatDate(_purchaseDate);
      return 'Premium actif depuis le $dateStr';
    } else {
      return 'Version gratuite - Upgrade pour $formattedPrice';
    }
  }

  /// Dispose des ressources (si nécessaire)
  @override
  void dispose() {
    super.dispose();
  }
}
