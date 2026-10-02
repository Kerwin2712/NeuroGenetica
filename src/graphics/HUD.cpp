#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 10.0f, 10.0f, 310.0f, 185.0f },
      panelColor{ Fade(BLACK, 0.78f) },
      borderColor{ RAYWHITE }
{
}

void HUD::Draw(const Car& car, const Track& track, bool showQuadTree) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    DrawText("NeuroGenetica - Fase 2 (QuadTree)", 20, 16, 15, GOLD);
    DrawText("Controles: WASD / Flechas", 20, 36, 12, LIGHTGRAY);
    DrawText("[F11] Pantalla   [R] Reiniciar   [Q] QuadTree", 20, 52, 11, SKYBLUE);

    if (car.IsAlive()) {
        DrawText("Estado: EN PISTA", 20, 72, 13, GREEN);
    } else {
        DrawText("Estado: !COLISIONADO! (Pulsa [R])", 20, 72, 13, RED);
    }

    DrawText(TextFormat("Velocidad: %.2f", car.GetSpeed()), 20, 92, 13, GREEN);
    DrawText(TextFormat("Angulo: %.1f deg", car.GetAngle()), 20, 110, 13, RAYWHITE);
    DrawText(TextFormat("FPS: %i", GetFPS()), 20, 128, 13, YELLOW);

    // Métricas del QuadTree (Programación 3)
    Color qtColor = showQuadTree ? GOLD : SKYBLUE;
    DrawText(TextFormat("QuadTree: %s (%i nodos | %i muros)", 
        showQuadTree ? "VISIBLE [Q]" : "ACTIVO O(log n)",
        track.GetQuadTree().GetTotalNodes(),
        (int)track.GetWalls().size()), 20, 150, 11, qtColor);
}
