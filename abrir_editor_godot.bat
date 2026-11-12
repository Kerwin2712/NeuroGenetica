@echo off
setlocal enabledelayedexpansion

echo ============================================================
echo   Abriendo Editor de Godot Engine para NeuroGenetica
echo ============================================================

set "GODOT_CMD="

:: 1. Comprobar si 'godot' esta en el PATH
where godot >nul 2>nul
if !ERRORLEVEL! EQU 0 (
    set "GODOT_CMD=godot"
    goto :FOUND
)

:: 2. Comprobar ruta habitual de Winget
if exist "%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe" (
    set "GODOT_CMD=%LOCALAPPDATA%\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\Godot_v4.7.2-stable_win64.exe"
    goto :FOUND
)

:: 3. Buscar cualquier ejecutable de Godot
for /f "delims=" %%i in ('dir /b /s "%LOCALAPPDATA%\Microsoft\WinGet\Packages\*godot*.exe" 2^>nul ^| findstr /v "console"') do (
    set "GODOT_CMD=%%i"
    goto :FOUND
)

echo.
echo [AVISO] No se encontro Godot Engine 4 en tu sistema.
echo.
echo Para abrir el proyecto en el editor, instala Godot ejecutando:
echo   winget install GodotEngine.GodotEngine
echo O descargalo desde: https://godotengine.org/download
echo.
pause
exit /b 1

:FOUND
echo Abriendo editor con: !GODOT_CMD!
start "" "!GODOT_CMD!" --path "%~dp0godot_project" -e
