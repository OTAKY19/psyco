import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class LoginFormWidget extends StatefulWidget {
  final Function(String email, String password) onLogin;
  final VoidCallback onForgotPassword;
  final bool isLoading;
  final String? errorMessage;

  const LoginFormWidget({
    super.key,
    required this.onLogin,
    required this.onForgotPassword,
    required this.isLoading,
    this.errorMessage,
  });

  @override
  State<LoginFormWidget> createState() => _LoginFormWidgetState();
}

class _LoginFormWidgetState extends State<LoginFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _rememberMe = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(5.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4.w),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            offset: const Offset(0, 4),
            blurRadius: 16,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(
              'Connexion',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),

            SizedBox(height: 3.h),

            // Error message
            if (widget.errorMessage != null)
              Container(
                margin: EdgeInsets.only(bottom: 2.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .error
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2.w),
                  border: Border.all(
                    color: Theme.of(context)
                        .colorScheme
                        .error
                        .withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        widget.errorMessage!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                    ),
                  ],
                ),
              ),

            // Email field
            TextFormField(
              controller: _emailController,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'Adresse e-mail',
                hintText: 'exemple@email.com',
                prefixIcon: const Icon(Icons.email_outlined),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre adresse e-mail';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                    .hasMatch(value)) {
                  return 'Veuillez saisir une adresse e-mail valide';
                }
                return null;
              },
            ),

            SizedBox(height: 2.h),

            // Password field
            TextFormField(
              controller: _passwordController,
              enabled: !widget.isLoading,
              obscureText: !_isPasswordVisible,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _handleLogin(),
              decoration: InputDecoration(
                labelText: 'Mot de passe',
                hintText: 'Saisissez votre mot de passe',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez saisir votre mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),

            SizedBox(height: 2.h),

            // Remember me and forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: widget.isLoading
                          ? null
                          : (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                    ),
                    Text(
                      'Se souvenir de moi',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                TextButton(
                  onPressed: widget.isLoading ? null : widget.onForgotPassword,
                  child: Text(
                    'Mot de passe oublié ?',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 3.h),

            // Login button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                ),
                child: widget.isLoading
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Theme.of(context).colorScheme.onPrimary,
                              ),
                            ),
                          ),
                          SizedBox(width: 3.w),
                          const Text('Connexion en cours...'),
                        ],
                      )
                    : const Text('Se connecter'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleLogin() {
    if (_formKey.currentState!.validate()) {
      widget.onLogin(_emailController.text, _passwordController.text);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}