# Script de diagnostic pour karton-system
# Verifie l'etat de karton-system et identifie les problemes potentiels

param(
    [switch]$Detailed = $false
)

Write-Host "=== Diagnostic karton-system ===" -ForegroundColor Cyan
Write-Host ""

# 1. Verifier l'etat du service
Write-Host "1. Etat du service karton-system..." -ForegroundColor Yellow
$logs = railway logs --service karton-system --lines 50 2>&1

# Verifier si le service est demarre
$started = $logs | Select-String -Pattern "Manager karton.system started|karton-system started"
if ($started) {
    Write-Host "  [OK] Service demarre" -ForegroundColor Green
    $startTime = ($logs | Select-String -Pattern "Manager karton.system started" | Select-Object -Last 1).Line
    Write-Host "  Dernier demarrage: $startTime" -ForegroundColor White
} else {
    Write-Host "  [ERREUR] Service non demarre ou logs non disponibles" -ForegroundColor Red
}

# 2. Verifier l'activite recente
Write-Host ""
Write-Host "2. Activite recente..." -ForegroundColor Yellow
$recentActivity = $logs | Select-String -Pattern "Processing task|HEARTBEAT" | Select-Object -Last 5
if ($recentActivity) {
    Write-Host "  [OK] Activite detectee:" -ForegroundColor Green
    $recentActivity | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  [ATTENTION] Aucune activite recente (pas de 'Processing task' ou 'HEARTBEAT')" -ForegroundColor Yellow
}

# 3. Compter les taches traitees
Write-Host ""
Write-Host "3. Taches traitees..." -ForegroundColor Yellow
$allLogs = railway logs --service karton-system --lines 1000 2>&1
$taskCount = ($allLogs | Select-String -Pattern "Processing task").Count
Write-Host "  Nombre de taches traitees: $taskCount" -ForegroundColor White

if ($taskCount -eq 0) {
    Write-Host "  [ATTENTION] Aucune tache traitee depuis le demarrage" -ForegroundColor Yellow
} elseif ($taskCount -ge 980) {
    Write-Host "  [ATTENTION] Proche de la limite MAX_NUM_TASKS_TO_PROCESS (1000)" -ForegroundColor Yellow
    Write-Host "    Le service va probablement redemarrer bientot" -ForegroundColor Yellow
}

# 4. Verifier les erreurs
Write-Host ""
Write-Host "4. Erreurs et warnings..." -ForegroundColor Yellow
$errors = $logs | Select-String -Pattern "ERROR|WARN|Exception|Traceback|FATAL" | Select-Object -Last 10
if ($errors) {
    Write-Host "  [ERREUR] Erreurs detectees:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  [OK] Aucune erreur detectee" -ForegroundColor Green
}

# 5. Verifier les heartbeats
Write-Host ""
Write-Host "5. Heartbeats..." -ForegroundColor Yellow
$heartbeats = $logs | Select-String -Pattern "HEARTBEAT"
if ($heartbeats) {
    Write-Host "  [OK] Heartbeats detectes (diagnostic actif):" -ForegroundColor Green
    $heartbeats | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor White
} else {
    Write-Host "  [ATTENTION] Aucun heartbeat detecte" -ForegroundColor Yellow
    Write-Host "    Le diagnostic ameliore n'est peut-etre pas deploye" -ForegroundColor Yellow
}

# 6. Verifier la derniere activite
Write-Host ""
Write-Host "6. Derniere activite..." -ForegroundColor Yellow
$lastActivity = $logs | Select-String -Pattern "Processing task|HEARTBEAT|Manager.*started" | Select-Object -Last 1
if ($lastActivity) {
    Write-Host "  Derniere activite: $($lastActivity.Line)" -ForegroundColor White
    
    # Essayer d'extraire le timestamp
    if ($lastActivity.Line -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
        $lastTimestamp = $matches[1]
        Write-Host "  Timestamp: $lastTimestamp" -ForegroundColor White
        
        # Calculer le temps ecoule
        try {
            $lastTime = [DateTime]::Parse($lastTimestamp)
            $elapsed = (Get-Date) - $lastTime
            Write-Host "  Temps ecoule: $([math]::Round($elapsed.TotalMinutes, 1)) minutes" -ForegroundColor White
            
            if ($elapsed.TotalMinutes -gt 10) {
                Write-Host "  [ATTENTION] Aucune activite depuis plus de 10 minutes - service peut etre bloque" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  (Impossible de parser le timestamp)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  [ATTENTION] Aucune activite trouvee" -ForegroundColor Yellow
}

# 7. Recommandations
Write-Host ""
Write-Host "=== Recommandations ===" -ForegroundColor Cyan

if ($taskCount -eq 0 -and $started) {
    Write-Host "  - Le service est demarre mais ne traite pas de taches" -ForegroundColor Yellow
    Write-Host "  - Verifier s'il y a des taches dans la queue 'unrouted' (karton.tasks)" -ForegroundColor White
    Write-Host "  - Redemarrer le service: railway restart --service karton-system" -ForegroundColor White
}

if ($taskCount -ge 980) {
    Write-Host "  - Le service approche de la limite de 1000 taches" -ForegroundColor Yellow
    Write-Host "  - Il va redemarrer automatiquement bientot" -ForegroundColor White
    Write-Host "  - Considerer augmenter MAX_NUM_TASKS_TO_PROCESS si necessaire" -ForegroundColor White
}

if (-not $heartbeats) {
    Write-Host "  - Le diagnostic ameliore n'est pas actif" -ForegroundColor Yellow
    Write-Host "  - Redeployer avec le nouveau karton-system-wrapper.py pour activer les heartbeats" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Fin du diagnostic ===" -ForegroundColor Cyan
