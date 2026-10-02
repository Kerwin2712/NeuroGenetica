#pragma once
#include "raylib.h"
#include "Car.hpp"
#include "Track.hpp"
#include "GeneticAlgorithm.hpp"

class HUD {
public:
    HUD();
    ~HUD() = default;

    // Dibuja el panel de métricas adaptado al modo activo (Manual o Evolución Genética)
    void Draw(const Car& playerCar, const GeneticAlgorithm& ga, bool isGeneticMode, const Track& track, bool showQuadTree, int simSpeed) const;

private:
    Rectangle panelBounds;
    Color panelColor;
    Color borderColor;
};
