# Script pour identifier les différences entre vos fichiers Railway et upstream
# Utile pour comprendre quels fichiers vous avez modifiés

Write-Host "=== Analyse des Différences Railway vs Upstream ===" -ForegroundColor Cyan
Write-Host ""

# Vérifier que upstream est configuré
$upstreamExists = git remote | Select-String -Pattern "^upstream$"
if (-not $upstreamExists) {
    Write-Host "ERREUR: Remote upstream non configuré" -ForegroundColor Red
    Write-Host "Exécutez d'abord: git remote add upstream https://github.com/CERT-Polska/Artemis.git" -ForegroundColor Yellow
    exit 1
}

# Récupérer les dernières modifications
Write-Host "Récupération des dernières modifications d'upstream..." -ForegroundColor Yellow
git fetch upstream main -q
Write-Host "✓ Fait" -ForegroundColor Green
Write-Host ""

# Fichiers Railway spécifiques (n'existent pas dans upstream)
$railwaySpecificFiles = @(
    "Dockerfile.worker.railway",
    "Dockerfile.karton-system.railway",
    "Dockerfile.web.railway",
    "Dockerfile.karton-dashboard",
    "railway-setup.ps1",
    "railway.karton-system.json",
    "karton-dashboard-service/railway.json"
)

Write-Host "=== Fichiers Railway Spécifiques (n'existent pas dans upstream) ===" -ForegroundColor Cyan
foreach ($file in $railwaySpecificFiles) {
    if (Test-Path $file) {
        Write-Host "  ✓ $file" -ForegroundColor Green
    } else {
        Write-Host "  ✗ $file (manquant)" -ForegroundColor Red
    }
}
Write-Host ""

# Fichiers modifiés par rapport à upstream
Write-Host "=== Fichiers Modifiés par Rapport à Upstream ===" -ForegroundColor Cyan

$modifiedFiles = git diff --name-only upstream/main HEAD
if ($modifiedFiles) {
    foreach ($file in $modifiedFiles) {
        $status = git diff --stat upstream/main HEAD -- $file
        Write-Host "  📝 $file" -ForegroundColor Yellow
        Write-Host "     $status" -ForegroundColor Gray
    }
} else {
    Write-Host "  Aucun fichier modifié" -ForegroundColor Green
}
Write-Host ""

# Fichiers qui existent dans upstream mais pas dans votre fork
Write-Host "=== Fichiers dans Upstream mais Absents Localement ===" -ForegroundColor Cyan
$upstreamFiles = git ls-tree -r --name-only upstream/main
$localFiles = git ls-tree -r --name-only HEAD

$missingFiles = $upstreamFiles | Where-Object { $localFiles -notcontains $_ }
if ($missingFiles) {
    foreach ($file in $missingFiles) {
        # Ignorer les fichiers qui sont normaux d'etre differents (submodules, etc.)
        if ($file -notmatch "Artemis-modules-extra" -and $file -notmatch "\.git") {
            Write-Host "  ⚠ $file" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "  Aucun fichier manquant" -ForegroundColor Green
}
Write-Host ""

# Statistiques
Write-Host "=== Statistiques ===" -ForegroundColor Cyan
$commitsBehind = (git rev-list --count HEAD..upstream/main)
$commitsAhead = (git rev-list --count upstream/main..HEAD)

Write-Host "  Commits en retard sur upstream: $commitsBehind" -ForegroundColor $(if ($commitsBehind -gt 0) { "Yellow" } else { "Green" })
Write-Host "  Commits en avance sur upstream: $commitsAhead" -ForegroundColor $(if ($commitsAhead -gt 0) { "Cyan" } else { "White" })
Write-Host ""

# Recommandations
if ($commitsBehind -gt 10) {
    Write-Host "⚠ RECOMMANDATION: Vous êtes $commitsBehind commits en retard!" -ForegroundColor Yellow
    Write-Host "  Exécutez .\sync-upstream.ps1 pour synchroniser" -ForegroundColor White
}
