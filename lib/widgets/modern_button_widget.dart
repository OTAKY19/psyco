import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'custom_icon_widget.dart';

/// Widget de bouton moderne avec animations et styles variés
class ModernButtonWidget extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final String? iconName;
  final ModernButtonStyle style;
  final ModernButtonSize size;
  final bool isLoading;
  final bool isDisabled;
  final Color? customColor;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const ModernButtonWidget({
    super.key,
    required this.text,
    this.onPressed,
    this.iconName,
    this.style = ModernButtonStyle.primary,
    this.size = ModernButtonSize.medium,
    this.isLoading = false,
    this.isDisabled = false,
    this.customColor,
    this.width,
    this.margin,
  });

  @override
  State<ModernButtonWidget> createState() => _ModernButtonWidgetState();
}

class _ModernButtonWidgetState extends State<ModernButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.linear,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() {
        _isPressed = true;
      });
      _animationController.forward();
    }
  }

  void _handleTapUp(TapUpDetails details) {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  void _handleTapCancel() {
    if (!widget.isDisabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    
    // Déterminer les couleurs selon le style
    Color backgroundColor;
    Color foregroundColor;
    Color borderColor = Colors.transparent;
    
    switch (widget.style) {
      case ModernButtonStyle.primary:
        backgroundColor = widget.customColor ?? colorScheme.primary;
        foregroundColor = colorScheme.onPrimary;
        break;
      case ModernButtonStyle.secondary:
        backgroundColor = colorScheme.secondary;
        foregroundColor = colorScheme.onSecondary;
        break;
      case ModernButtonStyle.outline:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.customColor ?? colorScheme.primary;
        borderColor = widget.customColor ?? colorScheme.primary;
        break;
      case ModernButtonStyle.ghost:
        backgroundColor = Colors.transparent;
        foregroundColor = widget.customColor ?? colorScheme.primary;
        break;
      case ModernButtonStyle.success:
        backgroundColor = Colors.green;
        foregroundColor = Colors.white;
        break;
      case ModernButtonStyle.warning:
        backgroundColor = Colors.orange;
        foregroundColor = Colors.white;
        break;
      case ModernButtonStyle.danger:
        backgroundColor = Colors.red;
        foregroundColor = Colors.white;
        break;
    }

    // Ajuster les couleurs si désactivé
    if (widget.isDisabled) {
      backgroundColor = colorScheme.onSurface.withValues(alpha: 0.12);
      foregroundColor = colorScheme.onSurface.withValues(alpha: 0.38);
      borderColor = borderColor != Colors.transparent 
          ? colorScheme.onSurface.withValues(alpha: 0.12) 
          : Colors.transparent;
    }

    // Déterminer la taille
    double height;
    double fontSize;
    double iconSize;
    EdgeInsetsGeometry padding;
    
    switch (widget.size) {
      case ModernButtonSize.small:
        height = 5.h;
        fontSize = 14;
        iconSize = 4.w;
        padding = EdgeInsets.symmetric(horizontal: 4.w);
        break;
      case ModernButtonSize.medium:
        height = 6.h;
        fontSize = 16;
        iconSize = 5.w;
        padding = EdgeInsets.symmetric(horizontal: 6.w);
        break;
      case ModernButtonSize.large:
        height = 7.h;
        fontSize = 18;
        iconSize = 6.w;
        padding = EdgeInsets.symmetric(horizontal: 8.w);
        break;
    }

    return Container(
      margin: widget.margin,
      width: widget.width,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              height: height,
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(12),
                border: borderColor != Colors.transparent 
                    ? Border.all(color: borderColor, width: 1.5)
                    : null,
                boxShadow: widget.style != ModernButtonStyle.ghost && 
                           widget.style != ModernButtonStyle.outline &&
                           !widget.isDisabled
                    ? [
                        BoxShadow(
                          color: backgroundColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: widget.isDisabled || widget.isLoading ? null : widget.onPressed,
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: padding,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading) ...[
                          SizedBox(
                            width: iconSize,
                            height: iconSize,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                            ),
                          ),
                          SizedBox(width: 2.w),
                        ] else if (widget.iconName != null) ...[
                          CustomIconWidget(
                            iconName: widget.iconName!,
                            color: foregroundColor,
                            size: iconSize,
                          ),
                          SizedBox(width: 2.w),
                        ],
                        Flexible(
                          child: Text(
                            widget.text,
                            style: theme.textTheme.labelLarge?.copyWith(
                              color: foregroundColor,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Styles de boutons disponibles
enum ModernButtonStyle {
  primary,
  secondary,
  outline,
  ghost,
  success,
  warning,
  danger,
}

/// Tailles de boutons disponibles
enum ModernButtonSize {
  small,
  medium,
  large,
}

/// Widget de bouton flottant moderne
class ModernFloatingButtonWidget extends StatefulWidget {
  final String? text;
  final String iconName;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final bool isExtended;
  final bool showBadge;
  final String? badgeText;

  const ModernFloatingButtonWidget({
    super.key,
    this.text,
    required this.iconName,
    this.onPressed,
    this.backgroundColor,
    this.foregroundColor,
    this.isExtended = false,
    this.showBadge = false,
    this.badgeText,
  });

  @override
  State<ModernFloatingButtonWidget> createState() => _ModernFloatingButtonWidgetState();
}

class _ModernFloatingButtonWidgetState extends State<ModernFloatingButtonWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.9,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = widget.backgroundColor ?? theme.colorScheme.primary;
    final foregroundColor = widget.foregroundColor ?? theme.colorScheme.onPrimary;

    Widget button = AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(widget.isExtended ? 16 : 28),
              boxShadow: [
                BoxShadow(
                  color: backgroundColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onPressed,
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                borderRadius: BorderRadius.circular(widget.isExtended ? 16 : 28),
                child: Padding(
                  padding: widget.isExtended 
                      ? EdgeInsets.symmetric(horizontal: 6.w, vertical: 3.w)
                      : EdgeInsets.all(4.w),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CustomIconWidget(
                        iconName: widget.iconName,
                        color: foregroundColor,
                        size: 6.w,
                      ),
                      if (widget.isExtended && widget.text != null) ...[
                        SizedBox(width: 2.w),
                        Text(
                          widget.text!,
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    // Ajouter un badge si nécessaire
    if (widget.showBadge) {
      button = Stack(
        clipBehavior: Clip.none,
        children: [
          button,
          Positioned(
            top: -1.w,
            right: -1.w,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(10),
              ),
              constraints: BoxConstraints(
                minWidth: 5.w,
                minHeight: 5.w,
              ),
              child: widget.badgeText != null
                  ? Text(
                      widget.badgeText!,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    )
                  : null,
            ),
          ),
        ],
      );
    }

    return button;
  }
}

/// Élément d'un groupe de boutons
class ModernButtonGroupItem {
  final String text;
  final String? iconName;
  final VoidCallback? onPressed;

  const ModernButtonGroupItem({
    required this.text,
    this.iconName,
    this.onPressed,
  });
}

/// Widget de groupe de boutons
class ModernButtonGroupWidget extends StatelessWidget {
  final List<ModernButtonGroupItem> items;
  final int? selectedIndex;
  final ValueChanged<int>? onSelectionChanged;
  final Axis direction;
  final MainAxisAlignment mainAxisAlignment;

  const ModernButtonGroupWidget({
    super.key,
    required this.items,
    this.selectedIndex,
    this.onSelectionChanged,
    this.direction = Axis.horizontal,
    this.mainAxisAlignment = MainAxisAlignment.spaceEvenly,
  });

  @override
  Widget build(BuildContext context) {
    return Flex(
      direction: direction,
      mainAxisAlignment: mainAxisAlignment,
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        final isSelected = selectedIndex == index;
        
        return Flexible(
          child: ModernButtonWidget(
            text: item.text,
            iconName: item.iconName,
            onPressed: () => onSelectionChanged?.call(index),
            style: isSelected ? ModernButtonStyle.primary : ModernButtonStyle.outline,
            size: ModernButtonSize.small,
            width: direction == Axis.horizontal ? null : double.infinity,
            margin: EdgeInsets.symmetric(
              horizontal: direction == Axis.horizontal ? 1.w : 0,
              vertical: direction == Axis.vertical ? 1.w : 0,
            ),
          ),
        );
      }).toList(),
    );
  }
}
