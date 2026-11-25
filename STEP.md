# STEP.md — Plan de travail TaskTimer (module 450)

Document de suivi personnel : une case cochée = travail terminé **et** preuve disponible.
Renseigner la date dès qu'une case est cochée, et la référence de preuve (`P-xx` selon
`TESTING.md`) ou le chemin du fichier produit.

Références stables utilisées ici :

- `CR-1`…`CR-6` : exigences du cahier des charges (`S-450-01_Cahier_des_charges_TaskTimer`).
- `R1`…`R13` : risques et `B-01`…`B-13` : anomalies, tels que définis dans `TESTING.md`.
- `TC-U-xx` (unitaire), `TC-I-xx` (intégration), `TC-E-xx` (E2E), `TC-P-xx` (performance),
  `TC-S-xx` (sécurité) : identifiants prévus dans `TESTING.md`.
- `B-xx` = **hypothèse** tant que l'anomalie n'a pas été reproduite. Ne jamais présenter une
  hypothèse comme un défaut constaté dans le rapport.

## Tableau de progression

| Étape | Intitulé CDC | Livrable attendu | Statut | Date |
|---|---|---|---|---|
| 0 | Prérequis techniques | environnement installé, dépôt Git initialisé | ☑ | 25.11.2026 |
| 1 | Installer et découvrir | rapport de mise en place | ◐ | 25.11.2026 |
| 2 | Analyser les anomalies | tableau d'analyse initiale (reproductions) | ☑ | 25.11.2026 |
| 3 | Concept et stratégie de test | `TESTING.md` | ☑ | 25.11.2026 |
| 4 | Concevoir et automatiser les tests | plan de test + code + scripts npm | ☐ | |
| 5 | Exécuter, corriger et vérifier | résultats, corrections, retests | ☐ | |
| — | Rapport final + journal de travail | PDF conforme au modèle, journal | ☐ | |

Légende : `☑` terminé et prouvé · `◐` partiel (reste à faire précisé dans la section) · `☐` à faire.

Rappels du CDC : **aucune correction fonctionnelle avant l'étape 5**, aucun test automatisé
exigé avant l'étape 4. Un critère hors étape est noté NE (non évalué).

---

## Étape 0 — Prérequis techniques

- [x] Node.js ≥ 18 et npm installés — **Node v26.13.1, npm 12.2.3**
- [x] MongoDB installé et démarré : **MongoDB 7.0.14 local** dans `.tools/mongodb` (données dans
  `.data/mongo`, port `127.0.0.1:27017`). Pas d'installation système : `sudo` exige un mot de passe
  et l'OS (FWS Linux) n'a pas `apt`.
- [x] `backend/.env` créé depuis `backend/.env.example` (`MONGODB_URI=mongodb://127.0.0.1:27017/tasktimer`, `PORT=3000`)
- [x] Dépendances installées : backend (cors, dotenv, express, mongoose, morgan) et frontend (vue, vite)
- [x] Application démarrée avec `./start.sh` → API `http://localhost:3000/api/tasks` (200), interface `http://localhost:5173` (200)
- [x] Dépôt Git initialisé à la racine du projet, commit de l'état d'origine
- [x] **Tag `v0-initial`** posé sur cet état : indispensable pour comparer « avant/après » à l'étape 5
- [x] Dépôt distant : https://github.com/BlackAngelTVdev/450-timer (branche `main`)
- [x] Journal de travail démarré (table en bas de ce fichier)

Constats du 25.11.2026 : le premier `POST` avec `priority` en texte échoue déjà (voir B-01 ci-dessous),
c'est-à-dire que l'application démarre mais ne permet pas de créer une tâche.

## Étape 1 — Installer et découvrir

Objectif : décrire l'environnement et les commandes réellement utilisées, sans corriger.

- [x] Noter OS, versions Node/npm, version MongoDB, navigateur utilisé — 25.11.2026 (`ANALYSE.md` §1.1 ;
  navigateur : **aucun installé**, Chrome absent)
- [x] Vérifier que l'interface s'affiche et que la liste se charge (`GET /api/tasks` → `[]`) — 25.11.2026
  (`/` sur `5173` → 200, `GET /api/tasks` → `[]` 200)
- [ ] Créer une tâche depuis l'interface et observer ce qui se passe (à ce stade : succès ou échec, noter tel quel)
  → **non exécuté : pas de navigateur installé** ; le même enchaînement est reproduit via `curl` (P-01)
- [ ] Tester chaque bouton de l'interface (ajouter, modifier, supprimer) et noter les réactions
  → **non exécuté : pas de navigateur** ; comportement déduit du code (`ANALYSE.md`, B-09 à B-13)
- [x] Exercer l'API à la main avec `curl` : `GET`, `POST` valide, `POST` invalide, `PUT`, `DELETE` — 25.11.2026
- [x] Consigner chaque difficulté d'installation rencontrée (c'est demandé explicitement) — 25.11.2026,
  `ANALYSE.md` §1.2 (4 difficultés)
- [x] Rédiger le **rapport de mise en place** : commandes, ports, environnement, difficultés, captures —
  `ANALYSE.md` §1 (captures remplacées par les transcriptions de commandes, faute de navigateur)

Commandes utiles :

```bash
./start.sh                                   # back + front
curl -s localhost:3000/api/tasks             # liste
curl -s -X POST localhost:3000/api/tasks \
  -H 'Content-Type: application/json' \
  -d '{"title":"Test","priority":"medium"}'  # création
```

## Étape 2 — Analyser les anomalies

Objectif : **reproduire** chaque hypothèse. Le tableau ci-dessous est le point de départ :
la colonne « Reproduit » doit être remplie uniquement avec une preuve (requête + réponse,
écran, log).

| ID | Anomalie | Exigence | Reproduit ? | Gravité | Priorité | Preuve |
|---|---|---|---|---|---|---|
| B-01 | `priority` déclarée `Number` dans le modèle au lieu d'une chaîne `low/medium/high` | CR-2 | ☑ oui — POST texte → 500 | Bloquante | Haute | P-01 |
| B-02 | `validateTaskPayload()` retourne toujours `true` | CR-2 | ☑ oui — `true` sur `{}` | Élevée | Haute | P-02 |
| B-03 | `POST` n'appelle pas la validation (données invalides acceptées) | CR-2 | ☑ oui — `POST {}` → 201 | Élevée | Haute | P-03 |
| B-04 | `title` non obligatoire dans le schéma | CR-2 | ☑ oui — 201 sans `title` | Élevée | Haute | P-04 |
| B-05 | `createdAt` écrasé/non immuable, `updatedAt` jamais mis à jour | CR-5 | ☑ oui — dates mesurées | Élevée | Moyenne | P-05 |
| B-06 | `PUT` sur un id inconnu répond 200 avec `null` | contrat API (404) | ☑ oui — 200 `null` | Moyenne | Moyenne | P-06 |
| B-07 | `DELETE` sur un id inconnu répond 204 sans suppression | contrat API (404) | ☑ oui — 204 | Moyenne | Moyenne | P-07 |
| B-08 | handler d'erreur global renvoie `status(200)` | contrat API (500) | ☑ oui — JSON mal formé → 200 | Moyenne | Moyenne | P-08 |
| B-09 | l'interface envoie l'index du tableau au lieu de `_id` dans `PUT` | CR-1 | ☑ API (`PUT /0` → 400) + code | Élevée | Haute | P-09 |
| B-10 | le bouton supprimer utilise `method: 'GET'` | CR-1 | ☑ API (tâche toujours là) + code | Élevée | Haute | P-09 |
| B-11 | mises à jour optimistes sans vérifier `res.ok` → succès affiché malgré l'échec | CR-4 | ☑ recoupement code + P-01 | Élevée | Haute | P-10 |
| B-12 | libellés en anglais et priorités non traduites (low/medium/high) | CR-3 | ☑ lecture du code | Faible | Moyenne | P-10 |
| B-13 | charte non respectée (couleurs des boutons, police, format d'erreur) | CR-6 | ☑ lecture du code | Faible | Basse | P-10 |

**Fiches détaillées, transcriptions des requêtes et tableau récapitulatif : `ANALYSE.md`.**
Toutes les reproductions API ont été faites sur une base isolée `tasktimer_test` (port `3001`),
jamais sur la base de démonstration `tasktimer` (exigence du CDC). Base supprimée après usage.

**P-01 — constat d'exécution du 25.11.2026** (à reprendre comme preuve dans le rapport) :

```
$ curl -s -X POST http://localhost:3000/api/tasks \
    -H 'Content-Type: application/json' \
    -d '{"title":"Test étape 0","priority":"medium"}' -w ' -> %{http_code}'
{"error":"create failed"} -> 500
```

Attendu (contrat API) : `201` avec l'objet créé. Observé : `500`, aucune tâche créée.
Cela confirme le risque R1. L'isolement de la cause a été fait depuis : B-01 (`priority` en
`Number` → échec de cast) déclenche l'exception, B-02 et B-03 laissent passer les données
invalides sans jamais les refuser.

Pour chaque anomalie confirmée, produire une fiche avec : identifiant, environnement,
préconditions, étapes, données, résultat attendu, résultat observé, preuve, gravité, priorité.

- [x] B-01 à B-13 : statut « reproduit / infirmé / non testable » renseigné — 25.11.2026, 13/13 reproduites
  ou confirmées, 0 infirmée
- [x] Fiches de reproduction rédigées pour chaque anomalie confirmée — `ANALYSE.md` §3 (13 fiches)
- [x] **Aucune correction** apportée au code à ce stade — seul ajout : `ANALYSE.md` (documentation)
- [x] Tableau d'analyse initiale exporté (PDF ou Markdown) et joint au rapport — `ANALYSE.md` §5
  (version Markdown ; export PDF à faire avec le rapport final)

## Étape 3 — Concept et stratégie de test

- [x] `TESTING.md` rédigé (objectifs, périmètre, risques, niveaux, outils, jeux de données,
  critères d'entrée/sortie, ordre d'exécution, traçabilité)
- [x] Après l'étape 2 : mettre à jour le statut des anomalies dans `TESTING.md`
  (« hypothèse » → « reproduite » ou « infirmée ») — 25.11.2026, §4 renvoie vers `ANALYSE.md`
- [x] Ajouter la date de dernière mise à jour en tête de `TESTING.md` — version 1.1 du 25.11.2026

## Étape 4 — Concevoir et automatiser les tests

Architecture à mettre en place (voir `TESTING.md` §6) :

- [ ] `vitest` + `supertest` + `mongodb-memory-server` installés en `devDependencies`
  (repli : base locale `tasktimer_test` si le binaire ne se télécharge pas)
- [ ] Fichier de configuration Vitest (`backend/vitest.config.js`) avec `MONGODB_URI` de test
- [ ] Utilitaire de test : connexion à la base de test, `drop()` de `tasks` avant chaque test, seed (`J0`…`J6`)
- [ ] Plan de test écrit : chaque cas avec identifiant, exigence/risque, préconditions, données,
  étapes, attendu, observé, statut, preuve

Minimum obligatoire du CDC :

- [ ] Tests **unitaires** de la validation (`utils/validation.js`) — `TC-U-01`…`TC-U-06`
- [ ] Au moins **3 tests d'intégration API** : cas valide, cas invalide, erreur attendue — `TC-I-01`…`TC-I-10`
- [ ] Au moins **2 parcours E2E** sur l'interface (un succès, une erreur) — `TC-E-01`…`TC-E-05`
- [ ] Au moins **1 test de performance** sur `GET /api/tasks` — `TC-P-01`
  (env., jeu `J6` = 200 tâches, 20 connexions, 20 s, seuils fixés avant mesure : p95 < 300 ms, erreurs < 1 %)
- [ ] Au moins **1 test de sécurité** : entrée invalide rejetée **sans modification en base** — `TC-S-01`
- [ ] Scripts npm ajoutés : `test`, `test:unit`, `test:integration`, `test:e2e`, `test:perf`, `test:all`
- [ ] Instructions de lancement écrites (README ou section dédiée de `TESTING.md`)
- [ ] Vérifier que les tests ne touchent **jamais** la base `tasktimer` de démonstration

## Étape 5 — Exécuter, corriger et vérifier

- [ ] Exécuter toute la suite sur la version **initiale** et conserver les résultats, **échecs compris**
- [ ] Preuve par type de test : commande ou procédure + résultat + statut
- [ ] Indiquer taux de réussite, couverture disponible et limites (ne pas confondre couverture et qualité)
- [ ] Classer les anomalies (gravité/priorité) et décider quoi corriger
- [ ] Corriger **dans l'ordre de `TESTING.md`** : R1 d'abord (B-01/B-02/B-03), puis R2, R3, R4, R5, R13…
- [ ] Un commit par correction, message référençant `B-xx`
- [ ] Documenter pour chaque correction : cause probable, modification, preuve avant/après, statut
- [ ] Relancer les tests concernés **puis** les tests de non-régression
- [ ] Si une correction est abandonnée : expliquer la raison et l'impact

## Livrables finaux

- [ ] Rapport PDF conforme à `S-P450_Modele_rapport_TaskTimer` (structure imposée conservée)
- [ ] Projet avec code des tests, scripts npm, configuration, instructions reproductibles
- [ ] `TESTING.md`
- [ ] Journal de travail
- [ ] Preuves d'exécution et de retest, intégrées au rapport ou jointes
- [ ] Relecture croisée avec `S-P450_Grille_evaluation_TaskTimer` : chaque critère
  (ENV, ANA, CT, STR, PT, AUTO, RES, DOC, COR, PER, SEC) doit pouvoir être coché par une preuve

---

## Journal de travail

| Date | Durée | Activité | Résultat / preuve |
|---|---|---|---|
| 24.11.2026 | | Décompression du projet, lecture du cahier des charges, lecture du code | 13 hypothèses d'anomalies |
| 25.11.2026 | | Rédaction de `TESTING.md` (concept et stratégie) | `TESTING.md` |
| 25.11.2026 | | Script de démarrage `start.sh` (back + front en une commande) | `start.sh`, testé en échec contrôlé |
| 25.11.2026 | | Installation de MongoDB 7.0.14 local (`.tools/mongodb`), démarrage automatique dans `start.sh` | `mongod` répond, connexion Mongoose validée |
| 25.11.2026 | | Initialisation Git, commit initial, tag `v0-initial`, dépôt distant | commit `1ab1d57`, tag `v0-initial`, push sur `main` |
| 25.11.2026 | | Vérification du démarrage complet à froid puis arrêt propre | API 200, UI 200, mongod arrêté proprement (P-01) |
| 25.11.2026 | | Étape 1 : relevé de l'environnement, exercice de l'API avec `curl`, difficultés d'installation | `ANALYSE.md` §1 |
| 25.11.2026 | | Étape 2 : reproduction des 13 anomalies sur base isolée `tasktimer_test` | `ANALYSE.md` §3–§5, preuves P-01…P-10 |
| 25.11.2026 | | Mise à jour de `TESTING.md` (statut des anomalies, version 1.1) | `TESTING.md` §4 |
| | | | |

## Notes libres

- MongoDB n'est pas installé au niveau système : binaire officiel 7.0.14 décompressé dans
  `.tools/mongodb` (non versionné), données dans `.data/mongo` (non versionnées). `./start.sh`
  le démarre si le port 27017 ne répond pas, et l'arrête à la sortie (`KEEP_MONGO=1` pour le garder).
- Le chemin nominal de `./start.sh` est vérifié : démarrage à froid (mongod + API + Vite), réponses
  HTTP 200/200, puis arrêt propre des trois processus.
- Ne pas utiliser la base `tasktimer` de démonstration pour les tests destructifs (CDC, étape 3) :
  créer `tasktimer_test` à l'étape 4.
- Dépôt : https://github.com/BlackAngelTVdev/450-timer — un commit par correction à l'étape 5,
  message référençant `B-xx`.
- Base de test : `tasktimer_test`, utilisée sur un port d'API séparé (`3001`) pour ne pas
  mélanger avec les données de démonstration, puis supprimée après la campagne de reproduction.
- Navigateur absent de la machine : les parcours d'interface (étape 1 et B-09 à B-13) seront
  exécutés à l'étape 4 avec Playwright/Chromium, qui servira aussi de preuve visuelle.
