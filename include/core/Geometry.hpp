#pragma once
#include "raylib.h"
#include <cmath>
#include <algorithm>

struct LineSegment {
    Vector2 start;
    Vector2 end;
    int id = -1; // Identificador opcional para deduplicación rápida

    bool operator==(const LineSegment& other) const {
        return (id != -1 && id == other.id) ||
               (start.x == other.start.x && start.y == other.start.y &&
                end.x == other.end.x && end.y == other.end.y);
    }
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

// Rectángulo alineado a los ejes (AABB) para partición espacial y QuadTree
struct BoundingBox2D {
    float x;
    float y;
    float width;
    float height;

    bool ContainsPoint(Vector2 p) const {
        return (p.x >= x && p.x <= x + width &&
                p.y >= y && p.y <= y + height);
    }

    bool IntersectsBox(const BoundingBox2D& other) const {
        return !(other.x > x + width ||
                 other.x + other.width < x ||
                 other.y > y + height ||
                 other.y + other.height < y);
    }

    bool IntersectsSegment(const LineSegment& seg) const {
        // 1. Si alguno de los extremos está dentro de la caja
        if (ContainsPoint(seg.start) || ContainsPoint(seg.end)) return true;

        // 2. Verificar intersección del AABB del segmento con este AABB
        float minX = std::min(seg.start.x, seg.end.x);
        float maxX = std::max(seg.start.x, seg.end.x);
        float minY = std::min(seg.start.y, seg.end.y);
        float maxY = std::max(seg.start.y, seg.end.y);

        BoundingBox2D segBox = { minX, minY, maxX - minX, maxY - minY };
        if (!IntersectsBox(segBox)) return false;

        // 3. Comprobar si el segmento corta alguna de las 4 aristas de la caja
        Vector2 topLeft = { x, y };
        Vector2 topRight = { x + width, y };
        Vector2 bottomLeft = { x, y + height };
        Vector2 bottomRight = { x + width, y + height };

        Vector2 hit;
        float t;
        if (CheckLineIntersection(seg.start, seg.end, topLeft, topRight, hit, t)) return true;
        if (CheckLineIntersection(seg.start, seg.end, topRight, bottomRight, hit, t)) return true;
        if (CheckLineIntersection(seg.start, seg.end, bottomRight, bottomLeft, hit, t)) return true;
        if (CheckLineIntersection(seg.start, seg.end, bottomLeft, topLeft, hit, t)) return true;

        return false;
    }
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
