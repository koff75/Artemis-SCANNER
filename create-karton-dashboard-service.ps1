# Script pour créer le service karton-dashboard dans le projet Railway existant
# Note: Railway CLI ne permet pas de créer un nouveau service via la ligne de commande
# Ce script guide l'utilisateur pour créer le service via le Dashboard

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Création du service karton-dashboard sur Railway" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Le MCP Railway ne permet pas de créer un nouveau service directement." -ForegroundColor Yellow
Write-Host "Vous devez créer le service manuellement via le Dashboard Railway." -ForegroundColor Yellow
Write-Host ""

Write-Host "Étapes à suivre :" -ForegroundColor Green
Write-Host "1. Allez sur : https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307" -ForegroundColor White
Write-Host "2. Cliquez sur '+ New' → 'Empty Service'" -ForegroundColor White
Write-Host "3. Nommez le service : karton-dashboard" -ForegroundColor White
Write-Host "4. Dans les paramètres du service :" -ForegroundColor White
Write-Host "   - Source : Connectez le même dépôt GitHub que artemis-scanner" -ForegroundColor White
Write-Host "   - Root Directory : karton-dashboard-service" -ForegroundColor White
Write-Host "   - Ou utilisez la variable RAILWAY_DOCKERFILE_PATH=Dockerfile.karton-dashboard depuis la racine" -ForegroundColor White
Write-Host ""

Write-Host "Une fois le service créé, dites-moi et je configurerai :" -ForegroundColor Green
Write-Host "- Les variables d'environnement (REDIS_CONN_STR)" -ForegroundColor White
Write-Host "- L'URL du dashboard dans le service principal" -ForegroundColor White
Write-Host ""

Read-Host "Appuyez sur Entrée pour ouvrir le Dashboard Railway dans votre navigateur"

# Ouvrir le Dashboard Railway
Start-Process "https://railway.app/project/badbaba7-0e07-4a15-a6e7-f542f5282307"
