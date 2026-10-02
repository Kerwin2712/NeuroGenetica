#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 10.0f, 10.0f, 325.0f, 215.0f },
      panelColor{ Fade(BLACK, 0.80f) },
      borderColor{ RAYWHITE }
{
}

void HUD::Draw(const Car& car, const Track& track, bool showQuadTree) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    DrawText("NeuroGenetica - Fase 3 (IA)", 20, 16, 15, GOLD);

    // Indicador destacado del modo activo
    bool isAuto = (car.GetControlMode() == ControlMode::Autonomous);
    if (isAuto) {
        DrawRectangle(20, 36, 285, 20, Fade(SKYBLUE, 0.25f));
        DrawRectangleLines(20, 36, 285, 20, SKYBLUE);
        DrawText("MODO: AUTONOMO (RED NEURONAL)", 26, 40, 12, SKYBLUE);
    } else {
        DrawRectangle(20, 36, 285, 20, Fade(ORANGE, 0.25f));
        DrawRectangleLines(20, 36, 285, 20, ORANGE);
        DrawText("MODO: MANUAL (TECLADO WASD)", 26, 40, 12, ORANGE);
    }

    // Atajos de control
    DrawText("[M] Alternar Manual / Autonomo", 20, 62, 11, LIGHTGRAY);
    DrawText("[N] Red Aleatoria    [B] Red Navegacion", 20, 78, 11, LIGHTGRAY);
    DrawText("[R] Reiniciar Auto   [Q] Ver QuadTree", 20, 94, 11, LIGHTGRAY);

    // Estado del auto
    if (car.IsAlive()) {
        DrawText("Estado: EN PISTA", 20, 115, 12, GREEN);
    } else {
        DrawText("Estado: !COLISIONADO! (Pulsa [R])", 20, 115, 12, RED);
    }

    DrawText(TextFormat("Velocidad: %.2f", car.GetSpeed()), 20, 133, 12, GREEN);
    DrawText(TextFormat("Angulo: %.1f deg", car.GetAngle()), 20, 150, 12, RAYWHITE);

    // Telemetría de la Red Neuronal si está en modo autónomo
    if (isAuto && car.GetLastAiOutputs().size() >= 2) {
        float aiSteer = car.GetLastAiOutputs()[0];
        float aiThrottle = car.GetLastAiOutputs()[1];
        DrawText(TextFormat("IA Viraje: %+.2f | Motor: %+.2f", aiSteer, aiThrottle), 20, 168, 11, SKYBLUE);
    } else {
        DrawText("FPS: %i", 20, 168, 11, YELLOW);
    }

    // Métricas del QuadTree (Programación 3)
    Color qtColor = showQuadTree ? GOLD : GRAY;
    DrawText(TextFormat("QuadTree: %s (%i nodos)", 
        showQuadTree ? "VISIBLE [Q]" : "ACTIVO",
        track.GetQuadTree().GetTotalNodes()), 20, 188, 11, qtColor);
}
