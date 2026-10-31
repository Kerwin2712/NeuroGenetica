#include "Simulation.hpp"

int main() {
    // Inicialización del simulador con dimensiones y título
    Simulation app(960, 540, "NeuroGenetica");
    
    // Ejecución del bucle principal
    app.Run();

    return 0;
}
