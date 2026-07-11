import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/clients_screen.dart';
import 'screens/area_screen.dart';
import 'screens/new_client_screen.dart';
import 'screens/client_detail_screen.dart';
import 'screens/history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase using the generated firebase_options.dart configurations
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase core initialization error: $e');
    debugPrint('Please configure Firebase using FlutterFire CLI to run backend features.');
  }

  // Detect if a user is currently logged in (for auto-login)
  final bool loggedIn = Firebase.apps.isNotEmpty && FirebaseAuth.instance.currentUser != null;

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;
  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lyallpur Telecom Broadband',
      theme: AppTheme.themeData,
      initialRoute: loggedIn ? '/dashboard' : '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/clients': (context) => const ClientsScreen(),
        '/area': (context) => const AreaScreen(),
        '/new_client': (context) => const NewClientScreen(),
        '/client_detail': (context) => const ClientDetailScreen(),
        '/history': (context) => const HistoryScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
