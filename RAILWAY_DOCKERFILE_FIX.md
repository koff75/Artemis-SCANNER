# Correction du problème Dockerfile pour les services workers

## 🔴 Problème identifié

Les services workers (`karton-scanners`, `karton-webapp-scanners`, `karton-core-workers`, `karton-brute-specialized`) utilisent **`Dockerfile.web.railway`** (pour le service web) au lieu de **`Dockerfile.worker.railway`** (pour les workers).

### Preuve dans les logs

1. **Logs de build** : Montrent les étapes `COPY static/`, `COPY templates/` qui sont dans `Dockerfile.web.railway` mais **PAS** dans `Dockerfile.worker.railway`
2. **Logs de déploiement** : Montrent `Uvicorn running` (serveur web) au lieu de `start-multiple-modules.sh` (workers)
3. **Modules extra** : Ne sont **PAS** installés car `Dockerfile.worker.railway` n'est pas utilisé

### Cause

Railway détecte automatiquement `Dockerfile.railway` (ou `Dockerfile.web.railway`) à la racine et l'utilise par défaut, ce qui peut écraser la configuration du Dashboard. **Solution** : Renommer en `Dockerfile.web.railway` pour éviter la détection automatique.

## ✅ Solution

### Option 1 : Configurer via Dashboard Railway (RECOMMANDÉ)

Pour chaque service worker, configurez le Dockerfile directement dans les paramètres du service :

1. Allez sur https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur le service (ex: `karton-scanners`)
3. Allez dans **Settings** → **Build**
4. Dans **Dockerfile Path**, entrez : `Dockerfile.worker.railway`
5. Sauvegardez → Le service redéploiera automatiquement

**Services à configurer** :
- `karton-scanners`
- `karton-webapp-scanners`
- `karton-core-workers`
- `karton-brute-specialized`

### Option 2 : Supprimer railway.json (NON RECOMMANDÉ)

Si vous supprimez `railway.json` à la racine, Railway utilisera `RAILWAY_DOCKERFILE_PATH`, mais cela casserait le service principal `artemis-scanner`.

### Option 3 : Créer des fichiers railway.json par service

Créer des fichiers `railway.json` dans des sous-dossiers, mais Railway ne les détecte peut-être pas automatiquement.

## 🔍 Vérification après correction

Après avoir configuré le Dockerfile correct, vérifiez les logs de build :

### Logs de build attendus (Dockerfile.worker.railway)

Vous devriez voir :
```
COPY Artemis-modules-extra/ Artemis-modules-extra/
RUN if [ -d "Artemis-modules-extra" ] && [ -n "$(find Artemis-modules-extra -mindepth 1 -maxdepth 1 -type d \( -name 'karton_*' -o -name 'forti_vuln' \) 2>/dev/null | head -1)" ]; then \
    echo "Installation des modules extra d'Artemis-modules-extra..."; \
    ...
```

### Logs de déploiement attendus

Vous devriez voir :
```
=== Démarrage des modules: ... ===
Module classifier (core) démarré avec PID: X
Module karton_ssl_checks (extra) démarré avec PID: Y
...
```

**PAS** de `Uvicorn running` (c'est pour le service web uniquement).

## 📝 État actuel

- ✅ Variables `RAILWAY_DOCKERFILE_PATH` : Définies correctement
- ✅ Variables `MODULES` : Configurées correctement (avec `forti_vuln` corrigé)
- ✅ Scripts et Dockerfiles : Corrigés et prêts
- ❌ **Configuration Railway** : Utilise le mauvais Dockerfile

## 🚀 Action requise

**Configurer manuellement le Dockerfile Path dans les paramètres de chaque service worker via le Dashboard Railway.**

Une fois fait, les services redéploieront automatiquement avec le bon Dockerfile et les modules extra seront installés et démarrés correctement.
