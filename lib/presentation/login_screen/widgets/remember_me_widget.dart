import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class RememberMeWidget extends StatelessWidget {
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final bool isBiometricSupported;
  final VoidCallback onBiometricPressed;

  const RememberMeWidget({
    super.key,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.isBiometricSupported,
    required this.onBiometricPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Remember me checkbox
        Expanded(
          child: Row(
            children: [
              SizedBox(
                width: 6.w,
                height: 6.w,
                child: Checkbox(
                  value: rememberMe,
                  onChanged: (value) => onRememberMeChanged(value ?? false),
                ),
              ),
              SizedBox(width: 2.w),
              Flexible(
                child: Text(
                  'Se souvenir de moi',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ),
        ),

        // Biometric authentication button
        if (isBiometricSupported) ...[
          SizedBox(width: 2.w),
          Container(
            decoration: BoxDecoration(
              color:
                  Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: IconButton(
              onPressed: onBiometricPressed,
              icon: Icon(
                Icons.fingerprint,
                color: Theme.of(context).colorScheme.primary,
                size: 6.w,
              ),
              tooltip: 'Authentification biométrique',
            ),
          ),
        ],
      ],
    );
  }
}
