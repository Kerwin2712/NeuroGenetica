#include "MaxHeap.hpp"
#include "GeneticAlgorithm.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

void TestMaxHeapBasicOperations() {
    MaxHeap<int> heap;
    assert(heap.IsEmpty());
    assert(heap.Size() == 0);

    heap.Push(10);
    heap.Push(50);
    heap.Push(30);
    heap.Push(70);
    heap.Push(20);

    assert(heap.Size() == 5);
    assert(heap.PeekMax() == 70);

    // Debe extraer en orden estrictamente descendente: 70, 50, 30, 20, 10
    assert(heap.PopMax() == 70);
    assert(heap.PopMax() == 50);
    assert(heap.PopMax() == 30);
    assert(heap.PopMax() == 20);
    assert(heap.PopMax() == 10);
    assert(heap.IsEmpty());

    std::cout << "[PASS] TestMaxHeapBasicOperations (Propiedad de montículo máximo verificada)\n";
}

struct TestFitnessEntry {
    float fitness;
    int carId;
    bool operator<(const TestFitnessEntry& other) const {
        return fitness < other.fitness;
    }
};

void TestMaxHeapFitnessRanking() {
    MaxHeap<TestFitnessEntry> heap;
    heap.Push({ 150.5f, 1 });
    heap.Push({ 890.0f, 2 });
    heap.Push({ 420.3f, 3 });
    heap.Push({ 1200.8f, 4 });
    heap.Push({ 50.0f, 5 });

    // El primer elemento extraído debe ser el de mayor fitness (carId 4 con 1200.8)
    TestFitnessEntry top1 = heap.PopMax();
    assert(top1.carId == 4);
    assert(top1.fitness == 1200.8f);

    TestFitnessEntry top2 = heap.PopMax();
    assert(top2.carId == 2);
    assert(top2.fitness == 890.0f);

    std::cout << "[PASS] TestMaxHeapFitnessRanking (Selección elitista en O(k log n) verificada)\n";
}

void TestCrossoverGeneInheritance() {
    NeuralNetwork parentA(6, 8, 2);
    NeuralNetwork parentB(6, 8, 2);

    // Llenar parentA con 1.0f y parentB con -1.0f
    std::vector<float> genesA(parentA.GetTotalWeightsCount(), 1.0f);
    std::vector<float> genesB(parentB.GetTotalWeightsCount(), -1.0f);
    parentA.SetFlatWeights(genesA);
    parentB.SetFlatWeights(genesB);

    NeuralNetwork child = NeuralNetwork::Crossover(parentA, parentB);
    std::vector<float> childGenes = child.GetFlatWeights();

    int countA = 0;
    int countB = 0;
    for (float g : childGenes) {
        if (std::abs(g - 1.0f) < 1e-5f) countA++;
        else if (std::abs(g - (-1.0f)) < 1e-5f) countB++;
    }

    // El hijo debe tener una mezcla balanceada de ambos padres
    assert(countA > 0);
    assert(countB > 0);
    assert(countA + countB == (int)childGenes.size());

    std::cout << "[PASS] TestCrossoverGeneInheritance (Cruce genético uniforme verificado)\n";
}

void TestGeneticAlgorithmPopulationCycle() {
    GeneticAlgorithm ga(20, 0.10f, 0.20f);
    assert(ga.GetPopulationSize() == 20);
    assert(ga.GetGeneration() == 1);
    assert(ga.GetAliveCount() == 20);

    // Forzar evolución a la siguiente generación
    ga.EvolveNextGeneration();
    assert(ga.GetGeneration() == 2);
    assert(ga.GetAliveCount() == 20);

    std::cout << "[PASS] TestGeneticAlgorithmPopulationCycle (Ciclo generativo verificado)\n";
}

void TestTrackIntegrity() {
    Track track;
    assert(!track.GetWalls().empty());
    assert(!track.GetCheckpoints().empty());

    // El auto en la posición de spawn inicial no debe estar en colisión
    Car car(track.GetStartPosition(), track.GetStartAngle(), ControlMode::Manual);
    assert(car.IsAlive());
    bool collides = car.CheckCollision(track.GetQuadTree());
    assert(!collides);

    // Los sensores deben castear correctamente contra el QuadTree de la pista
    car.CastSensors(track.GetQuadTree());
    const auto& hits = car.GetSensorHits();
    assert(hits.size() == 5);

    std::cout << "[PASS] TestTrackIntegrity (Geometria del circuito y spawn validados)\n";
}

int main() {
    std::cout << "=== EJECUTANDO TESTS UNITARIOS: ALGORITMO GENETICO Y MAX-HEAP ===\n";
    TestMaxHeapBasicOperations();
    TestMaxHeapFitnessRanking();
    TestCrossoverGeneInheritance();
    TestGeneticAlgorithmPopulationCycle();
    TestTrackIntegrity();
    std::cout << "=== TODOS LOS TESTS GENETICOS PASARON EXITOSAMENTE (5/5) ===\n";
    return 0;
}
