# Démarrer le backend (port 8080)

## Le backend est-il indépendant de Flutter ?

**Oui.** Ce sont deux processus distincts :

- **Backend** : application Spring Boot qui tourne sur votre machine (ou un serveur), sur le **port 8080**. Elle gère l’auth (OTP, démo), les JWT et écrit dans la base Supabase (PostgreSQL).
- **Flutter** : l’app mobile/web que vous lancez avec `flutter run`. Elle appelle le backend en HTTP (URL configurée dans `ApiConfig.baseUrl`).

Vous devez **démarrer le backend avant** (ou en parallèle) pour que la connexion (téléphone, démo) et l’ajout de prix fonctionnent. Vous pouvez lancer le backend dans un terminal et Flutter dans un autre.

---

## Prérequis

- **JDK 17** (ou plus) installé. Vérification : `java -version`
- **Mot de passe de la base Supabase** (voir ci‑dessous)
- **Redis** (pour le stockage des codes OTP). Si vous ne l’utilisez pas, le backend peut refuser de démarrer ; voir la section Redis plus bas.

---

## 1. Récupérer le mot de passe Supabase

1. Allez sur [Supabase Dashboard](https://supabase.com/dashboard) → votre projet.
2. **Settings** (Paramètres) → **Database**.
3. Dans **Database password**, utilisez le mot de passe que vous avez défini à la création du projet (ou réinitialisez‑le).
4. Ce mot de passe sera la valeur de la variable d’environnement **`SUPABASE_DB_PASSWORD`**.

---

## 2. Démarrer le backend

Ouvrez un terminal dans le dossier du backend :

```bash
cd prix-yi-backend
```

Sous **Windows** (PowerShell ou CMD) :

```cmd
set SUPABASE_DB_PASSWORD=VotreMotDePasseIci
gradlew.bat bootRun
```

Sous **Windows PowerShell** (pour une seule commande) :

```powershell
$env:SUPABASE_DB_PASSWORD="VotreMotDePasseIci"; .\gradlew.bat bootRun
```

Sous **Linux / macOS** :

```bash
export SUPABASE_DB_PASSWORD=VotreMotDePasseIci
./gradlew bootRun
```

Le backend écoute sur **http://localhost:8080**. Vous devriez voir des logs Spring Boot et, à la fin, quelque chose comme « Started PrixYiApplication ».

---

## 3. Vérifier que le backend répond

- Dans le navigateur : **http://localhost:8080/actuator/health**
- Ou en ligne de commande : `curl http://localhost:8080/actuator/health`

Une réponse du type `{"status":"UP"}` indique que le backend est bien démarré.

---

## 4. Redis (optionnel mais souvent nécessaire)

Le backend utilise Redis pour stocker les codes OTP. Si Redis n’est pas installé ou pas démarré, le démarrage peut échouer.

- **Avec Docker** (recommandé si vous avez Docker) :

  ```bash
  docker run -d --name redis -p 6379:6379 redis
  ```

- **Sans Docker** : installez Redis (ex. [Windows](https://github.com/microsoftarchive/redis/releases), Chocolatey `choco install redis-64`, ou WSL).

Par défaut, le backend se connecte à **localhost:6379**. Si Redis est ailleurs, définissez `REDIS_HOST` et éventuellement `REDIS_PORT`.

---

## 5. Résumé des variables utiles

| Variable | Obligatoire | Description |
|----------|-------------|-------------|
| `SUPABASE_DB_PASSWORD` | Oui | Mot de passe de la base Supabase (Settings → Database) |
| `JWT_SECRET` | Non (défaut en dev) | Secret JWT (min 32 caractères) ; à changer en prod |
| `REDIS_HOST` | Non (défaut: localhost) | Hôte Redis |
| `REDIS_PORT` | Non (défaut: 6379) | Port Redis |

---

## 6. Ensuite : lancer Flutter

Dans un **autre terminal**, à la racine du projet Flutter :

```bash
flutter run
```

L’app utilise par défaut `ApiConfig.baseUrl` (ex. `http://10.0.2.2:8080` pour l’émulateur Android). Sur un appareil physique, adaptez l’URL pour pointer vers la machine qui fait tourner le backend (ex. `http://192.168.x.x:8080`).

En résumé : **démarrage du backend = indépendant de `flutter run`** ; vous lancez d’abord le backend sur le port 8080, puis vous lancez l’app Flutter.
