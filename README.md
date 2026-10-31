# NeuroGenetica 🏎️🧠

Simulación de vehículos autónomos en **C++17** que aprenden a conducir en circuitos de carreras mediante **Redes Neuronales Feedforward** y **Algoritmos Genéticos (Neuroevolución)**, optimizados con estructuras de datos avanzadas (**QuadTree** para partición espacial y **Max-Heap** para selección elitista). Proyecto desarrollado para la materia *Programación 3*.

---

## 🎯 Resumen y Objetivos del Proyecto

El objetivo de **NeuroGenetica** es aplicar conceptos avanzados de programación orientada a objetos, optimización algorítmica y estructuras de datos para resolver un problema de aprendizaje autónomo en tiempo real:

- **Estructuras de Datos Avanzadas**:
  - **QuadTree (Árbol de partición espacial 2D)**: Indexa los segmentos y muros del circuito para optimizar el cálculo de colisiones y el raycasting de sensores en tiempo $O(\log n)$ en lugar del costo ingenuo $O(n \times m)$.
  - **Max-Heap (Cola de Prioridad)**: Realiza el ranking y la selección del top de individuos más aptos para elitismo y cruce genético en tiempo $O(k \log n)$.
- **Neuroevolución (IA sin Backpropagation)**:
  - Cada vehículo posee un "cerebro" (Red Neuronal Feedforward).
  - La población evoluciona mediante selección por torneo/elitismo, cruce uniforme de pesos y mutación gaussiana continua.
- **Validación con Pruebas Unitarias**:
  - Cobertura completa de tests unitarios independientes para el QuadTree, la Red Neuronal y el Algoritmo Genético, integrados con **CTest**.
- **Flujo de Trabajo Profesional**:
  - Commits atómicos descriptivos bajo estándar *Conventional Commits* y flujo de ramas estructurado.

---

## 🎮 Controles de la Simulación

| Tecla / Control | Acción | Descripción |
| :--- | :---: | :--- |
| **`W` / `A` / `S` / `D`** o **`Flechas`** | Conducir vehículo | Permite acelerar, frenar y virar manualmente en Modo Manual. |
| **`M`** | Alternar Modo IA / Manual | Cambia entre conducción manual del usuario y la simulación genética autónoma. |
| **`Espacio`** | Velocidad de simulación | Alterna la velocidad entre **$\times 1$**, **$\times 2$** y **$\times 5$** para acelerar el entrenamiento. |
| **`Q`** | Depuración de QuadTree | Activa/desactiva la visualización en pantalla de las subdivisiones del árbol espacial. |
| **`R`** | Forzar nueva generación | Reinicia inmediatamente la generación actual para descartar individuos estancados. |
| **`ESC`** | Salir | Cierra la ventana y finaliza la simulación. |

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

1. **`Car` (Vehículo)**: Cinemática 2D con aceleración, fricción y viraje angular. Proyecta 5 rayos de sensores normalizados $[0, 1]$ hacia los límites del circuito.
2. **`NeuralNetwork` (Red Neuronal)**: Arquitectura Feedforward con capas densas y activación no lineal Tanh. Entradas: distancias de sensores + velocidad. Salidas: ángulo de giro y aceleración/freno.
3. **`GeneticAlgorithm` (Neuroevolución)**: Administra la población de agentes, evalúa el fitness mediante avance ordenado por checkpoints y genera nuevas generaciones usando selección elitista por Max-Heap, crossover y mutación gaussiana.
4. **`QuadTree` (Árbol Espacial 2D)**: Subdivide espacialmente el plano para reducir drásticamente el espacio de búsqueda en las intersecciones de rayos y colisiones.
5. **`Track` (Pista y Checkpoints)**: Trazado de alta complejidad con splines Catmull-Rom, pianos bicolores y una secuencia estricta de 69 checkpoints anti-trampas.
6. **`HUD` (Telemetría e Interfaz)**: Métricas en vivo (generación actual, autos vivos, mejor fitness histórico, telemetría y FPS).

> [!NOTE]
> Para una descripción exhaustiva de cada archivo del proyecto, diagramas de módulos y análisis formal de complejidades asintóticas para la materia *Programación 3*, consulte la carpeta de **[Documentación Técnica en docs/](docs/README.md)**:
> - 🏛️ **[Arquitectura y Organización de Archivos](docs/ARCHITECTURE.md)**
> - 🌳 **[Estructuras de Datos Avanzadas (QuadTree y Max-Heap)](docs/DATA_STRUCTURES.md)**
> - 🧠 **[Física, Redes Neuronales y Neuroevolución](docs/AI_AND_PHYSICS.md)**

---

## 📋 Requerimientos Previos (Requirements)

Antes de compilar, asegúrese de contar con los siguientes programas instalados en su sistema operativo.

### Requisitos Mínimos Generales
- **Compilador de C++**: Compatible con **C++17** o superior (GCC 9+, Clang 10+ o MSVC 2019+).
- **CMake**: Versión **3.15** o superior.
- **Git**: Para clonar el repositorio y descargar automáticamente las dependencias.
- **Conexión a Internet**: En la primera compilación, CMake descargará automáticamente la librería gráfica [Raylib 5.5](https://www.raylib.com/) mediante `FetchContent`.

---

### 🪟 Instalación de Requerimientos en Windows

Puede instalar todas las herramientas en Windows de dos formas:

#### Opción A: Vía Windows Package Manager (`winget` - Recomendada)
Abra una terminal de **PowerShell** como Administrador y ejecute:

```powershell
# Instalar Git y CMake
winget install --id Git.Git -e
winget install --id Kitware.CMake -e

# Instalar MinGW-w64 (GCC/G++ y Make) mediante MSYS2
winget install --id MSYS2.MSYS2 -e
```

Una vez instalado MSYS2, abra la consola **MSYS2 UCRT64** y ejecute:
```bash
pacman -S --needed base-devel mingw-w64-ucrt-x86_64-gcc mingw-w64-ucrt-x86_64-cmake mingw-w64-ucrt-x86_64-ninja
```
*Asegúrese de agregar `C:\msys64\ucrt64\bin` a las Variables de Entorno del sistema (`PATH`).*

#### Opción B: Con Visual Studio (MSVC)
Si prefiere el entorno de Microsoft:
1. Descargue [Visual Studio Community](https://visualstudio.microsoft.com/es/vs/community/).
2. En el instalador, marque la casilla **"Desarrollo para el escritorio con C++"** (incluye compilador MSVC, CMake y Ninja).

---

### 🐧 Instalación de Requerimientos en Linux

> [!IMPORTANT]
> En distribuciones Linux, la librería gráfica **Raylib** compila directamente desde el código fuente y requiere las cabeceras de desarrollo de X11, OpenGL y ALSA. Debe instalarlas previamente según su distribución:

#### Debian / Ubuntu / Linux Mint
Abra una terminal y ejecute:
```bash
sudo apt update
sudo apt install -y build-essential cmake git \
    libasound2-dev libx11-dev libxrandr-dev libxi-dev \
    libgl1-mesa-dev libglu1-mesa-dev libxcursor-dev \
    libxinerama-dev libwayland-dev libxkbcommon-dev
```

#### Fedora / RHEL
```bash
sudo dnf install -y gcc-c++ cmake git \
    mesa-libGL-devel libX11-devel libXrandr-devel libXi-devel \
    libXcursor-devel libXinerama-devel alsa-lib-devel
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S --needed base-devel cmake git \
    libx11 libxrandr libxi libxcursor libxinerama mesa alsa-lib
```

---

## 🔨 Compilación desde la Fuente (Building from Source)

Siga estos pasos desde su terminal (PowerShell en Windows o Bash en Linux):

### 1. Clonar el repositorio
```bash
git clone https://github.com/Kerwin2712/NeuroGenetica.git
cd NeuroGenetica
```

### 2. Configurar el proyecto con CMake
Crea la carpeta `build/` y genera los archivos de construcción correspondientes:

- **En Windows (con MinGW Makefiles)**:
  ```powershell
  cmake -B build -G "MinGW Makefiles"
  ```
- **En Windows (con Visual Studio / MSVC)**:
  ```powershell
  cmake -B build
  ```
- **En Linux**:
  ```bash
  cmake -B build
  ```

### 3. Compilar el proyecto
Construye el ejecutable principal y las suites de pruebas unitarias:

- **En Windows**:
  ```powershell
  cmake --build build
  ```
- **En Linux (compilación en paralelo)**:
  ```bash
  cmake --build build --parallel
  ```

---

## 🚀 Ejecución

### Ejecutar la Simulación Principal

- **En Windows**:
  ```powershell
  .\build\NeuroGenetica.exe
  ```
- **En Linux**:
  ```bash
  ./build/NeuroGenetica
  ```

---

## 🧪 Ejecución de Pruebas Unitarias (Tests)

El proyecto cuenta con suites de pruebas unitarias exhaustivas que validan la correctitud algorítmica y matemática antes del renderizado.

### Método 1: Automatizado vía CTest (Recomendado)
Desde la raíz del repositorio, ejecute:

```bash
ctest --test-dir build --output-on-failure
```
*Salida esperada:*
```
1/3 Test #1: QuadTreeTests ....................   Passed
2/3 Test #2: NeuralNetworkTests ...............   Passed
3/3 Test #3: GeneticAlgorithmTests ............   Passed
100% tests passed out of 3
```

### Método 2: Ejecución individual por módulo

- **En Windows**:
  ```powershell
  # 1. Pruebas de partición espacial 2D e intersecciones
  .\build\QuadTreeTests.exe

  # 2. Pruebas de Feedforward, activaciones y mutación
  .\build\NeuralNetworkTests.exe

  # 3. Pruebas de Max-Heap, elitismo y ciclo generativo
  .\build\GeneticAlgorithmTests.exe
  ```

- **En Linux**:
  ```bash
  ./build/QuadTreeTests
  ./build/NeuralNetworkTests
  ./build/GeneticAlgorithmTests
  ```

---

## 👥 Equipo de Desarrollo y Créditos

Proyecto desarrollado para la materia **Programación 3**:

### 🏎️ Integrantes del Equipo
- **Javier Olivieri**:
  - Cinemática del vehículo (`Car`), física y dinámica de viraje.
  - Estructura de partición espacial **QuadTree** 2D y consultas optimizadas.
  - Sistema de sensores por **Raycasting** e intersecciones geométricas.
  - Suite de pruebas: `test_quadtree.cpp`.
- **Kerwin Quintero**:
  - Red Neuronal Feedforward (`NeuralNetwork`), capas densas y activación Tanh.
  - Estructura de datos **Max-Heap** para selección elitista de fitness en $O(k \log n)$.
  - **Algoritmo Genético**: operadores de cruce uniforme y mutación continua.
  - Suites de pruebas: `test_neural_network.cpp` y `test_genetic_algorithm.cpp`.
- **Rafael Hernandez**:
  - Motor gráfico y ventana interactiva con **Raylib**.
  - Trazado de circuito de Gran Premio con splines Catmull-Rom, pianos bicolores y checkpoints secuenciales anti-trampas.
  - Interfaz de telemetría y HUD en tiempo real con estadísticas y modos de simulación.

### 🎓 Reconocimientos Académicos
- **Docente**: Prof. Alejandro Mujica
- **Preparadores**: Jesús León y Sarai Rojas

---

## 🌿 Flujo de Trabajo en Git

El desarrollo del proyecto se rige bajo la convención de ramas:

```
feature/nueva-funcionalidad  ──► (merge) ──┐
                                           ▼
                                      development ──► (merge cuando es estable) ──► main (versión final)
```

1. **`main`**: Rama protegida que contiene únicamente versiones estables, compilables y listas para entrega o release. No se realizan commits directos sobre ella.
2. **`development`**: Rama integradora donde convergen todas las características probadas.
3. **`feature/*`**: Ramas de trabajo individuales para cada componente o corrección antes de ser integradas a `development`.

---

## 📦 Generación de Release (Opcional)

Para generar una entrega empaquetada lista para distribuir a usuarios sin requerir compilación:

1. Compilar el proyecto en modo optimizado:
   ```bash
   cmake -B build -DCMAKE_BUILD_TYPE=Release
   cmake --build build --config Release
   ```
2. Crear un archivo comprimido (`.zip` o `.tar.gz`) con:
   - El ejecutable `NeuroGenetica.exe` (o binario `NeuroGenetica`).
   - La carpeta `assets/` (si contiene texturas/fuentes externas).
   - El archivo `README.md`.
3. En GitHub, navegar a **Releases** $\to$ **Draft a new release**, asignar la etiqueta `v1.0.0` y adjuntar el archivo comprimido.
