import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../routes/app_routes.dart';
import '../../services/subscription_service.dart';
import '../../services/one_time_purchase_service.dart';
import '../../services/test_service.dart';
import '../../widgets/neural_header_simple.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TestService _testService = TestService();

  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionInfo;
  Map<String, dynamic>? _userStats;

  final Map<String, dynamic> userData = {
    "id": 1,
    "name": "Utilisateur PsychoTest",
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
      debugPrint('Erreur lors du chargement des données utilisateur: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _loadUserData,
              color: AppColors.primary,
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildNeuralHeader(screenWidth),
                  ),
                  SliverToBoxAdapter(
                    child: _buildStatsRow(screenWidth),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg, AppSpacing.xxl, AppSpacing.lg, AppSpacing.xxl,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildSection('Compte', [
                          _SettingItem(
                            icon: Icons.person_outline,
                            iconColor: AppColors.primary,
                            title: 'Modifier le profil',
                            subtitle: 'Nom, email, photo de profil',
                            onTap: _onEditProfile,
                          ),
                          _SettingItem(
                            icon: Icons.lock_outline,
                            iconColor: AppColors.primaryDark,
                            title: 'Changer le mot de passe',
                            subtitle: 'Sécurité du compte',
                            onTap: _onChangePassword,
                          ),
                        ]),
                        _buildSection('Préférences', [
                          _SettingItem(
                            icon: Icons.timer_outlined,
                            iconColor: AppColors.accent,
                            title: 'Minuteur',
                            subtitle: _timerEnabled ? 'Activé' : 'Désactivé',
                            trailing: Switch(
                              value: _timerEnabled,
                              onChanged: (v) => setState(() => _timerEnabled = v),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.tune,
                            iconColor: AppColors.accentDark,
                            title: 'Difficulté',
                            subtitle: userData["difficultyPreference"] as String,
                            onTap: _onDifficultyPreferences,
                          ),
                          _SettingItem(
                            icon: Icons.notifications_outlined,
                            iconColor: AppColors.accentLight,
                            title: 'Notifications',
                            subtitle: 'Rappels d\'étude',
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: (v) => setState(() => _notificationsEnabled = v),
                              activeColor: AppColors.primary,
                            ),
                          ),
                        ]),
                        _buildSection('Application', [
                          _SettingItem(
                            icon: Icons.download_outlined,
                            iconColor: AppColors.success,
                            title: 'Téléchargements hors ligne',
                            subtitle: 'Tests disponibles hors connexion',
                            trailing: Switch(
                              value: _offlineDownloadsEnabled,
                              onChanged: (v) => setState(() => _offlineDownloadsEnabled = v),
                              activeColor: AppColors.primary,
                            ),
                          ),
                          _SettingItem(
                            icon: Icons.language,
                            iconColor: AppColors.primaryLight,
                            title: 'Langue',
                            subtitle: 'Français',
                            onTap: _onLanguageSettings,
                          ),
                        ]),
                        _buildSection('Support', [
                          _SettingItem(
                            icon: Icons.help_outline,
                            iconColor: AppColors.primary,
                            title: 'Centre d\'aide',
                            subtitle: 'FAQ et guides d\'utilisation',
                            onTap: _onHelpCenter,
                          ),
                          _SettingItem(
                            icon: Icons.support_agent,
                            iconColor: AppColors.primaryDark,
                            title: 'Contacter',
                            subtitle: 'Obtenir de l\'aide personnalisée',
                            onTap: _onContactSupport,
                          ),
                          _SettingItem(
                            icon: Icons.star_outline,
                            iconColor: AppColors.accent,
                            title: 'Noter l\'application',
                            subtitle: 'Partagez votre expérience',
                            onTap: _onRateApp,
                          ),
                        ]),
                        _buildSection('Données', [
                          _SettingItem(
                            icon: Icons.cleaning_services_outlined,
                            iconColor: AppColors.warning,
                            title: 'Vider cache',
                            subtitle: 'Libérer de l\'espace de stockage',
                            onTap: _onClearCache,
                          ),
                          _SettingItem(
                            icon: Icons.file_download_outlined,
                            iconColor: AppColors.primary,
                            title: 'Exporter progrès',
                            subtitle: 'Sauvegarder vos données',
                            onTap: _onExportProgress,
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.lg),
                        _buildLogoutButton(),
                        const SizedBox(height: AppSpacing.massive),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildNeuralHeader(double screenWidth) {
    return NeuralHeaderSimple(
      height: screenWidth > 600 ? 220 : 200,
      child: Row(
        children: [
          GestureDetector(
            onTap: _onChangeAvatar,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: screenWidth > 600 ? 36 : 32,
                  backgroundImage: NetworkImage(userData["avatar"] as String),
                  backgroundColor: AppColors.primaryLight.withValues(alpha: 0.3),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userData["name"] as String,
                        style: AppTextStyles.titleLarge.copyWith(
                          color: AppColors.textOnPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (_subscriptionInfo?['isPremium'] ?? false) ...[
                      const SizedBox(width: AppSpacing.sm),
                      GestureDetector(
                        onTap: _onManageSubscription,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xxs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            'PREMIUM',
                            style: AppTextStyles.labelSmall.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  userData["email"] as String,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textOnPrimary.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _onEditProfile,
            icon: Icon(
              Icons.edit_outlined,
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
              size: 20,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(double screenWidth) {
    final totalTests = _userStats?['totalTests'] ?? 0;
    final averageScore = (_userStats?['averageScore'] ?? 0.0).toDouble();
    final currentStreak = _userStats?['currentStreak'] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg, -AppSpacing.xl, AppSpacing.lg, 0,
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatItem(
            value: '$totalTests',
            label: 'Tests',
            color: AppColors.primary,
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          _StatItem(
            value: '${averageScore.round()}%',
            label: 'Score moy.',
            color: AppColors.success,
          ),
          Container(width: 1, height: 36, color: AppColors.border),
          _StatItem(
            value: '$currentStreak',
            label: 'Série',
            color: AppColors.accent,
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<_SettingItem> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(
            left: AppSpacing.xs,
            top: AppSpacing.lg,
            bottom: AppSpacing.sm,
          ),
          child: Text(
            title,
            style: AppTextStyles.labelLarge.copyWith(
              color: AppColors.textMuted,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadii.card),
            boxShadow: AppShadows.cardSm,
          ),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              final isLast = index == items.length - 1;
              return Column(
                children: [
                  _buildSettingsTile(item),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      indent: 56,
                      color: AppColors.borderLight,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTile(_SettingItem item) {
    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(AppRadii.card),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.iconContainer),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (item.subtitle.isNotEmpty)
                    Text(
                      item.subtitle,
                      style: AppTextStyles.bodySmall,
                    ),
                ],
              ),
            ),
            if (item.trailing != null)
              item.trailing!
            else
              const Icon(
                Icons.chevron_right,
                color: AppColors.textMuted,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: _onLogout,
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: Text(
          'Se déconnecter',
          style: AppTextStyles.buttonLarge.copyWith(color: AppColors.error),
        ),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.button),
          ),
          backgroundColor: AppColors.error.withValues(alpha: 0.04),
        ),
      ),
    );
  }

  // ─── Navigation / Dialog ───

  void _onEditProfile() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Modifier le profil'),
        content: const Text('Fonctionnalité de modification du profil à implémenter.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  void _onChangeAvatar() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.modalTop)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Changer la photo de profil',
                style: AppTextStyles.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xl),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                title: const Text('Prendre une photo'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primaryDark),
                title: const Text('Choisir depuis la galerie'),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
                onTap: () {
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _soon(BuildContext context) => ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bientôt disponible')),
      );

  void _onChangePassword() => _soon(context);

  void _onDifficultyPreferences() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Niveau de difficulté'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ['Débutant', 'Intermédiaire', 'Avancé'].map((level) {
            return RadioListTile<String>(
              title: Text(level),
              value: level,
              groupValue: userData["difficultyPreference"],
              activeColor: AppColors.primary,
              onChanged: (value) {
                setState(() => userData["difficultyPreference"] = value);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  void _onLanguageSettings() => _soon(context);
  void _onHelpCenter() => _soon(context);
  void _onContactSupport() => _soon(context);

  void _onRateApp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Noter l\'application'),
        content: const Text(
          'Merci de nous aider à améliorer PsychoTest+ en laissant une note sur le store.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Plus tard')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Noter maintenant'),
          ),
        ],
      ),
    );
  }

  void _onClearCache() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vider le cache'),
        content: const Text(
          'Êtes-vous sûr de vouloir vider le cache ? Cette action libérera de l\'espace mais nécessitera de retélécharger certaines données.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Cache vidé avec succès')),
              );
            },
            child: const Text('Vider'),
          ),
        ],
      ),
    );
  }

  void _onExportProgress() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exporter les progrès'),
        content: const Text('Vos données de progression seront exportées dans un fichier CSV.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Données exportées avec succès')),
              );
            },
            child: const Text('Exporter'),
          ),
        ],
      ),
    );
  }

  String? _getSubscriptionPlanName() {
    if (_subscriptionInfo == null || !(_subscriptionInfo!['isPremium'] ?? false)) return null;
    final subscriptionType = _subscriptionInfo!['subscriptionType'] ?? 'lifetime';
    switch (subscriptionType) {
      case 'lifetime': return 'Premium à vie';
      case 'monthly': return 'Premium Mensuel';
      case 'yearly': return 'Premium Annuel';
      default: return 'Premium';
    }
  }

  String? _getSubscriptionDate() {
    if (_subscriptionInfo == null || !(_subscriptionInfo!['isPremium'] ?? false)) return null;
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
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Activation Premium'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Statut: Premium Actif'),
              const SizedBox(height: AppSpacing.sm),
              Text('Plan: ${_getSubscriptionPlanName() ?? "Premium"}'),
              if (_getSubscriptionDate() != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text('Activé le: ${_getSubscriptionDate()}'),
              ],
              if (_subscriptionInfo!['transactionId'] != null) ...[
                const SizedBox(height: AppSpacing.xxs),
                Text('Transaction: ${_subscriptionInfo!['transactionId']}'),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
            TextButton(
              onPressed: () async {
                // Reçu d'achat (E8) : preuve à conserver / transmettre au support.
                final info =
                    await OneTimePurchaseService().getPremiumInfo();
                final txn =
                    info?['transaction_id']?.toString() ?? 'inconnue';
                final date = info?['purchase_date'] != null
                    ? DateTime.parse(
                            info!['purchase_date'].toString())
                        .toLocal()
                        .toString()
                        .split('.')
                        .first
                    : 'inconnue';
                await SharePlus.instance.share(
                  ShareParams(
                    text: 'Reçu PsychoTest+ Premium\n'
                        'Transaction : $txn\n'
                        'Date : $date\n'
                        'Montant : 3000 FCFA\n'
                        'Conservez ce reçu : il permet de restaurer votre accès.',
                    title: 'Reçu PsychoTest+ Premium',
                  ),
                );
              },
              child: const Text('Partager mon reçu'),
            ),
          ],
        ),
      );
    } else {
      context.push(AppRoutes.mobileMoneyPayment);
    }
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Se déconnecter'),
        content: const Text(
          'Êtes-vous sûr de vouloir vous déconnecter ? Vos progrès seront sauvegardés.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.go(AppRoutes.home);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Se déconnecter'),
          ),
        ],
      ),
    );
  }
}

class _SettingItem {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _SettingItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
  });
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  final Color color;

  const _StatItem({
    required this.value,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTextStyles.headlineLarge.copyWith(color: color),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(
          label,
          style: AppTextStyles.caption,
        ),
      ],
    );
  }
}
