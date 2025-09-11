import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class ActionButtonsWidget extends StatelessWidget {
  final double scorePercentage;
  final String testName;
  final VoidCallback? onRetakeTest;
  final VoidCallback? onTrySimilarTests;
  final VoidCallback? onGenerateCertificate;

  const ActionButtonsWidget({
    Key? key,
    required this.scorePercentage,
    required this.testName,
    this.onRetakeTest,
    this.onTrySimilarTests,
    this.onGenerateCertificate,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      child: Column(
        children: [
          // Share button
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _shareResults(),
              icon: CustomIconWidget(
                iconName: 'share',
                color: AppTheme.primaryLight,
                size: 20,
              ),
              label: Text('Partager mes résultats'),
              style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 3.h),
              ),
            ),
          ),
          SizedBox(height: 2.h),

          // Certificate button (only for high scores)
          if (scorePercentage >= 70) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onGenerateCertificate,
                icon: CustomIconWidget(
                  iconName: 'workspace_premium',
                  color: Colors.white,
                  size: 20,
                ),
                label: Text('Générer le certificat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentLight,
                  padding: EdgeInsets.symmetric(vertical: 3.h),
                ),
              ),
            ),
            SizedBox(height: 2.h),
          ],

          // Action buttons row
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onRetakeTest,
                  icon: CustomIconWidget(
                    iconName: 'refresh',
                    color: Colors.white,
                    size: 20,
                  ),
                  label: Text('Refaire'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                  ),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onTrySimilarTests,
                  icon: CustomIconWidget(
                    iconName: 'quiz',
                    color: AppTheme.primaryLight,
                    size: 20,
                  ),
                  label: Text('Tests similaires'),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 3.h),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _shareResults() {
    final String shareText = '''
🎯 Résultat du test: $testName

📊 Score obtenu: ${scorePercentage.toInt()}%

Préparation aux concours de la douane avec DouaneTest Pro!
''';

    Share.share(shareText);
  }
}
