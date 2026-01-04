# Script pour créer le service karton-system sur Railway
# Ce service est nécessaire pour router les tâches depuis la queue unrouted vers les queues des modules

Write-Host "=== Création du service karton-system sur Railway ===" -ForegroundColor Cyan

# Vérifier que Railway CLI est installé
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Erreur: Railway CLI n'est pas installé." -ForegroundColor Red
    Write-Host "Installez-le avec: npm install -g @railway/cli" -ForegroundColor Yellow
    exit 1
}

# Vérifier que nous sommes dans le bon répertoire
if (-not (Test-Path "Dockerfile.karton-system.railway")) {
    Write-Host "Erreur: Dockerfile.karton-system.railway introuvable." -ForegroundColor Red
    Write-Host "Assurez-vous d'être dans le répertoire du projet Artemis-SCANNER." -ForegroundColor Yellow
    exit 1
}

Write-Host ""
Write-Host "Instructions pour créer le service karton-system:" -ForegroundColor Yellow
Write-Host "1. Allez sur https://railway.app et ouvrez votre projet" -ForegroundColor White
Write-Host "2. Cliquez sur 'New Service' ou '+' pour ajouter un service" -ForegroundColor White
Write-Host "3. Sélectionnez 'GitHub Repo' et choisissez votre dépôt Artemis-SCANNER" -ForegroundColor White
Write-Host "4. Nommez le service 'karton-system'" -ForegroundColor White
Write-Host "5. Dans les paramètres du service, configurez:" -ForegroundColor White
Write-Host "   - Root Directory: / (racine du projet)" -ForegroundColor Gray
Write-Host "   - Dockerfile Path: Dockerfile.karton-system.railway" -ForegroundColor Gray
Write-Host "6. Ajoutez les variables d'environnement suivantes:" -ForegroundColor White
Write-Host "   - REDIS_CONN_STR: (la même valeur que pour les autres services)" -ForegroundColor Gray
Write-Host ""
Write-Host "OU utilisez Railway CLI pour créer le service via le dashboard web." -ForegroundColor Yellow
Write-Host ""
Write-Host "Une fois le service créé, vous pouvez le lier avec:" -ForegroundColor Cyan
Write-Host "  railway link --service karton-system" -ForegroundColor White
Write-Host ""

# Vérifier si le service existe déjà
Write-Host "Vérification des services existants..." -ForegroundColor Cyan
railway service list 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "Services Railway disponibles:" -ForegroundColor Green
    railway service list
}
