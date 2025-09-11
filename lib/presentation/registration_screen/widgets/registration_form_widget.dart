import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class RegistrationFormWidget extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController fullNameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final bool hasMinLength;
  final bool hasUppercase;
  final bool hasLowercase;
  final bool hasNumber;
  final bool hasSpecialChar;
  final bool termsAccepted;
  final bool privacyAccepted;
  final ValueChanged<bool?> onTermsChanged;
  final ValueChanged<bool?> onPrivacyChanged;
  final VoidCallback onSendVerification;
  final bool isLoading;

  const RegistrationFormWidget({
    super.key,
    required this.formKey,
    required this.fullNameController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.hasMinLength,
    required this.hasUppercase,
    required this.hasLowercase,
    required this.hasNumber,
    required this.hasSpecialChar,
    required this.termsAccepted,
    required this.privacyAccepted,
    required this.onTermsChanged,
    required this.onPrivacyChanged,
    required this.onSendVerification,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informations personnelles',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          SizedBox(height: 3.h),

          TextFormField(
            controller: fullNameController,
            decoration: const InputDecoration(
              labelText: 'Nom complet',
              hintText: 'Entrez votre nom complet',
              prefixIcon: Icon(Icons.person_outline),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Le nom complet est requis';
              }
              if (value.trim().length < 2) {
                return 'Le nom doit contenir au moins 2 caractères';
              }
              return null;
            },
          ),

          SizedBox(height: 2.h),

          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              hintText: 'votre.email@exemple.com',
              prefixIcon: Icon(Icons.email_outlined),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'L\'email est requis';
              }
              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                  .hasMatch(value)) {
                return 'Format d\'email invalide';
              }
              return null;
            },
          ),

          SizedBox(height: 2.h),

          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Mot de passe',
              hintText: 'Créez un mot de passe sécurisé',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Le mot de passe est requis';
              }
              if (value.length < 8) {
                return 'Le mot de passe doit contenir au moins 8 caractères';
              }
              return null;
            },
          ),

          SizedBox(height: 1.h),

          // Password strength indicators
          _buildPasswordStrengthIndicators(context),

          SizedBox(height: 2.h),

          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Confirmer le mot de passe',
              hintText: 'Retapez votre mot de passe',
              prefixIcon: Icon(Icons.lock_outline),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'La confirmation est requise';
              }
              if (value != passwordController.text) {
                return 'Les mots de passe ne correspondent pas';
              }
              return null;
            },
          ),

          SizedBox(height: 3.h),

          // Terms and Privacy checkboxes
          CheckboxListTile(
            value: termsAccepted,
            onChanged: onTermsChanged,
            title: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'J\'accepte les '),
                  TextSpan(
                    text: 'conditions d\'utilisation',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          CheckboxListTile(
            value: privacyAccepted,
            onChanged: onPrivacyChanged,
            title: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyMedium,
                children: [
                  const TextSpan(text: 'J\'accepte la '),
                  TextSpan(
                    text: 'politique de confidentialité',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ],
              ),
            ),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
          ),

          SizedBox(height: 3.h),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading || !termsAccepted || !privacyAccepted
                  ? null
                  : onSendVerification,
              child: isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Créer le compte'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrengthIndicators(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Exigences du mot de passe :',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        SizedBox(height: 0.5.h),
        _buildPasswordCriterion(
          context,
          'Au moins 8 caractères',
          hasMinLength,
        ),
        _buildPasswordCriterion(
          context,
          'Une lettre majuscule',
          hasUppercase,
        ),
        _buildPasswordCriterion(
          context,
          'Une lettre minuscule',
          hasLowercase,
        ),
        _buildPasswordCriterion(
          context,
          'Un chiffre',
          hasNumber,
        ),
        _buildPasswordCriterion(
          context,
          'Un caractère spécial',
          hasSpecialChar,
        ),
      ],
    );
  }

  Widget _buildPasswordCriterion(
      BuildContext context, String text, bool isMet) {
    return Row(
      children: [
        Icon(
          isMet ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 16,
          color: isMet
              ? Theme.of(context).colorScheme.tertiary
              : Theme.of(context).colorScheme.outline,
        ),
        SizedBox(width: 1.w),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isMet
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
