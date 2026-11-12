#!/usr/bin/env bash
# Hook « Stop » de Claude Code : à la fin de chaque tour de Claude,
# lance flutter analyze + flutter test si du code Dart a changé.
# En cas d'échec, sort avec le code 2 : Claude reçoit l'erreur et doit corriger.

cd "$(dirname "$0")/.." || exit 0
export PATH="/c/Users/benja/Documents/flutter/bin:$PATH"

entree=$(cat)
temoin=.dart_tool/derniere_verification

# Rien à faire si aucun fichier Dart / pubspec n'a changé depuis la dernière vérification réussie.
if [ -f "$temoin" ] && [ -z "$(find lib test pubspec.yaml -newer "$temoin" \( -name '*.dart' -o -name 'pubspec.yaml' \) 2>/dev/null | head -1)" ]; then
  exit 0
fi

sortie=$( { flutter analyze --no-pub && flutter test --no-pub; } 2>&1 )
if [ $? -eq 0 ]; then
  mkdir -p .dart_tool && touch "$temoin"
  exit 0
fi

# Évite une boucle sans fin : un seul nouvel essai imposé par tour.
if echo "$entree" | grep -q '"stop_hook_active": *true'; then
  echo "Vérification toujours en échec (voir verifier.bat)." >&2
  exit 0
fi

{
  echo "flutter analyze / flutter test en échec, corrige avant de terminer :"
  echo "$sortie" | grep -E "error|warning|info -|\[E\]|Expected|Actual|Some tests failed|EXCEPTION" | head -40
} >&2
exit 2
