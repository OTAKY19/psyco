import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/app_export.dart';

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
    this.displayDuration = 3,
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
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Memory Sequence Display
          if (_showSequence) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.primary
                    .withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppTheme.lightTheme.colorScheme.primary
                      .withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.visibility, color: AppTheme.lightTheme.colorScheme.primary, size: AppSpacing.xl),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        'Mémorisez cette séquence',
                        style:
                            AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.lightTheme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AnimatedBuilder(
                    animation: _fadeAnimation,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _showSequence ? 1.0 : _fadeAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: AppTheme.lightTheme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: AppTheme.lightTheme.colorScheme.shadow
                                    .withValues(alpha: 0.1),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Text(
                            widget.memorySequence,
                            style: AppTheme.lightTheme.textTheme.headlineMedium
                                ?.copyWith(
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
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: 12),
                    decoration: BoxDecoration(
                      color: _countdown <= 3
                          ? AppTheme.lightTheme.colorScheme.error
                              .withValues(alpha: 0.1)
                          : AppTheme.lightTheme.colorScheme.secondary
                              .withValues(alpha: 0.1),
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
                          size: AppSpacing.lg,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '$_countdown',
                          style: AppTheme.lightTheme.textTheme.titleMedium
                              ?.copyWith(
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
              padding: const EdgeInsets.all(AppSpacing.lg),
              margin: const EdgeInsets.only(bottom: AppSpacing.xxl),
              decoration: BoxDecoration(
                color: AppTheme.lightTheme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.lightTheme.colorScheme.shadow
                        .withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(Icons.psychology, color: AppTheme.lightTheme.colorScheme.primary, size: AppSpacing.xl),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      'Rappelez-vous de la séquence et répondez à la question',
                      style:
                          AppTheme.lightTheme.textTheme.titleMedium?.copyWith(
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

          const SizedBox(height: AppSpacing.xxl),

          // Options
          ...widget.options.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            final isSelected = widget.selectedOption == index;

            return Container(
              margin: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: InkWell(
                onTap: () => widget.onOptionSelected(index),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.lightTheme.colorScheme.primary
                            .withValues(alpha: 0.1)
                        : AppTheme.lightTheme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? AppTheme.lightTheme.colorScheme.primary
                          : AppTheme.lightTheme.colorScheme.outline
                              .withValues(alpha: 0.3),
                      width: isSelected ? 2 : 1,
                    ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.lightTheme.colorScheme.primary
                                  .withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
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
                                color:
                                    AppTheme.lightTheme.colorScheme.onPrimary,
                                size: AppSpacing.lg,
                              )
                            : null,
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Text(
                          option,
                          style:
                              AppTheme.lightTheme.textTheme.bodyLarge?.copyWith(
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w400,
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
