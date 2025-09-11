import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class SocialRegistrationWidget extends StatelessWidget {
  final VoidCallback onGoogleSignUp;
  final VoidCallback onAppleSignUp;
  final VoidCallback onFacebookSignUp;

  const SocialRegistrationWidget({
    super.key,
    required this.onGoogleSignUp,
    required this.onAppleSignUp,
    required this.onFacebookSignUp,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'OU',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            Expanded(
              child: Divider(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'S\'inscrire avec',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        SizedBox(height: 2.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildSocialButton(
              context,
              icon: Icons.g_mobiledata,
              label: 'Google',
              onPressed: onGoogleSignUp,
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              borderColor: Theme.of(context).colorScheme.outline,
            ),
            _buildSocialButton(
              context,
              icon: Icons.apple,
              label: 'Apple',
              onPressed: onAppleSignUp,
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            _buildSocialButton(
              context,
              icon: Icons.facebook,
              label: 'Facebook',
              onPressed: onFacebookSignUp,
              backgroundColor: const Color(0xFF1877F2),
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color foregroundColor,
    Color? borderColor,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: borderColor != null
                  ? Border.all(color: borderColor, width: 1)
                  : null,
            ),
            child: Icon(
              icon,
              color: foregroundColor,
              size: 6.w,
            ),
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
