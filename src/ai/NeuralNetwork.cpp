#include "NeuralNetwork.hpp"
#include <cmath>
#include <random>
#include <algorithm>

NeuralNetwork::NeuralNetwork(int inputs, int hidden, int outputs)
    : numInputs(inputs),
      numHidden(hidden),
      numOutputs(outputs)
{
    // Dimensionar matrices de pesos y sesgos
    weightsInputHidden.resize(numHidden, std::vector<float>(numInputs, 0.0f));
    biasesHidden.resize(numHidden, 0.0f);

    weightsHiddenOutput.resize(numOutputs, std::vector<float>(numHidden, 0.0f));
    biasesOutput.resize(numOutputs, 0.0f);

    // Por defecto inicializar con pesos heurísticos de evasión de muros
    InitializeHeuristicWeights();
}

float NeuralNetwork::ActivationFunction(float x) {
    // Función tangente hiperbólica: salida suave en el rango [-1.0, 1.0]
    return std::tanh(x);
}

std::vector<float> NeuralNetwork::FeedForward(const std::vector<float>& inputs) const {
    if ((int)inputs.size() < numInputs) {
        return std::vector<float>(numOutputs, 0.0f);
    }

    // 1. Capa Oculta
    std::vector<float> hiddenActivations(numHidden, 0.0f);
    for (int j = 0; j < numHidden; ++j) {
        float sum = biasesHidden[j];
        for (int i = 0; i < numInputs; ++i) {
            sum += weightsInputHidden[j][i] * inputs[i];
        }
        hiddenActivations[j] = ActivationFunction(sum);
    }

    // 2. Capa de Salida
    std::vector<float> outputs(numOutputs, 0.0f);
    for (int k = 0; k < numOutputs; ++k) {
        float sum = biasesOutput[k];
        for (int j = 0; j < numHidden; ++j) {
            sum += weightsHiddenOutput[k][j] * hiddenActivations[j];
        }
        outputs[k] = ActivationFunction(sum);
    }

    return outputs;
}

void NeuralNetwork::InitializeHeuristicWeights() {
    // Inicializar todo en cero antes de calibrar
    for (auto& row : weightsInputHidden) std::fill(row.begin(), row.end(), 0.0f);
    std::fill(biasesHidden.begin(), biasesHidden.end(), 0.0f);
    for (auto& row : weightsHiddenOutput) std::fill(row.begin(), row.end(), 0.0f);
    std::fill(biasesOutput.begin(), biasesOutput.end(), 0.0f);

    // Neurona oculta 0: Balance lateral (sensores izquierdos vs derechos)
    // Sensor 0 (-60°), Sensor 1 (-30°), Sensor 3 (+30°), Sensor 4 (+60°)
    // Si la izquierda está cerca (valor bajo), resta menos -> valor positivo -> gira a la derecha
    weightsInputHidden[0][0] = -1.2f;
    weightsInputHidden[0][1] = -2.0f;
    weightsInputHidden[0][3] =  2.0f;
    weightsInputHidden[0][4] =  1.2f;
    biasesHidden[0] = 0.0f;

    // Neurona oculta 1: Detección frontal de proximidad (Sensor 2)
    weightsInputHidden[1][2] = -2.5f;
    biasesHidden[1] = 0.5f;

    // Neurona oculta 2: Sensor de giro pronunciado ante curvas cerradas
    weightsInputHidden[2][1] = -2.2f;
    weightsInputHidden[2][3] =  2.2f;
    biasesHidden[2] = 0.0f;

    // Conexión a Salida 0 (Dirección: Giro [-1 = Izquierda, +1 = Derecha])
    // Un valor alto en balance lateral produce viraje directo
    weightsHiddenOutput[0][0] = 1.8f;
    weightsHiddenOutput[0][2] = 1.5f;
    biasesOutput[0] = 0.0f;

    // Conexión a Salida 1 (Acelerador: Mantener velocidad constante o moderar en curvas)
    weightsHiddenOutput[1][1] = -0.6f; // Moderar velocidad si hay muro frontal
    biasesOutput[1] = 0.85f;           // Aceleración constante hacia adelante
}

void NeuralNetwork::RandomizeWeights(float minVal, float maxVal) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> dis(minVal, maxVal);

    for (int j = 0; j < numHidden; ++j) {
        for (int i = 0; i < numInputs; ++i) {
            weightsInputHidden[j][i] = dis(gen);
        }
        biasesHidden[j] = dis(gen);
    }

    for (int k = 0; k < numOutputs; ++k) {
        for (int j = 0; j < numHidden; ++j) {
            weightsHiddenOutput[k][j] = dis(gen);
        }
        biasesOutput[k] = dis(gen);
    }
}

void NeuralNetwork::Mutate(float mutationRate, float mutationMagnitude) {
    std::random_device rd;
    std::mt19937 gen(rd());
    std::uniform_real_distribution<float> probDis(0.0f, 1.0f);
    std::normal_distribution<float> noiseDis(0.0f, mutationMagnitude);

    auto mutateVal = [&](float& val) {
        if (probDis(gen) < mutationRate) {
            val += noiseDis(gen);
            // Clamping en rango [-3.0, 3.0]
            val = std::clamp(val, -3.0f, 3.0f);
        }
    };

    for (int j = 0; j < numHidden; ++j) {
        for (int i = 0; i < numInputs; ++i) {
            mutateVal(weightsInputHidden[j][i]);
        }
        mutateVal(biasesHidden[j]);
    }

    for (int k = 0; k < numOutputs; ++k) {
        for (int j = 0; j < numHidden; ++j) {
            mutateVal(weightsHiddenOutput[k][j]);
        }
        mutateVal(biasesOutput[k]);
    }
}

std::vector<float> NeuralNetwork::GetFlatWeights() const {
    std::vector<float> flat;
    flat.reserve(GetTotalWeightsCount());

    for (int j = 0; j < numHidden; ++j) {
        for (int i = 0; i < numInputs; ++i) {
            flat.push_back(weightsInputHidden[j][i]);
        }
        flat.push_back(biasesHidden[j]);
    }

    for (int k = 0; k < numOutputs; ++k) {
        for (int j = 0; j < numHidden; ++j) {
            flat.push_back(weightsHiddenOutput[k][j]);
        }
        flat.push_back(biasesOutput[k]);
    }

    return flat;
}

void NeuralNetwork::SetFlatWeights(const std::vector<float>& flatWeights) {
    if ((int)flatWeights.size() != GetTotalWeightsCount()) return;

    int idx = 0;
    for (int j = 0; j < numHidden; ++j) {
        for (int i = 0; i < numInputs; ++i) {
            weightsInputHidden[j][i] = flatWeights[idx++];
        }
        biasesHidden[j] = flatWeights[idx++];
    }

    for (int k = 0; k < numOutputs; ++k) {
        for (int j = 0; j < numHidden; ++j) {
            weightsHiddenOutput[k][j] = flatWeights[idx++];
        }
        biasesOutput[k] = flatWeights[idx++];
    }
}

int NeuralNetwork::GetTotalWeightsCount() const {
    // (numInputs * numHidden + numHidden) + (numHidden * numOutputs + numOutputs)
    return (numInputs * numHidden + numHidden) + (numHidden * numOutputs + numOutputs);
}
