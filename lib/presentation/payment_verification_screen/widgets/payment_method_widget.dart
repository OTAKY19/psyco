import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class PaymentMethodWidget extends StatelessWidget {
  final String selectedMethod;
  final ValueChanged<String> onMethodChanged;
  final TextEditingController cardNumberController;
  final TextEditingController expiryController;
  final TextEditingController cvvController;
  final TextEditingController nameController;

  const PaymentMethodWidget({
    super.key,
    required this.selectedMethod,
    required this.onMethodChanged,
    required this.cardNumberController,
    required this.expiryController,
    required this.cvvController,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Méthode de paiement',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        SizedBox(height: 2.h),

        // Payment method options
        _buildPaymentMethodOption(
          context,
          id: 'card',
          icon: Icons.credit_card,
          title: 'Carte bancaire',
          subtitle: 'Visa, Mastercard, American Express',
        ),

        if (!kIsWeb) ...[
          SizedBox(height: 1.h),
          _buildPaymentMethodOption(
            context,
            id: 'apple_pay',
            icon: Icons.apple,
            title: 'Apple Pay',
            subtitle: 'Paiement sécurisé avec Touch ID / Face ID',
          ),
          SizedBox(height: 1.h),
          _buildPaymentMethodOption(
            context,
            id: 'google_pay',
            icon: Icons.g_mobiledata,
            title: 'Google Pay',
            subtitle: 'Paiement rapide et sécurisé',
          ),
        ],

        // Card details form (shown only when card is selected)
        if (selectedMethod == 'card') ...[
          SizedBox(height: 3.h),
          _buildCardForm(context),
        ],
      ],
    );
  }

  Widget _buildPaymentMethodOption(
    BuildContext context, {
    required String id,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final isSelected = selectedMethod == id;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected
          ? Theme.of(context)
              .colorScheme
              .primaryContainer
              .withValues(alpha: 0.3)
          : null,
      child: RadioListTile<String>(
        value: id,
        groupValue: selectedMethod,
        onChanged: (value) {
          if (value != null) {
            onMethodChanged(value);
          }
        },
        title: Row(
          children: [
            Container(
              width: 10.w,
              height: 10.w,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
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
          ],
        ),
        activeColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildCardForm(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(2.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de carte',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: cardNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Numéro de carte',
                hintText: '1234 5678 9012 3456',
                prefixIcon: const CustomIconWidget(iconName: 'credit_card'),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.payment, size: 20),
                    SizedBox(width: 1.w),
                    Icon(Icons.security, size: 20),
                  ],
                ),
              ),
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(19),
                _CardNumberFormatter(),
              ],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Numéro de carte requis';
                }
                if (value.replaceAll(' ', '').length < 13) {
                  return 'Numéro de carte invalide';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: expiryController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MM/AA',
                      hintText: '12/28',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                      _ExpiryDateFormatter(),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Date d\'expiration requise';
                      }
                      if (value.length < 5) {
                        return 'Format invalide';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 4.w),
                Expanded(
                  child: TextFormField(
                    controller: cvvController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'CVV',
                      hintText: '123',
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CVV requis';
                      }
                      if (value.length < 3) {
                        return 'CVV invalide';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Nom sur la carte',
                hintText: 'Jean Dupont',
                prefixIcon: CustomIconWidget(iconName: 'person_outline'),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nom du titulaire requis';
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final formatted = StringBuffer();

    for (int i = 0; i < text.length; i++) {
      if (i > 0 && i % 4 == 0) {
        formatted.write(' ');
      }
      formatted.write(text[i]);
    }

    return TextEditingValue(
      text: formatted.toString(),
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class _ExpiryDateFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text;

    if (text.length == 2 && oldValue.text.length == 1) {
      return TextEditingValue(
        text: '$text/',
        selection: TextSelection.collapsed(offset: 3),
      );
    }

    return newValue;
  }
}