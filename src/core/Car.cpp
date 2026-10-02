#include "Car.hpp"
#include <cmath>
#include <algorithm>

Car::Car(Vector2 startPos, float startAngle, ControlMode mode)
    : position(startPos),
      angle(startAngle),
      speed(0.0f),
      maxSpeed(4.5f),
      acceleration(0.12f),
      friction(0.96f),
      turnSpeed(3.2f),
      width(30.0f),
      height(15.0f),
      manualColor(RED),
      aiColor(Color{ 0, 130, 230, 255 }),
      customColor(WHITE),
      useCustomColor(false),
      isAlive(true),
      drawSensors(true),
      fitness(0.0f),
      currentCheckpoint(0),
      distanceTraveled(0.0f),
      timeAlive(0.0f),
      timeSinceLastCheckpoint(0.0f),
      controlMode(mode),
      brain(6, 8, 2),
      lastAiOutputs{ 0.0f, 0.0f },
      sensorLength(95.0f),
      sensorAngles{ -60.0f, -30.0f, 0.0f, 30.0f, 60.0f }
{
}

std::vector<Vector2> Car::GetCorners() const {
    float rad = angle * DEG2RAD;
    float cosA = std::cos(rad);
    float sinA = std::sin(rad);

    float hw = width / 2.0f;
    float hh = height / 2.0f;

    return {
        { position.x + ( hw * cosA -  hh * sinA), position.y + ( hw * sinA +  hh * cosA) },
        { position.x + (-hw * cosA -  hh * sinA), position.y + (-hw * sinA +  hh * cosA) },
        { position.x + (-hw * cosA - -hh * sinA), position.y + (-hw * sinA + -hh * cosA) },
        { position.x + ( hw * cosA - -hh * sinA), position.y + ( hw * sinA + -hh * cosA) }
    };
}

void Car::Update() {
    if (controlMode == ControlMode::Manual) {
        UpdateManual();
    } else {
        ThinkAndDrive();
    }
}

void Car::ThinkAndDrive() {
    if (!isAlive) return;

    std::vector<float> inputs;
    inputs.reserve(6);

    for (const auto& hit : sensorHits) {
        inputs.push_back(hit.normalizedDist);
    }
    while (inputs.size() < 5) {
        inputs.push_back(1.0f);
    }

    inputs.push_back(std::clamp(speed / maxSpeed, 0.0f, 1.0f));

    lastAiOutputs = brain.FeedForward(inputs);

    float steer = lastAiOutputs[0];
    float throttle = lastAiOutputs[1];

    UpdateAI(throttle, steer);
}

void Car::CheckCheckpoints(const std::vector<LineSegment>& checkpoints, float dt) {
    if (!isAlive || checkpoints.empty()) return;

    timeAlive += dt;
    timeSinceLastCheckpoint += dt;
    distanceTraveled += std::abs(speed);

    // Si pasa más de 3.0 segundos sin alcanzar el siguiente checkpoint consecutivo, descartar
    if (timeSinceLastCheckpoint > 3.0f) {
        isAlive = false;
        speed = 0.0f;
        return;
    }

    int targetIdx = currentCheckpoint % checkpoints.size();
    const LineSegment& cp = checkpoints[targetIdx];

    std::vector<Vector2> corners = GetCorners();
    LineSegment carEdges[4] = {
        { corners[0], corners[1] },
        { corners[1], corners[2] },
        { corners[2], corners[3] },
        { corners[3], corners[0] }
    };

    for (const auto& edge : carEdges) {
        Vector2 hit;
        float t;
        if (CheckLineIntersection(edge.start, edge.end, cp.start, cp.end, hit, t)) {
            currentCheckpoint++;
            timeSinceLastCheckpoint = 0.0f;
            break;
        }
    }

    fitness = (currentCheckpoint * 300.0f) + (distanceTraveled * 0.2f);
}

void Car::CastSensors(const QuadTree& quadTree) {
    sensorHits.clear();

    for (float sAngle : sensorAngles) {
        float totalRad = (angle + sAngle) * DEG2RAD;
        Vector2 rayEnd = {
            position.x + std::cos(totalRad) * sensorLength,
            position.y + std::sin(totalRad) * sensorLength
        };

        SensorHit hit;
        hit.start = position;
        hit.angleOffset = sAngle;
        hit.distance = sensorLength;
        hit.normalizedDist = 1.0f;
        hit.hasHit = false;
        hit.hitPoint = rayEnd;

        std::vector<LineSegment> candidateWalls;
        quadTree.QueryRay(position, rayEnd, candidateWalls);

        float minT = 1.0f;
        Vector2 closestPoint = rayEnd;

        for (const auto& wall : candidateWalls) {
            Vector2 currentHit;
            float currentT;
            if (CheckLineIntersection(position, rayEnd, wall.start, wall.end, currentHit, currentT)) {
                if (currentT < minT) {
                    minT = currentT;
                    closestPoint = currentHit;
                    hit.hasHit = true;
                }
            }
        }

        if (hit.hasHit) {
            hit.hitPoint = closestPoint;
            hit.distance = minT * sensorLength;
            hit.normalizedDist = minT;
        }

        sensorHits.push_back(hit);
    }
}

void Car::CastSensors(const std::vector<LineSegment>& walls) {
    sensorHits.clear();

    for (float sAngle : sensorAngles) {
        float totalRad = (angle + sAngle) * DEG2RAD;
        Vector2 rayEnd = {
            position.x + std::cos(totalRad) * sensorLength,
            position.y + std::sin(totalRad) * sensorLength
        };

        SensorHit hit;
        hit.start = position;
        hit.angleOffset = sAngle;
        hit.distance = sensorLength;
        hit.normalizedDist = 1.0f;
        hit.hasHit = false;
        hit.hitPoint = rayEnd;

        float minT = 1.0f;
        Vector2 closestPoint = rayEnd;

        for (const auto& wall : walls) {
            Vector2 currentHit;
            float currentT;
            if (CheckLineIntersection(position, rayEnd, wall.start, wall.end, currentHit, currentT)) {
                if (currentT < minT) {
                    minT = currentT;
                    closestPoint = currentHit;
                    hit.hasHit = true;
                }
            }
        }

        if (hit.hasHit) {
            hit.hitPoint = closestPoint;
            hit.distance = minT * sensorLength;
            hit.normalizedDist = minT;
        }

        sensorHits.push_back(hit);
    }
}

bool Car::CheckCollision(const QuadTree& quadTree) {
    if (!isAlive) return true;

    std::vector<Vector2> corners = GetCorners();

    float minX = std::min({ corners[0].x, corners[1].x, corners[2].x, corners[3].x });
    float maxX = std::max({ corners[0].x, corners[1].x, corners[2].x, corners[3].x });
    float minY = std::min({ corners[0].y, corners[1].y, corners[2].y, corners[3].y });
    float maxY = std::max({ corners[0].y, corners[1].y, corners[2].y, corners[3].y });

    BoundingBox2D carBox = { minX, minY, maxX - minX, maxY - minY };

    std::vector<LineSegment> candidateWalls;
    quadTree.QueryBox(carBox, candidateWalls);

    LineSegment carEdges[4] = {
        { corners[0], corners[1] },
        { corners[1], corners[2] },
        { corners[2], corners[3] },
        { corners[3], corners[0] }
    };

    for (const auto& edge : carEdges) {
        for (const auto& wall : candidateWalls) {
            Vector2 hitPoint;
            float t;
            if (CheckLineIntersection(edge.start, edge.end, wall.start, wall.end, hitPoint, t)) {
                isAlive = false;
                speed = 0.0f;
                return true;
            }
        }
    }

    return false;
}

bool Car::CheckCollision(const std::vector<LineSegment>& walls) {
    if (!isAlive) return true;

    std::vector<Vector2> corners = GetCorners();

    LineSegment carEdges[4] = {
        { corners[0], corners[1] },
        { corners[1], corners[2] },
        { corners[2], corners[3] },
        { corners[3], corners[0] }
    };

    for (const auto& edge : carEdges) {
        for (const auto& wall : walls) {
            Vector2 hitPoint;
            float t;
            if (CheckLineIntersection(edge.start, edge.end, wall.start, wall.end, hitPoint, t)) {
                isAlive = false;
                speed = 0.0f;
                return true;
            }
        }
    }

    return false;
}

void Car::Reset(Vector2 startPos, float startAngle) {
    position = startPos;
    angle = startAngle;
    speed = 0.0f;
    isAlive = true;
    fitness = 0.0f;
    currentCheckpoint = 0;
    distanceTraveled = 0.0f;
    timeAlive = 0.0f;
    timeSinceLastCheckpoint = 0.0f;
    sensorHits.clear();
    lastAiOutputs = { 0.0f, 0.0f };
}

void Car::UpdateManual() {
    if (!isAlive) return;

    if (IsKeyDown(KEY_UP) || IsKeyDown(KEY_W)) {
        speed += acceleration;
        if (speed > maxSpeed) speed = maxSpeed;
    }
    if (IsKeyDown(KEY_DOWN) || IsKeyDown(KEY_S)) {
        speed -= acceleration * 0.8f;
        if (speed < -maxSpeed * 0.4f) speed = -maxSpeed * 0.4f;
    }

    if (std::abs(speed) > 0.05f) {
        float direction = (speed > 0) ? 1.0f : -1.0f;
        if (IsKeyDown(KEY_LEFT) || IsKeyDown(KEY_A))  angle -= turnSpeed * direction;
        if (IsKeyDown(KEY_RIGHT) || IsKeyDown(KEY_D)) angle += turnSpeed * direction;
    }

    speed *= friction;

    float rad = angle * DEG2RAD;
    position.x += std::cos(rad) * speed;
    position.y += std::sin(rad) * speed;
}

void Car::UpdateAI(float throttleInput, float steerInput) {
    if (!isAlive) return;

    speed += throttleInput * acceleration;
    if (speed > maxSpeed) speed = maxSpeed;
    if (speed < -maxSpeed * 0.3f) speed = -maxSpeed * 0.3f;

    if (std::abs(speed) > 0.05f) {
        float direction = (speed > 0) ? 1.0f : -1.0f;
        angle += steerInput * turnSpeed * direction;
    }

    speed *= friction;
    float rad = angle * DEG2RAD;
    position.x += std::cos(rad) * speed;
    position.y += std::sin(rad) * speed;
}

void Car::Draw() const {
    // 1. Rayos sensores (solo si drawSensors está activo para no saturar pantalla en poblaciones)
    if (drawSensors && isAlive) {
        for (const auto& hit : sensorHits) {
            Color rayColor;
            if (hit.hasHit) {
                if (hit.normalizedDist < 0.35f) {
                    rayColor = RED;
                } else if (hit.normalizedDist < 0.70f) {
                    rayColor = ORANGE;
                } else {
                    rayColor = GREEN;
                }

                DrawLineEx(hit.start, hit.hitPoint, 1.5f, Fade(rayColor, 0.85f));
                DrawCircleV(hit.hitPoint, 4.0f, rayColor);
                DrawCircleV(hit.hitPoint, 2.0f, YELLOW);
                DrawCircleLines((int)hit.hitPoint.x, (int)hit.hitPoint.y, 6.0f, RAYWHITE);
            } else {
                DrawLineV(hit.start, hit.hitPoint, Fade(SKYBLUE, 0.3f));
                DrawCircleV(hit.hitPoint, 2.0f, Fade(SKYBLUE, 0.5f));
            }
        }
    }

    // 2. Chasis del vehículo
    Color baseColor;
    if (useCustomColor) {
        baseColor = customColor;
    } else {
        baseColor = (controlMode == ControlMode::Manual) ? manualColor : aiColor;
    }

    Color currentColor = isAlive ? baseColor : Fade(DARKGRAY, 0.25f);

    Rectangle rect = { position.x, position.y, width, height };
    Vector2 origin = { width / 2.0f, height / 2.0f };
    DrawRectanglePro(rect, origin, angle, currentColor);

    if (isAlive) {
        DrawRectangleLinesEx(rect, 1.0f, (controlMode == ControlMode::Manual) ? GOLD : SKYBLUE);

        // Faros delanteros
        float rad = angle * DEG2RAD;
        Vector2 frontRight = {
            position.x + std::cos(rad) * (width / 2.0f) - std::sin(rad) * (height / 3.0f),
            position.y + std::sin(rad) * (width / 2.0f) + std::cos(rad) * (height / 3.0f)
        };
        Vector2 frontLeft = {
            position.x + std::cos(rad) * (width / 2.0f) + std::sin(rad) * (height / 3.0f),
            position.y + std::sin(rad) * (width / 2.0f) - std::cos(rad) * (height / 3.0f)
        };
        DrawCircleV(frontRight, 2.5f, YELLOW);
        DrawCircleV(frontLeft, 2.5f, YELLOW);
    }
}
