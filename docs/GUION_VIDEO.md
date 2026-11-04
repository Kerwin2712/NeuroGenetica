# 🎬 Guion de Exposición y Grabación de Video: NeuroGenetica

Este documento contiene el guion técnico y narrativo detallado para grabar el video de presentación y defensa del proyecto **NeuroGenetica** para la materia *Programación 3*.

---

## 📋 Ficha Técnica del Video

- **Duración Estimada Total**: 5 a 7 minutos.
- **Herramienta de Grabación recomendada**: [OBS Studio](https://obsproject.com/) o [Loom](https://www.loom.com/) a 1080p y 60 FPS.
- **Recursos a proyectar durante la grabación**:
  1. **Visualizador Dinámico**: Abrir [`docs/showcase.html`](showcase.html) en el navegador web (presionar <kbd>F11</kbd> para pantalla completa limpia).
  2. **Juego en Vivo**: Ejecutable [`build/NeuroGenetica.exe`](../build/NeuroGenetica.exe) compilado con Raylib.
  3. **Terminal de Tests**: Ejecución de pruebas unitarias (`ctest --test-dir build --output-on-failure`).
- **Participantes**:
  - **Rafael Hernandez**: Motor Gráfico, Gamificación y Modos de Juego.
  - **Javier Olivieri**: Cinemática, Raycasting de Sensores y Estructura QuadTree 2D.
  - **Kerwin Quintero**: Red Neuronal Feedforward, Neuroevolución y Estructura Max-Heap.

---

## ⏱️ Estructura y Cronograma del Video

| Bloque / Escena | Tiempo Estimado | Responsable Sugerido | Recurso en Pantalla |
| :--- | :---: | :---: | :--- |
| **Escena 1: Introducción y Propuesta Jugable** | 00:00 - 01:15 | Rafael Hernandez | `showcase.html` (Diapositiva 1 y Pestaña *Modos de Juego*) |
| **Escena 2: Cinemática, Sensores y QuadTree** | 01:15 - 02:45 | Javier Olivieri | `showcase.html` (Pestaña *QuadTree en Vivo*) |
| **Escena 3: Red Neuronal y Max-Heap** | 02:45 - 04:15 | Kerwin Quintero | `showcase.html` (Pestañas *Red Neuronal* y *Max-Heap*) |
| **Escena 4: Demostración del Videojuego en Raylib** | 04:15 - 05:45 | Todo el equipo | Ventana de `NeuroGenetica.exe` (conducción y evolución) |
| **Escena 5: Pruebas CTest, Git Flow y Cierre** | 05:45 - 06:30 | Todo el equipo | Terminal con `ctest` y Diapositiva Final |

---

## 🎙️ Guion Paso a Paso (Locución y Acciones)

---

### 🎬 Escena 1: Introducción y Propuesta Jugable [00:00 - 01:15]

#### 🖥️ En Pantalla:
1. Abrir `docs/showcase.html` en pantalla completa (<kbd>F11</kbd>).
2. Comenzar en la pestaña **Diapositivas Video** (Diapositiva 1).
3. A los 40 segundos, hacer clic en la pestaña **Modos de Juego** para mostrar las tarjetas interactivas de *Modo Copa*, *Carrera Única*, *Carretera Vertical* y la diferenciación de rivales por color.

#### 🗣️ Locución (Rafael Hernandez):
> "Saludos a todos. Bienvenidos a la presentación de **NeuroGenetica**, nuestro proyecto para la materia Programación 3, desarrollado por Javier Olivieri, Kerwin Quintero y mi persona, Rafael Hernandez, bajo la tutoría del profesor Alejandro Mujica y los preparadores Jesús León y Sarai Rojas.
>
> Nuestra propuesta consiste en el desarrollo de un **Videojuego de Carreras interactivo en C++17** con la biblioteca gráfica Raylib, donde el jugador no solo recorre circuitos cerrados, sino que compite en tiempo real contra rivales controlados por **Inteligencia Artificial Adaptativa**.
>
> Diseñamos el juego bajo un enfoque de gamificación que contempla:
> - El **Modo Copa**, donde los rivales compiten en múltiples pistas y refinan su aprendizaje tras cada carrera.
> - La **Carrera Única**, para enfrentarse a modelos de IA pre-entrenados o al récord histórico.
> - Y la modalidad de **Carretera Vertical**, un formato de tráfico y supervivencia.
>
> Cada vehículo cuenta con identificación visual por colores: el auto del jugador en azul neón, los líderes élite en oro y los rivales en aprendizaje en tonos púrpuras.
>
> Para garantizar que un videojuego con decenas de autos inteligentes funcione de forma fluida a 60 fotogramas por segundo, integramos dos estructuras de datos avanzadas que optimizan las físicas y la selección: el **QuadTree** y el **Max-Heap**."

---

### 🎬 Escena 2: Cinemática, Sensores y Estructura QuadTree [01:15 - 02:45]

#### 🖥️ En Pantalla:
1. Cambiar a la pestaña **🔲 QuadTree en Vivo** en `showcase.html`.
2. Mover el auto con las teclas `W/A/S/D` o el ratón para que los 5 rayos sensores choquen contra los muros de la pista.
3. Señalar con el cursor el recuadro ámbar que se ilumina (el cuadrante activo del árbol) y la barra de métricas de aceleración algorítmica ($O(\log n)$ vs $O(n \times m)$).

#### 🗣️ Locución (Javier Olivieri):
> "Hola a todos, les habla Javier Olivieri. Yo estuve a cargo de la física cinemática del vehículo, el sistema de sensores y la estructura espacial del QuadTree.
>
> En el juego, cada coche proyecta **5 rayos de sensores** frontales que miden distancias normalizadas hacia los límites del circuito. Si utilizáramos un enfoque ingenuo de fuerza bruta para verificar cada rayo de cada coche contra todos los segmentos de la pista, estaríamos realizando decenas de miles de cálculos de intersección por cuadro, con una complejidad de $O(N \times S \times W)$, lo cual colapsaría el rendimiento del juego.
>
> Para solucionar esto, implementamos un **QuadTree (Árbol de Partición Espacial 2D)**. El QuadTree divide recursivamente el plano en cuatro cuadrantes: Noroeste, Noreste, Suroeste y Sureste, con una capacidad máxima de 4 segmentos por nodo.
>
> Como pueden observar en este simulador interactivo en pantalla, cuando el vehículo se desplaza y emite sus rayos sensores, el árbol realiza un **podado espacial inmediato**. Solo interroga a los segmentos contenidos en los cuadrantes que los rayos atraviesan, reduciendo la complejidad a **$O(\log W)$** por consulta.
>
> Esto nos otorga una aceleración de más de 10 veces en los cálculos espaciales, permitiendo que la simulación y las colisiones corran de forma perfectamente estable a 60 FPS e incluso a velocidades aceleradas de 2x y 5x."

---

### 🎬 Escena 3: Redes Neuronales y Selección con Max-Heap [02:45 - 04:15]

#### 🖥️ En Pantalla:
1. Cambiar a la pestaña **🧠 Red Neuronal**. Mover los sliders de sensores para ver cómo cambian las conexiones y las salidas de viraje y aceleración. Presionar el botón *"🎲 Mutar Pesos"*.
2. A los 3:30, cambiar a la pestaña **🏔️ Max-Heap**. Mostrar el árbol binario de los coches y presionar el botón *"PopMax() [Extraer Líder]"* para mostrar la extracción animada del Top-2 de élite.

#### 🗣️ Locución (Kerwin Quintero):
> "Buenas a todos, les habla Kerwin Quintero. Yo me encargué del cerebro de los vehículos, la neuroevolución y la estructura de datos Max-Heap.
>
> Cada vehículo enemigo está controlado por una **Red Neuronal Artificial Feedforward**. Recibe 6 entradas normalizadas: las 5 lecturas de distancia de los sensores más la velocidad actual. Estas señales pasan por una capa oculta de 8 neuronas con función de activación tangente hiperbólica ($\tanh$), y generan 2 salidas continuas: el ángulo de viraje y la aceleración o frenado. En total, cada coche posee un genoma lineal de 74 parámetros flotantes.
>
> Para que los rivales aprendan a conducir sin necesidad de un entrenamiento supervisado tradicional, usamos un **Algoritmo Genético**. Evaluamos la aptitud o *fitness* de cada individuo según la cantidad de checkpoints superados de forma secuencial, premiando el avance y penalizando la inactividad.
>
> Aquí entra nuestra segunda estructura de datos clave: el **Max-Heap o Cola de Prioridad genérica**, implementado en C++ mediante templates.
>
> Al finalizar cada generación, no necesitamos ordenar toda la población de 40 autos con algoritmos de costo $O(n \log n)$. En su lugar, insertamos los participantes en el Max-Heap y extraemos a los dos mejores mediante la operación `PopMax()`, garantizando la selección de élite en tiempo **$O(k \log n)$** gracias al algoritmo `SiftDown`.
>
> Estos líderes pasan intactos a la siguiente ronda, y mediante cruce genético uniforme y mutación gaussiana continua en sus pesos, la siguiente generación de rivales es progresivamente más hábil y competitiva."

---

### 🎬 Escena 4: Demostración del Videojuego en Raylib [04:15 - 05:45]

#### 🖥️ En Pantalla:
1. Minimizar el navegador y abrir la ventana del ejecutable compilado: `NeuroGenetica.exe`.
2. Mostrar la pantalla de inicio con la pista de Gran Premio, los pianos bicolores y la meta.
3. **Modo Manual**: Manejar el auto azul con `WASD` para demostrar la respuesta física del vehículo y las líneas de impacto de los sensores.
4. **Modo Autónomo / IA**: Presionar la tecla `M` para activar la población genética completa. Mostrar cómo la IA evalúa a los coches.
5. **Aceleración**: Presionar la `Barra Espaciadora` para alternar la simulación a $\times 2$ y $\times 5$, mostrando la fluidez del juego.
6. **Debug QuadTree**: Presionar la tecla `Q` para hacer visibles las líneas de subdivisión del QuadTree en tiempo real sobre la pista.
7. Señalar el panel **HUD en el centro de la pista** con las estadísticas en vivo (generación, autos vivos, mejor fitness histórico y telemetría).

#### 🗣️ Locución (Rafael Hernandez / Equipo):
> "Ahora pasamos a ver la ejecución real del juego compilado en C++ con Raylib.
>
> En pantalla observamos el circuito de Gran Premio generado con splines Catmull-Rom y sus 69 checkpoints transversales invisibles que impiden cualquier tipo de trampa, como girar en círculos o retroceder.
>
> En el modo manual, el jugador humano tiene el control total con WASD. Pero si presionamos la tecla **M**, activamos la simulación de la población autónoma.
>
> Vean cómo los coches de la primera generación cometen errores iniciales al explorar la pista, pero aquellos que logran superar más curvas son seleccionados por el Max-Heap. Si aceleramos el tiempo a **2x o 5x con la barra espaciadora**, podemos observar cómo en pocas generaciones los rivales perfeccionan su trazado y aprenden a recortar pianos y esquivar muros a alta velocidad.
>
> Al presionar la tecla **Q**, se hace visible la subdivisión dinámica del QuadTree sobre la pista, demostrando cómo la estructura de datos opera en cada milisegundo de ejecución."

---

### 🎬 Escena 5: Pruebas Unitarias CTest, Git Flow y Cierre [05:45 - 06:30]

#### 🖥️ En Pantalla:
1. Abrir la terminal y ejecutar el comando:
   ```bash
   ctest --test-dir build --output-on-failure
   ```
2. Mostrar la salida con el **100% de pruebas pasando** (`QuadTreeTests`, `NeuralNetworkTests`, `GeneticAlgorithmTests`).
3. Volver a la última diapositiva de `showcase.html` o al repositorio de GitHub para mostrar el historial de ramas y commits atómicos.

#### 🗣️ Locución (Todo el equipo):
> "Para finalizar, queremos destacar la rigurosidad técnica de la entrega:
> - El proyecto está validado al 100% mediante suites de pruebas unitarias integradas con **CTest**, que garantizan la correctitud matemática de la partición espacial, el forward pass de la red neuronal y las propiedades del montículo máximo antes de conectarse a la interfaz visual.
> - Todo el desarrollo siguió un flujo estricto de Git con ramas `main`, `development` y ramas de características, utilizando commits atómicos bajo el estándar Conventional Commits y asegurando que ningún binario compilado esté en el repositorio.
> - El código compila de forma nativa tanto en Windows como en Linux gracias a CMake y FetchContent.
>
> Esperamos que hayan disfrutado de la demostración de **NeuroGenetica**. Muchas gracias por su atención."

---

## 💡 Consejos Prácticos para la Grabación

1. **Resolución y Fuente**: Graba a 1920x1080. En el navegador, pulsa <kbd>F11</kbd> para ocultar pestañas y barra de direcciones.
2. **Audio Nítido**: Usa auriculares con micrófono o un micrófono condensador en un espacio silencioso.
3. **Distribución de Roles**: Si graban por separado, cada integrante puede grabar su fragmento de pantalla y voz, y luego unirlos con cualquier editor de video sencillo (como CapCut, Clipchamp o DaVinci Resolve).
4. **Guion Visible en Otra Pantalla**: Ten este archivo `GUION_VIDEO.md` abierto en tu teléfono, tablet o en un segundo monitor mientras grabas la pantalla principal con `showcase.html` y el ejecutable.
