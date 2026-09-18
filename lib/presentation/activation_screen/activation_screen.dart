import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../design/app_colors.dart';
import '../../design/app_radii.dart';
import '../../design/app_shadows.dart';
import '../../design/app_spacing.dart';
import '../../design/app_text_styles.dart';
import '../../services/one_time_purchase_service.dart';
import '../../services/user_state_service.dart';
import '../../router/app_routes.dart';

// Configuration des fournisseurs de paiement Bénin
final Map<String, BeninProvider> beninProviders = {
  'mtn': const BeninProvider(
    name: 'MTN Mobile Money',
    prefixes: ['90', '91', '96', '97'],
    color: Color(0xFFFFC107),
    ussdCode: '*133#',
  ),
  'moov': const BeninProvider(
    name: 'Moov Money',
    prefixes: ['94', '95', '98', '99'],
    color: Color(0xFF00A651),
    ussdCode: '*555#',
  ),
};

// Configuration de l'offre PsychoTest+
class PsychoTestOffer {
  static const double priceFcfa = 3000;

  static const Offer fullAccess = Offer(
    name: 'Accès Complet',
    price: priceFcfa,
    benefits: [
      'Accès à toutes les 40 questions par test',
      'Résultats détaillés et analyses complètes',
      'Statistiques de performance avancées',
      'Mode hors-ligne complet',
      'Sauvegarde automatique des progrès',
      'Support technique prioritaire',
      'Mises à jour gratuites à vie',
      'Accès aux nouvelles fonctionnalités',
    ],
  );
}

class Offer {
  final String name;
  final double price;
  final List<String> benefits;

  const Offer({
    required this.name,
    required this.price,
    required this.benefits,
  });
}

class BeninProvider {
  final String name;
  final List<String> prefixes;
  final Color color;
  final String ussdCode;

  const BeninProvider({
    required this.name,
    required this.prefixes,
    required this.color,
    required this.ussdCode,
  });
}

class ActivationScreen extends StatefulWidget {
  final Map<String, dynamic>? examResults;

  const ActivationScreen({super.key, this.examResults});

  @override
  State<ActivationScreen> createState() => _ActivationScreenState();
}

class _ActivationScreenState extends State<ActivationScreen> {
  final OneTimePurchaseService _purchaseService = OneTimePurchaseService();
  bool _isProcessingPayment = false;
  String? _selectedProvider;
  final TextEditingController _phoneNumberController = TextEditingController();

  @override
  void dispose() {
    _phoneNumberController.dispose();
    super.dispose();
  }

  void _showPaymentMethods(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadii.modalTop)),
      ),
      builder: (context) => Container(
        padding: AppSpacing.pagePadding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(AppRadii.pill),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "Choisir votre opérateur",
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: AppSpacing.xl),
            ...beninProviders.entries.map((entry) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadii.card),
                      onTap: () {
                        Navigator.pop(context);
                        _initiatePayment(context, entry.key);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: Border.all(color: AppColors.borderLight),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: entry.value.color,
                                borderRadius: BorderRadius.circular(AppRadii.md),
                              ),
                              child: const Icon(Icons.phone_android, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.value.name,
                                    style: AppTextStyles.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    "${entry.value.prefixes.join(', ')} • Code: ${entry.value.ussdCode}",
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted),
                          ],
                        ),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }

  void _initiatePayment(BuildContext context, String provider) {
    _selectedProvider = provider;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Paiement ${beninProviders[provider]!.name}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Veuillez entrer votre numéro de téléphone ${beninProviders[provider]!.name} pour procéder au paiement de ${PsychoTestOffer.priceFcfa} FCFA.",
            ),
            const SizedBox(height: AppSpacing.xl),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: "Numéro de téléphone",
                hintText: "Ex: 97123456",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processPayment();
            },
            child: const Text("Payer"),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment() async {
    if (_selectedProvider == null || _phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez sélectionner un opérateur et entrer un numéro.")),
      );
      return;
    }

    setState(() => _isProcessingPayment = true);

    try {
      final result = await _purchaseService.purchaseFullAccess(
        _selectedProvider!,
        _phoneNumberController.text,
      );

      if (mounted) {
        if (result.success) {
          // Accès activé UNIQUEMENT après attestation + confirmation (dialogue USSD).
          _showUssdInstructions(context, result);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result.errorMessage ?? "Erreur de paiement inconnue")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du traitement du paiement: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessingPayment = false);
      }
    }
  }

  void _showUssdInstructions(BuildContext context, PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Action requise"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Pour finaliser votre achat, veuillez composer le code USSD suivant sur votre téléphone:"),
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(AppRadii.sm),
              ),
              child: SelectableText(
                result.ussdCode!,
                style: AppTextStyles.headlineSmall.copyWith(color: AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              "Après avoir composé le code, suivez les instructions sur votre écran pour confirmer le paiement de ${result.amount} FCFA.",
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              "Touchez « J'ai payé » après avoir validé sur votre téléphone. Sans validation opérateur, l'accès ne sera pas activé.",
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              context.go(AppRoutes.home);
            },
            child: const Text("Plus tard"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              final txnId = result.transactionId;
              if (txnId == null) return;
              await _purchaseService.markUserAttested(txnId);
              final confirm =
                  await _purchaseService.confirmPayment(txnId);
              if (!context.mounted) return;
              if (confirm['success'] == true) {
                Provider.of<UserStateService>(context, listen: false)
                    .setLifetimeAccess(true);
                context.go(AppRoutes.home);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Accès premium activé. Bon courage !')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(confirm['error'] as String? ??
                          'Paiement non confirmé. Réessayez après validation.')),
                );
              }
            },
            child: const Text("J'ai payé, activer"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
                child: Column(
                  children: [
                    const SizedBox(height: AppSpacing.xxl),

                    // Hero section with gradient
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(size.width * 0.06),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(AppRadii.xxl),
                        boxShadow: AppShadows.ctaLg,
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.star_rounded,
                              size: 44,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          Text(
                            "Version Complète",
                            style: AppTextStyles.titleLarge.copyWith(
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            "Achat unique • Accès à vie",
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Price display
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "3 000",
                                style: AppTextStyles.displayLarge.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.only(bottom: 4),
                                child: Text(
                                  "FCFA",
                                  style: AppTextStyles.titleMedium.copyWith(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            "(~2,3€)",
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // Benefits list
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        boxShadow: AppShadows.card,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadii.iconContainer),
                                ),
                                child: const Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text(
                                'Ce que vous obtenez',
                                style: AppTextStyles.titleMedium,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          ...PsychoTestOffer.fullAccess.benefits.map(
                            (benefit) => Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    margin: const EdgeInsets.only(top: 1, right: AppSpacing.md),
                                    decoration: BoxDecoration(
                                      color: AppColors.successContainer,
                                      borderRadius: BorderRadius.circular(AppRadii.xs),
                                    ),
                                    child: const Icon(
                                      Icons.check_rounded,
                                      color: AppColors.success,
                                      size: 14,
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      benefit,
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: AppColors.textPrimary,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xxl),

                    // CTA Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                          ),
                          borderRadius: BorderRadius.circular(AppRadii.button),
                          boxShadow: AppShadows.ctaLg,
                        ),
                        child: ElevatedButton(
                          onPressed: _isProcessingPayment
                              ? null
                              : () => _showPaymentMethods(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadii.button),
                            ),
                          ),
                          child: _isProcessingPayment
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  "Activer maintenant - 3 000 FCFA",
                                  style: AppTextStyles.buttonLarge.copyWith(color: Colors.white),
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    // Secondary button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => _showActivationCodeDialog(context),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary, width: 1.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadii.button),
                          ),
                        ),
                        child: Text(
                          "J'ai un code d'activation",
                          style: AppTextStyles.buttonMedium.copyWith(color: AppColors.primary),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppSpacing.xl),

                    // Trust indicators
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      decoration: BoxDecoration(
                        color: AppColors.successContainer,
                        borderRadius: BorderRadius.circular(AppRadii.card),
                        border: Border.all(color: AppColors.success.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.shield_rounded,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Text(
                            "Paiement sécurisé • Accès immédiat",
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.successDark,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: padding.bottom + AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActivationCodeDialog(BuildContext context) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Code d'activation", style: AppTextStyles.titleLarge),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Entrez votre code d'activation reçu par email ou SMS.",
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: codeController,
              decoration: InputDecoration(
                hintText: "Entrez votre code",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                  borderSide: const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              if (codeController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Vérification du code...")),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text("Activer"),
          ),
        ],
      ),
    );
  }
}
