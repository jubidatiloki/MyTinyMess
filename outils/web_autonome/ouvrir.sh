#!/bin/sh
# My Tiny Mess - ouverture de la version web sur Mac ou Linux.
# Utilise Python 3 (déjà présent sur Mac et sur la plupart des Linux).
# Lancement : dans un terminal, « sh ouvrir.sh ».
PORT=8095
cd "$(dirname "$0")/app" || exit 1
echo ""
echo "  === My Tiny Mess ==="
echo "  Application ouverte dans le navigateur : http://localhost:$PORT/"
echo "  Laissez ce terminal ouvert ; Ctrl+C pour arrêter."
echo ""
(
  sleep 1
  if command -v open >/dev/null 2>&1; then
    open "http://localhost:$PORT/"
  elif command -v xdg-open >/dev/null 2>&1; then
    xdg-open "http://localhost:$PORT/"
  fi
) &
if command -v python3 >/dev/null 2>&1; then
  python3 -m http.server "$PORT" --bind 127.0.0.1
else
  python -m http.server "$PORT" --bind 127.0.0.1
fi
