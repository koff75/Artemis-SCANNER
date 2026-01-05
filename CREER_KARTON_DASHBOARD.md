# 🚀 Créer karton-dashboard dans le même projet Railway

## ✅ Oui, c'est possible dans le même projet !

Le service karton-dashboard peut être déployé dans le même projet `artemis-scanner`. Voici comment :

## 📋 Étapes (2 minutes)

### 1. Créer le service via Dashboard Railway

1. **Allez sur** : https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. **Cliquez sur** : `+ New` → `Empty Service`
3. **Nommez le service** : `karton-dashboard`
4. **Dans les paramètres du service** :
   - **Source** : Connectez le même dépôt GitHub que `artemis-scanner`
   - **Root Directory** : `/karton-dashboard-service`
   - **OU** Root Directory : `/` + Variable : `RAILWAY_DOCKERFILE_PATH=Dockerfile.karton-dashboard`

### 2. Je configurerai automatiquement (via MCP)

Une fois le service créé, **dites-moi** et je configurerai :
- ✅ Variable `REDIS_CONN_STR=${{Redis.REDIS_URL}}` dans karton-dashboard
- ✅ Variable `KARTON_DASHBOARD_URL=${{karton-dashboard.RAILWAY_PRIVATE_DOMAIN}}` dans artemis-scanner
- ✅ Déploiement automatique

## 📁 Fichiers déjà préparés

- ✅ `Dockerfile.karton-dashboard` - Prêt à l'emploi
- ✅ `karton-dashboard-service/` - Répertoire complet avec configuration
- ✅ Code frontend modifié pour utiliser `KARTON_DASHBOARD_URL`

---

**Le service sera dans le même projet `artemis-scanner`, pas dans un nouveau projet !** 🎯
