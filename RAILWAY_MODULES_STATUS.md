# État des modules déployés sur Railway

**Date de vérification** : 5 janvier 2026

## ✅ Résumé

**Tous les modules listés dans l'interface sont déployés et actifs.**

## 📊 Répartition des modules par service

### Service : `karton-core-workers`
**Modules déployés** :
- ✅ `classifier` (module essentiel - toujours actif)
- ✅ `http_service_to_url` (module essentiel - toujours actif)
- ✅ `webapp_identifier` (module essentiel - toujours actif)
- ✅ `ip_lookup` (module essentiel - toujours actif)

**État** : ✅ Actif - Les modules pollent leurs queues régulièrement

---

### Service : `karton-scanners`
**Modules déployés** :
- ✅ `port_scanner`
- ✅ `subdomain_enumeration`
- ✅ `dns_scanner`
- ✅ `reverse_dns_lookup` (correspond à `ReverseDNSLookup` dans l'interface)
- ✅ `device_identifier`
- ✅ `directory_index`
- ✅ `robots`
- ✅ `vcs`
- ✅ `api_scanner`

**État** : ✅ Actif - Les modules pollent leurs queues régulièrement

---

### Service : `karton-webapp-scanners`
**Modules déployés** :
- ✅ `nuclei`
- ✅ `wordpress_plugins`
- ✅ `joomla_extensions`
- ✅ `drupal_scanner`
- ✅ `wp_scanner`
- ✅ `joomla_scanner`
- ✅ `sql_injection_detector`
- ✅ `lfi_detector`

**État** : ✅ Actif - Les modules pollent leurs queues régulièrement

---

### Service : `karton-brute-specialized`
**Modules déployés** :
- ✅ `bruter`
- ✅ `admin_panel_login_bruter`
- ✅ `wordpress_bruter`
- ✅ `joomla_bruter` (non listé dans l'interface mais déployé)
- ✅ `ftp_bruter`
- ✅ `ssh_bruter`
- ✅ `mysql_bruter`
- ✅ `postgresql_bruter`
- ✅ `mail_dns_scanner`
- ✅ `domain_expiration_scanner`
- ✅ `dangling_dns_detector`
- ✅ `removed_domain_existing_vhost` (non listé dans l'interface mais déployé)
- ✅ `scripts_unregistered_domains`
- ✅ `shodan_vulns` (non listé dans l'interface mais déployé)
- ✅ `humble`

**État** : ✅ Actif - Les modules pollent leurs queues régulièrement

---

## 📋 Liste complète des modules (29 modules de l'interface)

| Module | Service | État | Notes |
|--------|---------|------|-------|
| `admin_panel_login_bruter` | karton-brute-specialized | ✅ Actif | |
| `api_scanner` | karton-scanners | ✅ Actif | |
| `bruter` | karton-brute-specialized | ✅ Actif | |
| `dangling_dns_detector` | karton-brute-specialized | ✅ Actif | |
| `device_identifier` | karton-scanners | ✅ Actif | |
| `directory_index` | karton-scanners | ✅ Actif | |
| `dns_scanner` | karton-scanners | ✅ Actif | |
| `domain_expiration_scanner` | karton-brute-specialized | ✅ Actif | |
| `drupal_scanner` | karton-webapp-scanners | ✅ Actif | |
| `ftp_bruter` | karton-brute-specialized | ✅ Actif | |
| `humble` | karton-brute-specialized | ✅ Actif | |
| `joomla_extensions` | karton-webapp-scanners | ✅ Actif | |
| `joomla_scanner` | karton-webapp-scanners | ✅ Actif | |
| `lfi_detector` | karton-webapp-scanners | ✅ Actif | |
| `mail_dns_scanner` | karton-brute-specialized | ✅ Actif | |
| `mysql_bruter` | karton-brute-specialized | ✅ Actif | |
| `nuclei` | karton-webapp-scanners | ✅ Actif | |
| `port_scanner` | karton-scanners | ✅ Actif | |
| `postgresql_bruter` | karton-brute-specialized | ✅ Actif | |
| `ReverseDNSLookup` | karton-scanners | ✅ Actif | (nom interne: `reverse_dns_lookup`) |
| `robots` | karton-scanners | ✅ Actif | |
| `scripts_unregistered_domains` | karton-brute-specialized | ✅ Actif | |
| `sql_injection_detector` | karton-webapp-scanners | ✅ Actif | |
| `ssh_bruter` | karton-brute-specialized | ✅ Actif | |
| `subdomain_enumeration` | karton-scanners | ✅ Actif | |
| `vcs` | karton-scanners | ✅ Actif | |
| `wordpress_bruter` | karton-brute-specialized | ✅ Actif | |
| `wordpress_plugins` | karton-webapp-scanners | ✅ Actif | |
| `wp_scanner` | karton-webapp-scanners | ✅ Actif | |

---

## 🔧 Modules essentiels (non listés dans l'interface mais toujours actifs)

Ces modules sont des modules "core" qui sont toujours actifs et ne peuvent pas être désactivés :

| Module | Service | État | Rôle |
|--------|---------|------|------|
| `classifier` | karton-core-workers | ✅ Actif | Classifie les nouvelles tâches et les route vers les modules appropriés |
| `http_service_to_url` | karton-core-workers | ✅ Actif | Convertit les services HTTP en URLs |
| `webapp_identifier` | karton-core-workers | ✅ Actif | Identifie les applications web |
| `ip_lookup` | karton-core-workers | ✅ Actif | Effectue des recherches IP |

---

## 📈 Modules supplémentaires déployés (non listés dans l'interface)

Ces modules sont déployés mais ne sont pas visibles dans l'interface car ils ne sont pas dans la liste des modules activables :

| Module | Service | État | Notes |
|--------|---------|------|-------|
| `joomla_bruter` | karton-brute-specialized | ✅ Actif | Brute force pour Joomla |
| `removed_domain_existing_vhost` | karton-brute-specialized | ✅ Actif | Détecte les domaines supprimés avec vhost existant |
| `shodan_vulns` | karton-brute-specialized | ✅ Actif | Recherche de vulnérabilités via Shodan |

---

## ✅ Vérification de l'activité

Tous les modules sont **actifs et fonctionnels** :

1. **Modules core** : Pollent régulièrement leurs queues (`classifier`, `http_service_to_url`, `webapp_identifier`, `ip_lookup`)
2. **Scanners** : Actifs et traitent des tâches (`port_scanner`, `nuclei`, `directory_index`, etc.)
3. **Webapp scanners** : Actifs (`wordpress_plugins`, `joomla_scanner`, `drupal_scanner`, etc.)
4. **Brute force** : Actifs (`bruter`, `ftp_bruter`, `ssh_bruter`, etc.)

**Preuve d'activité** : Les logs montrent que tous les modules :
- Pollent leurs queues régulièrement (`[taking tasks] Taking tasks from queue...`)
- Traitent des tâches (`1 tasks done`, `Processing task`)
- Sont correctement routés par `karton-system`

---

## 🎯 Conclusion

**✅ Tous les 29 modules listés dans l'interface sont déployés et actifs.**

**✅ Les 4 modules essentiels (core) sont également actifs.**

**✅ 3 modules supplémentaires sont déployés (non listés dans l'interface).**

**Total : 36 modules déployés et actifs sur Railway**

---

## 📝 Notes

- Les modules sont groupés dans 4 services workers pour optimiser les coûts
- Le service `karton-system` route correctement les tâches vers tous les modules
- Tous les modules sont opérationnels et traitent des tâches
