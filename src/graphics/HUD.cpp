#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 10.0f, 10.0f, 290.0f, 160.0f },
      panelColor{ Fade(BLACK, 0.75f) },
      borderColor{ RAYWHITE }
{
}

void HUD::Draw(const Car& car) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    DrawText("NeuroGenetica - Fase 1 (Base)", 20, 16, 15, GOLD);
    DrawText("Controles: WASD / Flechas", 20, 36, 12, LIGHTGRAY);
    DrawText("[F11] Pantalla Completa  [R] Reiniciar", 20, 52, 12, SKYBLUE);

    if (car.IsAlive()) {
        DrawText("Estado: EN PISTA", 20, 72, 13, GREEN);
    } else {
        DrawText("Estado: !COLISIONADO! ([R])", 20, 72, 13, RED);
    }

    DrawText(TextFormat("Velocidad: %.2f", car.GetSpeed()), 20, 92, 13, GREEN);
    DrawText(TextFormat("Angulo: %.1f deg", car.GetAngle()), 20, 112, 13, RAYWHITE);
    DrawText(TextFormat("FPS: %i", GetFPS()), 20, 132, 13, YELLOW);
}
