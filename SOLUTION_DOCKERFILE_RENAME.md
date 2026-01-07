# Solution : Renommage de Dockerfile.railway

## ✅ Action effectuée

**Fichier renommé** : `Dockerfile.railway` → `Dockerfile.web.railway`

## 🔴 Problème résolu

Railway détecte automatiquement les fichiers Dockerfile à la racine du projet et les utilise par défaut, même si vous configurez un autre Dockerfile dans les paramètres du service. Cela peut écraser votre configuration et faire rebasculer vers `Dockerfile.railway` après chaque "Apply Changes".

### Pourquoi le renommage fonctionne

En renommant `Dockerfile.railway` en `Dockerfile.web.railway`, Railway ne le détectera plus automatiquement. Vous devez maintenant configurer explicitement chaque service avec le bon Dockerfile, et Railway respectera cette configuration.

## 🔧 Configuration requise dans Railway Dashboard

Maintenant que `Dockerfile.railway` n'existe plus, configurez chaque service :

### 1. Service : `artemis-scanner`

**Dockerfile Path** : `Dockerfile.web.railway`

### 2. Services workers

**Dockerfile Path** : `Dockerfile.worker.railway`

- `karton-scanners`
- `karton-webapp-scanners`
- `karton-core-workers`
- `karton-brute-specialized`

### 3. Service : `karton-system`

**Dockerfile Path** : `Dockerfile.karton-system.railway`

## ✅ Vérification

Après configuration, Railway ne devrait plus rebasculer automatiquement vers `Dockerfile.railway` car ce fichier n'existe plus.

Les logs de build devraient montrer :
- `[internal] load build definition from Dockerfile.worker.railway` (pour les workers)
- `[internal] load build definition from Dockerfile.web.railway` (pour artemis-scanner)

## 📝 Notes

- Le fichier `Dockerfile.railway` a été supprimé
- Le fichier `Dockerfile.web.railway` a été créé avec le même contenu
- Tous les services doivent maintenant être configurés explicitement dans Railway Dashboard
- Railway ne devrait plus détecter automatiquement de Dockerfile par défaut
