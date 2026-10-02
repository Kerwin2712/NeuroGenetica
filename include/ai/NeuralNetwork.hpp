#pragma once
#include <vector>
#include <string>

class NeuralNetwork {
public:
    NeuralNetwork(int numInputs = 6, int numHidden = 8, int numOutputs = 2);
    ~NeuralNetwork() = default;

    // Propagación hacia adelante: recibe entradas normalizadas y calcula salidas [-1, 1]
    std::vector<float> FeedForward(const std::vector<float>& inputs) const;

    // Inicializa la red con pesos totalmente aleatorios (comportamiento sin entrenar)
    void RandomizeWeights(float minVal = -1.0f, float maxVal = 1.0f);

    // Inicializa la red con pesos calibrados de prueba (opcional)
    void InitializeHeuristicWeights();

    // Mutación gaussiana en pesos y sesgos con tasa y magnitud
    void Mutate(float mutationRate, float mutationMagnitude);

    // Operador de cruce genético (Crossover uniforme entre 2 redes progenitoras)
    static NeuralNetwork Crossover(const NeuralNetwork& parentA, const NeuralNetwork& parentB);

    // Aplanar y reconstruir genoma completo de la red
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
