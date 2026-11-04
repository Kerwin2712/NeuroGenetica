# 📚 Documentación Técnica de NeuroGenetica

Bienvenido al centro de documentación técnica y arquitectónica de **NeuroGenetica**. Este conjunto de documentos detalla en profundidad el diseño de software, la experiencia de juego, los algoritmos matemáticos y las estructuras de datos avanzadas implementadas para la materia *Programación 3*.

---

## 🎬 Visualizador Dinámico para Exposición y Video

> [!TIP]
> **¿Deseas presentar el proyecto de forma interactiva en video?**  
> Abre el archivo **[`docs/showcase.html`](showcase.html)** en cualquier navegador web moderno (doble clic en Windows o mediante navegador). Incluye:
> - 🎙️ **Modo Presentación / Diapositivas**: Guion narrativo sincronizado y cronómetro para grabación con OBS o Loom.
> - 🔲 **Simulador de QuadTree en Canvas 2D**: Visualización en tiempo real del podado espacial y comparativa de rendimiento ($O(\log n)$ vs $O(n \times m)$).
> - 🧠 **Diagrama Interactivo de Red Neuronal**: Impulsos animados entre capas (6 → 8 → 2) y sliders de control de sensores.
> - 🏔️ **Árbol Binario de Max-Heap**: Extracción animada `PopMax()` del top-$k$ de coches élite en $O(k \log n)$.
> - 🎮 **Visualizador de Modos de Juego**: Tarjetas interactivas de Modo Copa, Carrera Única y Carretera Vertical.

---

## 🗺️ Mapa de Navegación

| Documento | Descripción | Temas Clave |
| :--- | :--- | :--- |
| **[Showcase Dinámico (HTML)](showcase.html)** | Interfaz web interactiva y diapositivas de apoyo para grabación de video. | Simulador Canvas de QuadTree, Red Neuronal, Max-Heap y guion de video. |
| **[Arquitectura de Software y Archivos](ARCHITECTURE.md)** | Visión integral de capas, componentes y árbol del repositorio. | Módulos Core, AI, Graphics, ciclo de vida del frame, flujo de datos. |
| **[Estructuras de Datos Avanzadas](DATA_STRUCTURES.md)** | Análisis teórico y práctico de los árboles y colas de prioridad. | QuadTree 2D, Max-Heap genérico, podado espacial, análisis de complejidad $O$. |
| **[Física, Red Neuronal y Neuroevolución](AI_AND_PHYSICS.md)** | Fundamentos matemáticos del simulador y del aprendizaje autónomo. | Cinemática 2D, Raycasting, ANN Feedforward, función de fitness, cruce y mutación. |

---

## 🎯 Propuesta Actualizada del Proyecto (Programación 3)

**Título:** *Desarrollo de un Videojuego de Carreras en C++ con Rivales de Inteligencia Artificial Adaptativa*.

1. **Experiencia de Juego de Carreras (Objetivo Principal)**:
   - Videojuego interactivo en circuitos cerrados donde el jugador humano compite en tiempo real contra múltiples rivales controlados por IA, garantizando fluidez competitiva a 60 FPS.
2. **Modos de Juego (Gamificación)**:
   - **Modo Copa**: Torneo multironda en circuitos cerrados donde los rivales acumulan puntuación y refinan sus genomas entre carreras.
   - **Carrera Única**: Partida rápida contra el mejor modelo histórico entrenado o rivales pre-calibrados.
   - **Carretera Vertical (Endless)**: Supervivencia en autopista esquivando tráfico con rivales IA reactivos.
   - **Diferenciación Visual**: Rivales identificables por color (Azul Neón = Jugador, Verde/Oro = Líder Élite, Púrpura/Naranja = Rivales en aprendizaje).
   - **Soporte Multijugador Local**: Competencia 1v1 en el mismo teclado (WASD vs Flechas) o cooperativo contra la parrilla de IA.
3. **Evolución de Rivales (IA Adaptativa)**:
   - Redes neuronales feedforward y algoritmos genéticos continuos que permiten a los coches rivales aprender a trazar curvas y adaptarse sin requerir rutas precalculadas (*waypoints* fijos) ni trampas.
4. **Optimización de Físicas y Rendimiento (Estructuras de Datos)**:
   - **QuadTree ($O(\log n)$)**: Indexación espacial 2D de los segmentos de la pista para acelerar el raycasting de sensores y las colisiones de toda la parrilla.
   - **Max-Heap ($O(k \log n)$)**: Ranking y extracción instantánea del top-$k$ de mejores corredores para elitismo y cruce genético sin caídas de cuadros por segundo.
5. **Arquitectura Limpia en C++17**:
   - Programación Orientada a Objetos modular, pruebas unitarias automatizadas con **CTest** y flujo de trabajo estructurado en Git.
