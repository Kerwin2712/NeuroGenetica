#include "raylib.h"
#include <cmath>
#include <vector>
#include <string>

// Estructura simple para el vehículo en Fase 1 (Prototipo con rectángulo)
struct CarPrototype {
    Vector2 position = { 360.0f, 420.0f }; // En la recta inferior
    float angle = 0.0f;                    // En grados (0 hacia la derecha)
    float speed = 0.0f;
    float maxSpeed = 4.5f;
    float acceleration = 0.12f;
    float friction = 0.96f;
    float turnSpeed = 3.2f;

    // Dimensiones del rectángulo
    float width = 30.0f;
    float height = 15.0f;
    Color color = RED;

    void Update() {
        // Controles manuales para probar física en Fase 1
        if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) {
            speed += acceleration;
            if (speed > maxSpeed) speed = maxSpeed;
        }
        if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) {
            speed -= acceleration * 0.8f;
            if (speed < -maxSpeed * 0.4f) speed = -maxSpeed * 0.4f;
        }

        // Girar solo si el auto se está moviendo
        if (std::abs(speed) > 0.05f) {
            float direction = (speed > 0) ? 1.0f : -1.0f;
            if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))  angle -= turnSpeed * direction;
            if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) angle += turnSpeed * direction;
        }

        // Fricción
        speed *= friction;

        // Actualizar posición cinemática
        float rad = angle * DEG2RAD;
        position.x += std::cos(rad) * speed;
        position.y += std::sin(rad) * speed;
    }

    void Draw() const {
        // Dibujar auto como rectángulo rotado
        Rectangle rect = { position.x, position.y, width, height };
        Vector2 origin = { width / 2.0f, height / 2.0f };
        DrawRectanglePro(rect, origin, angle, color);

        // Indicador de frente del auto (faros amarillos)
        float rad = angle * DEG2RAD;
        Vector2 frontRight = {
            position.x + std::cos(rad) * (width / 2.0f) - std::sin(rad) * (height / 3.0f),
            position.y + std::sin(rad) * (width / 2.0f) + std::cos(rad) * (height / 3.0f)
        };
        Vector2 frontLeft = {
            position.x + std::cos(rad) * (width / 2.0f) + std::sin(rad) * (height / 3.0f),
            position.y + std::sin(rad) * (width / 2.0f) - std::cos(rad) * (height / 3.0f)
        };
        DrawCircleV(frontRight, 2.5f, YELLOW);
        DrawCircleV(frontLeft, 2.5f, YELLOW);

        // Simulación visual de 5 rayos sensores (Fase 2 se conectará con el QuadTree)
        const float sensorLength = 75.0f;
        const float sensorAngles[] = { -60.0f, -30.0f, 0.0f, 30.0f, 60.0f };

        for (float sAngle : sensorAngles) {
            float totalRad = (angle + sAngle) * DEG2RAD;
            Vector2 endPoint = {
                position.x + std::cos(totalRad) * sensorLength,
                position.y + std::sin(totalRad) * sensorLength
            };
            DrawLineV(position, endPoint, Fade(SKYBLUE, 0.6f));
            DrawCircleV(endPoint, 2.5f, Fade(RED, 0.8f));
        }
    }
};

int main() {
    // Dimensiones óptimas para pantallas estándar (1366x768 o superiores)
    const int screenWidth = 960;
    const int screenHeight = 540;

    // Permitir redimensionar ventana y suavizado de bordes
    SetConfigFlags(FLAG_WINDOW_RESIZABLE | FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, "NeuroGenetica - Simulacion Base [Fase 1]");
    SetTargetFPS(60);

    // Centrar la ventana en la pantalla del monitor
    int monitor = GetCurrentMonitor();
    int monitorW = GetMonitorWidth(monitor);
    int monitorH = GetMonitorHeight(monitor);
    SetWindowPosition((monitorW - screenWidth) / 2, (monitorH - screenHeight) / 2 - 30);

    CarPrototype playerCar;

    while (!WindowShouldClose()) {
        // Soporte para alternar pantalla completa con F11 o Alt+Enter
        if (IsKeyPressed(KEY_F11) || (IsKeyDown(KEY_LEFT_ALT) && IsKeyPressed(KEY_ENTER))) {
            ToggleFullscreen();
        }

        // --- Actualización ---
        playerCar.Update();

        // --- Renderizado ---
        BeginDrawing();
        ClearBackground(Color{ 34, 139, 34, 255 }); // Césped exterior

        // Circuito centrado para resolución 960x540
        DrawRing(Vector2{ 300.0f, 270.0f }, 100.0f, 200.0f, 90.0f, 270.0f, 36, DARKGRAY);
        DrawRing(Vector2{ 660.0f, 270.0f }, 100.0f, 200.0f, 270.0f, 450.0f, 36, DARKGRAY);
        DrawRectangle(300, 70, 360, 100, DARKGRAY);  // Recta superior
        DrawRectangle(300, 370, 360, 100, DARKGRAY); // Recta inferior
        DrawRectangle(300, 170, 360, 200, Color{ 34, 139, 34, 255 }); // Césped interior

        // Bordes de pista blancos (para visualización)
        DrawLine(300, 70, 660, 70, RAYWHITE);
        DrawLine(300, 170, 660, 170, RAYWHITE);
        DrawLine(300, 370, 660, 370, RAYWHITE);
        DrawLine(300, 470, 660, 470, RAYWHITE);

        // Línea de salida / meta
        DrawRectangle(330, 370, 8, 100, WHITE);

        // Dibujar auto de prueba
        playerCar.Draw();

        // --- Interfaz / HUD provisional ---
        DrawRectangle(10, 10, 290, 135, Fade(BLACK, 0.75f));
        DrawRectangleLines(10, 10, 290, 135, RAYWHITE);
        DrawText("NeuroGenetica - Fase 1 (Base)", 20, 18, 15, GOLD);
        DrawText("Controles: WASD o Flechas", 20, 38, 12, LIGHTGRAY);
        DrawText("[F11] Pantalla Completa", 20, 54, 12, SKYBLUE);
        DrawText(TextFormat("Velocidad: %.2f", playerCar.speed), 20, 74, 13, GREEN);
        DrawText(TextFormat("Angulo: %.1f deg", playerCar.angle), 20, 92, 13, RAYWHITE);
        DrawText(TextFormat("FPS: %i", GetFPS()), 20, 112, 13, YELLOW);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
