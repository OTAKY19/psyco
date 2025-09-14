import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart'; // Importation ajoutée
import '../../services/exam_blanc_service.dart';
import '../../services/admin_service.dart';
import '../../services/user_state_service.dart'; // Importation ajoutée
import '../../services/one_time_purchase_service.dart'; // Importation ajoutée
import '../../routes/app_routes.dart'; // Importation ajoutée
import 'widgets/result_summary_widget.dart';
import 'widgets/result_details_widget.dart';
// import 'widgets/activation_prompt_widget.dart'; // Supprimé

class ExamResultsScreen extends StatefulWidget {
  final ExamBlancResult result;
  // final bool isPremium; // Supprimé
  // final VoidCallback onActivate; // Supprimé

  const ExamResultsScreen({
    super.key,
    required this.result,
    // required this.isPremium, // Supprimé
    // required this.onActivate, // Supprimé
  });

  @override
  State<ExamResultsScreen> createState() => _ExamResultsScreenState();
}

class _ExamResultsScreenState extends State<ExamResultsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Résultats de l\'examen'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showShareDialog(),
            icon: Icon(Icons.share),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Column(
          children: [
            // Résumé des résultats
            ResultSummaryWidget(
              result: widget.result,
            ),
            
            // Onglets
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                tabs: [
                  Tab(
                    icon: Icon(Icons.assessment),
                    text: 'Résumé',
                  ),
                  Tab(
                    icon: Icon(Icons.quiz),
                    text: 'Détails',
                  ),
                ],
              ),
            ),
            
            // Contenu des onglets
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildSummaryTab(),
                  _buildDetailsTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          // Statistiques détaillées
          _buildStatsCard(),
          
          SizedBox(height: 16),
          
          // Performance par catégorie
          _buildCategoryPerformance(),
          
          SizedBox(height: 16),
          
          // Recommandations
          _buildRecommendations(),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return Consumer<UserStateService>(
      builder: (context, userState, _) {
        final hasLifetimeAccess = userState.hasLifetimeAccess;
        return FutureBuilder<bool>(
          future: AdminService().isAdminModeEnabled(),
          builder: (context, snapshot) {
            final isAdminMode = snapshot.data ?? false;
            
            if (!hasLifetimeAccess && !isAdminMode) {
              return Column(
                children: [
                  // Résultats des 15 premières questions (simulation)
                  // PartialResultsWidget(results: examResults.take(15).toList()), // Ceci est un exemple, à adapter
                  
                  // Section bloquée avec call-to-action
                  Container(
                    padding: EdgeInsets.all(20),
                    margin: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.lock, size: 48, color: Colors.grey[600]),
                        SizedBox(height: 16),
                        Text("25 questions supplémentaires disponibles",
                             style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text("Débloquez l'accès complet pour voir tous vos résultats détaillés",
                             style: TextStyle(color: Colors.grey[600])),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => Navigator.pushNamed(context, AppRoutes.activationScreen),
                          child: Text("Débloquer pour ${OneTimePurchaseService.FULL_ACCESS_PRICE} FCFA"),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }
            
            return ResultDetailsWidget(
              result: widget.result,
              isAdminMode: isAdminMode,
            );
          },
        );
      },
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistiques détaillées',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Réponses correctes',
                    '${widget.result.correctAnswers}',
                    Colors.green,
                    Icons.check_circle,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Réponses incorrectes',
                    '${widget.result.incorrectAnswers}',
                    Colors.red,
                    Icons.cancel,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Questions sautées',
                    '${widget.result.skippedQuestions}',
                    Colors.orange,
                    Icons.skip_next,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Temps passé',
                    _formatDuration(widget.result.timeSpent),
                    Colors.blue,
                    Icons.timer,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    final categoryStats = _calculateCategoryStats();
    
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance par catégorie',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ...categoryStats.entries.map((entry) {
              final category = entry.key;
              final stats = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        _getCategoryLabel(category),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: LinearProgressIndicator(
                        value: stats['percentage'] / 100,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _getCategoryColor(category),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      '${stats['percentage'].toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildRecommendations() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recommandations',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            ..._getRecommendations().map((recommendation) {
              return Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      color: Colors.orange,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        recommendation,
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Map<String, Map<String, dynamic>> _calculateCategoryStats() {
    final Map<String, Map<String, dynamic>> stats = {};
    
    for (String key in widget.result.detailedResults.keys) {
      if (key.startsWith('question_')) {
        final questionData = widget.result.detailedResults[key] as Map<String, dynamic>;
        final category = questionData['category'] as String;
        final isCorrect = questionData['isCorrect'] as bool;
        
        if (!stats.containsKey(category)) {
          stats[category] = {'correct': 0, 'total': 0};
        }
        
        stats[category]!['total']++;
        if (isCorrect) {
          stats[category]!['correct']++;
        }
      }
    }
    
    // Calculer les pourcentages
    stats.forEach((category, data) {
      data['percentage'] = (data['correct'] / data['total']) * 100;
    });
    
    return stats;
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'culture_generale':
        return 'Culture Générale';
      case 'francais':
        return 'Français';
      case 'droit_douane':
        return 'Droit Douane';
      case 'mathematiques':
        return 'Mathématiques';
      case 'logique':
        return 'Logique';
      default:
        return category;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'culture_generale':
        return Colors.blue;
      case 'francais':
        return Colors.green;
      case 'droit_douane':
        return Colors.orange;
      case 'mathematiques':
        return Colors.purple;
      case 'logique':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  List<String> _getRecommendations() {
    final recommendations = <String>[];
    
    if (widget.result.scorePercentage < 50) {
      recommendations.add('Revoyez les bases dans toutes les catégories');
    } else if (widget.result.scorePercentage < 70) {
      recommendations.add('Concentrez-vous sur vos points faibles');
    } else if (widget.result.scorePercentage < 90) {
      recommendations.add('Excellent travail ! Peaufinez les détails');
    } else {
      recommendations.add('Performance exceptionnelle ! Vous êtes prêt');
    }
    
    if (widget.result.skippedQuestions > 5) {
      recommendations.add('Évitez de sauter trop de questions');
    }
    
    if (widget.result.timeSpent.inMinutes < 30) {
      recommendations.add('Prenez plus de temps pour lire les questions');
    }
    
    return recommendations;
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  void _showShareDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Partager le résultat'),
        content: Text('Fonctionnalité de partage à implémenter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }
}
