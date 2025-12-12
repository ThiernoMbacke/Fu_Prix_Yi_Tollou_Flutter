// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'config/supabase_config.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/auth_method_screen.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/phone_auth_screen.dart';
import 'package:fu_prix_yi_tollou_tay/screens/auth/email_auth_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialiser Supabase
  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  // Remplacer par :
//await Supabase.instance.client.auth.signInWithOtp(
 // email: 'dummy@example.com', // Email factice pour l'initialisation
  //shouldCreateUser: false,
//);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp(
        title: 'Fou Prix - Yi Tollou Tay',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,

        // ✅ Écran de démarrage
        home: const SplashScreen(),

        // ✅ Routes nommées
        routes: {
          '/auth-method': (context) => const AuthMethodScreen(),
          '/phone-auth': (context) => const PhoneAuthScreen(),
          '/email-auth': (context) => const EmailAuthScreen(),
        },
      ),
    );
  }
}
