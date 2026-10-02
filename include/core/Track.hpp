#pragma once
#include "raylib.h"
#include "Geometry.hpp"
#include "QuadTree.hpp"
#include <vector>

class Track {
public:
    Track();
    ~Track() = default;

    // Renderiza el fondo de césped, la pista asfaltada, bordes delimitadores y meta
    void Draw() const;

    // Dibuja la estructura espacial del QuadTree para depuración visual y defensas
    void DrawDebugQuadTree() const;

    // Retorna todos los segmentos de línea que conforman las paredes exteriores e interiores
    const std::vector<LineSegment>& GetWalls() const { return walls; }

    // Retorna el QuadTree que indexa espacialmente las paredes de la pista
    const QuadTree& GetQuadTree() const { return quadTree; }

private:
    void BuildTrackBoundaries();

    Color grassColor;
    Color roadColor;
    Color innerBoundaryColor;
    Color outerBoundaryColor;

    Vector2 leftTurnCenter;
    Vector2 rightTurnCenter;
    float innerRadius;
    float outerRadius;
    Rectangle topStraight;
    Rectangle bottomStraight;
    Rectangle innerGrass;
    Rectangle finishLine;

    // Colección de segmentos de colisión y raycasting
    std::vector<LineSegment> walls;

    // Árbol de partición espacial 2D
    QuadTree quadTree;
};
