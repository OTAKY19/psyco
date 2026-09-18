import 'package:flutter/material.dart';
import '../design/app_spacing.dart';
import 'neural_header_shell.dart';

class NeuralHeaderSimple extends StatelessWidget {
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  const NeuralHeaderSimple({
    super.key,
    required this.child,
    this.height = 180,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.pageHorizontal,
      AppSpacing.xxxl,
      AppSpacing.pageHorizontal,
      AppSpacing.xxl,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return NeuralHeaderShell(
      height: height,
      padding: padding,
      showLeftRing: false,
      showRightRing: true,
      child: child,
    );
  }
}
