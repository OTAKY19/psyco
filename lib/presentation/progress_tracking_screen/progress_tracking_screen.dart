import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../router/app_routes.dart';
import '../../services/test_service.dart';
import '../../services/user_data_service.dart';


class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isRefreshing = false;

  // Metrics
  int _totalTests = 0;
  double _averageScore = 0;
  int _currentStreak = 0;

  // Performance chart data
  List<Map<String, dynamic>> _performanceData = [];

  // Category data
  final List<Map<String, dynamic>> _categoryData = [
    {'category': 'Logique', 'score': 0.0},
    {'category': 'Mémoire', 'score': 0.0},
    {'category': 'Attention', 'score': 0.0},
    {'category': 'Calcul', 'score': 0.0},
    {'category': 'Spatial', 'score': 0.0},
    {'category': 'Verbal', 'score': 0.0},
  ];

  // Recent activities
  List<Map<String, dynamic>> _recentActivities = [];

  // Calendar data
  final Map<DateTime, int> _studyCalendarData = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRealUserData();
  }

  Future<void> _loadRealUserData() async {
    try {
      final userDataService = UserDataService();
      final userProgress = await userDataService.getUserProgress();

      setState(() {
        _totalTests = userProgress['testsCompleted'] as int;
        _averageScore = userProgress['averageScore'] as double;
        _currentStreak = userProgress['studyStreak'] as int;
      });

      await _loadCategoryProgress();
      await _loadRecentActivities();
      await _loadPerformanceData();
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
    }
  }

  Future<void> _loadCategoryProgress() async {
    try {
      final userDataService = UserDataService();
      for (int i = 0; i < _categoryData.length; i++) {
        final categoryId = (i + 1).toString();
        final progress = await userDataService.getCategoryProgress(categoryId);
        setState(() => _categoryData[i]['score'] = progress);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des catégories: $e');
    }
  }

  Future<void> _loadRecentActivities() async {
    try {
      final testService = TestService();
      final testHistory = await testService.getTestHistory();
      final recentTests = testHistory.take(10).toList();

      setState(() {
        _recentActivities = recentTests.map((test) {
          final durationMinutes = (test['totalQuestions'] * 1.5).round();
          return {
            'testName': 'Test ${test['sessionId'].substring(0, 8)}',
            'category': 'Général',
            'score': (test['correctAnswers'] / test['totalQuestions'] * 100).roundToDouble(),
            'date': test['completedAt'],
            'duration': '$durationMinutes min',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des activités récentes: $e');
    }
  }

  Future<void> _loadPerformanceData() async {
    try {
      final testService = TestService();
      final testHistory = await testService.getTestHistory();

      if (testHistory.isEmpty) {
        setState(() => _performanceData = []);
        return;
      }

      final Map<String, List<double>> weeklyScores = {};
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];

      for (final test in testHistory) {
        final dayOfWeek = days[test['completedAt'].weekday - 1];
        final score = (test['correctAnswers'] / test['totalQuestions'] * 100);
        weeklyScores.putIfAbsent(dayOfWeek, () => []).add(score);
      }

      setState(() {
        _performanceData = days.map((day) {
          final scores = weeklyScores[day] ?? [];
          final avg = scores.isEmpty
              ? 0.0
              : scores.reduce((a, b) => a + b) / scores.length;
          return {'label': day, 'score': avg};
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des données de performance: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() => _isRefreshing = true);
    await _loadRealUserData();
    setState(() => _isRefreshing = false);
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary, size: 24),
        ),
        title: Text(
          'Suivi des progrès',
          style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.file_download_outlined, color: AppColors.primary, size: 24),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          indicatorColor: AppColors.primary,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w400),
          tabs: const [
            Tab(text: 'Progression'),
            Tab(text: 'Activité'),
            Tab(text: 'Calendrier'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: _isRefreshing
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProgressTab(screenWidth),
                  _buildActivityTab(screenWidth),
                  _buildCalendarTab(screenWidth),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 1 — Progression
  // ═══════════════════════════════════════════

  Widget _buildProgressTab(double screenWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Performance chart
          _buildPerformanceChart(screenWidth),
          const SizedBox(height: AppSpacing.xxl),

          // Category breakdown
          _buildCategoryBreakdown(screenWidth),
          const SizedBox(height: AppSpacing.xxl),

          // Overall score
          _buildOverallScore(screenWidth),
        ],
      ),
    );
  }

  Widget _buildPerformanceChart(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Évolution des scores', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            height: 200,
            child: _performanceData.isEmpty
                ? Center(
                    child: Text(
                      'Pas encore de données',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
                    ),
                  )
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: 25,
                        getDrawingHorizontalLine: (value) => const FlLine(
                          color: AppColors.borderLight,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 24,
                            getTitlesWidget: (value, meta) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= _performanceData.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: AppSpacing.xs),
                                child: Text(
                                  _performanceData[idx]['label'] as String,
                                  style: AppTextStyles.caption,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      minX: 0,
                      maxX: 6,
                      minY: 0,
                      maxY: 100,
                      lineBarsData: [
                        LineChartBarData(
                          spots: _performanceData.asMap().entries.map((e) {
                            return FlSpot(
                              e.key.toDouble(),
                              (e.value['score'] as double).clamp(0, 100),
                            );
                          }).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          isStrokeCapRound: true,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) => FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeColor: AppColors.surface,
                              strokeWidth: 2,
                            ),
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: AppColors.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryBreakdown(double screenWidth) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Performance par catégorie', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          ..._categoryData.map((cat) {
            final score = (cat['score'] as double).clamp(0.0, 100.0);
            final color = _categoryColor(score);
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        cat['category'] as String,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '${score.round()}%',
                        style: AppTextStyles.bodySmall.copyWith(color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadii.xs),
                    child: LinearProgressIndicator(
                      value: score / 100,
                      minHeight: 8,
                      backgroundColor: AppColors.surfaceDim,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Color _categoryColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 60) return AppColors.primary;
    if (score >= 40) return AppColors.accent;
    return AppColors.error;
  }

  Widget _buildOverallScore(double screenWidth) {
    final score = _averageScore.clamp(0.0, 100.0).toDouble();
    final color = _categoryColor(score);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Text('Score global', style: AppTextStyles.titleMedium),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: 120,
            height: 120,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 10,
                  backgroundColor: AppColors.surfaceDim,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${score.round()}%',
                        style: AppTextStyles.displayMedium.copyWith(color: color),
                      ),
                      Text(
                        'moyen',
                        style: AppTextStyles.caption,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ScoreStat(label: 'Tests', value: '$_totalTests', color: AppColors.primary),
              _ScoreStat(label: 'Série', value: '$_currentStreak j', color: AppColors.accent),
              _ScoreStat(
                label: 'Niveau',
                value: _levelLabel(score),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _levelLabel(double score) {
    if (score >= 80) return 'Expert';
    if (score >= 60) return 'Avancé';
    if (score >= 40) return 'Moyen';
    return 'Débutant';
  }

  // ═══════════════════════════════════════════
  //  TAB 2 — Activité
  // ═══════════════════════════════════════════

  Widget _buildActivityTab(double screenWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Activité récente', style: AppTextStyles.titleLarge),
          const SizedBox(height: AppSpacing.lg),
          if (_recentActivities.isEmpty)
            _buildEmptyState(screenWidth)
          else
            ..._recentActivities.map((activity) => _buildActivityCard(activity)),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final score = (activity['score'] as double).round();
    final date = activity['date'] as DateTime;
    final timeAgo = _formatTimeAgo(date);
    final color = _categoryColor(score.toDouble());

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.cardSm,
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.iconContainer),
            ),
            child: Icon(Icons.quiz, color: color, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['testName'] as String,
                  style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Row(
                  children: [
                    Text(
                      activity['category'] as String,
                      style: AppTextStyles.caption,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text('·', style: AppTextStyles.caption),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      activity['duration'] as String,
                      style: AppTextStyles.caption,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxs,
                ),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
                child: Text(
                  '$score%',
                  style: AppTextStyles.labelMedium.copyWith(color: color),
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(timeAgo, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays}j';
    return '${date.day}/${date.month}';
  }

  Widget _buildEmptyState(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacing.massive,
        horizontal: AppSpacing.xxl,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.xxl),
            decoration: const BoxDecoration(
              color: AppColors.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.quiz, color: AppColors.primary, size: 48),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(
            'Aucune activité récente',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Commencez à passer des tests pour voir votre historique ici.',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xxl),
          ElevatedButton(
            onPressed: () =>
                context.push(AppRoutes.testLibraryDashboard),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.textOnPrimary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl,
                vertical: AppSpacing.lg,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.button),
              ),
              elevation: 0,
            ),
            child: const Text('Commencer un test'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  TAB 3 — Calendrier
  // ═══════════════════════════════════════════

  Widget _buildCalendarTab(double screenWidth) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: AppSpacing.pagePadding,
      child: Column(
        children: [
          _buildCalendarHeatmap(screenWidth),
          const SizedBox(height: AppSpacing.xxl),
          _buildStreakCard(screenWidth),
        ],
      ),
    );
  }

  Widget _buildCalendarHeatmap(double screenWidth) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final startWeekday = firstDay.weekday % 7;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_monthName(now.month)} ${now.year}',
                style: AppTextStyles.titleMedium,
              ),
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 20),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Day headers
          Row(
            children: ['D', 'L', 'M', 'M', 'J', 'V', 'S'].map((d) {
              return Expanded(
                child: Center(
                  child: Text(
                    d,
                    style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          // Calendar grid
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (context, index) {
              if (index < startWeekday) return const SizedBox.shrink();
              final day = index - startWeekday + 1;
              final date = DateTime(now.year, now.month, day);
              final isToday = day == now.day;
              final studyCount = _studyCalendarData[DateTime(date.year, date.month, date.day)] ?? 0;

              return Container(
                decoration: BoxDecoration(
                  color: _heatmapColor(studyCount),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  border: isToday
                      ? Border.all(color: AppColors.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: studyCount > 0 || isToday
                          ? AppColors.textPrimary
                          : AppColors.textMuted,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _HeatmapLegend(label: '0', color: _heatmapColor(0)),
              const SizedBox(width: AppSpacing.md),
              _HeatmapLegend(label: '1-2', color: _heatmapColor(1)),
              const SizedBox(width: AppSpacing.md),
              _HeatmapLegend(label: '3-4', color: _heatmapColor(3)),
              const SizedBox(width: AppSpacing.md),
              _HeatmapLegend(label: '5+', color: _heatmapColor(5)),
            ],
          ),
        ],
      ),
    );
  }

  Color _heatmapColor(int count) {
    if (count == 0) return AppColors.surfaceDim;
    if (count <= 2) return AppColors.primary.withValues(alpha: 0.15);
    if (count <= 4) return AppColors.primary.withValues(alpha: 0.35);
    return AppColors.primary.withValues(alpha: 0.6);
  }

  String _monthName(int month) {
    const names = [
      '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
    ];
    return names[month];
  }

  Widget _buildStreakCard(double screenWidth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xxl),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.ctaLg,
      ),
      child: Column(
        children: [
          const Icon(Icons.local_fire_department, color: AppColors.accent, size: 48),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Série actuelle',
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$_currentStreak jours',
            style: AppTextStyles.displayLarge.copyWith(
              color: AppColors.textOnPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Continuez comme ça !',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textOnPrimary.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ScoreStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ScoreStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.xxs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}

class _HeatmapLegend extends StatelessWidget {
  final String label;
  final Color color;

  const _HeatmapLegend({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }
}
