# NeuroGenetica 🏎️🧠

Simulación de vehículos autónomos en **C++** que aprenden a conducir en circuitos mediante **Redes Neuronales** y **Algoritmos Genéticos (Neuroevolución)**, optimizados con **estructuras de datos avanzadas (Árboles / QuadTrees y Heaps)** para la materia *Programación 3*.

---

## 🎯 Objetivos del Proyecto (Programación 3)

- **Estructuras de Datos Avanzadas**:
  - **QuadTree (Árbol de partición espacial 2D)**: Almacena los segmentos y límites de la pista para optimizar el cálculo de colisiones y el raycasting de sensores en tiempo $O(\log n)$ en lugar de $O(n \times m)$.
  - **Max-Heap / Cola de Prioridad**: Ordenamiento y selección eficiente del top de individuos por fitness para elitismo y cruce genético en tiempo $O(k \log n)$.
- **Programación Orientada a Objetos (POO)**: Arquitectura limpia, modular y desacoplada en C++ moderno (C++17/20).
- **Pruebas Unitarias Obligatorias**: Validación rigurosa de cada estructura de datos y módulo lógico mediante tests unitarios antes de integrarlos a la simulación visual.
- **Flujo de Trabajo Git con Commits Atómicos**: Cada commit debe ser pequeño, autocontenido, funcional y explicar claramente qué cambia, evitando commits masivos o desordenados.
- **Optimización y Rendimiento**: Capacidad de simular decenas o cientos de vehículos en paralelo a altos FPS o en modo acelerado.

---

## ⚙️ Arquitectura del Sistema

```
                        ┌───────────────────────────────────┐
                        │           Engine / Main           │
                        └─────────────────┬─────────────────┘
                                          │
                  ┌───────────────────────┼───────────────────────┐
                  ▼                       ▼                       ▼
        ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
        │      Track       │    │    Population    │    │     Renderer     │
        │ - QuadTree       │    │ - GeneticAlg     │    │ - Raylib Window  │
        │ - Checkpoints    │    │ - Max-Heap Rank  │    │ - HUD & Stats    │
        └─────────┬────────┘    └─────────┬────────┘    └──────────────────┘
                  │                       │
                  │              ┌────────┴────────┐
                  ▼              ▼                 ▼
          ┌───────────────┐ ┌───────────────┐ ┌───────────────┐
          │   QuadTree    │ │      Car      │ │ NeuralNetwork │
          │ (Partición    │ │ - Sensores    │ │ - Capas       │
          │  espacial 2D) │ │ - Cinemática  │ │ - Pesos/Biases│
          └───────────────┘ └───────────────┘ └───────────────┘
```

### Componentes Clave

1. **`Car` (Vehículo)**:
   - Estado físico: posición $(x, y)$, ángulo de rotación $\theta$, velocidad lineal y angular.
   - Detección: 5 a 7 rayos de sensores (raycasting) que miden la distancia normalizada $[0, 1]$ a los bordes.
   - Estado de vida: activo o colisionado.
2. **`NeuralNetwork` (Cerebro)**:
   - Arquitectura Feedforward:
     - **Entradas**: Distancias de sensores (5–7) + Velocidad actual.
     - **Capa Oculta**: 6–8 neuronas con función de activación ReLU o Tanh.
     - **Salidas**: 2 valores (Dirección: izquierda/derecha, Aceleración: acelerar/frenar).
3. **`GeneticAlgorithm` (Evolución)**:
   - Población de $N$ agentes (ej. 50–100 autos).
   - **Función de Fitness**: Basada en checkpoints alcanzados + distancia recorrida - penalizaciones por tiempo detenido o colisión prematura.
   - **Operadores Genéticos**: Selección por torneo/elitismo (usando Max-Heap), Cruce (Crossover uniforme/aritmético) y Mutación Gaussiana en pesos y sesgos.
4. **`QuadTree` (Estructura de Árbol Espacial)**:
   - Subdivide el espacio 2D en cuadrantes recursivos.
   - Almacena los segmentos de línea de las paredes de la pista.
   - Provee consultas rápidas `queryRange()` para encontrar únicamente los segmentos cercanos a cada rayo del sensor.
5. **`Track` (Pista y Checkpoints)**:
   - Define los bordes internos y externos del circuito.
   - Secuencia ordenada de checkpoints invisibles para guiar y calcular el fitness sin premiar giros en círculos.
6. **`Renderer` (Visualización)**:
   - Basado en **Raylib** (o librería gráfica C++ seleccionada).
   - Renderizado en dos etapas: inicial con primitivas geométricas (rectángulos y líneas de rayos) y posterior con texturas/sprites.

---

## 👥 Distribución del Equipo (3 Integrantes)

> [!IMPORTANT]
> **Normas Obligatorias para los 3 Integrantes**:
> 1. **Commits Atómicos**: Cada integrante DEBE realizar commits pequeños, independientes y con mensajes descriptivos bajo estándar Conventional Commits (`feat: ...`, `fix: ...`, `test: ...`). **Prohibido hacer commits masivos** con días de trabajo acumulados o subir código que no compile.
> 2. **Tests Unitarios Obligatorios**: Todo algoritmo, estructura de datos y módulo lógico desarrollado por cada integrante **DEBE incluir sus pruebas unitarias en `tests/`** antes de conectarse al simulador gráfico.

---

### 👤 Integrante 1: Física, Sensores y Estructuras Espaciales (Árboles)
- **Módulos a desarrollar**:
  - Cinemática del auto (`Car`): posición, ángulo, aceleración, fricción y viraje.
  - Estructura de datos **QuadTree**: partición espacial 2D recursiva para los segmentos del circuito.
  - Sistema de **Raycasting** (`SensorSystem`): proyección de rayos de distancia usando el QuadTree para consultas rápidas $O(\log n)$.
  - Detección de colisiones de los autos contra los muros de la pista.
- **🧪 Tests Unitarios que DEBE entregar (en `tests/`)**:
  - `test_quadtree`: Inserción de límites, partición en 4 cuadrantes y consultas `queryRange()` precisas.
  - `test_raycasting`: Intersección matemática correcta entre rayos y segmentos de pared.
  - `test_car_physics`: Verificación de límites de aceleración, fricción y rotación.
- **📦 Ejemplos de Commits Atómicos esperados**:
  - `feat(car): implementar cinemática básica y rotación de vehículo`
  - `test(car): añadir pruebas unitarias de movimiento y fricción`
  - `feat(quadtree): implementar estructura nodo y división espacial 2D`
  - `feat(quadtree): agregar inserción de segmentos y consulta de rango`
  - `test(quadtree): añadir tests unitarios de partición e intersección`
  - `feat(sensors): integrar raycasting conectado al quadtree`

---

### 👤 Kerwin Quintero: Red Neuronal y Algoritmo Genético
- **Módulos a desarrollar**:
  - Red Neuronal Feedforward (`NeuralNetwork`): capas, matrices de pesos, sesgos y función de activación (ReLU/Tanh).
  - Algoritmo Genético (`GeneticAlgorithm`): población de cerebros, cruce (crossover) y mutación gaussiana.
  - Estructura de datos **Max-Heap** (`PriorityQueue`): ranking y selección eficiente de individuos por fitness.
  - Serialización: guardar y cargar en archivo el mejor cerebro entrenado.
- **🧪 Tests Unitarios que DEBE entregar (en `tests/`)**:
  - `test_neural_network`: Propagación hacia adelante (*forward pass*), dimensiones de salidas y consistencia matemática.
  - `test_max_heap`: Operaciones `push`, `popMax` y garantía de orden de prioridad por fitness.
  - `test_genetic_operators`: Verificación de rangos válidos tras mutación y herencia de pesos en cruce.
- **📦 Ejemplos de Commits Atómicos esperados**:
  - `feat(nn): estructurar capas, matrices de pesos y sesgos iniciales`
  - `feat(nn): implementar propagación hacia adelante con activación`
  - `test(nn): añadir tests unitarios de forward pass y consistencia`
  - `feat(heap): implementar max-heap para ordenamiento de fitness`
  - `test(heap): añadir tests unitarios para extracción de mejores individuos`
  - `feat(ga): implementar operadores de mutación y cruce genético`
  - `feat(io): implementar serialización del mejor modelo a archivo`

---

### 👤 Integrante 3: Motor Gráfico, Circuito e Interfaz (HUD)
- **Módulos a desarrollar**:
  - Ciclo principal y ventana con **Raylib**.
  - Circuito y Checkpoints (`Track`): trazado de muros y secuencia de checkpoints para guiar a los autos.
  - Función de Fitness: cálculo de puntaje según checkpoints alcanzados y tiempo/distancia.
  - Interfaz gráfica (`HUD`): métricas en tiempo real (generación, vivos/muertos, mejor fitness, FPS).
  - Controles de simulación: pausa, reinicio de generación y avance rápido ($\times 2, \times 5, \times 10$).
  - Transición visual: soporte para reemplazar figuras geométricas por texturas/sprites.
- **🧪 Tests Unitarios que DEBE entregar (en `tests/`)**:
  - `test_checkpoints`: Validación de que los checkpoints solo se registren en orden secuencial (sistema anti-trampas).
  - `test_fitness_calc`: Verificación matemática del puntaje asignado según avance y penalizaciones.
- **📦 Ejemplos de Commits Atómicos esperados**:
  - `feat(engine): configurar ventana y game loop a 60 fps con raylib`
  - `feat(track): definir bordes geométricos y secuencia de checkpoints`
  - `test(track): añadir tests unitarios para validación secuencial de checkpoints`
  - `feat(fitness): implementar algoritmo de cálculo de puntaje`
  - `test(fitness): añadir tests unitarios del sistema de fitness`
  - `feat(hud): agregar panel con métricas de la generación en vivo`
  - `feat(assets): integrar soporte para sprites de vehículos y fondo de pista`

---

## 🗺️ Fases de Desarrollo

### Fase 1: Prototipo Base y Control Manual
- [ ] Configurar proyecto C++ con CMake y Raylib.
- [ ] Crear la ventana, bucle de juego a 60 FPS y fondo básico.
- [ ] Representar el auto como un rectángulo simple con rotación y aceleración controlable con teclado (WASD / Flechas).

### Fase 2: Circuito, QuadTree y Sensores
- [ ] Definir el circuito mediante polígonos/segmentos de línea (bordes interiores y exteriores).
- [ ] Implementar la estructura **QuadTree** en C++ para indexar los segmentos de la pista.
- [ ] Implementar el sistema de sensores del auto (rayos que proyectan líneas e intersectan la pista mediante el QuadTree).
- [ ] Dibujar visualmente los rayos del sensor y marcar el punto de colisión.

### Fase 3: Red Neuronal y Conducción Automática
- [ ] Implementar la clase `NeuralNetwork` (capa de entrada, capa oculta, capa de salida).
- [ ] Conectar las lecturas de los sensores como inputs de la red.
- [ ] Mapear los outputs de la red neuronal a los controles del auto (girar y acelerar).
- [ ] Probar la propagación hacia adelante con un auto individual y pesos aleatorios.

### Fase 4: Neuroevolución y Checkpoints (Algoritmo Genético)
- [ ] Implementar checkpoints en la pista para medir progreso real en el circuito.
- [ ] Crear la población de $N$ autos simultáneos con cerebros independientes.
- [ ] Calcular la función de fitness (checkpoints superados + distancia).
- [ ] Implementar el ciclo generativo: evaluar generación $\to$ seleccionar mejores con **Max-Heap** $\to$ crossover $\to$ mutación $\to$ reiniciar posición.

### Fase 5: Optimización, UI y Texturas Finales
- [ ] Integrar sprites de vehículos e imagen de pista (generadas con IA o diseñadas).
- [ ] Diseñar panel HUD con estadísticas en vivo de la evolución.
- [ ] Añadir selector de velocidad de simulación (entrenamiento acelerado sin limitar a 60 FPS).
- [ ] Exportación/importación del mejor modelo genético a archivo `.json` o binario.

---

## 📂 Estructura del Repositorio

```
NeuroGenetica/
├── CMakeLists.txt              # Configuración de compilación CMake
├── README.md                   # Documentación principal del proyecto
├── assets/                     # Sprites, texturas y fuentes
│   ├── cars/                   # Texturas de vehículos
│   └── tracks/                 # Fondos y circuitos
├── include/                    # Archivos de cabecera (.hpp / .h)
│   ├── core/
│   │   ├── Car.hpp             # Clase auto y cinemática
│   │   ├── SensorSystem.hpp    # Sensores y rayos
│   │   ├── Track.hpp           # Pista y checkpoints
│   │   └── QuadTree.hpp        # Estructura de árbol de partición espacial
│   ├── ai/
│   │   ├── NeuralNetwork.hpp   # Red neuronal feedforward
│   │   ├── GeneticAlgorithm.hpp# Lógica genética (cruce, mutación)
│   │   └── PriorityQueue.hpp   # Heap para selección de fitness
│   └── graphics/
│       ├── Renderer.hpp        # Métodos de dibujo y cámara
│       └── HUD.hpp             # Interfaz con métricas y gráficas
├── src/                        # Implementación (.cpp)
│   ├── core/
│   ├── ai/
│   ├── graphics/
│   └── main.cpp                # Punto de entrada
└── tests/                      # Pruebas unitarias (QuadTree, Red Neuronal, etc.)
```

---

## 🛠️ Tecnologías y Dependencias

- **Lenguaje**: C++17 o superior.
- **Compilador recomendado**: MinGW-w64 (GCC 11+) / MSVC / Clang.
- **Sistema de compilación**: CMake 3.15+.
- **Librería gráfica**: [Raylib](https://www.raylib.com/) (ligera, ideal para C++, sin dependencias pesadas y fácil integración con CMake `FetchContent`).

---

## 🚀 Compilación y Ejecución

### 1. Clonar el repositorio
```bash
git clone https://github.com/Kerwin2712/NeuroGenetica.git
cd NeuroGenetica
```

### 2. Configurar y compilar con CMake

**En Windows (MinGW / PowerShell):**
```powershell
cmake -B build -G "MinGW Makefiles"
cmake --build build
```

### 3. Ejecutar
```powershell
./build/NeuroGenetica.exe
```

---

## 🧪 Puntos Clave de Evaluación (Docente / Exposición)

1. **¿Por qué un QuadTree?** Reduce la complejidad temporal de verificar cada sensor contra cada segmento de la pista de $O(S \times P)$ a $O(S \times \log P)$, permitiendo simular 100+ autos simultáneos sin caídas de rendimiento.
2. **¿Cómo aprende el auto?** No usa backpropagation clásico; utiliza Neuroevolución. La red neuronal toma decisiones en tiempo real y el algoritmo genético premia a las redes que completan más sectores de la pista.
3. **Control anti-trampas en Fitness**: El sistema de checkpoints impide que los autos den vueltas en círculos o retrocedan para acumular puntos falsos.
