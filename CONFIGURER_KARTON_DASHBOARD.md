# Configuration de karton-dashboard sur Railway (Option 2)

## 📋 Étapes de configuration

### 1. Dans le Dashboard Railway

1. Allez sur : https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur le service **`karton-dashboard`**
3. Allez dans **Settings** (Paramètres)

### 2. Configuration du Root Directory et Dockerfile

Dans les paramètres du service :

- **Root Directory** : `/` (laissez vide ou mettez `/`)
- **Variables d'environnement** : Ajoutez :
  ```
  RAILWAY_DOCKERFILE_PATH=Dockerfile.karton-dashboard
  ```

### 3. Variables d'environnement requises

Assurez-vous que le service `karton-dashboard` a la variable :
- `REDIS_CONN_STR=${{Redis.REDIS_URL}}`

### 4. Déploiement

Une fois configuré, Railway redéploiera automatiquement le service avec le bon Dockerfile.

## ✅ Vérification

Après le déploiement, vérifiez les logs. Vous devriez voir :
- "=== Starting karton-dashboard ==="
- "Generating karton.ini from REDIS_CONN_STR..."
- Le contenu du fichier karton.ini avec la configuration S3
- "Starting karton-dashboard on port..."

## 📝 Fichiers utilisés

- `Dockerfile.karton-dashboard` - Dockerfile à la racine du projet
- `docker/generate-karton-config.py` - Script qui génère karton.ini avec la config S3
