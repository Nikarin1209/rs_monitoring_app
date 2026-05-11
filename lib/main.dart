import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'state/profile_provider.dart';
import 'state/diary_provider.dart';
import 'state/test_results_provider.dart';
import 'state/settings_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Hive must be open before providers call load() synchronously below.
  await initStorage();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => ProfileProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => DiaryProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => TestResultsProvider()..load(),
        ),
        ChangeNotifierProvider(
          create: (_) => SettingsProvider()..load(),
        ),
      ],
      child: const NeuroLifeApp(),
    ),
  );
}

class NeuroLifeApp extends StatelessWidget {
  const NeuroLifeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NeuroLife',
      debugShowCheckedModeBanner: false,
      theme: nlTheme(),
      home: const SplashScreen(),
    );
  }
}
