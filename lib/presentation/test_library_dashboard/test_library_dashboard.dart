import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_data_service.dart';
import '../../services/activation_service.dart';
import '../../widgets/enhanced_dashboard_widgets.dart';
import './widgets/empty_state_widget.dart';
import './widgets/featured_test_card_widget.dart';
import './widgets/filter_bottom_sheet_widget.dart';
import './widgets/quick_stats_widget.dart';
import './widgets/test_category_card_widget.dart';

class TestLibraryDashboard extends StatefulWidget {
  const TestLibraryDashboard({super.key});

  @override
  State<TestLibraryDashboard> createState() => _TestLibraryDashboardState();
}

class _TestLibraryDashboardState extends State<TestLibraryDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isSearching = false;
  final bool _isOffline = false;
  bool _isDarkMode = false; // Nouveau : mode sombre
  bool _isAppActivated = false; // État d'activation de l'app
  String _sortBy = 'popularite'; // Tri par défaut
  Map<String, dynamic> _currentFilters = {
    'categories': <String>[],
    'difficulties': <String>[],
    'completionStatus': <String>[],
  };

  // Mock data for test categories
  final List<Map<String, dynamic>> _testCategories = [
    {
      'id': 'raisonnement_logique',
      'name': 'Tests de Logique',
      'description':
          'Développez votre raisonnement logique avec des séquences, analogies et déductions.',
      'iconName': 'psychology',
      'testCount': 25,
      'completionPercentage': 68,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'raisonnement_logique',
      'difficulty': 'Moyen',
    },
    {
      'id': 'aptitude_numerique',
      'name': 'Mathématiques',
      'description':
          'Maîtrisez les calculs mentaux, pourcentages et problèmes arithmétiques.',
      'iconName': 'calculate',
      'testCount': 30,
      'completionPercentage': 45,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'aptitude_numerique',
      'difficulty': 'Facile',
    },
    {
      'id': 'aptitude_verbale',
      'name': 'Français et Orthographe',
      'description':
          'Perfectionnez votre maîtrise de la langue française et de l\'orthographe.',
      'iconName': 'spellcheck',
      'testCount': 20,
      'completionPercentage': 82,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'aptitude_verbale',
      'difficulty': 'Moyen',
    },
    {
      'id': 'culture_generale', // Assuming 'culture_generale' is a valid category in your data or will be handled
      'name': 'Culture Générale',
      'description':
          'Enrichissez vos connaissances sur l\'histoire, géographie et actualités du Bénin.',
      'iconName': 'public',
      'testCount': 35,
      'completionPercentage': 23,
      'isPremium': true,
      'isUnlocked': false,
      'category': 'culture_generale',
      'difficulty': 'Difficile',
    },
    {
      'id': 'memoire_attention',
      'name': 'Tests d\'Attention et Mémoire',
      'description':
          'Améliorez votre concentration, capacité d\'observation et mémoire.',
      'iconName': 'visibility',
      'testCount': 40, // Combined count
      'completionPercentage': 0,
      'isPremium': true,
      'isUnlocked': false,
      'category': 'memoire_attention',
      'difficulty': 'Moyen',
    },
    {
      'id': 'raisonnement_spatial',
      'name': 'Raisonnement Spatial',
      'description':
          'Développez votre capacité à manipuler des formes et des espaces.',
      'iconName': 'grid_view',
      'testCount': 22,
      'completionPercentage': 0,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'raisonnement_spatial',
      'difficulty': 'Moyen',
    },
    {
      'id': 'rapidite_personnalite',
      'name': 'Rapidité et Personnalité',
      'description':
          'Évaluez votre rapidité de traitement et vos traits de personnalité.',
      'iconName': 'speed',
      'testCount': 15,
      'completionPercentage': 0,
      'isPremium': false,
      'isUnlocked': true,
      'category': 'rapidite_personnalite',
      'difficulty': 'Facile',
    },
  ];

  // Mock data for featured tests with enhanced features
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
      'rating': 4.8,
      'attempts': 1250,
      'successRate': 68.5,
      'isNew': false,
      'isPopular': true,
      'tags': ['Logique', 'Avancé', 'Séquence'],
      'estimatedTime': '45 min',
      'points': 150,
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
      'rating': 4.6,
      'attempts': 890,
      'successRate': 72.3,
      'isNew': true,
      'isPopular': false,
      'tags': ['Mathématiques', 'Rapidité', 'Mental'],
      'estimatedTime': '20 min',
      'points': 100,
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
      'rating': 4.9,
      'attempts': 2100,
      'successRate': 75.8,
      'isNew': false,
      'isPopular': true,
      'tags': ['Culture', 'Bénin', 'Histoire'],
      'estimatedTime': '30 min',
      'points': 120,
    },
    {
      'id': 4,
      'title': 'Test de Mémoire Interactive',
      'description':
          'Développez votre mémoire avec des exercices visuels et auditifs interactifs.',
      'duration': 25,
      'questionCount': 15,
      'difficulty': 'Facile',
      'category': 'Mémoire',
      'rating': 4.7,
      'attempts': 650,
      'successRate': 80.2,
      'isNew': true,
      'isPopular': false,
      'tags': ['Mémoire', 'Interactif', 'Visuel'],
      'estimatedTime': '25 min',
      'points': 90,
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
      final activationService = ActivationService();

      // Vérifier l'état d'activation de l'app
      final isActivated = await activationService.isAppActivated();

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

        // Bloquer certaines catégories si l'app n'est pas activée
        if (!isActivated && category['isPremium'] == true) {
          category = Map.from(category);
          category['isUnlocked'] = false;
        }

        updatedCategories.add(category);
      }

      setState(() {
        _isAppActivated = isActivated;
        _userStats = {
          'testsCompleted': progress['testsCompleted'] ?? 0,
          'averageScore': progress['averageScore'] ?? 0.0,
          'studyStreak': progress['studyStreak'] ?? 0,
        };
        _testCategories.clear();
        _testCategories.addAll(updatedCategories);
        _filteredCategories = List.from(_testCategories);
      });

      // Vérifier si on doit afficher la popup d'activation
      _checkActivationPrompt();

    } catch (e) {
      debugPrint('Error loading user data: $e');
      // Continuer avec les données par défaut en cas d\'erreur
    }
  }

  /// Vérifie si on doit afficher la popup d'activation
  Future<void> _checkActivationPrompt() async {
    try {
      final activationService = ActivationService();
      final isActivated = await activationService.isAppActivated();

      // Si l'app n'est pas activée, afficher la popup d'activation
      if (!isActivated && mounted) {
        // Afficher la popup d'activation après un court délai
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            _showActivationPrompt();
          }
        });
      }
    } catch (e) {
      debugPrint('Error checking activation prompt: $e');
    }
  }

  /// Affiche la popup d'activation
  void _showActivationPrompt() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'school',
              color: AppTheme.lightTheme.colorScheme.primary,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'Bienvenue sur PsychoTest+ !',
                style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Découvrez PsychoTest+, votre compagnon idéal pour réussir vos concours de la douane !',
              style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '🎯 Version d\'essai gratuite :',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Tests d\'entraînement de base\n• Questions de logique et mathématiques\n• Statistiques simples\n• Mode sombre/clair',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '🔓 Activez pour accéder à TOUT :',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.lightTheme.colorScheme.secondary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '• Examens blancs complets (60 questions)\n• Toutes les catégories de questions\n• Questions mémoire interactives\n• Statistiques avancées\n• Mode hors ligne\n• Mises à jour régulières',
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.monetization_on,
                    color: AppTheme.lightTheme.colorScheme.secondary,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Paiement unique : 2499 FCFA - Pas d\'abonnement !',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppTheme.lightTheme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Marquer comme affiché et continuer en mode gratuit
              final activationService = ActivationService();
              activationService.markActivationPromptShown();
            },
            child: Text('Essayer gratuitement'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Aller vers l'écran d'activation
              Navigator.pushNamed(context, '/activation-screen');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
            ),
            child: Text('Activer maintenant'),
          ),
        ],
      ),
    );
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
                color: AppTheme.lightTheme.colorScheme.primary,
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
                color: AppTheme.lightTheme.colorScheme.primary,
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
                color: AppTheme.lightTheme.colorScheme.primary,
                size: 6.w,
              ),
              title: Text('Voir les détails'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  '/test-category-screen',
                  arguments: {
                    'categoryName': category['name'],
                    'categoryId': category['id'].toString(),
                  },
                );
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
            ModernSearchBarWidget(
              controller: _searchController,
              hintText: 'Rechercher des tests...',
              onFilterTap: _showFilterBottomSheet,
              onChanged: (value) {
                setState(() {
                  _isSearching = value.isNotEmpty;
                });
              },
              showFilter: true,
            ),

            // Sort Bar - Nouvelle fonctionnalité
            Container(
              padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
              color: AppTheme.lightTheme.colorScheme.surface,
              child: Row(
                children: [
                  Text(
                    'Trier par :',
                    style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSortChip('Popularité', 'popularite'),
                          SizedBox(width: 2.w),
                          _buildSortChip('Difficulté', 'difficulte'),
                          SizedBox(width: 2.w),
                          _buildSortChip('Durée', 'duree'),
                          SizedBox(width: 2.w),
                          _buildSortChip('Note', 'note'),
                          SizedBox(width: 2.w),
                          _buildSortChip('Nouveauté', 'nouveaute'),
                        ],
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
          // Test aléatoire avec 15 questions de toutes catégories
          Navigator.pushNamed(
            context,
            '/test-taking-screen',
            arguments: {
              'questionCount': 15,
              'dbCategory': null, // Toutes les catégories
              'duration': 30, // 30 minutes pour test aléatoire
            },
          );
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
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
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
            EnhancedQuickStatsWidget(stats: _userStats),

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
                  final featuredTest = _featuredTests[index];
                  return EnhancedFeaturedTestCardWidget(
                    test: featuredTest,
                    onTap: () {
                      // Navigation vers test avec configuration spécifique
                      Navigator.pushNamed(
                        context,
                        '/test-taking-screen',
                        arguments: {
                          'questionCount': featuredTest['questionCount'] ?? 20,
                          'dbCategory': null, // Tests recommandés = toutes catégories
                          'duration': featuredTest['duration'] ?? 30,
                        },
                      );
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
                        color: AppTheme.lightTheme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Display first 3 categories
            ...(_filteredCategories.take(3).map(
                  (category) => EnhancedTestCategoryCardWidget(
                    category: category,
                    onTap: () {
                      if (category['isPremium'] == true &&
                          category['isUnlocked'] != true) {
                        _showPremiumUpgradeDialog();
                      } else {
                        Navigator.pushNamed(
                          context,
                          '/test-category-screen',
                          arguments: {
                            'categoryName': category['name'],
                            'categoryId': category['id'].toString(),
                          },
                        );
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
          return EnhancedTestCategoryCardWidget(
            category: category,
            onTap: () {
              if (category['isPremium'] == true &&
                  category['isUnlocked'] != true) {
                _showPremiumUpgradeDialog();
              } else {
                Navigator.pushNamed(
                  context,
                  '/test-category-screen',
                  arguments: {
                    'categoryName': category['name'],
                    'categoryId': category['id'].toString(),
                  },
                );
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
            color: AppTheme.lightTheme.colorScheme.primary,
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  width: 25.w,
                  height: 25.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.lightTheme.colorScheme.primary,
                        AppTheme.lightTheme.colorScheme.secondary,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.person,
                    color: Colors.white,
                    size: 15.w,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Profil utilisateur',
                  style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Gérez votre compte et vos préférences',
                  style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                    color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Paramètres Section
          Text(
            'Paramètres',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 2.h),

          // Mode sombre
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: _isDarkMode ? 'dark_mode' : 'light_mode',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mode sombre',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          _isDarkMode ? 'Activé' : 'Désactivé',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: _isDarkMode,
                  onChanged: (value) {
                    setState(() {
                      _isDarkMode = value;
                    });
                    // Ici on pourrait sauvegarder la préférence
                    _saveThemePreference(value);
                  },
                  activeColor: AppTheme.lightTheme.colorScheme.primary,
                ),
              ],
            ),
          ),

          SizedBox(height: 2.h),

          // Autres paramètres
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CustomIconWidget(
                      iconName: 'notifications',
                      color: AppTheme.lightTheme.colorScheme.primary,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          'Rappels et mises à jour',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: true, // Valeur par défaut
                  onChanged: (value) {
                    // Implémenter la logique de notifications
                  },
                  activeColor: AppTheme.lightTheme.colorScheme.primary,
                ),
              ],
            ),
          ),

          SizedBox(height: 4.h),

          // Statistiques utilisateur
          Text(
            'Vos statistiques',
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),

          SizedBox(height: 2.h),

          // Stats Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Tests terminés',
                  _userStats['testsCompleted'].toString(),
                  'quiz',
                  AppTheme.lightTheme.colorScheme.primary,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  'Score moyen',
                  '${_userStats['averageScore']}%',
                  'trending_up',
                  AppTheme.lightTheme.colorScheme.secondary,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Série actuelle',
                  '${_userStats['studyStreak']} jours',
                  'local_fire_department',
                  AppTheme.accentLight,
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: _buildStatCard(
                  'Temps total',
                  '24h 30min',
                  'schedule',
                  AppTheme.lightTheme.colorScheme.tertiary,
                ),
              ),
            ],
          ),

          SizedBox(height: 4.h),

          // Actions
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/user-profile-screen');
              },
              icon: Icon(Icons.edit),
              label: Text('Modifier le profil'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(height: 2.h),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                // Implémenter la déconnexion
              },
              icon: Icon(Icons.logout),
              label: Text('Se déconnecter'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.w),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),

          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, String iconName, Color color) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.lightTheme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: color,
            size: 8.w,
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
              color: AppTheme.lightTheme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _saveThemePreference(bool isDark) {
    // Ici on sauvegarderait la préférence dans SharedPreferences
    // Pour l'instant, juste un print de debug
    debugPrint('Theme preference saved: ${isDark ? 'Dark' : 'Light'}');
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

  // Nouvelle méthode pour les chips de tri
  Widget _buildSortChip(String label, String sortType) {
    final isSelected = _sortBy == sortType;
    return FilterChip(
      label: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : AppTheme.lightTheme.colorScheme.onSurface,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _sortBy = sortType;
            _applySorting();
          });
        }
      },
      backgroundColor: AppTheme.lightTheme.colorScheme.surface,
      selectedColor: AppTheme.lightTheme.colorScheme.primary,
      checkmarkColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected
              ? AppTheme.lightTheme.colorScheme.primary
              : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
    );
  }

  // Nouvelle méthode pour appliquer le tri
  void _applySorting() {
    setState(() {
      switch (_sortBy) {
        case 'popularite':
          _filteredCategories.sort((a, b) {
            final aCompletion = a['completionPercentage'] as int;
            final bCompletion = b['completionPercentage'] as int;
            return bCompletion.compareTo(aCompletion); // Plus populaire en premier
          });
          break;
        case 'difficulte':
          _filteredCategories.sort((a, b) {
            final difficultyOrder = {'Facile': 1, 'Moyen': 2, 'Difficile': 3};
            final aDifficulty = difficultyOrder[a['difficulty']] ?? 2;
            final bDifficulty = difficultyOrder[b['difficulty']] ?? 2;
            return aDifficulty.compareTo(bDifficulty); // Facile vers Difficile
          });
          break;
        case 'duree':
          // Tri par nombre de tests (approximation de la durée)
          _filteredCategories.sort((a, b) {
            final aCount = a['testCount'] as int;
            final bCount = b['testCount'] as int;
            return aCount.compareTo(bCount); // Moins de tests en premier
          });
          break;
        case 'note':
          // Tri par taux de complétion (approximation de la note)
          _filteredCategories.sort((a, b) {
            final aCompletion = a['completionPercentage'] as int;
            final bCompletion = b['completionPercentage'] as int;
            return bCompletion.compareTo(aCompletion); // Meilleures notes en premier
          });
          break;
        case 'nouveaute':
          // Tri par ID (approximation de la nouveauté)
          _filteredCategories.sort((a, b) {
            final aId = a['id'].toString();
            final bId = b['id'].toString();
            return bId.compareTo(aId); // Plus récent en premier
          });
          break;
        default:
          // Tri par défaut : popularité
          _filteredCategories.sort((a, b) {
            final aCompletion = a['completionPercentage'] as int;
            final bCompletion = b['completionPercentage'] as int;
            return bCompletion.compareTo(aCompletion);
          });
      }
    });
  }
}
