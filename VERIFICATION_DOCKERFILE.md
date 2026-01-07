# Vérification de la configuration Dockerfile

## 🔍 État actuel

**Date de vérification** : 5 janvier 2026, 18:47

### Problème détecté

Les logs montrent que les services workers utilisent **encore** `Dockerfile.web.railway` (ou `Dockerfile.railway` si détecté automatiquement) au lieu de `Dockerfile.worker.railway`.

**Preuve dans les logs** :
- Logs de build : `[internal] load build definition from Dockerfile.web.railway` (ou `Dockerfile.railway`)
- Logs de déploiement : `Uvicorn running on http://0.0.0.0:8080` (service web, pas workers)
- **Absence** de : `COPY Artemis-modules-extra/` (présent uniquement dans `Dockerfile.worker.railway`)
- **Absence** de : `=== Démarrage des modules: ... ===` (présent uniquement dans `start-multiple-modules.sh`)

### Services concernés

- ❌ `karton-scanners` - Utilise `Dockerfile.web.railway` (ou `Dockerfile.railway` si détecté)
- ❌ `karton-webapp-scanners` - Utilise `Dockerfile.web.railway` (ou `Dockerfile.railway` si détecté)
- ❌ `karton-core-workers` - Utilise `Dockerfile.web.railway` (ou `Dockerfile.railway` si détecté)
- ❌ `karton-brute-specialized` - Utilise `Dockerfile.web.railway` (ou `Dockerfile.railway` si détecté)

## ✅ Solution

### Étape 1 : Vérifier la configuration dans Railway Dashboard

Pour chaque service worker, vérifiez que le Dockerfile Path est bien configuré :

1. Allez sur https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur le service (ex: `karton-scanners`)
3. Allez dans **Settings** → **Build**
4. Vérifiez que **Dockerfile Path** est : `Dockerfile.worker.railway`
5. Si ce n'est pas le cas, modifiez-le et sauvegardez

### Étape 2 : Forcer un nouveau déploiement

Après avoir modifié le Dockerfile Path, Railway devrait automatiquement redéployer. Si ce n'est pas le cas :

1. Dans le service, cliquez sur **Deployments**
2. Cliquez sur **Redeploy** ou **Deploy Latest**

### Étape 3 : Vérifier les logs du nouveau build

Après le redéploiement, vérifiez les logs de build. Vous devriez voir :

**✅ Logs de build attendus (Dockerfile.worker.railway)** :
```
[internal] load build definition from Dockerfile.worker.railway
...
COPY Artemis-modules-extra/ Artemis-modules-extra/
RUN if [ -d "Artemis-modules-extra" ] && [ -n "$(find Artemis-modules-extra -mindepth 1 -maxdepth 1 -type d \( -name 'karton_*' -o -name 'forti_vuln' \) 2>/dev/null | head -1)" ]; then \
    echo "Installation des modules extra d'Artemis-modules-extra..."; \
    ...
COPY docker/start-multiple-modules.sh /usr/local/bin/start-multiple-modules.sh
```

**✅ Logs de déploiement attendus** :
```
=== Démarrage des modules: port_scanner,subdomain_enumeration,...,karton_ssl_checks,... ===
Module port_scanner (core) démarré avec PID: X
Module karton_ssl_checks (extra) démarré avec PID: Y
...
```

**❌ Ne devrait PAS apparaître** :
- `Uvicorn running` (c'est pour le service web uniquement)
- `COPY static/` ou `COPY templates/` (présents uniquement dans `Dockerfile.web.railway`)

## 🔧 Alternative : Utiliser la variable d'environnement

Si la configuration via le Dashboard ne fonctionne pas, essayez d'utiliser la variable d'environnement :

1. Dans le service, allez dans **Variables**
2. Ajoutez ou modifiez : `RAILWAY_DOCKERFILE_PATH=Dockerfile.worker.railway`
3. Sauvegardez et redéployez

**Note** : La variable d'environnement peut être ignorée si `railway.json` existe à la racine du projet.

## 📝 Notes importantes

- Railway détecte automatiquement les fichiers Dockerfile à la racine. `Dockerfile.railway` a été renommé en `Dockerfile.web.railway` pour éviter cette détection automatique.
- Les services workers doivent utiliser `Dockerfile.worker.railway` configuré individuellement
- Après modification du Dockerfile Path, un nouveau build est nécessaire
- Les modules extra ne seront installés que si `Dockerfile.worker.railway` est utilisé

## 🚨 Prochaines étapes

1. ✅ Vérifier la configuration Dockerfile Path dans Railway Dashboard
2. ✅ Forcer un nouveau déploiement si nécessaire
3. ✅ Vérifier les logs de build pour confirmer l'utilisation du bon Dockerfile
4. ✅ Vérifier les logs de déploiement pour confirmer le démarrage des modules
