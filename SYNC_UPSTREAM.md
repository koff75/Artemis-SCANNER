# Guide de Synchronisation avec le Repo Upstream Artemis

Ce guide explique comment synchroniser votre fork avec le dépôt original `CERT-Polska/Artemis` tout en préservant vos modifications Railway.

## 📋 Prérequis

- Git installé
- Accès au dépôt GitHub (authentifié)
- Vos modifications Railway commitées ou sauvegardées

## 🚀 Méthode Rapide (Script Automatique)

### Première utilisation

1. **Exécutez le script de synchronisation :**
   ```powershell
   .\sync-upstream.ps1
   ```

2. Le script va :
   - Configurer automatiquement le remote `upstream`
   - Récupérer les dernières modifications
   - Fusionner les changements
   - Vous alerter en cas de conflits

### Mode Dry-Run (simulation)

Pour voir ce qui se passerait sans appliquer les changements :
```powershell
.\sync-upstream.ps1 -DryRun
```

## 🔧 Méthode Manuelle

### Étape 1: Configurer le remote upstream

```powershell
# Ajouter le remote upstream (une seule fois)
git remote add upstream https://github.com/CERT-Polska/Artemis.git

# Vérifier les remotes
git remote -v
```

### Étape 2: Récupérer les modifications

```powershell
# Récupérer les dernières modifications d'upstream
git fetch upstream main

# Voir les différences
git log HEAD..upstream/main --oneline
```

### Étape 3: Fusionner les modifications

**Option A: Merge (recommandé pour préserver l'historique)**

```powershell
# S'assurer d'être sur votre branche principale
git checkout main

# Fusionner les modifications
git merge upstream/main
```

**Option B: Rebase (historique linéaire, mais plus risqué)**

```powershell
git rebase upstream/main
```

### Étape 4: Résoudre les conflits

Si des conflits apparaissent :

1. **Identifier les fichiers en conflit :**
   ```powershell
   git status
   ```

2. **Ouvrir les fichiers et résoudre manuellement :**
   - Cherchez les marqueurs `<<<<<<< HEAD`, `=======`, `>>>>>>> upstream/main`
   - Gardez vos modifications Railway
   - Intégrez les changements upstream pertinents

3. **Marquer comme résolu :**
   ```powershell
   git add <fichier-résolu>
   ```

4. **Finaliser la fusion :**
   ```powershell
   git commit
   ```

## 📁 Fichiers Railway à Préserver

Ces fichiers sont spécifiques à votre configuration Railway et doivent être préservés :

- `Dockerfile.worker.railway`
- `Dockerfile.karton-system.railway`
- `Dockerfile.web.railway`
- `Dockerfile.karton-dashboard`
- `docker/generate-karton-config.py`
- `docker/karton.ini`
- `docker/start-multiple-modules.sh`
- `docker/karton-system-wrapper.py`
- `karton-dashboard-service/`
- `railway-setup.ps1`
- `railway.karton-system.json`
- Tous les fichiers `RAILWAY_*.md`

## ⚠️ Gestion des Conflits Courants

### Conflit dans les Dockerfiles

Si upstream modifie `Dockerfile` mais vous avez `Dockerfile.worker.railway` :
- **Pas de conflit** : Ce sont des fichiers différents
- **Action** : Aucune action nécessaire

### Conflit dans `docker/generate-karton-config.py`

Si upstream modifie ce fichier :
1. Comparez les changements : `git diff upstream/main docker/generate-karton-config.py`
2. Intégrez les améliorations upstream
3. Préservez vos modifications Railway (génération depuis `REDIS_CONN_STR`)

### Conflit dans `docker/karton.ini`

Si upstream modifie ce fichier :
- **Généralement pas de problème** : Votre script `generate-karton-config.py` le régénère`
- **Action** : Vérifiez que votre script génère toujours correctement

## 🔄 Workflow Recommandé

### Avant chaque synchronisation

1. **Sauvegarder votre travail :**
   ```powershell
   git status
   git add .
   git commit -m "WIP: Modifications Railway avant sync upstream"
   ```

2. **Créer une branche de sauvegarde (optionnel mais recommandé) :**
   ```powershell
   git branch backup-railway-$(Get-Date -Format "yyyyMMdd")
   ```

### Après la synchronisation

1. **Tester votre configuration :**
   - Vérifier que les Dockerfiles Railway fonctionnent
   - Tester un déploiement Railway en staging si possible

2. **Commiter et pousser :**
   ```powershell
   git commit -m "Merge upstream Artemis - $(Get-Date -Format 'yyyy-MM-dd')"
   git push origin main
   ```

## 📊 Vérifier l'état de synchronisation

```powershell
# Voir combien de commits vous êtes en retard
git fetch upstream
git rev-list --count HEAD..upstream/main

# Voir les commits upstream que vous n'avez pas
git log HEAD..upstream/main --oneline

# Voir vos commits qui ne sont pas dans upstream
git log upstream/main..HEAD --oneline
```

## 🆘 En cas de problème

### Annuler une fusion en cours

```powershell
git merge --abort
```

### Annuler un rebase en cours

```powershell
git rebase --abort
```

### Restaurer depuis une sauvegarde

```powershell
git checkout backup-railway-YYYYMMDD
git branch -D main
git checkout -b main
```

## 📅 Fréquence recommandée

- **Hebdomadaire** : Si Artemis est très actif
- **Mensuelle** : Pour un suivi régulier
- **Avant chaque déploiement majeur** : Pour bénéficier des dernières corrections

## 💡 Astuces

1. **Utilisez des branches de fonctionnalité** pour vos modifications Railway
2. **Commitez souvent** pour faciliter la résolution de conflits
3. **Documentez vos modifications Railway** dans les fichiers `RAILWAY_*.md`
4. **Testez après chaque sync** avant de déployer en production

## 🔗 Ressources

- [Documentation Git - Merging](https://git-scm.com/book/en/v2/Git-Branching-Basic-Branching-and-Merging)
- [GitHub - Syncing a fork](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/working-with-forks/syncing-a-fork)
- [Repo original Artemis](https://github.com/CERT-Polska/Artemis)
