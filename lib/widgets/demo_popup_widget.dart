import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../services/demo_service.dart';

class DemoPopupWidget extends StatefulWidget {
  final VoidCallback onDemoCompleted;
  final VoidCallback onSkipDemo;

  const DemoPopupWidget({
    super.key,
    required this.onDemoCompleted,
    required this.onSkipDemo,
  });

  @override
  State<DemoPopupWidget> createState() => _DemoPopupWidgetState();

  static Future<void> show(
    BuildContext context,
    VoidCallback onDemoCompleted,
    VoidCallback onSkipDemo,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => DemoPopupWidget(
        onDemoCompleted: onDemoCompleted,
        onSkipDemo: onSkipDemo,
      ),
    );
  }
}

class _DemoPopupWidgetState extends State<DemoPopupWidget> {
  int _currentStep = 0;
  final List<DemoStepData> _steps = [
    DemoStepData(
      title: '🎯 Bienvenue sur PsychoTest+',
      description: 'Votre compagnon intelligent pour réussir vos concours de la douane béninoise.',
      icon: 'school',
      color: Colors.blue,
    ),
    DemoStepData(
      title: '📚 Bibliothèque de Tests',
      description: 'Accédez à des milliers de questions organisées par catégories : Logique, Calcul, Français, Spatial...',
      icon: 'library_books',
      color: Colors.green,
    ),
    DemoStepData(
      title: '⏱️ Tests Chronométrés',
      description: 'Entraînez-vous dans des conditions réelles avec notre système de timer intelligent.',
      icon: 'timer',
      color: Colors.orange,
    ),
    DemoStepData(
      title: '📊 Statistiques Détaillées',
      description: 'Suivez vos progrès avec des rapports complets et des recommandations personnalisées.',
      icon: 'analytics',
      color: Colors.purple,
    ),
    DemoStepData(
      title: '🎓 Simulations Complètes',
      description: 'Testez-vous avec des examens blancs identiques aux vrais concours.',
      icon: 'assignment',
      color: Colors.indigo,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStep];

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
                    'Découvrez PsychoTest+',
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
                  // Étape actuelle
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      color: currentStep.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: currentStep.color.withValues(alpha: 0.3),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        // Icône de l'étape
                        Container(
                          padding: EdgeInsets.all(2.w),
                          decoration: BoxDecoration(
                            color: currentStep.color.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getIconForStep(currentStep.icon),
                            color: currentStep.color,
                            size: 8.w,
                          ),
                        ),

                        SizedBox(height: 2.h),

                        // Titre de l'étape
                        Text(
                          currentStep.title,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: currentStep.color,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        SizedBox(height: 1.h),

                        // Description
                        Text(
                          currentStep.description,
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Indicateur de progression
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _steps.length,
                      (index) => Container(
                        margin: EdgeInsets.symmetric(horizontal: 1.w),
                        width: 3.w,
                        height: 3.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: index == _currentStep
                              ? currentStep.color
                              : Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 3.h),

                  // Boutons d'action (style drawer)
                  Row(
                    children: [
                      if (_currentStep > 0)
                        Expanded(
                          child: TextButton(
                            onPressed: _previousStep,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 2.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Précédent',
                              style: TextStyle(
                                fontSize: 14.sp,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ),
                        ),
                      if (_currentStep > 0) SizedBox(width: 2.w),

                      Expanded(
                        flex: 2,
                        child: ElevatedButton(
                          onPressed: _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: currentStep.color,
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(
                            _currentStep == _steps.length - 1 ? 'Commencer' : 'Suivant',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      if (_currentStep == 0) ...[
                        SizedBox(width: 2.w),
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                            widget.onSkipDemo();
                          },
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 2.h),
                          ),
                          child: Text(
                            'Passer',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
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

  IconData _getIconForStep(String iconName) {
    switch (iconName) {
      case 'school':
        return Icons.school;
      case 'library_books':
        return Icons.library_books;
      case 'timer':
        return Icons.timer;
      case 'analytics':
        return Icons.analytics;
      case 'assignment':
        return Icons.assignment;
      default:
        return Icons.info;
    }
  }

  void _nextStep() {
    if (_currentStep < _steps.length - 1) {
      setState(() {
        _currentStep++;
      });
    } else {
      // Démo terminée
      Navigator.pop(context);
      widget.onDemoCompleted();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }
}

class DemoStepData {
  final String title;
  final String description;
  final String icon;
  final Color color;

  const DemoStepData({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
