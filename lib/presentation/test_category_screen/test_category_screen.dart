import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/database_service.dart';
import './widgets/context_menu_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';
import './widgets/test_card_widget.dart';

class TestCategoryScreen extends StatefulWidget {
  final String? categoryName;
  final String? categoryId;
  
  const TestCategoryScreen({
    super.key,
    this.categoryName,
    this.categoryId,
  });

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  String _searchQuery = '';
  String _currentSortOption = 'alphabetical';
  final List<Map<String, dynamic>> _activeFilters = [];
  bool _isLoading = true;
  bool _isRefreshing = false;
  
  // Service de base de données
  final DatabaseService _databaseService = DatabaseService();
  
  // Titre dynamique basé sur la catégorie
  String get _categoryTitle => widget.categoryName ?? 'Tests Psychotechniques';

  // Mapping des noms affichés vers les catégories de la base de données
  final Map<String, String> _displayToDbMapping = {
    'Tests de Logique': 'raisonnement_logique',
    'Mathématiques': 'aptitude_numerique',
    'Français et Orthographe': 'aptitude_verbale',
    'Raisonnement Spatial': 'raisonnement_spatial',
    'Tests d\'Attention et Mémoire': 'memoire_attention',
    'Rapidité et Personnalité': 'rapidite_personnalite',
    'Culture Générale': 'culture_generale',
  };

  // Mapping des catégories de la base de données vers les noms affichés
  final Map<String, String> _categoryMapping = {
    'raisonnement_logique': 'Tests de Logique',
    'aptitude_numerique': 'Mathématiques',
    'aptitude_verbale': 'Français et Orthographe',
    'raisonnement_spatial': 'Raisonnement Spatial',
    'memoire_attention': 'Tests d\'Attention et Mémoire',
    'rapidite_personnalite': 'Rapidité et Personnalité',
    'culture_generale': 'Culture Générale',
  };

  // Tests générés dynamiquement basés sur la banque de questions
  List<Map<String, dynamic>> _allTests = [];

  @override
  void initState() {
    super.initState();
    _loadTestsFromDatabase();
  }

  /// Charge les tests depuis la base de données basés sur la catégorie
  Future<void> _loadTestsFromDatabase() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('🔍 Chargement des tests pour la catégorie: ${widget.categoryName}');

      // Obtenir la catégorie de la base de données correspondante
      String? dbCategory;
      if (widget.categoryName != null) {
        // Utiliser le mapping direct pour trouver la catégorie DB
        dbCategory = _displayToDbMapping[widget.categoryName];
        print('📋 Mapping "${widget.categoryName}" -> "$dbCategory"');
        if (dbCategory == null) {
          // Si aucune correspondance n'est trouvée, utiliser categoryId si disponible
          dbCategory = widget.categoryId;
          print('⚠️ Aucune correspondance trouvée pour: ${widget.categoryName}, utilisation de categoryId: $dbCategory');
        }
      } else if (widget.categoryId != null) {
        dbCategory = widget.categoryId;
        print('📋 Utilisation directe de categoryId: $dbCategory');
      }

      // Obtenir le nombre de questions par catégorie
      Map<String, int> questionCounts;
      if (dbCategory != null) {
        // Une catégorie spécifique
        print('🔍 Recherche des questions pour la catégorie: $dbCategory');
        final questions = await _databaseService.getQuestionsByCategory(dbCategory);
        questionCounts = {dbCategory: questions.length};
        print('📊 Questions trouvées pour $dbCategory: ${questions.length}');
      } else {
        // Toutes les catégories
        print('🔍 Chargement de toutes les catégories');
        questionCounts = await _databaseService.getQuestionCountByCategory();
        print('📊 Comptage par catégorie: $questionCounts');
      }

      // Générer les tests dynamiquement
      _allTests = await _generateTestsFromQuestions(questionCounts);
      print('🎯 Tests générés: ${_allTests.length}');

      // Appliquer les filtres et la recherche après avoir chargé les tests
      _applyFiltersAndSearch();
      print('✅ Tests filtrés: ${_filteredTests.length}');

      setState(() {
        _isLoading = false;
      });
    } catch (e, stackTrace) {
      print('❌ Erreur lors du chargement des tests: $e');
      print('📋 Stack trace: $stackTrace');
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Génère des tests dynamiquement basés sur le nombre de questions disponibles
  Future<List<Map<String, dynamic>>> _generateTestsFromQuestions(Map<String, int> questionCounts) async {
    List<Map<String, dynamic>> tests = [];
    int testId = 1;

    for (final entry in questionCounts.entries) {
      final dbCategory = entry.key;
      final questionCount = entry.value;
      final displayCategory = _categoryMapping[dbCategory] ?? dbCategory;

      if (questionCount == 0) continue;

      // Générer différents types de tests selon le nombre de questions disponibles
      final testConfigurations = _getTestConfigurations(questionCount);

      for (final config in testConfigurations) {
        tests.add({
          "id": testId++,
          "title": config['title'],
          "description": config['description'],
          "difficulty": config['difficulty'],
          "duration": config['duration'],
          "iconName": config['iconName'],
          "isPremium": config['isPremium'],
          "isDownloaded": false,
          "isCompleted": false,
          "attemptCount": 0,
          "bestScore": 0.0,
          "category": displayCategory,
          "questionCount": config['questionCount'],
          "type": "Cognitif",
          "dbCategory": dbCategory, // Pour référence lors du test
        });
      }
    }

    return tests;
  }

  /// Génère des configurations de tests basées sur le nombre de questions disponibles
  List<Map<String, dynamic>> _getTestConfigurations(int totalQuestions) {
    List<Map<String, dynamic>> configurations = [];

    if (totalQuestions >= 10) {
      // Test court (10 questions)
      configurations.add({
        'title': 'Test Court',
        'description': 'Test rapide avec 10 questions',
        'difficulty': 2,
        'duration': 15,
        'iconName': 'timer',
        'isPremium': false,
        'questionCount': 10,
      });
    }

    if (totalQuestions >= 20) {
      // Test standard (20 questions)
      configurations.add({
        'title': 'Test Standard',
        'description': 'Test complet avec 20 questions',
        'difficulty': 3,
        'duration': 30,
        'iconName': 'quiz',
        'isPremium': false,
        'questionCount': 20,
      });
    }

    if (totalQuestions >= 30) {
      // Test long (30 questions)
      configurations.add({
        'title': 'Test Long',
        'description': 'Test approfondi avec 30 questions',
        'difficulty': 4,
        'duration': 45,
        'iconName': 'school',
        'isPremium': true,
        'questionCount': 30,
      });
    }

    if (totalQuestions >= 50) {
      // Test marathon (50 questions)
      configurations.add({
        'title': 'Test Marathon',
        'description': 'Test complet avec 50 questions',
        'difficulty': 5,
        'duration': 60,
        'iconName': 'emoji_events',
        'isPremium': true,
        'questionCount': 50,
      });
    }

    // Test personnalisé avec toutes les questions disponibles
    if (totalQuestions > 0) {
      configurations.add({
        'title': 'Test Complet',
        'description': 'Test avec toutes les $totalQuestions questions disponibles',
        'difficulty': 3,
        'duration': (totalQuestions * 1.2).round(), // 1.2 min par question
        'iconName': 'all_inclusive',
        'isPremium': totalQuestions > 40,
        'questionCount': totalQuestions,
      });
    }

    return configurations;
  }

  // Tests filtrés pour l'affichage
  List<Map<String, dynamic>> _filteredTests = [];

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
      _applyFiltersAndSearch();
    });
  }

  void _onSearchClear() {
    setState(() {
      _searchQuery = '';
      _applyFiltersAndSearch();
    });
  }

  void _applyFiltersAndSearch() {
    List<Map<String, dynamic>> filtered = List.from(_allTests);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((test) {
        final title = (test['title'] as String).toLowerCase();
        final description = (test['description'] as String).toLowerCase();
        final category = (test['category'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();

        return title.contains(query) ||
            description.contains(query) ||
            category.contains(query);
      }).toList();
    }

    // Apply active filters
    for (final filter in _activeFilters) {
      final filterType = filter['type'] as String;
      final filterValue = filter['value'] as String;

      switch (filterType) {
        case 'difficulty':
          final difficulty = int.tryParse(filterValue) ?? 0;
          filtered = filtered
              .where((test) => (test['difficulty'] as int) == difficulty)
              .toList();
          break;
        case 'duration':
          final duration = int.tryParse(filterValue) ?? 0;
          filtered = filtered
              .where((test) => (test['duration'] as int) <= duration)
              .toList();
          break;
        case 'status':
          switch (filterValue) {
            case 'completed':
              filtered = filtered
                  .where((test) => test['isCompleted'] == true)
                  .toList();
              break;
            case 'not_started':
              filtered = filtered
                  .where((test) => (test['attemptCount'] as int) == 0)
                  .toList();
              break;
            case 'in_progress':
              filtered = filtered
                  .where((test) =>
                      (test['attemptCount'] as int) > 0 &&
                      test['isCompleted'] == false)
                  .toList();
              break;
          }
          break;
        case 'type':
          filtered = filtered
              .where((test) => (test['type'] as String) == filterValue)
              .toList();
          break;
      }
    }

    setState(() {
      _filteredTests = filtered;
      _applySorting();
    });
  }

  void _applySorting() {
    switch (_currentSortOption) {
      case 'alphabetical':
        _filteredTests.sort(
            (a, b) => (a['title'] as String).compareTo(b['title'] as String));
        break;
      case 'difficulty_asc':
        _filteredTests.sort((a, b) =>
            (a['difficulty'] as int).compareTo(b['difficulty'] as int));
        break;
      case 'difficulty_desc':
        _filteredTests.sort((a, b) =>
            (b['difficulty'] as int).compareTo(a['difficulty'] as int));
        break;
      case 'duration_asc':
        _filteredTests.sort(
            (a, b) => (a['duration'] as int).compareTo(b['duration'] as int));
        break;
      case 'duration_desc':
        _filteredTests.sort(
            (a, b) => (b['duration'] as int).compareTo(a['duration'] as int));
        break;
      case 'completion_status':
        _filteredTests.sort((a, b) {
          final aCompleted = a['isCompleted'] as bool;
          final bCompleted = b['isCompleted'] as bool;
          if (aCompleted == bCompleted) {
            final aAttempts = a['attemptCount'] as int;
            final bAttempts = b['attemptCount'] as int;
            return aAttempts.compareTo(bAttempts);
          }
          return aCompleted ? 1 : -1;
        });
        break;
      case 'best_score':
        _filteredTests.sort((a, b) =>
            (b['bestScore'] as double).compareTo(a['bestScore'] as double));
        break;
    }
  }

  void _onSortChanged(String sortOption) {
    setState(() {
      _currentSortOption = sortOption;
      _applySorting();
    });
  }

  void _onRemoveFilter(String filterKey) {
    setState(() {
      _activeFilters.removeWhere(
          (filter) => '${filter['type']}:${filter['value']}' == filterKey);
      _applyFiltersAndSearch();
    });
  }

  Future<void> _onRefresh() async {
    setState(() {
      _isRefreshing = true;
    });

    // Recharger les tests depuis la base de données
    await _loadTestsFromDatabase();

    setState(() {
      _isRefreshing = false;
    });

    Fluttertoast.showToast(
      msg: "Tests mis à jour avec succès",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onTestTap(Map<String, dynamic> testData) {
    final bool isPremium = testData['isPremium'] ?? false;

    if (isPremium) {
      _showPremiumDialog(testData);
    } else {
      Navigator.pushNamed(context, '/test-taking-screen', arguments: testData);
    }
  }

  void _onStartTest(Map<String, dynamic> testData) {
    final bool isPremium = testData['isPremium'] ?? false;

    if (isPremium) {
      _showPremiumDialog(testData);
    } else {
      Navigator.pushNamed(context, '/test-taking-screen', arguments: testData);
    }
  }

  void _onDownloadTest(Map<String, dynamic> testData) {
    HapticFeedback.lightImpact();

    setState(() {
      final index =
          _allTests.indexWhere((test) => test['id'] == testData['id']);
      if (index != -1) {
        _allTests[index]['isDownloaded'] = true;
      }
      _applyFiltersAndSearch();
    });

    Fluttertoast.showToast(
      msg: "Test téléchargé pour utilisation hors ligne",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onFavoriteTest(Map<String, dynamic> testData) {
    HapticFeedback.lightImpact();

    Fluttertoast.showToast(
      msg: "Test ajouté aux favoris",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onRemoveTest(Map<String, dynamic> testData) {
    HapticFeedback.lightImpact();

    setState(() {
      final index =
          _allTests.indexWhere((test) => test['id'] == testData['id']);
      if (index != -1) {
        _allTests[index]['isDownloaded'] = false;
      }
      _applyFiltersAndSearch();
    });

    Fluttertoast.showToast(
      msg: "Test supprimé du stockage local",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onDeleteProgress(Map<String, dynamic> testData) {
    HapticFeedback.lightImpact();

    setState(() {
      final index =
          _allTests.indexWhere((test) => test['id'] == testData['id']);
      if (index != -1) {
        _allTests[index]['isCompleted'] = false;
        _allTests[index]['attemptCount'] = 0;
        _allTests[index]['bestScore'] = 0.0;
      }
      _applyFiltersAndSearch();
    });

    Fluttertoast.showToast(
      msg: "Progression du test réinitialisée",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onRandomTest() {
    final availableTests =
        _filteredTests.where((test) => !(test['isPremium'] ?? false)).toList();

    if (availableTests.isEmpty) {
      Fluttertoast.showToast(
        msg: "Aucun test disponible dans cette catégorie",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }

    final randomTest = availableTests[
        DateTime.now().millisecondsSinceEpoch % availableTests.length];
    Navigator.pushNamed(context, '/test-taking-screen', arguments: randomTest);
  }

  void _showPremiumDialog(Map<String, dynamic> testData) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            CustomIconWidget(
              iconName: 'lock',
              color: Colors.amber,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Test Premium',
              style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ce test nécessite un abonnement premium pour être accessible.',
              style: AppTheme.lightTheme.textTheme.bodyLarge,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'star',
                    color: Colors.amber,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Débloquez tous les tests premium pour seulement 2 500 XOF/mois',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.amber.shade700,
                        fontWeight: FontWeight.w500,
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
            onPressed: () => Navigator.pop(context),
            child: const Text('Plus tard'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Navigate to premium upgrade screen
            },
            child: const Text('Passer Premium'),
          ),
        ],
      ),
    );
  }

  void _onShareTest(Map<String, dynamic> testData) {
    Fluttertoast.showToast(
      msg: "Lien de partage copié dans le presse-papiers",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onReportTest(Map<String, dynamic> testData) {
    Fluttertoast.showToast(
      msg: "Problème signalé. Merci pour votre retour !",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onViewSolutions(Map<String, dynamic> testData) {
    Navigator.pushNamed(context, '/test-results-screen', arguments: {
      'testData': testData,
      'showSolutions': true,
    });
  }

  void _onLongPressTest(Map<String, dynamic> testData) {
    HapticFeedback.mediumImpact();

    ContextMenuWidget.show(
      context,
      testData: testData,
      onShare: () => _onShareTest(testData),
      onReport: () => _onReportTest(testData),
      onViewSolutions: () => _onViewSolutions(testData),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.lightTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_categoryTitle),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: CustomIconWidget(
              iconName: 'arrow_back',
              color: AppTheme.lightTheme.colorScheme.onSurface,
              size: 6.w,
            ),
          ),
        ),
        actions: [
          GestureDetector(
            onTap: () => SortBottomSheetWidget.show(
              context,
              currentSortOption: _currentSortOption,
              onSortChanged: _onSortChanged,
            ),
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: CustomIconWidget(
                iconName: 'sort',
                color: AppTheme.lightTheme.colorScheme.onSurface,
                size: 6.w,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        color: AppTheme.lightTheme.colorScheme.primary,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _isRefreshing 
                ? const Center(child: CircularProgressIndicator())
                : Column(
                    children: [
            // Search bar
            SearchBarWidget(
              hintText: 'Rechercher un test...',
              onChanged: _onSearchChanged,
              onClear: _onSearchClear,
              initialValue: _searchQuery,
            ),

            // Filter chips
            FilterChipsWidget(
              activeFilters: _activeFilters,
              onRemoveFilter: _onRemoveFilter,
            ),

            // Test list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredTests.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.only(bottom: 10.h),
                          itemCount: _filteredTests.length,
                          itemBuilder: (context, index) {
                            final testData = _filteredTests[index];
                            return GestureDetector(
                              onLongPress: () => _onLongPressTest(testData),
                              child: TestCardWidget(
                                testData: testData,
                                onTap: () => _onTestTap(testData),
                                onStartTest: () => _onStartTest(testData),
                                onDownload: () => _onDownloadTest(testData),
                                onFavorite: () => _onFavoriteTest(testData),
                                onRemove: () => _onRemoveTest(testData),
                                onDeleteProgress: () =>
                                    _onDeleteProgress(testData),
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _onRandomTest,
        icon: CustomIconWidget(
          iconName: 'shuffle',
          color: Colors.white,
          size: 5.w,
        ),
        label: const Text('Test Aléatoire'),
        backgroundColor: AppTheme.lightTheme.colorScheme.primary,
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchQuery.isNotEmpty) {
      return EmptyStateWidget(
        title: 'Aucun résultat trouvé',
        subtitle:
            'Aucun test ne correspond à votre recherche "$_searchQuery". Essayez avec d\'autres mots-clés.',
        iconName: 'search_off',
        actionText: 'Effacer la recherche',
        onAction: _onSearchClear,
      );
    } else if (_activeFilters.isNotEmpty) {
      return EmptyStateWidget(
        title: 'Aucun test trouvé',
        subtitle:
            'Aucun test ne correspond aux filtres appliqués. Essayez de modifier vos critères de recherche.',
        iconName: 'filter_list_off',
        actionText: 'Supprimer les filtres',
        onAction: () {
          setState(() {
            _activeFilters.clear();
            _applyFiltersAndSearch();
          });
        },
      );
    } else {
      return const EmptyStateWidget(
        title: 'Plus de tests bientôt !',
        subtitle:
            'Cette catégorie sera enrichie avec de nouveaux tests psychotechniques très prochainement. Revenez régulièrement pour découvrir les nouveautés.',
        iconName: 'upcoming',
      );
    }
  }
}
