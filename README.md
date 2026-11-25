# TaskTimer – Version buggée (version étudiants)

Dépôt : https://github.com/BlackAngelTVdev/450-timer

## Démarrage en une commande

```bash
./start.sh
```

- MongoDB : `mongodb://127.0.0.1:27017/tasktimer` — API : http://localhost:3000/api/tasks — Interface : http://localhost:5173
- Le script installe les dépendances au premier lancement (`node_modules` manquant),
  crée `backend/.env` depuis `.env.example`, démarre MongoDB local s'il ne répond pas,
  attend que l'API écoute, puis démarre le frontend. `Ctrl+C` arrête tout.
- Prérequis : Node.js 18+ et npm. MongoDB n'a pas besoin d'être installé sur le système :
  un binaire local 7.0.14 est fourni dans `.tools/mongodb` (non versionné), avec ses données
  dans `.data/mongo`.
- Options : `SKIP_INSTALL=1 ./start.sh` (pas d'installation), `KEEP_MONGO=1 ./start.sh`
  (laisser MongoDB tourner après `Ctrl+C`), `PORT=3001 WEB_PORT=5174 ./start.sh` (autres ports).

## Démarrage manuel (deux terminaux)

Backend -> cd backend ; copy .env.example .env ; npm i ; npm run dev
Frontend -> cd frontend ; npm i ; npm run dev

## Documentation du projet

- `TESTING.md` — concept et stratégie de test (périmètre, risques, outils, critères d'entrée/sortie).
- `STEP.md` — plan de travail suivi : étapes 0 à 5 du cahier des charges, à cocher.
