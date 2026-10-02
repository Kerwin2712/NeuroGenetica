#pragma once
#include "raylib.h"
#include "Car.hpp"
#include "Track.hpp"

class HUD {
public:
    HUD();
    ~HUD() = default;

    // Dibuja el panel de métricas, controles, telemetría y estado del QuadTree
    void Draw(const Car& car, const Track& track, bool showQuadTree) const;

private:
    Rectangle panelBounds;
    Color panelColor;
    Color borderColor;
};
