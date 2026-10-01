#include "Car.hpp"
#include <cmath>
#include <algorithm>

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
      sensorLength(95.0f),
      sensorAngles{ -60.0f, -30.0f, 0.0f, 30.0f, 60.0f }
{
}

std::vector<Vector2> Car::GetCorners() const {
    float rad = angle * DEG2RAD;
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);

    float hw = width / 2.0f;
    float hh = height / 2.0f;

    // 4 esquinas rotadas relativas al centro
    return {
        { position.x + ( hw * cosA -  hh * sinA), position.y + ( hw * sinA +  hh * cosA) }, // Delantera derecha
        { position.x + (-hw * cosA -  hh * sinA), position.y + (-hw * sinA +  hh * cosA) }, // Trasera derecha
        { position.x + (-hw * cosA - -hh * sinA), position.y + (-hw * sinA + -hh * cosA) }, // Trasera izquierda
        { position.x + ( hw * cosA - -hh * sinA), position.y + ( hw * sinA + -hh * cosA) }  // Delantera izquierda
    };
}

void Car::CastSensors(const std::vector<LineSegment>& walls) {
    sensorHits.clear();

    for (float sAngle : sensorAngles) {
        float totalRad = (angle + sAngle) * DEG2RAD;
        Vector2 rayEnd = {
            position.x + std::cos(totalRad) * sensorLength,
            position.y + std::sin(totalRad) * sensorLength
        };

        SensorHit hit;
        hit.start = position;
        hit.angleOffset = sAngle;
        hit.distance = sensorLength;
        hit.normalizedDist = 1.0f;
        hit.hasHit = false;
        hit.hitPoint = rayEnd;

        float minT = 1.0f;
        Vector2 closestPoint = rayEnd;

        // Comprobar intersección del rayo con cada muro de la pista
        for (const auto& wall : walls) {
            Vector2 currentHit;
            float currentT;
            if (CheckLineIntersection(position, rayEnd, wall.start, wall.end, currentHit, currentT)) {
                if (currentT < minT) {
                    minT = currentT;
                    closestPoint = currentHit;
                    hit.hasHit = true;
                }
            }
        }

        if (hit.hasHit) {
            hit.hitPoint = closestPoint;
            hit.distance = minT * sensorLength;
            hit.normalizedDist = minT;
        }

        sensorHits.push_back(hit);
    }
}

bool Car::CheckCollision(const std::vector<LineSegment>& walls) {
    if (!isAlive) return true;

    std::vector<Vector2> corners = GetCorners();

    // Las 4 aristas del rectángulo del auto
    LineSegment carEdges[4] = {
        { corners[0], corners[1] },
        { corners[1], corners[2] },
        { corners[2], corners[3] },
        { corners[3], corners[0] }
    };

    // Verificar si alguna arista del vehículo corta los muros del circuito
    for (const auto& edge : carEdges) {
        for (const auto& wall : walls) {
            Vector2 hitPoint;
            float t;
            if (CheckLineIntersection(edge.start, edge.end, wall.start, wall.end, hitPoint, t)) {
                isAlive = false;
                speed = 0.0f; // Detener el auto inmediatamente al chocar
                return true;
            }
        }
    }

    return false;
}

void Car::Reset(Vector2 startPos, float startAngle) {
    position = startPos;
    angle = startAngle;
    speed = 0.0f;
    isAlive = true;
    sensorHits.clear();
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

    // Rozamiento
    speed *= friction;

    // Cinemática 2D
    float rad = angle * DEG2RAD;
    position.x += std::cos(rad) * speed;
    position.y += std::sin(rad) * speed;
}

void Car::UpdateAI(float throttleInput, float steerInput) {
    if (!isAlive) return;

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
    // 1. Rayos sensores con detección visual de extremos de la carretera
    for (const auto& hit : sensorHits) {
        Color rayColor;
        if (hit.hasHit) {
            // Gradiente según proximidad al borde: rojo (muy cerca), naranja (medio), verde (lejos)
            if (hit.normalizedDist < 0.35f) {
                rayColor = RED;
            } else if (hit.normalizedDist < 0.70f) {
                rayColor = ORANGE;
            } else {
                rayColor = GREEN;
            }

            // Línea del sensor hasta el impacto con la pared
            DrawLineEx(hit.start, hit.hitPoint, 1.5f, Fade(rayColor, 0.85f));

            // Indicador gráfico destacado sobre el borde de la pista
            DrawCircleV(hit.hitPoint, 4.5f, rayColor);
            DrawCircleV(hit.hitPoint, 2.0f, YELLOW);
            DrawCircleLines((int)hit.hitPoint.x, (int)hit.hitPoint.y, 6.5f, RAYWHITE);
        } else {
            // Rayo sin colisión (alcance máximo)
            DrawLineV(hit.start, hit.hitPoint, Fade(SKYBLUE, 0.4f));
            DrawCircleV(hit.hitPoint, 2.0f, Fade(SKYBLUE, 0.6f));
        }
    }

    // 2. Chasis del vehículo
    Color currentColor = isAlive ? bodyColor : Color{ 90, 30, 30, 255 }; // Tono oscuro si colisionó
    Rectangle rect = { position.x, position.y, width, height };
    Vector2 origin = { width / 2.0f, height / 2.0f };
    DrawRectanglePro(rect, origin, angle, currentColor);
    DrawRectangleLinesEx(rect, 1.0f, isAlive ? GOLD : RED);

    // 3. Faros delanteros
    float rad = angle * DEG2RAD;
    Vector2 frontRight = {
        position.x + std::cos(rad) * (width / 2.0f) - std::sin(rad) * (height / 3.0f),
        position.y + std::sin(rad) * (width / 2.0f) + std::cos(rad) * (height / 3.0f)
    };
    Vector2 frontLeft = {
        position.x + std::cos(rad) * (width / 2.0f) + std::sin(rad) * (height / 3.0f),
        position.y + std::sin(rad) * (width / 2.0f) - std::cos(rad) * (height / 3.0f)
    };
    DrawCircleV(frontRight, 2.5f, isAlive ? YELLOW : DARKGRAY);
    DrawCircleV(frontLeft, 2.5f, isAlive ? YELLOW : DARKGRAY);

    // 4. Efecto gráfico destacado si colisionó
    if (!isAlive) {
        DrawCircleLines((int)position.x, (int)position.y, 22.0f, RED);
        DrawCircleLines((int)position.x, (int)position.y, 28.0f, Fade(ORANGE, 0.7f));
        DrawText("!COLISION!", (int)position.x - 38, (int)position.y - 32, 14, RED);
    }
}
