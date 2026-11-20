# 📚 Centro de Documentación Técnica — NeuroGenetica

Bienvenido a la documentación oficial de **NeuroGenetica** (**Godot Engine 4 + C++17 GDExtension**). Este conjunto de documentos explica la arquitectura híbrida 3D/C++, los fundamentos matemáticos de la neuroevolución, las estructuras de datos avanzadas implementadas para la materia *Programación 3* y la evolución histórica del proyecto desde su prototipo 2D en Raylib.

> [!TIP]
> 📖 **Lectura Interactiva en Navegador**: Abre **[`docs/showcase.html`](showcase.html)** desde un servidor local (extensión *Live Server* de VS Code o `python -m http.server 8080`) para navegar por todos los documentos con renderizado de ecuaciones **KaTeX**, tema claro aperlado / gris oscuro e índice lateral persistente.

---

## 🗺️ Mapa de Navegación

| Sección | Documento | Descripción | Temas Clave |
| :--- | :--- | :--- | :--- |
| **Proyecto** | **[Visión General (`README.md`)](../README.md)** | Punto de entrada del repositorio, línea de tiempo y ejecución rápida. | Evolución 2D $\to$ 3D, arquitectura Godot+C++, controles, ejecución, equipo y tests. |
| **Motor 3D** | **[Guía de Simulación 3D (Godot 4)](GUIA_GODOT.md)** | Manual completo de juego y mecánicas tridimensionales. | Pista 4 carriles, daño 100 HP, Modo Copa, cámaras GTA/Isométrica, escuderías JSON y controles. |
| **Motor 3D** | **[Arquitectura y Módulos](ARCHITECTURE.md)** | Visión de capas, puente GDExtension C++ y árbol de archivos. | Godot 4 (`Main3D`), `GodotBrain` C++, núcleo `ai/`, legado 2D Raylib y ciclo de fotograma. |
| **Algoritmos** | **[Estructuras de Datos Avanzadas](DATA_STRUCTURES.md)** | Análisis teórico, práctico y asintótico de las estructuras del curso. | `SpatialTree3D` ($O(\log P)$), `QuadTree` 2D, `MaxHeap` ($O(k \log N)$), sensores con $d^2$. |
| **Algoritmos** | **[Física, Red Neuronal y Neuroevolución](AI_AND_PHYSICS.md)** | Modelo matemático del movimiento y aprendizaje autónomo. | Cinemática, Raycasting optimizado, ANN Feedforward ($\tanh$), fitness, cruce y mutación. |

---

## 🎯 Propuesta y Estado Actual (Programación 3)

**Título:** *Desarrollo de un Videojuego de Carreras 3D con Rivales de Inteligencia Artificial Adaptativa en Godot 4 y C++17*.

1. **Experiencia de Juego de Carreras 3D**:
   - Circuito tridimensional de 4 carriles (parrilla de 10 autos) donde el jugador humano compite en tiempo real contra rivales controlados por redes neuronales en C++, con colisiones reales, sistema de daño (100 HP) y 4 cámaras dinámicas.
2. **Modos de Juego (Gamificación)**:
   - **Modo Copa (Humano vs IAs)**: Torneo multironda con semáforo de salida, podio, tabla de puntos y evolución de rivales entre rondas.
   - **Modo Espectador**: Análisis libre de la evolución con cámara isométrica interactiva y telemetría detallada (`Tecla I`).
   - **Escuderías Guardables**: Selección de rivales pre-entrenados (*Novatos*, *GT Pro*, *Élite*) y exportación/importación de generaciones en `.json` (`Tecla G`).
3. **Evolución de Rivales (IA Adaptativa en C++17)**:
   - Redes neuronales feedforward (`NeuralNetwork` expuesta como `GodotBrain` vía GDExtension) entrenadas con Algoritmos Genéticos continuos sin rutas fijas (*waypoints*) ni trampas.
4. **Optimización de Rendimiento (Estructuras de Datos Avanzadas)**:
   - **`SpatialTree3D` (3D) y `QuadTree` (2D)** ($O(\log P)$): Partición espacial mediante cajas AABB que acelera las comprobaciones de pista y el raycasting de sensores, con visualización en vivo (`Tecla Q`).
   - **`MaxHeap`** ($O(k \log N)$): Cola de prioridad para ranking de podio y extracción de élite en cada generación sin pausar los FPS.
5. **Ingeniería de Software y Pruebas**:
   - Arquitectura modular híbrida (Godot 4 + C++17), legado 2D compilable con CMake, pruebas unitarias automatizadas con **CTest** y flujo estructurado en Git.
