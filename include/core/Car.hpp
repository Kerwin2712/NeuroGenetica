#pragma once
#include "raylib.h"
#include "Geometry.hpp"
#include "QuadTree.hpp"
#include <vector>

class Car {
public:
    Car(Vector2 startPos = { 360.0f, 420.0f }, float startAngle = 0.0f);
    ~Car() = default;

    // Actualización de física con controles manuales por teclado
    void UpdateManual();

    // Actualización guiada por red neuronal
    void UpdateAI(float throttleInput, float steerInput);

    // Raycasting optimizado usando consultas espaciales en QuadTree
    void CastSensors(const QuadTree& quadTree);

    // Detección de colisión optimizada con QuadTree
    bool CheckCollision(const QuadTree& quadTree);

    // Métodos alternativos directos con lista de segmentos
    void CastSensors(const std::vector<LineSegment>& walls);
    bool CheckCollision(const std::vector<LineSegment>& walls);

    // Reiniciar posición y revivir el vehículo
    void Reset(Vector2 startPos = { 360.0f, 420.0f }, float startAngle = 0.0f);

    // Dibuja el chasis, faros, rayos sensores con puntos de impacto y efecto de colisión
    void Draw() const;

    // Getters
    Vector2 GetPosition() const { return position; }
    float GetAngle() const { return angle; }
    float GetSpeed() const { return speed; }
    bool IsAlive() const { return isAlive; }
    const std::vector<SensorHit>& GetSensorHits() const { return sensorHits; }

    // Setters
    void SetPosition(Vector2 pos) { position = pos; }
    void SetAngle(float newAngle) { angle = newAngle; }
    void SetAlive(bool alive) { isAlive = alive; }

private:
    std::vector<Vector2> GetCorners() const;

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

    // Sensores de raycasting
    float sensorLength;
    std::vector<float> sensorAngles;
    std::vector<SensorHit> sensorHits;
};
