
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/user_data_service.dart';
import './widgets/goal_setting_widget.dart';
import './widgets/onboarding_step_widget.dart';
import './widgets/permission_request_widget.dart';
import './widgets/preferences_setup_widget.dart';
import './widgets/progress_indicator_widget.dart';

class IntegrationFlowScreen extends StatefulWidget {
  const IntegrationFlowScreen({super.key});

  @override
  State<IntegrationFlowScreen> createState() => _IntegrationFlowScreenState();
}

class _IntegrationFlowScreenState extends State<IntegrationFlowScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _fadeAnimationController;
  late AnimationController _slideAnimationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  int _currentStep = 0;
  bool _isAnimating = false;
  final Map<String, dynamic> _userPreferences = {};

  final List<Map<String, dynamic>> _onboardingSteps = [
    {
      'title': 'Bienvenue dans PsychoTest+',
      'subtitle': 'Votre compagnon d\'\u00e9tude pour les tests psychotechniques',
      'description':
          'Accédez à une bibliothèque complète de tests psychotechniques, suivez vos progrès et améliorez vos performances avec notre plateforme d\'apprentissage adaptative.',
      'illustration':
          'https://images.unsplash.com/photo-1434030216411-0b793f4b4173?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'welcome',
    },
    {
      'title': 'Bibliothèque de Tests',
      'subtitle': 'Des milliers de questions à votre disposition',
      'description':
          'Explorez nos tests organisés par catégories, niveaux de difficulté et sujets spécifiques pour une préparation ciblée.',
      'illustration':
          'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'feature',
    },
    {
      'title': 'Suivi de Progression',
      'subtitle': 'Analysez vos performances en temps réel',
      'description':
          'Visualisez vos statistiques détaillées, identifiez vos points forts et les domaines à améliorer grâce à nos graphiques interactifs.',
      'illustration':
          'https://images.unsplash.com/photo-1551288049-bebda4e38f71?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'feature',
    },
    {
      'title': 'Analytique de Performance',
      'subtitle': 'Intelligence artificielle pour votre réussite',
      'description':
          'Notre IA analyse vos réponses pour vous proposer des exercices personnalisés et optimiser votre temps d\'étude.',
      'illustration':
          'https://images.unsplash.com/photo-1560472354-b33ff0c44a43?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'feature',
    },
    {
      'title': 'Autorisations',
      'subtitle': 'Améliorez votre expérience d\'apprentissage',
      'description':
          'Activez les notifications pour recevoir des rappels d\'étude et des conseils personnalisés.',
      'illustration':
          'https://images.unsplash.com/photo-1611224923853-80b023f02d71?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'permissions',
    },
    {
      'title': 'Préférences d\'Étude',
      'subtitle': 'Personnalisez votre parcours d\'apprentissage',
      'description':
          'Sélectionnez vos catégories préférées et niveaux de difficulté pour une expérience sur mesure.',
      'illustration':
          'https://images.unsplash.com/photo-1454165804606-c3d57bc86b40?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'preferences',
    },
    {
      'title': 'Définir vos Objectifs',
      'subtitle': 'Fixez des objectifs hebdomadaires réalisables',
      'description':
          'Établissez vos cibles de tests par semaine et recevez des encouragements pour maintenir votre motivation.',
      'illustration':
          'https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'goals',
    },
    {
      'title': 'Synchronisation des Données',
      'subtitle': 'Vos progrès sauvegardés en sécurité',
      'description':
          'Bénéficiez de la synchronisation automatique avec le cloud et continuez votre apprentissage sur tous vos appareils.',
      'illustration':
          'https://images.unsplash.com/photo-1451187580459-43490279c0fa?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'sync',
    },
    {
      'title': 'Prêt à Commencer !',
      'subtitle': 'Votre tableau de bord vous attend',
      'description':
          'Découvrez maintenant votre tableau de bord personnalisé avec vos préférences appliquées et commencez votre parcours vers la réussite.',
      'illustration':
          'https://images.unsplash.com/photo-1553028826-f4804a6dba3b?ixlib=rb-4.0.3&auto=format&fit=crop&w=400&h=300',
      'type': 'completion',
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializePageController();

    // Add haptic feedback for premium feel
    HapticFeedback.lightImpact();
  }

  void _initializeAnimations() {
    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    // Start initial animation
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _initializePageController() {
    _pageController = PageController();
  }

  void _nextStep() {
    if (_isAnimating) return;

    try {
      HapticFeedback.selectionClick();

      if (_currentStep < _onboardingSteps.length - 1) {
        _animateToNextStep();
      } else {
        _completeOnboarding();
      }
    } catch (e) {
      debugPrint('Erreur lors du passage à l\'étape suivante: $e');
      // Réinitialiser l'état d'animation en cas d'erreur
      setState(() {
        _isAnimating = false;
      });
    }
  }

  void _previousStep() {
    if (_isAnimating || _currentStep <= 0) return;

    HapticFeedback.selectionClick();
    _animateToPreviousStep();
  }

  void _animateToNextStep() {
    try {
      setState(() => _isAnimating = true);

      _fadeAnimationController.reverse().then((_) {
        setState(() {
          _currentStep++;
        });

        _pageController
            .animateToPage(
          _currentStep,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        )
            .then((_) {
          _fadeAnimationController.forward();
          _slideAnimationController.reset();
          _slideAnimationController.forward();
          setState(() => _isAnimating = false);
        }).catchError((error) {
          debugPrint('Erreur lors de l\'animation vers l\'étape suivante: $error');
          setState(() => _isAnimating = false);
        });
      }).catchError((error) {
        debugPrint('Erreur lors de l\'animation de fade: $error');
        setState(() => _isAnimating = false);
      });
    } catch (e) {
      debugPrint('Erreur dans _animateToNextStep: $e');
      setState(() => _isAnimating = false);
    }
  }

  void _animateToPreviousStep() {
    setState(() => _isAnimating = true);

    _fadeAnimationController.reverse().then((_) {
      setState(() {
        _currentStep--;
      });

      _pageController
          .animateToPage(
        _currentStep,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      )
          .then((_) {
        _fadeAnimationController.forward();
        _slideAnimationController.reset();
        _slideAnimationController.forward();
        setState(() => _isAnimating = false);
      });
    });
  }

  void _skipOnboarding() {
    HapticFeedback.lightImpact();

    // Show skip confirmation
    _showSkipConfirmationDialog();
  }

  void _showSkipConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Passer l\'intégration ?'),
        content: const Text(
          'Voulez-vous vraiment passer cette introduction ? Vous pourrez toujours y accéder plus tard depuis les paramètres.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _completeOnboarding();
            },
            child: const Text('Passer'),
          ),
        ],
      ),
    );
  }

  Future<void> _completeOnboarding() async {
    HapticFeedback.mediumImpact();

    // Save completion status and user preferences
    await _saveOnboardingCompletion();

    // Navigate to main dashboard
    Navigator.pushReplacementNamed(
      context,
      AppRoutes.testLibraryDashboard,
      arguments: _userPreferences,
    );
  }

  Future<void> _saveOnboardingCompletion() async {
    try {
      final userDataService = UserDataService();
      
      // Sauvegarder l'état d'onboarding terminé
      await userDataService.completeOnboarding();
      
      // Sauvegarder les préférences utilisateur
      if (_userPreferences.isNotEmpty) {
        await userDataService.saveUserPreferences(_userPreferences);
      }
      
      debugPrint('Onboarding completed with preferences: $_userPreferences');
    } catch (e) {
      debugPrint('Error saving onboarding completion: $e');
    }
  }

  void _updateUserPreferences(String key, dynamic value) {
    setState(() {
      _userPreferences[key] = value;
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeAnimationController.dispose();
    _slideAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastStep = _currentStep == _onboardingSteps.length - 1;
    final isFirstStep = _currentStep == 0;

    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.03),
              Theme.of(context).colorScheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with progress and skip button
              _buildHeader(isLastStep),

              // Main content area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const ClampingScrollPhysics(), // Permet le scroll
                  itemCount: _onboardingSteps.length,
                  onPageChanged: (index) {
                    setState(() {
                      _currentStep = index;
                    });
                  },
                  itemBuilder: (context, index) {
                    final stepData = _onboardingSteps[index];
                    return AnimatedBuilder(
                      animation: _fadeAnimation,
                      builder: (context, child) {
                        return FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: SingleChildScrollView(
                              padding: EdgeInsets.symmetric(
                                horizontal: 4.w,
                                vertical: 2.h,
                              ),
                              child: _buildStepContent(stepData),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Bottom navigation buttons
              _buildBottomNavigation(isFirstStep, isLastStep),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isLastStep) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Progress indicator
          Expanded(
            child: IntegrationProgressIndicatorWidget(
              currentStep: _currentStep,
              totalSteps: _onboardingSteps.length,
            ),
          ),

          SizedBox(width: 4.w),

          // Skip button (hidden on last step)
          if (!isLastStep)
            TextButton(
              onPressed: _skipOnboarding,
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.7),
              ),
              child: Text(
                'Passer',
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepContent(Map<String, dynamic> stepData) {
    try {
      switch (stepData['type']) {
        case 'permissions':
          return IntegrationPermissionRequestWidget(
            title: stepData['title'],
            subtitle: stepData['subtitle'],
            description: stepData['description'],
            illustration: stepData['illustration'],
            onPermissionResult: (granted) {
              _updateUserPreferences('notificationsEnabled', granted);
            },
          );

        case 'preferences':
          return IntegrationPreferencesSetupWidget(
            title: stepData['title'],
            subtitle: stepData['subtitle'],
            description: stepData['description'],
            illustration: stepData['illustration'],
            onPreferencesChanged: (preferences) {
              _updateUserPreferences('studyPreferences', preferences);
            },
          );

        case 'goals':
          return IntegrationGoalSettingWidget(
            title: stepData['title'],
            subtitle: stepData['subtitle'],
            description: stepData['description'],
            illustration: stepData['illustration'],
            onGoalSet: (goal) {
              _updateUserPreferences('weeklyGoal', goal);
            },
          );

        default:
          return IntegrationOnboardingStepWidget(
            title: stepData['title'],
            subtitle: stepData['subtitle'],
            description: stepData['description'],
            illustration: stepData['illustration'],
            isCompletion: stepData['type'] == 'completion',
            userPreferences:
                stepData['type'] == 'completion' ? _userPreferences : null,
          );
      }
    } catch (e) {
      // Gestion d'erreur pour les étapes qui ne se chargent pas
      return Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 15.w,
              color: Theme.of(context).colorScheme.error,
            ),
            SizedBox(height: 2.h),
            Text(
              'Erreur de chargement',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Impossible de charger cette étape. Veuillez réessayer.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  // Forcer le rechargement de l'étape
                });
              },
              child: Text('Réessayer'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildBottomNavigation(bool isFirstStep, bool isLastStep) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
      child: Row(
        children: [
          // Previous button
          if (!isFirstStep)
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _isAnimating ? null : _previousStep,
                icon: const Icon(Icons.arrow_back_ios, size: 18),
                label: const Text('Précédent'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.5.h),
                ),
              ),
            ),

          if (!isFirstStep) SizedBox(width: 4.w),

          // Next/Complete button
          Expanded(
            flex: isFirstStep ? 1 : 1,
            child: ElevatedButton(
              onPressed: _isAnimating ? null : _nextStep,
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                backgroundColor: isLastStep
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.primary,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isLastStep ? 'Commencer' : 'Suivant',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  SizedBox(width: 2.w),
                  Icon(
                    isLastStep ? Icons.rocket_launch : Icons.arrow_forward_ios,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
