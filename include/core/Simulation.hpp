#pragma once
#include "raylib.h"
#include "Track.hpp"
#include "Car.hpp"
#include "HUD.hpp"
#include <string>

class Simulation {
public:
    Simulation(int width = 960, int height = 540, const std::string& title = "NeuroGenetica");
    ~Simulation();

    // Bucle principal de ejecución
    void Run();

private:
    void Update();
    void Render();

    int screenWidth;
    int screenHeight;
    std::string windowTitle;

    // Componentes del simulador
    Track track;
    Car playerCar;
    HUD hud;
};
