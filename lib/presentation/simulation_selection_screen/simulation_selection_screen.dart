import 'package:flutter/material.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../design/app_spacing.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../services/simulation_service.dart';
import '../simulation_screen/simulation_screen.dart';

class SimulationSelectionScreen extends StatefulWidget {
  final String userId;

  const SimulationSelectionScreen({
    super.key,
    required this.userId,
  });

  @override
  State<SimulationSelectionScreen> createState() => _SimulationSelectionScreenState();
}

class _SimulationSelectionScreenState extends State<SimulationSelectionScreen> {
  final SimulationService _simulationService = SimulationService();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(size),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeroBanner(size),
                    const SizedBox(height: AppSpacing.xxl),
                    Text(
                      'Simulation Disponible',
                      style: AppTextStyles.headlineMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _buildSimulationCard(size),
                    const SizedBox(height: AppSpacing.xxl),
                    _buildInfoSection(size),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Size size) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.lg,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        boxShadow: AppShadows.header,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceDim,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new,
                color: AppColors.textSecondary,
                size: 18,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              'Simulations de Test',
              style: AppTextStyles.headlineLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(Size size) {
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
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.onPrimary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadii.md),
            ),
            child: const Icon(
              Icons.quiz,
              size: 28,
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Simulations Officielles',
            style: AppTextStyles.headlineLarge.copyWith(
              color: AppColors.onPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Testez vos connaissances avec nos simulations officielles du concours de la douane béninoise',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onPrimary.withValues(alpha: 0.85),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimulationCard(Size size) {
    final sim = SimulationService.defaultSimulation;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.sm),
                      ),
                      child: const Icon(
                        Icons.school,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sim.title,
                            style: AppTextStyles.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            sim.description,
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.lg),

                // Details
                _buildDetailRow(
                  Icons.quiz_outlined,
                  'Questions',
                  '${sim.totalQuestions} questions',
                ),
                _buildDetailRow(
                  Icons.timer_outlined,
                  'Durée totale',
                  '${sim.totalDuration.inMinutes} minutes',
                ),
                _buildDetailRow(
                  Icons.schedule_outlined,
                  'Temps par question',
                  '${sim.questionDuration.inSeconds} secondes',
                ),
                _buildDetailRow(
                  Icons.category_outlined,
                  'Catégories',
                  '${sim.categories.length} domaines',
                ),

                const SizedBox(height: AppSpacing.lg),

                // Categories
                Text(
                  'Domaines couverts',
                  style: AppTextStyles.titleSmall.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: sim.categories.map((category) {
                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadii.badge),
                      ),
                      child: Text(
                        _getCategoryDisplayName(category),
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),

          // Start button
          Container(
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: AppColors.borderLight),
              ),
            ),
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startSimulation,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadii.button),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(AppColors.onPrimary),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.play_arrow_rounded, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            'Commencer la simulation',
                            style: AppTextStyles.buttonMedium.copyWith(
                              color: AppColors.onPrimary,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(Size size) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadii.card),
        border: Border.all(
          color: AppColors.primaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline,
                  color: AppColors.onPrimary,
                  size: 16,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Informations importantes',
                style: AppTextStyles.titleSmall.copyWith(
                  color: AppColors.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoItem('Le test dure exactement 40 minutes'),
          _buildInfoItem('Chaque question a un temps limité de 1 minute'),
          _buildInfoItem('Aucun retour en arrière n\'est possible'),
          _buildInfoItem('Les questions sont sélectionnées aléatoirement'),
          _buildInfoItem('Assurez-vous d\'avoir une connexion stable'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 7),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
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
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.sm),
            ),
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
