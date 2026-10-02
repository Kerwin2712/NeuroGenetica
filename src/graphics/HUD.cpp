#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 340.0f, 255.0f, 280.0f, 155.0f },
      panelColor{ Fade(BLACK, 0.85f) },
      borderColor{ Fade(RAYWHITE, 0.40f) }
{
}

void HUD::Draw(const Car& playerCar, const GeneticAlgorithm& ga, bool isGeneticMode, const Track& track, bool showQuadTree, int simSpeed) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    int startX = (int)panelBounds.x + 12;
    int startY = (int)panelBounds.y + 10;

    DrawText("NeuroGenetica - Neuroevolucion", startX, startY, 13, GOLD);

    if (isGeneticMode) {
        // --- Modo Evolución Genética Masiva ---
        DrawRectangle(startX, startY + 18, 256, 18, Fade(LIME, 0.25f));
        DrawRectangleLines(startX, startY + 18, 256, 18, LIME);
        DrawText("MODO: ENTRENAMIENTO GENETICO", startX + 6, startY + 22, 10, LIME);

        DrawText(TextFormat("Gen: %i", ga.GetGeneration()), startX, startY + 42, 12, GOLD);
        DrawText(TextFormat("Vivos: %i / %i", ga.GetAliveCount(), ga.GetPopulationSize()), startX + 130, startY + 42, 12, 
            ga.GetAliveCount() > 0 ? GREEN : RED);

        DrawText(TextFormat("Fitness Gen: %.1f", ga.GetBestFitnessCurrentGen()), startX, startY + 58, 11, RAYWHITE);
        DrawText(TextFormat("Record: %.1f", ga.GetBestFitnessAllTime()), startX + 130, startY + 58, 11, YELLOW);

        DrawText(TextFormat("Tiempo: %.1fs | Vel: %ix [ESPACIO]", ga.GetGenerationTimer(), simSpeed), startX, startY + 74, 11, SKYBLUE);

        DrawText("[M] Modo  [R] Evolucionar  [N] Gen 1", startX, startY + 92, 10, LIGHTGRAY);
        DrawText("[Q] QuadTree  [F11] Pantalla Completa", startX, startY + 106, 10, LIGHTGRAY);
    } else {
        // --- Modo Manual Individual ---
        DrawRectangle(startX, startY + 18, 256, 18, Fade(ORANGE, 0.25f));
        DrawRectangleLines(startX, startY + 18, 256, 18, ORANGE);
        DrawText("MODO: MANUAL (1 AUTO - WASD)", startX + 6, startY + 22, 10, ORANGE);

        if (playerCar.IsAlive()) {
            DrawText("Estado: EN PISTA", startX, startY + 42, 12, GREEN);
        } else {
            DrawText("Estado: !COLISIONADO! [R]", startX, startY + 42, 12, RED);
        }

        DrawText(TextFormat("Velocidad: %.2f | Checkpoints: %i", playerCar.GetSpeed(), playerCar.GetCurrentCheckpoint()), startX, startY + 58, 11, RAYWHITE);
        DrawText(TextFormat("Angulo: %.1f deg", playerCar.GetAngle()), startX, startY + 74, 11, GOLD);

        DrawText("[M] Activar IA Masiva  [R] Reiniciar", startX, startY + 92, 10, LIGHTGRAY);
        DrawText("[WASD/Flechas] Conducir  [Q] QuadTree", startX, startY + 106, 10, LIGHTGRAY);
    }

    // Métricas del QuadTree y rendimiento
    Color qtColor = showQuadTree ? GOLD : GRAY;
    DrawText(TextFormat("QuadTree: %s (%i) | FPS: %i", 
        showQuadTree ? "VISIBLE [Q]" : "O(log n)",
        track.GetQuadTree().GetTotalNodes(), GetFPS()), startX, startY + 128, 10, qtColor);
}
