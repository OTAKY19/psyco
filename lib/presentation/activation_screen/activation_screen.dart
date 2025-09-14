import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:provider/provider.dart'; // Importation ajoutée

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../services/one_time_purchase_service.dart'; // Remplacé ActivationService
import '../../services/user_state_service.dart'; // Pour mettre à jour l'état premium

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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Choisir votre opérateur",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),

            // MTN Mobile Money
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: beninProviders['mtn']!.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.phone_android, color: Colors.white),
              ),
              title: Text("MTN Mobile Money"),
              subtitle: Text(
                  "${beninProviders['mtn']!.prefixes.join(', ')} • Code: *133#"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _initiatePayment(context, 'mtn');
              },
            ),

            Divider(),

            // Moov Money
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: beninProviders['moov']!.color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              title: Text("Moov Money"),
              subtitle: Text(
                  "${beninProviders['moov']!.prefixes.join(', ')} • Code: *555#"),
              trailing: Icon(Icons.arrow_forward_ios),
              onTap: () {
                Navigator.pop(context);
                _initiatePayment(context, 'moov');
              },
            ),
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
                "Veuillez entrer votre numéro de téléphone ${beninProviders[provider]!.name} pour procéder au paiement de ${PsychoTestOffer.PRICE_FCFA} FCFA."),
            SizedBox(height: 20),
            TextField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
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
            child: Text("Annuler"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processPayment(context);
            },
            child: Text("Payer"),
          ),
        ],
      ),
    );
  }

  Future<void> _processPayment(BuildContext context) async {
    if (_selectedProvider == null || _phoneNumberController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Veuillez sélectionner un opérateur et entrer un numéro.")),
      );
      return;
    }

    setState(() {
      _isProcessingPayment = true;
    });

    try {
      final result = await _purchaseService.purchaseFullAccess(
          _selectedProvider!, _phoneNumberController.text);

      if (mounted) {
        if (result.success) {
          _showUssdInstructions(context, result);
          // Mettre à jour l'état premium après un paiement réussi (simulation)
          Provider.of<UserStateService>(context, listen: false).setLifetimeAccess(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(result.errorMessage ?? "Erreur de paiement inconnue")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du traitement du paiement: $e'),
            backgroundColor: AppTheme.lightTheme.colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessingPayment = false;
        });
      }
    }
  }

  void _showUssdInstructions(BuildContext context, PaymentResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text("Action requise"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                "Pour finaliser votre achat, veuillez composer le code USSD suivant sur votre téléphone:"),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.all(10),
              color: Colors.grey[200],
              child: SelectableText(
                result.ussdCode!,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            SizedBox(height: 10),
            Text(
                "Après avoir composé le code, suivez les instructions sur votre écran pour confirmer le paiement de ${result.amount} FCFA."),
            SizedBox(height: 20),
            Text("Nous vérifierons automatiquement votre paiement."),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // Optionnel: Rediriger ou afficher un écran de vérification
              Navigator.pushReplacementNamed(context, AppRoutes.initial);
            },
            child: Text("Compris"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Débloquer PsychoTest+")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // Hero section
            Container(
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[400]!, Colors.purple[400]!],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(Icons.star, size: 64, color: Colors.white),
                  Text("Version Complète",
                      style: TextStyle(
                          fontSize: 24,
                          color: Colors.white,
                          fontWeight: FontWeight.bold)),
                  Text("Achat unique • Accès à vie",
                      style: TextStyle(fontSize: 16, color: Colors.white70)),
                ],
              ),
            ),

            SizedBox(height: 24),

            // Prix
            Container(
              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.green[200]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("1.500",
                      style: TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.green[700])),
                  Text(" FCFA",
                      style: TextStyle(fontSize: 18, color: Colors.green[600])),
                  SizedBox(width: 8),
                  Text("(~2,3€)",
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Liste des avantages
            ...PsychoTestOffer.fullAccess.benefits.map((benefit) => Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 20),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text(benefit, style: TextStyle(fontSize: 16))),
                    ],
                  ),
                )),

            SizedBox(height: 32),

            // Bouton d'achat
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isProcessingPayment ? null : () => _showPaymentMethods(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[600],
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: _isProcessingPayment
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : Text("Débloquer maintenant - 1.500 FCFA",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),

            SizedBox(height: 16),

            // Garantie
            Text("🛡️ Paiement sécurisé • Accès immédiat après paiement",
                style: TextStyle(color: Colors.grey[600], fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
