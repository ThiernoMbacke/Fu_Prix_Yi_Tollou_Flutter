# Architecture Backend + Flutter (Fou Prix)

## Résumé

- **Auth** : Backend Spring Boot (OTP SMS → JWT). Plus d’auth Supabase côté app.
- **Données** : Lecture villes/marchés/produits/prix via **Supabase** (Flutter). Écriture des prix et profil via **Backend** (API + JWT).
- **Flutter** : `dio` + `flutter_secure_storage` pour les appels API et le stockage des tokens.

## Flow d’authentification

1. L’utilisateur saisit son numéro → Flutter appelle `POST /api/auth/send-otp`.
2. Le backend génère un OTP (6 chiffres), l’envoie par SMS (Infobip/Orange) et le stocke dans Redis (TTL 5 min).
3. L’utilisateur saisit le code → Flutter appelle `POST /api/auth/verify-otp`.
4. Le backend vérifie l’OTP, crée ou récupère l’utilisateur en base (Supabase Postgres), génère access + refresh JWT.
5. Flutter enregistre les tokens dans `flutter_secure_storage` et les envoie sur chaque requête protégée (`Authorization: Bearer <access_token>`).
6. Quand l’access token expire, Flutter utilise le refresh token (`POST /api/auth/refresh-token`) pour en obtenir un nouveau.

## Sécurité backend

- Rate limiting par IP et par numéro (configurable, ex. 5 OTP/IP/heure, 3 OTP/numéro/15 min).
- JWT : access 15 min, refresh 7 jours, rotation du refresh au refresh.
- Endpoints publics : `/api/auth/**`, `/actuator/health`. Le reste exige un JWT valide.

## Flutter : ce qui a changé

- **Supprimé** : utilisation de `supabase_flutter` pour l’auth (plus de `signInWithPhone` / `verifyOTP` Supabase/Twilio).
- **Conservé** : `supabase_flutter` pour la lecture des données (villes, marchés, produits, prix) et pour Storage/Realtime si besoin.
- **Ajouté** : `dio` pour les appels au backend, `flutter_secure_storage` pour les JWT.
- **Config** : `lib/config/api_config.dart` — `API_BASE_URL` (ou `--dart-define=API_BASE_URL=...`).

## Scripts SQL

À exécuter dans le SQL Editor Supabase : `prix-yi-backend/scripts/supabase-schema.sql` (tables `users`, `refresh_tokens`, `otp_attempts`, et métier si besoin).

## Prochaines étapes possibles

- Compléter l’intégration Orange SMS (OAuth2 + envoi réel).
- Exposer davantage d’endpoints métier sur le backend (optionnel si on garde la lecture via Supabase).
