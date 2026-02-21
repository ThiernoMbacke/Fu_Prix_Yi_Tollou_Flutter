// Test minimal pour le web : aucun Supabase, aucun Provider.
// Lancer avec : flutter run -d chrome -t lib/main_web_minimal.dart
// Si cette page s'affiche, le problème vient de l'init ou des dépendances dans main.dart.

import 'package:flutter/material.dart';

void main() {
  runApp(
    MaterialApp(
      title: 'Test web',
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              const Text('Si vous voyez ceci, Flutter web fonctionne.'),
              const SizedBox(height: 16),
              Text(
                'Revenez à main.dart pour déboguer Supabase / Provider.',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
