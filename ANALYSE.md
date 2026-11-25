# ANALYSE.md — Mise en place et analyse initiale des anomalies

Module 450 (ETML / DevFactory) — TaskTimer, version `v0-initial` (commit `1ab1d57`).
Document rédigé le 25.11.2026. Il couvre l'étape 1 (« Installer et découvrir ») et
l'étape 2 (« Analyser les anomalies ») du cahier des charges.

> Règle appliquée : **aucune correction de code** n'a été apportée. Les anomalies ne sont
> déclarées « reproduites » que si une preuve d'exécution ou une lecture de code ciblée est
> citée. Les preuves sont numérotées `P-01`…`P-10` et reprises dans `STEP.md`.

---

## 1. Rapport de mise en place (étape 1)

### 1.1 Environnement réellement utilisé

| Élément | Valeur constatée |
|---|---|
| OS | FWS Linux (base Arch-like), pas d'`apt`, `sudo` protégé par mot de passe |
| Node.js / npm | `v26.13.1` / `12.2.3` |
| MongoDB | 7.0.14, binaire local dans `.tools/mongodb`, données dans `.data/mongo`, écoute `127.0.0.1:27017` |
| Navigateur | **aucun navigateur installé** (Chrome absent) → les parcours d'interface n'ont pas pu être exécutés |
| Ports | API `3000`, interface `5173` (proxy Vite `/api` → `3000`), MongoDB `27017` |
| Dépôt | https://github.com/BlackAngelTVdev/450-timer, branche `main`, tag `v0-initial` |

### 1.2 Difficultés rencontrées (demandées par le CDC)

1. **Pas de paquet MongoDB pour l'OS** : `apt` absent et `sudo` demande un mot de passe.
   Solution : archive officielle `mongodb-linux-x86_64-ubuntu2204-7.0.14.tgz` décompressée
   dans `.tools/mongodb` (hors versionnement), `mongod` lancé par `./start.sh`.
2. **Port ouvert ≠ MongoDB prêt** : un `mongod` en cours d'arrêt gardait `27017` en écoute et
   le backend échouait en `ECONNREFUSED`. `start.sh` teste donc une **vraie connexion Mongoose**
   avant de démarrer l'API.
3. **Deux terminaux à gérer** (backend + frontend) : un seul script `./start.sh` démarre et
   arrête les trois processus, installe les dépendances au premier lancement et crée `backend/.env`.
4. **`shellcheck` absent** : le script a été validé par exécution réelle (démarrage à froid +
   arrêt propre), pas par analyse statique.

### 1.3 Commandes utilisées

```bash
cd x-Projets/TaskTimer_Bugged
./start.sh                            # MongoDB + API + interface, Ctrl+C pour tout arrêter
curl -s localhost:3000/api/tasks      # liste (200, [])
curl -s localhost:5173/ -o /dev/null -w '%{http_code}'   # interface (200)
```

---

## 2. Méthode de reproduction (étape 2)

- Anomalies **serveur** : API lancée sur une instance dédiée
  (`MONGODB_URI=mongodb://127.0.0.1:27017/tasktimer_test PORT=3001`), sollicitée avec `curl`.
  La base `tasktimer` de démonstration n'a **pas** été utilisée pour les tests destructifs
  (exigence du CDC) ; `tasktimer_test` a été supprimée après chaque campagne.
- Anomalies **interface** : lecture ciblée de `frontend/src/App.vue`, recoupée avec le
  comportement observé de l'API. Aucun navigateur n'étant installé, ces anomalies sont
  marquées « reproduite par lecture + recoupement API » et seront reconfirmées visuellement
  à l'étape 4 (Playwright).
- Environnement de référence : contrat API du CDC §4 et exigences CR-1…CR-6.

---

## 3. Fiches de reproduction

### B-01 — Priorité stockée dans un type incompatible

- **Composant** : `backend/src/models/task.js` (`priority: Number`), API de création.
- **Préconditions / données** : API démarrée, base de test vide ; `{"title":"Test étape 0","priority":"medium"}`.
- **Étapes** : `POST /api/tasks` puis `GET /api/tasks`.
- **Attendu** : `201` et tâche créée avec `priority:"medium"` (CR-2).
- **Observé** : `500 {"error":"create failed"}`, aucune tâche créée.
- **Preuve** : **P-01** (voir §4).
- **Cause** : Mongoose tente de caster `"medium"` en `Number`, échoue, l'exception est
  convertie en `500` par la route.
- **Statut** : reproduite — **Gravité : bloquante — Priorité : haute**.

### B-02 — `validateTaskPayload()` retourne toujours `true`

- **Composant** : `backend/src/utils/validation.js`.
- **Étapes** : appel direct du module avec `{}` puis avec `{"title":"","priority":"x"}`.
- **Attendu** : un résultat exploitable (`{ ok:false, errors:[…] }`) pour des données invalides.
- **Observé** : `true` dans les deux cas — la fonction ne peut jamais signaler d'erreur.
- **Preuve** : **P-02**.
- **Statut** : reproduite — **Gravité : élevée — Priorité : haute** (cause racine de R2).

### B-03 — `POST` accepte n'importe quelle donnée

- **Composant** : `backend/src/routes/tasks.js` (`POST /`).
- **Étapes** : `POST /api/tasks` avec `{}`.
- **Attendu** : `400` avec une propriété `error` ; aucune tâche créée.
- **Observé** : `201` et tâche persistée `{"description":"","priority":1,_id,…,__v":0}` — sans titre.
- **Preuve** : **P-03**.
- **Statut** : reproduite — **Gravité : élevée — Priorité : haute**.

### B-04 — `title` non obligatoire

- **Composant** : `backend/src/models/task.js` (`title: { required:false }`).
- **Étapes** : `POST /api/tasks` avec `{"priority":2,"description":"sans titre"}`.
- **Attendu** : `400` (titre obligatoire non vide, CR-2).
- **Observé** : `201`, tâche enregistrée **sans champ `title`**.
- **Preuve** : **P-04**.
- **Statut** : reproduite — **Gravité : élevée — Priorité : haute**.

### B-05 — `createdAt` réécrit, `updatedAt` figé

- **Composant** : `backend/src/services/taskService.js` (`updateTask`) et modèle (pas de hooks).
- **Étapes** : créer une tâche (`createdAt = 09:12:03.644`), attendre 2 s, puis
  `PUT /api/tasks/:id` avec `{"title":"Tache dates modifiee","priority":2,"createdAt":"2020-01-01T00:00:00.000Z","updatedAt":"2020-01-01T00:00:00.000Z"}`.
- **Attendu** : `createdAt` inchangé, `updatedAt` actualisé par le serveur, dates non modifiables (CR-5, CDC §4).
- **Observé** : `createdAt` devient `09:12:05.716` (écrasé par le serveur) et `updatedAt`
  recule à `2020-01-01T00:00:00.000Z` (valeur du client conservée) ; en base :
  `createdAt: 09:12:05.716`, `updatedAt: 2020-01-01T00:00:00.000Z`.
- **Preuve** : **P-05**.
- **Statut** : reproduite — **Gravité : élevée — Priorité : moyenne**.

### B-06 — `PUT` sur un identifiant inconnu répond 200 `null`

- **Étapes** : `PUT /api/tasks/000000000000000000000000` (ObjectId valide, inexistant).
- **Attendu** : `404` avec `error`.
- **Observé** : `200` et corps `null`.
- **Preuve** : **P-06**.
- **Statut** : reproduite — **Gravité : moyenne — Priorité : moyenne**.

### B-07 — `DELETE` sur un identifiant inconnu répond 204

- **Étapes** : `DELETE /api/tasks/000000000000000000000000`.
- **Attendu** : `404` ; `204` réservé à une suppression réelle.
- **Observé** : `204` sans corps, alors qu'aucune tâche n'a été supprimée.
- **Preuve** : **P-07**.
- **Statut** : reproduite — **Gravité : moyenne — Priorité : moyenne**.

### B-08 — Le handler d'erreur renvoie 200

- **Composant** : `backend/src/server.js` (`res.status(200).json({ error:'Something went wrong' })`).
- **Étapes** : `POST /api/tasks` avec un JSON mal formé (`{"title":`).
- **Attendu** : `400` (JSON mal formé) ou `500` (erreur interne), jamais `200`.
- **Observé** : `200 {"error":"Something went wrong"}`.
- **Preuve** : **P-08**.
- **Statut** : reproduite — **Gravité : moyenne — Priorité : moyenne**.
- Remarque : une erreur de validation Mongoose dans `POST` est déjà convertie en `500`
  `create failed` par la route, donc le handler global ne masque pas ce cas-là ; il masque
  les erreurs de parsing et les erreurs non interceptées.

### B-09 — `PUT` envoyé sur l'index du tableau

- **Composant** : `frontend/src/App.vue`, `saveEditBuggy(idx)` → `fetch(`${API}/${idx}`, { method:'PUT' })`.
- **Étapes** : reproduire la requête réellement émise pour la première tâche : `PUT /api/tasks/0`.
- **Attendu** : `PUT /api/tasks/<_id>` → `200` avec la tâche mise à jour.
- **Observé** : `400 {"error":"invalid task id"}` (l'index n'est pas un ObjectId). L'interface
  ignore la réponse et affiche la modification : rien n'est persisté.
- **Preuve** : **P-09** + lecture de code.
- **Statut** : reproduite (API) / confirmée par lecture (interface) — **Gravité : élevée — Priorité : haute**.

### B-10 — Suppression envoyée en `GET`

- **Composant** : `frontend/src/App.vue`, `deleteTaskBuggy(idx)` → `fetch(`${API}/${id}`, { method:'GET' })`.
- **Étapes** : reproduire la requête : `GET /api/tasks/<id>` puis `GET /api/tasks`.
- **Attendu** : `DELETE /api/tasks/<id>` → `204`, puis tâche absente de la liste.
- **Observé** : `GET /api/tasks/<id>` → `200` avec l'objet, puis la tâche **est toujours
  présente** dans la liste. La ligne disparaît seulement de l'affichage local.
- **Preuve** : **P-09** + lecture de code.
- **Statut** : reproduite (API) / confirmée par lecture (interface) — **Gravité : élevée — Priorité : haute**.

### B-11 — Mises à jour optimistes sans vérifier `res.ok`

- **Composant** : `frontend/src/App.vue` (`createTaskBuggy`, `saveEditBuggy`, `deleteTaskBuggy`).
- **Étapes** : lecture du code + recoupement avec P-01 : le formulaire envoie
  `priority` en texte (`low|medium|high`) et l'API répond **500** ; le `fetch` est donc en échec.
- **Attendu** : message d'erreur visible, liste inchangée, saisie conservée (CR-4).
- **Observé** : la tâche est ajoutée à `tasks.value` **avant** la requête, aucune vérification
  de `res.ok`, `catch(e){}` vide, puis le formulaire est vidé. L'utilisateur voit un succès
  pour une tâche jamais enregistrée ; le rechargement la fait disparaître.
- **Preuve** : **P-10** + P-01.
- **Statut** : reproduite par lecture + recoupement — **Gravité : élevée — Priorité : haute**.

### B-12 — Libellés anglais / priorités non traduites

- **Composant** : `frontend/src/App.vue` (template).
- **Attendu** (CR-3) : interface entièrement en français, priorités « Faible / Moyenne / Élevée ».
- **Observé** : boutons et textes `Create task`, `Create`, `Save`, `Cancel`, `Edit`, `Delete`,
  `No tasks yet.` ; seules les options de priorité sont en français, mais la valeur affichée
  dans la liste est brute (`[low]`, `[medium]`, `[high]`, et même `[1]` avec le bug B-01).
- **Preuve** : **P-10** (lecture de code) ; confirmation visuelle prévue à l'étape 4.
- **Statut** : confirmée par lecture — **Gravité : faible — Priorité : moyenne**.

### B-13 — Charte graphique non respectée

- **Composant** : `frontend/src/App.vue` (bloc `<style>`).
- **Attendu** (Annexe A du CDC) : bouton principal « + Ajouter une tâche », fond `#007BFF`,
  survol `#0056b3` ; erreurs en `#c1121f` sur `#ffeef0` au format « Erreur : [message] » ;
  police Arial ou Roboto, base 14 px.
- **Observé** : boutons `.btn-bad` en vert `#2ecc71` sans état de survol, libellé `Create`
  au lieu de « + Ajouter une tâche », police `"Times New Roman", serif` en `12px`, message
  d'erreur en `#333` sans fond. Écarts sur 5 points de la charte.
- **Preuve** : **P-10** (lecture de code) ; confirmation visuelle prévue à l'étape 4.
- **Statut** : confirmée par lecture — **Gravité : faible — Priorité : basse**.

---

## 4. Preuves d'exécution (transcriptions)

Toutes les requêtes ci-dessous ont été passées sur l'instance de test
(`tasktimer_test`, port `3001`), sauf P-01 (base de démonstration, simple lecture d'échec).

**P-01 — POST avec priorité textuelle (base `tasktimer`, version `v0-initial`)**

```
$ curl -s -X POST http://localhost:3000/api/tasks \
    -H 'Content-Type: application/json' \
    -d '{"title":"Test étape 0","priority":"medium"}' -w ' -> %{http_code}'
{"error":"create failed"} -> 500
```

**P-02 — validation unitaire**

```
$ node -e "import('./src/utils/validation.js').then(m=>{ ... })"
validateTaskPayload({}) = true
validateTaskPayload({title:"",priority:"x"}) = true
```

**P-03 — POST corps vide**

```
$ curl -s -X POST …/api/tasks -H 'Content-Type: application/json' -d '{}' -w ' -> %{http_code}'
{"description":"","priority":1,"_id":"6b06a657…","createdAt":"2026-11-25T09:11:51.448Z","updatedAt":"2026-11-25T09:11:51.448Z","__v":0} -> 201
```

**P-04 — POST sans titre**

```
$ curl -s -X POST … -d '{"priority":2,"description":"sans titre"}' -w ' -> %{http_code}'
{"description":"sans titre","priority":2,"_id":"6b06a65a…","createdAt":"…","updatedAt":"…","__v":0} -> 201
```

**P-05 — dates après PUT**

```
création        : createdAt 2026-11-25T09:12:03.644Z, updatedAt 2026-11-25T09:12:03.645Z
PUT (createdAt et updatedAt forcés à 2020-01-01)
réponse         : createdAt 2026-11-25T09:12:05.716Z, updatedAt 2020-01-01T00:00:00.000Z -> 200
en base         : createdAt 2026-11-25T09:12:05.716Z, updatedAt 2020-01-01T00:00:00.000Z
```

**P-06 — PUT id inconnu**

```
$ curl -s -X PUT …/api/tasks/000000000000000000000000 -d '{"title":"x","priority":1}' -w ' -> %{http_code}'
null -> 200
```

**P-07 — DELETE id inconnu**

```
$ curl -s -X DELETE …/api/tasks/000000000000000000000000 -w ' -> %{http_code}'
 -> 204
```

**P-08 — JSON mal formé**

```
$ curl -s -X POST …/api/tasks -H 'Content-Type: application/json' -d '{"title":' -w ' -> %{http_code}'
{"error":"Something went wrong"} -> 200
```

**P-09 — requêtes réellement émises par l'interface (B-09/B-10)**

```
$ curl -s -X PUT …/api/tasks/0 -d '{"title":"modifie","priority":1}' -w ' -> %{http_code}'
{"error":"invalid task id"} -> 400

$ curl -s -X GET …/api/tasks/<id> -w ' -> %{http_code}'
{"_id":"<id>","title":"Tache B-09 B-10",…} -> 200

$ curl -s …/api/tasks -w ' -> %{http_code}'
[{…tâche toujours présente…}] -> 200
```

**P-10 — lecture de `frontend/src/App.vue`**

```js
// mise à jour optimiste, aucune vérification de res.ok, erreurs avalées
tasks.value = [optimistic, ...tasks.value];
await fetch(API, { method:'POST', … })          // réponse jamais contrôlée
await fetch(`${API}/${idx}`, { method:'PUT', … })      // idx = index du tableau
await fetch(`${API}/${removed[0]?._id}`, { method:'GET' }) // suppression en GET
```

```css
.btn-bad{ background:#2ecc71; }                                  /* attendu #007BFF + survol #0056b3 */
.container{ font-family:"Times New Roman", serif; font-size:12px } /* attendu Arial/Roboto 14px */
#errors { color:#333 }                                            /* attendu #c1121f sur #ffeef0 */
```

---

## 5. Tableau récapitulatif de l'analyse initiale

| ID | Exigence | Statut | Gravité | Priorité | Preuve |
|---|---|---|---|---|---|
| B-01 | CR-2 | reproduite | Bloquante | Haute | P-01 |
| B-02 | CR-2 | reproduite | Élevée | Haute | P-02 |
| B-03 | CR-2 | reproduite | Élevée | Haute | P-03 |
| B-04 | CR-2 | reproduite | Élevée | Haute | P-04 |
| B-05 | CR-5 | reproduite | Élevée | Moyenne | P-05 |
| B-06 | contrat API (404) | reproduite | Moyenne | Moyenne | P-06 |
| B-07 | contrat API (404) | reproduite | Moyenne | Moyenne | P-07 |
| B-08 | contrat API (500) | reproduite | Moyenne | Moyenne | P-08 |
| B-09 | CR-1 | reproduite (API) / lecture | Élevée | Haute | P-09 |
| B-10 | CR-1 | reproduite (API) / lecture | Élevée | Haute | P-09 |
| B-11 | CR-4 | lecture + recoupement | Élevée | Haute | P-10, P-01 |
| B-12 | CR-3 | lecture | Faible | Moyenne | P-10 |
| B-13 | CR-6 | lecture | Faible | Basse | P-10 |

**Aucune anomalie n'a été infirmée ; aucune correction n'a été appliquée.**

### Limites de cette analyse

- Les anomalies d'interface (B-09 à B-13) reposent sur la lecture du code et le recoupement
  avec l'API ; l'observation visuelle et les parcours complets seront réalisés à l'étape 4
  (Playwright + Chromium), puis consignés comme preuves définitives.
- La création d'une tâche **valide** étant impossible (B-01), les cas `PUT`/`DELETE` nominaux
  ont été préparés avec des documents insérés via `POST` en priorité numérique ; à l'étape 5,
  le jeu de données de référence sera inséré directement en base de test.
- Les tests de performance et de sécurité ne relèvent pas de l'étape 2 (`TESTING.md` §10).
