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

5. **Modo Copa, Guardado de Generaciones y Equipos de IA**:
   * Competición por rondas con puntuación acumulada (25, 18, 15, 10, 8 pts...).
   * **Guardar Generación (`G`)**: Guarda en disco los pesos neuronales, velocidades máximas y estadísticas de todos los autos para reutilizarlos en cualquier momento.
   * **Selector de Equipos de IA (`L` / `T`)**: Permite elegir con qué equipo competir (*Novatos Aleatorios*, *Calibrados para Curvas*, *Élite de Copa* o *Tus Equipos Guardados*).
   * **Telemetría y Nivel de Entrenamiento (`I`)**: Ventana detallada con velocidades punta, mejores vueltas, nivel de entrenamiento (⭐ Nivel 1 al 10) y daños sufridos.
   * **Reinicio Completo (`F5` / `Shift + R`)**: Reinicia la Copa, las generaciones y los puntos a cero instantáneamente.
   * **Plano de Terreno Expandido ($1600 \times 1400$ m)**: La pista está completamente rodeada por un extenso paisaje verde sin cortes visuales.

---

## 🕹️ Controles del Juego

| Tecla / Ratón | Acción |
| :--- | :--- |
| **`TAB`** o **`P`** | **Alternar Modalidad**: Cambia entre **Modo Espectador Libre** y **Modo Piloto Humano**. |
| **`G`** | **Guardar Generación**: Guarda los pesos de la IA y telemetría de todos los autos en un archivo `.json`. |
| **`L`** o **`T`** | **Cargar / Cambiar Equipo IA**: Elige entre *Novatos*, *Calibrados*, *Élite* o tus equipos guardados. |
| **`I`** | **Telemetría Detallada**: Abre/cierra la tabla con velocidades punta, vueltas y nivel de entrenamiento. |
| **`F5`** o **`Shift + R`** | **Reiniciar Todo**: Vuelve la Copa y la generación a 1 con puntos en cero. |
| **`R`** *(sin Shift)* | **Siguiente Carrera**: Fuerza el fin de la ronda actual y evoluciona la generación. |
| **`Arrastrar Ratón`** | **Desplazar cámara**: Muévete libremente por toda la pista en la Vista Isométrica. |
| **`Rueda del Ratón`** *(Scroll)* | **Zoom**: Acércate o aléjate de cualquier curva o sector del circuito. |
| **`W`, `A`, `S`, `D`** o **`Flechas`** | Conducir tu auto (en Modo Piloto Humano) o desplazar la vista (en Modo Espectador). |
| **`C`** / **`Shift + C`** | Cambiar al siguiente / anterior auto en la pista para ver su telemetría. |
| **`V`** | Alternar modo de cámara (**Isométrica Libre**, **GTA Cenital**, **Isométrica Auto**, **3ª Persona**). |
| **`Espacio`** | Velocidad de simulación (**1x**, **2x**, **4x**). |
| **`ESC` / `Alt + F4`** | Salir del juego. |


---

## 🚀 Cómo Ejecutar

* **Directo a la simulación**: Haz doble clic en **`ejecutar_juego_godot.bat`**.
* **Abrir en el editor**: Haz doble clic en **`abrir_editor_godot.bat`**.
