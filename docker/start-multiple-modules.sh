#!/bin/bash
# Script pour démarrer plusieurs modules Karton en parallèle dans un même conteneur
# Utilise la variable MODULES (séparée par des virgules) pour spécifier quels modules exécuter

set -e

# Générer karton.ini
python3 /usr/local/bin/generate-karton-config.py

# DB_CONN_STR est requis par le code (legacy MongoDB) mais n'est plus utilisé
# On le définit avec une valeur factice pour éviter l'erreur
export DB_CONN_STR="${DB_CONN_STR:-mongodb://localhost:27017/artemis}"

# Exécuter les migrations
alembic upgrade head

# Parser la variable MODULES (format: "module1,module2,module3")
MODULES="${MODULES:-classifier}"

echo "=== Démarrage des modules: $MODULES ==="

# Fonction pour démarrer un module en arrière-plan
start_module() {
    local module=$1
    echo "Démarrage du module: $module"
    # Démarrer le module en arrière-plan - sa sortie sera visible dans les logs Railway
    # car les processus enfants héritent de stdout/stderr du processus parent
    python3 -m artemis.modules.$module &
    local pid=$!
    echo "Module $module démarré avec PID: $pid"
    echo $pid >> /tmp/module_pids.txt
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
