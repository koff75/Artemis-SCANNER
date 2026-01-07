# Modifications pour le déploiement sur Railway

Ce document décrit tous les changements effectués depuis le dépôt initial pour déployer Artemis-SCANNER sur Railway.

## 📋 Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Fichiers créés](#fichiers-créés)
3. [Modifications de code](#modifications-de-code)
4. [Architecture de déploiement](#architecture-de-déploiement)
5. [Problèmes rencontrés et résolus](#problèmes-rencontrés-et-résolus)
6. [Services Railway](#services-railway)
7. [Configuration requise](#configuration-requise)

---

## Vue d'ensemble

Artemis-SCANNER a été adapté pour fonctionner sur Railway, une plateforme cloud qui ne fournit pas de services S3. Les principales adaptations concernent :

- **Dockerfiles** pour Railway (multiples services)
- **Configuration dynamique** de Karton depuis les variables d'environnement
- **Contournement du problème S3** de Karton
- **Déploiement des modules Karton** en groupes pour optimiser les coûts
- **Logging amélioré** pour le débogage

---

## Fichiers créés

### Dockerfiles pour Railway

#### 1. `Dockerfile.web.railway` (anciennement `Dockerfile.railway`)
- **But** : Service principal `artemis-scanner` (API web)
- **Base** : `python:3.13-alpine3.20`
- **Fonctionnalités** :
  - Génération dynamique de `karton.ini` depuis `REDIS_CONN_STR`
  - Attente de Redis avant démarrage
  - Exécution des migrations Alembic
  - Démarrage de l'API FastAPI/Uvicorn

#### 2. `Dockerfile.worker.railway`
- **But** : Services workers pour les modules Karton
- **Base** : `python:3.13-alpine3.20`
- **Fonctionnalités** :
  - Support pour exécuter plusieurs modules en parallèle dans un même conteneur
  - Utilise `start-multiple-modules.sh` pour grouper les modules
  - Optimisation des coûts en regroupant les modules

#### 3. `Dockerfile.karton-system.railway`
- **But** : Service `karton-system` (routing des tâches)
- **Base** : `certpl/karton-system:v5.3.3`
- **Fonctionnalités** :
  - Wrapper Python pour contourner la vérification S3
  - Génération de configuration sans S3 réel
  - Désactivation du garbage collection (GC)

#### 4. `Dockerfile.karton-dashboard`
- **But** : Service Karton Dashboard (optionnel)
- **Base** : Image Karton Dashboard officielle
- **Fonctionnalités** : Interface web pour visualiser les queues Karton

### Scripts de configuration

#### 1. `docker/generate-karton-config.py`
- **But** : Génère `karton.ini` depuis `REDIS_CONN_STR`
- **Utilisé par** : Services principaux et workers
- **Fonctionnalités** :
  - Parse l'URL Redis
  - Génère la configuration avec section S3 factice (requis par Karton)

#### 2. `docker/generate-karton-config-system.py`
- **But** : Génère `karton.ini` spécifiquement pour `karton-system`
- **Différence** : Inclut une section S3 factice (requis par karton-system)

#### 3. `docker/karton-system-wrapper.py`
- **But** : Wrapper Python pour contourner la vérification S3 de karton-system
- **Fonctionnalités** :
  - Patche `SystemService.ensure_bucket_exists()` pour retourner toujours `True`
  - Permet à karton-system de démarrer sans S3 réel

#### 4. `docker/wait-for-redis.sh`
- **But** : Attendre que Redis soit disponible avant de démarrer
- **Fonctionnalités** :
  - Vérifie la connexion Redis avec timeout
  - Parse `REDIS_CONN_STR` pour obtenir host/port

#### 5. `docker/start-multiple-modules.sh`
- **But** : Démarrer plusieurs modules Karton en parallèle dans un conteneur
- **Fonctionnalités** :
  - Parse la variable `MODULES` (format: "module1,module2,module3")
  - Démarre chaque module en arrière-plan
  - Gère les signaux pour arrêt propre

### Fichiers de configuration Railway

#### 1. `railway.json`
- **But** : Configuration pour le service principal `artemis-scanner`
- **Contenu** : Référence à `Dockerfile.web.railway` (renommé pour éviter la détection automatique de Railway)

#### 2. `railway.karton-system.json`
- **But** : Configuration pour le service `karton-system`
- **Contenu** : Référence à `Dockerfile.karton-system.railway`

#### 3. `karton-dashboard-service/railway.json`
- **But** : Configuration pour le service Karton Dashboard
- **Contenu** : Référence au Dockerfile du dashboard

### Scripts PowerShell

#### 1. `install-railway-cli.ps1`
- **But** : Installer Railway CLI sur Windows
- **Fonctionnalités** : Installation via npm

#### 2. `railway-setup.ps1`
- **But** : Script de configuration initiale Railway
- **Fonctionnalités** : Création/liaison du projet Railway

#### 3. `create-karton-system-service.ps1`
- **But** : Aide à la création du service karton-system
- **Fonctionnalités** : Instructions pour créer le service manuellement

### Documentation

#### 1. `RAILWAY_DEPLOY.md`
- **But** : Guide de déploiement principal sur Railway
- **Contenu** : Instructions complètes de déploiement

#### 2. `RAILWAY_KARTON_SYSTEM.md`
- **But** : Documentation spécifique pour karton-system
- **Contenu** : Explication du problème S3 et de la solution

#### 3. `RAILWAY_KARTON_DASHBOARD.md`
- **But** : Guide pour déployer Karton Dashboard
- **Contenu** : Instructions de déploiement du dashboard

---

## Modifications de code

### 1. `artemis/producer.py`

#### Logging amélioré pour le débogage

**Ajouts** :
- Logging de l'initialisation du Producer
- Vérification des binds Karton enregistrés
- Vérification des queues Redis avant/après envoi de tâches
- Détection des tâches dans le stockage Karton
- Vérification des queues unrouted
- Logging des noms de queues que Karton utiliserait

**Raison** : Permettre de diagnostiquer pourquoi les tâches n'étaient pas routées.

**Exemple de logs ajoutés** :
```python
logger.info(f"Found {len(binds)} registered binds in Redis")
logger.info(f"Found {len(matching_binds)} binds matching type={task_type}")
logger.info(f"Queues that would be used for {classifier_bind.identity}: {classifier_queues}")
```

#### Correction du type de tâche

**Changement** :
```python
# Avant
task = Task({"type": TaskType.NEW})

# Après
task = Task({"type": TaskType.NEW.value})  # Assure que c'est une string
```

**Raison** : Karton attend une string, pas un enum.

---

## Architecture de déploiement

### Services Railway

1. **artemis-scanner** (Service principal)
   - API web FastAPI
   - Interface utilisateur
   - Génération de rapports
   - Dockerfile : `Dockerfile.web.railway`

2. **karton-core-workers** (Workers principaux)
   - Modules : `classifier`, `http_service_to_url`, `webapp_identifier`, `ip_lookup`
   - Dockerfile : `Dockerfile.worker.railway`
   - Variable : `MODULES=classifier,http_service_to_url,webapp_identifier,ip_lookup`

3. **karton-scanners** (Scanners)
   - Modules : `port_scanner`, `nuclei`, `directory_index`, etc.
   - Dockerfile : `Dockerfile.worker.railway`
   - Variable : `MODULES=port_scanner,nuclei,directory_index,...`

4. **karton-webapp-scanners** (Scanners d'applications web)
   - Modules : `wordpress_plugins`, `joomla_scanner`, `drupal_scanner`, etc.
   - Dockerfile : `Dockerfile.worker.railway`
   - Variable : `MODULES=wordpress_plugins,joomla_scanner,...`

5. **karton-brute-specialized** (Brute force spécialisés)
   - Modules : `bruter`, `ftp_bruter`, `wordpress_bruter`, etc.
   - Dockerfile : `Dockerfile.worker.railway`
   - Variable : `MODULES=bruter,ftp_bruter,...`

6. **karton-system** (Routing des tâches) ⚠️ **ESSENTIEL**
   - Route les tâches depuis la queue unrouted vers les queues des modules
   - Dockerfile : `Dockerfile.karton-system.railway`
   - Wrapper Python pour contourner S3

7. **karton-dashboard** (Optionnel)
   - Interface web pour visualiser les queues Karton
   - Dockerfile : `Dockerfile.karton-dashboard`

### Services Railway (infrastructure)

- **Postgres** : Base de données principale
- **Redis** : Queues de tâches Karton

---

## Problèmes rencontrés et résolus

### Problème 1 : Tâches bloquées à 0%

**Symptôme** : Les tâches restaient à 0% de progression malgré l'envoi réussi.

**Cause** : Le service `karton-system` n'était pas déployé. Sans ce service, les tâches restent dans `karton.task:UID` mais ne sont jamais routées vers les queues des modules.

**Solution** : Déploiement du service `karton-system` avec contournement du problème S3.

### Problème 2 : karton-system crash à cause de S3

**Symptôme** : `karton-system` crashait avec l'erreur :
```
RuntimeError: Missing S3 configuration
ou
EndpointConnectionError: Could not connect to the endpoint URL
```

**Cause** : 
- `karton-system` vérifie le bucket S3 au démarrage, même avec `--disable-gc`
- Railway ne fournit pas de service S3
- C'est une limitation de design de Karton, pas un bug

**Solution** :
1. Création de `karton-system-wrapper.py` qui patche `ensure_bucket_exists()`
2. Configuration S3 factice dans `karton.ini`
3. Utilisation de `--disable-gc` pour désactiver le garbage collection

### Problème 3 : Configuration Karton dynamique

**Symptôme** : Besoin de générer `karton.ini` depuis les variables d'environnement Railway.

**Solution** : Création de `generate-karton-config.py` qui :
- Parse `REDIS_CONN_STR` depuis les variables d'environnement
- Génère `karton.ini` avec la bonne configuration Redis
- Inclut une section S3 factice (requis par Karton)

### Problème 4 : Groupement des modules pour optimiser les coûts

**Symptôme** : Déployer chaque module comme service séparé serait très coûteux.

**Solution** : 
- Création de `start-multiple-modules.sh` pour exécuter plusieurs modules en parallèle
- Groupement des modules par catégorie dans 4 services workers
- Réduction significative des coûts

### Problème 5 : Logging insuffisant pour le débogage

**Symptôme** : Difficile de comprendre pourquoi les tâches n'étaient pas routées.

**Solution** : Ajout de logging extensif dans `artemis/producer.py` pour :
- Vérifier les binds enregistrés
- Vérifier les queues Redis
- Vérifier le stockage des tâches
- Détecter les problèmes de routing

---

## Services Railway

### Configuration des variables d'environnement

Tous les services nécessitent :

```bash
REDIS_CONN_STR=${{Redis.REDIS_URL}}
POSTGRES_CONN_STR=${{Postgres.DATABASE_URL}}
```

### Services workers

Les services workers nécessitent également :

```bash
MODULES=module1,module2,module3  # Liste des modules à exécuter
```

### Service karton-system

Le service `karton-system` nécessite uniquement :

```bash
REDIS_CONN_STR=${{Redis.REDIS_URL}}
```

---

## Configuration requise

### Services Railway nécessaires

1. **Postgres** : Base de données
2. **Redis** : Queues de tâches
3. **artemis-scanner** : Service principal
4. **karton-system** : ⚠️ **ESSENTIEL** pour le routing
5. **karton-core-workers** : Modules principaux
6. **karton-scanners** : Scanners
7. **karton-webapp-scanners** : Scanners d'applications web
8. **karton-brute-specialized** : Brute force
9. **karton-dashboard** : (Optionnel) Interface de monitoring

### Variables d'environnement

#### Tous les services
- `REDIS_CONN_STR` : URL Redis (généralement `${{Redis.REDIS_URL}}`)
- `POSTGRES_CONN_STR` : URL PostgreSQL (généralement `${{Postgres.DATABASE_URL}}`)

#### Services workers uniquement
- `MODULES` : Liste des modules à exécuter (séparés par des virgules)

#### Service artemis-scanner uniquement
- `CUSTOM_USER_AGENT` : User-Agent personnalisé (optionnel)

---

## Points importants

### ⚠️ karton-system est essentiel

**Sans `karton-system`, les tâches ne seront jamais routées vers les modules.** C'est le composant qui :
- Lit les tâches depuis la queue unrouted (`karton.tasks`)
- Vérifie les binds enregistrés par les modules
- Route les tâches vers les queues appropriées
- Gère le forking si une tâche correspond à plusieurs modules

### 🔧 Contournement S3

Le problème S3 est une **limitation de design de Karton**, pas un bug. Karton suppose que S3 est toujours disponible, même si on ne l'utilise pas. La solution utilise un wrapper Python pour contourner cette vérification.

### 💰 Optimisation des coûts

Les modules sont groupés dans 4 services workers au lieu d'un service par module, ce qui réduit significativement les coûts sur Railway.

### 📊 Monitoring

Les logs de `artemis-scanner` et des services workers montrent l'activité des modules. Le service `karton-dashboard` (optionnel) fournit une interface web pour visualiser les queues Karton.

---

## Résumé des changements

### Fichiers créés (nouveaux)
- 4 Dockerfiles pour Railway
- 5 scripts de configuration/démarrage
- 3 fichiers de configuration Railway (JSON)
- 3 scripts PowerShell
- 3 fichiers de documentation

### Fichiers modifiés
- `artemis/producer.py` : Logging amélioré et correction du type de tâche

### Architecture
- Passage d'un déploiement Docker Compose local à un déploiement multi-services sur Railway
- Groupement des modules pour optimiser les coûts
- Configuration dynamique depuis les variables d'environnement

### Problèmes résolus
- Routing des tâches (karton-system)
- Problème S3 (wrapper Python)
- Configuration dynamique (scripts de génération)
- Optimisation des coûts (groupement des modules)

---

## État actuel

✅ **Tout fonctionne correctement** :
- Les tâches sont routées correctement
- Les modules consomment et traitent les tâches
- Les analyses progressent normalement
- Le système est opérationnel sur Railway

---

## Références

- [RAILWAY_DEPLOY.md](RAILWAY_DEPLOY.md) : Guide de déploiement principal
- [RAILWAY_KARTON_SYSTEM.md](RAILWAY_KARTON_SYSTEM.md) : Documentation karton-system
- [RAILWAY_KARTON_DASHBOARD.md](RAILWAY_KARTON_DASHBOARD.md) : Documentation Karton Dashboard
