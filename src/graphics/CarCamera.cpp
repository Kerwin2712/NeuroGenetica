#include "graphics/CarCamera.hpp"

#include <algorithm>
#include <cmath>

CarCamera::CarCamera(
    int screenWidth,
    int screenHeight,
    Vector2 generalViewTarget)
    : zoomMinimum(0.65f),
      zoomMaximum(1.0f),
      speedZoomFactor(0.20f),
      generalViewTarget(generalViewTarget),
      trainingWorldWidth(960.0f),
      trainingWorldHeight(540.0f),
      trainingZoom(1.0f),
      screenWidth(screenWidth),
      screenHeight(screenHeight)
{
    SetScreenSize(screenWidth, screenHeight);
    camera.target = generalViewTarget;
    camera.rotation = 0.0f;
    camera.zoom = zoomMaximum;
}

void CarCamera::Update(
    Vector2 carPosition,
    float carSpeed,
    bool isManualMode)
{
    // La cámara no puede rotar en ningún modo.
    camera.rotation = 0.0f;

    if (!isManualMode) {
        // Modo entrenamiento/IA: vista general fija.
        camera.target = generalViewTarget;
        camera.zoom = trainingZoom;
        return;
    }

    // Seguimiento exacto: el carro siempre queda en el centro.
    camera.target = carPosition;

    // El zoom sale progresivamente a medida que aumenta la velocidad.
    const float zoomProgress =
        std::clamp(std::fabs(carSpeed) * speedZoomFactor, 0.0f, 1.0f);

    camera.zoom = zoomMaximum -
                  zoomProgress * (zoomMaximum - zoomMinimum);

    camera.zoom = std::clamp(camera.zoom, zoomMinimum, zoomMaximum);
}

const Camera2D& CarCamera::GetCamera() const {
    return camera;
}

void CarCamera::SetScreenSize(int screenWidth, int screenHeight) {
    this->screenWidth = screenWidth;
    this->screenHeight = screenHeight;

    camera.offset = {
        static_cast<float>(screenWidth) * 0.5f,
        static_cast<float>(screenHeight) * 0.5f
    };

    UpdateTrainingZoom();
}

void CarCamera::SetGeneralView(Vector2 target) {
    generalViewTarget = target;
}

void CarCamera::SetTrainingView(
    Vector2 target,
    float worldWidth,
    float worldHeight)
{
    generalViewTarget = target;
    trainingWorldWidth = worldWidth;
    trainingWorldHeight = worldHeight;
    UpdateTrainingZoom();
}

void CarCamera::SetZoomLimits(float newZoomMinimum, float newZoomMaximum) {
    zoomMinimum = newZoomMinimum;
    zoomMaximum = newZoomMaximum;

    if (zoomMinimum > zoomMaximum) {
        std::swap(zoomMinimum, zoomMaximum);
    }

    if (zoomMinimum <= 0.0f) {
        zoomMinimum = 0.01f;
    }

    camera.zoom = zoomMaximum;
}

void CarCamera::SetSpeedZoomFactor(float factor) {
    if (factor > 0.0f) {
        speedZoomFactor = factor;
    }
}

void CarCamera::UpdateTrainingZoom() {
    if (screenWidth <= 0 || screenHeight <= 0 ||
        trainingWorldWidth <= 0.0f || trainingWorldHeight <= 0.0f) {
        trainingZoom = 1.0f;
        return;
    }

    // Usa el zoom menor para que la pista completa quede visible
    // tanto horizontal como verticalmente.
    const float widthZoom =
        static_cast<float>(screenWidth) / trainingWorldWidth;
    const float heightZoom =
        static_cast<float>(screenHeight) / trainingWorldHeight;

    trainingZoom = std::min(widthZoom, heightZoom);
}
