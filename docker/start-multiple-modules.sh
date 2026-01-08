#!/bin/bash
# Script pour démarrer plusieurs modules Karton en parallèle dans un même conteneur
# Utilise la variable MODULES (séparée par des virgules) pour spécifier quels modules exécuter

set -e

# Générer karton.ini
python3 /usr/local/bin/generate-karton-config.py

# DB_CONN_STR est requis par le code (legacy MongoDB) mais n'est plus utilisé
# On le définit avec une valeur factice pour éviter l'erreur
export DB_CONN_STR="${DB_CONN_STR:-mongodb://localhost:27017/artemis}"

# Exécuter les migrations (ne pas faire échouer le script si cela échoue)
alembic upgrade head || echo "Avertissement: Échec des migrations Alembic (peut être normal si DB_CONN_STR n'est pas défini)"

# Parser la variable MODULES (format: "module1,module2,module3")
MODULES="${MODULES:-classifier}"

echo "=== Démarrage des modules: $MODULES ==="

# Fonction pour démarrer un module en arrière-plan
# Supporte les modules core (artemis.modules.*) et les modules extra (karton_*)
start_module() {
    local module=$1
    echo "Démarrage du module: $module"
    
    # Détecter d'abord si c'est un module extra (commence par karton_ ou forti_vuln)
    # Les modules extra peuvent avoir le préfixe karton_ ou être forti_vuln
    if [[ "$module" =~ ^karton_ ]] || [[ "$module" == "forti_vuln" ]]; then
        # Module extra - exécuter le fichier Python directement
        # Certains modules ont le préfixe karton_ dans le nom du répertoire, d'autres non
        if [[ "$module" == "forti_vuln" ]]; then
            module_file="/opt/Artemis-modules-extra/forti_vuln/forti_vuln.py"
        else
            module_file="/opt/Artemis-modules-extra/$module/$module.py"
        fi
        # Debug: vérifier si le répertoire existe
        if [ ! -d "/opt/Artemis-modules-extra" ]; then
            echo "ERREUR: Répertoire /opt/Artemis-modules-extra n'existe pas"
            echo "Contenu de /opt: $(ls -la /opt/ 2>/dev/null | head -20)"
            return 1
        fi
        if [ "$module" != "forti_vuln" ] && [ ! -d "/opt/Artemis-modules-extra/$module" ]; then
            echo "ERREUR: Répertoire /opt/Artemis-modules-extra/$module n'existe pas"
            echo "Modules disponibles dans /opt/Artemis-modules-extra: $(ls -la /opt/Artemis-modules-extra/ 2>/dev/null | grep -E '^d' | awk '{print $NF}' | tr '\n' ' ')"
            return 1
        fi
        if [ -f "$module_file" ]; then
            echo "Module extra détecté: $module"
            python3 "$module_file" &
            local pid=$!
            echo "Module $module (extra) démarré avec PID: $pid"
            echo $pid >> /tmp/module_pids.txt
        else
            echo "ERREUR: Fichier module extra introuvable: $module_file"
            echo "Vérifiez que Artemis-modules-extra est bien copié dans l'image Docker"
            echo "Contenu de /opt/Artemis-modules-extra/$module: $(ls -la /opt/Artemis-modules-extra/$module/ 2>/dev/null | head -10)"
            return 1
        fi
    # Sinon, essayer comme module core (artemis.modules.*)
    elif python3 -c "import artemis.modules.$module" 2>/dev/null; then
        echo "Module core détecté: artemis.modules.$module"
        python3 -m artemis.modules.$module &
        local pid=$!
        echo "Module $module (core) démarré avec PID: $pid"
        echo $pid >> /tmp/module_pids.txt
    else
        echo "ERREUR: Module $module introuvable (ni core ni extra)"
        echo "Vérifiez que le module est installé et que le nom est correct"
        return 1
    fi
}

# Nettoyer les anciens PIDs
rm -f /tmp/module_pids.txt

# Démarrer chaque module
IFS=',' read -ra MODULE_ARRAY <<< "$MODULES"
for module in "${MODULE_ARRAY[@]}"; do
    module=$(echo "$module" | xargs)  # Trim whitespace
    if [ -n "$module" ]; then
        start_module "$module"
    fi
done

echo "=== Tous les modules démarrés ==="
if [ -f /tmp/module_pids.txt ]; then
    echo "PIDs: $(cat /tmp/module_pids.txt)"
else
    echo "PIDs: none"
fi

# Fonction de nettoyage au shutdown
cleanup() {
    echo "Arrêt des modules..."
    if [ -f /tmp/module_pids.txt ]; then
        while read pid; do
            if kill -0 "$pid" 2>/dev/null; then
                echo "Arrêt du processus $pid"
                kill "$pid" 2>/dev/null || true
            fi
        done < /tmp/module_pids.txt
    fi
    exit 0
}

# Capturer les signaux pour nettoyer proprement
trap cleanup SIGTERM SIGINT

# Attendre que tous les processus se terminent
wait
