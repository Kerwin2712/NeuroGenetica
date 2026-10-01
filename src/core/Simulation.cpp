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

    // Actualización del vehículo
    playerCar.UpdateManual();
}

void Simulation::Render() {
    BeginDrawing();

    // 1. Dibujar fondo y circuito
    track.Draw();

    // 2. Dibujar vehículo y sensores
    playerCar.Draw();

    // 3. Dibujar interfaz / telemetría
    hud.Draw(playerCar);

    EndDrawing();
}
