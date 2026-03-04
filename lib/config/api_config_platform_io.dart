import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// Implémentation mobile (Android / iOS) : émulateur vs appareil physique.
Future<String> getDefaultBackendBaseUrl() async {
  const fromEnv = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  if (fromEnv.isNotEmpty) return fromEnv;

  if (Platform.isAndroid) {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    // Émulateur Android : 10.0.2.2 = machine hôte
    if (!androidInfo.isPhysicalDevice) return 'http://10.0.2.2:8080';
    // Appareil physique : localhost = le téléphone, on utilise une valeur par défaut
    // que l'utilisateur devra remplacer via "Configurer l'URL" (ou --dart-define)
    return 'http://localhost:8080';
  }

  if (Platform.isIOS) {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    // Simulateur iOS : localhost = machine hôte
    if (!iosInfo.isPhysicalDevice) return 'http://localhost:8080';
    return 'http://localhost:8080';
  }

  return 'http://localhost:8080';
}
