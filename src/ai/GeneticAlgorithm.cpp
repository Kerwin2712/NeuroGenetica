#include "GeneticAlgorithm.hpp"
#include <random>
#include <algorithm>

struct FitnessEntry {
    float fitness;
    int index;

    bool operator<(const FitnessEntry& other) const {
        return fitness < other.fitness;
    }
};

GeneticAlgorithm::GeneticAlgorithm(int popSize, float mutRate, float mutMag)
    : populationSize(popSize),
      mutationRate(mutRate),
      mutationMagnitude(mutMag),
      generation(1),
      generationTimer(0.0f),
      maxGenerationDuration(24.0f),
      spawnPosition{ 250.0f, 465.0f },
      spawnAngle{ 0.0f },
      bestFitnessCurrentGen(0.0f),
      bestFitnessAllTime(0.0f),
      bestCarIndex(0),
      bestBrainAllTime(6, 8, 2)
{
    ResetPopulation();
}

void GeneticAlgorithm::SetSpawnPoint(Vector2 pos, float angle) {
    spawnPosition = pos;
    spawnAngle = angle;
}

void GeneticAlgorithm::ResetPopulation() {
    population.clear();
    population.reserve(populationSize);

    for (int i = 0; i < populationSize; ++i) {
        Car car(spawnPosition, spawnAngle, ControlMode::Autonomous);
        // Cada cerebro empieza 100% aleatorio (sin entrenar)
        car.GetBrain().RandomizeWeights(-1.5f, 1.5f);
        car.SetCustomColor(Fade(SKYBLUE, 0.45f));
        car.SetDrawSensors(false);
        population.push_back(car);
    }

    generation = 1;
    generationTimer = 0.0f;
    bestFitnessCurrentGen = 0.0f;
    bestCarIndex = 0;
}

void GeneticAlgorithm::Update(const Track& track, float dt) {
    generationTimer += dt;
    bestFitnessCurrentGen = -9999.0f;
    bestCarIndex = 0;

    for (size_t i = 0; i < population.size(); ++i) {
        Car& car = population[i];

        if (car.IsAlive()) {
            // 1. Raycasting acelerado por QuadTree
            car.CastSensors(track.GetQuadTree());

            // 2. La red neuronal toma decisiones autónomas
            car.Update();

            // 3. Progreso en checkpoints y fitness
            car.CheckCheckpoints(track.GetCheckpoints(), dt);

            // 4. Detección de colisión contra muros en QuadTree
            car.CheckCollision(track.GetQuadTree());
        }

        // Buscar el auto con mejor fitness de la generación actual
        if (car.GetFitness() > bestFitnessCurrentGen) {
            bestFitnessCurrentGen = car.GetFitness();
            bestCarIndex = (int)i;
        }
    }

    // Configurar el auto líder con color dorado y sensores visibles
    for (size_t i = 0; i < population.size(); ++i) {
        if ((int)i == bestCarIndex && population[i].IsAlive()) {
            population[i].SetCustomColor(GOLD);
            population[i].SetDrawSensors(true);
        } else {
            population[i].SetCustomColor(Fade(SKYBLUE, 0.40f));
            population[i].SetDrawSensors(false);
        }
    }

    // Si todos los autos colisionaron o se agotó el tiempo máximo, evolucionar
    if (IsGenerationComplete()) {
        EvolveNextGeneration();
    }
}

bool GeneticAlgorithm::IsGenerationComplete() const {
    return (GetAliveCount() == 0 || generationTimer >= maxGenerationDuration);
}

int GeneticAlgorithm::GetAliveCount() const {
    int count = 0;
    for (const auto& car : population) {
        if (car.IsAlive()) count++;
    }
    return count;
}

void GeneticAlgorithm::EvolveNextGeneration() {
    // 1. Estructura de Datos Avanzada: Max-Heap para ordenar y seleccionar en O(k log n)
    MaxHeap<FitnessEntry> maxHeap;
    for (int i = 0; i < populationSize; ++i) {
        maxHeap.Push({ population[i].GetFitness(), i });
    }

    // 2. Extraer a los mejores individuos (Top Elitismo)
    int eliteCount = std::max(2, populationSize / 8);
    std::vector<NeuralNetwork> eliteBrains;
    eliteBrains.reserve(eliteCount);

    for (int e = 0; e < eliteCount && !maxHeap.IsEmpty(); ++e) {
        FitnessEntry best = maxHeap.PopMax();
        eliteBrains.push_back(population[best.index].GetBrain());

        if (e == 0 && best.fitness > bestFitnessAllTime) {
            bestFitnessAllTime = best.fitness;
            bestBrainAllTime = population[best.index].GetBrain();
        }
    }

    // 3. Generar nueva generación mediante Cruce (Crossover) y Mutación
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_int_distribution<int> eliteDist(0, (int)eliteBrains.size() - 1);

    std::vector<NeuralNetwork> nextGenerationBrains;
    nextGenerationBrains.reserve(populationSize);

    for (int i = 0; i < eliteCount; ++i) {
        nextGenerationBrains.push_back(eliteBrains[i]);
    }

    while ((int)nextGenerationBrains.size() < populationSize) {
        int parentA = eliteDist(gen);
        int parentB = eliteDist(gen);

        NeuralNetwork child = NeuralNetwork::Crossover(eliteBrains[parentA], eliteBrains[parentB]);
        child.Mutate(mutationRate, mutationMagnitude);
        nextGenerationBrains.push_back(child);
    }

    // 4. Asignar los nuevos cerebros y reiniciar posición a la línea de salida del circuito
    for (int i = 0; i < populationSize; ++i) {
        population[i].Reset(spawnPosition, spawnAngle);
        population[i].SetBrain(nextGenerationBrains[i]);
        population[i].SetControlMode(ControlMode::Autonomous);
        population[i].SetCustomColor(Fade(SKYBLUE, 0.40f));
        population[i].SetDrawSensors(false);
    }

    generation++;
    generationTimer = 0.0f;
    bestFitnessCurrentGen = 0.0f;
    bestCarIndex = 0;
}

void GeneticAlgorithm::Draw() const {
    for (size_t i = 0; i < population.size(); ++i) {
        if (!population[i].IsAlive()) {
            population[i].Draw();
        }
    }

    for (size_t i = 0; i < population.size(); ++i) {
        if (population[i].IsAlive() && (int)i != bestCarIndex) {
            population[i].Draw();
        }
    }

    if (bestCarIndex >= 0 && bestCarIndex < (int)population.size()) {
        population[bestCarIndex].Draw();
    }
}
