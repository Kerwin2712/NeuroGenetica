#pragma once

#include "raylib.h"

class CarCamera {
public:
    CarCamera(
        int screenWidth,
        int screenHeight,
        Vector2 generalViewTarget = { 0.0f, 0.0f });

    // Actualiza la cámara sin interpolación ni rotación.
    void Update(Vector2 carPosition, float carSpeed, bool isManualMode);

    const Camera2D& GetCamera() const;

    void SetScreenSize(int screenWidth, int screenHeight);
    void SetGeneralView(Vector2 target);
    void SetTrainingView(Vector2 target, float worldWidth, float worldHeight);
    void SetZoomLimits(float zoomMinimum, float zoomMaximum);
    void SetSpeedZoomFactor(float factor);

private:
    Camera2D camera{};

    // Zoom normal y mínimo permitido al alcanzar velocidad alta.
    float zoomMinimum;
    float zoomMaximum;

    // Factor de reducción de zoom por unidad de velocidad.
    float speedZoomFactor;

    Vector2 generalViewTarget;
    float trainingWorldWidth;
    float trainingWorldHeight;
    float trainingZoom;
    int screenWidth;
    int screenHeight;

    void UpdateTrainingZoom();
};
