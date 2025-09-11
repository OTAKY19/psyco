import 'dart:io' if (dart.library.io) 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import './widgets/profile_avatar_widget.dart';
import './widgets/registration_form_widget.dart';
import './widgets/social_registration_widget.dart';
import './widgets/study_preferences_widget.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _verificationCodeController = TextEditingController();

  final PageController _pageController = PageController();
  int _currentStep = 0;
  bool _isLoading = false;
  bool _emailVerificationSent = false;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  File? _avatarImage;
  List<String> _selectedCategories = [];
  String _selectedDifficulty = 'intermediate';
  int _resendTimer = 60;
  bool _canResend = false;

  // Password strength indicators
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_updatePasswordStrength);
  }

  @override
  void dispose() {
    _formKey.currentState?.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _verificationCodeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _updatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasNumber = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<bool> _requestCameraPermission() async {
    if (kIsWeb) return true;
    final status = await Permission.camera.request();
    return status.isGranted;
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final hasPermission = await _requestCameraPermission();
    if (!hasPermission && source == ImageSource.camera) {
      _showErrorSnackBar('Permission caméra refusée');
      return;
    }

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && !kIsWeb) {
        setState(() {
          _avatarImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Erreur lors de la sélection de l\'image');
    }
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _sendVerificationCode() async {
    if (!_formKey.currentState!.validate() ||
        !_termsAccepted ||
        !_privacyAccepted) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
      _emailVerificationSent = true;
      _canResend = false;
      _resendTimer = 60;
    });

    _nextStep();
    _startResendTimer();
  }

  void _startResendTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _resendTimer > 0) {
        setState(() {
          _resendTimer--;
        });
        _startResendTimer();
      } else if (mounted) {
        setState(() {
          _canResend = true;
        });
      }
    });
  }

  Future<void> _verifyCodeAndComplete() async {
    if (_verificationCodeController.text.length != 6) {
      _showErrorSnackBar('Code de vérification invalide');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    // Simulate verification
    await Future.delayed(const Duration(seconds: 2));

    setState(() {
      _isLoading = false;
    });

    _nextStep();
  }

  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate account creation
    await Future.delayed(const Duration(seconds: 3));

    setState(() {
      _isLoading = false;
    });

    // Show success animation
    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.check_circle,
              color: Theme.of(context).colorScheme.tertiary,
              size: 64,
            ),
            SizedBox(height: 2.h),
            Text(
              'Compte créé avec succès !',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.h),
            Text(
              'Bienvenue dans DouaneTest Pro',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                AppRoutes.loginScreen,
                (route) => false,
              );
            },
            child: const Text('Commencer'),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer un compte'),
        leading: _currentStep > 0
            ? IconButton(
                onPressed: _previousStep,
                icon: const CustomIconWidget(iconName: 'arrow_back'),
              )
            : IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const CustomIconWidget(iconName: 'close'),
              ),
      ),
      body: Column(
        children: [
          // Progress indicator
          Container(
            padding: EdgeInsets.all(2.h),
            child: Row(
              children: List.generate(3, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                    height: 4,
                    decoration: BoxDecoration(
                      color: index <= _currentStep
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context).colorScheme.outline,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentStep = index;
                });
              },
              children: [
                // Step 1: Personal Information
                SingleChildScrollView(
                  padding: EdgeInsets.all(2.h),
                  child: RegistrationFormWidget(
                    formKey: _formKey,
                    fullNameController: _fullNameController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                    hasMinLength: _hasMinLength,
                    hasUppercase: _hasUppercase,
                    hasLowercase: _hasLowercase,
                    hasNumber: _hasNumber,
                    hasSpecialChar: _hasSpecialChar,
                    termsAccepted: _termsAccepted,
                    privacyAccepted: _privacyAccepted,
                    onTermsChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                    onPrivacyChanged: (value) =>
                        setState(() => _privacyAccepted = value ?? false),
                    onSendVerification: _sendVerificationCode,
                    isLoading: _isLoading,
                  ),
                ),

                // Step 2: Email Verification
                SingleChildScrollView(
                  padding: EdgeInsets.all(2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vérification email',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Un code de vérification a été envoyé à ${_emailController.text}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      SizedBox(height: 3.h),
                      TextFormField(
                        controller: _verificationCodeController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Code de vérification',
                          hintText: 'Entrez le code à 6 chiffres',
                        ),
                        validator: (value) {
                          if (value == null || value.length != 6) {
                            return 'Le code doit contenir 6 chiffres';
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: 2.h),
                      if (!_canResend)
                        Text(
                          'Renvoyer le code dans ${_resendTimer}s',
                          style: Theme.of(context).textTheme.bodySmall,
                        )
                      else
                        TextButton(
                          onPressed: _sendVerificationCode,
                          child: const Text('Renvoyer le code'),
                        ),
                      SizedBox(height: 4.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _verifyCodeAndComplete,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Vérifier'),
                        ),
                      ),
                    ],
                  ),
                ),

                // Step 3: Profile Setup
                SingleChildScrollView(
                  padding: EdgeInsets.all(2.h),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Configuration du profil',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      SizedBox(height: 3.h),
                      ProfileAvatarWidget(
                        avatarImage: _avatarImage,
                        onPickImage: _pickAvatar,
                      ),
                      SizedBox(height: 3.h),
                      StudyPreferencesWidget(
                        selectedCategories: _selectedCategories,
                        selectedDifficulty: _selectedDifficulty,
                        onCategoriesChanged: (categories) {
                          setState(() {
                            _selectedCategories = categories;
                          });
                        },
                        onDifficultyChanged: (difficulty) {
                          setState(() {
                            _selectedDifficulty = difficulty;
                          });
                        },
                      ),
                      SizedBox(height: 4.h),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _completeRegistration,
                          child: _isLoading
                              ? const CircularProgressIndicator()
                              : const Text('Terminer l\'inscription'),
                        ),
                      ),
                      SizedBox(height: 2.h),
                      SocialRegistrationWidget(
                        onGoogleSignUp: () {
                          // Handle Google registration
                        },
                        onAppleSignUp: () {
                          // Handle Apple registration
                        },
                        onFacebookSignUp: () {
                          // Handle Facebook registration
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}