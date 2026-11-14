# 🏎️💨 NeuroGenetica 3D (Godot 4 + C++ GDExtension)

Versión **Tridimensional** de **NeuroGenetica** con física 3D, pistas de 4 carriles, colisiones reales entre vehículos, sistema de energía/resistencia por impactos, perspectivas de cámara dinámicas (incluyendo **Vista GTA Cenital** e **Isométrica**), **Modo Copa** y conducción humana en tiempo real compitiendo contra la IA en C++.

---

## ✨ Nuevas Características 3D

1. **Vehículos 3D con Daño y Resistencia (HP)**:
   * Chasis tridimensional con colores distintivos por auto, ruedas modeladas, faros con emisión de luz y partículas de humo en caso de avería.
   * **Sistema de Energía (100 HP)**: Los autos no mueren al primer roce; cada impacto (contra muros u otros autos) resta energía en función de la velocidad y el ángulo de colisión.
   * Si la energía llega a 0, el auto queda destruido y se detiene en la pista como obstáculo.

2. **Pistas 3D de 4 Carriles con Parrilla de Salida (Grid)**:
   * Circuito ancho (22m) con líneas discontinuas de carril, pianos/bordillos rojiblancos y muros de contención con colisiones tridimensionales.
   * **Parrilla de largada ordenada**: 10 autos colocados en 4 carriles (formación 4-4-2) con arranque limpio sin amontonamiento inicial.

3. **Cámaras Multi-Perspectiva (Tecla `V`)**:
   * 🎮 **Vista GTA Cenital (Top-Down)**: Cámara directa desde arriba del auto que rota suavemente acompañando la dirección de marcha (estilo *Grand Theft Auto 1 / 2 / Chinatown Wars*).
   * 📐 **Vista Isométrica de Coche**: Perspectiva a 45° siguiendo al vehículo (estilo *Circuit Superstars* / *Micro Machines*).
   * 🏎️ **Vista Tercera Persona (Chase)**: Trasera dinámica a ras de asfalto.
   * 🌐 **Vista Panorámica General**: Vista aérea de todo el circuito.

4. **Selección de Auto y Conducción Manual (Humano vs IA)**:
   * Pulsa **`C`** para alternar qué auto seguir con la cámara y ver su telemetría en el HUD.
   * Pulsa **`M`** para tomar el volante del auto enfocado y conducirlo tú mismo con **`W`, `A`, `S`, `D`** o las **`Flechas`**.

5. **Modo Copa**:
   * Competición por rondas con puntuación acumulada (25, 18, 15, 10, 8 pts...).
   * Tras cada ronda, los mejores genomas en C++ se cruzan (`crossover`) y mutan (`mutate`) para aprender a esquivar choques y trazar curvas más rápido.

---

## 🕹️ Controles del Juego

| Tecla / Ratón | Acción |
| :--- | :--- |
| **`TAB`** o **`P`** | **Alternar Modalidad**: Cambia entre **Modo Espectador Libre** y **Modo Piloto Humano**. |
| **`Arrastrar Ratón`** *(Clic Derecho/Izquierdo)* | **Desplazar cámara**: Muévete libremente por toda la pista en la Vista Isométrica. |
| **`Rueda del Ratón`** *(Scroll)* | **Zoom**: Acércate o aléjate de cualquier curva o sector del circuito. |
| **`W`, `A`, `S`, `D`** o **`Flechas`** | Conducir tu auto (en Modo Piloto Humano) o desplazar la vista (en Modo Espectador). |
| **`C`** / **`Shift + C`** | Cambiar al siguiente / anterior auto en la pista para ver su telemetría. |
| **`V`** | Alternar modo de cámara (**Isométrica Libre**, **GTA Cenital**, **Isométrica Auto**, **3ª Persona**). |
| **`Espacio`** | Velocidad de simulación (**1x**, **2x**, **4x**). |
| **`R`** | Forzar fin de ronda y avanzar a la siguiente carrera de la Copa. |
| **`ESC` / `Alt + F4`** | Salir del juego. |

---

## 🚀 Cómo Ejecutar

* **Directo a la simulación**: Haz doble clic en **`ejecutar_juego_godot.bat`**.
* **Abrir en el editor**: Haz doble clic en **`abrir_editor_godot.bat`**.
