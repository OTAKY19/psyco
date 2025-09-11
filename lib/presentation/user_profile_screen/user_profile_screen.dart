import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';
import '../../services/test_service.dart';
import './widgets/premium_subscription_widget.dart';
import './widgets/profile_header_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/study_statistics_widget.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TestService _testService = TestService();
  
  // État de l'interface utilisateur
  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;
  Map<String, dynamic>? _userStats;
  
  // Données utilisateur (mocked pour le nom et email)
  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Utilisateur DouaneTest",
    "email": "user@douanetest.pro",
    "avatar":
        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150&h=150&fit=crop&crop=face",
    "notificationsEnabled": true,
    "offlineDownloadsEnabled": false,
    "timerEnabled": true,
    "difficultyPreference": "Intermédiaire",
  };

  bool _notificationsEnabled = true;
  bool _offlineDownloadsEnabled = false;
  bool _timerEnabled = true;

  @override
  void initState() {
    super.initState();
    _notificationsEnabled = userData["notificationsEnabled"] as bool;
    _offlineDownloadsEnabled = userData["offlineDownloadsEnabled"] as bool;
    _timerEnabled = userData["timerEnabled"] as bool;
    _loadUserData();
  }
  
  Future<void> _loadUserData() async {
    try {
      final subscriptionInfo = await _subscriptionService.getSubscriptionInfo();
      final userStats = await _testService.getUserStats();
      
      setState(() {
        _subscriptionInfo = subscriptionInfo;
        _userStats = userStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Erreur lors du chargement des données utilisateur: \$e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Profil',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 24,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    // Profile Header
                    ProfileHeaderWidget(
                      userName: userData["name"] as String,
                      userEmail: userData["email"] as String,
                      isPremium: _subscriptionInfo?['isPremium'] ?? false,
                      avatarUrl: userData["avatar"] as String,
                      onEditPressed: _onEditProfile,
                      onAvatarTap: _onChangeAvatar,
                    ),
                    SizedBox(height: 3.h),

                    // Study Statistics
                    StudyStatisticsWidget(
                      totalTests: _userStats?['totalTests'] ?? 0,
                      averageScore: _userStats?['averageScore'] ?? 0.0,
                      currentStreak: 0, // TODO: implémenter les streaks
                    ),
                    SizedBox(height: 3.h),

                    // Premium Subscription
                    PremiumSubscriptionWidget(
                      isPremium: _subscriptionInfo?['isPremium'] ?? false,
                      currentPlan: _getSubscriptionPlanName(),
                      renewalDate: _getSubscriptionDate(),
                      onUpgradePressed: _onManageSubscription,
                    ),
            SizedBox(height: 3.h),

            // Account Settings
            SettingsSectionWidget(
              title: 'Compte',
              items: [
                SettingsItem(
                  title: 'Modifier le profil',
                  subtitle: 'Nom, email, photo de profil',
                  iconName: 'person',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  onTap: _onEditProfile,
                ),
                SettingsItem(
                  title: 'Changer le mot de passe',
                  subtitle: 'Sécurité du compte',
                  iconName: 'lock',
                  iconColor: AppTheme.lightTheme.colorScheme.secondary,
                  onTap: _onChangePassword,
                ),
                SettingsItem(
                  title: 'Préférences email',
                  subtitle: 'Notifications par email',
                  iconName: 'email',
                  iconColor: AppTheme.lightTheme.colorScheme.tertiary,
                  onTap: _onEmailPreferences,
                ),
              ],
            ),

            // Study Preferences
            SettingsSectionWidget(
              title: 'Préférences d\'étude',
              items: [
                SettingsItem(
                  title: 'Minuteur des tests',
                  subtitle: 'Activer/désactiver le chronomètre',
                  iconName: 'timer',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  isToggle: true,
                  toggleValue: _timerEnabled,
                  onToggleChanged: (value) {
                    setState(() {
                      _timerEnabled = value;
                    });
                  },
                ),
                SettingsItem(
                  title: 'Niveau de difficulté',
                  subtitle: userData["difficultyPreference"] as String,
                  iconName: 'tune',
                  iconColor: AppTheme.lightTheme.colorScheme.secondary,
                  onTap: _onDifficultyPreferences,
                ),
                SettingsItem(
                  title: 'Notifications',
                  subtitle: 'Rappels d\'étude',
                  iconName: 'notifications',
                  iconColor: AppTheme.lightTheme.colorScheme.tertiary,
                  isToggle: true,
                  toggleValue: _notificationsEnabled,
                  onToggleChanged: (value) {
                    setState(() {
                      _notificationsEnabled = value;
                    });
                  },
                ),
              ],
            ),

            // App Settings
            SettingsSectionWidget(
              title: 'Paramètres de l\'application',
              items: [
                SettingsItem(
                  title: 'Téléchargements hors ligne',
                  subtitle: 'Télécharger les tests pour un accès hors ligne',
                  iconName: 'download',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  isToggle: true,
                  toggleValue: _offlineDownloadsEnabled,
                  onToggleChanged: (value) {
                    setState(() {
                      _offlineDownloadsEnabled = value;
                    });
                  },
                ),
                SettingsItem(
                  title: 'Utilisation des données',
                  subtitle: 'Gérer la consommation de données',
                  iconName: 'data_usage',
                  iconColor: AppTheme.lightTheme.colorScheme.secondary,
                  onTap: _onDataUsage,
                ),
                SettingsItem(
                  title: 'Langue',
                  subtitle: 'Français',
                  iconName: 'language',
                  iconColor: AppTheme.lightTheme.colorScheme.tertiary,
                  onTap: _onLanguageSettings,
                ),
              ],
            ),

            // Support
            SettingsSectionWidget(
              title: 'Support',
              items: [
                SettingsItem(
                  title: 'Centre d\'aide',
                  subtitle: 'FAQ et guides d\'utilisation',
                  iconName: 'help',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  onTap: _onHelpCenter,
                ),
                SettingsItem(
                  title: 'Contacter le support',
                  subtitle: 'Obtenir de l\'aide personnalisée',
                  iconName: 'support_agent',
                  iconColor: AppTheme.lightTheme.colorScheme.secondary,
                  onTap: _onContactSupport,
                ),
                SettingsItem(
                  title: 'Noter l\'application',
                  subtitle: 'Partagez votre expérience',
                  iconName: 'star_rate',
                  iconColor: AppTheme.lightTheme.colorScheme.tertiary,
                  onTap: _onRateApp,
                ),
              ],
            ),

            // Data Management
            SettingsSectionWidget(
              title: 'Gestion des données',
              items: [
                SettingsItem(
                  title: 'Vider le cache',
                  subtitle: 'Libérer de l\'espace de stockage',
                  iconName: 'clear_all',
                  iconColor: AppTheme.lightTheme.colorScheme.secondary,
                  onTap: _onClearCache,
                ),
                SettingsItem(
                  title: 'Télécharger tous les tests',
                  subtitle: 'Accès hors ligne complet',
                  iconName: 'cloud_download',
                  iconColor: AppTheme.lightTheme.primaryColor,
                  onTap: _onDownloadAllTests,
                ),
                SettingsItem(
                  title: 'Exporter les progrès',
                  subtitle: 'Sauvegarder vos données',
                  iconName: 'file_download',
                  iconColor: AppTheme.lightTheme.colorScheme.tertiary,
                  onTap: _onExportProgress,
                ),
              ],
            ),

            // Logout Button
            SizedBox(height: 2.h),
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: 0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _onLogout,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.lightTheme.colorScheme.error
                      .withValues(alpha: 0.1),
                  foregroundColor: AppTheme.lightTheme.colorScheme.error,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'logout',
                      color: AppTheme.lightTheme.colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Se déconnecter',
                      style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.error,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 4.h),
          ],
        ),
      ),
    );
  }

  void _onEditProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Modifier le profil'),
        content:
            Text('Fonctionnalité de modification du profil à implémenter.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _onChangeAvatar() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Changer la photo de profil',
              style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'camera_alt',
                color: AppTheme.lightTheme.primaryColor,
                size: 24,
              ),
              title: Text('Prendre une photo'),
              onTap: () {
                Navigator.pop(context);
                // Implement camera functionality
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'photo_library',
                color: AppTheme.lightTheme.colorScheme.secondary,
                size: 24,
              ),
              title: Text('Choisir depuis la galerie'),
              onTap: () {
                Navigator.pop(context);
                // Implement gallery selection
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onChangePassword() {
    Navigator.pushNamed(context, '/change-password');
  }

  void _onEmailPreferences() {
    Navigator.pushNamed(context, '/email-preferences');
  }

  void _onDifficultyPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Niveau de difficulté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: Text('Débutant'),
              value: 'Débutant',
              groupValue: userData["difficultyPreference"],
              onChanged: (value) {
                setState(() {
                  userData["difficultyPreference"] = value;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Intermédiaire'),
              value: 'Intermédiaire',
              groupValue: userData["difficultyPreference"],
              onChanged: (value) {
                setState(() {
                  userData["difficultyPreference"] = value;
                });
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: Text('Avancé'),
              value: 'Avancé',
              groupValue: userData["difficultyPreference"],
              onChanged: (value) {
                setState(() {
                  userData["difficultyPreference"] = value;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _onDataUsage() {
    Navigator.pushNamed(context, '/data-usage');
  }

  void _onLanguageSettings() {
    Navigator.pushNamed(context, '/language-settings');
  }

  void _onHelpCenter() {
    Navigator.pushNamed(context, '/help-center');
  }

  void _onContactSupport() {
    Navigator.pushNamed(context, '/contact-support');
  }

  void _onRateApp() {
    // Implement app rating functionality
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Noter l\'application'),
        content: Text(
            'Merci de nous aider à améliorer DouaneTest Pro en laissant une note sur le store.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Open app store for rating
            },
            child: Text('Noter maintenant'),
          ),
        ],
      ),
    );
  }

  void _onClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Vider le cache'),
        content: Text(
            'Êtes-vous sûr de vouloir vider le cache ? Cette action libérera de l\'espace mais nécessitera de retélécharger certaines données.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement cache clearing
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Cache vidé avec succès')),
              );
            },
            child: Text('Vider'),
          ),
        ],
      ),
    );
  }

  void _onDownloadAllTests() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Télécharger tous les tests'),
        content: Text(
            'Cette action téléchargera tous les tests disponibles pour un accès hors ligne. Cela peut prendre du temps et utiliser des données.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement download all tests
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Téléchargement en cours...')),
              );
            },
            child: Text('Télécharger'),
          ),
        ],
      ),
    );
  }

  void _onExportProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Exporter les progrès'),
        content: Text(
            'Vos données de progression seront exportées dans un fichier CSV.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement progress export
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Données exportées avec succès')),
              );
            },
            child: Text('Exporter'),
          ),
        ],
      ),
    );
  }

  String? _getSubscriptionPlanName() {
    if (_subscriptionInfo == null || !(_subscriptionInfo!['isPremium'] ?? false)) {
      return null;
    }
    
    final subscriptionType = _subscriptionInfo!['subscriptionType'] ?? 'lifetime';
    switch (subscriptionType) {
      case 'lifetime':
        return 'Premium à vie';
      case 'monthly':
        return 'Premium Mensuel';
      case 'yearly':
        return 'Premium Annuel';
      default:
        return 'Premium';
    }
  }
  
  String? _getSubscriptionDate() {
    if (_subscriptionInfo == null || !(_subscriptionInfo!['isPremium'] ?? false)) {
      return null;
    }
    
    final subscriptionDate = _subscriptionInfo!['subscriptionDate'];
    if (subscriptionDate != null) {
      try {
        final date = DateTime.parse(subscriptionDate);
        return '${date.day}/${date.month}/${date.year}';
      } catch (e) {
        return subscriptionDate;
      }
    }
    
    return null;
  }
  
  void _onManageSubscription() {
    final isPremium = _subscriptionInfo?['isPremium'] ?? false;
    
    if (isPremium) {
      // Afficher les informations d'abonnement
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Abonnement Premium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Statut: Premium Actif ✅'),
              SizedBox(height: 1.h),
              Text('Plan: ${_getSubscriptionPlanName() ?? "Premium"}'),
              if (_getSubscriptionDate() != null) ..[
                SizedBox(height: 0.5.h),
                Text('Activé le: ${_getSubscriptionDate()}'),
              ],
              if (_subscriptionInfo!['transactionId'] != null) ..[
                SizedBox(height: 0.5.h),
                Text('Transaction: ${_subscriptionInfo!['transactionId']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      );
    } else {
      // Naviguer vers l'écran de paiement
      Navigator.pushNamed(context, AppRoutes.mobileMoneyPayment);
    }
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Se déconnecter'),
        content: Text(
            'Êtes-vous sûr de vouloir vous déconnecter ? Vos progrès seront sauvegardés.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Implement logout functionality
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.error,
            ),
            child: Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}
