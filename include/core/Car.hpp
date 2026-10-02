#pragma once
#include "raylib.h"
#include "Geometry.hpp"
#include "QuadTree.hpp"
#include "NeuralNetwork.hpp"
#include <vector>

enum class ControlMode {
    Manual,
    Autonomous
};

class Car {
public:
    Car(Vector2 startPos = { 360.0f, 420.0f }, float startAngle = 0.0f, ControlMode mode = ControlMode::Manual);
    ~Car() = default;

    // Actualización según el modo activo
    void Update();

    // Actualización manual por teclado
    void UpdateManual();

    // Actualización autónoma procesada por la red neuronal
    void ThinkAndDrive();

    // Control directo por valores de aceleración [-1, 1] y viraje [-1, 1]
    void UpdateAI(float throttleInput, float steerInput);

    // Verificación de checkpoints para avance de fitness y descarte por inactividad
    void CheckCheckpoints(const std::vector<LineSegment>& checkpoints, float dt);

    // Raycasting optimizado usando consultas espaciales en QuadTree
    void CastSensors(const QuadTree& quadTree);

    // Detección de colisión optimizada con QuadTree
    bool CheckCollision(const QuadTree& quadTree);

    // Métodos alternativos directos con lista de segmentos
    void CastSensors(const std::vector<LineSegment>& walls);
    bool CheckCollision(const std::vector<LineSegment>& walls);

    // Reiniciar posición y revivir el vehículo
    void Reset(Vector2 startPos = { 360.0f, 420.0f }, float startAngle = 0.0f);

    // Dibuja el chasis, faros, rayos sensores y telemetría visual
    void Draw() const;

    // Getters
    Vector2 GetPosition() const { return position; }
    float GetAngle() const { return angle; }
    float GetSpeed() const { return speed; }
    bool IsAlive() const { return isAlive; }
    ControlMode GetControlMode() const { return controlMode; }
    float GetFitness() const { return fitness; }
    int GetCurrentCheckpoint() const { return currentCheckpoint; }
    const std::vector<SensorHit>& GetSensorHits() const { return sensorHits; }
    const std::vector<float>& GetLastAiOutputs() const { return lastAiOutputs; }
    NeuralNetwork& GetBrain() { return brain; }
    const NeuralNetwork& GetBrain() const { return brain; }

    // Setters
    void SetPosition(Vector2 pos) { position = pos; }
    void SetAngle(float newAngle) { angle = newAngle; }
    void SetAlive(bool alive) { isAlive = alive; }
    void SetControlMode(ControlMode mode) { controlMode = mode; }
    void SetBrain(const NeuralNetwork& newBrain) { brain = newBrain; }
    void SetCustomColor(Color col) { customColor = col; useCustomColor = true; }
    void SetDrawSensors(bool draw) { drawSensors = draw; }

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
    Color manualColor;
    Color aiColor;
    Color customColor;
    bool useCustomColor;
    bool isAlive;
    bool drawSensors;

    // Métricas para Algoritmo Genético (Neuroevolución)
    float fitness;
    int currentCheckpoint;
    float distanceTraveled;
    float timeAlive;
    float timeSinceLastCheckpoint;

    // Modo de control: Manual o Autónomo
    ControlMode controlMode;

    // Cerebro de Red Neuronal
    NeuralNetwork brain;
    std::vector<float> lastAiOutputs;

    // Sensores de raycasting
    float sensorLength;
    std::vector<float> sensorAngles;
    std::vector<SensorHit> sensorHits;
};
