#pragma once
#include "Car.hpp"
#include "Track.hpp"
#include "MaxHeap.hpp"
#include <vector>
#include <memory>

class GeneticAlgorithm {
public:
    GeneticAlgorithm(int popSize = 40, float mutRate = 0.10f, float mutMag = 0.30f);
    ~GeneticAlgorithm() = default;

    // Configurar punto de partida y ángulo de spawn
    void SetSpawnPoint(Vector2 pos, float angle);

    // Actualiza la física, sensores, checkpoints y detección de colisiones de toda la población
    void Update(const Track& track, float dt);

    // Dibuja la población en pantalla, destacando al auto líder
    void Draw() const;

    // Evoluciona la población seleccionando a los mejores mediante Max-Heap
    void EvolveNextGeneration();

    // Reinicia la población con nuevas redes aleatorias (Generación 1)
    void ResetPopulation();

    // Consultas de estado
    bool IsGenerationComplete() const;
    int GetAliveCount() const;
    int GetPopulationSize() const { return populationSize; }
    int GetGeneration() const { return generation; }
    float GetBestFitnessCurrentGen() const { return bestFitnessCurrentGen; }
    float GetBestFitnessAllTime() const { return bestFitnessAllTime; }
    int GetBestCarIndex() const { return bestCarIndex; }
    float GetGenerationTimer() const { return generationTimer; }

private:
    int populationSize;
    float mutationRate;
    float mutationMagnitude;
    int generation;
    float generationTimer;
    float maxGenerationDuration;

    Vector2 spawnPosition;
    float spawnAngle;

    float bestFitnessCurrentGen;
    float bestFitnessAllTime;
    int bestCarIndex;
    NeuralNetwork bestBrainAllTime;

    std::vector<Car> population;
};
