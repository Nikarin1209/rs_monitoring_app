import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app_theme.dart';
import 'screens/splash_screen.dart';
import 'services/storage_service.dart';
import 'state/profile_provider.dart';
import 'state/diary_provider.dart';
import 'state/test_results_provider.dart';
import 'state/settings_provider.dart';

const _supabaseUrl = 'https://adexqoztgljywbsedsth.supabase.co';
const _supabaseAnonKey =
    'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFkZXhxb3p0Z2xqeXdic2Vkc3RoIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg0ODk1NjQsImV4cCI6MjA5NDA2NTU2NH0.e7cr3vGf9QmrjgmwYsdobYrRTwYk4Pp1aM9u26NTPRk';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnonKey);
  await initStorage();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider(create: (_) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => TestResultsProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
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
