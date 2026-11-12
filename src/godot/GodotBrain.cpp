#include "GodotBrain.hpp"

using namespace godot;

void GodotBrain::_bind_methods() {
    ClassDB::bind_method(D_METHOD("predict", "sensor_inputs"), &GodotBrain::predict);
    ClassDB::bind_method(D_METHOD("mutate", "rate", "magnitude"), &GodotBrain::mutate);
    ClassDB::bind_method(D_METHOD("randomize", "min_val", "max_val"), &GodotBrain::randomize, DEFVAL(-1.0f), DEFVAL(1.0f));
    ClassDB::bind_method(D_METHOD("initialize_heuristic"), &GodotBrain::initialize_heuristic);
    ClassDB::bind_method(D_METHOD("crossover", "partner"), &GodotBrain::crossover);
    ClassDB::bind_method(D_METHOD("get_weights"), &GodotBrain::get_weights);
    ClassDB::bind_method(D_METHOD("set_weights", "flat_weights"), &GodotBrain::set_weights);
    ClassDB::bind_method(D_METHOD("get_input_count"), &GodotBrain::get_input_count);
    ClassDB::bind_method(D_METHOD("get_hidden_count"), &GodotBrain::get_hidden_count);
    ClassDB::bind_method(D_METHOD("get_output_count"), &GodotBrain::get_output_count);
    ClassDB::bind_method(D_METHOD("get_total_weights_count"), &GodotBrain::get_total_weights_count);
}

GodotBrain::GodotBrain() : brain(6, 8, 2) {
    brain.RandomizeWeights();
}

GodotBrain::GodotBrain(int inputs, int hidden, int outputs) : brain(inputs, hidden, outputs) {
    brain.RandomizeWeights();
}

PackedFloat32Array GodotBrain::predict(const PackedFloat32Array& sensor_inputs) {
    std::vector<float> inputs;
    inputs.reserve(sensor_inputs.size());
    for (int i = 0; i < sensor_inputs.size(); ++i) {
        inputs.push_back(sensor_inputs[i]);
    }

    std::vector<float> outputs = brain.FeedForward(inputs);

    PackedFloat32Array result;
    for (float val : outputs) {
        result.append(val);
    }
    return result;
}

void GodotBrain::mutate(float rate, float magnitude) {
    brain.Mutate(rate, magnitude);
}

void GodotBrain::randomize(float min_val, float max_val) {
    brain.RandomizeWeights(min_val, max_val);
}

void GodotBrain::initialize_heuristic() {
    brain.InitializeHeuristicWeights();
}

Ref<GodotBrain> GodotBrain::crossover(const Ref<GodotBrain>& partner) const {
    Ref<GodotBrain> child;
    child.instantiate();
    if (partner.is_valid()) {
        child->get_internal_network() = NeuralNetwork::Crossover(this->brain, partner->get_internal_network());
    }
    return child;
}

PackedFloat32Array GodotBrain::get_weights() const {
    std::vector<float> weights = brain.GetFlatWeights();
    PackedFloat32Array result;
    for (float w : weights) {
        result.append(w);
    }
    return result;
}

void GodotBrain::set_weights(const PackedFloat32Array& flat_weights) {
    std::vector<float> weights;
    weights.reserve(flat_weights.size());
    for (int i = 0; i < flat_weights.size(); ++i) {
        weights.push_back(flat_weights[i]);
    }
    brain.SetFlatWeights(weights);
}

int GodotBrain::get_input_count() const {
    return brain.GetInputCount();
}

int GodotBrain::get_hidden_count() const {
    return brain.GetHiddenCount();
}

int GodotBrain::get_output_count() const {
    return brain.GetOutputCount();
}

int GodotBrain::get_total_weights_count() const {
    return brain.GetTotalWeightsCount();
}

