@echo off
:: One-click post-export script for Nicepage + GitHub Pages
:: Steps:
:: 1. Restructure .html files into subfolders with index.html
:: 2. Rewrite asset references to absolute root paths
:: 3. Rewrite internal .html links to pretty URLs

echo === Step 1: Restructuring pages into subfolders ===

for /R %%f in (*.html) do (
    if /I not "%%~nxf"=="index.html" (
        set "filepath=%%~dpf"
        set "filename=%%~nf"
        call :process "%%f" "%%~dpf" "%%~nf"
    )
)

echo === Step 2 & 3: Fixing asset references and internal links ===

for /R %%f in (*.html) do (
    echo Processing %%f...
    powershell -Command "(Get-Content -Raw '%%f') -replace 'href\s*=\s*\"(css/.*?)\"', 'href=\"/$1\"' | Set-Content '%%f'"
    powershell -Command "(Get-Content -Raw '%%f') -replace 'src\s*=\s*\"(js/.*?)\"', 'src=\"/$1\"' | Set-Content '%%f'"
    powershell -Command "(Get-Content -Raw '%%f') -replace 'src\s*=\s*\"(images/.*?)\"', 'src=\"/$1\"' | Set-Content '%%f'"
    powershell -Command "(Get-Content -Raw '%%f') -replace 'src\s*=\s*\"(assets/.*?)\"', 'src=\"/$1\"' | Set-Content '%%f'"
    powershell -Command "(Get-Content -Raw '%%f') -replace '([A-Za-z0-9_-]+)\.html', '$1/' | Set-Content '%%f'"
)

echo === Done! Your site is ready to push. ===
pause
exit /b

:process
set "fullfile=%~1"
set "path=%~2"
set "name=%~3"

if not exist "%path%%name%" (
    mkdir "%path%%name%"
)

move "%fullfile%" "%path%%name%\index.html" >nul
exit /b
