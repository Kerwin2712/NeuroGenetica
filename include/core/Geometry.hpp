#pragma once
#include "raylib.h"
#include <cmath>

struct LineSegment {
    Vector2 start;
    Vector2 end;
};

// Estructura para registrar la lectura de cada rayo sensor
struct SensorHit {
    Vector2 start;
    Vector2 hitPoint;
    float distance;         // Distancia euclidiana al muro
    float normalizedDist;   // [0.0, 1.0] para la red neuronal
    bool hasHit;            // true si intersecta un límite de la pista
    float angleOffset;      // Desplazamiento angular respecto al frente del auto
};

// Función auxiliar de intersección matemática entre 2 segmentos de recta 2D
inline bool CheckLineIntersection(Vector2 p1, Vector2 p2, Vector2 p3, Vector2 p4, Vector2& outHit, float& outT) {
    float rx = p2.x - p1.x;
    float ry = p2.y - p1.y;
    float sx = p4.x - p3.x;
    float sy = p4.y - p3.y;

    float denom = rx * sy - ry * sx;
    if (std::abs(denom) < 1e-6f) return false; // Paralelos o colineales

    float qpx = p3.x - p1.x;
    float qpy = p3.y - p1.y;

    float t = (qpx * sy - qpy * sx) / denom;
    float u = (qpx * ry - qpy * rx) / denom;

    if (t >= 0.0f && t <= 1.0f && u >= 0.0f && u <= 1.0f) {
        outT = t;
        outHit.x = p1.x + t * rx;
        outHit.y = p1.y + t * ry;
        return true;
    }
    return false;
}
