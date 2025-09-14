import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class TestCategoryCardWidget extends StatelessWidget {
  final Map<String, dynamic> category;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const TestCategoryCardWidget({
    super.key,
    required this.category,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final completionPercentage =
        (category['completionPercentage'] as num).toDouble();
    final testCount = category['testCount'] as int;
    final isCompleted = completionPercentage >= 100;
    final hasStarted = completionPercentage > 0;
    final isPremium = category['isPremium'] == true && category['isUnlocked'] != true;

    return Container(
      margin: EdgeInsets.only(bottom: 4.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _getStatusColor().withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: EdgeInsets.all(5.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  _getStatusColor().withValues(alpha: 0.02),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _getStatusColor().withValues(alpha: 0.1),
                width: 1.5,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // En-tête avec icône et titre
                Row(
                  children: [
                    // Icône avec gradient
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _getStatusColor().withValues(alpha: 0.8),
                            _getStatusColor().withValues(alpha: 0.6),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: _getStatusColor().withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: CustomIconWidget(
                        iconName: category['iconName'] as String,
                        color: Colors.white,
                        size: 7.w,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            category['name'] as String,
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                              letterSpacing: 0.5,
                            ),
                          ),
                          SizedBox(height: 1.w),
                          Text(
                            category['description'] as String,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w400,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Badge de statut
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 2.5.w, vertical: 1.w),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _getStatusColor().withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        isCompleted ? 'Terminé' :
                        hasStarted ? 'En cours' : 'Nouveau',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: _getStatusColor(),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 4.w),

                // Barre de progression améliorée
                Container(
                  padding: EdgeInsets.all(3.w),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.grey[200]!,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Progression',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            '${completionPercentage.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 12.sp,
                              fontWeight: FontWeight.w700,
                              color: _getProgressColor(completionPercentage),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 2.w),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: completionPercentage / 100,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _getProgressColor(completionPercentage),
                          ),
                          minHeight: 1.w,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 4.w),

                // Chips d'information améliorés
                Wrap(
                  spacing: 2.w,
                  runSpacing: 2.w,
                  children: [
                    _buildModernInfoChip(
                      Icons.quiz,
                      '$testCount tests',
                      Colors.blue,
                    ),
                    if (category['difficulty'] != null)
                      _buildModernInfoChip(
                        Icons.speed,
                        category['difficulty'] as String,
                        _getDifficultyColor(category['difficulty'] as String),
                      ),
                    if (isPremium)
                      _buildModernInfoChip(
                        Icons.lock,
                        'Premium',
                        Colors.orange,
                      ),
                  ],
                ),

                SizedBox(height: 4.w),

                // Bouton d'action amélioré
                Container(
                  width: double.infinity,
                  height: 12.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _getStatusColor(),
                        _getStatusColor().withValues(alpha: 0.8),
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _getStatusColor().withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: onTap,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          isCompleted ? Icons.refresh :
                          hasStarted ? Icons.play_arrow : Icons.explore,
                          size: 5.w,
                          color: Colors.white,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          isCompleted ? 'Réviser' :
                          hasStarted ? 'Continuer' : 'Explorer',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModernInfoChip(IconData icon, String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.1),
            color.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.w, color: color),
          SizedBox(width: 1.5.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor() {
    final completionPercentage =
        (category['completionPercentage'] as num).toDouble();

    if (completionPercentage >= 100) return Colors.green;
    if (completionPercentage > 0) return Colors.blue;
    return Colors.blue;
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 60) return Colors.orange;
    if (percentage > 0) return Colors.blue;
    return Colors.grey;
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'facile':
        return Colors.green;
      case 'moyen':
        return Colors.orange;
      case 'difficile':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }
}
