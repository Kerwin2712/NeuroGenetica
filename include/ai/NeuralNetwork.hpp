#pragma once
#include <vector>
#include <string>

class NeuralNetwork {
public:
    NeuralNetwork(int numInputs = 6, int numHidden = 8, int numOutputs = 2);
    ~NeuralNetwork() = default;

    // Propagación hacia adelante: recibe entradas normalizadas y calcula salidas [-1, 1]
    std::vector<float> FeedForward(const std::vector<float>& inputs) const;

    // Inicializa la red con pesos calibrados para esquivar muros y navegar el circuito
    void InitializeHeuristicWeights();

    // Inicializa la red con pesos totalmente aleatorios (para evolución genética)
    void RandomizeWeights(float minVal = -1.0f, float maxVal = 1.0f);

    // Mutación gaussiana en pesos y sesgos (para Fase 4)
    void Mutate(float mutationRate, float mutationMagnitude);

    // Aplanar todos los pesos y sesgos en un vector continuo (para cruce genético)
    std::vector<float> GetFlatWeights() const;
    void SetFlatWeights(const std::vector<float>& flatWeights);

    // Getters de arquitectura
    int GetInputCount() const { return numInputs; }
    int GetHiddenCount() const { return numHidden; }
    int GetOutputCount() const { return numOutputs; }
    int GetTotalWeightsCount() const;

private:
    static float ActivationFunction(float x);

    int numInputs;
    int numHidden;
    int numOutputs;

    // Matriz de pesos Capa Entrada -> Capa Oculta [numHidden x numInputs]
    std::vector<std::vector<float>> weightsInputHidden;
    std::vector<float> biasesHidden;

    // Matriz de pesos Capa Oculta -> Capa Salida [numOutputs x numHidden]
    std::vector<std::vector<float>> weightsHiddenOutput;
    std::vector<float> biasesOutput;
};
