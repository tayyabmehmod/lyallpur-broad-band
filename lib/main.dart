import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart' hide FirebaseService;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'theme.dart';
import 'services/firebase_service.dart';
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
    if (Firebase.apps.isNotEmpty) {
      // Enable Firestore offline persistence/cache to make load times instant
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      // Start background syncing to prevent stream buffer/delays on tab changes
      FirebaseService.startSyncing();
    }
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
      onGenerateRoute: (settings) {
        Widget builder;
        switch (settings.name) {
          case '/login':
            builder = const LoginScreen();
            break;
          case '/dashboard':
            builder = const DashboardScreen();
            break;
          case '/clients':
            builder = const ClientsScreen();
            break;
          case '/area':
            builder = const AreaScreen();
            break;
          case '/new_client':
            builder = const NewClientScreen();
            break;
          case '/client_detail':
            builder = const ClientDetailScreen();
            break;
          case '/history':
            builder = const HistoryScreen();
            break;
          default:
            builder = const LoginScreen();
        }

        // Apply instant (zero-duration) transitions for main sidebar routes
        final isSidebarRoute = settings.name == '/dashboard' ||
            settings.name == '/clients' ||
            settings.name == '/area' ||
            settings.name == '/new_client' ||
            settings.name == '/history';

        if (isSidebarRoute) {
          return PageRouteBuilder(
            settings: settings,
            pageBuilder: (context, animation, secondaryAnimation) => builder,
            transitionDuration: Duration.zero,
            reverseTransitionDuration: Duration.zero,
          );
        }

        return MaterialPageRoute(
          settings: settings,
          builder: (context) => builder,
        );
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
