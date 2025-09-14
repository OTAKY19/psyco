import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ActivationPromptWidget extends StatelessWidget {
  final VoidCallback onActivate;
  final String message;

  const ActivationPromptWidget({
    super.key,
    required this.onActivate,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icône de verrouillage
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock,
              size: 40,
              color: Colors.orange,
            ),
          ),
          
          SizedBox(height: 24),
          
          // Titre
          Text(
            'Activation requise',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16),
          
          // Message
          Text(
            message,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 32),
          
          // Avantages
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.blue.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avantages de l\'activation:',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[800],
                  ),
                ),
                SizedBox(height: 16),
                _buildBenefitItem(
                  '✓ Accès illimité à tous les examens blancs',
                  Icons.quiz,
                ),
                _buildBenefitItem(
                  '✓ Corrections détaillées avec explications',
                  Icons.assignment_turned_in,
                ),
                _buildBenefitItem(
                  '✓ Statistiques de progression avancées',
                  Icons.trending_up,
                ),
                _buildBenefitItem(
                  '✓ Mode hors ligne',
                  Icons.offline_bolt,
                ),
                _buildBenefitItem(
                  '✓ Support prioritaire',
                  Icons.support_agent,
                ),
                _buildBenefitItem(
                  '✓ Mises à jour gratuites',
                  Icons.system_update,
                ),
              ],
            ),
          ),
          
          SizedBox(height: 32),
          
          // Bouton d'activation
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onActivate,
              icon: Icon(Icons.rocket_launch),
              label: Text(
                'Activer l\'application',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
              ),
            ),
          ),
          
          SizedBox(height: 16),
          
          // Prix
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer, color: Colors.green, size: 16),
                SizedBox(width: 4),
                Text(
                  'Seulement 5000 FCFA',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.blue,
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[700],
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
