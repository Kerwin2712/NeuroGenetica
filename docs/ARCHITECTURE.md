# 🏛️ Arquitectura de Software y Organización de Archivos

Este documento describe la arquitectura modular híbrida (**Godot Engine 4 + C++17 GDExtension**), los patrones de diseño y la estructura completa de archivos que conforman el proyecto **NeuroGenetica**, incluyendo su núcleo evolutivo original en 2D y su suite de pruebas unitarias.

---

## 📐 Visión General de la Arquitectura Actual (3D + GDExtension)

El sistema aplica el principio de **Responsabilidad Única (SRP)** y desacopla la simulación tridimensional (renderizado, físicas, cámaras e interfaz en **Godot Engine 4**) del cómputo de inteligencia artificial (redes neuronales y algoritmos genéticos compilados de forma nativa en **C++17** mediante **GDExtension**):

```
                      ┌─────────────────────────────────────────────┐
                      │         Godot Engine 4 (Main3D.tscn)        │
                      │       SimulationManager3D.gd (Orquestador)  │
                      └──────────────────────┬──────────────────────┘
                                             │
        ┌────────────────────────────────────┼────────────────────────────────────┐
        ▼                                    ▼                                    ▼
┌─────────────────────┐          ┌───────────────────────┐          ┌─────────────────────┐
│   Capa Escenario    │          │   Capa Agentes 3D     │          │  Capa Presentación  │
│  (Geometría 3D)     │          │ (Física y Sensores)   │          │  (Cámara y UI)      │
└──────────┬──────────┘          └───────────┬───────────┘          └──────────┬──────────┘
           │                                 │                                 │
┌──────────┴──────────┐          ┌───────────┴───────────┐          ┌──────────┴──────────┐
│ - Track3D.gd        │          │ - Car3D.gd (100 HP)   │          │ - CameraRig3D.gd    │
│ - SpatialTree3D.gd  │          │ - Raycasting (d²,1/R) │          │ - Menú / Semáforo   │
│   (AABB O(log P))   │          │ - MaxHeap.gd O(k lgN) │          │ - Telemetría (I)    │
└─────────────────────┘          └───────────┬───────────┘          │ - Podio / JSON (G)  │
                                             │                      └─────────────────────┘
                                             │ puente nativo DLL (.gdextension)
                                             ▼
                                 ┌───────────────────────┐
                                 │  Núcleo C++17 Nativo  │
                                 │  (src/godot + src/ai) │
                                 │ - GodotBrain.cpp/.hpp │
                                 │ - NeuralNetwork.cpp   │
                                 │ - GeneticAlgorithm    │
                                 │ - MaxHeap.hpp         │
                                 └───────────────────────┘
```

> [!NOTE]
> **Arquitectura Legada 2D (Raylib)**: Las carpetas `src/core/`, `src/graphics/` y `src/main.cpp` conservan el prototipo 2D original compilable con CMake + Raylib 5.5, sobre el cual se construyeron y validan las suites de pruebas unitarias C++ (`tests/`).

---

## 📂 Árbol de Directorios y Responsabilidades

```text
NeuroGenetica/
├── SConstruct                        # Script de compilación SCons para GDExtension C++17
├── CMakeLists.txt                    # Configuración CMake para tests unitarios (CTest) y prototipo 2D
├── ejecutar_juego_godot.bat          # Lanzador directo del juego 3D en Godot Engine 4
├── abrir_editor_godot.bat            # Lanzador del proyecto en el Editor de Godot 4
├── compilar_libreria_godot.bat       # Compilador automático de la librería nativa C++ GDExtension
├── README.md                         # Visión general, línea de tiempo y guía rápida
│
├── godot_project/                    # Proyecto Principal 3D en Godot Engine 4
│   ├── project.godot                 # Configuración de ventana (1152×648 centrada) y escena principal
│   ├── bin/                          # Librería nativa C++ compilada (.dll) y descriptor .gdextension
│   │   ├── neurogenetica.gdextension # Mapeo de entrada del puente GDExtension
│   │   └── liblibneurogenetica...dll # Binario nativo de GodotBrain + NeuralNetwork
│   ├── scenes/                       # Escenas tridimensionales y de respaldo
│   │   ├── Main3D.tscn               # Escena principal 3D (pista, parrilla, luces, cámara y HUD)
│   │   └── Car3D.tscn                # Prefab 3D del vehículo (chasis, ruedas, faros y colisionador)
│   ├── scripts/                      # Lógica 3D, estructuras espaciales y UI en GDScript
│   │   ├── SimulationManager3D.gd    # Orquestador: Menú, Copa, Semáforo, Podio, Telemetría y JSON
│   │   ├── Track3D.gd                # Circuito 3D de 4 carriles, muros y depuración de cuadrantes
│   │   ├── Car3D.gd                  # Física 3D, daño HP y sensores optimizados (d² y 1/R)
│   │   ├── SpatialTree3D.gd          # Árbol de partición espacial 3D (AABB, 0 asignaciones en heap)
│   │   ├── MaxHeap.gd                # Montículo Máximo (Cola de Prioridad) para podio y elitismo
│   │   └── CameraRig3D.gd            # 4 vistas: GTA Cenital, Isométrica Libre/Auto y 3ª Persona
│   └── saved_teams/                  # Escuderías pre-entrenadas y generaciones guardadas (.json)
│       ├── Escuderia_Novatos.json
│       ├── Escuderia_GT_Pro.json
│       └── Escuderia_Elite_Leyendas.json
│
├── src/                              # Código Fuente Nativo en C++17
│   ├── godot/                        # Puente GDExtension (C++17 ↔ Godot 4)
│   │   ├── GodotBrain.hpp / .cpp     # Clase expuesta a Godot: Think(), Mutate(), Crossover(), JSON
│   │   └── register_types.hpp / .cpp # Registro de clases nativas en el ciclo de carga de Godot
│   ├── ai/                           # Núcleo de Inteligencia Artificial (Compartido 3D y 2D)
│   │   ├── NeuralNetwork.cpp         # Red neuronal Feedforward densa, activación tanh y mutación
│   │   └── GeneticAlgorithm.cpp      # Evolución poblacional y selección elitista con MaxHeap
│   ├── core/                         # Prototipo histórico 2D (QuadTree, Track, Car, Simulation)
│   ├── graphics/                     # Renderizador histórico 2D (HUD, CarCamera en Raylib)
│   └── main.cpp                      # Punto de entrada del prototipo histórico 2D
│
├── include/                          # Cabeceras C++17 (.hpp) de las capas ai/, core/ y graphics/
├── tests/                            # Pruebas unitarias independientes (CTest)
│   ├── test_quadtree.cpp             # Subdivisión, consultas y podado espacial
│   ├── test_neural_network.cpp       # Topología, forward pass tanh y mutación
│   └── test_genetic_algorithm.cpp    # Propiedad Max-Heap, elitismo y ciclo generativo
│
└── docs/                             # Documentación Técnica Oficial
    ├── showcase.html                 # Portal web dinámico (lee los .md en vivo con KaTeX)
    ├── README.md                     # Índice de la documentación
    ├── GUIA_GODOT.md                 # Manual de usuario del motor 3D
    ├── ARCHITECTURE.md               # Este documento
    ├── DATA_STRUCTURES.md            # Análisis formal de SpatialTree3D, QuadTree y MaxHeap
    └── AI_AND_PHYSICS.md             # Ecuaciones cinemáticas, sensores y neuroevolución
```

---

## 🔍 Detalle por Módulos Clave

### 1. Motor 3D en Godot (`godot_project/scripts/`)

- **`SimulationManager3D.gd`**: Controla los estados globales del juego (`MENU`, `COUNTDOWN`, `RACING`, `RESULTS`), la parrilla de 10 vehículos en 4 carriles, el sistema de puntos de la Copa, la carga/guardado de escuderías en `.json`, la telemetría (`I`) y la transición entre rondas usando `MaxHeap.gd`.
- **`Track3D.gd`**: Construye procedimentalmente la malla 3D del circuito (asfalto de 22 m de ancho, 4 carriles discontinuos, bordillos rojiblancos y muros colisionables) e indexa sus 138 segmentos dentro de `SpatialTree3D`. Permite alternar el wireframe de depuración con `Q`.
- **`SpatialTree3D.gd`**: Árbol espacial jerárquico basado en cajas `AABB` tridimensionales. Realiza consultas `is_on_track` en tiempo **$O(\log P)$** sin asignaciones dinámicas por fotograma (sin `duplicate()` ni lambdas de ordenamiento) y genera una malla 3D de cajas para inspección visual.
- **`Car3D.gd`**: Implementa el movimiento físico 3D, dirección dependiente de la velocidad, sistema de energía (100 HP con daño proporcional al impacto y desgaste sobre el pasto), y sensores de raycasting optimizados con distancias al cuadrado ($d^2$) y multiplicación por recíproco (`INV_MAX_RANGE`).
- **`MaxHeap.gd`**: Montículo binario genérico (`push`, `pop_max`, `sift_up`, `sift_down`, `get_top_k`) usado para clasificar el podio y seleccionar a los mejores genomas élite en **$O(k \log N)$**.
- **`CameraRig3D.gd`**: Interpola suavemente entre vista **GTA Cenital**, **Isométrica Libre** (arrastre + zoom), **Isométrica de Auto** y **Tercera Persona**.

### 2. Puente Nativo GDExtension (`src/godot/`)

- **`GodotBrain.hpp` / `GodotBrain.cpp`**: Envuelve la clase C++ `NeuralNetwork` heredando de `godot::RefCounted`. Expone a GDScript los métodos `think(inputs)`, `get_weights()`, `set_weights()`, `crossover()` y `mutate()`, logrando ejecución nativa C++ desde Godot sin sobrecarga de scripts.
- **`register_types.cpp`**: Registra `GodotBrain` al inicializar la librería dinámica definida en `godot_project/bin/neurogenetica.gdextension`.

### 3. Núcleo de IA en C++17 (`include/ai/`, `src/ai/`)

- **`NeuralNetwork`**: Arquitectura Feedforward densa con activación no lineal $\tanh$ en $[-1, 1]$, serialización de pesos/sesgos como genoma lineal, cruce uniforme y mutación gaussiana.
- **`MaxHeap.hpp`**: Plantilla C++ `template <typename T, typename Compare>` con inserción y extracción en $O(\log n)$.
- **`GeneticAlgorithm`**: Motor evolutivo poblacional validado por pruebas unitarias.

### 4. Módulo Histórico 2D y Pruebas (`src/core/`, `src/graphics/`, `tests/`)

- Mantiene íntegra la primera versión del proyecto en **Raylib 5.5** (`QuadTree`, `Track`, `Car`, `HUD`, `CarCamera`, `Simulation`) y sirve como base de verificación continua mediante **CTest**:
  - `test_quadtree.cpp`
  - `test_neural_network.cpp`
  - `test_genetic_algorithm.cpp`

---

## 🔄 Ciclo de Vida por Fotograma (`_physics_process` 3D)

En cada paso físico de Godot Engine 4 (60 Hz, escalable a $\times 2$ y $\times 4$), el flujo sigue esta secuencia:

```
                    ┌───────────────────────────────────┐
                    │   Inicio de Paso Físico (60 Hz)   │
                    └─────────────────┬─────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────┐
                    │  1. Entrada y Estado de Carrera   │
                    │  - Teclas (WASD, V, C, M, Q, I)   │
                    │  - Control de Semáforo / Escala   │
                    └─────────────────┬─────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────┐
                    │  2. Sensores y Consultas 3D       │
                    │  - Track3D → SpatialTree3D        │
                    │    is_on_track() en O(log P)      │
                    │  - Car3D → Rayos optimizados      │
                    │    (distancias d² y 1/R_max)      │
                    └─────────────────┬─────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────┐
                    │  3. Decisión (Humano o C++ IA)    │
                    │  - Si es IA → GodotBrain.think()  │
                    │    (Red Neuronal C++17 nativa)    │
                    └─────────────────┬─────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────┐
                    │  4. Física 3D, Daño y Ranking     │
                    │  - Movimiento, colisiones y HP    │
                    │  - Checkpoints y vueltas          │
                    │  - ¿Fin de carrera?               │
                    │    → MaxHeap.get_top_k() O(k lgN) │
                    │    → Podio + Evolución de Ronda   │
                    └─────────────────┬─────────────────┘
                                      │
                                      ▼
                    ┌───────────────────────────────────┐
                    │  5. Renderizado 3D y Telemetría   │
                    │  - Escena 3D, luces, humo, pistas │
                    │  - Wireframe SpatialTree3D (Q)    │
                    │  - Cámara activa y HUD (I)        │
                    └───────────────────────────────────┘
```
