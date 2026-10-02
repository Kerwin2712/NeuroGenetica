#include "NeuralNetwork.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

void TestNetworkArchitecture() {
    NeuralNetwork nn(6, 8, 2);
    assert(nn.GetInputCount() == 6);
    assert(nn.GetHiddenCount() == 8);
    assert(nn.GetOutputCount() == 2);

    // Total de pesos: (6 * 8 + 8) + (8 * 2 + 2) = 56 + 18 = 74
    assert(nn.GetTotalWeightsCount() == 74);
    std::cout << "[PASS] TestNetworkArchitecture\n";
}

void TestFeedForwardOutputRange() {
    NeuralNetwork nn(6, 8, 2);
    std::vector<float> inputs = { 0.5f, 0.5f, 0.5f, 0.5f, 0.5f, 0.8f };

    std::vector<float> outputs = nn.FeedForward(inputs);
    assert(outputs.size() == 2);

    // Activación tanh garantiza rango estricto [-1.0, 1.0]
    for (float out : outputs) {
        assert(out >= -1.0f && out <= 1.0f);
    }
    std::cout << "[PASS] TestFeedForwardOutputRange (Salidas en [-1, 1])\n";
}

void TestObstacleAvoidanceSteering() {
    NeuralNetwork nn(6, 8, 2);
    nn.InitializeHeuristicWeights();

    // Caso A: Obstáculo o muro a la IZQUIERDA (sensores 0 y 1 bajos)
    // El auto debe virar hacia la DERECHA (salida de giro > 0)
    std::vector<float> leftWallInputs = { 0.15f, 0.25f, 0.8f, 0.95f, 0.95f, 0.7f };
    std::vector<float> leftOutputs = nn.FeedForward(leftWallInputs);
    assert(leftOutputs[0] > 0.1f); // Giro a la derecha verificado

    // Caso B: Obstáculo o muro a la DERECHA (sensores 3 y 4 bajos)
    // El auto debe virar hacia la IZQUIERDA (salida de giro < 0)
    std::vector<float> rightWallInputs = { 0.95f, 0.95f, 0.8f, 0.25f, 0.15f, 0.7f };
    std::vector<float> rightOutputs = nn.FeedForward(rightWallInputs);
    assert(rightOutputs[0] < -0.1f); // Giro a la izquierda verificado

    std::cout << "[PASS] TestObstacleAvoidanceSteering (Evasión autónoma de muros)\n";
}

void TestFlatWeightsSerialization() {
    NeuralNetwork nn(6, 8, 2);
    std::vector<float> originalWeights = nn.GetFlatWeights();
    assert((int)originalWeights.size() == nn.GetTotalWeightsCount());

    // Crear segunda red y transferir pesos
    NeuralNetwork nn2(6, 8, 2);
    nn2.RandomizeWeights(-2.0f, 2.0f);
    nn2.SetFlatWeights(originalWeights);

    std::vector<float> restoredWeights = nn2.GetFlatWeights();
    for (size_t i = 0; i < originalWeights.size(); ++i) {
        assert(std::abs(originalWeights[i] - restoredWeights[i]) < 1e-6f);
    }
    std::cout << "[PASS] TestFlatWeightsSerialization (Genoma continuo verificado)\n";
}

void TestMutation() {
    NeuralNetwork nn(6, 8, 2);
    std::vector<float> before = nn.GetFlatWeights();

    // Mutación con tasa 1.0 (todos los pesos)
    nn.Mutate(1.0f, 0.5f);
    std::vector<float> after = nn.GetFlatWeights();

    bool hasChanged = false;
    for (size_t i = 0; i < before.size(); ++i) {
        if (std::abs(before[i] - after[i]) > 1e-4f) {
            hasChanged = true;
            break;
        }
    }
    assert(hasChanged);
    std::cout << "[PASS] TestMutation (Mutación gaussiana verificada)\n";
}

int main() {
    std::cout << "=== EJECUTANDO TESTS UNITARIOS: RED NEURONAL FEEDFORWARD ===\n";
    TestNetworkArchitecture();
    TestFeedForwardOutputRange();
    TestObstacleAvoidanceSteering();
    TestFlatWeightsSerialization();
    TestMutation();
    std::cout << "=== TODOS LOS TESTS DE RED NEURONAL PASARON (5/5) ===\n";
    return 0;
}
