# 🏛️ Arquitectura de Software y Organización de Archivos

Este documento describe la arquitectura modular, los patrones de diseño y la estructura completa de archivos que conforman el proyecto **NeuroGenetica**.

---

## 📐 Visión General de la Arquitectura

El sistema está diseñado bajo una arquitectura modular en **C++17**, aplicando el principio de **Responsabilidad Única (SRP)** y un desacoplamiento estricto entre la lógica de simulación, las estructuras de datos, la inteligencia artificial y el renderizado gráfico.

```
                                 ┌──────────────┐
                                 │   main.cpp   │
                                 └──────┬───────┘
                                        │
                                        ▼
                               ┌─────────────────┐
                               │   Simulation    │  (Orquestador Principal)
                               └────────┬────────┘
                                        │
         ┌──────────────────────────────┼──────────────────────────────┐
         ▼                              ▼                              ▼
  ┌─────────────┐               ┌───────────────┐               ┌─────────────┐
  │  Capa Core  │               │    Capa AI    │               │Capa Graphics│
  │ (Física y   │               │ (Aprendizaje  │               │ (Raylib y   │
  │  Geometría) │               │   Genético)   │               │  Interfaz)  │
  └──────┬──────┘               └───────┬───────┘               └──────┬──────┘
         │                              │                              │
  ┌──────┴──────────────┐        ┌──────┴──────────────┐               │
  │ - Geometry.hpp      │        │ - NeuralNetwork     │               ▼
  │ - QuadTree (Árbol)  │        │ - GeneticAlgorithm  │        ┌─────────────┐
  │ - Track (Circuito)  │        │ - MaxHeap (Priority)│        │ - HUD.hpp   │
  │ - Car (Cinemática)  │        └─────────────────────┘        │ - Raylib GL │
  └─────────────────────┘                                       └─────────────┘
```

---

## 📂 Árbol de Directorios y Responsabilidades

```
NeuroGenetica/
├── CMakeLists.txt                # Configuración de CMake, FetchContent (Raylib) y CTest
├── README.md                     # Guía principal de compilación y ejecución rápida
├── .gitignore                    # Reglas de exclusión para binarios, build/ y temporales
│
├── docs/                         # Documentación técnica y académica detallada
│   ├── README.md                 # Índice y mapa de navegación de la documentación
│   ├── ARCHITECTURE.md           # Arquitectura de software, capas y árbol de archivos
│   ├── DATA_STRUCTURES.md        # Documentación de QuadTree y MaxHeap con complejidades
│   └── AI_AND_PHYSICS.md         # Fundamentos de cinemática, raycasting y neuroevolución
│
├── include/                      # Declaraciones y cabeceras (.hpp)
│   ├── core/                     # Capa Core: Simulación, geometría y espacio
│   │   ├── Geometry.hpp          # Primitivas geométricas, AABB y función de intersección
│   │   ├── QuadTree.hpp          # Definición del árbol de partición espacial 2D
│   │   ├── Track.hpp             # Geometría del circuito, splines y checkpoints
│   │   ├── Car.hpp               # Cinemática física, sensores de raycasting y agente
│   │   └── Simulation.hpp        # Controlador principal y bucle de juego
│   ├── ai/                       # Capa de Inteligencia Artificial y Neuroevolución
│   │   ├── NeuralNetwork.hpp     # Red neuronal feedforward multicapa y genoma
│   │   ├── MaxHeap.hpp           # Estructura de datos Max-Heap (Cola de Prioridad genérica)
│   │   └── GeneticAlgorithm.hpp  # Población, elitismo, cruce uniforme y mutación
│   └── graphics/                 # Capa de Presentación e Interfaz
│       └── HUD.hpp               # Panel de estadísticas, telemetría y métricas
│
├── src/                          # Implementaciones de código fuente (.cpp)
│   ├── core/
│   │   ├── QuadTree.cpp          # Implementación de inserción, subdivisión y podado
│   │   ├── Track.cpp             # Generación por splines Catmull-Rom y muros
│   │   ├── Car.cpp               # Física de aceleración, fricción y raycasting
│   │   └── Simulation.cpp        # Inicialización, bucle Update/Render y eventos
│   ├── ai/
│   │   ├── NeuralNetwork.cpp     # Feedforward, activación Tanh y mutación continua
│   │   └── GeneticAlgorithm.cpp  # Ciclo generativo y ranking con MaxHeap
│   ├── graphics/
│   │   └── HUD.cpp               # Dibujo de métricas, velocímetro y controles
│   └── main.cpp                  # Punto de entrada de la aplicación
│
├── tests/                        # Pruebas unitarias independientes (validadas con CTest)
│   ├── test_quadtree.cpp         # Verificación de subdivisión y podado espacial
│   ├── test_neural_network.cpp   # Verificación de topología, activaciones y mutación
│   └── test_genetic_algorithm.cpp# Verificación de propiedad Max-Heap y ciclo genético
│
└── assets/                       # Recursos visuales y texturas externas
    ├── cars/                     # Modelos y sprites de vehículos
    └── tracks/                   # Fondos y texturas de asfalto
```

---

## 🔍 Detalle por Módulos y Archivos

### 1. Capa Core (`include/core/`, `src/core/`)

#### `Geometry.hpp`
- **Propósito**: Proporciona las estructuras matemáticas básicas para el motor 2D sin dependencias de alto nivel.
- **Estructuras**:
  - `LineSegment`: Representa un segmento de pared o checkpoint con puntos `start` y `end`, e identificador numérico único para deduplicación rápida.
  - `BoundingBox2D`: Rectángulo alineado a los ejes (**AABB**) utilizado para delimitar nodos del QuadTree, cajas de impacto de vehículos y áreas de consulta espacial.
  - `SensorHit`: Registro del resultado del raycasting (distancia euclidiana, punto de impacto y normalización).
  - `CheckLineIntersection`: Función matemática optimizada de intersección entre 2 segmentos de recta en 2D.

#### `QuadTree.hpp` / `QuadTree.cpp`
- **Propósito**: Implementa la estructura de datos jerárquica para partición espacial 2D.
- **Responsabilidades**:
  - Subdivisión recursiva en cuatro cuadrantes: `NW` (Noroeste), `NE` (Noreste), `SW` (Suroeste), `SE` (Sureste).
  - Almacena los segmentos de la pista en los nodos correspondientes.
  - Provee consultas podadas en tiempo logarítmico: `QueryRay()` para los sensores y `QueryBox()` para la colisión del vehículo.

#### `Track.hpp` / `Track.cpp`
- **Propósito**: Administra el trazado, la representación visual y los límites del circuito de carreras.
- **Responsabilidades**:
  - Generación procedimental mediante splines cúbicos **Catmull-Rom** para garantizar curvas suaves.
  - Genera bordes interiores, exteriores, pianos (kerbs) y la línea divisoria discontinua.
  - Inserta los segmentos de los muros en el `QuadTree`.
  - Establece la secuencia ordenada de **69 checkpoints anti-trampas** transversales.

#### `Car.hpp` / `Car.cpp`
- **Propósito**: Modela la entidad del vehículo autónomo o manual.
- **Responsabilidades**:
  - Cinemática 2D: aceleración, frenado, velocidad angular, fricción dinámica y velocidad terminal.
  - Proyección de 5 sensores de raycasting hacia los límites de la pista.
  - Contiene una instancia de su cerebro (`NeuralNetwork`).
  - Detección de colisión con las paredes indexadas en el `QuadTree`.
  - Acumulación de fitness basada en checkpoints superados y penalización por inactividad.

#### `Simulation.hpp` / `Simulation.cpp`
- **Propósito**: Clase controladora principal (Game Engine) que orquesta la aplicación.
- **Responsabilidades**:
  - Inicialización de la ventana gráfica y contexto de OpenGL mediante Raylib.
  - Gestión de entrada del usuario (teclado: `WASD`, `M`, `Espacio`, `Q`, `R`).
  - Control de modos: Modo Manual (conducción individual) vs Modo Genético (Neuroevolución de 40 agentes).
  - Control de velocidad temporal de la simulación ($\times 1$, $\times 2$, $\times 5$).

---

### 2. Capa AI (`include/ai/`, `src/ai/`)

#### `NeuralNetwork.hpp` / `NeuralNetwork.cpp`
- **Propósito**: Red neuronal artificial Feedforward densa.
- **Responsabilidades**:
  - Topología por defecto: **6 entradas** (5 distancias de sensores + 1 velocidad actual) $\to$ **8 neuronas ocultas** $\to$ **2 salidas** (ángulo de viraje y aceleración/freno).
  - Activación no lineal mediante tangente hiperbólica ($\tanh$), garantizando salidas normalizadas en $[-1, 1]$.
  - Métodos para serializar y deserializar los pesos y sesgos en un vector lineal (`std::vector<float>`) para operar como genoma.
  - Operadores de mutación gaussiana continua y cruce uniforme (*Uniform Crossover*).

#### `MaxHeap.hpp`
- **Propósito**: Estructura de datos avanzada tipo **Montículo Máximo (Priority Queue)** genérica basada en plantillas (`template <typename T, typename Compare>`).
- **Responsabilidades**:
  - Inserción en tiempo $O(\log n)$ mediante `SiftUp`.
  - Extracción del individuo con mayor fitness en tiempo $O(\log n)$ mediante `SiftDown`.
  - Permite implementar selección por elitismo en tiempo $O(k \log n)$ sin el costo de ordenar el vector completo $O(n \log n)$.

#### `GeneticAlgorithm.hpp` / `GeneticAlgorithm.cpp`
- **Propósito**: Motor de neuroevolución poblacional.
- **Responsabilidades**:
  - Mantiene una población de 40 agentes simultáneos.
  - Evalúa la aptitud individual según progreso en el circuito y tiempo de vida.
  - Detecta cuándo todos los autos han colisionado o se ha alcanzado el límite de tiempo de la generación.
  - Ejecuta la transición generacional: Selección elitista con `MaxHeap`, cruce entre los mejores individuos y mutación continua en la descendencia.

---

### 3. Capa Graphics (`include/graphics/`, `src/graphics/`)

#### `HUD.hpp` / `HUD.cpp`
- **Propósito**: Renderizado de la interfaz de usuario y telemetría en tiempo real.
- **Responsabilidades**:
  - Panel flotante adaptativo integrado en el infield central del circuito.
  - Muestra: Generación actual, número de autos activos vs colisionados, mejor fitness de la generación y récord histórico.
  - Barra de telemetría: Velocidad del líder, ángulo de viraje y estado del QuadTree.
  - Indicador de multiplicador de velocidad ($\times 1, \times 2, \times 5$).

---

### 4. Capa de Pruebas Unitarias (`tests/`)

- **`test_quadtree.cpp`**: Valida que la estructura subdivida correctamente los cuadrantes al superar la capacidad máxima y que `QueryRange` y `QueryRay` retornen únicamente los segmentos relevantes sin falsos negativos.
- **`test_neural_network.cpp`**: Verifica las dimensiones del *forward pass*, los rangos válidos de salida con $\tanh$, la consistencia de aplanamiento de genoma y la correcta aplicación de la mutación.
- **`test_genetic_algorithm.cpp`**: Valida las operaciones `Push`, `PopMax` y `PeekMax` del `MaxHeap`, el orden descendente estricto por fitness y la integridad del ciclo generativo.

---

## 🔄 Ciclo de Vida por Cuadro (Frame Lifecycle)

En cada fotograma de la simulación, el ciclo principal ejecuta el siguiente flujo ordenado:

```
                      ┌────────────────────────────┐
                      │    Inicio de Fotograma     │
                      └─────────────┬──────────────┘
                                    │
                                    ▼
                      ┌────────────────────────────┐
                      │   1. Procesar Input (E/S)  │
                      │  - Teclas WASD / Flechas   │
                      │  - Cambios de modo (M)     │
                      │  - Velocidad (Espacio)     │
                      └─────────────┬──────────────┘
                                    │
                                    ▼
                      ┌────────────────────────────┐
                      │    2. Update Simulación    │
                      │ (Se repite N veces si x2/x5)
                      │                            │
                      │ a) Raycasting con QuadTree │
                      │ b) Forward Pass en Redes   │
                      │ c) Actualizar Cinemática   │
                      │ d) Verificar Checkpoints   │
                      │ e) Detección de Colisiones │
                      │ f) ¿Generación terminada?  │
                      │    --> MaxHeap Evolve      │
                      └─────────────┬──────────────┘
                                    │
                                    ▼
                      ┌────────────────────────────┐
                      │    3. Renderizado Visual   │
                      │  - Pista, Césped y Pianos  │
                      │  - Checkpoints / Debug     │
                      │  - Autos y Sensores Rayos  │
                      │  - Panel HUD de Telemetría │
                      └─────────────┬──────────────┘
                                    │
                                    ▼
                      ┌────────────────────────────┐
                      │     Fin de Fotograma       │
                      │   (Sincronización 60 FPS)  │
                      └────────────────────────────┘
```

