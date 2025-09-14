import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';
import '../../services/admin_service.dart';
import '../../services/subscription_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminService _adminService = AdminService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isAdminMode = false;
  bool _isLoading = false;
  Map<String, dynamic> _debugInfo = {};

  @override
  void initState() {
    super.initState();
    _checkAdminMode();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _checkAdminMode() async {
    final isAdmin = await _adminService.isAdminModeEnabled();
    setState(() {
      _isAdminMode = isAdmin;
    });
    
    if (isAdmin) {
      _loadDebugInfo();
    }
  }

  Future<void> _loadDebugInfo() async {
    final info = await _adminService.getDebugInfo();
    setState(() {
      _debugInfo = info;
    });
  }

  Future<void> _enableAdminMode() async {
    if (_passwordController.text.isEmpty) {
      _showSnackBar('Veuillez entrer le mot de passe admin');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final success = await _adminService.enableAdminMode(_passwordController.text);
    
    setState(() {
      _isLoading = false;
    });

    if (success) {
      setState(() {
        _isAdminMode = true;
      });
      _loadDebugInfo();
      _showSnackBar('Mode admin activé');
      _passwordController.clear();
    } else {
      _showSnackBar('Mot de passe incorrect');
    }
  }

  Future<void> _disableAdminMode() async {
    await _adminService.disableAdminMode();
    setState(() {
      _isAdminMode = false;
      _debugInfo = {};
    });
    _showSnackBar('Mode admin désactivé');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Mode Admin'),
        centerTitle: true,
        backgroundColor: _isAdminMode ? Colors.red : Colors.blue,
        actions: [
          if (_isAdminMode)
            IconButton(
              onPressed: _disableAdminMode,
              icon: Icon(Icons.logout),
              tooltip: 'Désactiver le mode admin',
            ),
        ],
      ),
      body: _isAdminMode ? _buildAdminPanel() : _buildLoginForm(),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.admin_panel_settings,
            size: 80,
            color: Colors.blue,
          ),
          SizedBox(height: 24),
          Text(
            'Connexion Admin',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Entrez le mot de passe admin pour accéder aux contrôles de test',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 32),
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Mot de passe admin',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lock),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _enableAdminMode,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white)
                  : Text('Se connecter'),
            ),
          ),
          SizedBox(height: 16),
          Text(
            'Mot de passe par défaut: admin123',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.grey[500],
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminPanel() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête du mode admin
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Mode Admin Activé - Utilisé uniquement pour les tests',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.red[800],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          SizedBox(height: 24),
          
          // Informations de debug
          _buildDebugInfo(),
          
          SizedBox(height: 24),
          
          // Contrôles de test
          _buildTestControls(),
          
          SizedBox(height: 24),
          
          // Contrôles de réinitialisation
          _buildResetControls(),
        ],
      ),
    );
  }

  Widget _buildDebugInfo() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Informations de Debug',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildInfoRow('Mode Admin', _isAdminMode ? 'Activé' : 'Désactivé'),
            _buildInfoRow('Utilisateur Premium', _debugInfo['isPremiumUser'] == true ? 'Oui' : 'Non'),
            _buildInfoRow('Tests Gratuits Utilisés', '${_debugInfo['freeTestsUsed']}'),
            _buildInfoRow('Méthode de Paiement', _debugInfo['paymentMethod'] ?? 'Aucune'),
            _buildInfoRow('Type d\'Abonnement', _debugInfo['subscriptionType'] ?? 'Aucun'),
            _buildInfoRow('Date d\'Abonnement', _debugInfo['subscriptionDate'] ?? 'Aucune'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildTestControls() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contrôles de Test',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildControlButton(
              'Activer Premium (Test)',
              'Force l\'activation du compte premium',
              Icons.star,
              Colors.green,
              () async {
                await _adminService.forceActivatePremium();
                _loadDebugInfo();
                _showSnackBar('Compte premium activé (test)');
              },
            ),
            _buildControlButton(
              'Désactiver Premium (Test)',
              'Force la désactivation du compte premium',
              Icons.star_border,
              Colors.orange,
              () async {
                await _adminService.forceDeactivatePremium();
                _loadDebugInfo();
                _showSnackBar('Compte premium désactivé (test)');
              },
            ),
            _buildControlButton(
              'Définir Tests Gratuits',
              'Définit le nombre de tests gratuits restants',
              Icons.quiz,
              Colors.blue,
              () => _showSetFreeTestsDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResetControls() {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Réinitialisation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16),
            _buildControlButton(
              'Réinitialiser Tout',
              'Remet à zéro tous les compteurs et données',
              Icons.refresh,
              Colors.red,
              () => _showResetConfirmDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton(
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: color, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  void _showSetFreeTestsDialog() {
    final controller = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Définir Tests Gratuits'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Nombre de tests gratuits restants:'),
            SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nombre de tests',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final count = int.tryParse(controller.text);
              if (count != null && count >= 0) {
                await _adminService.setFreeTestsCount(count);
                _loadDebugInfo();
                _showSnackBar('Tests gratuits définis à $count');
                Navigator.pop(context);
              } else {
                _showSnackBar('Veuillez entrer un nombre valide');
              }
            },
            child: Text('Définir'),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirmer la Réinitialisation'),
        content: Text(
          'Êtes-vous sûr de vouloir réinitialiser tous les compteurs et données ? '
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _adminService.resetAllCounters();
              _loadDebugInfo();
              _showSnackBar('Toutes les données ont été réinitialisées');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}
