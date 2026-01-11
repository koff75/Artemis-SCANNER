# Script de diagnostic pour karton-system
# Vérifie l'état de karton-system et identifie les problèmes potentiels

param(
    [switch]$Detailed = $false
)

Write-Host "=== Diagnostic karton-system ===" -ForegroundColor Cyan
Write-Host ""

# 1. Vérifier l'état du service
Write-Host "1. État du service karton-system..." -ForegroundColor Yellow
$logs = railway logs --service karton-system --lines 50 2>&1

# Vérifier si le service est démarré
$started = $logs | Select-String -Pattern "Manager karton.system started|karton-system started"
if ($started) {
    Write-Host "  ✓ Service démarré" -ForegroundColor Green
    $startTime = ($logs | Select-String -Pattern "Manager karton.system started" | Select-Object -Last 1).Line
    Write-Host "  Dernier démarrage: $startTime" -ForegroundColor White
} else {
    Write-Host "  ✗ Service non démarré ou logs non disponibles" -ForegroundColor Red
}

# 2. Vérifier l'activité récente
Write-Host ""
Write-Host "2. Activité récente..." -ForegroundColor Yellow
$recentActivity = $logs | Select-String -Pattern "Processing task|HEARTBEAT" | Select-Object -Last 5
if ($recentActivity) {
    Write-Host "  ✓ Activité détectée:" -ForegroundColor Green
    $recentActivity | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  ⚠ Aucune activité récente (pas de 'Processing task' ou 'HEARTBEAT')" -ForegroundColor Yellow
}

# 3. Compter les tâches traitées
Write-Host ""
Write-Host "3. Tâches traitées..." -ForegroundColor Yellow
$allLogs = railway logs --service karton-system --lines 1000 2>&1
$taskCount = ($allLogs | Select-String -Pattern "Processing task").Count
Write-Host "  Nombre de tâches traitées: $taskCount" -ForegroundColor White

if ($taskCount -eq 0) {
    Write-Host "  ⚠ Aucune tâche traitée depuis le démarrage" -ForegroundColor Yellow
} elseif ($taskCount -ge 980) {
    Write-Host "  ⚠ Proche de la limite MAX_NUM_TASKS_TO_PROCESS (1000)" -ForegroundColor Yellow
    Write-Host "    Le service va probablement redémarrer bientôt" -ForegroundColor Yellow
}

# 4. Vérifier les erreurs
Write-Host ""
Write-Host "4. Erreurs et warnings..." -ForegroundColor Yellow
$errors = $logs | Select-String -Pattern "ERROR|WARN|Exception|Traceback|FATAL" | Select-Object -Last 10
if ($errors) {
    Write-Host "  ⚠ Erreurs détectées:" -ForegroundColor Red
    $errors | ForEach-Object { Write-Host "    $_" -ForegroundColor Red }
} else {
    Write-Host "  ✓ Aucune erreur détectée" -ForegroundColor Green
}

# 5. Vérifier les heartbeats (si diagnostic activé)
Write-Host ""
Write-Host "5. Heartbeats (diagnostic)..." -ForegroundColor Yellow
$heartbeats = $logs | Select-String -Pattern "HEARTBEAT"
if ($heartbeats) {
    Write-Host "  ✓ Heartbeats détectés (diagnostic actif):" -ForegroundColor Green
    $heartbeats | Select-Object -Last 3 | ForEach-Object { Write-Host "    $_" -ForegroundColor White }
} else {
    Write-Host "  ⚠ Aucun heartbeat détecté" -ForegroundColor Yellow
    Write-Host "    Le diagnostic amélioré n'est peut-être pas déployé" -ForegroundColor Yellow
}

# 6. Vérifier la dernière activité
Write-Host ""
Write-Host "6. Dernière activité..." -ForegroundColor Yellow
$lastActivity = $logs | Select-String -Pattern "Processing task|HEARTBEAT|Manager.*started" | Select-Object -Last 1
if ($lastActivity) {
    Write-Host "  Dernière activité: $($lastActivity.Line)" -ForegroundColor White
    
    # Essayer d'extraire le timestamp
    if ($lastActivity.Line -match '\[(\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2})\]') {
        $lastTimestamp = $matches[1]
        Write-Host "  Timestamp: $lastTimestamp" -ForegroundColor White
        
        # Calculer le temps écoulé
        try {
            $lastTime = [DateTime]::Parse($lastTimestamp)
            $elapsed = (Get-Date) - $lastTime
            Write-Host "  Temps écoulé: $($elapsed.TotalMinutes) minutes" -ForegroundColor White
            
            if ($elapsed.TotalMinutes -gt 10) {
                Write-Host "  ⚠ Aucune activité depuis plus de 10 minutes - service peut être bloqué" -ForegroundColor Yellow
            }
        } catch {
            Write-Host "  (Impossible de parser le timestamp)" -ForegroundColor Gray
        }
    }
} else {
    Write-Host "  ⚠ Aucune activité trouvée" -ForegroundColor Yellow
}

# 7. Recommandations
Write-Host ""
Write-Host "=== Recommandations ===" -ForegroundColor Cyan

if ($taskCount -eq 0 -and $started) {
    Write-Host "  • Le service est démarré mais ne traite pas de tâches" -ForegroundColor Yellow
    Write-Host "  • Vérifier s'il y a des tâches dans la queue 'unrouted' (karton.tasks)" -ForegroundColor White
    Write-Host "  • Redémarrer le service: railway restart --service karton-system" -ForegroundColor White
}

if ($taskCount -ge 980) {
    Write-Host "  • Le service approche de la limite de 1000 tâches" -ForegroundColor Yellow
    Write-Host "  • Il va redémarrer automatiquement bientôt" -ForegroundColor White
    Write-Host "  • Considérer augmenter MAX_NUM_TASKS_TO_PROCESS si nécessaire" -ForegroundColor White
}

if (-not $heartbeats) {
    Write-Host "  • Le diagnostic amélioré n'est pas actif" -ForegroundColor Yellow
    Write-Host "  • Redéployer avec le nouveau karton-system-wrapper.py pour activer les heartbeats" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Fin du diagnostic ===" -ForegroundColor Cyan
