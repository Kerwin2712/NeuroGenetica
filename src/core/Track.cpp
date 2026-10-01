#include "Track.hpp"

Track::Track()
    : grassColor{ 34, 139, 34, 255 },
      roadColor{ DARKGRAY },
      lineColor{ RAYWHITE },
      leftTurnCenter{ 300.0f, 270.0f },
      rightTurnCenter{ 660.0f, 270.0f },
      innerRadius{ 100.0f },
      outerRadius{ 200.0f },
      topStraight{ 300.0f, 70.0f, 360.0f, 100.0f },
      bottomStraight{ 300.0f, 370.0f, 360.0f, 100.0f },
      innerGrass{ 300.0f, 170.0f, 360.0f, 200.0f },
      finishLine{ 330.0f, 370.0f, 8.0f, 100.0f }
{
}

void Track::Draw() const {
    // 1. Fondo de césped exterior
    ClearBackground(grassColor);

    // 2. Curvas asfaltadas izquierda y derecha
    DrawRing(leftTurnCenter, innerRadius, outerRadius, 90.0f, 270.0f, 36, roadColor);
    DrawRing(rightTurnCenter, innerRadius, outerRadius, 270.0f, 450.0f, 36, roadColor);

    // 3. Rectas asfaltadas superior e inferior
    DrawRectangleRec(topStraight, roadColor);
    DrawRectangleRec(bottomStraight, roadColor);

    // 4. Césped interior (isla central)
    DrawRectangleRec(innerGrass, grassColor);

    // 5. Líneas delimitadoras de la pista (guías visuales)
    DrawLine(300, 70, 660, 70, lineColor);
    DrawLine(300, 170, 660, 170, lineColor);
    DrawLine(300, 370, 660, 370, lineColor);
    DrawLine(300, 470, 660, 470, lineColor);

    // 6. Línea de salida / meta
    DrawRectangleRec(finishLine, WHITE);
}
