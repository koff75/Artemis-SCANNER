# Déploiement de Karton Dashboard - Guide Rapide

## ⚠️ Limitation MCP Railway

Le MCP Railway ne permet **pas** de créer un nouveau service directement. Vous devez créer le service manuellement via le Dashboard Railway (1 minute), puis je configurerai tout le reste automatiquement.

## 🚀 Étapes

### 1. Créer le service (Dashboard Railway - 1 minute)

1. Allez sur : **https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307**
2. Cliquez sur **"+ New"** → **"Empty Service"**
3. Nommez le service : **`karton-dashboard`**
4. Dans les paramètres du service :
   - **Source** : Connectez le même dépôt GitHub que `artemis-scanner`
   - **Root Directory** : `/karton-dashboard-service` (ou laissez `/` et utilisez la variable ci-dessous)
   - **Variable d'environnement** : `RAILWAY_DOCKERFILE_PATH=Dockerfile.karton-dashboard` (si Root Directory = `/`)

### 2. Configuration automatique (MCP)

Une fois le service créé, **dites-moi** et je configurerai automatiquement :
- ✅ Variable `REDIS_CONN_STR=${{Redis.REDIS_URL}}`
- ✅ Variable `KARTON_DASHBOARD_URL` dans le service `artemis-scanner`
- ✅ Déploiement du service

## 📝 Fichiers préparés

- ✅ `Dockerfile.karton-dashboard` - Dockerfile prêt à l'emploi
- ✅ `karton-dashboard-service/` - Répertoire avec toute la configuration
- ✅ Code frontend modifié pour utiliser `KARTON_DASHBOARD_URL`

---

**Note** : Le service sera déployé dans le même projet `artemis-scanner`, pas dans un nouveau projet.
