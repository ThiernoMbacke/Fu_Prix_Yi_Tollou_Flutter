# Développement : Chrome + téléphone (Test1, produits, marchés)

## 1. Backend (HTTP, sans certificat)

Depuis `prix-yi-backend` :

```powershell
$env:SUPABASE_DB_PASSWORD="votre_mot_de_passe_supabase"
.\gradlew.bat bootRun
```

- **`bootRun` active par défaut le profil `local`** → serveur en **`http://0.0.0.0:8080`** (HTTP, pas HTTPS). Le fichier `application-local.yml` force **`server.address: 0.0.0.0`** pour que le téléphone sur le Wi‑Fi puisse joindre le PC par son IP (pas seulement `localhost` sur la machine).
- **Redis** doit tourner (`localhost:6379`) ou utilisez `docker compose up -d` dans ce dossier si vous avez un `docker-compose.yml` avec Redis.

Pour forcer la prod / HTTPS : ` $env:SPRING_PROFILES_ACTIVE="prod" ` avant `bootRun`.

**Pare-feu Windows** : autoriser **Java** ou le **port 8080** entrant sur le réseau **privé**, sinon le téléphone ne joindra pas le PC.

## 2. Flutter — Chrome (même PC)

- URL par défaut : **`http://localhost:8080`** (déjà le cas pour le web).
- Connexion → **Test 1** → ajout produit / marché comme d’habitude.

## 3. Flutter — Téléphone Samsung (même Wi‑Fi)

1. Sur le PC : `ipconfig` → noter l’**IPv4** (ex. `192.168.1.105`).
2. Dans `lib/config/api_config_platform_io.dart`, mettre **`kPhysicalDeviceHost`** sur cette IP (ou utiliser **Configurer l’URL du serveur** dans l’app : `http://192.168.1.105:8080`).
3. **Redémarrer l’app** après changement d’URL enregistrée.
4. Écran de connexion : vérifier **« Serveur actuel »** = `http://...:8080` en **http**, pas **https** (tant que le backend est en profil `local`).
5. **Chrome sur le téléphone** : si vous ouvrez `http://192.168.x.x:8080`, le navigateur peut afficher *« connexion non sécurisée »* ou *« non chiffrée »* — c’est **normal** en HTTP local. Utilisez **Continuer quand même** / **Avancé** → accéder au site. L’app Flutter n’a pas ce message (cleartext déjà autorisé dans le manifeste Android).

## 4. Authentification sur le téléphone (OTP ou Test1)

L’API d’auth (`/api/auth/...`) pointe vers **le même `ApiConfig.baseUrl`** que le reste (pas Supabase pour le login).

1. **URL du backend** : sur l’écran de connexion, ligne **« Serveur actuel »** doit être `http://VOTRE_IP:8080` (pas `localhost`, pas `https` si le PC tourne en profil `local`). Dans **Configurer l’URL du serveur**, utilisez d’abord **« Tester cette URL »** : si le test échoue, le message indique en général pare-feu, IP ou serveur arrêté — pas la peine d’enregistrer tant que le test n’est pas OK.
2. **Redis** : les codes OTP sont stockés dans **Redis** (`localhost:6379` côté PC). Sans Redis, l’envoi ou la vérification OTP peut échouer. Démarrez Redis ou `docker compose` si vous l’utilisez.
3. **SMS** : sans clé Infobip valide, le backend **simule** l’envoi et écrit le code dans **les logs du terminal** (`gradlew bootRun`). Si une clé Infobip est configurée mais incorrecte, l’API peut renvoyer *Impossible d’envoyer le SMS*.
4. **Connexion rapide sans SMS** : sur l’écran **Choisissez votre méthode**, utilisez **Test 1** / **Test 2** (POST `/api/auth/demo`) — pratique pour valider le réseau téléphone ↔ PC sans OTP.
5. **Numéro** : format Sénégal — 9 chiffres, préfixes **70, 71, 76, 77, 78** (ex. `77 123 45 67`).

## 5. Check-list si ça échoue

| Problème | Piste |
|----------|--------|
| Connexion refusée | Backend lancé ? Redis OK ? Pare-feu ? |
| `Failed host lookup` | Mauvaise IP ou pas le même Wi‑Fi |
| HTTPS / certificat | URL en `https://` alors que le backend est en **local** (HTTP) → mettre `http://` |
| CORS (Chrome seulement) | Déjà géré côté backend ; recharger après redémarrage serveur |
| OTP jamais reçu / erreur envoi | Voir logs PC pour le code (simulation) ; ou **Test1** ; vérifier Infobip si configuré |

## 6. Fichiers utiles

- Backend profil local : `prix-yi-backend/src/main/resources/application-local.yml`
- IP téléphone : `lib/config/api_config_platform_io.dart` → `kPhysicalDeviceHost`
- Dialogue URL : écran connexion → **Configurer l'URL du serveur**
