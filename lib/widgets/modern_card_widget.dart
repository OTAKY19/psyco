import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import 'custom_icon_widget.dart';

/// Widget de carte moderne avec animations et design amélioré
class ModernCardWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? elevation;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final bool enableHoverEffect;
  final Duration animationDuration;

  const ModernCardWidget({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.elevation,
    this.borderRadius,
    this.showShadow = true,
    this.enableHoverEffect = true,
    this.animationDuration = const Duration(milliseconds: 200),
  });

  @override
  State<ModernCardWidget> createState() => _ModernCardWidgetState();
}

class _ModernCardWidgetState extends State<ModernCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: widget.elevation ?? 2.0,
      end: (widget.elevation ?? 2.0) * 1.5,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (widget.enableHoverEffect) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (widget.enableHoverEffect) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (widget.enableHoverEffect) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: widget.margin ?? EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
            child: Material(
              elevation: widget.showShadow ? _elevationAnimation.value : 0,
              borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
              shadowColor: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
              child: Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Theme.of(context).colorScheme.surface,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
                    width: 1,
                  ),
                  gradient: _isPressed
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                            Theme.of(context).colorScheme.surface,
                          ],
                        )
                      : null,
                ),
                child: InkWell(
                  onTap: widget.onTap,
                  onLongPress: widget.onLongPress,
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
                  child: Padding(
                    padding: widget.padding ?? EdgeInsets.all(4.w),
                    child: widget.child,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Widget de carte de statistiques moderne
class ModernStatsCardWidget extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String iconName;
  final Color? iconColor;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool showTrend;
  final double? trendValue;
  final bool isPositiveTrend;

  const ModernStatsCardWidget({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.iconName,
    this.iconColor,
    this.backgroundColor,
    this.onTap,
    this.showTrend = false,
    this.trendValue,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCardWidget(
      onTap: onTap,
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: (iconColor ?? Theme.of(context).colorScheme.primary)
                      .withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: iconColor ?? Theme.of(context).colorScheme.primary,
                  size: 6.w,
                ),
              ),
              if (showTrend && trendValue != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
                  decoration: BoxDecoration(
                    color: isPositiveTrend
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: isPositiveTrend ? 'trending_up' : 'trending_down',
                        color: isPositiveTrend ? Colors.green : Colors.red,
                        size: 3.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '${trendValue!.abs().toStringAsFixed(1)}%',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: isPositiveTrend ? Colors.green : Colors.red,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
          ),
          if (subtitle != null) ...[
            SizedBox(height: 0.5.h),
            Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Widget de carte de progression moderne
class ModernProgressCardWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final double progress; // 0.0 to 1.0
  final String progressText;
  final String iconName;
  final Color? progressColor;
  final VoidCallback? onTap;

  const ModernProgressCardWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.progressText,
    required this.iconName,
    this.progressColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = progressColor ?? Theme.of(context).colorScheme.primary;
    
    return ModernCardWidget(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CustomIconWidget(
                  iconName: iconName,
                  color: color,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                progressText,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: color.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 1.h,
            ),
          ),
        ],
      ),
    );
  }
}
