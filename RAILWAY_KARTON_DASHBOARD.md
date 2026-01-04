# Déploiement de Karton Dashboard sur Railway

## Limitation du MCP Railway

Le MCP Railway ne permet pas de créer un nouveau service avec un Dockerfile spécifique. Vous devez créer le service manuellement via le Dashboard Railway, puis je configurerai tout le reste via MCP.

## Étapes de déploiement

### 1. Créer le service via Railway Dashboard

1. Allez sur https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur "+ New" → "Empty Service"
3. Nommez le service : `karton-dashboard`
4. Dans les paramètres du service :
   - **Source** : Connectez le même dépôt GitHub que le service artemis-scanner
   - **Root Directory** : `/` (racine du projet)
   - **Dockerfile Path** : Définissez la variable d'environnement `RAILWAY_DOCKERFILE_PATH=Dockerfile.karton-dashboard`

### 2. Configuration automatique via MCP

Une fois le service créé, dites-moi et je configurerai :
- Les variables d'environnement (`REDIS_CONN_STR`)
- L'URL du dashboard dans le service principal
- Le déploiement du service
