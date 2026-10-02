#pragma once
#include "raylib.h"
#include "Geometry.hpp"
#include "QuadTree.hpp"
#include <vector>

class Track {
public:
    Track();
    ~Track() = default;

    // Renderiza el fondo de césped, asfalto, pianos (kerbs), línea discontinua y meta
    void Draw() const;

    // Dibuja la estructura espacial del QuadTree para depuración visual y defensas
    void DrawDebugQuadTree() const;

    // Dibuja los checkpoints guía del circuito
    void DrawCheckpoints(bool visible = true) const;

    // Retorna todos los segmentos de línea que conforman las paredes exteriores e interiores
    const std::vector<LineSegment>& GetWalls() const { return walls; }

    // Retorna la secuencia ordenada de checkpoints para medir fitness
    const std::vector<LineSegment>& GetCheckpoints() const { return checkpoints; }

    // Retorna el QuadTree que indexa espacialmente las paredes de la pista
    const QuadTree& GetQuadTree() const { return quadTree; }

    // Posición y orientación inicial para el spawn de vehículos
    Vector2 GetStartPosition() const { return startPosition; }
    float GetStartAngle() const { return startAngle; }

private:
    void BuildComplexTrack();
    static Vector2 CatmullRom(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float t);

    Color grassColor;
    Color roadColor;
    float roadWidth;

    Vector2 startPosition;
    float startAngle;

    // Vértices del circuito interpolado
    std::vector<Vector2> centerline;
    std::vector<Vector2> innerBoundary;
    std::vector<Vector2> outerBoundary;

    // Segmentos de colisión y raycasting
    std::vector<LineSegment> walls;

    // Secuencia de checkpoints perpendiculares
    std::vector<LineSegment> checkpoints;

    // Árbol de partición espacial 2D
    QuadTree quadTree;
};
