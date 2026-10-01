#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 10.0f, 10.0f, 290.0f, 135.0f },
      panelColor{ Fade(BLACK, 0.75f) },
      borderColor{ RAYWHITE }
{
}

void HUD::Draw(const Car& car) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    DrawText("NeuroGenetica - Fase 1 (Base)", 20, 18, 15, GOLD);
    DrawText("Controles: WASD o Flechas", 20, 38, 12, LIGHTGRAY);
    DrawText("[F11] Pantalla Completa", 20, 54, 12, SKYBLUE);

    DrawText(TextFormat("Velocidad: %.2f", car.GetSpeed()), 20, 74, 13, GREEN);
    DrawText(TextFormat("Angulo: %.1f deg", car.GetAngle()), 20, 92, 13, RAYWHITE);
    DrawText(TextFormat("FPS: %i", GetFPS()), 20, 112, 13, YELLOW);
}
