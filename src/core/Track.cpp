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
      finishLine{ 330.0f, 370.0f, 8.0f, 100.0f },
      quadTree(BoundingBox2D{ 0.0f, 0.0f, 960.0f, 540.0f }, 4, 6)
{
    BuildTrackBoundaries();
    BuildCheckpoints();
}

void Track::BuildTrackBoundaries() {
    walls.clear();
    quadTree.Clear();

    const int curveSubdivisions = 24;
    int currentId = 0;

    auto addWall = [this, &currentId](Vector2 start, Vector2 end) {
        LineSegment seg = { start, end, currentId++ };
        walls.push_back(seg);
        quadTree.Insert(seg);
    };

    // 1. Recta exterior superior (Y = 70)
    addWall({ 300.0f, 70.0f }, { 660.0f, 70.0f });

    // 2. Curva exterior derecha (centro 660, 270 | radio 200 | de -90° a +90°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (-90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (-90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { rightTurnCenter.x + std::cos(a1) * outerRadius, rightTurnCenter.y + std::sin(a1) * outerRadius };
        Vector2 p2 = { rightTurnCenter.x + std::cos(a2) * outerRadius, rightTurnCenter.y + std::sin(a2) * outerRadius };
        addWall(p1, p2);
    }

    // 3. Recta exterior inferior (Y = 470)
    addWall({ 660.0f, 470.0f }, { 300.0f, 470.0f });

    // 4. Curva exterior izquierda (centro 300, 270 | radio 200 | de +90° a +270°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { leftTurnCenter.x + std::cos(a1) * outerRadius, leftTurnCenter.y + std::sin(a1) * outerRadius };
        Vector2 p2 = { leftTurnCenter.x + std::cos(a2) * outerRadius, leftTurnCenter.y + std::sin(a2) * outerRadius };
        addWall(p1, p2);
    }

    // 5. Recta interior superior (Y = 170)
    addWall({ 300.0f, 170.0f }, { 660.0f, 170.0f });

    // 6. Curva interior derecha (centro 660, 270 | radio 100 | de -90° a +90°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (-90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (-90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { rightTurnCenter.x + std::cos(a1) * innerRadius, rightTurnCenter.y + std::sin(a1) * innerRadius };
        Vector2 p2 = { rightTurnCenter.x + std::cos(a2) * innerRadius, rightTurnCenter.y + std::sin(a2) * innerRadius };
        addWall(p1, p2);
    }

    // 7. Recta interior inferior (Y = 370)
    addWall({ 660.0f, 370.0f }, { 300.0f, 370.0f });

    // 8. Curva interior izquierda (centro 300, 270 | radio 100 | de +90° a +270°)
    for (int i = 0; i < curveSubdivisions; ++i) {
        float a1 = (90.0f + (180.0f / curveSubdivisions) * i) * DEG2RAD;
        float a2 = (90.0f + (180.0f / curveSubdivisions) * (i + 1)) * DEG2RAD;
        Vector2 p1 = { leftTurnCenter.x + std::cos(a1) * innerRadius, leftTurnCenter.y + std::sin(a1) * innerRadius };
        Vector2 p2 = { leftTurnCenter.x + std::cos(a2) * innerRadius, leftTurnCenter.y + std::sin(a2) * innerRadius };
        addWall(p1, p2);
    }
}

void Track::BuildCheckpoints() {
    checkpoints.clear();
    int cpId = 0;

    // 1. Recta inferior (de izquierda a derecha, avance antihorario)
    for (float x = 420.0f; x <= 660.0f; x += 60.0f) {
        checkpoints.push_back({ { x, 370.0f }, { x, 470.0f }, cpId++ });
    }

    // 2. Curva derecha (de +70° descendiendo a -70°)
    for (float deg = 70.0f; deg >= -70.0f; deg -= 20.0f) {
        float rad = deg * DEG2RAD;
        Vector2 p1 = { rightTurnCenter.x + std::cos(rad) * innerRadius, rightTurnCenter.y + std::sin(rad) * innerRadius };
        Vector2 p2 = { rightTurnCenter.x + std::cos(rad) * outerRadius, rightTurnCenter.y + std::sin(rad) * outerRadius };
        checkpoints.push_back({ p1, p2, cpId++ });
    }

    // 3. Recta superior (de derecha a izquierda)
    for (float x = 600.0f; x >= 300.0f; x -= 60.0f) {
        checkpoints.push_back({ { x, 70.0f }, { x, 170.0f }, cpId++ });
    }

    // 4. Curva izquierda (de 250° descendiendo a 110°)
    for (float deg = 250.0f; deg >= 110.0f; deg -= 20.0f) {
        float rad = deg * DEG2RAD;
        Vector2 p1 = { leftTurnCenter.x + std::cos(rad) * innerRadius, leftTurnCenter.y + std::sin(rad) * innerRadius };
        Vector2 p2 = { leftTurnCenter.x + std::cos(rad) * outerRadius, leftTurnCenter.y + std::sin(rad) * outerRadius };
        checkpoints.push_back({ p1, p2, cpId++ });
    }

    // 5. Cierre de vuelta (línea de meta final)
    checkpoints.push_back({ { 330.0f, 370.0f }, { 330.0f, 470.0f }, cpId++ });
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

    // 7. Dibujar checkpoints tenuemente
    DrawCheckpoints(true);
}

void Track::DrawCheckpoints(bool visible) const {
    if (!visible) return;
    for (const auto& cp : checkpoints) {
        DrawLineV(cp.start, cp.end, Fade(LIME, 0.25f));
    }
}

void Track::DrawDebugQuadTree() const {
    quadTree.DrawDebug();
}
