#include "Track.hpp"
#include <cmath>

Vector2 Track::CatmullRom(Vector2 p0, Vector2 p1, Vector2 p2, Vector2 p3, float t) {
    float t2 = t * t;
    float t3 = t2 * t;

    float x = 0.5f * ((2.0f * p1.x) +
              (-p0.x + p2.x) * t +
              (2.0f * p0.x - 5.0f * p1.x + 4.0f * p2.x - p3.x) * t2 +
              (-p0.x + 3.0f * p1.x - 3.0f * p2.x + p3.x) * t3);

    float y = 0.5f * ((2.0f * p1.y) +
              (-p0.y + p2.y) * t +
              (2.0f * p0.y - 5.0f * p1.y + 4.0f * p2.y - p3.y) * t2 +
              (-p0.y + 3.0f * p1.y - 3.0f * p2.y + p3.y) * t3);

    return { x, y };
}

Track::Track()
    : grassColor{ 24, 105, 38, 255 },
      roadColor{ 38, 42, 48, 255 },
      roadWidth{ 64.0f },
      startPosition{ 250.0f, 465.0f },
      startAngle{ 0.0f },
      quadTree(BoundingBox2D{ 0.0f, 0.0f, 960.0f, 540.0f }, 4, 6)
{
    BuildComplexTrack();
}

void Track::BuildComplexTrack() {
    walls.clear();
    checkpoints.clear();
    centerline.clear();
    innerBoundary.clear();
    outerBoundary.clear();
    quadTree.Clear();

    // Circuito Grand Prix técnico: 23 puntos de control interpolados con Catmull-Rom
    // Incluye: Recta principal, Curva Grande, chicane/eses superior, horquilla cerrada de 180° y parabólica
    std::vector<Vector2> controlPoints = {
        // Sector 1: Recta principal de salida y curva rápida a derechas (Curva Grande)
        { 240.0f, 465.0f },
        { 380.0f, 465.0f },
        { 520.0f, 465.0f },
        { 660.0f, 465.0f },
        { 780.0f, 450.0f },
        { 860.0f, 400.0f },
        { 890.0f, 310.0f },
        { 860.0f, 210.0f },
        { 790.0f, 140.0f },

        // Sector 2: Chicane / Curva en 'S' técnica superior
        { 700.0f, 100.0f },
        { 610.0f, 110.0f },
        { 540.0f, 160.0f },
        { 470.0f, 190.0f },
        { 400.0f, 160.0f },
        { 340.0f, 110.0f },

        // Sector 3: Horquilla oeste cerrada (Hairpin)
        { 260.0f, 80.0f },
        { 170.0f, 80.0f },
        { 100.0f, 130.0f },
        { 85.0f, 210.0f },
        { 110.0f, 280.0f },

        // Sector 4: Curva amplia de entrada a recta principal (Parabólica)
        { 140.0f, 340.0f },
        { 155.0f, 405.0f },
        { 195.0f, 455.0f }
    };

    size_t numControl = controlPoints.size();
    const int subdivisionsPerSegment = 3; // 23 * 3 = 69 puntos suaves y 69 checkpoints

    // 1. Generar la línea central suave usando interpolación Catmull-Rom
    for (size_t i = 0; i < numControl; ++i) {
        Vector2 p0 = controlPoints[(i + numControl - 1) % numControl];
        Vector2 p1 = controlPoints[i];
        Vector2 p2 = controlPoints[(i + 1) % numControl];
        Vector2 p3 = controlPoints[(i + 2) % numControl];

        for (int s = 0; s < subdivisionsPerSegment; ++s) {
            float t = (float)s / (float)subdivisionsPerSegment;
            centerline.push_back(CatmullRom(p0, p1, p2, p3, t));
        }
    }

    size_t totalPoints = centerline.size();
    float halfWidth = roadWidth / 2.0f;

    // 2. Calcular los límites izquierdo/derecho perpendiculares a la trayectoria
    for (size_t i = 0; i < totalPoints; ++i) {
        Vector2 prev = centerline[(i + totalPoints - 1) % totalPoints];
        Vector2 next = centerline[(i + 1) % totalPoints];

        Vector2 tangent = { next.x - prev.x, next.y - prev.y };
        float len = std::sqrt(tangent.x * tangent.x + tangent.y * tangent.y);
        if (len < 1e-4f) len = 1.0f;

        // Normal perpendicular a la dirección del circuito
        Vector2 normal = { -tangent.y / len, tangent.x / len };

        Vector2 inner = { centerline[i].x - normal.x * halfWidth, centerline[i].y - normal.y * halfWidth };
        Vector2 outer = { centerline[i].x + normal.x * halfWidth, centerline[i].y + normal.y * halfWidth };

        innerBoundary.push_back(inner);
        outerBoundary.push_back(outer);
    }

    // 3. Crear segmentos de muros e indexarlos en el QuadTree
    int wallId = 0;
    for (size_t i = 0; i < totalPoints; ++i) {
        size_t nextIdx = (i + 1) % totalPoints;

        // Muro exterior
        LineSegment outerWall = { outerBoundary[i], outerBoundary[nextIdx], wallId++ };
        walls.push_back(outerWall);
        quadTree.Insert(outerWall);

        // Muro interior
        LineSegment innerWall = { innerBoundary[i], innerBoundary[nextIdx], wallId++ };
        walls.push_back(innerWall);
        quadTree.Insert(innerWall);

        // Checkpoint transversal para evaluar progreso de los autos
        checkpoints.push_back({ innerBoundary[i], outerBoundary[i], (int)i });
    }
}

void Track::Draw() const {
    // 1. Césped exterior del entorno
    ClearBackground(grassColor);

    if (centerline.empty()) return;
    size_t total = centerline.size();

    // 2. Dibujar superficie de asfalto mediante malla triangular continua
    for (size_t i = 0; i < total; ++i) {
        size_t next = (i + 1) % total;

        // Dos triángulos por cada cuadrilátero de asfalto
        DrawTriangle(innerBoundary[i], outerBoundary[i], outerBoundary[next], roadColor);
        DrawTriangle(innerBoundary[i], outerBoundary[next], innerBoundary[next], roadColor);

        // 3. Pianos de carrera (kerbs) rojo y blanco en los bordes
        Color kerbColor = (i % 2 == 0) ? RED : RAYWHITE;
        DrawLineEx(outerBoundary[i], outerBoundary[next], 3.0f, kerbColor);
        DrawLineEx(innerBoundary[i], innerBoundary[next], 3.0f, kerbColor);

        // 4. Línea discontinua central
        if (i % 2 == 0) {
            DrawLineEx(centerline[i], centerline[next], 1.5f, Fade(RAYWHITE, 0.45f));
        }
    }

    // 5. Línea de meta / salida (Checkered finish line)
    DrawLineEx(innerBoundary[0], outerBoundary[0], 6.0f, RAYWHITE);
    DrawLineEx(innerBoundary[0], outerBoundary[0], 2.5f, DARKGRAY);

    // 6. Checkpoints guía (dibujados tenuemente)
    DrawCheckpoints(true);
}

void Track::DrawCheckpoints(bool visible) const {
    if (!visible) return;
    for (const auto& cp : checkpoints) {
        DrawLineV(cp.start, cp.end, Fade(LIME, 0.20f));
    }
}

void Track::DrawDebugQuadTree() const {
    quadTree.DrawDebug();
}
