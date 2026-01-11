# Fix: Nuclei Module Blocking - Implémentation

## Solution Implémentée

**Approche combinée** : Solution 2 (timeout DNS) + Solution 4 (timeout global)

### Modifications Apportées

#### 1. `artemis/resolvers.py`

**Ajout de timeout pour `socket.gethostbyname()`** :
- Nouvelle fonction `_gethostbyname_with_timeout()` utilisant `ThreadPoolExecutor` (compatible Windows/Unix)
- Timeout de 5 secondes maximum (ou `REQUEST_TIMEOUT_SECONDS` si inférieur)

**Configuration explicite du timeout DNS** :
- Modification de `_single_resolution_attempt()` pour créer un resolver avec timeout explicite
- `resolver.timeout = 5 secondes` (max par requête)
- `resolver.lifetime = 10 secondes` (max total)

**Gestion des timeouts DNS** :
- Capture de `dns.resolver.Timeout` et conversion en `ResolutionException` avec message clair

#### 2. `artemis/module_base.py`

**Timeout global sur `check_connection_to_base_url_and_save_error()`** :
- Ajout du décorateur `@timeout_decorator.timeout()` avec `use_signals=False` (compatible Windows)
- Timeout de `REQUEST_TIMEOUT_SECONDS * 3` (15 secondes par défaut) pour couvrir DNS + HTTP

**Gestion des exceptions de timeout** :
- Capture de `timeout_decorator.TimeoutError` 
- Enregistrement de l'erreur dans la base de données avec message explicite
- Libération du lock et retour de `False` pour continuer le traitement

## Avantages de cette Solution

1. **Compatible Windows et Unix** : Utilise `ThreadPoolExecutor` au lieu de `signal` (Unix-only)
2. **Double protection** : Timeout au niveau DNS ET au niveau de la fonction complète
3. **Pas de changement d'architecture** : Solution minimale et ciblée
4. **Gestion d'erreurs propre** : Les timeouts sont loggés et les tâches sont marquées comme erreur (pas de crash)
5. **Rétrocompatible** : N'affecte pas le comportement normal, seulement les cas de blocage

## Impact

- **Avant** : Un blocage DNS pouvait bloquer indéfiniment le traitement d'un batch de 10 tâches
- **Après** : Maximum 15 secondes par vérification de connexion (5s DNS + 5s HTTP + marge)
- **Pour 10 tâches** : Maximum 150 secondes (2.5 minutes) au lieu d'un blocage infini

## Tests Recommandés

1. Vérifier que les résolutions DNS normales fonctionnent toujours
2. Tester avec un domaine qui ne répond pas (devrait timeout après 5s)
3. Vérifier que les logs montrent les timeouts correctement
4. Confirmer que `nuclei` peut maintenant traiter les tâches même si certaines ont des problèmes DNS

## Déploiement

1. Les modifications sont prêtes à être déployées
2. Redémarrer le service `karton-webapp-scanners` après déploiement
3. Surveiller les logs pour confirmer que les timeouts fonctionnent correctement
