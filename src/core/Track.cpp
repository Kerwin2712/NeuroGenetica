#include "Track.hpp"
#include <cmath>

Track::Track()
    : grassColor{ 34, 139, 34, 255 },
      roadColor{ DARKGRAY },
      innerBoundaryColor{ RAYWHITE },
      outerBoundaryColor{ RAYWHITE },
      leftTurnCenter{ 300.0f, 270.0f },
      rightTurnCenter{ 660.0f, 270.0f },
      innerRadius{ 100.0f },
      outerRadius{ 200.0f },
      topStraight{ 300.0f, 70.0f, 360.0f, 100.0f },
      bottomStraight{ 300.0f, 370.0f, 360.0f, 100.0f },
      innerGrass{ 300.0f, 170.0f, 360.0f, 200.0f },
      finishLine{ 330.0f, 370.0f, 8.0f, 100.0f }
{
    BuildTrackBoundaries();
}

void Track::BuildTrackBoundaries() {
    walls.clear();
    const int curveSubdivisions = 24;

    // 1. Recta exterior superior (Y = 70)
    walls.push_back({ { 300.0f, 70.0f }, { 660.0f, 70.0f } });

    // 2. Curva exterior derecha (centro 660, 270 | radio 200 | de -90° a +90°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (-90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (-90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { rightTurnCenter.x + std::cos(a1) * outerRadius, rightTurnCenter.y + std::sin(a1) * outerRadius };
        Vector2 p2 = { rightTurnCenter.x + std::cos(a2) * outerRadius, rightTurnCenter.y + std::sin(a2) * outerRadius };
        walls.push_back({ p1, p2 });
    }

    // 3. Recta exterior inferior (Y = 470)
    walls.push_back({ { 660.0f, 470.0f }, { 300.0f, 470.0f } });

    // 4. Curva exterior izquierda (centro 300, 270 | radio 200 | de +90° a +270°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { leftTurnCenter.x + std::cos(a1) * outerRadius, leftTurnCenter.y + std::sin(a1) * outerRadius };
        Vector2 p2 = { leftTurnCenter.x + std::cos(a2) * outerRadius, leftTurnCenter.y + std::sin(a2) * outerRadius };
        walls.push_back({ p1, p2 });
    }

    // 5. Recta interior superior (Y = 170)
    walls.push_back({ { 300.0f, 170.0f }, { 660.0f, 170.0f } });

    // 6. Curva interior derecha (centro 660, 270 | radio 100 | de -90° a +90°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (-90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (-90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { rightTurnCenter.x + std::cos(a1) * innerRadius, rightTurnCenter.y + std::sin(a1) * innerRadius };
        Vector2 p2 = { rightTurnCenter.x + std::cos(a2) * innerRadius, rightTurnCenter.y + std::sin(a2) * innerRadius };
        walls.push_back({ p1, p2 });
    }

    // 7. Recta interior inferior (Y = 370)
    walls.push_back({ { 660.0f, 370.0f }, { 300.0f, 370.0f } });

    // 8. Curva interior izquierda (centro 300, 270 | radio 100 | de +90° a +270°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { leftTurnCenter.x + std::cos(a1) * innerRadius, leftTurnCenter.y + std::sin(a1) * innerRadius };
        Vector2 p2 = { leftTurnCenter.x + std::cos(a2) * innerRadius, leftTurnCenter.y + std::sin(a2) * innerRadius };
        walls.push_back({ p1, p2 });
    }
}

void Track::Draw() const {
    // 1. Fondo de césped exterior
    ClearBackground(grassColor);

    // 2. Curvas asfaltadas izquierda y derecha
    DrawRing(leftTurnCenter, innerRadius, outerRadius, 90.0f, 270.0f, 48, roadColor);
    DrawRing(rightTurnCenter, innerRadius, outerRadius, 270.0f, 450.0f, 48, roadColor);

    // 3. Rectas asfaltadas superior e inferior
    DrawRectangleRec(topStraight, roadColor);
    DrawRectangleRec(bottomStraight, roadColor);

    // 4. Césped interior (isla central)
    DrawRectangleRec(innerGrass, grassColor);

    // 5. Dibujar bordes de las paredes visibles
    for (const auto& wall : walls) {
        DrawLineEx(wall.start, wall.end, 2.0f, RAYWHITE);
    }

    // 6. Línea de salida / meta
    DrawRectangleRec(finishLine, WHITE);
}
