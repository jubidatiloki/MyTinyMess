@echo off
chcp 65001 >nul
REM Construit la livraison dans le dossier "livraison" :
REM  - my_tiny_mess_X.Y.Z.apk      (Android)
REM  - my_tiny_mess_web_X.Y.Z.zip  (version web autonome, n'importe quel ordinateur)
cd /d "%~dp0"
where flutter >nul 2>nul || set "PATH=C:\Users\benja\Documents\flutter\bin;%PATH%"
call flutter config --jdk-dir="C:\Program Files\Eclipse Adoptium\jdk-17.0.18.8-hotspot" >nul

for /f "tokens=2" %%v in ('findstr /b "version:" pubspec.yaml') do set VERSION=%%v
set SORTIE=%~dp0livraison
if not exist "%SORTIE%" mkdir "%SORTIE%"
echo === Livraison de My Tiny Mess %VERSION% ===

echo.
echo --- Verification (analyse + tests) ---
call flutter analyze || goto erreur
call flutter test || goto erreur

echo.
echo --- APK Android ---
call flutter build apk --release || goto erreur
copy /y "build\app\outputs\flutter-apk\app-release.apk" "%SORTIE%\my_tiny_mess_%VERSION%.apk" >nul || goto erreur

echo.
echo --- Version web autonome ---
call flutter build web --release || goto erreur
set NOM=my_tiny_mess_web_%VERSION%
set DOSSIER=%SORTIE%\%NOM%
if exist "%DOSSIER%" rmdir /s /q "%DOSSIER%"
xcopy /e /i /q "build\web" "%DOSSIER%\app" >nul || goto erreur
mkdir "%DOSSIER%\outils"
copy /y "outils\web_autonome\servir.ps1" "%DOSSIER%\outils\" >nul
copy /y "outils\web_autonome\Ouvrir My Tiny Mess.bat" "%DOSSIER%\" >nul
copy /y "outils\web_autonome\ouvrir.sh" "%DOSSIER%\" >nul
copy /y "outils\web_autonome\LISEZMOI.txt" "%DOSSIER%\" >nul
if exist "%SORTIE%\%NOM%.zip" del "%SORTIE%\%NOM%.zip"
REM tar (fourni avec Windows 10/11) produit un zip lisible sur Mac et Linux.
tar -a -c -f "%SORTIE%\%NOM%.zip" -C "%SORTIE%" "%NOM%" || goto erreur

echo.
echo [OK] Livraison prete dans %SORTIE%
goto fin

:erreur
echo.
echo [ECHEC] La livraison n'a pas pu etre construite (voir les messages ci-dessus).

:fin
if "%~1"=="" pause
