import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/test_service.dart';
import '../models/test_session.dart';
import 'package:intl/intl.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  List<TestResult> _allResults = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadTestHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTestHistory() async {
    setState(() => _isLoading = true);
    
    try {
      final testService = Provider.of<TestService>(context, listen: false);
      final results = await testService.getTestHistory();
      
      setState(() {
        _allResults = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du chargement de l\'historique: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  List<TestResult> get _recentResults {
    final now = DateTime.now();
    final lastWeek = now.subtract(const Duration(days: 7));
    return _allResults.where((result) => 
      result.endTime?.isAfter(lastWeek) ?? false).toList();
  }

  List<TestResult> get _completedResults {
    return _allResults.where((result) => result.isCompleted).toList();
  }

  Map<String, List<TestResult>> get _resultsByCategory {
    final Map<String, List<TestResult>> grouped = {};
    for (final result in _completedResults) {
      final category = result.testType;
      grouped[category] = (grouped[category] ?? [])..add(result);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique des tests'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Récents', icon: Icon(Icons.schedule)),
            Tab(text: 'Tous', icon: Icon(Icons.list)),
            Tab(text: 'Statistiques', icon: Icon(Icons.analytics)),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildRecentTab(),
                _buildAllTestsTab(),
                _buildStatsTab(),
              ],
            ),
    );
  }

  Widget _buildRecentTab() {
    if (_recentResults.isEmpty) {
      return _buildEmptyState(
        'Aucun test récent',
        'Vous n\'avez fait aucun test cette semaine',
        Icons.schedule,
      );
    }

    return RefreshIndicator(
      onRefresh: _loadTestHistory,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _recentResults.length,
        itemBuilder: (context, index) {
          return _buildTestResultCard(_recentResults[index]);
        },
      ),
    );
  }

  Widget _buildAllTestsTab() {
    if (_allResults.isEmpty) {
      return _buildEmptyState(
        'Aucun historique',
        'Commencez votre premier test pour voir vos résultats ici',
        Icons.history,
      );
    }

    return Column(
      children: [
        // Résumé rapide
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildQuickStat('Tests', _allResults.length.toString(), Icons.quiz),
              _buildQuickStat(
                'Complétés', 
                _completedResults.length.toString(), 
                Icons.check_circle,
              ),
              _buildQuickStat(
                'Score moyen',
                '${_getAverageScore().toStringAsFixed(1)}%',
                Icons.trending_up,
              ),
            ],
          ),
        ),
        
        // Liste des tests
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadTestHistory,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _allResults.length,
              itemBuilder: (context, index) {
                return _buildTestResultCard(_allResults[index]);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    if (_completedResults.isEmpty) {
      return _buildEmptyState(
        'Pas encore de statistiques',
        'Complétez quelques tests pour voir vos statistiques',
        Icons.analytics,
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vue d'ensemble
          _buildOverviewStats(),
          
          const SizedBox(height: 24),
          
          // Performance par catégorie
          _buildCategoryPerformance(),
          
          const SizedBox(height: 24),
          
          // Évolution temporelle
          _buildTimelineStats(),
          
          const SizedBox(height: 24),
          
          // Records personnels
          _buildPersonalRecords(),
        ],
      ),
    );
  }

  Widget _buildTestResultCard(TestResult result) {
    final theme = Theme.of(context);
    final isCompleted = result.isCompleted;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showTestDetails(result),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getTestIcon(result.testType),
                      color: isCompleted ? Colors.green : Colors.orange,
                      size: 20,
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getTestTypeLabel(result.testType),
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _formatDate(result.startTime),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Badge de statut
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isCompleted 
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      isCompleted ? 'Terminé' : 'En cours',
                      style: TextStyle(
                        color: isCompleted ? Colors.green : Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              
              if (isCompleted) ...[
                const SizedBox(height: 12),
                
                // Statistiques
                Row(
                  children: [
                    Expanded(
                      child: _buildResultStat(
                        'Score',
                        '${result.score.toStringAsFixed(1)}%',
                        Icons.grade,
                        _getScoreColor(result.score),
                      ),
                    ),
                    Expanded(
                      child: _buildResultStat(
                        'Questions',
                        '${result.correctAnswers}/${result.totalQuestions}',
                        Icons.help_outline,
                        Colors.blue,
                      ),
                    ),
                    Expanded(
                      child: _buildResultStat(
                        'Durée',
                        _formatDuration(result.duration),
                        Icons.timer,
                        Colors.purple,
                      ),
                    ),
                  ],
                ),
              ] else ...[
                const SizedBox(height: 12),
                
                // Progression pour tests en cours
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Progression: ${result.currentQuestionIndex + 1}/${result.totalQuestions}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: (result.currentQuestionIndex + 1) / result.totalQuestions,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultStat(String label, String value, IconData icon, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.9),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewStats() {
    final theme = Theme.of(context);
    final avgScore = _getAverageScore();
    final totalTime = _getTotalStudyTime();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vue d\'ensemble',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Score moyen',
                    '${avgScore.toStringAsFixed(1)}%',
                    Icons.trending_up,
                    _getScoreColor(avgScore),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Temps total',
                    _formatDuration(totalTime),
                    Icons.access_time,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Taux de réussite',
                    '${_getSuccessRate().toStringAsFixed(1)}%',
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Meilleur score',
                    '${_getBestScore().toStringAsFixed(1)}%',
                    Icons.star,
                    Colors.amber,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryPerformance() {
    final theme = Theme.of(context);
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance par catégorie',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            ..._resultsByCategory.entries.map((entry) {
              final category = entry.key;
              final results = entry.value;
              final avgScore = results.fold<double>(0, (sum, r) => sum + r.score) / results.length;
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Icon(_getTestIcon(category), size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _getTestTypeLabel(category),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '${results.length} test(s)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${avgScore.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getScoreColor(avgScore),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStats() {
    final theme = Theme.of(context);
    final recentScores = _getRecentScores();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Évolution récente',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (recentScores.length >= 2) ...[
              Text(
                'Tendance: ${_getTrend(recentScores)}',
                style: TextStyle(
                  color: _getTrendColor(recentScores),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
            ],
            
            Text(
              'Derniers scores: ${recentScores.take(5).map((s) => "${s.toStringAsFixed(0)}%").join(", ")}',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalRecords() {
    final theme = Theme.of(context);
    final bestResult = _getBestResult();
    final fastestResult = _getFastestResult();
    
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Records personnels',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            if (bestResult != null) ...[
              ListTile(
                leading: Icon(Icons.star, color: Colors.amber),
                title: Text('Meilleur score'),
                subtitle: Text('${bestResult.score.toStringAsFixed(1)}% • ${_getTestTypeLabel(bestResult.testType)}'),
                trailing: Text(_formatDate(bestResult.startTime)),
              ),
            ],
            
            if (fastestResult != null) ...[
              ListTile(
                leading: Icon(Icons.speed, color: Colors.blue),
                title: Text('Plus rapide'),
                subtitle: Text('${_formatDuration(fastestResult.duration)} • ${_getTestTypeLabel(fastestResult.testType)}'),
                trailing: Text(_formatDate(fastestResult.startTime)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showTestDetails(TestResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(_getTestTypeLabel(result.testType)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Statut', result.isCompleted ? 'Terminé' : 'En cours'),
              _buildDetailRow('Date', _formatDate(result.startTime)),
              if (result.isCompleted) ...[
                _buildDetailRow('Score', '${result.score.toStringAsFixed(1)}%'),
                _buildDetailRow('Questions correctes', '${result.correctAnswers}/${result.totalQuestions}'),
                _buildDetailRow('Durée', _formatDuration(result.duration)),
                _buildDetailRow('Taux de réussite', '${((result.correctAnswers / result.totalQuestions) * 100).toStringAsFixed(1)}%'),
              ] else ...[
                _buildDetailRow('Progression', '${result.currentQuestionIndex + 1}/${result.totalQuestions}'),
              ],
              if (result.categories.isNotEmpty) ...[
                const SizedBox(height: 8),
                const Text('Catégories:', style: TextStyle(fontWeight: FontWeight.bold)),
                ...result.categories.map((cat) => Text('• $cat')),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }

  // Méthodes utilitaires
  
  IconData _getTestIcon(String testType) {
    switch (testType.toLowerCase()) {
      case 'mixte': return Icons.shuffle;
      case 'raisonnement logique': return Icons.psychology;
      case 'aptitude numérique': return Icons.calculate;
      case 'aptitude verbale': return Icons.text_fields;
      case 'aptitude spatiale': return Icons.view_in_ar;
      case 'mémoire': return Icons.memory;
      case 'rapidité': return Icons.speed;
      default: return Icons.quiz;
    }
  }

  String _getTestTypeLabel(String testType) {
    return testType.isEmpty ? 'Test général' : testType;
  }

  String _formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy à HH:mm').format(date);
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes}m ${seconds}s';
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  double _getAverageScore() {
    if (_completedResults.isEmpty) return 0;
    return _completedResults.fold<double>(0, (sum, r) => sum + r.score) / _completedResults.length;
  }

  double _getSuccessRate() {
    if (_completedResults.isEmpty) return 0;
    final passed = _completedResults.where((r) => r.score >= 60).length;
    return (passed / _completedResults.length) * 100;
  }

  double _getBestScore() {
    if (_completedResults.isEmpty) return 0;
    return _completedResults.map((r) => r.score).reduce((a, b) => a > b ? a : b);
  }

  TestResult? _getBestResult() {
    if (_completedResults.isEmpty) return null;
    return _completedResults.reduce((a, b) => a.score > b.score ? a : b);
  }

  TestResult? _getFastestResult() {
    if (_completedResults.isEmpty) return null;
    return _completedResults.reduce((a, b) => a.duration < b.duration ? a : b);
  }

  Duration _getTotalStudyTime() {
    return _completedResults.fold(Duration.zero, (sum, r) => sum + r.duration);
  }

  List<double> _getRecentScores() {
    final sorted = _completedResults..sort((a, b) => b.startTime.compareTo(a.startTime));
    return sorted.take(10).map((r) => r.score).toList();
  }

  String _getTrend(List<double> scores) {
    if (scores.length < 2) return 'Pas assez de données';
    final recent = scores.take(3).fold<double>(0, (sum, s) => sum + s) / 3;
    final older = scores.skip(3).take(3).fold<double>(0, (sum, s) => sum + s) / 3;
    
    if (recent > older + 2) return '📈 En progression';
    if (recent < older - 2) return '📉 En baisse';
    return '➡️ Stable';
  }

  Color _getTrendColor(List<double> scores) {
    final trend = _getTrend(scores);
    if (trend.contains('progression')) return Colors.green;
    if (trend.contains('baisse')) return Colors.red;
    return Colors.blue;
  }
}
