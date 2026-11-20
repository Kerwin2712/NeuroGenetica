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

5. **Pantalla de Inicio y Menú de Modos**:
   * Pantalla de inicio con fondo 3D dinámico para elegir el modo de juego:
     * **Modo Copa (Humano vs IAs)**: El jugador entra al volante en parrilla compitiendo contra 9 rivales de IA.
     * **Modo Espectador**: Carrera de IAs con cámara isométrica libre.
   * **Selector de Escuderías Rival Pre-entrenadas**:
     * 🔰 *Escudería Novatos*: Redes neuronales aprendiendo desde cero.
     * 🏎️ *Escudería GT Pro*: Redes calibradas en curvas rápidas.
     * 👑 *Escudería Élite*: Redes agresivas de alta velocidad y adelantamientos.
     * 📂 *Equipos Guardados*: Archivos guardados por ti con la tecla `G`.

6. **Semáforo de Salida Oficial (Countdown)**:
   * Antes de iniciar la carrera, todos los vehículos permanecen congelados en la parrilla.
   * El semáforo realiza la cuenta regresiva oficial: **🔴 3... 🔴🔴 2... 🔴🔴🔴 1... 🟢🟢🟢 ¡¡GO!!**
   * Al encenderse las luces verdes, todos los autos aceleran al unísono.

7. **Pantalla de Resultados y Podio de la Copa**:
   * Al cruzar la meta tras 2 vueltas o completarse el tiempo:
     * Anuncio de ganador y podio oficial (1º, 2º, 3º...).
     * Tabla con tiempos de carrera, velocidad punta, vueltas y puntos de Copa sumados.
     * Botones para pasar a la siguiente ronda, reintentar la carrera o volver al menú.

8. **Estructuras de Datos Avanzadas y Optimización de Sensores (Programación 3)**:
   * **`SpatialTree3D` (Árbol de Partición Espacial 3D)**:
     * Indexa los 138 puntos de la pista y muros en una jerarquía de cajas envolventes 3D (`AABB`).
     * Reduce la comprobación de límites de pista (`is_on_track`) de un escaneo lineal $O(P)$ a búsqueda en tiempo logarítmico **$O(\log P)$**.
     * Poda automática de ramas lejanas para no desperdiciar ciclos de CPU.
   * **`MaxHeap` (Montículo Binario / Cola de Prioridad)**:
     * Clasificación de podio y ranking de la carrera en tiempo **$O(k \log N)$** mediante `SiftDown`.
     * Selección de los mejores individuos élite para evolución entre rondas de la Copa sin necesidad de ordenar todo el arreglo.
   * **Optimización de Cálculos de Sensores**:
     * Eliminación de raíces cuadradas ($\sqrt{}$) en comprobaciones intermedias mediante distancias al cuadrado ($d^2$).
     * Multiplicación por recíproco precalculado (`INV_MAX_RANGE`) para evitar divisiones de coma flotante.
   * Puedes ver estas métricas en tiempo real pulsando la tecla **`I`** (ventana de telemetría).

---

## 🕹️ Controles del Juego

| Tecla / Ratón | Acción |
| :--- | :--- |
| **`ESC`** | **Volver al Menú Principal** (durante la carrera) o **Salir del Juego** (en el Menú Principal). |
| **`F11`** | **Pantalla Completa / Modo Ventana**: Alterna instantáneamente el tamaño de pantalla. |
| **`Q`** | **Ver Divisiones de Pista 3D y Sensores**: Activa/desactiva las cajas del `SpatialTree3D` y los 5 rayos sensores de cada auto (verde/amarillo/rojo según distancia). |
| **`TAB`** | **Alternar Modalidad** (Modo Copa Humano $\leftrightarrow$ Modo Espectador Libre). |
| **`G`** | **Guardar Generación**: Guarda los cerebros y datos en archivo `.json`. |
| **`I`** | **Ver Telemetría y Estadísticas**: Abre/cierra la tabla completa de rendimiento. |
| **`F5`** o **`Shift + R`** | **Reiniciar Todo**: Vuelve la Copa a Ronda 1, Gen 1 y puntos a cero. |
| **`R`** *(sin Shift)* | **Bandera a Cuadros**: Termina la carrera actual y abre la pantalla de resultados. |
| **`Arrastrar Ratón`** | **Desplazar la vista libremente** por la pista (en vista isométrica). |
| **`Rueda del Ratón`** *(Scroll)* | **Zoom In / Zoom Out** suave sobre cualquier curva o auto. |
| **`W`, `A`, `S`, `D`** / **`Flechas`** | Conducir tu auto (Modo Copa) o desplazar la vista (Modo Espectador). |
| **`C`** / **`Shift + C`** | Cambiar el auto enfocado para ver su cámara y sensores. |
| **`V`** | Alternar modo de cámara (**GTA Cenital**, **Isométrica Libre**, **Isométrica Auto**, **3ª Persona**). |
| **`Espacio`** | Velocidad de simulación (**1x**, **2x**, **4x**). |



---

## 🚀 Cómo Ejecutar

* **Directo a la simulación**: Haz doble clic en **`ejecutar_juego_godot.bat`**.
* **Abrir en el editor**: Haz doble clic en **`abrir_editor_godot.bat`**.
