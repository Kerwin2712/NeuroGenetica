#include "Simulation.hpp"

Simulation::Simulation(int width, int height, const std::string& title)
    : screenWidth(width),
      screenHeight(height),
      windowTitle(title),
      track(),
      playerCar({ 360.0f, 420.0f }, 0.0f, ControlMode::Manual),
      geneticAlgorithm(40, 0.10f, 0.30f),
      hud(),
      isGeneticMode(true), // Iniciar por defecto en entrenamiento masivo de IA
      showQuadTreeDebug(false),
      simSpeed(1)
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, windowTitle.c_str());
    SetTargetFPS(60);

    int monitor = GetCurrentMonitor();
    int monitorW = GetMonitorWidth(monitor);
    int monitorH = GetMonitorHeight(monitor);
    SetWindowPosition((monitorW - screenWidth) / 2, (monitorH - screenHeight) / 2 - 30);

    playerCar.CastSensors(track.GetQuadTree());
}

Simulation::~Simulation() {
    CloseWindow();
}

void Simulation::Run() {
    while (!WindowShouldClose()) {
        Update();
        Render();
    }
}

void Simulation::Update() {
    float dt = GetFrameTime();
    // Limitar delta time para evitar saltos si hay micro-pausas
    if (dt > 0.05f) dt = 0.016f;

    // 1. Pantalla completa con F11 o Alt+Enter
    if (IsKeyPressed(KEY_F11) || (IsKeyDown(KEY_LEFT_ALT) && IsKeyPressed(KEY_ENTER))) {
        ToggleFullscreen();
    }

    // 2. Alternar entre Modo Manual y Modo Entrenamiento Genético con la tecla 'M'
    if (IsKeyPressed(KEY_M)) {
        isGeneticMode = !isGeneticMode;
        if (!isGeneticMode) {
            playerCar.Reset({ 360.0f, 420.0f }, 0.0f);
            playerCar.SetControlMode(ControlMode::Manual);
        }
    }

    // 3. Acelerar simulación (1x -> 2x -> 5x) con la barra espaciadora
    if (IsKeyPressed(KEY_SPACE)) {
        if (simSpeed == 1) simSpeed = 2;
        else if (simSpeed == 2) simSpeed = 5;
        else simSpeed = 1;
    }

    // 4. Tecla 'R': Reiniciar o forzar siguiente generación
    if (IsKeyPressed(KEY_R)) {
        if (isGeneticMode) {
            geneticAlgorithm.EvolveNextGeneration();
        } else {
            playerCar.Reset({ 360.0f, 420.0f }, 0.0f);
        }
    }

    // 5. Tecla 'N': Reiniciar población a Generación 1 con cerebros 100% nuevos
    if (IsKeyPressed(KEY_N)) {
        if (isGeneticMode) {
            geneticAlgorithm.ResetPopulation();
        } else {
            playerCar.GetBrain().RandomizeWeights(-1.5f, 1.5f);
        }
    }

    // 6. Alternar visualización del QuadTree con la tecla 'Q'
    if (IsKeyPressed(KEY_Q)) {
        showQuadTreeDebug = !showQuadTreeDebug;
    }

    // 7. Lógica de actualización según modo activo
    if (isGeneticMode) {
        // En modo genético masivo, ejecutar según la velocidad seleccionada (simSpeed pasos de física)
        for (int step = 0; step < simSpeed; ++step) {
            geneticAlgorithm.Update(track, dt);
        }
    } else {
        // En modo manual individual
        playerCar.CastSensors(track.GetQuadTree());
        playerCar.Update();
        playerCar.CheckCheckpoints(track.GetCheckpoints(), dt);
        playerCar.CheckCollision(track.GetQuadTree());
    }
}

void Simulation::Render() {
    BeginDrawing();

    // 1. Dibujar pista y fondo
    track.Draw();

    // 2. Modo depuración de cuadrantes del QuadTree
    if (showQuadTreeDebug) {
        track.DrawDebugQuadTree();
    }

    // 3. Dibujar vehículos según el modo
    if (isGeneticMode) {
        geneticAlgorithm.Draw();
    } else {
        playerCar.Draw();
    }

    // 4. Dibujar telemetría y controles en el HUD
    hud.Draw(playerCar, geneticAlgorithm, isGeneticMode, track, showQuadTreeDebug, simSpeed);

    EndDrawing();
}
