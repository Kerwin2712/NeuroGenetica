#include "Simulation.hpp"

Simulation::Simulation(int width, int height, const std::string& title)
    : screenWidth(width),
      screenHeight(height),
      windowTitle(title),
      track(),
      playerCar({ 360.0f, 420.0f }, 0.0f),
      hud()
{
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, windowTitle.c_str());
    SetTargetFPS(60);

    // Centrar la ventana en la pantalla del monitor
    int monitor = GetCurrentMonitor();
    int monitorW = GetMonitorWidth(monitor);
    int monitorH = GetMonitorHeight(monitor);
    SetWindowPosition((monitorW - screenWidth) / 2, (monitorH - screenHeight) / 2 - 30);

    // Calcular lecturas iniciales de los sensores
    playerCar.CastSensors(track.GetWalls());
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

    // Reiniciar vehículo con tecla 'R'
    if (IsKeyPressed(KEY_R)) {
        playerCar.Reset({ 360.0f, 420.0f }, 0.0f);
    }

    // 1. Actualización de movimiento cinemático manual
    playerCar.UpdateManual();

    // 2. Proyección de sensores y detección geométrica de extremos de la carretera
    playerCar.CastSensors(track.GetWalls());

    // 3. Verificación de colisión contra los muros
    playerCar.CheckCollision(track.GetWalls());
}

void Simulation::Render() {
    BeginDrawing();

    // 1. Dibujar fondo y circuito con bordes
    track.Draw();

    // 2. Dibujar vehículo, rayos sensores y puntos de impacto
    playerCar.Draw();

    // 3. Dibujar interfaz / telemetría
    hud.Draw(playerCar);

    EndDrawing();
}
