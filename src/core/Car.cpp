#include "Car.hpp"
#include <cmath>

Car::Car(Vector2 startPos, float startAngle)
    : position(startPos),
      angle(startAngle),
      speed(0.0f),
      maxSpeed(4.5f),
      acceleration(0.12f),
      friction(0.96f),
      turnSpeed(3.2f),
      width(30.0f),
      height(15.0f),
      bodyColor(RED),
      isAlive(true),
      sensorLength(75.0f),
      sensorAngles{ -60.0f, -30.0f, 0.0f, 30.0f, 60.0f }
{
}

void Car::UpdateManual() {
    if (!isAlive) return;

    // Controles por teclado: W/Up para acelerar, S/Down para frenar o reversa
    if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) {
        speed += acceleration;
        if (speed > maxSpeed) speed = maxSpeed;
    }
    if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) {
        speed -= acceleration * 0.8f;
        if (speed < -maxSpeed * 0.4f) speed = -maxSpeed * 0.4f;
    }

    // Viraje activo cuando hay movimiento
    if (std::abs(speed) > 0.05f) {
        float direction = (speed > 0) ? 1.0f : -1.0f;
        if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))  angle -= turnSpeed * direction;
        if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) angle += turnSpeed * direction;
    }

    // Aplicar rozamiento/fricción
    speed *= friction;

    // Cinemática 2D
    float rad = angle * DEG2RAD;
    position.x += std::cos(rad) * speed;
    position.y += std::sin(rad) * speed;
}

void Car::UpdateAI(float throttleInput, float steerInput) {
    if (!isAlive) return;

    // throttleInput: [-1, 1], steerInput: [-1, 1]
    speed += throttleInput * acceleration;
    if (speed > maxSpeed) speed = maxSpeed;
    if (speed < -maxSpeed * 0.3f) speed = -maxSpeed * 0.3f;

    if (std::abs(speed) > 0.05f) {
        float direction = (speed > 0) ? 1.0f : -1.0f;
        angle += steerInput * turnSpeed * direction;
    }

    speed *= friction;
    float rad = angle * DEG2RAD;
    position.x += std::cos(rad) * speed;
    position.y += std::sin(rad) * speed;
}

void Car::Draw() const {
    if (!isAlive) return;

    // 1. Chasis del auto como rectángulo con rotación
    Rectangle rect = { position.x, position.y, width, height };
    Vector2 origin = { width / 2.0f, height / 2.0f };
    DrawRectanglePro(rect, origin, angle, bodyColor);

    // 2. Faros delanteros para identificar el frente
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

    // 3. Rayos de sensores (raycasting visual)
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
