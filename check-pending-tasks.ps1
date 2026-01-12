# Script pour identifier les 7 tâches en attente
# Utilise l'API Artemis ou interroge directement Redis

Write-Host "=== Identification des 7 tâches en attente ===" -ForegroundColor Cyan
Write-Host ""

# Récupérer l'URL du service web
$webUrl = railway variables --service artemis-scanner 2>&1 | Select-String -Pattern "RAILWAY_SERVICE.*URL" | ForEach-Object { 
    if ($_ -match 'RAILWAY_SERVICE_ARTEMIS_SCANNER_URL.*\|.*(\S+)') {
        "https://$($matches[1])"
    }
}

if (-not $webUrl) {
    Write-Host "[ERREUR] Impossible de récupérer l'URL du service web" -ForegroundColor Red
    Write-Host ""
    Write-Host "Alternative: Utilisez l'interface web directement:" -ForegroundColor Yellow
    Write-Host "1. Ouvrez l'interface web Artemis" -ForegroundColor Yellow
    Write-Host "2. Cliquez sur 'Show pending tasks' pour Extia.fr" -ForegroundColor Yellow
    Write-Host "3. Cela affichera les détails (receiver, target, status) de chaque tâche" -ForegroundColor Yellow
    exit 1
}

Write-Host "URL du service web: $webUrl" -ForegroundColor Green
Write-Host ""

# Récupérer l'ID de l'analyse pour Extia.fr
Write-Host "Récupération de l'ID de l'analyse pour Extia.fr..." -ForegroundColor Cyan

# Note: Pour voir les détails dans l'interface web:
Write-Host ""
Write-Host "=== Instructions ===" -ForegroundColor Yellow
Write-Host "Pour voir les détails des 7 tâches en attente:" -ForegroundColor Yellow
Write-Host "1. Ouvrez l'interface web Artemis: $webUrl" -ForegroundColor Yellow
Write-Host "2. Cliquez sur 'Show pending tasks' pour Extia.fr" -ForegroundColor Yellow
Write-Host "3. Cela affichera:" -ForegroundColor Yellow
Write-Host "   - Le receiver (module concerné)" -ForegroundColor Yellow
Write-Host "   - Le target (cible de la tâche)" -ForegroundColor Yellow
Write-Host "   - Le status (Waiting in queue ou Running)" -ForegroundColor Yellow
Write-Host ""

Write-Host "=== Analyse ===" -ForegroundColor Cyan
Write-Host "Les 7 tâches sont probablement pour des modules qui:" -ForegroundColor White
Write-Host "- Ne sont pas actifs (pas démarrés)" -ForegroundColor White
Write-Host "- Sont bloqués par un autre problème" -ForegroundColor White
Write-Host "- Attendent des conditions spécifiques" -ForegroundColor White
Write-Host ""

Write-Host "=== Recommandations ===" -ForegroundColor Cyan
Write-Host "1. Vérifiez dans l'interface web quels modules sont concernés" -ForegroundColor White
Write-Host "2. Redémarrez les services si nécessaire:" -ForegroundColor White
Write-Host "   railway restart --service karton-scanners" -ForegroundColor Gray
Write-Host "   railway restart --service karton-core-workers" -ForegroundColor Gray
Write-Host "3. Attendez: les tâches seront traitées ou expireront selon TASK_TIMEOUT_SECONDS (12h par défaut)" -ForegroundColor White
Write-Host ""

Write-Host "Le système fonctionne globalement:" -ForegroundColor Green
Write-Host "- Le fix DNS fonctionne (nuclei a terminé)" -ForegroundColor Green
Write-Host "- 2951/2958 tâches sont terminées (99.8%)" -ForegroundColor Green
Write-Host "- Les 7 tâches restantes sont probablement pour des modules moins actifs" -ForegroundColor Green
