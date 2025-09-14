import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../core/app_export.dart';
import '../routes/app_routes.dart';
import '../presentation/admin_screen/admin_screen.dart';
import '../services/activation_service.dart';
import '../services/demo_service.dart';
import '../services/user_state_service.dart';
import '../widgets/demo_popup_widget.dart';
import '../widgets/payment_suggestion_widget.dart';
import '../widgets/simulation_demo_widget.dart';
import '../widgets/feature_blocked_widget.dart';
import '../widgets/demo_choice_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _tapCount = 0;
  DateTime? _lastTapTime;
  bool _isAdminMode = false;

  void _showAdminAccess() {
    final now = DateTime.now();

    // Reset le compteur si plus de 2 secondes se sont écoulées
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 2) {
      _tapCount = 0;
    }

    _tapCount++;
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      Navigator.pushNamed(context, AppRoutes.admin);
    }
  }

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    await _checkAdminMode();
    await _checkFirstTimeUser();
  }

  Future<void> _checkAdminMode() async {
    // Vérifier le mode admin au démarrage
    // Cette logique sera implémentée dans AdminService
  }

  Future<void> _checkFirstTimeUser() async {
    final userStateService = UserStateService();
    final hasCompletedDemo = await userStateService.hasCompletedDemo();
    final isActivated = await userStateService.isActivated();

    if (mounted) {
      // Si l'utilisateur n'a jamais utilisé l'app, montrer le choix
      if (!hasCompletedDemo && !isActivated) {
        await _showDemoChoice();
      }
      // Sinon, vérifier s'il faut montrer d'autres séquences
      else {
        await _checkDemoSequence();
      }
    }
  }

  Future<void> _showDemoChoice() async {
    await DemoChoiceWidget.show(context);
  }

  Future<void> _checkDemoSequence() async {
    final demoService = DemoService();
    final nextStep = await demoService.getNextDemoStep();

    if (mounted) {
      switch (nextStep) {
        case DemoStep.showDemo:
          await _showDemo();
          break;
        case DemoStep.showPaymentSuggestion:
          await _showPaymentSuggestion();
          break;
        case DemoStep.showSimulationDemo:
          await _showSimulationDemo();
          break;
        case DemoStep.none:
          // Rien à afficher
          break;
      }
    }
  }

  Future<void> _showDemo() async {
    await DemoPopupWidget.show(
      context,
      () async {
        final demoService = DemoService();
        await demoService.markDemoShown();
        await demoService.markFirstLoginCompleted();
        await _checkDemoSequence(); // Vérifier l'étape suivante
      },
      () async {
        final demoService = DemoService();
        await demoService.markDemoShown();
        await demoService.markFirstLoginCompleted();
        await _checkDemoSequence(); // Vérifier l'étape suivante
      },
    );
  }

  Future<void> _showPaymentSuggestion() async {
    await PaymentSuggestionWidget.show(
      context,
      () async {
        final demoService = DemoService();
        await demoService.markPaymentSuggestionShown();
        // Rediriger vers l'écran d'activation
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.activationScreen);
        }
      },
      () async {
        final demoService = DemoService();
        await demoService.markPaymentSuggestionShown();
        await _checkDemoSequence(); // Vérifier l'étape suivante
      },
    );
  }

  Future<void> _showSimulationDemo() async {
    await SimulationDemoWidget.show(
      context,
      () async {
        final demoService = DemoService();
        await demoService.markSimulationDemoCompleted();
        // Démo terminée, rien d'autre à faire
      },
      () async {
        final demoService = DemoService();
        await demoService.markSimulationDemoCompleted();
        // Rediriger vers l'écran d'activation
        if (mounted) {
          Navigator.pushNamed(context, AppRoutes.activationScreen);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: _buildDrawer(context),
      appBar: AppBar(
        title: const Text('PsychoTest+'),
        centerTitle: true,
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
            tooltip: 'Menu avancé',
          ),
        ),
        actions: [
          // ACCÈS ADMIN: Appuyer 5x sur le titre de l'AppBar
          // pour accéder à l'écran d'administration (AdminScreen)
          GestureDetector(
            onTap: () => _showAdminAccess(),
            child: Container(
              padding: EdgeInsets.all(8),
              child: Icon(Icons.settings, color: Colors.transparent),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // En-tête de bienvenue
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _isAdminMode
                    ? [Colors.red, Colors.red.withValues(alpha:0.8)]
                    : [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                      ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _isAdminMode ? 'MODE ADMIN - PsychoTest+' : 'Bienvenue sur PsychoTest+',
                          style: TextStyle(
                            fontSize: 24.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      if (_isAdminMode)
                        Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 24,
                        ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Préparez-vous efficacement aux concours de la douane béninoise',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.white.withValues(alpha:0.9),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 16),

            // Widget de statut d'abonnement
            _buildSubscriptionStatus(),

            SizedBox(height: 24),
            
            // Options principales
            Text(
              'Choisissez votre mode de préparation',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            SizedBox(height: 16),
            
            // Cartes d'options principales (simplifiées)
            _buildOptionCard(
              context,
              'Tests d\'Entraînement',
              'Entraînez-vous avec des tests par catégories',
              Icons.quiz,
              Colors.blue,
              () {
                Navigator.pushNamed(context, AppRoutes.examBlanc);
              },
            ),

            _buildOptionCard(
              context,
              'Bibliothèque de Tests',
              'Explorez tous les tests avec tri avancé',
              Icons.library_books,
              Colors.orange,
              () async {
                final activationService = ActivationService();
                final isActivated = await activationService.isAppActivated();

                if (mounted) {
                  if (isActivated) {
                    Navigator.pushNamed(context, AppRoutes.testLibraryDashboard);
                  } else {
                    await FeatureBlockedWidget.show(
                      context,
                      featureName: 'Bibliothèque de Tests',
                      description: 'Accédez à des milliers de questions organisées par catégories et niveaux de difficulté.',
                      iconName: 'library_books',
                      color: Colors.orange,
                    );
                  }
                }
              },
            ),

            _buildOptionCard(
              context,
              'Examens Blancs',
              'Simulez les vrais examens du concours',
              Icons.assignment,
              Colors.indigo,
              () async {
                // Vérifier si l'app est activée avant d'accéder aux examens
                final activationService = ActivationService();
                final isActivated = await activationService.isAppActivated();

                if (mounted) {
                  if (isActivated) {
                    Navigator.pushNamed(context, AppRoutes.examScreen);
                  } else {
                    // Rediriger vers l'écran d'activation
                    Navigator.pushNamed(context, AppRoutes.activationScreen);
                  }
                }
              },
            ),

            _buildOptionCard(
              context,
              'Suivi des Progrès',
              'Consultez vos statistiques et performances',
              Icons.trending_up,
              Colors.purple,
              () async {
                final activationService = ActivationService();
                final isActivated = await activationService.isAppActivated();

                if (mounted) {
                  if (isActivated) {
                    Navigator.pushNamed(context, AppRoutes.progressTracking);
                  } else {
                    await FeatureBlockedWidget.show(
                      context,
                      featureName: 'Suivi des Progrès',
                      description: 'Analysez vos performances avec des rapports détaillés et des recommandations personnalisées.',
                      iconName: 'trending_up',
                      color: Colors.purple,
                    );
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // En-tête du drawer
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.primary.withValues(alpha:0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menu Avancé',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Accès aux fonctionnalités premium',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha:0.8),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),

          // Section Paiements
          _buildDrawerSection('Paiements & Monétisation'),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.green),
            title: Text('Paiement Mobile Money'),
            subtitle: Text('Effectuer un paiement'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.mobileMoneyPayment);
            },
          ),
          ListTile(
            leading: Icon(Icons.receipt, color: Colors.orange),
            title: Text('Confirmation Paiement'),
            subtitle: Text('Vérifier un paiement'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.paymentConfirmation);
            },
          ),
          ListTile(
            leading: Icon(Icons.verified, color: Colors.purple),
            title: Text('Vérification Paiement'),
            subtitle: Text('Statut des paiements'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.paymentVerificationScreen);
            },
          ),

          // Section Tests Avancés (simplifié)
          _buildDrawerSection('Tests Avancés'),
          ListTile(
            leading: Icon(Icons.library_books, color: Colors.orange),
            title: Text('Bibliothèque Complète'),
            subtitle: Text('Tous les tests disponibles'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.testLibraryDashboard);
            },
          ),
          ListTile(
            leading: Icon(Icons.science, color: Colors.indigo),
            title: Text('Simulations'),
            subtitle: Text('Examens simulés complets'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.simulationSelection);
            },
          ),

          // Section Limites et Flux
          _buildDrawerSection('Limites & Flux'),
          ListTile(
            leading: Icon(Icons.lock_clock, color: Colors.red),
            title: Text('Limite Tests Gratuits'),
            subtitle: Text('Gérer les limitations'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.freeTestsLimit);
            },
          ),
          ListTile(
            leading: Icon(Icons.integration_instructions, color: Colors.amber),
            title: Text('Flux d\'Intégration'),
            subtitle: Text('Configuration avancée'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRoutes.integrationFlowScreen);
            },
          ),

          // Section Administration (si en mode admin)
          if (_isAdminMode) ...[
            _buildDrawerSection('Administration'),
            ListTile(
              leading: Icon(Icons.admin_panel_settings, color: Colors.red),
              title: Text('Panneau Admin'),
              subtitle: Text('Administration complète'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.admin);
              },
            ),
          ],

          // Section Informations
          Divider(),
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ℹ️ Informations',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Ces fonctionnalités sont en développement actif. Certaines peuvent nécessiter une activation préalable.',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerSection(String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSubscriptionStatus() {
    return FutureBuilder<Map<String, dynamic>>(
      future: ActivationService().getActivationStatus(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 12),
                Text('Chargement du statut...'),
              ],
            ),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Erreur lors du chargement du statut',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          );
        }

        final status = snapshot.data ?? {};
        final isActivated = status['is_activated'] ?? false;
        final remainingDays = status['remaining_days'] ?? 0;
        final subscription = status['subscription'] as Map<String, dynamic>?;

        return Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                isActivated ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                isActivated ? Colors.green.withValues(alpha: 0.05) : Colors.orange.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActivated ? Colors.green.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRoutes.subscriptionScreen),
            borderRadius: BorderRadius.circular(12),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isActivated ? Colors.green : Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isActivated ? Icons.verified : Icons.subscriptions,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isActivated ? 'Abonnement Actif' : 'Abonnement Requis',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: isActivated ? Colors.green : Colors.orange,
                        ),
                      ),
                      SizedBox(height: 2),
                      if (subscription != null) ...[
                        Text(
                          subscription['name'] as String? ?? 'Aucun abonnement',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.black87,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (isActivated && remainingDays > 0) ...[
                          SizedBox(height: 2),
                          Text(
                            '$remainingDays jours restants',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.green,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ] else ...[
                        Text(
                          'Cliquez pour gérer votre abonnement',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey[400],
                  size: 16,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: color,
                    size: 32,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
