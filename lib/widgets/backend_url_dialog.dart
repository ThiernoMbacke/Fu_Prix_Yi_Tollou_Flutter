import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';

/// GET / sur une base donnée — n’utilise pas l’[ApiService] global (test avant enregistrement).
Future<String> probeBackendUrl(String rawUrl) async {
  final base = ApiConfig.normalizeBackendUrl(rawUrl);
  final dio = Dio(
    BaseOptions(
      baseUrl: base,
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {'Accept': 'application/json'},
    ),
  );
  try {
    final r = await dio.get<Object>('/');
    return 'OK — le serveur répond sur $base (HTTP ${r.statusCode}). Vous pouvez Enregistrer.';
  } on DioException catch (e) {
    if (e.type == DioExceptionType.connectionTimeout) {
      return 'Délai dépassé vers $base.\n'
          '• PC et téléphone sur le même Wi‑Fi ?\n'
          '• Backend lancé (gradlew bootRun) ?\n'
          '• Pare-feu Windows : autoriser le port 8080 ?\n'
          '• IP du PC correcte (ipconfig → IPv4) ?';
    }
    if (e.type == DioExceptionType.connectionError) {
      return 'Connexion impossible vers $base.\n'
          'Souvent : mauvaise IP, serveur arrêté, ou pare-feu qui bloque le port 8080 depuis le Wi‑Fi.';
    }
    return 'Erreur réseau : ${e.message ?? e.type}';
  }
}

/// Affiche le dialogue pour configurer l'URL du backend (PC).
/// Utilisable depuis l'écran de connexion ou après une erreur réseau (ex. ajout de prix).
Future<void> showBackendUrlDialog(BuildContext context) async {
  final current = ApiConfig.baseUrl;
  final controller = TextEditingController(text: current);
  final formKey = GlobalKey<FormState>();
  final probing = ValueNotifier(false);

  if (!context.mounted) return;
  final saved = await showDialog<dynamic>(
    context: context,
    builder: (ctx) => ValueListenableBuilder<bool>(
      valueListenable: probing,
      builder: (ctx, _, __) {
        return AlertDialog(
          title: const Text('URL du serveur'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Même Wi‑Fi que le PC. Backend lancé avec le profil « local » (HTTP, pas HTTPS) : '
                  'sur le PC utilisez http://localhost:8080 ; sur le téléphone http://IP_DU_PC:8080 '
                  '(ipconfig → adresse IPv4). N\'utilisez https:// que si le serveur est vraiment en TLS.\n\n'
                  'Astuce : touchez « Tester cette URL » avant « Enregistrer ».',
                  style: TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'URL (ex. http://192.168.1.14:8080)',
                    hintText: '192.168.1.14:8080',
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
              onPressed: probing.value ? null : () => Navigator.of(ctx).pop(false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: probing.value
                  ? null
                  : () async {
                      await ApiConfig.setStoredBaseUrl(null);
                      if (!ctx.mounted) return;
                      Navigator.of(ctx).pop('reset');
                    },
              child: const Text('Réinitialiser'),
            ),
            TextButton(
              onPressed: probing.value
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      probing.value = true;
                      final msg = await probeBackendUrl(controller.text.trim());
                      probing.value = false;
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          duration: const Duration(seconds: 10),
                        ),
                      );
                    },
              child: Text(probing.value ? 'Test…' : 'Tester cette URL'),
            ),
            FilledButton(
              onPressed: probing.value
                  ? null
                  : () {
                      if (formKey.currentState!.validate()) {
                        Navigator.of(ctx).pop(controller.text.trim());
                      }
                    },
              child: const Text('Enregistrer'),
            ),
          ],
        );
      },
    ),
  );

  probing.dispose();

  if (saved is String && saved.isNotEmpty) {
    await ApiConfig.setStoredBaseUrl(saved);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'URL enregistrée. Vous pouvez réessayer la connexion (Test 1) tout de suite.',
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  } else if (saved == 'reset') {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'URL réinitialisée. Réessayez la connexion ; l\'IP par défaut du code s\'applique.',
        ),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }
}
