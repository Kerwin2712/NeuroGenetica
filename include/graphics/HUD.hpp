#pragma once
#include "raylib.h"
#include "Car.hpp"

class HUD {
public:
    HUD();
    ~HUD() = default;

    // Dibuja el panel de métricas, controles y estadísticas en pantalla
    void Draw(const Car& car) const;

private:
    Rectangle panelBounds;
    Color panelColor;
    Color borderColor;
};
