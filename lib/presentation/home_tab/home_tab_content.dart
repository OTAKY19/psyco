import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../router/app_routes.dart';
import '../../services/subscription_service.dart';
import '../../services/test_service.dart';

/// Accueil filières (IA Stitch) : greeting + dernier test réel +
/// filières concours + progression locale. Zéro donnée simulée :
/// chaque section n'apparaît que si ses données existent.
class HomeTabContent extends StatefulWidget {
  const HomeTabContent({super.key});

  @override
  State<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends State<HomeTabContent> {
  final TestService _testService = TestService();
  final SubscriptionService _subscriptionService = SubscriptionService();

  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic> _stats = {};
  int _remainingFree = 0;
  bool _isPremium = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final history = await _testService.getTestHistory();
    final stats = await _testService.getUserStats();
    final remaining = await _subscriptionService.getRemainingFreeTests();
    final premium = await _subscriptionService.hasActiveSubscription();
    if (!mounted) return;
    setState(() {
      _history = history;
      _stats = stats;
      _remainingFree = remaining;
      _isPremium = premium;
      _loaded = true;
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 18) return 'Bonjour';
    return 'Bonsoir';
  }

  String _formatDate(String? iso) {
    if (iso == null) return '';
    try {
      final date = DateTime.parse(iso);
      final now = DateTime.now();
      final diff = now.difference(date).inDays;
      if (diff <= 0) return "Aujourd'hui";
      if (diff == 1) return 'Hier';
      return 'Il y a $diff jours';
    } catch (_) {
      return '';
    }
  }

  String _categoryLabel(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) =>
            w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.pageHorizontal),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppSpacing.xxl),
            Text(
              '${_greeting()} !',
              style: AppTextStyles.displayMedium.copyWith(
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Heure de la rigueur. À vous de jouer.',
              style: AppTextStyles.bodyMedium.copyWith(
                color: colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
            if (_loaded && _history.isNotEmpty) ...[
              _LastTestCard(
                category:
                    _categoryLabel(_history.first['category']?.toString() ?? ''),
                scorePct: _scorePct(_history.first),
                when: _formatDate(
                    _history.first['completedAt']?.toString()),
                onTap: () =>
                    context.push(AppRoutes.testLibraryDashboard),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
            const _SectionTitle(title: 'Filières & Concours'),
            const SizedBox(height: AppSpacing.md),
            _FiliereCard(
              title: 'Douanes Béninoises',
              subtitle: 'Banque 500 questions • Examens blancs',
              icon: Icons.shield_rounded,
              color: AppColors.primary,
              onTap: () => context.push(AppRoutes.examBlanc),
            ),
            _FiliereCard(
              title: 'Police Républicaine',
              subtitle: 'Via la bibliothèque de tests',
              icon: Icons.local_police_rounded,
              color: AppColors.primary,
              onTap: () =>
                  context.push(AppRoutes.testLibraryDashboard),
            ),
            _FiliereCard(
              title: 'Armée de l’Air',
              subtitle: 'Via la bibliothèque de tests',
              icon: Icons.flight_rounded,
              color: AppColors.primary,
              onTap: () =>
                  context.push(AppRoutes.testLibraryDashboard),
            ),
            const SizedBox(height: AppSpacing.xxl),
            const _SectionTitle(title: 'Ma progression'),
            const SizedBox(height: AppSpacing.md),
            _ProgressCard(
              totalTests: (_stats['totalTests'] as num?)?.toInt() ?? 0,
              averageScore:
                  (_stats['averageScore'] as num?)?.toDouble() ?? 0.0,
              remainingFree: _remainingFree,
              isPremium: _isPremium,
              onTap: () => context.push(_isPremium
                  ? AppRoutes.progressTracking
                  : AppRoutes.activation),
            ),
            // Clearance hauteurs variables + bottom nav (pas de token adapté).
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  double _scorePct(Map<String, dynamic> h) {
    final total = (h['totalQuestions'] as num?)?.toInt() ?? 0;
    final correct = (h['correctAnswers'] as num?)?.toInt() ?? 0;
    if (total <= 0) return 0.0;
    return correct / total * 100;
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: AppTextStyles.headlineSmall.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}

class _LastTestCard extends StatelessWidget {
  final String category;
  final double scorePct;
  final String when;
  final VoidCallback onTap;

  const _LastTestCard({
    required this.category,
    required this.scorePct,
    required this.when,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dernier test évalué${when.isNotEmpty ? ' • $when' : ''}',
            style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.isNotEmpty ? category : 'Test',
                      style: AppTextStyles.titleLarge.copyWith(
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Score : ${scorePct.toStringAsFixed(0)} %',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 44,
                child: OutlinedButton(
                  onPressed: onTap,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Colors.white),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadii.button),
                    ),
                  ),
                  child: const Text("S'entraîner"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FiliereCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _FiliereCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.cardSm),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius:
                        BorderRadius.circular(AppRadii.cardSm),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface
                              .withValues(alpha: 0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurface.withValues(alpha: 0.3),
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final int totalTests;
  final double averageScore;
  final int remainingFree;
  final bool isPremium;
  final VoidCallback onTap;

  const _ProgressCard({
    required this.totalTests,
    required this.averageScore,
    required this.remainingFree,
    required this.isPremium,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final detail = totalTests == 0
        ? (isPremium
            ? 'Premium actif : tests illimités.'
            : '$remainingFree tests gratuits pour commencer.')
        : 'Moyenne ${averageScore.toStringAsFixed(0)} % sur $totalTests test${totalTests > 1 ? 's' : ''}'
            '${isPremium ? '' : ' • $remainingFree gratuits restants'}';
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(AppRadii.cardSm),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  totalTests == 0 ? 'Commencez ici' : 'En progression',
                  style: textTheme.titleSmall?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  detail,
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            height: 44,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.button),
                ),
              ),
              child: Text(isPremium ? 'Mon bilan' : 'Activer'),
            ),
          ),
        ],
      ),
    );
  }
}
