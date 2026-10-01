#include "raylib.h"
#include <cmath>
#include <vector>
#include <string>

// Estructura simple para el vehículo en Fase 1 (Prototipo con rectángulo)
struct CarPrototype {
    Vector2 position = { 200.0f, 380.0f };
    float angle = 0.0f;       // En grados
    float speed = 0.0f;
    float maxSpeed = 5.0f;
    float acceleration = 0.15f;
    float friction = 0.96f;
    float turnSpeed = 3.5f;

    // Dimensiones del rectángulo
    float width = 36.0f;
    float height = 18.0f;
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
        DrawCircleV(frontRight, 3.0f, YELLOW);
        DrawCircleV(frontLeft, 3.0f, YELLOW);

        // Simulación visual de 5 rayos sensores (Fase 2 se conectará con el QuadTree)
        const float sensorLength = 90.0f;
        const float sensorAngles[] = { -60.0f, -30.0f, 0.0f, 30.0f, 60.0f };

        for (float sAngle : sensorAngles) {
            float totalRad = (angle + sAngle) * DEG2RAD;
            Vector2 endPoint = {
                position.x + std::cos(totalRad) * sensorLength,
                position.y + std::sin(totalRad) * sensorLength
            };
            DrawLineV(position, endPoint, Fade(SKYBLUE, 0.5f));
            DrawCircleV(endPoint, 2.5f, Fade(RED, 0.7f));
        }
    }
};

int main() {
    const int screenWidth = 1024;
    const int screenHeight = 768;

    SetConfigFlags(FLAG_MSAA_4X_HINT);
    InitWindow(screenWidth, screenHeight, "NeuroGenetica - Simulacion Base [Fase 1]");
    SetTargetFPS(60);

    CarPrototype playerCar;

    while (!WindowShouldClose()) {
        // --- Actualización ---
        playerCar.Update();

        // --- Renderizado ---
        BeginDrawing();
        ClearBackground(Color{ 34, 139, 34, 255 }); // Césped exterior

        // Circuito básico procedural (Fondo de pista)
        // En fases posteriores se cargará una textura generada o mapa vectorial
        DrawRing(Vector2{ 340.0f, 384.0f }, 140.0f, 280.0f, 90.0f, 270.0f, 36, DARKGRAY);
        DrawRing(Vector2{ 684.0f, 384.0f }, 140.0f, 280.0f, 270.0f, 450.0f, 36, DARKGRAY);
        DrawRectangle(340, 104, 344, 140, DARKGRAY); // Recta superior
        DrawRectangle(340, 524, 344, 140, DARKGRAY); // Recta inferior
        DrawRectangle(340, 244, 344, 280, Color{ 34, 139, 34, 255 }); // Césped interior

        // Línea de salida / meta
        DrawRectangle(335, 524, 10, 140, WHITE);

        // Dibujar auto de prueba
        playerCar.Draw();

        // --- Interfaz / HUD provisional ---
        DrawRectangle(10, 10, 310, 130, Fade(BLACK, 0.75f));
        DrawRectangleLines(10, 10, 310, 130, RAYWHITE);
        DrawText("NeuroGenetica - Fase 1 (Base)", 20, 20, 16, GOLD);
        DrawText("Controles: WASD o Flechas de direccion", 20, 45, 13, LIGHTGRAY);
        DrawText(TextFormat("Velocidad: %.2f", playerCar.speed), 20, 68, 14, GREEN);
        DrawText(TextFormat("Angulo: %.1f deg", playerCar.angle), 20, 88, 14, SKYBLUE);
        DrawText(TextFormat("FPS: %i", GetFPS()), 20, 108, 14, YELLOW);

        EndDrawing();
    }

    CloseWindow();
    return 0;
}
