@echo off
chcp 65001 >nul
REM Lance l'application My Tiny Mess directement dans le navigateur (Chrome),
REM sur http://localhost:8081.
REM Le port reste fixe : le navigateur garde ainsi les donnees saisies.
REM Autres cibles possibles : "lancer.bat windows" ou "lancer.bat android".
cd /d "%~dp0"
where flutter >nul 2>nul || set "PATH=C:\Users\benja\Documents\flutter\bin;%PATH%"

echo.
echo  === My Tiny Mess ===
echo  Pendant que l'application tourne : r = recharger, R = redemarrer, q = quitter.
echo.

call flutter pub get
if /i "%~1"=="windows" (
  call flutter run -d windows
) else if /i "%~1"=="android" (
  call flutter run -d android
) else (
  call flutter run -d chrome --web-port 8081
)
pause
