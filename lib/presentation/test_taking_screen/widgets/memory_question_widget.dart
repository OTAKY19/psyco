import 'dart:async';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class MemoryQuestionWidget extends StatefulWidget {
  final String memorySequence;
  final String questionText;
  final List<String> options;
  final int? selectedOption;
  final Function(int) onOptionSelected;
  final int displayDuration; // in seconds

  const MemoryQuestionWidget({
    super.key,
    required this.memorySequence,
    required this.questionText,
    required this.options,
    this.selectedOption,
    required this.onOptionSelected,
    this.displayDuration = 5,
  });

  @override
  State<MemoryQuestionWidget> createState() => _MemoryQuestionWidgetState();
}

class _MemoryQuestionWidgetState extends State<MemoryQuestionWidget>
    with TickerProviderStateMixin {
  bool _showSequence = true;
  int _countdown = 0;
  Timer? _timer;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _countdown = widget.displayDuration;

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Démarrer automatiquement le timer
    _startSequenceTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  void _startSequenceTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _countdown--;
        });

        if (_countdown <= 0) {
          _timer?.cancel();
          _fadeController.forward().then((_) {
            if (mounted) {
              setState(() {
                _showSequence = false;
              });
            }
          });
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Sequence Display
          if (_showSequence) ...[
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              margin: EdgeInsets.only(bottom: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CustomIconWidget(
                        iconName: 'visibility',
                        color: AppTheme.lightTheme.colorScheme.primary,
                        size: 6.w,
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Mémorisez cette séquence',
                        style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _showSequence ? 1.0 : _fadeAnimation.value,
                        child: Container(
                          padding: EdgeInsets.all(3.w),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.memorySequence,
                            style: AppTheme.lightTheme.textTheme.headlineMedium?.copyWith(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w600,
                              letterSpacing: 2,
                              color: AppTheme.lightTheme.colorScheme.onSurface,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 2.h),
                  // Timer display only
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.5.h),
                    decoration: BoxDecoration(
                      color: _countdown <= 3
                          ? AppTheme.lightTheme.colorScheme.error.withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.timer,
                          color: _countdown <= 3
                              ? AppTheme.lightTheme.colorScheme.error
                              : AppTheme.lightTheme.colorScheme.secondary,
                          size: 4.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$_countdown',
                          style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                            color: _countdown <= 3
                                ? AppTheme.lightTheme.colorScheme.error
                                : AppTheme.lightTheme.colorScheme.secondary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Question Display (after sequence is hidden)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              margin: EdgeInsets.only(bottom: 3.h),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'psychology',
                    color: AppTheme.lightTheme.colorScheme.primary,
                    size: 6.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Rappelez-vous de la séquence et répondez à la question',
                      style: AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.lightTheme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Question Text
          Text(
            widget.questionText,
            style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),

          SizedBox(height: 3.h),

          // Options
          ...widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = widget.selectedOption == index;

            return Container(
              margin: EdgeInsets.only(bottom: 2.h),
              child: InkWell(
                onTap: () => widget.onOptionSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline.withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 6.w,
                        height: 6.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected
                              ? AppTheme.lightTheme.colorScheme.primary
                              : Colors.transparent,
                          border: Border.all(
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.outline,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                color: AppTheme.lightTheme.colorScheme.onPrimary,
                                size: 4.w,
                              )
                            : null,
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Text(
                          option,
                          style: AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: isSelected
                                ? AppTheme.lightTheme.colorScheme.primary
                                : AppTheme.lightTheme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
