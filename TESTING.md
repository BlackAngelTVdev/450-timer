# TESTING.md — TaskTimer

Concept et stratégie de test — Module 450 (ETML / DevFactory)
Version du document : 1.0 — 25.11.2026
Périmètre applicatif : TaskTimer_Bugged (backend Node.js/Express/Mongoose + frontend Vue 3/Vite)

> Ce document répond à l'étape 3 du cahier des charges (« Concept et stratégie de test »).
> Il décrit **ce qui doit être testé, pourquoi, comment et dans quel ordre**, avant toute
> correction. Les résultats d'exécution et les corrections sont documentés dans le rapport
> final, pas ici.

---

## 1. Objectifs

1. **Vérifier la conformité** de l'application aux exigences de réception CR-1 à CR-6 et au
   contrat API de référence (codes HTTP, corps JSON, persistance).
2. **Détecter et rendre reproductibles** les anomalies de la version fournie, avec preuves
   (requête, réponse, état de la base, capture d'interface).
3. **Prioriser les risques** pour l'utilisateur et pour les données, afin de concentrer
   l'effort de test et de correction là où l'impact est le plus fort.
4. **Automatiser** un socle de tests reproductibles (unitaire, intégration API, E2E) et
   l'exécuter sur la version initiale **puis** sur la version corrigée.
5. **Prouver l'amélioration** par des résultats avant/après et une non-régression complète.

Objectifs mesurables :

| Objectif | Indicateur | Cible |
|---|---|---|
| Couverture des exigences | CR-1 à CR-6 reliées à au moins un cas de test | 6/6 |
| Couverture des risques | chaque risque de niveau élevé/critique testé | 100 % |
| Anomalies documentées | anomalies avec étapes reproductibles + preuve | 100 % |
| Socle automatisé | unitaires + ≥ 3 intégration + ≥ 2 E2E | atteint et exécutable en une commande |
| Correction vérifiée | anomalies haute priorité retestées avec preuve après | 100 % |

## 2. Périmètre

### 2.1 Inclus

- **API** `/api/tasks` : `GET`, `POST`, `PUT /:id`, `DELETE /:id`.
  Validation des entrées, codes HTTP, corps des réponses, immutabilité de `createdAt`,
  actualisation d'`updatedAt`, persistance réelle en base après succès.
- **Interface** : création, affichage, modification, suppression d'une tâche ; gestion et
  affichage des erreurs ; libellés et charte graphique (annexe A du cahier des charges).
- **Cohérence UI ↔ API** : la liste ne doit refléter une opération qu'après succès confirmé.
- **Performance** : `GET /api/tasks` sous charge définie et reproductible.
- **Sécurité** : rejet d'une entrée invalide sans modification des données.
- **Erreurs transverses** : JSON mal formé, identifiant mal formé, identifiant inconnu,
  erreur interne.

### 2.2 Exclusions (assumées et justifiées)

| Exclusion | Justification |
|---|---|
| `GET /api/tasks/:id` | hors périmètre obligatoire du cahier des charges (§4) ; testé seulement en curiosité, sans critère de réussite |
| Champ `dueDate` du modèle | absent du contrat API et de l'interface ; signalé comme écart de modèle, non testé fonctionnellement |
| Authentification, comptes, droits | fonctionnalité inexistante dans la version fournie |
| Multi-utilisateurs / concurrence d'écriture métier | hors périmètre ; seule la concurrence en lecture est mesurée en performance |
| Compatibilité mobile / responsive | non exigée ; contrôle visuel desktop uniquement |
| Accessibilité complète (RGAA/WCAG) | non exigée ; seuls les contrastes et la police de l'annexe A sont vérifiés |
| Tests de charge extrême / soak test | hors périmètre du module ; un seul protocole de performance borné est exécuté |
| TDD | facultatif selon le cahier des charges |

## 3. Référentiel de conformité

- **CR-1** CRUD complet, liste fidèle aux données persistées.
- **CR-2** `title` obligatoire non vide, `priority` ∈ {low, medium, high}, `description`
  facultative (chaîne vide si absente) ; validation **dans l'UI et sur l'API**.
- **CR-3** Priorités affichées en français : Faible / Moyenne / Élevée ; libellés UI en français.
- **CR-4** Erreur visible, liste non trompeuse, **saisie conservée** pour correction.
- **CR-5** `createdAt` fixé par le serveur et immuable ; `updatedAt` actualisé à chaque
  modification réussie ; dates non modifiables via `PUT`.
- **CR-6** Charte UI : bouton « + Ajouter une tâche » `#007BFF` / survol `#0056b3`, erreurs
  `#c1121f` sur fond `#ffeef0` au format « Erreur : [message] » sous l'action concernée,
  police Arial/Roboto 14 px, liste à fond clair et texte noir.
- **Contrat API** : `GET` 200 tableau ; `POST` 201 objet créé ; `PUT` 200 objet mis à jour ;
  `DELETE` 204 sans corps ; 400 (JSON mal formé, id mal formé, données invalides) ;
  404 (id valide inconnu pour `PUT`/`DELETE`) ; 500 (erreur interne) ; toute erreur renvoie
  `{ "error": "..." }` et **ne modifie aucune donnée**.

## 4. Risques, impacts et liens avec les anomalies

Statut des anomalies ci-dessous : **hypothèse issue de la lecture de code**, à confirmer par
reproduction. Un identifiant `B-xx` ne change plus jusqu'à la fin du projet.

| ID | Risque | Impact utilisateur / données | Gravité | Priorité | Anomalies liées | Tests |
|---|---|---|---|---|---|---|
| R1 | Une tâche valide ne peut pas être créée (priorité stockée dans un type incompatible) | fonction essentielle inutilisable, produit non démontrable | Bloquante | Haute | B-01, B-02, B-03 | TC-I-01, TC-I-02, TC-E-01 |
| R2 | Données invalides acceptées et persistées (`title` vide, `priority` hors liste) | base polluée, affichage incohérent, corrections manuelles | Élevée | Haute | B-02, B-03, B-04 | TC-U-01…TC-U-06, TC-I-02, TC-S-01 |
| R3 | L'interface affiche un succès alors que l'API a échoué (mise à jour optimiste) | l'utilisateur croit avoir enregistré ; perte silencieuse de données | Élevée | Haute | B-11 | TC-E-02, TC-E-03 |
| R4 | Modification non persistée (mauvais identifiant envoyé) | travail perdu au rechargement, perte de confiance | Élevée | Haute | B-09 | TC-E-03 |
| R5 | Suppression non persistée (mauvaise méthode HTTP) | la tâche réapparaît ; impossibilité de supprimer | Élevée | Haute | B-10 | TC-E-04 |
| R6 | `createdAt` écrasé et `updatedAt` jamais actualisé | perte de traçabilité temporelle des données | Élevée | Moyenne | B-05 | TC-I-05, TC-I-06 |
| R7 | Erreurs serveur renvoyées en 200 / erreurs masquées | supervision impossible, faux positifs côté client | Moyenne | Moyenne | B-08, B-07 | TC-I-07, TC-I-08 |
| R8 | Identifiant inconnu traité comme un succès (200 `null`, 204 sans suppression) | l'utilisateur ne sait pas que l'action a échoué | Moyenne | Moyenne | B-06, B-07 | TC-I-09, TC-I-10 |
| R9 | Libellés anglais et priorités non traduites | non-respect de CR-3, lisibilité pour un public francophone | Faible | Moyenne | B-12 | TC-E-05 |
| R10 | Charte graphique non respectée (couleurs, police, format d'erreur) | non-respect de CR-6, évaluation partielle | Faible | Basse | B-13 | TC-E-05 |
| R11 | Validation absente côté client : formulaire vide accepté sans retour | expérience dégradée, requêtes inutiles | Moyenne | Moyenne | B-11, B-02 | TC-E-02 |
| R12 | Dégradation du temps de réponse sur `GET /api/tasks` | interface lente, perception de panne | Moyenne | Basse | — (mesure) | TC-P-01 |
| R13 | Entrée malveillante/invalide modifiant les données | intégrité des données compromise | Élevée | Haute | B-02, B-03 | TC-S-01 |

**Ordre de traitement des risques** : R1 (bloquant, conditionne tous les autres tests) →
R2, R3, R4, R5, R13 (données et confiance) → R6, R7, R8, R11 → R9, R10, R12.

## 5. Niveaux et types de tests

| Niveau / type | Cible | Objectif | Isolation |
|---|---|---|---|
| **Unitaire** | `utils/validation.js` (règles CR-2), formatage des libellés de priorité (CR-3) | vérifier la logique pure sans base, sans réseau, sans DOM | totale : aucune I/O |
| **Intégration API** | routeur `/api/tasks` + service + modèle + MongoDB | codes HTTP, corps JSON, persistance et non-modification en cas d'erreur | base MongoDB de test dédiée, réinitialisée avant chaque test |
| **E2E (interface)** | frontend Vue lancé + backend + base de test | parcours utilisateur réels : succès et erreur, fidélité de la liste | navigateur réel (Chromium), base réinitialisée par scénario |
| **Performance** | `GET /api/tasks` | temps de réponse et taux d'erreur sous charge reproductible | base de test avec jeu de données fixe |
| **Sécurité** | `POST`/`PUT` avec entrées invalides ou hostiles | rejet sans écriture en base | base de test, comparaison avant/après |
| **Vérification visuelle** | UI | charte CR-6 (couleurs, police, libellés, position de l'erreur) | manuelle, capture d'écran |

Justification des niveaux : la logique de validation est extraite dans un module dédié, donc
testable en unitaire ; les défauts observés se situent majoritairement à l'interface entre
route, service et modèle, ce qui rend l'intégration API indispensable ; les anomalies les plus
coûteuses pour l'utilisateur (R3, R4, R5) ne sont visibles qu'en E2E car elles concernent la
synchronisation entre l'affichage et le serveur.

## 6. Outils et justification

| Outil | Usage | Justification |
|---|---|---|
| **Vitest** | tests unitaires et d'intégration | même famille que Vite déjà présent côté frontend, configuration minimale, exécution rapide, compatible ESM (le projet est en `"type": "module"`) |
| **Supertest** | requêtes HTTP sur l'app Express sans ouvrir de port | teste le routeur et la pile middleware réelle, y compris le handler d'erreur global |
| **mongodb-memory-server** | base MongoDB éphémère par exécution | garantit l'isolation et la réinitialisation, évite tout risque sur la base de démonstration ; alternative retenue : base `tasktimer_test` locale si le binaire n'est pas téléchargeable |
| **Playwright** | E2E sur l'interface réelle | pilote Chromium, gère l'attente réseau, capture d'écran automatique en preuve, `webServer` pour lancer backend + frontend |
| **autocannon** (ou `k6`) | test de performance de `GET /api/tasks` | protocole reproductible (durée, concurrence, nombre de requêtes), sortie chiffrée exploitable dans le rapport |
| **curl / Postman** | reproduction manuelle et preuves ponctuelles | preuve brute requête/réponse pour les anomalies |
| **Git** | traçabilité des corrections | commit par correction, référence `B-xx` dans le message |

Aucun de ces outils n'est imposé par le cahier des charges ; le choix privilégie la cohérence
avec la stack existante (Vite/ESM) et la gratuité. Scripts npm prévus à l'étape 4 :

```
npm run test          # unitaires + intégration
npm run test:unit     # unitaires seuls
npm run test:integration
npm run test:e2e      # Playwright
npm run test:perf     # autocannon sur GET /api/tasks
npm run test:all      # tout, dans l'ordre de la stratégie
```

## 7. Environnement et jeux de données

### 7.1 Environnement

| Élément | Valeur |
|---|---|
| Système | Linux (poste de développement), navigateur Chromium |
| Runtime | Node.js ≥ 18 (le projet utilise `fetch` et le top-level `await`), npm |
| Base | MongoDB locale ; **base de test distincte** `tasktimer_test` |
| Backend | port 3000, `.env` avec `MONGODB_URI` pointant sur la base de test pour les tests |
| Frontend | Vite, port 5173, proxy `/api` → 3000 |
| Version testée | commit initial `TaskTimer_Bugged` (tag `v0-initial`), puis commit(s) de correction |

Règles d'hygiène :

- La base `tasktimer` (démonstration) n'est **jamais** utilisée pour des tests destructifs.
- `MONGODB_URI` de test est passé par variable d'environnement du script de test, jamais
  codé en dur dans les fichiers de test ; aucun secret versionné.
- Les tests d'intégration et E2E sont responsables de leur propre réinitialisation.

### 7.2 Jeux de données

| Jeu | Contenu | Utilisé par |
|---|---|---|
| `J0` | base vide | GET liste vide, premier POST, E2E « liste vide » |
| `J1` | 1 tâche valide (`title: "Préparer le rapport"`, `priority: "medium"`, description fournie) | PUT/DELETE nominaux, affichage |
| `J2` | 3 tâches couvrant low/medium/high | tri/affichage, traduction des priorités (CR-3) |
| `J3` | données invalides : `title` vide, `title` = `"   "`, `priority` = `"urgent"`, `priority` absente, `title` absent, `description` non fournie | validation unitaire, intégration 400, sécurité |
| `J4` | identifiants : `"abc"` (mal formé), ObjectId valide inexistant | 400 et 404 |
| `J5` | JSON tronqué / mal formé (`{"title":`) | 400 sans écriture |
| `J6` | 200 tâches générées (script de seed) | performance TC-P-01 |

Réinitialisation : `drop()` de la collection `tasks` avant chaque test d'intégration et avant
chaque scénario E2E, puis insertion du jeu requis. Un script de seed (`test/fixtures/seed.js`)
produit J1, J2 et J6 de façon déterministe.

## 8. Critères d'entrée et de sortie

### 8.1 Critères d'entrée (avant d'exécuter la campagne)

1. Backend et frontend démarrent sans erreur ; `GET /health` n'existe pas, on vérifie donc
   `GET /api/tasks` → 200.
2. MongoDB accessible et base de test créée, vide.
3. `.env` configuré (sans secret versionné), dépendances installées (`npm ci`).
4. Commit de la version initiale identifié et tagué.
5. Jeux de données reproductibles disponibles.
6. Plan de test validé : chaque cas a un identifiant, des préconditions et un résultat attendu
   non ambigu.

### 8.2 Critères de sortie (fin de campagne)

1. 100 % des cas de test prévus exécutés, y compris ceux qui échouent ; les cas non exécutés
   sont listés avec justification.
2. Tous les cas liés aux risques R1 à R5 ont un résultat et une preuve.
3. Sur la version corrigée : **100 % de réussite** sur les cas de non-régression et sur les
   cas de vérification des anomalies corrigées.
4. Aucune anomalie de gravité bloquante ou élevée ouverte sans décision documentée
   (corrigée, ou non corrigée avec justification et impact).
5. Rapport final et journal complétés ; chaque anomalie reliée à un cas de test et à une preuve.
6. Le socle automatisé s'exécute à partir d'un environnement propre en une commande.

## 9. Priorisation et ordre d'exécution

Ordre retenu, du moins coûteux au plus coûteux et du plus bloquant au plus cosmétique :

1. **Tests unitaires de la validation** (rapides, sans I/O) — révèlent immédiatement R2.
2. **Tests d'intégration API** sur `POST` d'abord (R1), puis erreurs et statuts (R2, R7, R8),
   puis `PUT`/immutabilité des dates (R6), puis `DELETE`.
3. **E2E** : création réussie (R1/R3), création en erreur (R3/R11), modification (R4),
   suppression (R5), puis contrôle visuel CR-3/CR-6 (R9/R10).
4. **Sécurité** (R13) après stabilisation de la validation : comparer l'état de la base avant/après.
5. **Performance** (R12) en dernier, sur une version fonctionnelle et stable, pour que les
   mesures ne soient pas faussées par des erreurs applicatives.

Justification : les tests unitaires coûtent peu et détectent les causes racines ; les tests
d'intégration sécurisent le contrat API dont dépend toute l'interface ; l'E2E valide le
comportement perçu par l'utilisateur ; la performance n'a de sens que sur un système sain.

Chaque exécution est horodatée et conservée (sortie console, rapport, captures) : les résultats
de la version initiale, y compris les échecs, sont des **preuves**, pas des erreurs de test.

## 10. Protocole de performance et de sécurité (seuils fixés avant exécution)

### TC-P-01 — `GET /api/tasks`

| Paramètre | Valeur |
|---|---|
| Jeu de données | J6 — 200 tâches |
| Outil | autocannon, 1 connexion, 20 connexions concurrentes |
| Durée / volume | 20 s, 500 requêtes minimum |
| Environnement | même machine, backend seul (sans navigateur), MongoDB local |
| Seuil fixé **avant** mesure | p95 < 300 ms, taux d'erreur < 1 %, aucune réponse non-200 |

Seuil justifié : une API locale sans requête complexe doit répondre en quelques dizaines de
millisecondes ; 300 ms au 95e centile laisse une marge pour 20 utilisateurs simultanés tout en
détectant une absence d'index ou une fuite de connexions. Limite assumée : mesure mono-machine,
non extrapolable à une production réelle.

### TC-S-01 — entrée invalide

| Paramètre | Valeur |
|---|---|
| Données | J3 + J5, plus tentative d'injection de champ (`createdAt`, `updatedAt`, `_id`, champ inconnu) |
| Procédure | compter les documents et hacher la collection avant, envoyer les requêtes, comparer après |
| Attendu | 400 sur les données invalides, **aucune** écriture, dates serveur non modifiables, aucun détail interne (stack trace) renvoyé |

## 11. Traçabilité

Convention d'identifiants utilisée dans tout le projet :

- `CR-x` : exigence de réception du cahier des charges.
- `R-x` : risque (section 4).
- `B-xx` : anomalie (même identifiant dans l'analyse, les tests, les corrections et le rapport).
- `TC-U-xx` / `TC-I-xx` / `TC-E-xx` / `TC-P-xx` / `TC-S-xx` : cas de test par niveau.
- `P-xx` : preuve (capture, sortie console, rapport de test).

Matrice de traçabilité à tenir à jour (remplie au fil de l'exécution) :

| Exigence | Risques | Anomalies | Cas de test | Résultat initial | Résultat après correction |
|---|---|---|---|---|---|
| CR-1 | R1, R3, R4, R5 | B-01…B-11 | TC-I-01, TC-E-01, TC-E-03, TC-E-04 | à compléter | à compléter |
| CR-2 | R2, R11 | B-02, B-03, B-04 | TC-U-01…06, TC-I-02, TC-I-03 | à compléter | à compléter |
| CR-3 | R9 | B-12 | TC-E-05 | à compléter | à compléter |
| CR-4 | R3, R11 | B-11 | TC-E-02 | à compléter | à compléter |
| CR-5 | R6 | B-05 | TC-I-05, TC-I-06 | à compléter | à compléter |
| CR-6 | R10 | B-13 | TC-E-05 | à compléter | à compléter |
| Contrat API (400/404/500) | R7, R8, R13 | B-06, B-07, B-08 | TC-I-07…10, TC-S-01 | à compléter | à compléter |
| Performance | R12 | — | TC-P-01 | à compléter | à compléter |

## 12. Risques du projet de test

| Risque projet | Mitigation |
|---|---|
| MongoDB indisponible sur le poste | mongodb-memory-server en repli, difficulté documentée (ENV3/ENV5) |
| Base de démonstration polluée par les tests | base `tasktimer_test` dédiée + réinitialisation systématique |
| B-01 bloquant : impossible de créer une tâche pour tester `PUT`/`DELETE` nominaux | insertion directe via le seed pour les cas dépendants, consigné comme précondition |
| Tests E2E instables (attentes réseau) | attentes sur état visible, pas de `sleep` fixe ; base réinitialisée par scénario |
| Confusion entre couverture et qualité | la couverture est reportée comme indicateur brut, accompagnée de ses limites |
| Correction d'une anomalie qui en masque une autre | non-régression complète après chaque correction |
