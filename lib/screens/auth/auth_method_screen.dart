// lib/screens/auth/auth_method_screen.dart
import 'package:flutter/material.dart';
import 'package:fu_prix_yi_tollou_tay/config/app_theme.dart';

class AuthMethodScreen extends StatelessWidget {
  const AuthMethodScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Se connecter'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
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
              
              // Titre
              const Text(
                'Choisissez votre méthode de connexion',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 40),
              
              // Bouton Téléphone
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
              
              // Bouton Email
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
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}