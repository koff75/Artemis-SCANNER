# Intégration des modules extra d'Artemis-modules-extra

Ce guide explique comment intégrer les modules supplémentaires d'[Artemis-modules-extra](https://github.com/CERT-Polska/Artemis-modules-extra) dans les services Railway existants.

## 📋 Vue d'ensemble

Les modules extra sont répartis dans les services existants pour optimiser les coûts. **Aucun nouveau service Railway n'est nécessaire.**

## 🎯 Modules disponibles

D'après le dépôt Artemis-modules-extra :

1. **karton_sqlmap** - Détection d'injections SQL (GPL-2.0)
2. **karton_ssl_checks** - Vérification de la configuration SSL (AGPL-3.0)
3. **karton_dns_reaper** - Détection de subdomain takeover (AGPL-3.0)
4. **karton_forti_vuln** - Détection CVE-2024-21762 Fortigate (GPL-3.0)
5. **karton_whatvpn** - Identification de serveurs VPN SSL (GPL-3.0-or-later)
6. **karton_xss_scanner** - Détection de vulnérabilités XSS (GPL-3.0)
7. **karton_wpscan** - Scan WordPress (désactivé par défaut, nécessite licence)

## 📊 Répartition recommandée

### Service : `karton-scanners`

**Modules actuels** :
- `port_scanner`, `subdomain_enumeration`, `dns_scanner`, `reverse_dns_lookup`, `device_identifier`, `directory_index`, `robots`, `vcs`, `api_scanner`

**Modules extra à ajouter** :
- `karton_ssl_checks` - Vérification SSL
- `karton_dns_reaper` - Subdomain takeover
- `karton_forti_vuln` - Vulnérabilités Fortigate
- `karton_whatvpn` - Identification VPN

**Nouvelle variable MODULES** :
```
MODULES=port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn
```

---

### Service : `karton-webapp-scanners`

**Modules actuels** :
- `nuclei`, `wordpress_plugins`, `joomla_extensions`, `drupal_scanner`, `wp_scanner`, `joomla_scanner`, `sql_injection_detector`, `lfi_detector`

**Modules extra à ajouter** :
- `karton_sqlmap` - Injections SQL (plus puissant que sql_injection_detector)
- `karton_xss_scanner` - Vulnérabilités XSS

**Optionnel** :
- `karton_wpscan` - Scan WordPress avancé (nécessite licence, voir avertissement ci-dessous)

**Nouvelle variable MODULES** :
```
MODULES=nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner
```

---

## ⚠️ Avertissement pour karton_wpscan

Le module `karton_wpscan` nécessite une licence spécifique. **Lisez attentivement** les termes et conditions : https://github.com/wpscanteam/wpscan/blob/master/LICENSE

**Ne l'ajoutez PAS** si vous n'êtes pas sûr de respecter la licence.

---

## 🚀 Étapes d'intégration

### Étape 1 : Ajouter le submodule Git (si pas déjà fait)

```bash
git submodule add https://github.com/CERT-Polska/Artemis-modules-extra.git Artemis-modules-extra
git commit -m "Add Artemis-modules-extra submodule"
git push origin main
```

**Note** : Le submodule est déjà configuré dans `.gitmodules`, il suffit de l'initialiser :

```bash
git submodule update --init --recursive
```

---

### Étape 2 : Mettre à jour les variables MODULES dans Railway

#### Pour `karton-scanners` :

1. Allez sur Railway Dashboard → Service `karton-scanners`
2. Variables d'environnement → Modifier `MODULES`
3. Nouvelle valeur :
   ```
   MODULES=port_scanner,subdomain_enumeration,dns_scanner,reverse_dns_lookup,device_identifier,directory_index,robots,vcs,api_scanner,karton_ssl_checks,karton_dns_reaper,karton_forti_vuln,karton_whatvpn
   ```
4. Sauvegarder → Le service redéploiera automatiquement

#### Pour `karton-webapp-scanners` :

1. Allez sur Railway Dashboard → Service `karton-webapp-scanners`
2. Variables d'environnement → Modifier `MODULES`
3. Nouvelle valeur :
   ```
   MODULES=nuclei,wordpress_plugins,joomla_extensions,drupal_scanner,wp_scanner,joomla_scanner,sql_injection_detector,lfi_detector,karton_sqlmap,karton_xss_scanner
   ```
4. Sauvegarder → Le service redéploiera automatiquement

---

### Étape 3 : Vérifier le déploiement

Après le redéploiement, vérifiez les logs :

1. **karton-scanners** : Vous devriez voir :
   ```
   Installation des modules extra d'Artemis-modules-extra...
   Installation de Artemis-modules-extra/karton_ssl_checks/
   ...
   Module karton_ssl_checks (extra) démarré avec PID: X
   ```

2. **karton-webapp-scanners** : Vous devriez voir :
   ```
   Installation des modules extra d'Artemis-modules-extra...
   Installation de Artemis-modules-extra/karton_sqlmap/
   ...
   Module karton_sqlmap (extra) démarré avec PID: X
   ```

---

## 🔧 Modifications techniques

### Fichiers modifiés

1. **`Dockerfile.worker.railway`** :
   - Ajout de la copie et installation des modules extra
   - Installation automatique des dépendances de chaque module

2. **`docker/start-multiple-modules.sh`** :
   - Support des modules core (`artemis.modules.*`)
   - Support des modules extra (`karton_*`)
   - Détection automatique du type de module

---

## ✅ Vérification

Pour vérifier que les modules extra fonctionnent :

1. **Logs Railway** : Les modules doivent démarrer sans erreur
2. **Interface Artemis** : Les nouveaux modules devraient apparaître dans la liste des modules disponibles
3. **Traitement des tâches** : Les modules extra devraient traiter les tâches appropriées

---

## 📝 Notes importantes

- **Coûts** : Aucun nouveau service Railway n'est créé, les modules sont ajoutés aux services existants
- **Licences** : Les modules extra ont des licences différentes (GPL, AGPL). Vérifiez la compatibilité avec votre usage
- **Dépendances** : Les modules extra sont installés automatiquement avec leurs dépendances lors du build Docker
- **Submodule Git** : Assurez-vous que le submodule est initialisé lors du clonage du dépôt

---

## 🐛 Dépannage

### Les modules extra ne démarrent pas

1. Vérifiez que le submodule est bien initialisé :
   ```bash
   git submodule status
   ```

2. Vérifiez les logs Railway pour les erreurs d'installation

3. Vérifiez que le nom du module est correct dans `MODULES` (format `karton_*`)

### Erreur "Module introuvable"

- Vérifiez que le module est bien installé dans le Dockerfile
- Vérifiez que le nom du module correspond exactement au package Python

---

## 📚 Références

- [Artemis-modules-extra](https://github.com/CERT-Polska/Artemis-modules-extra)
- [Documentation Artemis](https://artemis-scanner.readthedocs.io/)
- [RAILWAY_CHANGES.md](RAILWAY_CHANGES.md) - Modifications pour Railway
