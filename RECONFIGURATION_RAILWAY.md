# Reconfiguration des services Railway après suppression de railway.json

## 📋 Vue d'ensemble

Le fichier `railway.json` à la racine a été supprimé. Railway détecte automatiquement `Dockerfile.railway` à la racine, c'est pourquoi nous avons renommé `Dockerfile.railway` en `Dockerfile.web.railway` pour éviter la détection automatique. Maintenant, chaque service doit être configuré individuellement via le Dashboard Railway.

## ⚠️ Action requise

Après suppression de `railway.json`, **vous devez reconfigurer chaque service** via le Dashboard Railway.

## 🔧 Configuration requise pour chaque service

### 1. Service : `artemis-scanner` (Service principal - API web)

**Configuration** :
- **Dockerfile Path** : `Dockerfile.web.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées

**Étapes** :
1. Allez sur https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur le service `artemis-scanner`
3. Allez dans **Settings** → **Build**
4. Dans **Dockerfile Path**, entrez : `Dockerfile.web.railway`
5. Sauvegardez

---

### 2. Service : `karton-scanners`

**Configuration** :
- **Dockerfile Path** : `Dockerfile.worker.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées
  - `MODULES=port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,forti_vuln,karton_whatvpn`

**Étapes** :
1. Cliquez sur le service `karton-scanners`
2. Allez dans **Settings** → **Build**
3. Dans **Dockerfile Path**, entrez : `Dockerfile.worker.railway`
4. Sauvegardez → Le service redéploiera automatiquement

---

### 3. Service : `karton-webapp-scanners`

**Configuration** :
- **Dockerfile Path** : `Dockerfile.worker.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées
  - `MODULES=nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner`

**Étapes** :
1. Cliquez sur le service `karton-webapp-scanners`
2. Allez dans **Settings** → **Build**
3. Dans **Dockerfile Path**, entrez : `Dockerfile.worker.railway`
4. Sauvegardez → Le service redéploiera automatiquement

---

### 4. Service : `karton-core-workers`

**Configuration** :
- **Dockerfile Path** : `Dockerfile.worker.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées
  - `MODULES=classifier,http_service_to_url,webapp_identifier,ip_lookup`

**Étapes** :
1. Cliquez sur le service `karton-core-workers`
2. Allez dans **Settings** → **Build**
3. Dans **Dockerfile Path**, entrez : `Dockerfile.worker.railway`
4. Sauvegardez → Le service redéploiera automatiquement

---

### 5. Service : `karton-brute-specialized`

**Configuration** :
- **Dockerfile Path** : `Dockerfile.worker.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées

**Étapes** :
1. Cliquez sur le service `karton-brute-specialized`
2. Allez dans **Settings** → **Build**
3. Dans **Dockerfile Path**, entrez : `Dockerfile.worker.railway`
4. Sauvegardez → Le service redéploiera automatiquement

---

### 6. Service : `karton-system`

**Configuration** :
- **Dockerfile Path** : `Dockerfile.karton-system.railway`
- **Root Directory** : `/` (racine)
- **Variables d'environnement** : Déjà configurées

**Étapes** :
1. Cliquez sur le service `karton-system`
2. Allez dans **Settings** → **Build**
3. Dans **Dockerfile Path**, entrez : `Dockerfile.karton-system.railway`
4. Sauvegardez → Le service redéploiera automatiquement

---

### 7. Service : `karton-dashboard` (si existant)

**Configuration** :
- **Dockerfile Path** : `Dockerfile.karton-dashboard` (ou selon votre configuration)
- **Root Directory** : `/` (racine)

**Étapes** :
1. Cliquez sur le service `karton-dashboard`
2. Allez dans **Settings** → **Build**
3. Configurez le **Dockerfile Path** approprié
4. Sauvegardez

---

## ✅ Vérification après reconfiguration

### Pour les services workers (karton-scanners, karton-webapp-scanners, etc.)

**Logs de build attendus** :
```
[internal] load build definition from Dockerfile.worker.railway
...
COPY Artemis-modules-extra/ Artemis-modules-extra/
RUN if [ -d "Artemis-modules-extra" ] && [ -n "$(find Artemis-modules-extra -mindepth 1 -maxdepth 1 -type d \( -name 'karton_*' -o -name 'forti_vuln' \) 2>/dev/null | head -1)" ]; then \
    echo "Installation des modules extra d'Artemis-modules-extra..."; \
    ...
COPY docker/start-multiple-modules.sh /usr/local/bin/start-multiple-modules.sh
```

**Logs de déploiement attendus** :
```
=== Démarrage des modules: port_scanner,subdomain_enumeration,...,karton_ssl_checks,... ===
Module port_scanner (core) démarré avec PID: X
Module karton_ssl_checks (extra) démarré avec PID: Y
...
```

**Ne devrait PAS apparaître** :
- ❌ `Uvicorn running` (c'est pour le service web uniquement)
- ❌ `COPY static/` ou `COPY templates/` (présents uniquement dans `Dockerfile.web.railway`)

### Pour le service artemis-scanner

**Logs de build attendus** :
```
[internal] load build definition from Dockerfile.web.railway
...
COPY static/ static/
COPY templates/ templates/
```

**Logs de déploiement attendus** :
```
INFO:     Uvicorn running on http://0.0.0.0:8080 (Press CTRL+C to quit)
```

---

## 📝 Ordre de reconfiguration recommandé

1. ✅ **artemis-scanner** (service principal - doit fonctionner en premier)
2. ✅ **karton-system** (routing des tâches - essentiel)
3. ✅ **karton-core-workers** (modules essentiels)
4. ✅ **karton-scanners** (scanners avec modules extra)
5. ✅ **karton-webapp-scanners** (scanners webapp avec modules extra)
6. ✅ **karton-brute-specialized** (brute force)

---

## 🚨 Important

- Après suppression de `railway.json`, Railway redéploiera automatiquement tous les services
- Les services utiliseront leur configuration par défaut jusqu'à ce que vous configuriez le Dockerfile Path
- Configurez d'abord `artemis-scanner` pour éviter qu'il ne tombe en erreur
- Vérifiez les logs après chaque configuration pour confirmer que le bon Dockerfile est utilisé

---

## 📚 Références

- [RAILWAY_DOCKERFILE_FIX.md](RAILWAY_DOCKERFILE_FIX.md) - Détails du problème
- [VERIFICATION_DOCKERFILE.md](VERIFICATION_DOCKERFILE.md) - Guide de vérification
