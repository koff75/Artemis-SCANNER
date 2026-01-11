# Root Cause Analysis: Nuclei Module Blocking

## Problème Observé

Le module `nuclei` reçoit des tâches (log "Received 10 new tasks" à 09:39:21) mais ne commence jamais le traitement. Aucun log "running X templates" n'apparaît, indiquant que `run_multiple()` n'est jamais appelé.

## Root Cause Identifiée

Le blocage se produit **AVANT** l'appel à `run_multiple()`, dans la fonction `check_connection_to_base_url_and_save_error()` appelée par `process_multiple()`.

### Flux d'Exécution

1. **`internal_process_multiple()`** (ligne 565, `module_base.py`)
   - Appelle `process_multiple()` à la ligne 590

2. **`process_multiple()`** (ligne 624, `module_base.py`)
   - Pour chaque tâche de type `SERVICE` avec `service: HTTP` (lignes 631-641):
     - Appelle `check_connection_to_base_url_and_save_error(task)` (ligne 640)
   - **Si cette fonction bloque, la boucle entière se bloque et `run_multiple()` n'est jamais appelé**

3. **`check_connection_to_base_url_and_save_error()`** (ligne 813, `module_base.py`)
   - Appelle `_get_scan_destination(task)` (ligne 815)
   - Appelle `self.http_get(base_url)` (ligne 819)

4. **`_get_scan_destination()`** (ligne 740, `module_base.py`)
   - Pour les tâches de type `SERVICE`, appelle `_get_ip_for_locking(task.payload["host"])` (ligne 777)

5. **`_get_ip_for_locking()`** (ligne 790, `module_base.py`)
   - Si `host` n'est pas une IP, appelle `lookup(host)` (ligne 804)

6. **`lookup()`** (ligne 80, `resolvers.py`)
   - Appelle `socket.gethostbyname(domain)` (ligne 89) **SANS TIMEOUT**
   - Puis appelle `retry(_single_resolution_attempt, ...)` (ligne 94)

7. **`_single_resolution_attempt()`** (ligne 59, `resolvers.py`)
   - Appelle `dns.resolver.resolve(domain, query_type)` (ligne 61)
   - Le timeout par défaut de `dns.resolver.resolve()` peut être long (5-30 secondes par tentative)

### Points de Blocage

1. **`socket.gethostbyname()`** (ligne 55 dans `retrying_resolver.py`, ligne 89 dans `resolvers.py`)
   - **Aucun timeout explicite** - peut bloquer indéfiniment si le DNS ne répond pas
   - Blocage synchrone qui empêche toute progression

2. **`dns.resolver.resolve()`** (ligne 61, `resolvers.py`)
   - Timeout par défaut de dnspython (généralement 5-30 secondes par tentative)
   - Avec `retry()` qui peut faire plusieurs tentatives, le délai total peut être très long

3. **`self.http_get(base_url)`** (ligne 819, `module_base.py`)
   - Timeout de 5 secondes par défaut (`REQUEST_TIMEOUT_SECONDS`)
   - Moins probable mais possible si le timeout ne fonctionne pas correctement

## Impact

- **Pour 10 tâches**: Si chaque tâche nécessite une résolution DNS qui bloque ou prend 30+ secondes, le traitement peut prendre plusieurs minutes ou bloquer indéfiniment
- **Blocage en série**: Les vérifications sont faites en série dans une boucle, donc une seule résolution DNS lente bloque tout le batch
- **Aucun log d'erreur**: Si `socket.gethostbyname()` bloque, aucune exception n'est levée, donc aucun log d'erreur n'apparaît

## Solutions Recommandées

### Solution 1: Ajouter un timeout à `socket.gethostbyname()`

Modifier `resolvers.py` pour utiliser `socket.getaddrinfo()` avec timeout ou wrapper `socket.gethostbyname()` avec un timeout:

```python
import signal

def gethostbyname_with_timeout(domain: str, timeout: int = 5) -> str:
    def timeout_handler(signum, frame):
        raise TimeoutError(f"DNS resolution timeout for {domain}")
    
    signal.signal(signal.SIGALRM, timeout_handler)
    signal.alarm(timeout)
    try:
        result = socket.gethostbyname(domain)
        signal.alarm(0)  # Cancel alarm
        return result
    except TimeoutError:
        raise
    finally:
        signal.alarm(0)  # Ensure alarm is cancelled
```

**Note**: Cette approche ne fonctionne que sur Unix. Pour Windows, utiliser `threading` avec timeout.

### Solution 2: Configurer un timeout DNS explicite

Configurer le timeout de `dns.resolver.Resolver` avant utilisation:

```python
resolver = dns.resolver.Resolver()
resolver.timeout = 5  # 5 secondes
resolver.lifetime = 10  # 10 secondes maximum total
```

### Solution 3: Paralléliser les vérifications de connexion

Modifier `process_multiple()` pour faire les vérifications de connexion en parallèle au lieu de série:

```python
from concurrent.futures import ThreadPoolExecutor, as_completed

with ThreadPoolExecutor(max_workers=10) as executor:
    futures = {executor.submit(self.check_connection_to_base_url_and_save_error, task): task 
               for task in tasks if should_check_connection}
    for future in as_completed(futures):
        task = futures[future]
        if future.result():
            tasks_filtered.append(task)
```

### Solution 4: Ajouter un timeout global à `check_connection_to_base_url_and_save_error()`

Utiliser `timeout_decorator` ou `concurrent.futures` pour limiter le temps total de la vérification:

```python
@timeout_decorator.timeout(10)  # 10 secondes maximum
def check_connection_to_base_url_and_save_error(self, task: Task) -> bool:
    # ... code existant
```

## Recommandation Immédiate

**Solution rapide**: Ajouter un timeout explicite à la résolution DNS dans `_get_ip_for_locking()` en utilisant `concurrent.futures.ThreadPoolExecutor` avec timeout pour `lookup()`, ou configurer le timeout de `dns.resolver.Resolver`.

**Solution à long terme**: Paralléliser les vérifications de connexion dans `process_multiple()` et ajouter des timeouts à tous les appels DNS.

## Fichiers à Modifier

1. `artemis/resolvers.py` - Ajouter timeout à `socket.gethostbyname()`
2. `artemis/module_base.py` - Paralléliser `check_connection_to_base_url_and_save_error()` ou ajouter timeout global
3. `artemis/retrying_resolver.py` - Configurer timeout DNS explicite
