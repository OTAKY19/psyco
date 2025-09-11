import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SocialLoginWidget extends StatelessWidget {
  final Function(String provider) onSocialLogin;
  final bool isLoading;

  const SocialLoginWidget({
    super.key,
    required this.onSocialLogin,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final socialProviders = [
      {
        'name': 'Google',
        'icon': Icons.g_mobiledata,
        'color': const Color(0xFF4285F4),
        'textColor': Colors.white,
      },
      {
        'name': 'Apple',
        'icon': Icons.apple,
        'color': Colors.black,
        'textColor': Colors.white,
      },
      {
        'name': 'Facebook',
        'icon': Icons.facebook,
        'color': const Color(0xFF1877F2),
        'textColor': Colors.white,
      },
    ];

    return Column(
      children: [
        // Social login buttons
        ...socialProviders.map((provider) {
          return Container(
            margin: EdgeInsets.only(bottom: 2.h),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: isLoading
                    ? null
                    : () => onSocialLogin(provider['name'] as String),
                icon: Icon(
                  provider['icon'] as IconData,
                  color: provider['color'] as Color,
                  size: 24,
                ),
                label: Text(
                  'Continuer avec ${provider['name']}',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 1.8.h),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.3),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ],
    );
  }
}
