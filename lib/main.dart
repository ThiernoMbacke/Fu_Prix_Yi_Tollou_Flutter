// lib/main.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/api_config.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'services/token_storage.dart';
import 'services/api_service.dart';
import 'services/auth_service.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/auth_method_screen.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/phone_auth_screen.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/email_auth_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
    };
  }

  // Important : runApp() tout de suite pour que le premier frame s'affiche (évite page blanche web).
  // L'init Supabase se fait ensuite dans _AppLoader.
  runApp(const _AppLoader());
}

/// Affiche un écran de chargement immédiatement, puis lance l'init Supabase et affiche l'app ou une erreur.
class _AppLoader extends StatefulWidget {
  const _AppLoader();

  @override
  State<_AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<_AppLoader> {
  Widget? _app;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      await ApiConfig.init();
      if (SupabaseConfig.isPlaceholderConfiguration) {
        throw StateError(
          'Configuration Supabase incomplète (fichier lib/config/supabase_config.dart).\n\n'
          '• supabaseUrl : https://<référence>.supabase.co — même ref que dans l’hôte Postgres '
          '(db.<ref>.supabase.co → https://<ref>.supabase.co). Dashboard → Settings → API → Project URL.\n'
          '• supabaseAnonKey : clé « anon » « public » (très longue), même écran.\n\n'
          'Sans cela, les requêtes partent vers une fausse URL → net::ERR_NAME_NOT_RESOLVED.',
        );
      }
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        anonKey: SupabaseConfig.supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 15),
        onTimeout: () => throw TimeoutException('Supabase: délai dépassé (vérifiez CORS / réseau).'),
      );
    } on TimeoutException catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message ?? e.toString());
      return;
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Supabase init: $e');
        debugPrint(stack.toString());
      }
      if (!mounted) return;
      setState(() => _error = e.toString());
      return;
    }

    if (!mounted) return;
    final tokenStorage = TokenStorage();
    final apiService = ApiService(tokenStorage: tokenStorage);
    final authService = AuthService(tokenStorage: tokenStorage, apiService: apiService);
    setState(() {
      _app = MyApp(authService: authService, apiService: apiService);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _ErrorApp(message: _error!);
    }
    if (_app != null) {
      return _app!;
    }
    // Premier frame : uniquement ceci, sans dépendance à Supabase.
    return MaterialApp(
      title: 'Fou Prix - Yi Tollou Tay',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2E7D32)),
        useMaterial3: true,
      ),
      home: Scaffold(
        backgroundColor: const Color(0xFF2E7D32),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.shopping_basket, size: 64, color: Colors.white),
              const SizedBox(height: 24),
              const Text(
                'Fou Prix - Yi Tollou Tay',
                style: TextStyle(fontSize: 22, color: Colors.white, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

/// App minimal affichée si l'initialisation (ex. Supabase) échoue — évite la page blanche.
class _ErrorApp extends StatelessWidget {
  final String message;

  const _ErrorApp({required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fou Prix - Yi Tollou Tay',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Erreur d\'initialisation'),
          backgroundColor: AppTheme.primaryGreen,
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Impossible de démarrer l\'application.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Text(message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 24),
                const Text(
                  'Vérifiez la console du navigateur (F12) pour plus de détails.',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;

  const MyApp({super.key, required this.authService, required this.apiService});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(authService: authService)),
        Provider<ApiService>.value(value: apiService),
      ],
      child: MaterialApp(
        title: 'Fou Prix - Yi Tollou Tay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const SplashScreen(),
        routes: {
          '/auth-method': (context) => const AuthMethodScreen(),
          '/phone-auth': (context) => const PhoneAuthScreen(),
          '/email-auth': (context) => const EmailAuthScreen(),
        },
      ),
    );
  }
}
