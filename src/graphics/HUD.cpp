#include "HUD.hpp"

HUD::HUD()
    : panelBounds{ 10.0f, 10.0f, 335.0f, 225.0f },
      panelColor{ Fade(BLACK, 0.82f) },
      borderColor{ RAYWHITE }
{
}

void HUD::Draw(const Car& playerCar, const GeneticAlgorithm& ga, bool isGeneticMode, const Track& track, bool showQuadTree, int simSpeed) const {
    DrawRectangleRec(panelBounds, panelColor);
    DrawRectangleLinesEx(panelBounds, 1.0f, borderColor);

    DrawText("NeuroGenetica - Neuroevolucion", 20, 16, 15, GOLD);

    if (isGeneticMode) {
        // --- Modo Evolución Genética Masiva ---
        DrawRectangle(20, 36, 295, 20, Fade(LIME, 0.25f));
        DrawRectangleLines(20, 36, 295, 20, LIME);
        DrawText("MODO: ENTRENAMIENTO GENETICO", 26, 40, 12, LIME);

        DrawText(TextFormat("Generacion: %i", ga.GetGeneration()), 20, 62, 13, GOLD);
        DrawText(TextFormat("Autos Vivos: %i / %i", ga.GetAliveCount(), ga.GetPopulationSize()), 160, 62, 13, 
            ga.GetAliveCount() > 0 ? GREEN : RED);

        DrawText(TextFormat("Mejor Fitness Gen: %.1f", ga.GetBestFitnessCurrentGen()), 20, 80, 12, RAYWHITE);
        DrawText(TextFormat("Record Historico: %.1f", ga.GetBestFitnessAllTime()), 20, 96, 12, YELLOW);
        DrawText(TextFormat("Tiempo Gen: %.1f s", ga.GetGenerationTimer()), 20, 112, 12, LIGHTGRAY);

        DrawText(TextFormat("Velocidad: %ix [ESPACIO]", simSpeed), 20, 134, 12, SKYBLUE);
        DrawText("[M] Modo Manual  [R] Forzar Evolucion", 20, 150, 11, LIGHTGRAY);
        DrawText("[N] Reiniciar Gen 1   [Q] Ver QuadTree", 20, 166, 11, LIGHTGRAY);
    } else {
        // --- Modo Manual Individual ---
        DrawRectangle(20, 36, 295, 20, Fade(ORANGE, 0.25f));
        DrawRectangleLines(20, 36, 295, 20, ORANGE);
        DrawText("MODO: MANUAL (1 AUTO - WASD)", 26, 40, 12, ORANGE);

        DrawText("[M] Activar Entrenamiento Masivo (IA)", 20, 62, 11, SKYBLUE);
        DrawText("[R] Reiniciar Auto  [Q] Ver QuadTree", 20, 78, 11, LIGHTGRAY);

        if (playerCar.IsAlive()) {
            DrawText("Estado: EN PISTA", 20, 102, 12, GREEN);
        } else {
            DrawText("Estado: !COLISIONADO! (Pulsa [R])", 20, 102, 12, RED);
        }

        DrawText(TextFormat("Velocidad: %.2f", playerCar.GetSpeed()), 20, 122, 12, GREEN);
        DrawText(TextFormat("Angulo: %.1f deg", playerCar.GetAngle()), 20, 140, 12, RAYWHITE);
        DrawText(TextFormat("Checkpoints: %i", playerCar.GetCurrentCheckpoint()), 20, 158, 12, GOLD);
    }

    // Métricas del QuadTree (Programación 3)
    Color qtColor = showQuadTree ? GOLD : GRAY;
    DrawText(TextFormat("QuadTree: %s (%i nodos)", 
        showQuadTree ? "VISIBLE [Q]" : "ACTIVO O(log n)",
        track.GetQuadTree().GetTotalNodes()), 20, 195, 11, qtColor);
    DrawText(TextFormat("FPS: %i", GetFPS()), 250, 195, 11, YELLOW);
}
