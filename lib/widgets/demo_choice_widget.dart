import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../routes/app_routes.dart';
import '../services/user_state_service.dart';

class DemoChoiceWidget extends StatefulWidget {
  const DemoChoiceWidget({super.key});

  @override
  State<DemoChoiceWidget> createState() => _DemoChoiceWidgetState();

  static Future<void> show(BuildContext context) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const DemoChoiceWidget(),
    );
  }
}

class _DemoChoiceWidgetState extends State<DemoChoiceWidget> {
  final UserStateService _userStateService = UserStateService();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec style drawer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
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
                    'Choisissez votre mode d\'accès',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Container(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  // Option 1 : Activation Complète (style drawer)
                  _buildDrawerStyleOption(
                    context: context,
                    icon: Icons.verified,
                    title: 'Activation Complète',
                    subtitle: 'Accès à toutes les fonctionnalités',
                    color: Colors.green,
                    onTap: () async {
                      // Rediriger vers l'écran d'activation
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.activationScreen);
                      }
                    },
                  ),

                  SizedBox(height: 2.h),

                  // Séparateur
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      'OU',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Option 2 : Mode Démo (style drawer)
                  _buildDrawerStyleOption(
                    context: context,
                    icon: Icons.play_circle_outline,
                    title: 'Mode Démo',
                    subtitle: 'Découvrez avec limitations',
                    color: Colors.blue,
                    onTap: () async {
                      await _userStateService.recordDemoStartTime();
                      if (mounted) {
                        Navigator.pop(context);
                        Navigator.pushNamed(context, AppRoutes.examScreen);
                      }
                    },
                  ),

                  SizedBox(height: 3.h),

                  // Informations détaillées
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.blue.shade200,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: Colors.blue.shade600,
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Text(
                              'À propos du mode démo :',
                              style: TextStyle(
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        _buildInfoPoint('✅ Testez 40 questions complètes'),
                        _buildInfoPoint('✅ Résultats progressifs (1-10 d\'abord)'),
                        _buildInfoPoint('✅ Découvrez l\'interface complète'),
                        _buildInfoPoint('✅ Possibilité d\'activation ultérieure'),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Boutons d'action (style drawer)
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Plus tard',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () async {
                            await _userStateService.recordDemoStartTime();
                            if (mounted) {
                              Navigator.pop(context);
                              Navigator.pushNamed(context, AppRoutes.examScreen);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            'Commencer',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour créer une option avec le style du drawer
  Widget _buildDrawerStyleOption({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Row(
          children: [
            // Icône avec style drawer
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 6.w,
              ),
            ),

            SizedBox(width: 3.w),

            // Texte
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // Flèche
            Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey.shade400,
              size: 4.w,
            ),
          ],
        ),
      ),
    );
  }

  // Méthode pour créer un point d'information
  Widget _buildInfoPoint(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.blue.shade600,
        ),
      ),
    );
  }
}
