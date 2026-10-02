#include "Simulation.hpp"

Simulation::Simulation(int width, int height, const std::string& title)
    : screenWidth(width),
      screenHeight(height),
      windowTitle(title),
      track(),
      playerCar({ 360.0f, 420.0f }, 0.0f, ControlMode::Manual),
      hud(),
      showQuadTreeDebug(false)
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, windowTitle.c_str());
    SetTargetFPS(60);

    int monitor = GetCurrentMonitor();
    int monitorW = GetMonitorWidth(monitor);
    int monitorH = GetMonitorHeight(monitor);
    SetWindowPosition((monitorW - screenWidth) / 2, (monitorH - screenHeight) / 2 - 30);

    // Lectura inicial de sensores
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
    // 1. Alternar pantalla completa con F11 o Alt+Enter
    if (IsKeyPressed(KEY_F11) || (IsKeyDown(KEY_LEFT_ALT) && IsKeyPressed(KEY_ENTER))) {
        ToggleFullscreen();
    }

    // 2. Alternar entre Modo Manual y Modo Autónomo (Red Neuronal) con la tecla 'M'
    if (IsKeyPressed(KEY_M)) {
        if (playerCar.GetControlMode() == ControlMode::Manual) {
            playerCar.SetControlMode(ControlMode::Autonomous);
        } else {
            playerCar.SetControlMode(ControlMode::Manual);
        }
    }

    // 3. Generar una Red Neuronal con pesos aleatorios para experimentar (tecla 'N')
    if (IsKeyPressed(KEY_N)) {
        playerCar.GetBrain().RandomizeWeights(-1.5f, 1.5f);
    }

    // 4. Restaurar Red Neuronal con pesos calibrados de navegación (tecla 'B')
    if (IsKeyPressed(KEY_B)) {
        playerCar.GetBrain().InitializeHeuristicWeights();
    }

    // 5. Alternar visualización del QuadTree con la tecla 'Q'
    if (IsKeyPressed(KEY_Q)) {
        showQuadTreeDebug = !showQuadTreeDebug;
    }

    // 6. Reiniciar vehículo con tecla 'R'
    if (IsKeyPressed(KEY_R)) {
        playerCar.Reset({ 360.0f, 420.0f }, 0.0f);
    }

    // 7. Raycasting acelerado mediante el QuadTree O(log n)
    playerCar.CastSensors(track.GetQuadTree());

    // 8. Actualización del vehículo (manual por teclado o autónoma por red neuronal)
    playerCar.Update();

    // 9. Detección de colisión contra los muros de la pista
    playerCar.CheckCollision(track.GetQuadTree());
}

void Simulation::Render() {
    BeginDrawing();

    // 1. Dibujar pista y fondo
    track.Draw();

    // 2. Modo depuración de cuadrantes del QuadTree
    if (showQuadTreeDebug) {
        track.DrawDebugQuadTree();
    }

    // 3. Dibujar vehículo y sensores
    playerCar.Draw();

    // 4. Dibujar telemetría y selector de modo en el HUD
    hud.Draw(playerCar, track, showQuadTreeDebug);

    EndDrawing();
}
