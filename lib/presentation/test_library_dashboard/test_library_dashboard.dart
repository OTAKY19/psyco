import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_data_service.dart';
import './widgets/empty_state_widget.dart';
import './widgets/featured_test_card_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/test_category_card_widget.dart';

class TestLibraryDashboard extends StatefulWidget {
  const TestLibraryDashboard({Key? key}) : super(key: key);

  @override
  State<TestLibraryDashboard> createState() => _TestLibraryDashboardState();
}

class _TestLibraryDashboardState extends State<TestLibraryDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  bool _isOffline = false;
  Map<String, dynamic> _currentFilters = {
    'categories': <String>[],
    'difficulties': <String>[],
    'completionStatus': <String>[],
  };

  // Mock data for test categories
  final List<Map<String, dynamic>> _testCategories = [
    {
      'id': 1,
      'name': 'Tests de Logique',
      'description':
          'Développez votre raisonnement logique avec des séquences, analogies et déductions.',
      'iconName': 'psychology',
      'testCount': 25,
      'completionPercentage': 68,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'Logique',
      'difficulty': 'Moyen',
    },
    {
      'id': 2,
      'name': 'Mathématiques',
      'description':
          'Maîtrisez les calculs mentaux, pourcentages et problèmes arithmétiques.',
      'iconName': 'calculate',
      'testCount': 30,
      'completionPercentage': 45,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'Mathématiques',
      'difficulty': 'Facile',
    },
    {
      'id': 3,
      'name': 'Français et Orthographe',
      'description':
          'Perfectionnez votre maîtrise de la langue française et de l\'orthographe.',
      'iconName': 'spellcheck',
      'testCount': 20,
      'completionPercentage': 82,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'Français',
      'difficulty': 'Moyen',
    },
    {
      'id': 4,
      'name': 'Culture Générale',
      'description':
          'Enrichissez vos connaissances sur l\'histoire, géographie et actualités du Bénin.',
      'iconName': 'public',
      'testCount': 35,
      'completionPercentage': 23,
      'isPremium': true,
      'isUnlocked': false,
      'category': 'Culture générale',
      'difficulty': 'Difficile',
    },
    {
      'id': 5,
      'name': 'Tests d\'Attention',
      'description':
          'Améliorez votre concentration et capacité d\'observation des détails.',
      'iconName': 'visibility',
      'testCount': 18,
      'completionPercentage': 0,
      'isPremium': true,
      'isUnlocked': false,
      'category': 'Attention',
      'difficulty': 'Moyen',
    },
    {
      'id': 6,
      'name': 'Tests de Mémoire',
      'description':
          'Développez votre mémoire visuelle et auditive avec des exercices ciblés.',
      'iconName': 'memory',
      'testCount': 22,
      'completionPercentage': 91,
      'isPremium': true,
      'isUnlocked': true,
      'category': 'Mémoire',
      'difficulty': 'Difficile',
    },
  ];

  // Mock data for featured tests
  final List<Map<String, dynamic>> _featuredTests = [
    {
      'id': 1,
      'title': 'Test de Logique Avancé',
      'description':
          'Un défi complet pour tester votre raisonnement logique avec des séquences complexes.',
      'duration': 45,
      'questionCount': 30,
      'difficulty': 'Difficile',
      'category': 'Logique',
    },
    {
      'id': 2,
      'title': 'Calcul Mental Rapide',
      'description':
          'Entraînez-vous aux calculs mentaux avec des exercices chronométrés.',
      'duration': 20,
      'questionCount': 25,
      'difficulty': 'Moyen',
      'category': 'Mathématiques',
    },
    {
      'id': 3,
      'title': 'Culture Générale Bénin',
      'description':
          'Testez vos connaissances sur l\'histoire et la géographie du Bénin.',
      'duration': 30,
      'questionCount': 20,
      'difficulty': 'Moyen',
      'category': 'Culture générale',
    },
  ];

  // User stats (loaded from UserDataService)
  Map<String, dynamic> _userStats = {
    'testsCompleted': 47,
    'averageScore': 78.5,
    'studyStreak': 12,
  };

  List<Map<String, dynamic>> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filteredCategories = List.from(_testCategories);
    _searchController.addListener(_onSearchChanged);
    _loadUserData();
  }

  /// Charge les données utilisateur depuis UserDataService
  Future<void> _loadUserData() async {
    try {
      final userDataService = UserDataService();
      
      // Charger les statistiques utilisateur
      final progress = await userDataService.getUserProgress();
      
      // Charger les progrès de catégories
      List<Map<String, dynamic>> updatedCategories = [];
      for (var category in _testCategories) {
        final categoryId = category['id'].toString();
        final savedProgress = await userDataService.getCategoryProgress(categoryId);
        
        // Utiliser la progression sauvegardée si elle existe
        if (savedProgress > 0) {
          category = Map.from(category);
          category['completionPercentage'] = savedProgress.toInt();
        }
        updatedCategories.add(category);
      }
      
      setState(() {
        _userStats = {
          'testsCompleted': progress['testsCompleted'] ?? 0,
          'averageScore': progress['averageScore'] ?? 0.0,
          'studyStreak': progress['studyStreak'] ?? 0,
        };
        _testCategories.clear();
        _testCategories.addAll(updatedCategories);
        _filteredCategories = List.from(_testCategories);
      });
      
    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Continuer avec les données par défaut en cas d\'erreur
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredCategories = List.from(_testCategories);
      } else {
        _filteredCategories = _testCategories.where((category) {
          final name = (category['name'] as String).toLowerCase();
          final description = (category['description'] as String).toLowerCase();
          final categoryType = (category['category'] as String).toLowerCase();
          return name.contains(query) ||
              description.contains(query) ||
              categoryType.contains(query);
        }).toList();
      }
    });
  }

  void _applyFilters(Map<String, dynamic> filters) {
    setState(() {
      _currentFilters = filters;
      _filteredCategories = _testCategories.where((category) {
        final categories = filters['categories'] as List<String>;
        final difficulties = filters['difficulties'] as List<String>;
        final completionStatus = filters['completionStatus'] as List<String>;

        bool matchesCategory =
            categories.isEmpty || categories.contains(category['category']);

        bool matchesDifficulty = difficulties.isEmpty ||
            difficulties.contains(category['difficulty']);

        bool matchesCompletion = completionStatus.isEmpty;
        if (!matchesCompletion) {
          final completion = category['completionPercentage'] as int;
          for (String status in completionStatus) {
            if (status == 'Non commencé' && completion == 0) {
              matchesCompletion = true;
              break;
            } else if (status == 'En cours' &&
                completion > 0 &&
                completion < 100) {
              matchesCompletion = true;
              break;
            } else if (status == 'Terminé' && completion >= 100) {
              matchesCompletion = true;
              break;
            }
          }
        }

        return matchesCategory && matchesDifficulty && matchesCompletion;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheetWidget(
        currentFilters: _currentFilters,
        onFiltersChanged: _applyFilters,
      ),
    );
  }

  void _showCategoryContextMenu(Map<String, dynamic> category) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.lightTheme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12.w,
              height: 0.5.h,
              margin: EdgeInsets.symmetric(vertical: 1.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.outline
                    .withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'favorite_border',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text('Marquer comme favori'),
              onTap: () {
                Navigator.pop(context);
                // Handle favorite action
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'download',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text('Télécharger pour hors ligne'),
              onTap: () {
                Navigator.pop(context);
                // Handle download action
              },
            ),
            ListTile(
              leading: CustomIconWidget(
                iconName: 'info',
                color: AppTheme.lightTheme.primaryColor,
                size: 6.w,
              ),
              title: Text('Voir les détails'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/test-category-screen');
              },
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    // Simulate refresh delay
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      // Refresh data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Tab Bar
            Container(
              color: AppTheme.lightTheme.colorScheme.surface,
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Tableau de bord'),
                  Tab(text: 'Tests'),
                  Tab(text: 'Progrès'),
                  Tab(text: 'Profil'),
                ],
              ),
            ),

            // Search Bar
            Container(
              padding: EdgeInsets.all(4.w),
              color: AppTheme.lightTheme.colorScheme.surface,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Rechercher des tests...',
                        prefixIcon: Padding(
                          padding: EdgeInsets.all(3.w),
                          child: CustomIconWidget(
                            iconName: 'search',
                            color: AppTheme
                                .lightTheme.colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _isSearching = false;
                                  });
                                },
                                icon: CustomIconWidget(
                                  iconName: 'clear',
                                  color: AppTheme
                                      .lightTheme.colorScheme.onSurfaceVariant,
                                  size: 5.w,
                                ),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: AppTheme.lightTheme.scaffoldBackgroundColor,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _isSearching = value.isNotEmpty;
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 3.w),
                  GestureDetector(
                    onTap: _showFilterBottomSheet,
                    child: Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: AppTheme.lightTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: CustomIconWidget(
                        iconName: 'tune',
                        color: Colors.white,
                        size: 5.w,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Offline Indicator
            if (_isOffline)
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 1.h),
                color: AppTheme.warningLight.withValues(alpha: 0.1),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CustomIconWidget(
                      iconName: 'wifi_off',
                      color: AppTheme.warningLight,
                      size: 4.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'Mode hors ligne - Contenu mis en cache disponible',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.warningLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Main Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDashboardTab(),
                  _buildTestsTab(),
                  _buildProgressTab(),
                  _buildProfileTab(),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/test-taking-screen');
        },
        icon: CustomIconWidget(
          iconName: 'shuffle',
          color: Colors.white,
          size: 5.w,
        ),
        label: Text(
          'Test Aléatoire',
          style: AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: AppTheme.lightTheme.primaryColor,
      ),
    );
  }

  Widget _buildDashboardTab() {
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 2.h),

            // Quick Stats
            QuickStatsWidget(stats: _userStats),

            SizedBox(height: 3.h),

            // Featured Tests Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Tests recommandés',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            SizedBox(height: 2.h),

            SizedBox(
              height: 20.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: _featuredTests.length,
                itemBuilder: (context, index) {
                  return FeaturedTestCardWidget(
                    test: _featuredTests[index],
                    onTap: () {
                      Navigator.pushNamed(context, '/test-taking-screen');
                    },
                  );
                },
              ),
            ),

            SizedBox(height: 3.h),

            // Categories Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Catégories de tests',
                    style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      _tabController.animateTo(1);
                    },
                    child: Text(
                      'Voir tout',
                      style:
                          AppTheme.lightTheme.textTheme.labelMedium?.copyWith(
                        color: AppTheme.lightTheme.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Display first 3 categories
            ...(_filteredCategories.take(3).map(
                  (category) => TestCategoryCardWidget(
                    category: category,
                    onTap: () {
                      if (category['isPremium'] == true &&
                          category['isUnlocked'] != true) {
                        _showPremiumUpgradeDialog();
                      } else {
                        Navigator.pushNamed(context, '/test-category-screen');
                      }
                    },
                    onLongPress: () => _showCategoryContextMenu(category),
                  ),
                )),

            SizedBox(height: 10.h), // Space for FAB
          ],
        ),
      ),
    );
  }

  Widget _buildTestsTab() {
    if (_filteredCategories.isEmpty) {
      return EmptyStateWidget(
        title: 'Aucun test trouvé',
        description:
            'Essayez de modifier vos critères de recherche ou vos filtres pour trouver des tests.',
        buttonText: 'Réinitialiser les filtres',
        onButtonPressed: () {
          _searchController.clear();
          _applyFilters({
            'categories': <String>[],
            'difficulties': <String>[],
            'completionStatus': <String>[],
          });
        },
      );
    }

    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ListView.builder(
        padding: EdgeInsets.only(bottom: 10.h),
        itemCount: _filteredCategories.length,
        itemBuilder: (context, index) {
          final category = _filteredCategories[index];
          return TestCategoryCardWidget(
            category: category,
            onTap: () {
              if (category['isPremium'] == true &&
                  category['isUnlocked'] != true) {
                _showPremiumUpgradeDialog();
              } else {
                Navigator.pushNamed(context, '/test-category-screen');
              }
            },
            onLongPress: () => _showCategoryContextMenu(category),
          );
        },
      ),
    );
  }

  Widget _buildProgressTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'analytics',
            color: AppTheme.lightTheme.primaryColor,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Suivi des progrès',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Consultez vos statistiques détaillées',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/progress-tracking-screen');
            },
            child: Text('Voir les progrès'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: 'person',
            color: AppTheme.lightTheme.primaryColor,
            size: 20.w,
          ),
          SizedBox(height: 2.h),
          Text(
            'Profil utilisateur',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Gérez votre compte et vos préférences',
            style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(context, '/user-profile-screen');
            },
            child: Text('Voir le profil'),
          ),
        ],
      ),
    );
  }

  void _showPremiumUpgradeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: AppTheme.warningLight,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text('Contenu Premium'),
          ],
        ),
        content: Text(
          'Ce contenu nécessite un abonnement premium. Débloquez l\'accès à tous les tests pour améliorer vos chances de réussite au concours.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium upgrade screen
            },
            child: Text('Débloquer'),
          ),
        ],
      ),
    );
  }
}
