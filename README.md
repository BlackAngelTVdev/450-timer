# TaskTimer – Version buggée (version étudiants)

## Démarrage en une commande

```bash
./start.sh
```

- API : http://localhost:3000/api/tasks — Interface : http://localhost:5173
- Le script installe les dépendances au premier lancement (`node_modules` manquant),
  crée `backend/.env` depuis `.env.example`, démarre le backend, attend qu'il écoute,
  puis démarre le frontend. `Ctrl+C` arrête les deux.
- Prérequis : Node.js 18+, npm, et un MongoDB local sur `127.0.0.1:27017`.
- Options : `SKIP_INSTALL=1 ./start.sh` (pas d'installation), `PORT=3001 WEB_PORT=5174 ./start.sh`.

## Démarrage manuel (deux terminaux)

Backend -> cd backend ; copy .env.example .env ; npm i ; npm run dev
Frontend -> cd frontend ; npm i ; npm run dev
