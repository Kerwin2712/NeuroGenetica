#include "Simulation.hpp"

Simulation::Simulation(int width, int height, const std::string& title)
    : screenWidth(width),
      screenHeight(height),
      windowTitle(title),
      track(),
      playerCar({ 360.0f, 420.0f }, 0.0f),
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

    // Calcular lecturas iniciales de los sensores usando el QuadTree
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
    // Alternar pantalla completa con F11 o Alt+Enter
    if (IsKeyPressed(KEY_F11) || (IsKeyDown(KEY_LEFT_ALT) && IsKeyPressed(KEY_ENTER))) {
        ToggleFullscreen();
    }

    // Alternar visualización del QuadTree con la tecla 'Q'
    if (IsKeyPressed(KEY_Q)) {
        showQuadTreeDebug = !showQuadTreeDebug;
    }

    // Reiniciar vehículo con tecla 'R'
    if (IsKeyPressed(KEY_R)) {
        playerCar.Reset({ 360.0f, 420.0f }, 0.0f);
    }

    // 1. Cinemática manual
    playerCar.UpdateManual();

    // 2. Raycasting acelerado mediante consultas en el QuadTree O(log n)
    playerCar.CastSensors(track.GetQuadTree());

    // 3. Verificación de colisión acelerada mediante caja delimitadora en QuadTree
    playerCar.CheckCollision(track.GetQuadTree());
}

void Simulation::Render() {
    BeginDrawing();

    // 1. Dibujar fondo y circuito
    track.Draw();

    // 2. Si está activo el modo debug, dibujar cuadrantes del QuadTree
    if (showQuadTreeDebug) {
        track.DrawDebugQuadTree();
    }

    // 3. Dibujar vehículo, rayos sensores y puntos de impacto
    playerCar.Draw();

    // 4. Dibujar interfaz / telemetría con métricas del QuadTree
    hud.Draw(playerCar, track, showQuadTreeDebug);

    EndDrawing();
}
