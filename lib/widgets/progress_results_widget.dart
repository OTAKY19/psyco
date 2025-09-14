import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../services/user_state_service.dart';

class ProgressResultsWidget extends StatefulWidget {
  final List<Map<String, dynamic>> allResults;
  final int totalQuestions;
  final VoidCallback onActivatePressed;

  const ProgressResultsWidget({
    super.key,
    required this.allResults,
    required this.totalQuestions,
    required this.onActivatePressed,
  });

  @override
  State<ProgressResultsWidget> createState() => _ProgressResultsWidgetState();
}

class _ProgressResultsWidgetState extends State<ProgressResultsWidget> {
  final UserStateService _userStateService = UserStateService();
  late Timer _timer;
  int _visibleResultsCount = 10;
  bool _isActivated = false;
  bool _canRevealMore = false;

  @override
  void initState() {
    super.initState();
    _initializeResults();
    _startRevealTimer();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _initializeResults() async {
    final userState = await _userStateService.getUserState();
    setState(() {
      _isActivated = userState.isActivated;
      _visibleResultsCount = userState.visibleResultsCount;
      _canRevealMore = userState.canRevealMore;
    });
  }

  void _startRevealTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (mounted) {
        final canReveal = await _userStateService.canRevealMoreResults();
        if (canReveal && !_canRevealMore) {
          setState(() {
            _canRevealMore = true;
          });
        }
      }
    });
  }

  Future<void> _revealMoreResults() async {
    await _userStateService.revealMoreResults();
    final newCount = await _userStateService.getVisibleResultsCount();
    setState(() {
      _visibleResultsCount = newCount;
      _canRevealMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleResults = widget.allResults.take(_visibleResultsCount).toList();
    final hiddenResults = widget.allResults.skip(_visibleResultsCount).toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Header avec progression
          _buildProgressHeader(),

          SizedBox(height: 3.h),

          // Résultats visibles
          _buildVisibleResults(visibleResults),

          // Résultats masqués (si pas activé)
          if (hiddenResults.isNotEmpty && !_isActivated)
            _buildHiddenResults(hiddenResults),

          // Bouton révélation (si disponible)
          if (_canRevealMore && !_isActivated)
            _buildRevealButton(),

          // Bouton activation (si résultats masqués)
          if (hiddenResults.isNotEmpty && !_isActivated)
            _buildActivationButton(),

          // Espace supplémentaire pour le défilement
          SizedBox(height: 4.h),
        ],
      ),
    );
  }

  Widget _buildProgressHeader() {
    final progressPercentage = (_visibleResultsCount / widget.totalQuestions * 100).round();

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 3.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          children: [
            // Icône avec style drawer
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.lock_clock,
                color: Colors.white,
                size: 10.w,
              ),
            ),

            SizedBox(height: 2.h),

            // Titre avec style drawer
            Text(
              'Limite Tests Gratuits',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 1.h),

            // Sous-titre
            Text(
              'Résultats de l\'examen démo',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.9),
                fontSize: 12.sp,
              ),
            ),

            SizedBox(height: 3.h),

            // Barre de progression
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Questions visibles',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14.sp,
                        ),
                      ),
                      Text(
                        '$_visibleResultsCount/${widget.totalQuestions}',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: _visibleResultsCount / widget.totalQuestions,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '$progressPercentage% des résultats affichés',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVisibleResults(List<Map<String, dynamic>> visibleResults) {
    final correctAnswers = visibleResults.where((result) => result['isCorrect'] == true).length;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.shade200,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header des résultats visibles
          Row(
            children: [
              CustomIconWidget(
                iconName: 'check_circle',
                color: Colors.green.shade600,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions 1-${_visibleResultsCount} (Visibles)',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Score: $correctAnswers/${visibleResults.length} (${(correctAnswers / visibleResults.length * 100).round()}%)',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.green.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Liste des résultats détaillés
          ...visibleResults.asMap().entries.map((entry) {
            final index = entry.key;
            final result = entry.value;
            final questionNumber = index + 1;

            return Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: result['isCorrect'] ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    width: 6.w,
                    height: 6.w,
                    decoration: BoxDecoration(
                      color: result['isCorrect'] ? Colors.green.shade500 : Colors.red.shade500,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        questionNumber.toString(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Question $questionNumber',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          result['isCorrect'] ? '✅ Correct' : '❌ Incorrect',
                          style: AppTheme.lightTheme.textTheme.bodySmall?.copyWith(
                            color: result['isCorrect'] ? Colors.green.shade700 : Colors.red.shade700,
                          ),
                        ),
                      ],
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

  Widget _buildHiddenResults(List<Map<String, dynamic>> hiddenResults) {
    return Container(
      margin: EdgeInsets.only(top: 3.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header des résultats masqués
          Row(
            children: [
              CustomIconWidget(
                iconName: 'lock',
                color: Colors.grey.shade600,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Questions ${_visibleResultsCount + 1}-${widget.totalQuestions} (Masquées)',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${hiddenResults.length} questions supplémentaires',
                      style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Aperçu flouté des résultats
          Container(
            height: 20.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
            child: Stack(
              children: [
                // Contenu flouté simulé
                Container(
                  padding: EdgeInsets.all(2.w),
                  child: Column(
                    children: List.generate(
                      5,
                      (index) => Container(
                        margin: EdgeInsets.only(bottom: 1.h),
                        height: 3.h,
                        color: Colors.grey.shade200,
                      ),
                    ),
                  ),
                ),
                // Overlay de flou
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CustomIconWidget(
                          iconName: 'visibility_off',
                          color: Colors.grey.shade500,
                          size: 8.w,
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          'Résultats masqués',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Activez pour voir tous vos résultats',
                          style: AppTheme.lightTheme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealButton() {
    return Container(
      margin: EdgeInsets.only(top: 3.h),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _revealMoreResults,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade500,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'refresh',
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Révéler Plus de Résultats',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivationButton() {
    return Container(
      margin: EdgeInsets.only(top: 3.h),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: widget.onActivatePressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green.shade600,
          padding: EdgeInsets.symmetric(vertical: 2.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'star',
              color: Colors.white,
              size: 6.w,
            ),
            SizedBox(width: 2.w),
            Text(
              'Voir Tous les Résultats (Activer)',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
