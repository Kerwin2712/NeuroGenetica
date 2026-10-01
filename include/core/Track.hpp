#pragma once
#include "raylib.h"

class Track {
public:
    Track();
    ~Track() = default;

    // Renderiza el fondo de césped, la pista asfaltada y los bordes
    void Draw() const;

private:
    Color grassColor;
    Color roadColor;
    Color lineColor;

    // Puntos y dimensiones del trazado del circuito
    Vector2 leftTurnCenter;
    Vector2 rightTurnCenter;
    float innerRadius;
    float outerRadius;
    Rectangle topStraight;
    Rectangle bottomStraight;
    Rectangle innerGrass;
    Rectangle finishLine;
};
