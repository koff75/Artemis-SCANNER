# Script d'installation de Railway CLI pour Windows
# Exécutez ce script avec : .\install-railway-cli.ps1

Write-Host "Installation de Railway CLI..." -ForegroundColor Green

# Vérifier si Railway CLI est déjà installé
if (Get-Command railway -ErrorAction SilentlyContinue) {
    Write-Host "Railway CLI est déjà installé." -ForegroundColor Yellow
    railway --version
    exit 0
}

# Installer Railway CLI
try {
    Invoke-WebRequest -Uri "https://railway.app/install.ps1" -UseBasicParsing | Invoke-Expression
    Write-Host "Railway CLI installé avec succès!" -ForegroundColor Green
    
    # Ajouter au PATH si nécessaire
    $railwayPath = "$env:USERPROFILE\.railway\bin"
    if ($env:PATH -notlike "*$railwayPath*") {
        Write-Host "Ajout de Railway au PATH..." -ForegroundColor Yellow
        [Environment]::SetEnvironmentVariable("Path", $env:Path + ";$railwayPath", "User")
        $env:Path += ";$railwayPath"
    }
    
    Write-Host "`nVérification de l'installation..." -ForegroundColor Cyan
    railway --version
    
    Write-Host "`nPour vous connecter, exécutez : railway login" -ForegroundColor Cyan
} catch {
    Write-Host "Erreur lors de l'installation : $_" -ForegroundColor Red
    Write-Host "`nInstallation manuelle :" -ForegroundColor Yellow
    Write-Host "1. Téléchargez Railway CLI depuis : https://docs.railway.com/guides/cli" -ForegroundColor Yellow
    Write-Host "2. Ou utilisez : winget install Railway.Railway" -ForegroundColor Yellow
    exit 1
}
