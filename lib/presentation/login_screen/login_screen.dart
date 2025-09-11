import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import './widgets/login_form_widget.dart';
import './widgets/social_login_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideAnimationController;
  late AnimationController _fadeAnimationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();

    // Lock orientation to portrait
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  }

  void _initializeAnimations() {
    _slideAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideAnimationController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeAnimationController,
      curve: Curves.easeInOut,
    ));

    // Start animations
    _fadeAnimationController.forward();
    _slideAnimationController.forward();
  }

  void _handleLogin(String email, String password) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.lightImpact();

    try {
      // Validation côté client
      if (email.isEmpty) {
        throw Exception('Veuillez saisir votre email');
      }
      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
        throw Exception('Format d\'email invalide');
      }
      if (password.isEmpty) {
        throw Exception('Veuillez saisir votre mot de passe');
      }
      if (password.length < 6) {
        throw Exception('Le mot de passe doit contenir au moins 6 caractères');
      }

      // Simulate authentication API call
      await Future.delayed(const Duration(seconds: 2));

      // Success - navigate to integration flow or dashboard
      if (mounted) {
        HapticFeedback.mediumImpact();
        
        // Save login state
        await _saveLoginState(email);

        // Check if user has completed onboarding
        final hasCompletedOnboarding = await _checkOnboardingStatus();

        if (hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.testLibraryDashboard);
        } else {
          Navigator.pushReplacementNamed(context, AppRoutes.integrationFlowScreen);
        }
      }
    } catch (e) {
      if (mounted) {
        HapticFeedback.lightImpact();
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _handleSocialLogin(String provider) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    HapticFeedback.selectionClick();

    try {
      // Simulate social login API call
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        HapticFeedback.mediumImpact();

        // Navigate based on onboarding status
        final hasCompletedOnboarding = await _checkOnboardingStatus();

        if (hasCompletedOnboarding) {
          Navigator.pushReplacementNamed(
              context, AppRoutes.testLibraryDashboard);
        } else {
          Navigator.pushReplacementNamed(context, '/integration-flow-screen');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Erreur de connexion avec $provider';
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _checkOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_completed') ?? false;
    } catch (e) {
      debugPrint('Error checking onboarding status: $e');
      return false;
    }
  }

  Future<void> _saveLoginState(String email) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('is_logged_in', true);
      await prefs.setString('user_email', email);
      await prefs.setString('login_date', DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('Error saving login state: $e');
    }
  }

  void _navigateToRegistration() {
    HapticFeedback.selectionClick();
    Navigator.pushNamed(context, AppRoutes.registrationScreen);
  }

  void _navigateToForgotPassword() {
    HapticFeedback.selectionClick();
    // For now, show a dialog
    _showForgotPasswordDialog();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe oublié'),
        content: const Text(
          'Un lien de réinitialisation sera bientôt disponible. En attendant, veuillez contacter le support.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _slideAnimationController.dispose();
    _fadeAnimationController.dispose();
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
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.03),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 5.w),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Column(
                  children: [
                    SizedBox(height: 8.h),

                    // App Logo and Title
                    _buildHeader(context),

                    SizedBox(height: 6.h),

                    // Login Form
                    LoginFormWidget(
                      onLogin: _handleLogin,
                      onForgotPassword: _navigateToForgotPassword,
                      isLoading: _isLoading,
                      errorMessage: _errorMessage,
                    ),

                    SizedBox(height: 4.h),

                    // Divider
                    _buildDivider(context),

                    SizedBox(height: 3.h),

                    // Social Login Options
                    SocialLoginWidget(
                      onSocialLogin: _handleSocialLogin,
                      isLoading: _isLoading,
                    ),

                    SizedBox(height: 4.h),

                    // Sign up link
                    _buildSignUpLink(context),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      children: [
        // App logo
        Container(
          width: 20.w,
          height: 20.w,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary,
            borderRadius: BorderRadius.circular(4.w),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.3),
                offset: const Offset(0, 8),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4.w),
            child: CustomImageWidget(
              imageUrl: 'assets/images/logo/psychotest_logo.svg',
              width: 20.w,
              height: 20.w,
            ),
          ),
        ),

        SizedBox(height: 3.h),

        // App name
        Text(
          'PsychoTest+',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
              ),
        ),

        SizedBox(height: 1.h),

        // Welcome message
        Text(
          'Connectez-vous pour accéder à vos tests psychotechniques personnalisés',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Text(
            'OU',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            thickness: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpLink(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Nouveau sur PsychoTest+ ? ',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        GestureDetector(
          onTap: _navigateToRegistration,
          child: Text(
            'Créer un compte',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
          ),
        ),
      ],
    );
  }
}