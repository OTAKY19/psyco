import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../routes/app_routes.dart';

class PaymentSuggestionWidget extends StatefulWidget {
  final VoidCallback onPaymentSelected;
  final VoidCallback onLater;

  const PaymentSuggestionWidget({
    super.key,
    required this.onPaymentSelected,
    required this.onLater,
  });

  @override
  State<PaymentSuggestionWidget> createState() => _PaymentSuggestionWidgetState();

  static Future<void> show(
    BuildContext context,
    VoidCallback onPaymentSelected,
    VoidCallback onLater,
  ) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PaymentSuggestionWidget(
        onPaymentSelected: onPaymentSelected,
        onLater: onLater,
      ),
    );
  }
}

class _PaymentSuggestionWidgetState extends State<PaymentSuggestionWidget> {
  final List<PaymentPlan> _plans = [
    PaymentPlan(
      name: 'Basic',
      price: 2500,
      duration: 'mois',
      features: [
        '✅ Tests illimités',
        '✅ Statistiques de base',
        '✅ Support email',
        '✅ Accès mobile',
      ],
      color: Colors.blue,
      recommended: false,
    ),
    PaymentPlan(
      name: 'Premium',
      price: 5000,
      duration: 'mois',
      features: [
        '✅ Tout Basic +',
        '✅ Simulations complètes',
        '✅ Rapports détaillés',
        '✅ Support prioritaire',
        '✅ IA recommandations',
      ],
      color: Colors.purple,
      recommended: true,
    ),
    PaymentPlan(
      name: 'Elite',
      price: 10000,
      duration: 'mois',
      features: [
        '✅ Tout Premium +',
        '✅ Examens blancs illimités',
        '✅ Coaching personnalisé',
        '✅ Support 24/7',
        '✅ Certificats officiels',
      ],
      color: Colors.amber,
      recommended: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: BoxConstraints(maxWidth: 90.w, maxHeight: 90.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header avec style drawer
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  // Icône avec style drawer
                  Container(
                    padding: EdgeInsets.all(3.w),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.lock_clock,
                      color: Colors.white,
                      size: 10.w,
                    ),
                  ),

                  SizedBox(height: 2.h),

                  // Titre avec style drawer
                  Text(
                    'Limite Tests Gratuits',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 1.h),

                  // Sous-titre
                  Text(
                    'Débloquez tout le potentiel',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            ),

            // Contenu
            Flexible(
              child: SingleChildScrollView(
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Message de découverte
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.blue.shade200,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          'Vous venez de découvrir un échantillon de nos fonctionnalités premium. Pour accéder à tout le potentiel de PsychoTest+ :',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.blue.shade700,
                            height: 1.4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Avantages premium
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.green.shade200,
                            width: 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  color: Colors.green.shade600,
                                  size: 5.w,
                                ),
                                SizedBox(width: 2.w),
                                Text(
                                  'Avantages Premium :',
                                  style: TextStyle(
                                    fontSize: 14.sp,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 1.h),
                            _buildAdvantage('✅ Tests illimités sur toutes les catégories'),
                            _buildAdvantage('✅ Statistiques détaillées et recommandations IA'),
                            _buildAdvantage('✅ Simulations d\'examens blancs complètes'),
                          ],
                        ),
                      ),

                      SizedBox(height: 3.h),

                      // Plans de paiement
                      Text(
                        'Formules Disponibles :',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),

                      SizedBox(height: 2.h),

                      // Liste des plans (style drawer)
                      ..._plans.map((plan) => Container(
                        margin: EdgeInsets.only(bottom: 2.h),
                        child: _buildDrawerStylePlan(plan),
                      )),

                      SizedBox(height: 3.h),

                      // Boutons d'action (style drawer)
                      Row(
                        children: [
                          Expanded(
                            child: TextButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onLater();
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Plus tard',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pop(context);
                                widget.onPaymentSelected();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green.shade600,
                                padding: EdgeInsets.symmetric(vertical: 2.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Voir les Formules',
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 2.h),

                      // Note
                      Text(
                        '💡 Annulation possible à tout moment',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerStylePlan(PaymentPlan plan) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.recommended ? plan.color : Colors.grey.shade300,
          width: plan.recommended ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          // Header du plan
          Row(
            children: [
              // Icône
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: plan.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified,
                  color: plan.color,
                  size: 6.w,
                ),
              ),

              SizedBox(width: 3.w),

              // Texte
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        if (plan.recommended) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: plan.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Recommandé',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${plan.price.toString()} XOF/${plan.duration}',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: plan.color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Flèche
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 4.w,
              ),
            ],
          ),

          if (plan.features.isNotEmpty) ...[
            SizedBox(height: 2.h),
            // Fonctionnalités (premières 2 seulement pour le style drawer)
            ...plan.features.take(2).map((feature) => Padding(
              padding: EdgeInsets.only(bottom: 0.5.h),
              child: Text(
                feature,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAdvantage(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 0.5.h),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.sp,
          color: Colors.green.shade600,
        ),
      ),
    );
  }

  Widget _buildPlanCard(PaymentPlan plan) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: plan.recommended ? plan.color.withValues(alpha: 0.1) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: plan.recommended ? plan.color : Colors.grey.shade300,
          width: plan.recommended ? 2 : 1,
        ),
        boxShadow: plan.recommended ? [
          BoxShadow(
            color: plan.color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: Offset(0, 4),
          ),
        ] : null,
      ),
      child: Column(
        children: [
          // Header du plan
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          plan.name,
                          style: AppTheme.lightTheme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: plan.color,
                          ),
                        ),
                        if (plan.recommended) ...[
                          SizedBox(width: 2.w),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                            decoration: BoxDecoration(
                              color: plan.color,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              'Recommandé',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      '${plan.price.toString()} XOF/${plan.duration}',
                      style: AppTheme.lightTheme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Fonctionnalités
          ...plan.features.map((feature) => Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    feature,
                    style: AppTheme.lightTheme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
}

class PaymentPlan {
  final String name;
  final int price;
  final String duration;
  final List<String> features;
  final Color color;
  final bool recommended;

  const PaymentPlan({
    required this.name,
    required this.price,
    required this.duration,
    required this.features,
    required this.color,
    required this.recommended,
  });
}
