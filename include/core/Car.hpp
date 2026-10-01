#pragma once
#include "raylib.h"
#include <vector>

class Car {
public:
    Car(Vector2 startPos = { 360.0f, 420.0f }, float startAngle = 0.0f);
    ~Car() = default;

    // Actualización con controles manuales por teclado (Fase 1)
    void UpdateManual();

    // Actualización futura guiada por red neuronal
    void UpdateAI(float throttleInput, float steerInput);

    // Dibuja el chasis del auto (rectángulo rotado), faros y sensores de raycasting
    void Draw() const;

    // Getters
    Vector2 GetPosition() const { return position; }
    float GetAngle() const { return angle; }
    float GetSpeed() const { return speed; }
    bool IsAlive() const { return isAlive; }

    // Setters
    void SetPosition(Vector2 pos) { position = pos; }
    void SetAngle(float newAngle) { angle = newAngle; }
    void SetAlive(bool alive) { isAlive = alive; }

private:
    Vector2 position;
    float angle;         // Grados (0 = hacia la derecha)
    float speed;
    float maxSpeed;
    float acceleration;
    float friction;
    float turnSpeed;

    float width;
    float height;
    Color bodyColor;
    bool isAlive;

    // Configuración de los rayos sensores
    float sensorLength;
    std::vector<float> sensorAngles;
};
