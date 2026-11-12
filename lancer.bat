@echo off
chcp 65001 >nul
REM Lance l'application My Tiny Mess.
cd /d "%~dp0"
where flutter >nul 2>nul || set "PATH=C:\Users\benja\Documents\flutter\bin;%PATH%"

echo.
echo  === My Tiny Mess ===
echo   1. Navigateur (Chrome) - http://localhost:8081
echo   2. Application Windows
echo   3. Telephone Android branche en USB
echo.
set /p choix="Votre choix (1, 2 ou 3, Entree = 1) : "
if "%choix%"=="" set choix=1

call flutter pub get
if "%choix%"=="1" call flutter run -d chrome --web-port 8081
if "%choix%"=="2" call flutter run -d windows
if "%choix%"=="3" call flutter run -d android
echo.
echo Pendant que l'application tourne : r = recharger, R = redemarrer, q = quitter.
pause
