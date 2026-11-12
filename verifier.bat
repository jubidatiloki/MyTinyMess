@echo off
chcp 65001 >nul
REM Analyse du code + tests automatiques. Résultat complet dans verification.log.
cd /d "%~dp0"
where flutter >nul 2>nul || set "PATH=C:\Users\benja\Documents\flutter\bin;%PATH%"

echo Verification en cours...
(
  echo === flutter analyze ===
  call flutter analyze
  echo.
  echo === flutter test ===
  call flutter test
) > verification.log 2>&1

findstr /C:"Some tests failed" /C:" error - " verification.log >nul
if %errorlevel%==0 (
  echo.
  echo  [ECHEC] Des erreurs ont ete trouvees : voir verification.log
) else (
  echo.
  echo  [OK] Analyse sans erreur et tous les tests passent.
)
pause
