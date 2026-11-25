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
| 0 | Prérequis techniques | environnement installé, dépôt Git initialisé | ☐ | |
| 1 | Installer et découvrir | rapport de mise en place | ☐ | |
| 2 | Analyser les anomalies | tableau d'analyse initiale (reproductions) | ☐ | |
| 3 | Concept et stratégie de test | `TESTING.md` | ☑ | 25.11.2026 |
| 4 | Concevoir et automatiser les tests | plan de test + code + scripts npm | ☐ | |
| 5 | Exécuter, corriger et vérifier | résultats, corrections, retests | ☐ | |
| — | Rapport final + journal de travail | PDF conforme au modèle, journal | ☐ | |

Rappels du CDC : **aucune correction fonctionnelle avant l'étape 5**, aucun test automatisé
exigé avant l'étape 4. Un critère hors étape est noté NE (non évalué).

---

## Étape 0 — Prérequis techniques

- [ ] Node.js ≥ 18 et npm installés (`node -v`, `npm -v`) — version notée : ______
- [ ] MongoDB installé et démarré (`mongod` écoute sur `127.0.0.1:27017`) — **actuellement absent sur ce poste**
- [ ] `backend/.env` créé depuis `backend/.env.example` (fait automatiquement par `./start.sh`)
- [ ] Dépendances installées : `cd backend && npm install`, `cd frontend && npm install`
  (ou simplement `./start.sh` qui le fait au premier lancement)
- [ ] Application démarrée avec `./start.sh` → API `http://localhost:3000/api/tasks`, interface `http://localhost:5173`
- [ ] Dépôt Git initialisé à la racine du projet (`git init`), commit de l'état d'origine
- [ ] **Tag `v0-initial`** posé sur cet état : indispensable pour comparer « avant/après » à l'étape 5
- [ ] Journal de travail démarré (table en bas de ce fichier)

## Étape 1 — Installer et découvrir

Objectif : décrire l'environnement et les commandes réellement utilisées, sans corriger.

- [ ] Noter OS, versions Node/npm, version MongoDB, navigateur utilisé
- [ ] Vérifier que l'interface s'affiche et que la liste se charge (`GET /api/tasks` → `[]`)
- [ ] Créer une tâche depuis l'interface et observer ce qui se passe (à ce stade : succès ou échec, noter tel quel)
- [ ] Tester chaque bouton de l'interface (ajouter, modifier, supprimer) et noter les réactions
- [ ] Exercer l'API à la main avec `curl` : `GET`, `POST` valide, `POST` invalide, `PUT`, `DELETE`
- [ ] Consigner chaque difficulté d'installation rencontrée (c'est demandé explicitement)
- [ ] Rédiger le **rapport de mise en place** : commandes, ports, environnement, difficultés, captures

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

| ID | Hypothèse (lecture de code) | Exigence | Reproduit ? | Gravité | Priorité | Preuve |
|---|---|---|---|---|---|---|
| B-01 | `priority` déclarée `Number` dans le modèle au lieu d'une chaîne `low/medium/high` | CR-2 | ☐ | | | |
| B-02 | `validateTaskPayload()` retourne toujours `true` | CR-2 | ☐ | | | |
| B-03 | `POST` n'appelle pas la validation (données invalides acceptées) | CR-2 | ☐ | | | |
| B-04 | `title` non obligatoire dans le schéma | CR-2 | ☐ | | | |
| B-05 | `createdAt` écrasé/non immuable, `updatedAt` jamais mis à jour | CR-5 | ☐ | | | |
| B-06 | `PUT` sur un id inconnu répond 200 avec `null` | contrat API (404) | ☐ | | | |
| B-07 | `DELETE` sur un id inconnu répond 204 sans suppression | contrat API (404) | ☐ | | | |
| B-08 | handler d'erreur global renvoie `status(200)` | contrat API (500) | ☐ | | | |
| B-09 | l'interface envoie l'index du tableau au lieu de `_id` dans `PUT` | CR-1 | ☐ | | | |
| B-10 | le bouton supprimer utilise `method: 'GET'` | CR-1 | ☐ | | | |
| B-11 | mises à jour optimistes sans vérifier `res.ok` → succès affiché malgré l'échec | CR-4 | ☐ | | | |
| B-12 | libellés en anglais et priorités non traduites (low/medium/high) | CR-3 | ☐ | | | |
| B-13 | charte non respectée (couleurs des boutons, police, format d'erreur) | CR-6 | ☐ | | | |

Pour chaque anomalie confirmée, produire une fiche avec : identifiant, environnement,
préconditions, étapes, données, résultat attendu, résultat observé, preuve, gravité, priorité.

- [ ] B-01 à B-13 : statut « reproduit / infirmé / non testable » renseigné
- [ ] Fiches de reproduction rédigées pour chaque anomalie confirmée
- [ ] **Aucune correction** apportée au code à ce stade
- [ ] Tableau d'analyse initiale exporté (PDF ou Markdown) et joint au rapport

## Étape 3 — Concept et stratégie de test

- [x] `TESTING.md` rédigé (objectifs, périmètre, risques, niveaux, outils, jeux de données,
  critères d'entrée/sortie, ordre d'exécution, traçabilité)
- [ ] Après l'étape 2 : mettre à jour le statut des anomalies dans `TESTING.md`
  (« hypothèse » → « reproduite » ou « infirmée »)
- [ ] Ajouter la date de dernière mise à jour en tête de `TESTING.md`

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
| | | | |

## Notes libres

- Le chemin nominal de `./start.sh` n'a pas encore été vérifié : MongoDB n'est pas installé sur
  le poste et les dépendances npm ne sont pas installées (`./start.sh` s'en charge au 1er lancement).
- Ne pas utiliser la base `tasktimer` de démonstration pour les tests destructifs (CDC, étape 3).
- Le dossier du projet n'est pas encore un dépôt Git : initialiser avant de corriger, pour
  pouvoir produire les preuves avant/après.
