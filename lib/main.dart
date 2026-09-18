import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/app_export.dart';
import 'services/user_state_service.dart';
import 'services/app_state_service.dart';
import 'services/test_service.dart';
import 'services/premium_state_notifier.dart';
import 'router/app_router.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserStateService()),
        ChangeNotifierProvider(create: (context) => AppStateService()),
        ChangeNotifierProvider(create: (context) => TestService()),
        ChangeNotifierProvider(
            create: (context) => PremiumStateNotifier()),
      ],
      child: const PsychoTestApp(),
    ),
  );
}

class PsychoTestApp extends StatelessWidget {
  const PsychoTestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'PsychoTest+',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    );
  }
}
