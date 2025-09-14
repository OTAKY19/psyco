import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../core/app_export.dart';
import '../../models/simulation_model.dart';
import '../../services/simulation_service.dart';
import '../simulation_screen/simulation_screen.dart';

class SimulationSelectionScreen extends StatefulWidget {
  final String userId;

  const SimulationSelectionScreen({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  State<SimulationSelectionScreen> createState() => _SimulationSelectionScreenState();
}

class _SimulationSelectionScreenState extends State<SimulationSelectionScreen> {
  final SimulationService _simulationService = SimulationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Simulations de Test'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.quiz,
                    size: 48,
                    color: Colors.white,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Simulations Officielles',
                    style: TextStyle(
                      fontSize: 24.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Testez vos connaissances avec nos simulations officielles du concours de la douane béninoise',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha:0.9),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            
            SizedBox(height: 24),
            
            // Simulation disponible
            Text(
              'Simulation Disponible',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Carte de simulation
            _buildSimulationCard(),
            
            SizedBox(height: 24),
            
            // Informations importantes
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.school,
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        SimulationService.defaultSimulation.title,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        SimulationService.defaultSimulation.description,
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 20),
            
            // Détails de la simulation
            _buildDetailRow(
              Icons.quiz,
              'Questions',
              '${SimulationService.defaultSimulation.totalQuestions} questions',
            ),
            
            _buildDetailRow(
              Icons.timer,
              'Durée totale',
              '${SimulationService.defaultSimulation.totalDuration.inMinutes} minutes',
            ),
            
            _buildDetailRow(
              Icons.schedule,
              'Temps par question',
              '${SimulationService.defaultSimulation.questionDuration.inSeconds} secondes',
            ),
            
            _buildDetailRow(
              Icons.category,
              'Catégories',
              '${SimulationService.defaultSimulation.categories.length} domaines',
            ),
            
            SizedBox(height: 20),
            
            // Catégories
            Text(
              'Domaines couverts:',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            
            SizedBox(height: 8),
            
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SimulationService.defaultSimulation.categories.map((category) {
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha:0.3),
                    ),
                  ),
                  child: Text(
                    _getCategoryDisplayName(category),
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                );
              }).toList(),
            ),
            
            SizedBox(height: 24),
            
            // Bouton de démarrage
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startSimulation,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.play_arrow, size: 20),
                          SizedBox(width: 8),
                          Text(
                            'Commencer la simulation',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.primary,
          ),
          SizedBox(width: 12),
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.sp,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha:0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.withValues(alpha:0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info, color: Colors.blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Informations importantes',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800],
                ),
              ),
            ],
          ),
          
          SizedBox(height: 12),
          
          _buildInfoItem('• Le test dure exactement 40 minutes'),
          _buildInfoItem('• Chaque question a un temps limité de 1 minute'),
          _buildInfoItem('• Aucun retour en arrière n\'est possible'),
          _buildInfoItem('• Les questions sont sélectionnées aléatoirement'),
          _buildInfoItem('• Assurez-vous d\'avoir une connexion stable'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          color: Colors.blue[700],
        ),
      ),
    );
  }

  String _getCategoryDisplayName(String category) {
    switch (category) {
      case 'culture_generale':
        return 'Culture Générale';
      case 'francais':
        return 'Français';
      case 'droit_douane':
        return 'Droit de la Douane';
      case 'mathematiques':
        return 'Mathématiques';
      case 'logique':
        return 'Logique';
      case 'ethique_personnalite':
        return 'Éthique & Personnalité';
      default:
        return category;
    }
  }

  Future<void> _startSimulation() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Vérifier la connexion et charger les questions
      await _simulationService.loadQuestions();
      
      if (mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => SimulationScreen(
              userId: widget.userId,
              simulation: SimulationService.defaultSimulation,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
