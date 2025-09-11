import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/user_data_service.dart';
import './widgets/context_menu_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/sort_bottom_sheet_widget.dart';
import './widgets/test_card_widget.dart';

class TestCategoryScreen extends StatefulWidget {
  const TestCategoryScreen({Key? key}) : super(key: key);

  @override
  State<TestCategoryScreen> createState() => _TestCategoryScreenState();
}

class _TestCategoryScreenState extends State<TestCategoryScreen> {
  String _searchQuery = '';
  String _currentSortOption = 'alphabetical';
  List<Map<String, dynamic>> _activeFilters = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String _categoryTitle = 'Tests Psychotechniques';

  // Mock test data
  final List<Map<String, dynamic>> _allTests = [
    {
      "id": 1,
      "title": "Test de Logique Verbale",
      "description":
          "Évaluation des capacités de raisonnement verbal et de compréhension linguistique",
      "difficulty": 3,
      "duration": 45,
      "iconName": "psychology",
      "isPremium": false,
      "isDownloaded": true,
      "isCompleted": true,
      "attemptCount": 2,
      "bestScore": 85.5,
      "category": "Logique",
      "questionCount": 30,
      "type": "Verbal"
    },
    {
      "id": 2,
      "title": "Test de Raisonnement Numérique",
      "description":
          "Évaluation des compétences mathématiques et de calcul mental",
      "difficulty": 4,
      "duration": 60,
      "iconName": "calculate",
      "isPremium": true,
      "isDownloaded": false,
      "isCompleted": false,
      "attemptCount": 0,
      "bestScore": 0.0,
      "category": "Mathématiques",
      "questionCount": 25,
      "type": "Numérique"
    },
    {
      "id": 3,
      "title": "Test de Perception Spatiale",
      "description":
          "Évaluation de la capacité à visualiser et manipuler des objets dans l'espace",
      "difficulty": 2,
      "duration": 30,
      "iconName": "view_in_ar",
      "isPremium": false,
      "isDownloaded": true,
      "isCompleted": false,
      "attemptCount": 1,
      "bestScore": 72.0,
      "category": "Spatial",
      "questionCount": 20,
      "type": "Visuel"
    },
    {
      "id": 4,
      "title": "Test de Mémoire de Travail",
      "description":
          "Évaluation de la capacité à retenir et manipuler l'information temporairement",
      "difficulty": 3,
      "duration": 40,
      "iconName": "memory",
      "isPremium": false,
      "isDownloaded": false,
      "isCompleted": true,
      "attemptCount": 3,
      "bestScore": 91.2,
      "category": "Mémoire",
      "questionCount": 35,
      "type": "Cognitif"
    },
    {
      "id": 5,
      "title": "Test d'Attention Soutenue",
      "description":
          "Évaluation de la capacité à maintenir l'attention sur une période prolongée",
      "difficulty": 1,
      "duration": 25,
      "iconName": "visibility",
      "isPremium": true,
      "isDownloaded": false,
      "isCompleted": false,
      "attemptCount": 0,
      "bestScore": 0.0,
      "category": "Attention",
      "questionCount": 40,
      "type": "Cognitif"
    },
    {
      "id": 6,
      "title": "Test de Flexibilité Cognitive",
      "description":
          "Évaluation de la capacité à s'adapter aux changements de règles",
      "difficulty": 5,
      "duration": 50,
      "iconName": "psychology_alt",
      "isPremium": true,
      "isDownloaded": true,
      "isCompleted": false,
      "attemptCount": 1,
      "bestScore": 68.7,
      "category": "Flexibilité",
      "questionCount": 28,
      "type": "Exécutif"
    }
  ];

  List<Map<String, dynamic>> _filteredTests = [];

  @override
  void initState() {
    super.initState();
    _filteredTests = List.from(_allTests);
    _applySorting();
  }

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

    // Simulate network refresh
    await Future.delayed(const Duration(seconds: 2));

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
        child: Column(
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
