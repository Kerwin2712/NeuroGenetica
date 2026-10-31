# 📚 Documentación Técnica de NeuroGenetica

Bienvenido al centro de documentación técnica y arquitectónica de **NeuroGenetica**. Este conjunto de documentos detalla en profundidad el diseño de software, los algoritmos matemáticos y las estructuras de datos avanzadas implementadas para la materia *Programación 3*.

---

## 🗺️ Mapa de Navegación

| Documento | Descripción | Temas Clave |
| :--- | :--- | :--- |
| **[Arquitectura de Software y Archivos](ARCHITECTURE.md)** | Visión integral de capas, componentes y árbol del repositorio. | Módulos Core, AI, Graphics, ciclo de vida del frame, flujo de datos. |
| **[Estructuras de Datos Avanzadas](DATA_STRUCTURES.md)** | Análisis teórico y práctico de los árboles y colas de prioridad. | QuadTree 2D, Max-Heap genérico, podado espacial, análisis de complejidad $O$. |
| **[Física, Red Neuronal y Neuroevolución](AI_AND_PHYSICS.md)** | Fundamentos matemáticos del simulador y del aprendizaje autónomo. | Cinemática 2D, Raycasting, ANN Feedforward, función de fitness, cruce y mutación. |

---

## 🎯 Correspondencia con Objetivos de Programación 3

1. **Estructuras de Datos Avanzadas**:
   - **QuadTree**: Partición espacial 2D recursiva para acelerar la detección de colisiones y consultas de sensores de $O(n \times m)$ a $O(\log n)$.
   - **Max-Heap**: Montículo binario genérico con comparadores para seleccionar eficientemente a los mejores individuos en $O(k \log n)$ sin requerir ordenamiento completo $O(n \log n)$.
2. **Programación Orientada a Objetos Moderna (C++17)**:
   - Desacoplamiento estricto por capas (`core`, `ai`, `graphics`).
   - Uso de semántica de movimiento, punteros inteligentes (`std::unique_ptr`), templates y RAII.
3. **Pruebas Unitarias Automatizadas (CTest)**:
   - Módulos validados independientemente en `tests/` antes de su integración visual.
4. **Flujo de Trabajo Profesional**:
   - Control de versiones con ramas `main <- development <- feature/*` y *Conventional Commits*.

