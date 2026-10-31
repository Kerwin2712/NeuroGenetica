# 🧠 Física, Redes Neuronales y Neuroevolución

Este documento detalla los principios matemáticos, el modelo físico 2D y la arquitectura de aprendizaje por neuroevolución implementados en **NeuroGenetica**.

---

## 1. 🏎️ Modelo Cinemático del Vehículo

El movimiento del vehículo se calcula mediante cinemática 2D en tiempo discreto:

### Parámetros Físicos
- $\vec{p} = (x, y)$: Posición actual en el plano.
- $\theta$: Ángulo de orientación en radianes (donde $0$ apunta a la derecha, en el eje $+X$).
- $v$: Velocidad escalar lineal.
- $a_{\text{max}}$: Aceleración máxima hacia adelante.
- $\mu$: Coeficiente de fricción aerodinámica y de rodamiento ($0 < \mu < 1$).
- $\omega$: Tasa de viraje angular.

### Ecuaciones de Movimiento por Fotograma

1. **Aceleración y Fricción**:
   Dado el comando de aceleración $u_a \in [-1, 1]$:
   $$v_{t+1} = (v_t + u_a \cdot a) \cdot (1 - \mu)$$
   La velocidad está acotada entre una velocidad máxima de reversa y avance:
   $$-v_{\text{max\_rev}} \le v_{t+1} \le v_{\text{max}}$$

2. **Rotación Dependiente de la Velocidad**:
   Dado el comando de viraje $u_s \in [-1, 1]$:
   Un vehículo real no puede rotar sobre su propio eje si está detenido. Por ende, la velocidad angular es proporcional a la velocidad lineal:
   $$\theta_{t+1} = \theta_t + u_s \cdot \omega \cdot \left(\frac{v_{t+1}}{v_{\text{max}}}\right)$$

3. **Integración de Posición**:
   $$\vec{p}_{t+1} = \vec{p}_t + \begin{pmatrix} v_{t+1} \cos(\theta_{t+1}) \\ v_{t+1} \sin(\theta_{t+1}) \end{pmatrix} \cdot \Delta t$$

---

## 2. 📡 Sistema de Sensores (Raycasting)

Cada vehículo cuenta con **5 sensores de distancia ultrasónicos/ópticos simulados**, distribuidos en abanico frontal:

```
            -30°       0°       +30°
              \        |        /
               \       |       /
       -60° ----\      |      /---- +60°
                 \     |     /
                  ┌────┴────┐
                  │   Auto  │
                  └─────────┘
```

- **Ángulos de Proyección**: $\{-60^\circ, -30^\circ, 0^\circ, +30^\circ, +60^\circ\}$.
- **Alcance Máximo ($R_{\text{max}}$)**: 150 píxeles.
- **Normalización**:
  Para cada rayo $i$, la lectura entregada a la red neuronal es:
  $$d_i = \frac{\text{distancia\_impacto}}{R_{\text{max}}} \in [0.0, 1.0]$$
  Donde:
  - $0.0$: Obstáculo inmediato (colisión inminente).
  - $1.0$: Espacio totalmente despejado dentro del rango del sensor.

---

## 3. 🧠 Red Neuronal Feedforward

Cada agente es controlado por una **Red Neuronal Artificial (ANN)** multicapa completamente conectada (*Dense Feedforward*).

```
   Capa de Entrada (6)         Capa Oculta (8)           Capa de Salida (2)
   ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
   │ Sensor -60° (d0)│───┐   │                 │   ┌───│ Viraje [-1, 1]  │
   │ Sensor -30° (d1)│───┼──►│  Neuronas con   │───┤   └─────────────────┘
   │ Sensor   0° (d2)│───┼──►│   Activación    │   │   ┌─────────────────┐
   │ Sensor +30° (d3)│───┼──►│  Tanh(z) en R   │───┴──►│ Acel/Freno[-1, 1│
   │ Sensor +60° (d4)│───┼──►│                 │       └─────────────────┘
   │ Velocidad norm  │───┘   └─────────────────┘
   └─────────────────┘
```

### Formulación Matemática

1. **Capa Oculta**:
   $$\vec{z}_h = \mathbf{W}_1 \cdot \vec{x} + \vec{b}_1$$
   $$\vec{a}_h = \tanh(\vec{z}_h)$$
   Donde $\mathbf{W}_1 \in \mathbb{R}^{8 \times 6}$ y $\vec{b}_1 \in \mathbb{R}^8$.

2. **Capa de Salida**:
   $$\vec{z}_o = \mathbf{W}_2 \cdot \vec{a}_h + \vec{b}_2$$
   $$\vec{y} = \tanh(\vec{z}_o)$$
   Donde $\mathbf{W}_2 \in \mathbb{R}^{2 \times 8}$ y $\vec{b}_2 \in \mathbb{R}^2$.

3. **Interpretación de las Salidas**:
   - $y_0 \in [-1, 1]$: Control de viraje ($-1$ = izquierda máxima, $+1$ = derecha máxima).
   - $y_1 \in [-1, 1]$: Control de acelerador/freno ($-1$ = freno total / reversa, $+1$ = aceleración máxima).

### Genoma Lineal
Todas las matrices de pesos y vectores de sesgo se serializan en un único vector continuo unidimensional:
$$\text{Genoma} = [\mathbf{W}_1, \vec{b}_1, \mathbf{W}_2, \vec{b}_2] \in \mathbb{R}^{74}$$
- Pesos capa oculta: $8 \times 6 = 48$.
- Sesgos capa oculta: $8$.
- Pesos capa salida: $2 \times 8 = 16$.
- Sesgos capa salida: $2$.
- **Total de genes por individuo**: **74 parámetros en punto flotante**.

---

## 4. 🧬 Algoritmo Genético y Neuroevolución

A diferencia del entrenamiento supervisado tradicional con retropropagación (*Backpropagation*), la neuroevolución optimiza los pesos de la red a través de la selección natural:

### 1. Función de Aptitud (Fitness)
El fitness mide el progreso real a lo largo del circuito:
$$\text{Fitness} = (\text{Checkpoints Superados} \times 1000) + \text{Distancia Recorrida} - \text{Penalización por Inactividad}$$

#### Mecanismos Anti-Trampas
- **Validación Secuencial**: Un auto solo puede registrar el checkpoint $k+1$ si acaba de validar el checkpoint $k$. No puede ganar puntos retrocediendo o girando en círculos.
- **Temporizador de Inactividad**: Si un auto no alcanza un nuevo checkpoint en más de **2.5 segundos** o permanece inmóvil, se marca inmediatamente como colisionado/muerto para no ralentizar la generación.

### 2. Selección por Elitismo (Max-Heap)
- Al culminar la generación, los 40 individuos se insertan en un `MaxHeap`.
- Se extraen los $k = 2$ mejores individuos ($O(k \log N)$), cuyos genomas pasan **100% intactos** a la siguiente generación, asegurando que la aptitud histórica nunca decrezca.

### 3. Cruce Genético (Uniform Crossover)
Para engendrar nuevos individuos a partir de los progenitores élite $P_A$ y $P_B$:
$$\text{Hijo}_i = \begin{cases} P_{A, i} & \text{si } r < 0.5 \\ P_{B, i} & \text{si } r \ge 0.5 \end{cases}$$
Donde $r \sim \mathcal{U}(0, 1)$ se genera aleatoriamente para cada uno de los 74 genes.

### 4. Mutación Gaussiana Continua
Con una tasa de mutación del **10%** por gen:
$$\text{Gen}' = \text{Gen} + \mathcal{N}(0, \sigma^2)$$
Donde la perturbación $\sigma = 0.30$ altera suavemente los pesos sin destruir las representaciones aprendidas previamente.

