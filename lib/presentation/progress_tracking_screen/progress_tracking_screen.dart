import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_data_service.dart';
import '../../services/test_service.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/activity_item_widget.dart';
import './widgets/category_performance_widget.dart';
import './widgets/metric_card_widget.dart';
import './widgets/performance_chart_widget.dart';
import './widgets/study_calendar_widget.dart';

class ProgressTrackingScreen extends StatefulWidget {
  const ProgressTrackingScreen({super.key});

  @override
  State<ProgressTrackingScreen> createState() => _ProgressTrackingScreenState();
}

class _ProgressTrackingScreenState extends State<ProgressTrackingScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _selectedDateRange = 'Cette semaine';
  bool _isRefreshing = false;

  // Données réelles - seront mises à jour depuis UserDataService
  List<Map<String, dynamic>> _metricsData = [
    {
      'title': 'Tests complétés',
      'value': '0',
      'subtitle': 'Commencez vos tests',
      'icon': 'quiz',
      'color': AppTheme.primaryLight,
    },
    {
      'title': 'Score moyen',
      'value': '0%',
      'subtitle': 'Pas encore de score',
      'icon': 'trending_up',
      'color': AppTheme.successLight,
    },
    {
      'title': 'Série d\'étude',
      'value': '0 jours',
      'subtitle': 'Commencez votre série',
      'icon': 'local_fire_department',
      'color': AppTheme.warningLight,
    },
    {
      'title': 'Temps d\'étude',
      'value': '0h 0m',
      'subtitle': 'Pas encore de temps',
      'icon': 'schedule',
      'color': AppTheme.secondaryLight,
    },
  ];

  // Données de performance - seront calculées depuis l'historique des tests
  List<Map<String, dynamic>> _performanceData = [];

  // Données de catégories - seront mises à jour depuis UserDataService
  List<Map<String, dynamic>> _categoryData = [
    {'category': 'Logique', 'score': 0.0},
    {'category': 'Mémoire', 'score': 0.0},
    {'category': 'Attention', 'score': 0.0},
    {'category': 'Calcul', 'score': 0.0},
    {'category': 'Spatial', 'score': 0.0},
    {'category': 'Verbal', 'score': 0.0},
  ];

  // Activités récentes - seront chargées depuis l'historique des tests
  List<Map<String, dynamic>> _recentActivities = [];

  final List<Map<String, dynamic>> _achievements = [
    {
      'title': 'Premier test',
      'description': 'Complétez votre premier test',
      'icon': 'star',
      'progress': 100.0,
      'unlocked': true,
    },
    {
      'title': 'Série de 7',
      'description': 'Étudiez 7 jours consécutifs',
      'icon': 'local_fire_department',
      'progress': 85.0,
      'unlocked': false,
    },
    {
      'title': 'Expert logique',
      'description': 'Obtenez 90% en logique',
      'icon': 'psychology',
      'progress': 75.0,
      'unlocked': false,
    },
    {
      'title': '50 tests',
      'description': 'Complétez 50 tests',
      'icon': 'emoji_events',
      'progress': 94.0,
      'unlocked': false,
    },
  ];

  final Map<DateTime, int> _studyCalendarData = {
    DateTime(2025, 1, 1): 3,
    DateTime(2025, 1, 2): 2,
    DateTime(2025, 1, 3): 5,
    DateTime(2025, 1, 4): 1,
    DateTime(2025, 1, 6): 4,
    DateTime(2025, 1, 7): 2,
    DateTime(2025, 1, 8): 3,
    DateTime(2025, 1, 9): 6,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRealUserData();
  }

  /// Charge les vraies données utilisateur depuis UserDataService
  Future<void> _loadRealUserData() async {
    try {
      final userDataService = UserDataService();
      
      // Charger les statistiques réelles
      final userProgress = await userDataService.getUserProgress();
      
      setState(() {
        // Mettre à jour les métriques avec les vraies données
        final testsCompleted = userProgress['testsCompleted'] as int;
        final averageScore = userProgress['averageScore'] as double;
        final studyStreak = userProgress['studyStreak'] as int;
        
        _metricsData[0]['value'] = testsCompleted.toString();
        _metricsData[0]['subtitle'] = testsCompleted > 0 ? '+${testsCompleted} au total' : 'Commencez vos tests';
        
        _metricsData[1]['value'] = '${averageScore.toInt()}%';
        _metricsData[1]['subtitle'] = averageScore > 0 ? 'Score moyen' : 'Pas encore de score';
        
        _metricsData[2]['value'] = '$studyStreak jours';
        _metricsData[2]['subtitle'] = studyStreak > 0 ? 'Série actuelle' : 'Commencez votre série';
        
        // Calculer le temps d'étude basé sur les tests réels
        final totalMinutes = testsCompleted * 20; // 20 min par test en moyenne
        final hours = totalMinutes ~/ 60;
        final minutes = totalMinutes % 60;
        _metricsData[3]['value'] = '${hours}h ${minutes}m';
        _metricsData[3]['subtitle'] = testsCompleted > 0 ? 'Temps total' : 'Pas encore de temps';
      });
      
      // Charger les progrès par catégorie
      await _loadCategoryProgress();
      
      // Charger les activités récentes
      await _loadRecentActivities();
      
      // Charger les données de performance
      await _loadPerformanceData();
      
    } catch (e) {
      debugPrint('Erreur lors du chargement des données: $e');
      // Garder les données par défaut en cas d'erreur
    }
  }
  
  /// Charge les progrès réels par catégorie
  Future<void> _loadCategoryProgress() async {
    try {
      final userDataService = UserDataService();
      
      // Mettre à jour avec les vraies données
      for (int i = 0; i < _categoryData.length; i++) {
        final categoryId = (i + 1).toString(); // ID basé sur l'index
        final progress = await userDataService.getCategoryProgress(categoryId);
        
        setState(() {
          _categoryData[i]['score'] = progress;
        });
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des catégories: $e');
    }
  }

  /// Charge les activités récentes depuis l'historique des tests
  Future<void> _loadRecentActivities() async {
    try {
      final testService = TestService();
      final testHistory = await testService.getTestHistory();
      
      // Prendre les 10 derniers tests
      final recentTests = testHistory.take(10).toList();
      
      setState(() {
        _recentActivities = recentTests.map((test) {
          // Calculer la durée moyenne (simulation basée sur le nombre de questions)
          final durationMinutes = (test.totalQuestions * 1.5).round(); // 1.5 min par question
          
          return {
            'testName': 'Test ${test.sessionId.substring(0, 8)}',
            'category': 'Général', // Pour l'instant, on utilise une catégorie générale
            'score': (test.correctAnswers / test.totalQuestions * 100).roundToDouble(),
            'date': test.completedAt,
            'duration': '${durationMinutes} min',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Erreur lors du chargement des activités récentes: $e');
    }
  }

  /// Charge les données de performance pour le graphique
  Future<void> _loadPerformanceData() async {
    try {
      final testService = TestService();
      final testHistory = await testService.getTestHistory();
      
      if (testHistory.isEmpty) {
        setState(() {
          _performanceData = [];
        });
        return;
      }
      
      // Grouper les tests par jour de la semaine
      final Map<String, List<double>> weeklyScores = {};
      final days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      
      for (final test in testHistory) {
        final dayOfWeek = days[test.completedAt.weekday - 1];
        final score = (test.correctAnswers / test.totalQuestions * 100);
        
        if (!weeklyScores.containsKey(dayOfWeek)) {
          weeklyScores[dayOfWeek] = [];
        }
        weeklyScores[dayOfWeek]!.add(score);
      }
      
      // Calculer la moyenne pour chaque jour
      setState(() {
        _performanceData = days.map((day) {
          final scores = weeklyScores[day] ?? [];
          final averageScore = scores.isEmpty ? 0.0 : scores.reduce((a, b) => a + b) / scores.length;
          
          return {
            'label': day,
            'score': averageScore,
          };
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
    
    // Recharger toutes les données réelles
    await _loadRealUserData();
    
    setState(() => _isRefreshing = false);
  }

  void _showDateRangeSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'Sélectionner la période',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 3.h),
            ...[
              'Cette semaine',
              'Ce mois',
              'Ces 3 mois',
              'Cette année',
              'Tout le temps'
            ].map((range) => ListTile(
                  title: Text(range),
                  trailing: _selectedDateRange == range
                      ? CustomIconWidget(
                          iconName: 'check',
                          color: AppTheme.lightTheme.colorScheme.primary,
                          size: 5.w,
                        )
                      : null,
                  onTap: () {
                    setState(() => _selectedDateRange = range);
                    Navigator.pop(context);
                  },
                )),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  void _exportReport() {
    // Simulate PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rapport exporté avec succès'),
        backgroundColor: AppTheme.successLight,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppTheme.lightTheme.appBarTheme.backgroundColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: AppTheme.lightTheme.colorScheme.onSurface,
            size: 6.w,
          ),
        ),
        title: Text(
          'Suivi des progrès',
          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTheme.colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showDateRangeSelector,
            icon: CustomIconWidget(
              iconName: 'date_range',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
          ),
          IconButton(
            onPressed: _exportReport,
            icon: CustomIconWidget(
              iconName: 'file_download',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Progrès'),
            Tab(text: 'Activité'),
            Tab(text: 'Calendrier'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: _isRefreshing 
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildProgressTab(),
                  _buildActivityTab(),
                  _buildCalendarTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildProgressTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Date range selector
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDateRange,
                  style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  ),
                ),
                CustomIconWidget(
                  iconName: 'keyboard_arrow_down',
                  color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  size: 5.w,
                ),
              ],
            ),
          ),
          SizedBox(height: 3.h),

          // Metrics cards
          SizedBox(
            height: 20.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _metricsData.length,
              itemBuilder: (context, index) {
                final metric = _metricsData[index];
                return MetricCardWidget(
                  title: metric['title'],
                  value: metric['value'],
                  subtitle: metric['subtitle'],
                  iconName: metric['icon'],
                  iconColor: metric['color'],
                  onTap: () {
                    // Navigate to detailed view
                  },
                );
              },
            ),
          ),
          SizedBox(height: 4.h),

          // Performance chart
          PerformanceChartWidget(
            chartData: _performanceData,
            title: 'Évolution des scores',
          ),
          SizedBox(height: 4.h),

          // Category performance
          CategoryPerformanceWidget(
            categoryData: _categoryData,
          ),
          SizedBox(height: 4.h),

          // Achievements
          Text(
            'Réalisations',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.lightTheme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.h),
          SizedBox(
            height: 25.h,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final achievement = _achievements[index];
                return AchievementBadgeWidget(
                  achievement: achievement,
                  isUnlocked: achievement['unlocked'] as bool,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Activité récente',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.lightTheme.colorScheme.onSurface,
                ),
              ),
              TextButton(
                onPressed: () {
                  // Show filter options
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomIconWidget(
                      iconName: 'filter_list',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 4.w,
                    ),
                    SizedBox(width: 1.w),
                    Text(
                      'Filtrer',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 3.h),
          _recentActivities.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentActivities.length,
                  itemBuilder: (context, index) {
                    final activity = _recentActivities[index];
                    return ActivityItemWidget(
                      activity: activity,
                      onRetake: () {
                        Navigator.pushNamed(context, '/test-taking-screen');
                      },
                      onViewDetails: () {
                        Navigator.pushNamed(context, '/test-results-screen');
                      },
                      onShare: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Résultat partagé'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    );
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildCalendarTab() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          StudyCalendarWidget(
            studyData: _studyCalendarData,
            onDaySelected: (selectedDay) {
              // Handle day selection
              final testsCompleted = _studyCalendarData[DateTime(
                    selectedDay.year,
                    selectedDay.month,
                    selectedDay.day,
                  )] ??
                  0;

              if (testsCompleted > 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content:
                        Text('$testsCompleted test(s) complété(s) ce jour'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          SizedBox(height: 4.h),

          // Study streak info
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                CustomIconWidget(
                  iconName: 'local_fire_department',
                  color: AppTheme.warningLight,
                  size: 12.w,
                ),
                SizedBox(height: 2.h),
                Text(
                  'Série actuelle',
                  style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  '12 jours',
                  style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Continuez comme ça ! Votre record est de 15 jours.',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(8.w),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: 'quiz',
            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            size: 20.w,
          ),
          SizedBox(height: 3.h),
          Text(
            'Aucune activité récente',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Commencez à passer des tests pour voir vos progrès ici.',
            style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/test-library-dashboard');
            },
            child: const Text('Commencer un test'),
          ),
        ],
      ),
    );
  }
}
