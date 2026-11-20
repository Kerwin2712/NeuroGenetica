# NeuroGenetica 🏎️🧠

**Videojuego de Carreras 3D con Rivales de Inteligencia Artificial Adaptativa**, desarrollado con **Godot Engine 4** y un núcleo de alto rendimiento en **C++17 (GDExtension)**, optimizado mediante estructuras de datos avanzadas (**`SpatialTree3D`**, **`QuadTree`** y **`MaxHeap`**). Proyecto desarrollado para la materia *Programación 3*.

> [!TIP]
> 📖 **Portal Oficial de Documentación**: Abre **[`docs/showcase.html`](docs/showcase.html)** mediante un servidor local (ej. *Live Server* en VS Code o `python -m http.server 8080`) para leer toda la documentación con ecuaciones matemáticas, navegación seccionada y modo claro/oscuro.

---

## 🕰️ Línea de Tiempo y Evolución del Proyecto

**NeuroGenetica** nació como un simulador 2D puro en C++17 con Raylib y evolucionó progresivamente hasta convertirse en un videojuego de carreras tridimensional en **Godot Engine 4** con cerebro nativo en C++:

| Etapa | Fecha | Hito Principal | Tecnologías y Logros Clave |
| :--- | :---: | :--- | :--- |
| **Fase 1** | 1 Oct | **Fundación C++17 & Prototipo 2D** | Arquitectura POO modular, ventana gráfica con **Raylib 5.5**, cinemática vehicular 2D, pista procedimental y primeros rayos sensores. |
| **Fase 2** | 2 – 30 Oct | **Estructuras de Datos y Neuroevolución 2D** | Implementación de `QuadTree` 2D ($O(\log W)$), `NeuralNetwork` Feedforward ($\tanh$), `MaxHeap` ($O(k \log N)$), circuito Catmull-Rom de 69 checkpoints, HUD en el infield y pruebas automatizadas con **CTest**. |
| **Fase 3** | 5 Nov | **Cámara Dinámica y Pulido 2D** | Integración de cámara vehicular dinámica (`CarCamera`) y posicionamiento ergonómico del HUD en modo manual. |
| **Fase 4** | 11 – 13 Nov | **Salto a 3D: Godot 4 + GDExtension C++** | Compilación del cerebro C++ (`GodotBrain`) como librería nativa **GDExtension**, pista 3D de 4 carriles, colisiones físicas entre autos, sistema de daño (100 HP), cámaras **GTA Cenital / Isométrica / 3ª Persona**, **Modo Copa**, semáforo de salida, podio y guardado/carga de escuderías `.json`. |
| **Fase 5** | 19 Nov | **Optimización Espacial 3D y Portal Docs** | Creación de **`SpatialTree3D`** (árbol AABB 3D sin asignaciones en heap + depuración visual `Tecla Q`), **`MaxHeap` 3D** para podio/elitismo, optimización matemática de sensores ($d^2$ y `INV_MAX_RANGE`) y portal web dinámico de documentación (`docs/showcase.html`). |

---

## 🎯 Objetivos del Proyecto (Programación 3)

1. **Experiencia de Juego de Carreras 3D (Objetivo Principal)**:
   - Videojuego interactivo de carreras en circuitos cerrados 3D donde el jugador humano compite en tiempo real contra 9 rivales controlados por IA (parrilla de 10 autos en 4 carriles) con física 3D, colisiones y daño por impacto (100 HP).
2. **Modos de Juego y Gamificación**:
   - 🏆 **Modo Copa (Humano vs IAs)**: Torneo multironda con semáforo de salida oficial, tabla de podio, puntuación acumulada y rivales IA que evolucionan entre rondas.
   - 👁️ **Modo Espectador**: Observación libre con cámara isométrica interactiva (arrastrar + zoom con rueda del ratón) para analizar el comportamiento evolutivo de la parrilla.
   - 🏁 **Escuderías Pre-entrenadas y Guardado**: Selector entre *Novatos*, *GT Pro*, *Élite Leyendas* o generaciones guardadas en `.json` (`Tecla G`).
3. **Evolución de Rivales (IA Adaptativa en C++)**:
   - Redes Neuronales Feedforward (`GodotBrain` en C++17) entrenadas con Algoritmos Genéticos continuos (elitismo, cruce uniforme y mutación gaussiana) sin rutas precalculadas ni trampas.
4. **Optimización de Rendimiento (Estructuras de Datos Avanzadas)**:
   - **Árboles de Partición Espacial (`SpatialTree3D` en 3D y `QuadTree` en 2D)**: Indexan los segmentos de la pista en jerarquías AABB para reducir las consultas de pista y sensores de $O(P)$ a **$O(\log P)$**, con poda automática y cero asignaciones dinámicas por cuadro.
   - **Optimización Matemática de Sensores**: Uso de distancias al cuadrado ($d^2$) para evitar raíces cuadradas ($\sqrt{}$) intermedias y multiplicación por recíproco (`INV_MAX_RANGE`) en lugar de divisiones.
   - **Max-Heap (Cola de Prioridad)**: Clasificación del podio y selección de élite en **$O(k \log N)$** sin ordenar el arreglo completo ni afectar los FPS.
5. **Arquitectura de Software Modular y Verificable**:
   - Separación limpia entre el motor 3D (Godot 4), la librería nativa de IA (C++17 GDExtension), el prototipo clásico 2D (Raylib) y las pruebas unitarias automatizadas (**CTest**).

---

## ⚙️ Arquitectura del Sistema Actual (Godot 4 3D + C++17 GDExtension)

El proyecto opera bajo una **arquitectura híbrida**: Godot Engine 4 gestiona la simulación física 3D, las cámaras y la interfaz, mientras que el núcleo compilado en C++17 ejecuta la inferencia de las redes neuronales mediante **GDExtension**:

```
               ┌──────────────────────────────────────────────────┐
               │       Godot Engine 4 — Escena Main3D.tscn        │
               │        (SimulationManager3D.gd — Orquestador)    │
               └────────────────────────┬─────────────────────────┘
                                        │
        ┌───────────────────────────────┼───────────────────────────────┐
        ▼                               ▼                               ▼
┌────────────────────┐       ┌───────────────────────┐       ┌────────────────────┐
│     Track3D.gd     │       │   Parrilla (10 Autos) │       │  CameraRig3D.gd &  │
│ - Pista 4 carriles │       │  Car3D.gd (Física 3D) │       │   UI / Telemetría  │
│ - SpatialTree3D.gd │       │  - Sensores (d², 1/R) │       │ - GTA / Isométrica │
│   (AABB O(log P))  │       │  - Daño HP & Colisión │       │ - Menú, Semáforo,  │
│ - Wireframe (Q)    │       │  - MaxHeap.gd O(k lgN)│       │   Podio & HUD (I)  │
└────────────────────┘       └───────────┬───────────┘       └────────────────────┘
                                         │ llamada nativa (GDExtension DLL)
                                         ▼
                             ┌───────────────────────┐
                             │  Núcleo C++17 Nativo  │
                             │  (src/godot + src/ai) │
                             │ - GodotBrain.cpp      │
                             │ - NeuralNetwork.cpp   │
                             │ - GeneticAlgorithm.cpp│
                             └───────────────────────┘
```

> [!NOTE]
> **Módulo Clásico 2D (Raylib) y Pruebas Unitarias**: El código original 2D en `src/core/` y `src/graphics/` (Raylib) se conserva completamente compilable con CMake como base histórica del proyecto y respalda las 3 suites de pruebas unitarias C++ en `tests/` (`QuadTreeTests`, `NeuralNetworkTests` y `GeneticAlgorithmTests`).

### Componentes Principales
1. **`SimulationManager3D.gd` (Orquestador 3D)**: Gestiona el menú principal, selector de escuderías, semáforo de salida, Modo Copa/Espectador, telemetría (`I`), guardado JSON (`G`), podio y evolución generacional apoyada en `MaxHeap.gd`.
2. **`GodotBrain` + `NeuralNetwork` (C++17 GDExtension)**: Puente nativo compilado en `godot_project/bin/` que expone la red neuronal Feedforward ($\tanh$, genoma de pesos/sesgos, cruce y mutación) directamente a Godot a velocidad nativa.
3. **`SpatialTree3D.gd` (Árbol Espacial 3D)**: Árbol de cajas envolventes 3D (`AABB`) sin asignaciones en heap por consulta, usado por `Track3D.gd` para verificar límites de pista en $O(\log P)$ y renderizar los cuadrantes en tiempo real (`Q`).
4. **`Car3D.gd` (Vehículo 3D y Sensores Optimizados)**: Cinemática 3D, colisiones entre vehículos, sistema de 100 HP y sensores de distancia optimizados con $d^2$ y multiplicación por recíproco.
5. **`MaxHeap.gd` / `MaxHeap.hpp` (Cola de Prioridad)**: Montículo máximo binario para extraer el podio y los progenitores élite en $O(k \log N)$.
6. **`CameraRig3D.gd`**: Controlador de 4 perspectivas (GTA Cenital, Isométrica Libre con ratón, Isométrica de Coche y Tercera Persona).

> [!NOTE]
> Consulta el detalle técnico completo en la documentación dedicada:
> - 🎮 **[Guía de Simulación 3D (Godot 4)](docs/GUIA_GODOT.md)**
> - 🏛️ **[Arquitectura y Organización de Archivos](docs/ARCHITECTURE.md)**
> - 🌳 **[Estructuras de Datos Avanzadas (`SpatialTree3D`, `QuadTree` y `MaxHeap`)](docs/DATA_STRUCTURES.md)**
> - 🧠 **[Física, Redes Neuronales y Neuroevolución](docs/AI_AND_PHYSICS.md)**

---

## 🎮 Controles de la Simulación 3D (Godot 4)

| Tecla / Ratón | Acción | Descripción |
| :--- | :--- | :--- |
| **`W` / `A` / `S` / `D`** o **`Flechas`** | Conducir / Mover cámara | Conduce tu vehículo en Modo Copa o desplaza la vista en Modo Espectador. |
| **`V`** | Cambiar cámara | Alterna entre **GTA Cenital**, **Isométrica Libre**, **Isométrica Auto** y **3ª Persona**. |
| **`C`** / **`Shift + C`** | Cambiar auto enfocado | Cambia el vehículo seguido por la cámara para inspeccionar su telemetría y sensores. |
| **`M`** | Alternar Humano / IA | Toma el control manual del auto enfocado o devuélvelo a la IA. |
| **`Q`** | Divisiones de Pista 3D | Muestra u oculta en pantalla la malla 3D de cuadrantes del **`SpatialTree3D`**. |
| **`I`** | Panel de Telemetría | Abre/cierra la tabla detallada de rendimiento, complejidad y métricas de los autos. |
| **`Espacio`** | Velocidad de simulación | Alterna la escala temporal entre **$\times 1$**, **$\times 2$** y **$\times 4$**. |
| **`TAB`** | Cambiar Modalidad | Alterna rápidamente entre **Modo Copa (Humano)** y **Modo Espectador**. |
| **`G`** | Guardar Generación | Exporta los cerebros de la generación actual a `godot_project/saved_teams/*.json`. |
| **`R`** / **`F5`** | Resultados / Reiniciar | `R` finaliza la carrera y muestra el podio; `F5` (o `Shift + R`) reinicia la Copa. |
| **`Arrastrar` / `Rueda Ratón`** | Cámara libre y Zoom | Desplaza la cámara isométrica y hace zoom suave sobre cualquier curva. |
| **`F11`** / **`ESC`** | Pantalla completa / Salir | `F11` alterna pantalla completa; `ESC` vuelve al menú principal o cierra el juego. |

---

## 🚀 Ejecución del Juego 3D (Recomendado)

### Requisitos para Jugar
- **Godot Engine 4** (versión 4.3 o superior). En Windows puedes instalarlo en 1 minuto desde PowerShell:
  ```powershell
  winget install GodotEngine.GodotEngine
  ```
  O descargarlo desde [godotengine.org/download](https://godotengine.org/download).

### 1. Clonar el repositorio
```bash
git clone https://github.com/Kerwin2712/NeuroGenetica.git
cd NeuroGenetica
```

### 2. Iniciar la Simulación 3D
La librería nativa de C++ (`godot_project/bin/`) ya se encuentra integrada en el proyecto para Windows:
- **Ejecutar el juego directamente**: Haz doble clic en **`ejecutar_juego_godot.bat`** (o desde terminal: `godot --path godot_project`).
- **Abrir en el Editor de Godot**: Haz doble clic en **`abrir_editor_godot.bat`** (o `godot --path godot_project -e`).

### 3. Recompilar la Librería C++ GDExtension *(solo si modificas código C++ en `src/ai/` o `src/godot/`)*
Requiere **Python + SCons** (`pip install scons`) y un compilador **C++17** (MinGW-w64 o MSVC):
- En Windows: haz doble clic en **`compilar_libreria_godot.bat`** o ejecuta:
  ```powershell
  scons platform=windows target=template_debug -j6
  ```
- En Linux:
  ```bash
  scons platform=linux target=template_debug -j6
  ```

---

## 🧪 Pruebas Unitarias C++ (CTest) y Versión Clásica 2D (Raylib)

El proyecto conserva el sistema de construcción **CMake** para ejecutar las pruebas unitarias automatizadas en C++17 y, opcionalmente, compilar la versión histórica 2D en Raylib.

### Requisitos de Compilación C++
- **Compilador C++17** (MinGW-w64/GCC 9+, Clang 10+ o MSVC 2019+), **CMake 3.15+** y **Git**.
- *(En Linux para el ejecutable 2D Raylib)*: instalar librerías de desarrollo X11/OpenGL/ALSA (`libgl1-mesa-dev libx11-dev libxrandr-dev libxi-dev libxcursor-dev libxinerama-dev libasound2-dev`).

### Compilar y Ejecutar Pruebas (CTest)
```powershell
# 1. Configurar CMake (en Windows con MinGW añade: -G "MinGW Makefiles")
cmake -B build

# 2. Compilar tests y prototipo 2D
cmake --build build

# 3. Ejecutar toda la suite de pruebas unitarias
ctest --test-dir build --output-on-failure
```

*Salida esperada:*
```text
1/3 Test #1: QuadTreeTests ....................   Passed
2/3 Test #2: NeuralNetworkTests ...............   Passed
3/3 Test #3: GeneticAlgorithmTests ............   Passed
100% tests passed out of 3
```

*(Opcional)* Para lanzar la versión histórica 2D en Raylib tras compilar con CMake:
- Windows: `.\build\NeuroGenetica.exe` | Linux: `./build/NeuroGenetica`

---

## 👥 Equipo de Desarrollo y Estado del Proyecto

Proyecto desarrollado para la materia **Programación 3** (Universidad de Los Andes):

### 🏎️ Integrantes y Aportes Realizados (Según Commits)

- **Javier Olivieri**:
  - Implementación del sistema de cámara dinámica vehicular en el motor 2D (`feature/camara`).
  - Posicionamiento ergonómico del HUD en modo de conducción manual.
  - Calibración de la física cinemática de viraje y sistema de colisiones 2D.
  - Pruebas unitarias de partición espacial: `test_quadtree.cpp`.

- **Kerwin Quintero**:
  - Implementación de la Red Neuronal Feedforward (`NeuralNetwork`), capas densas y activación $\tanh$.
  - Estructura de datos avanzada **Max-Heap** (Cola de Prioridad) en C++ y GDScript para ranking y selección de élite en tiempo $O(k \log N)$.
  - Motor de neuroevolución continua con cruce uniforme y mutación gaussiana.
  - Migración e integración del motor 3D en **Godot Engine 4** mediante librería **GDExtension C++** (`GodotBrain`).
  - Estructura de datos avanzada **`SpatialTree3D`** (árbol espacial AABB 3D sin asignaciones en heap) con consultas logarítmicas $O(\log P)$ y visualización de cuadrantes (`Tecla Q`).
  - Optimización matemática de sensores: distancias al cuadrado ($d^2$), eliminación de raíces cuadradas intermedias y multiplicación por recíproco (`INV_MAX_RANGE`).
  - Lógica completa del juego 3D: menú de inicio, semáforo de largada countdown, podio de Copa, escuderías pre-entrenadas/guardado JSON y telemetría en tiempo real.
  - Desarrollo del portal web dinámico oficial de documentación técnica (`docs/showcase.html`) y actualización integral de especificaciones Markdown.

- **Rafael Hernandez**:
  - Diseño conceptual de la experiencia de carreras, gamificación y propuesta de modos competitivos (Modo Copa, Carrera Única, Carretera Vertical).
  - Trazado de circuitos de Gran Premio con splines cúbicos Catmull-Rom, pianos bicolores y secuencia estricta de 69 checkpoints anti-trampas.
  - Interfaz de telemetría y HUD central en el infield para monitoreo a 60 FPS.
  - Estructuración y coordinación del cronograma de defensa técnica del proyecto.

---

### 📋 Tareas para Terminar Esta Semana

1. 🧪 **Validación Final de Pruebas Unitarias**:
   - Comprobar que el 100% de las suites de prueba (`QuadTreeTests`, `NeuralNetworkTests`, `GeneticAlgorithmTests`) pasen con éxito mediante `ctest`.
2. 🏁 **Sincronización y Cierre de Ramas**:
   - Fusionar la rama de trabajo `feature/optimizacion-sensores-estructuras-3d` en `development` y consolidar la versión final estable en `main`.

---

### 💡 Ideas Adicionales y Mejoras Futuras (Opcionales)

- 🔊 **Efectos de Audio y Sonido del Motor**: Incorporar audio reactivo a las RPM del motor, derrapes en curvas y pitidos del semáforo de salida.
- 📈 **Gráfico de Evolución de Fitness en Pantalla**: Dibujar una gráfica en tiempo real con la curva de aprendizaje de las mejores IAs a través de las generaciones.
- 🌧️ **Condiciones Climáticas Dinámicas**: Variar la fricción ($\mu$) en lluvia o asfalto mojado para evaluar la adaptabilidad de las redes neuronales.
- 🛣️ **Nuevos Circuitos 3D**: Añadir un selector de pistas con distinta dificultad (óvalo rápido, circuito técnico con chicanes y autopista vertical).

---

### 🎓 Reconocimientos Académicos
- **Docente**: Prof. Alejandro Mujica
- **Preparadores**: Jesús León y Sarai Rojas

---

## 🌿 Flujo de Trabajo en Git

```
feature/nueva-funcionalidad  ──► (merge) ──┐
                                           ▼
                                      development ──► (merge cuando es estable) ──► main (versión final)
```

1. **`main`**: Rama protegida con versiones estables, compilables y listas para entrega.
2. **`development`**: Rama integradora donde convergen todas las características probadas.
3. **`feature/*`**: Ramas de trabajo individuales para cada módulo o mejora antes de integrarse a `development`.
