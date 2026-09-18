import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../design/app_colors.dart';
import '../../design/app_text_styles.dart';
import '../../router/app_routes.dart';
import '../../services/app_logger.dart';
import '../../services/user_data_service.dart';
import '../../services/user_state_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _loadingController;

  late Animation<double> _logoScale;
  late Animation<double> _logoFade;
  late Animation<double> _textFade;
  late Animation<double> _loadingProgress;

  @override
  void initState() {
    super.initState();
    _logoController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _loadingController = AnimationController(
      duration: const Duration(milliseconds: 2400),
      vsync: this,
    );
    _setupAnimations();
    // _initializeApp utilise le context (precache + navigation) : on
    // attend la fin du premier frame pour ne pas appeler MediaQuery trop tôt.
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeApp());
  }

  void _setupAnimations() {
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Cubic(0.34, 1.56, 0.64, 1.0),
      ),
    );

    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );

    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    // Loading bar: 2-segment tween over 2400ms
    _loadingProgress = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.7).chain(
          CurveTween(curve: Curves.easeOutCubic),
        ),
        weight: 70,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.7, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 30,
      ),
    ]).animate(_loadingController);

    // Start animations
    _logoController.forward();
    _loadingController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      await _preloadCriticalAssets();
      await _initializeBasicServices();
      // Identité invité persistée avant tout (T3) : aucun compte requis.
      await UserStateService.ensureGuestUserId();

      // Wait for loading bar + small UX buffer
      await Future.delayed(const Duration(milliseconds: 2600));

      if (mounted) {
        _navigateToHome();
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
      if (mounted) {
        _navigateToHome();
      }
    }
  }

  Future<void> _preloadCriticalAssets() async {
    try {
      await precacheImage(
        const AssetImage('assets/images/psychotest_logo.png'),
        context,
      );
      AppLogger.init('Assets', 'Ressources critiques préchargées');
    } catch (e) {
      AppLogger.warning('Erreur lors du préchargement des assets: $e');
    }
  }

  Future<void> _initializeBasicServices() async {
    try {
      WidgetsFlutterBinding.ensureInitialized();
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      debugPrint('Services de base initialisés');
    } catch (e) {
      debugPrint('Erreur initialisation services de base: $e');
    }
  }

  void _navigateToHome() {
    if (!mounted) return;
    // First-run minimal (T3) : onboarding une seule fois, sinon accueil.
    unawaited(UserDataService().isOnboardingCompleted().then((seen) {
      if (!mounted) return;
      context.go(seen ? AppRoutes.home : AppRoutes.onboarding);
      AppLogger.navigation(
          'SplashScreen', seen ? 'HomeScreen' : 'OnboardingScreen');
    }).catchError((_) {
      if (!mounted) return null;
      context.go(AppRoutes.home);
      return null;
    }));
  }

  @override
  void dispose() {
    _logoController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primaryDark,
              ],
            ),
          ),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -size.height * 0.15,
                right: -size.width * 0.2,
                child: _buildDecorativeCircle(size.height * 0.5, 0.06),
              ),
              Positioned(
                bottom: -size.height * 0.2,
                left: -size.width * 0.15,
                child: _buildDecorativeCircle(size.height * 0.45, 0.04),
              ),

              // Main content
              SafeArea(
                child: Column(
                  children: [
                    const Spacer(flex: 3),

                    // Logo
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _logoFade.value,
                          child: Transform.scale(
                            scale: _logoScale.value,
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        width: size.width * 0.22,
                        height: size.width * 0.22,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          Icons.psychology_rounded,
                          color: Colors.white,
                          size: size.width * 0.12,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.035),

                    // Brand title
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFade.value,
                          child: child,
                        );
                      },
                      child: Text(
                        'PsychoTest+',
                        style: AppTextStyles.displayMedium.copyWith(
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    SizedBox(height: size.height * 0.012),

                    // Tagline
                    AnimatedBuilder(
                      animation: _logoController,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _textFade.value,
                          child: child,
                        );
                      },
                      child: Text(
                        'Tests Psychotechniques Professionnels',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.white.withValues(alpha: 0.85),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),

                    const Spacer(flex: 3),

                    // Loading bar + version
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.18,
                      ),
                      child: Column(
                        children: [
                          // Loading bar
                          AnimatedBuilder(
                            animation: _loadingProgress,
                            builder: (context, child) {
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(100),
                                child: SizedBox(
                                  height: 4,
                                  width: double.infinity,
                                  child: LinearProgressIndicator(
                                    value: _loadingProgress.value,
                                    backgroundColor: Colors.white
                                        .withValues(alpha: 0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: size.height * 0.025),

                          // Loading text
                          AnimatedBuilder(
                            animation: _loadingController,
                            builder: (context, child) {
                              final progress = _loadingController.value;
                              String text;
                              if (progress < 0.3) {
                                text = 'Chargement des ressources...';
                              } else if (progress < 0.7) {
                                text = 'Initialisation...';
                              } else {
                                text = 'Prêt !';
                              }
                              return Text(
                                text,
                                style: AppTextStyles.labelMedium.copyWith(
                                  color:
                                      Colors.white.withValues(alpha: 0.7),
                                ),
                              );
                            },
                          ),

                          SizedBox(height: size.height * 0.06),

                          // Version
                          Text(
                            'Version 1.0.0+1',
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: size.height * 0.05),
                  ],
                ),
              ),

              // Green gradient bottom scrim
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: size.height * 0.12,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.success.withValues(alpha: 0.3),
                        AppColors.success.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeCircle(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: opacity),
          width: 1.5,
        ),
      ),
    );
  }
}
