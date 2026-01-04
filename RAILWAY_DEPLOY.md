# Guide de déploiement sur Railway

Ce guide vous explique comment déployer Artemis Scanner sur Railway.

## Prérequis

1. **Installer Railway CLI** :
   - Windows : `iwr https://railway.app/install.ps1 | iex`
   - Ou téléchargez depuis : https://docs.railway.com/guides/cli

2. **Se connecter à Railway** :
   ```bash
   railway login
   ```

## Étapes de déploiement

### 1. Créer le projet Railway

```bash
railway init
```

Ou créez le projet via le MCP Railway :
- Le projet sera créé et lié automatiquement

### 2. Ajouter les services nécessaires

Artemis nécessite deux services :
- **PostgreSQL** (base de données principale)
- **Redis** (cache et queue)

**Note** : MongoDB n'est plus utilisé par Artemis. Il a été remplacé par PostgreSQL. La variable `DB_CONN_STR` (anciennement pour MongoDB) est conservée uniquement pour la compatibilité avec les anciennes versions, mais n'est pas nécessaire pour un nouveau déploiement.

#### Via Railway Dashboard :
1. Allez sur https://railway.app
2. Dans votre projet, cliquez sur "+ New"
3. Ajoutez :
   - PostgreSQL
   - Redis

#### Via CLI :
```bash
# Ajouter PostgreSQL
railway add postgresql

# Ajouter Redis
railway add redis
```

### 3. Configurer les variables d'environnement

Les variables d'environnement seront automatiquement injectées par Railway pour chaque service.

Vous devez configurer les variables suivantes dans votre service web :

```bash
# Variables de connexion (Railway les génère automatiquement)
# POSTGRES_CONN_STR - sera généré automatiquement depuis le service PostgreSQL
# REDIS_CONN_STR - sera généré automatiquement depuis le service Redis

# Variables optionnelles
CUSTOM_USER_AGENT=Artemis-Scanner
```

#### Via Railway Dashboard :
1. Sélectionnez votre service web
2. Allez dans l'onglet "Variables"
3. Ajoutez les variables nécessaires

#### Via CLI :
```bash
railway variables set CUSTOM_USER_AGENT="Artemis-Scanner"
```

### 4. Configurer les variables de connexion

Railway génère automatiquement des variables d'environnement pour chaque service. Vous devez les mapper :

Pour PostgreSQL :
- `${{ServiceName.DATABASE_URL}}` → `POSTGRES_CONN_STR`
  - Remplacez `ServiceName` par le nom exact de votre service PostgreSQL dans Railway

Pour Redis :
- `${{ServiceName.REDIS_URL}}` → `REDIS_CONN_STR`
  - Remplacez `ServiceName` par le nom exact de votre service Redis dans Railway

#### Via Railway Dashboard :
Dans les variables de votre service web, utilisez les références Railway :
- `POSTGRES_CONN_STR=${{Postgres.DATABASE_URL}}`
- `REDIS_CONN_STR=${{Redis.REDIS_URL}}`

**Important** : Les noms de services (`Postgres`, `Redis`) doivent correspondre exactement aux noms de vos services dans Railway. Si vos services ont des noms différents, utilisez ces noms à la place.

### 5. Déployer l'application

```bash
railway up
```

Ou poussez vers votre dépôt Git connecté à Railway.

### 6. Générer un domaine

```bash
railway domain
```

## Structure du projet sur Railway

- **Service Web** : Application FastAPI principale (port dynamique via $PORT)
- **Service PostgreSQL** : Base de données principale
- **Service Redis** : Cache et queue

## Notes importantes

1. **Port** : Railway définit automatiquement la variable `PORT`. L'application s'adapte automatiquement.

2. **Services multiples** : Ce déploiement ne déploie que le service web principal. Les workers Karton (karton-*) peuvent être déployés séparément si nécessaire.

3. **Volumes** : Railway ne supporte pas les volumes persistants de la même manière que Docker Compose. Les données doivent être stockées dans les bases de données.

4. **Build** : Le build peut prendre du temps car il installe Go, compile des binaires, et télécharge des templates Nuclei.

## Dépannage

### Vérifier les logs
```bash
railway logs
```

### Vérifier les variables d'environnement
```bash
railway variables
```

### Vérifier le statut
```bash
railway status
```

## Support

Pour plus d'informations, consultez :
- Documentation Railway : https://docs.railway.com
- Documentation Artemis : https://artemis-scanner.readthedocs.io
