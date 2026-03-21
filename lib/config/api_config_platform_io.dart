import 'dart:io' show Platform;

import 'package:device_info_plus/device_info_plus.dart';

/// IP (ou host) du PC sur le réseau local — utilisé pour appareil physique (ex. Samsung).
/// Mettez l’IP de votre PC (`ipconfig` / `ip a`). Même Wi‑Fi que le téléphone.
///
/// **Important :** l’URL par défaut est en **HTTP** (`http://…:8080`). Le backend doit alors
/// tourner **sans** TLS sur le LAN : `SSL_ENABLED=false` (voir README backend). Si vous gardez
/// HTTPS + certificat auto-signé sur le téléphone, il faudrait `https://` + confiance du certificat
/// (plus complexe) — pour le dev, préférez HTTP + `SSL_ENABLED=false`.
const String kPhysicalDeviceHost = '192.168.1.203';

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
    // Appareil physique : utiliser l’IP du PC (kPhysicalDeviceHost)
    return 'http://$kPhysicalDeviceHost:8080';
  }

  if (Platform.isIOS) {
    final iosInfo = await DeviceInfoPlugin().iosInfo;
    // Simulateur iOS : localhost = machine hôte
    if (!iosInfo.isPhysicalDevice) return 'http://localhost:8080';
    // iPhone physique : même principe que Android
    return 'http://$kPhysicalDeviceHost:8080';
  }

  return 'http://localhost:8080';
}
