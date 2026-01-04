# Déploiement des Workers Karton sur Railway

## Problème

Les tâches sont créées mais ne sont pas traitées car les workers Karton (modules) ne sont pas déployés. Seul le service web principal est déployé.

## Solution

Déployer les modules Karton essentiels comme services séparés sur Railway.

## Modules essentiels à déployer

1. **classifier** - Module de base qui classifie les tâches (OBLIGATOIRE)
2. **identifier** - Identifie les services
3. **port_scanner** - Scanne les ports
4. **subdomain_enumeration** - Énumère les sous-domaines
5. **http_service_to_url** - Convertit les services HTTP en URLs
6. **webapp_identifier** - Identifie les applications web

## Étapes de déploiement

### 1. Créer un service worker pour chaque module

Pour chaque module, créez un nouveau service dans Railway :

1. Allez sur https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307
2. Cliquez sur **"+ New"** → **"Empty Service"**
3. Nommez le service : `karton-{module_name}` (ex: `karton-classifier`)
4. Dans les paramètres du service :
   - **Source** : Connectez le même dépôt GitHub que `artemis-scanner`
   - **Root Directory** : `/` (racine du projet)
   - **Dockerfile Path** : Définissez la variable d'environnement `RAILWAY_DOCKERFILE_PATH=Dockerfile.worker.railway`

### 2. Configurer les variables d'environnement

Pour chaque service worker, configurez :

- `POSTGRES_CONN_STR=${{Postgres.DATABASE_URL}}`
- `REDIS_CONN_STR=${{Redis.REDIS_URL}}`
- `MODULE={module_name}` (ex: `MODULE=classifier`, `MODULE=port_scanner`, etc.)

### 3. Modules à déployer (par ordre de priorité)

#### Priorité 1 - Modules essentiels (minimum requis) :
- `karton-classifier` avec `MODULE=classifier`
- `karton-identifier` avec `MODULE=identifier`
- `karton-port_scanner` avec `MODULE=port_scanner`

#### Priorité 2 - Modules importants :
- `karton-subdomain_enumeration` avec `MODULE=subdomain_enumeration`
- `karton-http_service_to_url` avec `MODULE=http_service_to_url`
- `karton-webapp_identifier` avec `MODULE=webapp_identifier`

#### Priorité 3 - Modules optionnels (pour fonctionnalités avancées) :
- `karton-nuclei` avec `MODULE=nuclei`
- `karton-wordpress_plugins` avec `MODULE=wordpress_plugins`
- `karton-joomla_extensions` avec `MODULE=joomla_extensions`
- `karton-dns_scanner` avec `MODULE=dns_scanner`
- `karton-ip_lookup` avec `MODULE=ip_lookup`

## Exemple de configuration pour karton-classifier

1. Créez le service `karton-classifier`
2. Variables d'environnement :
   ```
   POSTGRES_CONN_STR=${{Postgres.DATABASE_URL}}
   REDIS_CONN_STR=${{Redis.REDIS_URL}}
   MODULE=classifier
   RAILWAY_DOCKERFILE_PATH=Dockerfile.worker.railway
   ```

## Vérification

Après le déploiement des workers, vérifiez :
1. Les logs de chaque service worker - ils devraient traiter des tâches
2. L'interface web - les tâches devraient progresser
3. La page `/queue` - devrait montrer les tâches en cours de traitement

## Note importante

Déployer tous les modules peut être coûteux sur Railway. Commencez par les modules essentiels (Priorité 1) et ajoutez les autres selon vos besoins.
