#!/usr/bin/env bash
# TaskTimer – démarre MongoDB (local, si nécessaire), le backend (API) et le frontend (Vite)
# en une seule commande.
#
#   ./start.sh                # installe les dépendances au premier lancement si nécessaire
#   SKIP_INSTALL=1 ./start.sh # ne pas lancer npm install
#   KEEP_MONGO=1 ./start.sh   # laisser MongoDB tourner après Ctrl+C
#   PORT=3001 WEB_PORT=5174 ./start.sh
#
# Ctrl+C arrête les trois processus (MongoDB seulement s'il a été lancé par ce script).
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKEND_DIR="$ROOT/backend"
FRONTEND_DIR="$ROOT/frontend"
MONGO_BIN="$ROOT/.tools/mongodb/bin/mongod"
MONGO_DATA="$ROOT/.data/mongo"
MONGO_LOG="$MONGO_DATA/mongod.log"
MONGO_PIDFILE="$MONGO_DATA/mongod.pid"
API_PORT="${PORT:-3000}"
WEB_PORT="${WEB_PORT:-5173}"
MONGO_PORT="${MONGO_PORT:-27017}"

info() { printf '\033[36m[start]\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[start]\033[0m %s\n' "$*"; }
fail() { printf '\033[31m[start]\033[0m %s\n' "$*" >&2; exit 1; }

# --- Prérequis ---------------------------------------------------------------
command -v node >/dev/null 2>&1 || fail "Node.js est introuvable dans le PATH."
command -v npm >/dev/null 2>&1 || fail "npm est introuvable dans le PATH."
if ! node -e 'process.exit(Number(process.versions.node.split(".")[0]) >= 18 ? 0 : 1)'; then
  warn "Node.js 18+ est recommandé (version détectée : $(node -v))."
fi

[ -d "$BACKEND_DIR" ] || fail "Dossier backend introuvable : $BACKEND_DIR"
[ -d "$FRONTEND_DIR" ] || fail "Dossier frontend introuvable : $FRONTEND_DIR"

port_open() { (exec 3<>"/dev/tcp/127.0.0.1/$1") >/dev/null 2>&1; }

# --- Installation ------------------------------------------------------------
if [ "${SKIP_INSTALL:-0}" != "1" ]; then
  if [ ! -d "$BACKEND_DIR/node_modules" ]; then
    info "Installation des dépendances du backend…"
    (cd "$BACKEND_DIR" && npm install --no-audit --no-fund)
  fi
  if [ ! -d "$FRONTEND_DIR/node_modules" ]; then
    info "Installation des dépendances du frontend…"
    (cd "$FRONTEND_DIR" && npm install --no-audit --no-fund)
  fi
fi

if [ ! -f "$BACKEND_DIR/.env" ] && [ -f "$BACKEND_DIR/.env.example" ]; then
  info "Création de backend/.env à partir de .env.example"
  cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
fi

for p in "$API_PORT" "$WEB_PORT"; do
  if port_open "$p"; then
    fail "Le port $p est déjà utilisé. Arrête le processus, ou lance : PORT/$WEB_PORT différent."
  fi
done

# --- Arrêt propre ------------------------------------------------------------
BACKEND_PID=""
FRONTEND_PID=""
MONGO_STARTED=0

kill_tree() {
  local pid="$1" child
  [ -z "$pid" ] && return 0
  if command -v pgrep >/dev/null 2>&1; then
    for child in $(pgrep -P "$pid" 2>/dev/null || true); do
      kill_tree "$child"
    done
  fi
  kill -TERM "$pid" 2>/dev/null || true
}

cleanup() {
  trap - EXIT INT TERM
  info "Arrêt du frontend et du backend…"
  kill_tree "$FRONTEND_PID"
  kill_tree "$BACKEND_PID"
  if [ "$MONGO_STARTED" = "1" ] && [ "${KEEP_MONGO:-0}" != "1" ]; then
    info "Arrêt du MongoDB local démarré par ce script…"
    kill -TERM "$(cat "$MONGO_PIDFILE" 2>/dev/null)" 2>/dev/null || true
  elif [ "$MONGO_STARTED" = "1" ]; then
    info "MongoDB local laissé en marche (KEEP_MONGO=1)."
  fi
  wait 2>/dev/null || true
}
trap cleanup EXIT INT TERM

# --- MongoDB ----------------------------------------------------------------
if ! port_open "$MONGO_PORT"; then
  if [ -x "$MONGO_BIN" ]; then
    info "Démarrage du MongoDB local (.tools/mongodb) sur 127.0.0.1:$MONGO_PORT"
    mkdir -p "$MONGO_DATA"
    MONGO_STARTED=1
    if ! "$MONGO_BIN" --dbpath "$MONGO_DATA" --logpath "$MONGO_LOG" \
        --pidfilepath "$MONGO_PIDFILE" --port "$MONGO_PORT" --bind_ip 127.0.0.1 --fork >/dev/null 2>&1; then
      MONGO_STARTED=0
      warn "Échec du démarrage de MongoDB local — voir $MONGO_LOG"
    fi
    for _ in $(seq 1 40); do
      port_open "$MONGO_PORT" && break
      sleep 0.25
    done
    port_open "$MONGO_PORT" || warn "MongoDB n'écoute toujours pas sur le port $MONGO_PORT."
  else
    warn "Aucun MongoDB détecté sur 127.0.0.1:$MONGO_PORT et aucun binaire local dans .tools/mongodb."
    warn "L'API échouera à se connecter tant que MongoDB n'est pas démarré."
  fi
fi

# --- Backend ----------------------------------------------------------------
info "Démarrage du backend sur http://localhost:$API_PORT"
(cd "$BACKEND_DIR" && exec npm run dev) &
BACKEND_PID=$!

for _ in $(seq 1 60); do
  port_open "$API_PORT" && break
  if ! kill -0 "$BACKEND_PID" 2>/dev/null; then
    fail "Le backend s'est arrêté avant d'ouvrir le port $API_PORT (voir les erreurs ci-dessus, souvent MongoDB)."
  fi
  sleep 0.5
done
port_open "$API_PORT" || fail "Le backend n'a pas ouvert le port $API_PORT après 30 s."

# --- Frontend ---------------------------------------------------------------
info "Démarrage du frontend sur http://localhost:$WEB_PORT"
(cd "$FRONTEND_DIR" && exec npm run dev -- --port "$WEB_PORT" --strictPort) &
FRONTEND_PID=$!

info "Tout est lancé."
info "  MongoDB   : mongodb://127.0.0.1:$MONGO_PORT/tasktimer"
info "  API       : http://localhost:$API_PORT/api/tasks"
info "  Interface : http://localhost:$WEB_PORT"
info "Ctrl+C pour tout arrêter."

# On sort dès que l'un des serveurs s'arrête (cleanup arrête les autres).
if [ "${BASH_VERSINFO[0]:-0}" -gt 4 ] ||
   { [ "${BASH_VERSINFO[0]:-0}" -eq 4 ] && [ "${BASH_VERSINFO[1]:-0}" -ge 3 ]; }; then
  wait -n "$BACKEND_PID" "$FRONTEND_PID" || true
else
  wait "$BACKEND_PID" || true
fi
