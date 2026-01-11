# Diagnostic karton-system

Ce document explique comment diagnostiquer les problèmes avec karton-system sur Railway.

## Problèmes courants

### 1. karton-system démarre mais ne traite pas de tâches

**Symptômes :**
- Le service démarre (`Manager karton.system started`)
- Aucune activité "Processing task" dans les logs
- Des tâches restent en attente dans l'interface web

**Diagnostic :**
```powershell
.\scripts\diagnose-karton-system.ps1
```

**Causes possibles :**
- karton-system ne lit pas la queue `karton.tasks` (unrouted)
- Problème de connexion Redis (lecture seule)
- Service bloqué/en attente
- Les tâches sont dans une queue différente

**Solutions :**
1. Redémarrer karton-system : `railway restart --service karton-system`
2. Vérifier les logs pour des erreurs Redis
3. Vérifier que Redis est accessible

### 2. karton-system s'arrête après ~1000 tâches

**Symptômes :**
- Le service traite ~980-1000 tâches puis s'arrête
- Message "Exiting loop after processing X tasks" (si visible)
- Les tâches restantes ne sont pas routées

**Cause :**
- Limite `MAX_NUM_TASKS_TO_PROCESS` (défaut: 1000)
- Conçu pour prévenir les fuites mémoire
- Railway ne redémarre pas automatiquement sur arrêt normal

**Solutions :**
1. Redémarrer manuellement : `railway restart --service karton-system`
2. Augmenter la limite via variable d'environnement : `MAX_NUM_TASKS_TO_PROCESS=5000`
3. Configurer Railway pour redémarrer automatiquement (voir ci-dessous)

### 3. karton-system redémarre en boucle

**Symptômes :**
- Messages "Got signal, shutting down..." répétés
- Services qui redémarrent constamment
- Erreurs PostgreSQL "Connection reset by peer"

**Causes possibles :**
- Redéploiements automatiques Railway (nouveau commit)
- Crashes silencieux
- Problèmes de ressources (mémoire, CPU)

**Solutions :**
1. Vérifier les logs pour identifier la cause du crash
2. Vérifier les ressources allouées au service
3. Désactiver les redéploiements automatiques si nécessaire

## Outils de diagnostic

### Script PowerShell

```powershell
.\scripts\diagnose-karton-system.ps1
```

Vérifie :
- État du service
- Activité récente
- Nombre de tâches traitées
- Erreurs et warnings
- Heartbeats (si diagnostic activé)
- Recommandations

### Vérification manuelle

#### 1. Vérifier les logs récents
```powershell
railway logs --service karton-system --lines 50
```

#### 2. Compter les tâches traitées
```powershell
railway logs --service karton-system --lines 1000 | Select-String "Processing task" | Measure-Object
```

#### 3. Vérifier les heartbeats (si activé)
```powershell
railway logs --service karton-system --lines 100 | Select-String "HEARTBEAT"
```

#### 4. Vérifier l'état des workers
```powershell
railway logs --service karton-brute-specialized --lines 10
railway logs --service karton-webapp-scanners --lines 10
```

## Améliorations du diagnostic

### Heartbeats automatiques

Le wrapper `karton-system-wrapper.py` a été amélioré pour :
- Logger un heartbeat toutes les 5 minutes
- Afficher le nombre de tâches unrouted dans la queue
- Capturer et logger les exceptions
- Fournir plus de contexte sur l'état du service

### Activation

Les heartbeats sont automatiquement activés avec le nouveau wrapper. Pour les activer :
1. S'assurer que `docker/karton-system-wrapper.py` contient le code amélioré
2. Redéployer le service : `railway redeploy --service karton-system`

### Exemple de logs avec diagnostic

```
[2026-01-11 10:00:00][INFO] Starting karton-system wrapper
[2026-01-11 10:00:01][INFO] Patched karton-system to skip S3 bucket check
[2026-01-11 10:00:02][INFO] Added diagnostic logging to karton-system
[2026-01-11 10:00:03][INFO] Starting karton-system SystemService.main()
[2026-01-11 10:05:00][INFO] [HEARTBEAT] karton-system is alive. Unrouted tasks in queue: 92
[2026-01-11 10:10:00][INFO] [HEARTBEAT] karton-system is alive. Unrouted tasks in queue: 85
```

## Configuration Railway

### Redémarrage automatique

Pour que Railway redémarre automatiquement karton-system :

1. Modifier `railway.karton-system.json` :
```json
{
  "deploy": {
    "restartPolicyType": "ALWAYS",
    "restartPolicyMaxRetries": 10
  }
}
```

2. Ou via le dashboard Railway : Settings → Restart Policy → "Always"

### Variables d'environnement utiles

- `MAX_NUM_TASKS_TO_PROCESS` : Limite de tâches avant redémarrage (défaut: 1000)
- `LOG_LEVEL` : Niveau de log (DEBUG, INFO, WARNING, ERROR)

## Points de vérification

Lorsqu'un problème survient, vérifier dans l'ordre :

1. ✅ Service démarré ? (`Manager karton.system started`)
2. ✅ Activité récente ? (`Processing task` ou `HEARTBEAT`)
3. ✅ Nombre de tâches traitées ? (proche de 1000 ?)
4. ✅ Erreurs dans les logs ? (`ERROR`, `Exception`, `Traceback`)
5. ✅ Heartbeats présents ? (si diagnostic activé)
6. ✅ Tâches dans la queue ? (interface web ou Redis)
7. ✅ Workers actifs ? (logs des services workers)

## Commandes utiles

```powershell
# Diagnostic complet
.\scripts\diagnose-karton-system.ps1

# Redémarrer karton-system
railway restart --service karton-system

# Voir les logs en temps réel
railway logs --service karton-system --follow

# Vérifier les variables d'environnement
railway variables --service karton-system

# Redéployer avec les dernières modifications
railway redeploy --service karton-system
```
