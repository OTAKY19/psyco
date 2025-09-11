import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoAnimationController;
  late AnimationController _progressAnimationController;
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _progressAnimation;

  int _progressPercentage = 0;
  Timer? _progressTimer;
  String? _deepLinkTarget;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startInitialization();

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Handle deep linking storage during loading
    _handleDeepLinking();
  }

  void _initializeAnimations() {
    // Logo animation controller
    _logoAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // Progress animation controller
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    // Logo scale animation with bounce effect
    _logoScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: Curves.elasticOut,
    ));

    // Logo opacity animation
    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoAnimationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeInOut),
    ));

    // Progress animation
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _handleDeepLinking() {
    // Store any deep link target for navigation after initialization
    final route = ModalRoute.of(context);
    if (route?.settings.arguments != null) {
      _deepLinkTarget = route!.settings.arguments as String?;
    }
  }

  void _startInitialization() {
    // Start logo animation immediately
    _logoAnimationController.forward();

    // Add haptic feedback for iOS and material motion for Android
    HapticFeedback.lightImpact();

    // Start progress animation after logo appears
    Timer(const Duration(milliseconds: 600), () {
      _progressAnimationController.forward();
      _startProgressUpdates();
    });

    // Navigate after initialization completes
    Timer(const Duration(milliseconds: 2800), () {
      _navigateToNextScreen();
    });
  }

  void _startProgressUpdates() {
    _progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (mounted) {
        setState(() {
          _progressPercentage = (_progressAnimation.value * 100).round();
        });

        if (_progressPercentage >= 100) {
          timer.cancel();
        }
      }
    });
  }

  void _navigateToNextScreen() {
    if (!mounted) return;

    // Navigate to deep link target or default login screen
    final targetRoute = _deepLinkTarget ?? AppRoutes.loginScreen;

    Navigator.pushReplacementNamed(context, targetRoute);
  }

  @override
  void dispose() {
    _logoAnimationController.dispose();
    _progressAnimationController.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: 100.w,
        height: 100.h,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
              Theme.of(context).colorScheme.secondary,
            ],
            stops: const [0.0, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Spacer to center content
              SizedBox(height: 25.h),

              // Logo section with animation
              AnimatedBuilder(
                animation: _logoAnimationController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _logoScaleAnimation.value,
                    child: Opacity(
                      opacity: _logoOpacityAnimation.value,
                      child: Column(
                        children: [
                          // App logo
                          Container(
                            width: 25.w,
                            height: 25.w,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(4.w),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  offset: const Offset(0, 4),
                                  blurRadius: 12,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4.w),
                              child: CustomImageWidget(
                                imageUrl: 'assets/images/img_app_logo.svg',
                                width: 25.w,
                                height: 25.w,
                              ),
                            ),
                          ),

                          SizedBox(height: 4.h),

                          // App name
                          Text(
                            'DouaneTest Pro',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                          ),

                          SizedBox(height: 1.h),

                          // Tagline
                          Text(
                            'Excellence en Formation Douanière',
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  letterSpacing: 0.3,
                                ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Spacer
              SizedBox(height: 8.h),

              // Loading indicator section
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 15.w),
                child: Column(
                  children: [
                    // Progress bar
                    AnimatedBuilder(
                      animation: _progressAnimation,
                      builder: (context, child) {
                        return Container(
                          width: double.infinity,
                          height: 0.8.h,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(1.h),
                          ),
                          child: Stack(
                            children: [
                              Container(
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(1.h),
                                ),
                              ),
                              FractionallySizedBox(
                                widthFactor: _progressAnimation.value,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(1.h),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 2.h),

                    // Progress percentage
                    Text(
                      '$_progressPercentage%',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontWeight: FontWeight.w500,
                          ),
                    ),

                    SizedBox(height: 1.h),

                    // Loading text
                    Text(
                      'Initialisation en cours...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                    ),
                  ],
                ),
              ),

              // Bottom spacer and version
              const Spacer(),

              // Version number
              Padding(
                padding: EdgeInsets.only(bottom: 4.h),
                child: Text(
                  'Version 1.0.0',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}