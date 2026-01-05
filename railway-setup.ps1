# Script de configuration Railway pour Artemis Scanner
# Exécutez ce script après avoir installé Railway CLI et vous être connecté

param(
    [string]$ProjectName = "artemis-scanner"
)

Write-Host "=== Configuration Railway pour Artemis Scanner ===" -ForegroundColor Cyan

# Vérifier si Railway CLI est installé
if (-not (Get-Command railway -ErrorAction SilentlyContinue)) {
    Write-Host "Railway CLI n'est pas installé. Exécutez d'abord .\install-railway-cli.ps1" -ForegroundColor Red
    exit 1
}

# Vérifier si l'utilisateur est connecté
Write-Host "`nVérification de la connexion Railway..." -ForegroundColor Yellow
$loginCheck = railway whoami 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "Vous n'êtes pas connecté à Railway. Exécutez : railway login" -ForegroundColor Red
    exit 1
}

Write-Host "Connecté en tant que : $loginCheck" -ForegroundColor Green

# Créer le projet si nécessaire
Write-Host "`nCréation/liaison du projet Railway..." -ForegroundColor Yellow
railway init --name $ProjectName

if ($LASTEXITCODE -ne 0) {
    Write-Host "Erreur lors de la création du projet" -ForegroundColor Red
    exit 1
}

Write-Host "`n=== Instructions pour configurer les services ===" -ForegroundColor Cyan
Write-Host "1. Allez sur https://railway.app et ouvrez votre projet" -ForegroundColor Yellow
Write-Host "2. Ajoutez les services suivants :" -ForegroundColor Yellow
Write-Host "   - PostgreSQL" -ForegroundColor White
Write-Host "   - Redis" -ForegroundColor White
Write-Host "   (Note: MongoDB n'est plus nécessaire, Artemis utilise uniquement PostgreSQL et Redis)" -ForegroundColor Gray
Write-Host "3. Dans votre service web, configurez les variables d'environnement :" -ForegroundColor Yellow
Write-Host "   POSTGRES_CONN_STR=`${{Postgres.DATABASE_URL}}" -ForegroundColor White
Write-Host "   REDIS_CONN_STR=`${{Redis.REDIS_URL}}" -ForegroundColor White
Write-Host "   CUSTOM_USER_AGENT=Artemis-Scanner" -ForegroundColor White
Write-Host "   (Remplacez Postgres, Redis par les noms exacts de vos services)" -ForegroundColor Gray

Write-Host "`n=== Commandes utiles ===" -ForegroundColor Cyan
Write-Host "Déployer : railway up" -ForegroundColor Yellow
Write-Host "Voir les logs : railway logs" -ForegroundColor Yellow
Write-Host "Générer un domaine : railway domain" -ForegroundColor Yellow
Write-Host "Voir les variables : railway variables" -ForegroundColor Yellow

Write-Host "`nConfiguration terminée!" -ForegroundColor Green
