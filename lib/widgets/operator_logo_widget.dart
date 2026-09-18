import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../core/app_export.dart';

/// Widget universel pour afficher les logos des opérateurs
class OperatorLogoWidget extends StatelessWidget {
  final String operatorId;
  final double? size;
  final bool showLabel;
  final bool showBackground;
  final EdgeInsets? padding;

  const OperatorLogoWidget({
    super.key,
    required this.operatorId,
    this.size,
    this.showLabel = false,
    this.showBackground = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final operator = _getOperatorData(operatorId);
    final logoSize = size ?? AppSpacing.xxxl;

    return Container(
      padding: padding ?? const EdgeInsets.all(AppSpacing.xs),
      decoration: showBackground ? BoxDecoration(
        color: operator.backgroundColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: operator.backgroundColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ) : null,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo
          SizedBox(
            width: logoSize,
            height: logoSize,
            child: _buildLogo(operator),
          ),
          
          // Label optionnel
          if (showLabel) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              operator.name,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: operator.backgroundColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLogo(OperatorData operator) {
    return Stack(
      children: [
        // Logo principal avec fallback
        _buildMainLogo(operator),
        
        // Indicateur de statut (optionnel)
        if (operator.isActive)
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: AppSpacing.sm,
              height: AppSpacing.sm,
              decoration: BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainLogo(OperatorData operator) {
    // Essayer d'abord le logo réseau avec timeout et gestion d'erreurs
    if (operator.networkLogoUrl.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: operator.networkLogoUrl,
        fit: BoxFit.contain,
        fadeInDuration: const Duration(milliseconds: 300),
        placeholder: (context, url) => Container(
          decoration: BoxDecoration(
            color: operator.backgroundColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Center(
            child: SizedBox(
              width: (size ?? AppSpacing.xxxl) * 0.4,
              height: (size ?? AppSpacing.xxxl) * 0.4,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(operator.backgroundColor),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) {
          if (kDebugMode) {
            debugPrint('❌ Erreur chargement logo ${operator.id}: $error');
          }
          return _buildFallbackLogo(operator);
        },
        httpHeaders: const {
          'User-Agent': 'PsychoTest+ Mobile App',
        },
      );
    }
    
    // Utiliser le logo local ou fallback
    return _buildFallbackLogo(operator);
  }

  Widget _buildFallbackLogo(OperatorData operator) {
    // Essayer le logo SVG local
    if (operator.localSvgPath.isNotEmpty) {
      return SvgPicture.asset(
        operator.localSvgPath,
        fit: BoxFit.contain,
        placeholderBuilder: (context) => _buildIconFallback(operator),
      );
    }
    
    // Essayer le logo PNG local
    if (operator.localPngPath.isNotEmpty) {
      return Image.asset(
        operator.localPngPath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => _buildIconFallback(operator),
      );
    }
    
    // Fallback final avec icône
    return _buildIconFallback(operator);
  }

  Widget _buildIconFallback(OperatorData operator) {
    return Container(
      decoration: BoxDecoration(
        color: operator.backgroundColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Center(
        child: Text(
          operator.shortName,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: (size ?? AppSpacing.xxxl) * 0.3,
          ),
        ),
      ),
    );
  }

  OperatorData _getOperatorData(String operatorId) {
    switch (operatorId.toLowerCase()) {
      case 'mtn':
        return const OperatorData(
          id: 'mtn',
          name: 'MTN Mobile Money',
          shortName: 'MTN',
          backgroundColor: Color(0xFFFFC107),
          networkLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/8/8e/MTN_Group_Logo.svg',
          localSvgPath: 'assets/images/operators/mtn_logo.svg',
          localPngPath: 'assets/images/operators/mtn_logo.png',
          isActive: true,
        );
      
      case 'moov':
        return const OperatorData(
          id: 'moov',
          name: 'Moov Money',
          shortName: 'MOOV',
          backgroundColor: Color(0xFF00A651),
          networkLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/0/0c/Moov_Africa_Logo.png',
          localSvgPath: 'assets/images/operators/moov_logo.svg',
          localPngPath: 'assets/images/operators/moov_logo.png',
          isActive: true,
        );
      
      case 'orange':
        return const OperatorData(
          id: 'orange',
          name: 'Orange Money',
          shortName: 'ORG',
          backgroundColor: Color(0xFFFF6600),
          networkLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/c/c8/Orange_logo.svg',
          localSvgPath: 'assets/images/operators/orange_logo.svg',
          localPngPath: 'assets/images/operators/orange_logo.png',
          isActive: false, // Pas encore supporté
        );
      
      case 'airtel':
        return const OperatorData(
          id: 'airtel',
          name: 'Airtel Money',
          shortName: 'AIR',
          backgroundColor: Color(0xFFE60012),
          networkLogoUrl: 'https://upload.wikimedia.org/wikipedia/commons/4/4e/Airtel_logo.svg',
          localSvgPath: 'assets/images/operators/airtel_logo.svg',
          localPngPath: 'assets/images/operators/airtel_logo.png',
          isActive: false,
        );
      
      default:
        return const OperatorData(
          id: 'unknown',
          name: 'Opérateur Inconnu',
          shortName: '?',
          backgroundColor: Colors.grey,
          networkLogoUrl: '',
          localSvgPath: '',
          localPngPath: '',
          isActive: false,
        );
    }
  }
}

/// Widget pour afficher plusieurs opérateurs en ligne
class OperatorsRowWidget extends StatelessWidget {
  final List<String> operatorIds;
  final double? logoSize;
  final bool showLabels;
  final MainAxisAlignment alignment;
  final double spacing;

  const OperatorsRowWidget({
    super.key,
    required this.operatorIds,
    this.logoSize,
    this.showLabels = false,
    this.alignment = MainAxisAlignment.spaceEvenly,
    this.spacing = 2.0,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: operatorIds.map((operatorId) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: OperatorLogoWidget(
            operatorId: operatorId,
            size: logoSize,
            showLabel: showLabels,
          ),
        );
      }).toList(),
    );
  }
}

/// Widget pour sélectionner un opérateur
class OperatorSelectorWidget extends StatelessWidget {
  final List<String> operatorIds;
  final String? selectedOperator;
  final ValueChanged<String> onOperatorSelected;
  final bool showInactiveOperators;

  const OperatorSelectorWidget({
    super.key,
    required this.operatorIds,
    this.selectedOperator,
    required this.onOperatorSelected,
    this.showInactiveOperators = false,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.lg,
      children: operatorIds.map((operatorId) {
        final isSelected = selectedOperator == operatorId;
        final operatorData = OperatorLogoWidget(operatorId: operatorId, size: 0)
            ._getOperatorData(operatorId);
        
        // Masquer les opérateurs inactifs si demandé
        if (!showInactiveOperators && !operatorData.isActive) {
          return const SizedBox.shrink();
        }
        
        return GestureDetector(
          onTap: operatorData.isActive ? () => onOperatorSelected(operatorId) : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isSelected 
                  ? operatorData.backgroundColor.withValues(alpha: 0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected 
                    ? operatorData.backgroundColor
                    : Colors.grey.withValues(alpha: 0.3),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              children: [
                OperatorLogoWidget(
                  operatorId: operatorId,
                  size: AppSpacing.massive,
                  showBackground: false,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  operatorData.name,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: operatorData.isActive 
                        ? (isSelected ? operatorData.backgroundColor : Colors.black87)
                        : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                if (!operatorData.isActive)
                  const Text(
                    'Bientôt disponible',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Données d'un opérateur
class OperatorData {
  final String id;
  final String name;
  final String shortName;
  final Color backgroundColor;
  final String networkLogoUrl;
  final String localSvgPath;
  final String localPngPath;
  final bool isActive;

  const OperatorData({
    required this.id,
    required this.name,
    required this.shortName,
    required this.backgroundColor,
    required this.networkLogoUrl,
    required this.localSvgPath,
    required this.localPngPath,
    required this.isActive,
  });
}
