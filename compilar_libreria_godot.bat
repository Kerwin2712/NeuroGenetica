@echo off
echo ============================================================
echo   Compilando Nucleo C++ para Godot Engine (GDExtension)
echo ============================================================
cd /d "%~dp0"

if not exist "godot-cpp\gdextension\extension_api.json" (
    echo.
    echo Clonando bindings oficiales godot-cpp...
    git clone --depth 1 -b 4.3 https://github.com/godotengine/godot-cpp.git godot-cpp
)

scons platform=windows target=template_debug -j6
if %ERRORLEVEL% EQU 0 (
    echo.
    echo ============================================================
    echo   [EXITO] Libreria compilada correctamente en godot_project/bin/
    echo ============================================================
) else (
    echo.
    echo   [ERROR] Hubo un error durante la compilacion.
)
pause
