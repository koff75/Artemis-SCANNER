# Déploiement de karton-system sur Railway

## Problème résolu

Le composant `karton-system` est **essentiel** pour le fonctionnement d'Artemis. Il route les tâches depuis la queue "unrouted" (`karton.tasks`) vers les queues spécifiques des modules (par exemple, `karton.queue.normal:classifier`).

**Sans ce service, les tâches restent dans `karton.task:UID` mais ne sont jamais routées vers les queues des modules, ce qui explique pourquoi les tâches restent à 0%.**

## Instructions de déploiement

### Option 1 : Via le Dashboard Railway (Recommandé)

1. Allez sur https://railway.app et ouvrez votre projet Artemis-SCANNER
2. Cliquez sur **"New Service"** ou **"+"** pour ajouter un service
3. Sélectionnez **"GitHub Repo"** et choisissez votre dépôt `Artemis-SCANNER`
4. Nommez le service **`karton-system`**
5. Dans les paramètres du service (Settings → Build & Deploy) :
   - **Root Directory**: `/` (racine du projet)
   - **Dockerfile Path**: `Dockerfile.karton-system.railway`
6. Dans **Variables**, ajoutez :
   - **`REDIS_CONN_STR`**: La même valeur que pour les autres services (généralement `${{Redis.REDIS_URL}}`)

### Option 2 : Via Railway CLI

Si vous préférez utiliser la ligne de commande, créez le service manuellement dans le dashboard, puis liez-le :

```powershell
# Lier le service une fois créé
railway link --service karton-system
```

## Vérification

Une fois le service déployé, vérifiez les logs :

```powershell
railway logs --service karton-system
```

Vous devriez voir :
- `Generated /etc/karton/karton.ini from REDIS_CONN_STR`
- `karton-system` démarrant avec les options `--setup-bucket --gc-interval 14400`

## Fonctionnement

Le service `karton-system` :
1. **Lit les tâches** depuis la queue unrouted (`karton.tasks`)
2. **Vérifie les binds** enregistrés par les modules
3. **Route les tâches** vers les queues appropriées basées sur les filtres des binds
4. **Gère le forking** si une tâche correspond à plusieurs modules
5. **Nettoie** les tâches terminées (garbage collection)

## Coût

Ce service est très léger (consomme peu de ressources) car il ne fait que router les tâches. Il ne traite pas les tâches lui-même.

## Après le déploiement

Une fois `karton-system` déployé et fonctionnel :
1. Les tâches envoyées par `artemis-scanner` seront automatiquement routées
2. Les modules pourront consommer les tâches depuis leurs queues
3. Les tâches devraient progresser au lieu de rester à 0%
