// lib/screens/auth/auth_method_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fu_prix_yi_tollou_tay/config/api_config.dart';
import 'package:fu_prix_yi_tollou_tay/config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../home/home_screen.dart';

class AuthMethodScreen extends StatefulWidget {
  const AuthMethodScreen({super.key});

  @override
  State<AuthMethodScreen> createState() => _AuthMethodScreenState();
}

class _AuthMethodScreenState extends State<AuthMethodScreen> {
  bool _demoLoading = false;

  Future<void> _connectDemo(String demoUser) async {
    setState(() => _demoLoading = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.signInWithDemo(demoUser);
    if (!mounted) return;
    setState(() => _demoLoading = false);
    if (ok) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      final showConfig = auth.error != null &&
          auth.error!.toLowerCase().contains('joindre le serveur');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Erreur connexion démo'),
          backgroundColor: Colors.red,
          action: showConfig
              ? SnackBarAction(
                  label: 'Configurer',
                  textColor: Colors.white,
                  onPressed: () => _showBackendUrlDialog(context),
                )
              : null,
        ),
      );
    }
  }

  Future<void> _showBackendUrlDialog(BuildContext context) async {
    final current = ApiConfig.baseUrl;
    final controller = TextEditingController(text: current);
    final formKey = GlobalKey<FormState>();

    if (!context.mounted) return;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('URL du serveur'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sur téléphone branché en USB, indiquez l\'IP de votre PC (ex. 192.168.1.203:8080). PC et téléphone sur le même Wi‑Fi.',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'URL (ex. http://192.168.1.203:8080)',
                  hintText: '192.168.1.203:8080',
                ),
                keyboardType: TextInputType.url,
                autofillHints: const [AutofillHints.url],
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Indiquez l\'URL';
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.of(ctx).pop(true);
              }
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );

    if (saved == true && controller.text.trim().isNotEmpty) {
      await ApiConfig.setStoredBaseUrl(controller.text.trim());
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'URL enregistrée. Redémarrez l\'application pour l\'appliquer.',
          ),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // Logo/Illustration
              Container(
                width: 150,
                height: 150,
                margin: const EdgeInsets.only(bottom: 40),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_person,
                  size: 70,
                  color: AppTheme.primaryGreen,
                ),
              ),
              
              const Text(
                'Choisissez votre méthode de connexion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              ElevatedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/phone-auth'),
                icon: const Icon(Icons.phone_android),
                label: const Text('Continuer avec le téléphone'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/email-auth'),
                icon: const Icon(Icons.email_outlined),
                label: const Text('Continuer avec l\'email'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 16),
              Text(
                'Mode démo (sans code)',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _demoLoading
                          ? null
                          : () => _connectDemo('test1'),
                      icon: const Icon(Icons.person_outline, size: 20),
                      label: const Text('Test 1'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _demoLoading
                          ? null
                          : () => _connectDemo('test2'),
                      icon: const Icon(Icons.person_outline, size: 20),
                      label: const Text('Test 2'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              if (_demoLoading)
                const Padding(
                  padding: EdgeInsets.only(top: 12),
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
              const SizedBox(height: 24),
              TextButton.icon(
                onPressed: () => _showBackendUrlDialog(context),
                icon: const Icon(Icons.settings_ethernet, size: 18),
                label: const Text('Configurer l\'URL du serveur'),
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}