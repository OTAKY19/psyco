import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../models/user.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  
  bool _isLoading = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _loadUserData() {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      _firstNameController.text = user.firstName ?? '';
      _lastNameController.text = user.lastName ?? '';
      _phoneController.text = user.phoneNumber ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      
      final result = await authService.updateProfile(
        firstName: _firstNameController.text.trim().isNotEmpty 
            ? _firstNameController.text.trim() : null,
        lastName: _lastNameController.text.trim().isNotEmpty 
            ? _lastNameController.text.trim() : null,
        phoneNumber: _phoneController.text.trim().isNotEmpty 
            ? _phoneController.text.trim() : null,
      );

      if (result.isSuccess) {
        setState(() {
          _successMessage = 'Profil mis à jour avec succès';
        });
        
        // Effacer le message de succès après 3 secondes
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() {
              _successMessage = null;
            });
          }
        });
      } else {
        setState(() {
          _errorMessage = result.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur lors de la mise à jour: $e';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updatePreferences(UserPreferences newPreferences) async {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      await authService.updateProfile(preferences: newPreferences);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la sauvegarde: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        final user = authService.currentUser;
        
        if (user == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Paramètres'),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Messages de feedback
                if (_successMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green[600], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          _successMessage!,
                          style: TextStyle(color: Colors.green[600], fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],

                if (_errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red[600], size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red[600], fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Section Profil
                _buildProfileSection(context, user),
                
                const SizedBox(height: 24),
                
                // Section Préférences
                _buildPreferencesSection(context, user.preferences),
                
                const SizedBox(height: 24),
                
                // Section Test
                _buildTestSection(context, user.preferences),
                
                const SizedBox(height: 24),
                
                // Section Notifications
                _buildNotificationsSection(context, user.preferences),
                
                const SizedBox(height: 24),
                
                // Section À propos
                _buildAboutSection(context),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileSection(BuildContext context, User user) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Informations personnelles',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Email (lecture seule)
                  TextFormField(
                    initialValue: user.email,
                    enabled: false,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Prénom
                  TextFormField(
                    controller: _firstNameController,
                    decoration: InputDecoration(
                      labelText: 'Prénom',
                      prefixIcon: const Icon(Icons.person_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Nom
                  TextFormField(
                    controller: _lastNameController,
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Téléphone
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Téléphone',
                      prefixIcon: const Icon(Icons.phone_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Bouton de mise à jour
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _updateProfile,
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Mettre à jour le profil'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreferencesSection(BuildContext context, UserPreferences preferences) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.palette, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Préférences d\'affichage',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Thème
            ListTile(
              leading: const Icon(Icons.brightness_6),
              title: const Text('Thème'),
              subtitle: Text(_getThemeLabel(preferences.theme)),
              trailing: PopupMenuButton<String>(
                initialValue: preferences.theme,
                onSelected: (String newTheme) {
                  final newPreferences = preferences.copyWith(theme: newTheme);
                  _updatePreferences(newPreferences);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'light', child: Text('Clair')),
                  const PopupMenuItem(value: 'dark', child: Text('Sombre')),
                  const PopupMenuItem(value: 'auto', child: Text('Automatique')),
                ],
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            
            // Langue
            ListTile(
              leading: const Icon(Icons.language),
              title: const Text('Langue'),
              subtitle: Text(_getLanguageLabel(preferences.language)),
              trailing: PopupMenuButton<String>(
                initialValue: preferences.language,
                onSelected: (String newLanguage) {
                  final newPreferences = preferences.copyWith(language: newLanguage);
                  _updatePreferences(newPreferences);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'fr', child: Text('Français')),
                  const PopupMenuItem(value: 'en', child: Text('English')),
                  const PopupMenuItem(value: 'ar', child: Text('العربية')),
                ],
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            
            // Sons
            SwitchListTile(
              secondary: const Icon(Icons.volume_up),
              title: const Text('Sons activés'),
              subtitle: const Text('Sons d\'interface et de feedback'),
              value: preferences.soundEnabled,
              onChanged: (bool value) {
                final newPreferences = preferences.copyWith(soundEnabled: value);
                _updatePreferences(newPreferences);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestSection(BuildContext context, UserPreferences preferences) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.quiz, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Paramètres de test',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Durée par défaut
            ListTile(
              leading: const Icon(Icons.timer),
              title: const Text('Durée par défaut'),
              subtitle: Text('${preferences.defaultTestDuration} minutes'),
              trailing: PopupMenuButton<int>(
                initialValue: preferences.defaultTestDuration,
                onSelected: (int newDuration) {
                  final newPreferences = preferences.copyWith(defaultTestDuration: newDuration);
                  _updatePreferences(newPreferences);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 15, child: Text('15 minutes')),
                  const PopupMenuItem(value: 30, child: Text('30 minutes')),
                  const PopupMenuItem(value: 45, child: Text('45 minutes')),
                  const PopupMenuItem(value: 60, child: Text('60 minutes')),
                ],
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            
            // Difficulté préférée
            ListTile(
              leading: const Icon(Icons.trending_up),
              title: const Text('Difficulté préférée'),
              subtitle: Text(_getDifficultyLabel(preferences.preferredDifficulty)),
              trailing: PopupMenuButton<String>(
                initialValue: preferences.preferredDifficulty,
                onSelected: (String newDifficulty) {
                  final newPreferences = preferences.copyWith(preferredDifficulty: newDifficulty);
                  _updatePreferences(newPreferences);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'facile', child: Text('Facile')),
                  const PopupMenuItem(value: 'moyen', child: Text('Moyen')),
                  const PopupMenuItem(value: 'difficile', child: Text('Difficile')),
                  const PopupMenuItem(value: 'adaptatif', child: Text('Adaptatif')),
                ],
                child: const Icon(Icons.arrow_drop_down),
              ),
            ),
            
            // Sauvegarde automatique
            SwitchListTile(
              secondary: const Icon(Icons.save),
              title: const Text('Sauvegarde automatique'),
              subtitle: const Text('Sauvegarder automatiquement la progression'),
              value: preferences.autoSaveProgress,
              onChanged: (bool value) {
                final newPreferences = preferences.copyWith(autoSaveProgress: value);
                _updatePreferences(newPreferences);
              },
            ),
            
            // Afficher les explications
            SwitchListTile(
              secondary: const Icon(Icons.help_outline),
              title: const Text('Afficher les explications'),
              subtitle: const Text('Montrer les explications après chaque question'),
              value: preferences.showExplanations,
              onChanged: (bool value) {
                final newPreferences = preferences.copyWith(showExplanations: value);
                _updatePreferences(newPreferences);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsSection(BuildContext context, UserPreferences preferences) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.notifications, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Notifications',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Notifications générales
            SwitchListTile(
              secondary: const Icon(Icons.notifications_active),
              title: const Text('Notifications activées'),
              subtitle: const Text('Recevoir toutes les notifications'),
              value: preferences.notificationsEnabled,
              onChanged: (bool value) {
                final newPreferences = preferences.copyWith(notificationsEnabled: value);
                _updatePreferences(newPreferences);
              },
            ),
            
            // Notifications push
            SwitchListTile(
              secondary: const Icon(Icons.phone_android),
              title: const Text('Notifications push'),
              subtitle: const Text('Recevoir les notifications sur l\'appareil'),
              value: preferences.pushNotifications,
              onChanged: preferences.notificationsEnabled ? (bool value) {
                final newPreferences = preferences.copyWith(pushNotifications: value);
                _updatePreferences(newPreferences);
              } : null,
            ),
            
            // Notifications email
            SwitchListTile(
              secondary: const Icon(Icons.email),
              title: const Text('Notifications par email'),
              subtitle: const Text('Recevoir les notifications par email'),
              value: preferences.emailNotifications,
              onChanged: preferences.notificationsEnabled ? (bool value) {
                final newPreferences = preferences.copyWith(emailNotifications: value);
                _updatePreferences(newPreferences);
              } : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info, color: theme.primaryColor),
                const SizedBox(width: 8),
                Text(
                  'À propos',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.app_registration),
              title: const Text('Version de l\'application'),
              subtitle: const Text('1.0.0'),
            ),
            
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Politique de confidentialité'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Ouvrir la politique de confidentialité
                _showInfoDialog(
                  context,
                  'Politique de confidentialité',
                  'Votre vie privée est importante pour nous. Cette application respecte votre confidentialité et ne collecte que les données nécessaires à son fonctionnement.',
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Conditions d\'utilisation'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Ouvrir les conditions d'utilisation
                _showInfoDialog(
                  context,
                  'Conditions d\'utilisation',
                  'En utilisant cette application, vous acceptez nos conditions d\'utilisation. Cette application est conçue pour vous aider à vous préparer aux tests psychotechniques.',
                );
              },
            ),
            
            ListTile(
              leading: const Icon(Icons.support),
              title: const Text('Support'),
              subtitle: const Text('Contactez-nous pour toute question'),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () {
                // Ouvrir les options de support
                _showInfoDialog(
                  context,
                  'Support',
                  'Pour toute question ou problème, contactez-nous à:\nsupport@douanetest.pro\n\nNous répondons généralement sous 24h.',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Text(content),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fermer'),
            ),
          ],
        );
      },
    );
  }

  String _getThemeLabel(String theme) {
    switch (theme) {
      case 'light': return 'Clair';
      case 'dark': return 'Sombre';
      case 'auto': return 'Automatique';
      default: return 'Automatique';
    }
  }

  String _getLanguageLabel(String language) {
    switch (language) {
      case 'fr': return 'Français';
      case 'en': return 'English';
      case 'ar': return 'العربية';
      default: return 'Français';
    }
  }

  String _getDifficultyLabel(String difficulty) {
    switch (difficulty) {
      case 'facile': return 'Facile';
      case 'moyen': return 'Moyen';
      case 'difficile': return 'Difficile';
      case 'adaptatif': return 'Adaptatif';
      default: return 'Adaptatif';
    }
  }
}
