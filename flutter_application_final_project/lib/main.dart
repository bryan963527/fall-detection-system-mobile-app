import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/relatives_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/health_setup_screen.dart';
import 'screens/settings_screen.dart';
import 'constants/app_colors.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GyroStep - Fall Detection System',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          brightness: Brightness.light,
        ),
        fontFamily: 'Roboto',
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/health-setup': (context) => const HealthSetupScreen(),
        '/': (context) => const HomeScreen(),
        '/history': (context) => const HistoryScreen(),
        '/relatives': (context) => const RelativesScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
      onGenerateRoute: (settings) {
        // Handle ProfileScreen with or without userId parameter
        if (settings.name == '/profile') {
          final userId = settings.arguments as String?;
          return MaterialPageRoute(
            builder: (context) => ProfileScreen(userId: userId),
            settings: settings,
          );
        }
        return null;
      },
    );
  }
}
