# Script pour mettre à jour les variables MODULES avec les modules extra
# Ce script affiche les commandes Railway CLI à exécuter

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Mise à jour des modules extra sur Railway" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "Ce script vous guide pour ajouter les modules extra aux services existants." -ForegroundColor Yellow
Write-Host ""

# Vérifier que Railway CLI est installé
$railwayInstalled = Get-Command railway -ErrorAction SilentlyContinue
if (-not $railwayInstalled) {
    Write-Host "ERREUR: Railway CLI n'est pas installé." -ForegroundColor Red
    Write-Host "Installez-le avec: npm install -g @railway/cli" -ForegroundColor Yellow
    Write-Host "Ou exécutez: .\install-railway-cli.ps1" -ForegroundColor Yellow
    exit 1
}

Write-Host "✅ Railway CLI détecté" -ForegroundColor Green
Write-Host ""

Write-Host "📋 Variables MODULES à mettre à jour:" -ForegroundColor Cyan
Write-Host ""

# Service karton-scanners
Write-Host "1. Service: karton-scanners" -ForegroundColor White
Write-Host "   Nouvelle valeur MODULES:" -ForegroundColor Gray
Write-Host "   port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Commande Railway CLI:" -ForegroundColor Gray
Write-Host "   railway variables set MODULES='port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn' --service karton-scanners" -ForegroundColor Green
Write-Host ""

# Service karton-webapp-scanners
Write-Host "2. Service: karton-webapp-scanners" -ForegroundColor White
Write-Host "   Nouvelle valeur MODULES:" -ForegroundColor Gray
Write-Host "   nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner" -ForegroundColor Yellow
Write-Host ""
Write-Host "   Commande Railway CLI:" -ForegroundColor Gray
Write-Host "   railway variables set MODULES='nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner' --service karton-webapp-scanners" -ForegroundColor Green
Write-Host ""

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Options:" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "1. Exécuter les commandes automatiquement (recommandé)" -ForegroundColor White
Write-Host "2. Afficher uniquement les commandes (copier-coller manuel)" -ForegroundColor White
Write-Host "3. Annuler" -ForegroundColor White
Write-Host ""

$choice = Read-Host "Votre choix (1-3)"

if ($choice -eq "1") {
    Write-Host ""
    Write-Host "Mise à jour du service karton-scanners..." -ForegroundColor Cyan
    railway variables set MODULES='port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn' --service karton-scanners
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ karton-scanners mis à jour" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la mise à jour de karton-scanners" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Mise à jour du service karton-webapp-scanners..." -ForegroundColor Cyan
    railway variables set MODULES='nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner' --service karton-webapp-scanners
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ karton-webapp-scanners mis à jour" -ForegroundColor Green
    } else {
        Write-Host "❌ Erreur lors de la mise à jour de karton-webapp-scanners" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "✅ Mise à jour terminée!" -ForegroundColor Green
    Write-Host "Les services vont redéployer automatiquement avec les nouveaux modules." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Vérifiez les logs dans Railway Dashboard pour confirmer que les modules extra démarrent correctement." -ForegroundColor Cyan
    
} elseif ($choice -eq "2") {
    Write-Host ""
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Commandes à exécuter manuellement:" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "# Service karton-scanners" -ForegroundColor White
    Write-Host "railway variables set MODULES='port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn' --service karton-scanners" -ForegroundColor Green
    Write-Host ""
    Write-Host "# Service karton-webapp-scanners" -ForegroundColor White
    Write-Host "railway variables set MODULES='nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner' --service karton-webapp-scanners" -ForegroundColor Green
    Write-Host ""
} else {
    Write-Host "Annulé." -ForegroundColor Yellow
}
