# Script pour synchroniser les mises à jour du repo upstream Artemis
# tout en préservant les modifications Railway

param(
    [switch]$DryRun = $false,
    [string]$UpstreamBranch = "main"
)

Write-Host "=== Synchronisation Artemis Upstream ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier qu'on est dans un repo git
if (-not (Test-Path .git)) {
    Write-Host "ERREUR: Ce script doit être exécuté depuis la racine du dépôt Git" -ForegroundColor Red
    exit 1
}

# Vérifier l'état du working directory
$gitStatus = git status --porcelain
if ($gitStatus -and -not $DryRun) {
    Write-Host "ATTENTION: Vous avez des modifications non commitées:" -ForegroundColor Yellow
    Write-Host $gitStatus -ForegroundColor Yellow
    Write-Host ""
    # En mode non-interactif, continuer automatiquement
    if ([Environment]::UserInteractive) {
        $response = Read-Host "Voulez-vous continuer? Les modifications seront préservées mais vous devrez les commiter après (o/N)"
        if ($response -ne "o" -and $response -ne "O") {
            Write-Host "Annulé." -ForegroundColor Yellow
            exit 0
        }
    } else {
        Write-Host "Mode non-interactif: continuation automatique..." -ForegroundColor Cyan
    }
}

# Étape 1: Ajouter le remote upstream s'il n'existe pas
Write-Host "Étape 1: Configuration du remote upstream..." -ForegroundColor Yellow
$upstreamExists = git remote | Select-String -Pattern "^upstream$"
if (-not $upstreamExists) {
    Write-Host "  Ajout du remote upstream: https://github.com/CERT-Polska/Artemis.git" -ForegroundColor Green
    git remote add upstream https://github.com/CERT-Polska/Artemis.git
} else {
    Write-Host "  Remote upstream déjà configuré" -ForegroundColor Green
    $currentUpstream = git remote get-url upstream
    if ($currentUpstream -ne "https://github.com/CERT-Polska/Artemis.git") {
        Write-Host "  Mise à jour de l'URL upstream..." -ForegroundColor Yellow
        git remote set-url upstream https://github.com/CERT-Polska/Artemis.git
    }
}

# Étape 2: Récupérer les dernières modifications d'upstream
Write-Host ""
Write-Host "Étape 2: Récupération des dernières modifications d'upstream..." -ForegroundColor Yellow
git fetch upstream $UpstreamBranch
if ($LASTEXITCODE -ne 0) {
    Write-Host "ERREUR: Impossible de récupérer les modifications d'upstream" -ForegroundColor Red
    exit 1
}
Write-Host "  ✓ Modifications récupérées" -ForegroundColor Green

# Étape 3: Vérifier les différences
Write-Host ""
Write-Host "Étape 3: Analyse des différences..." -ForegroundColor Yellow
$currentBranch = git rev-parse --abbrev-ref HEAD
$upstreamCommit = git rev-parse upstream/$UpstreamBranch
$currentCommit = git rev-parse HEAD

Write-Host "  Branche actuelle: $currentBranch" -ForegroundColor White
Write-Host "  Commit actuel: $currentCommit" -ForegroundColor White
Write-Host "  Commit upstream: $upstreamCommit" -ForegroundColor White

# Vérifier si on est en avance ou en retard
$mergeBase = git merge-base HEAD upstream/$UpstreamBranch
$commitsBehind = (git rev-list --count $mergeBase..upstream/$UpstreamBranch)
$commitsAhead = (git rev-list --count $mergeBase..HEAD)

Write-Host ""
Write-Host "  Commits en retard sur upstream: $commitsBehind" -ForegroundColor $(if ($commitsBehind -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Commits en avance sur upstream: $commitsAhead" -ForegroundColor $(if ($commitsAhead -gt 0) { "Cyan" } else { "White" })

if ($commitsBehind -eq 0) {
    Write-Host ""
    Write-Host "✓ Vous êtes déjà à jour avec upstream!" -ForegroundColor Green
    exit 0
}

# Étape 4: Identifier les fichiers modifiés pour Railway
Write-Host ""
Write-Host "Étape 4: Identification des fichiers Railway modifiés..." -ForegroundColor Yellow
$railwayFiles = @(
    "Dockerfile.karton-dashboard",
    "Dockerfile.worker.railway",
    "Dockerfile.karton-system.railway",
    "Dockerfile.web.railway",
    "docker/generate-karton-config.py",
    "docker/karton.ini",
    "docker/start-multiple-modules.sh",
    "docker/karton-system-wrapper.py",
    "docker/generate-karton-config-system.py",
    "karton-dashboard-service/",
    "railway-setup.ps1",
    "railway.karton-system.json",
    "*.railway.*",
    "RAILWAY_*.md"
)

$modifiedFiles = @()
foreach ($file in $railwayFiles) {
    if (Test-Path $file) {
        $status = git status --porcelain $file
        if ($status) {
            $modifiedFiles += $file
        }
    }
}

if ($modifiedFiles.Count -gt 0) {
    Write-Host "  Fichiers Railway détectés:" -ForegroundColor Cyan
    foreach ($file in $modifiedFiles) {
        Write-Host "    - $file" -ForegroundColor White
    }
} else {
    Write-Host "  Aucun fichier Railway modifié détecté" -ForegroundColor Gray
}

# Étape 5: Fusion (merge) ou rebase
Write-Host ""
Write-Host "Étape 5: Fusion des modifications..." -ForegroundColor Yellow

if ($DryRun) {
    Write-Host "  [DRY RUN] Simulation de la fusion..." -ForegroundColor Cyan
    Write-Host "  Commandes qui seraient exécutées:" -ForegroundColor Cyan
    Write-Host "    git merge upstream/$UpstreamBranch --no-commit" -ForegroundColor White
    Write-Host ""
    Write-Host "  Pour appliquer réellement, exécutez sans -DryRun" -ForegroundColor Yellow
    exit 0
}

# Utiliser merge pour préserver l'historique
Write-Host "  Fusion des modifications d'upstream..." -ForegroundColor White
git merge upstream/$UpstreamBranch --no-commit --no-ff

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "⚠ CONFLITS DÉTECTÉS!" -ForegroundColor Red
    Write-Host ""
    Write-Host "Des conflits doivent être résolus manuellement." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Fichiers en conflit:" -ForegroundColor Yellow
    git diff --name-only --diff-filter=U | ForEach-Object {
        Write-Host "  - $_" -ForegroundColor White
    }
    Write-Host ""
    Write-Host "Pour résoudre les conflits:" -ForegroundColor Cyan
    Write-Host "  1. Ouvrez les fichiers en conflit" -ForegroundColor White
    Write-Host "  2. Cherchez les marqueurs <<<<<<< HEAD" -ForegroundColor White
    Write-Host "  3. Gardez vos modifications Railway et intégrez les changements upstream" -ForegroundColor White
    Write-Host "  4. Une fois résolu, exécutez: git add <fichier>" -ForegroundColor White
    Write-Host "  5. Puis: git commit" -ForegroundColor White
    Write-Host ""
    Write-Host "Pour annuler la fusion: git merge --abort" -ForegroundColor Yellow
    exit 1
}

# Si pas de conflits, finaliser le commit
Write-Host "  ✓ Fusion réussie sans conflits" -ForegroundColor Green
Write-Host ""
Write-Host "Étape 6: Finalisation..." -ForegroundColor Yellow

# Vérifier les fichiers Railway pour s'assurer qu'ils sont toujours présents
$railwayFilesMissing = @()
foreach ($file in @("Dockerfile.worker.railway", "Dockerfile.karton-system.railway", "Dockerfile.web.railway")) {
    if (-not (Test-Path $file)) {
        $railwayFilesMissing += $file
    }
}

if ($railwayFilesMissing.Count -gt 0) {
    Write-Host "  ⚠ ATTENTION: Fichiers Railway manquants après fusion:" -ForegroundColor Red
    foreach ($file in $railwayFilesMissing) {
        Write-Host "    - $file" -ForegroundColor Red
    }
    Write-Host "  Vérifiez que ces fichiers n'ont pas été supprimés par erreur!" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "✓ Synchronisation terminée!" -ForegroundColor Green
Write-Host ""
Write-Host "Prochaines étapes:" -ForegroundColor Cyan
Write-Host "  1. Vérifiez les modifications: git status" -ForegroundColor White
Write-Host "  2. Testez votre configuration Railway" -ForegroundColor White
Write-Host "  3. Commitez les changements: git commit -m `"Merge upstream Artemis`"" -ForegroundColor White
Write-Host "  4. Poussez vers votre repo: git push origin $currentBranch" -ForegroundColor White

