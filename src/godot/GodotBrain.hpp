#pragma once

#include <godot_cpp/classes/ref_counted.hpp>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/variant/packed_float32_array.hpp>
#include <godot_cpp/classes/ref.hpp>

#include "NeuralNetwork.hpp"

namespace godot {

class GodotBrain : public RefCounted {
    GDCLASS(GodotBrain, RefCounted)

private:
    NeuralNetwork brain;

protected:
    static void _bind_methods();

public:
    GodotBrain();
    explicit GodotBrain(int inputs, int hidden, int outputs);
    ~GodotBrain() = default;

    // Propagación hacia adelante: recibe lecturas de sensores y devuelve [dirección, aceleración]
    PackedFloat32Array predict(const PackedFloat32Array& sensor_inputs);

    // Mutación genética
    void mutate(float rate, float magnitude);

    // Inicialización de pesos
    void randomize(float min_val = -1.0f, float max_val = 1.0f);
    void initialize_heuristic();

    // Cruce genético con otra red
    Ref<GodotBrain> crossover(const Ref<GodotBrain>& partner) const;

    // Obtener y asignar pesos planos (para serialización o elitismo)
    PackedFloat32Array get_weights() const;
    void set_weights(const PackedFloat32Array& flat_weights);

    // Consultas de arquitectura
    int get_input_count() const;
    int get_hidden_count() const;
    int get_output_count() const;
    int get_total_weights_count() const;

    // Acceso interno en C++
    NeuralNetwork& get_internal_network() { return brain; }
    const NeuralNetwork& get_internal_network() const { return brain; }
};

} // namespace godot

