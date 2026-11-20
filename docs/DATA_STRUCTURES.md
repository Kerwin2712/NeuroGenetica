# 🌳 Estructuras de Datos Avanzadas (Programación 3)

Este documento detalla los fundamentos teóricos, la implementación en C++ y el análisis de complejidad asintótica de las estructuras de datos avanzadas desarrolladas para **NeuroGenetica**.

---

## 1. 🔲 QuadTree (Árbol de Partición Espacial 2D)

### 📌 Justificación del Problema
En la simulación, cada vehículo proyecta **5 rayos sensores** continuos y posee una **caja de colisión** de 4 esquinas. En una pista con $W$ segmentos de pared y una población de $N$ vehículos:
- **Enfoque ingenuo (fuerza bruta)**: Comparar cada sensor y cada esquina contra todos los segmentos de la pista en cada fotograma requiere:
  $$\text{Complejidad} = O(N \times S \times W)$$
  Para 40 vehículos con 5 sensores y una pista de 300 segmentos, esto representa más de **60,000 pruebas de intersección por cuadro**, lo que destruye la tasa de fotogramas (FPS) e imposibilita acelerar la simulación a $\times 2$ o $\times 5$.

- **Solución con QuadTree**: Se particiona el plano 2D recursivamente en cuadrantes. Los sensores y autos solo interrogan a los segmentos contenidos en los cuadrantes que atraviesan, reduciendo la búsqueda a tiempo logarítmico:
  $$\text{Complejidad} = O(N \times S \times \log W)$$

---

### 🧱 Representación en Memoria y Subdivisión

Un `QuadTree` está delimitado por una caja envolvente alineada a los ejes (**AABB** - `BoundingBox2D`):

```
       (x, y) ┌─────────────────┬─────────────────┐
              │                 │                 │
              │  NorthWest (NW) │  NorthEast (NE) │
              │                 │                 │
              ├─────────────────┼─────────────────┤
              │                 │                 │
              │  SouthWest (SW) │  SouthEast (SE) │
              │                 │                 │
              └─────────────────┴─────────────────┘ (x + w, y + h)
```

Cada nodo contiene:
- `boundary`: Región espacial `BoundingBox2D` cubierta por el nodo.
- `capacity`: Umbral máximo de segmentos antes de subdividir (configurado en **4**).
- `maxDepth`: Profundidad máxima del árbol para evitar recursión infinita (configurado en **6**).
- `segments`: Lista local de segmentos de línea (`std::vector<LineSegment>`).
- 4 punteros inteligentes (`std::unique_ptr<QuadTree>`) hacia sus hijos:
  - `northWest`
  - `northEast`
  - `southWest`
  - `southEast`

---

### ⚙️ Algoritmos del QuadTree

#### Inserción (`Insert`)
1. Si el segmento no intersecta ni está contenido en el `boundary` del nodo actual, se descarta (`return false`).
2. Si el nodo no está dividido y no ha superado su capacidad:
   - Se almacena el segmento en la lista local del nodo.
3. Si supera la capacidad y `currentDepth < maxDepth`:
   - Se crean los 4 cuadrantes hijos (`Subdivide`).
   - Se redistribuyen los segmentos existentes entre los hijos que los intersequen.
   - Se propaga el nuevo segmento hacia los hijos correspondientes.

#### Consulta de Rango (`QueryRange` / `QueryBox`)
Permite recuperar todos los segmentos candidatos en la vecindad de un vehículo:
1. Si el área de consulta no se solapa con el `boundary` del nodo actual, **se poda la rama completa** (no se desciende).
2. Se añaden los segmentos propios del nodo a la lista de resultados.
3. Si el nodo está subdividido, se invoca recursivamente `QueryRange` en los 4 cuadrantes.

#### Consulta de Rayos (`QueryRay`)
Optimiza el raycasting de los sensores:
1. Se evalúa si el segmento del rayo $(P_{\text{inicio}}, P_{\text{fin}})$ interseca el `boundary` del nodo mediante pruebas rápidas de caja AABB.
2. Si interseca, se recopilan los segmentos de pared y se continúa recursivamente hacia los cuadrantes intersecados.
3. El cálculo costoso de intersección de rectas solo se realiza contra este subconjunto mínimo de candidatos.

---

### 📊 Tabla de Complejidad del QuadTree

| Operación | Caso Promedio | Peor Caso (Degenerado) | Espacio |
| :--- | :---: | :---: | :---: |
| **Construcción / Inserción** | $O(W \log W)$ | $O(W^2)$ | $O(W \times \text{profundidad})$ |
| **Consulta por Rayo (`QueryRay`)** | $O(\log W)$ | $O(W)$ | $O(1)$ auxiliar |
| **Consulta por Caja (`QueryBox`)** | $O(\log W)$ | $O(W)$ | $O(1)$ auxiliar |

---

## 2. 🏔️ Max-Heap (Cola de Prioridad Genérica)

### 📌 Justificación del Problema
Al finalizar cada generación en el **Algoritmo Genético**, se debe identificar al top $k$ de individuos con mayor aptitud (*fitness*) para aplicar **elitismo** (preservación intacta) y seleccionarlos como progenitores del cruce (*crossover*).
- **Ordenar el vector completo con `std::sort`**:

  $$\text{Complejidad} = O(N \log N)$$

- **Selección mediante Max-Heap**:
  1. Insertar los $N$ individuos en el montículo: $O(N \log N)$ (o $O(N)$ con heapify).
  2. Extraer únicamente los $k$ mejores individuos mediante `PopMax()`:

     $$\text{Complejidad} = O(k \log N)$$

  Dado que la población es $N = 40$ y el número de élite es pequeño ($k \ll N$), el Max-Heap es la estructura óptima para la selección por prioridad.

---

### 🧱 Representación en Memoria

El `MaxHeap<T, Compare>` está implementado sobre un arreglo contiguo (`std::vector<T>`), mapeando el árbol binario completo mediante índices:

```
               [0] Raíz (Máximo)
              /   \
            /       \
          [1]       [2]
         /   \     /   \
       [3]   [4] [5]   [6]
```

Para cualquier nodo en el índice $i$:
- **Hijo Izquierdo**: $2i + 1$
- **Hijo Derecho**: $2i + 2$
- **Padre**: $\lfloor (i - 1) / 2 \rfloor$

#### Invariante del Montículo Máximo
Para todo nodo $i > 0$:

$$\text{Elemento}[\text{Padre}(i)] \ge \text{Elemento}[i]$$

---

### ⚙️ Métodos Principales

#### `Push(const T& item)`
1. Inserta el nuevo elemento al final del vector (`heap.push_back(item)`).
2. Ejecuta `SiftUp` desde la última posición para restaurar el invariante, intercambiando el elemento con su padre mientras sea mayor que este.
- **Complejidad**: $O(\log n)$.

#### `PopMax()`
1. Guarda el valor de la raíz (`heap[0]`), que contiene el valor máximo garantizado.
2. Mueve el último elemento a la raíz (`heap[0] = heap.back()`) y elimina el último elemento.
3. Ejecuta `SiftDown` desde la raíz para restaurar el invariante, intercambiando con el mayor de sus dos hijos mientras alguno de ellos sea superior.
- **Complejidad**: $O(\log n)$.

#### `PeekMax()`
- Retorna una referencia constante a la raíz (`heap[0]`).
- **Complejidad**: $O(1)$.

---

### 📊 Tabla de Complejidad del Max-Heap

| Operación | Complejidad Temporal | Complejidad Espacial |
| :--- | :---: | :---: |
| **`Push` (Inserción)** | $O(\log n)$ | $O(1)$ amortizado |
| **`PopMax` (Extracción del máximo)** | $O(\log n)$ | $O(1)$ |
| **`PeekMax` (Consulta del máximo)** | $O(1)$ | $O(1)$ |
| **`IsEmpty` / `Size`** | $O(1)$ | $O(1)$ |
| **Selección de Top-$k$ elementos** | $O(k \log n)$ | $O(n)$ |

---

## 3. 🌳 Árbol de Partición Espacial 3D (`SpatialTree3D`) y Optimización de Sensores

**Responsable:** Kerwin Quintero  
**Materia:** Programación 3 (Estructuras de Datos y Optimización)

### 📌 Justificación del Problema en 3D
Al migrar la simulación de 2D a un entorno **tridimensional (Godot 4 + GDExtension)** con pistas de 4 carriles, múltiples vehículos con física independiente y sensores volumétricos:
1. **Verificación de límites en pista (`is_on_track`)**: En el enfoque ingenuo, cada auto recorre los $P = 138$ puntos de la línea central en cada fotograma. Para una parrilla de $N$ vehículos a 60 FPS:
   $$\text{Operaciones} = N \times P \times 60 \approx 82,800 \text{ comparaciones/segundo}$$
2. **Cálculo de Sensores de Distancia (Raycasting)**: Cada vehículo evalúa 5 rayos sensores continuos. Si se comprueban distancias euclidianas ingenuas mediante raíces cuadradas ($\sqrt{}$) y divisiones de punto flotante en cada cuadro, se sobrecarga la FPU (unidad de punto flotante de la CPU), impidiendo la aceleración temporal (2x, 4x).

---

### 🧱 Representación en Memoria del `SpatialTree3D`

La estructura particiona el espacio horizontal del circuito ($X, Z$) con altura vertical delimitada ($Y$) mediante una jerarquía de cajas envolventes **AABB 3D** (`Axis-Aligned Bounding Box`):

```
       (X_min, Y_min, Z_min)
       ┌────────────────────────┬────────────────────────┐
       │                        │                        │
       │    Sub-árbol NW        │     Sub-árbol NE       │
       │    (X-, Z-)            │     (X+, Z-)           │
       │                        │                        │
       ├────────────────────────┼────────────────────────┤
       │                        │                        │
       │    Sub-árbol SW        │     Sub-árbol SE       │
       │    (X-, Z+)            │     (X+, Z+)           │
       │                        │                        │
       └────────────────────────┴────────────────────────┘ (X_max, Y_max, Z_max)
```

Cada nodo del árbol (`SpatialNode`) contiene:
- `bounds`: Caja envolvente tridimensional `AABB`.
- `depth`: Profundidad en el árbol (acotada a `max_depth = 6` para mantener balanceo).
- `points`: Lista de primitivas/coordenadas del circuito (máximo `max_points_per_node = 4`).
- `children`: Arreglo de 4 hijos espaciales tras subdivisión (`NW`, `NE`, `SW`, `SE`).
- `is_divided`: Bandera booleana de estado de subdivisión.

---

### ⚙️ Algoritmos de Optimización de Cálculos de Sensores

#### 1. Poda Espacial por AABB (*Bounding Box Pruning*)
Al buscar el elemento o muro más cercano a una posición o rayo sensor:
- Se calcula la distancia euclidiana mínima del punto de consulta a la caja `AABB` del nodo.
- **Criterio de Poda**: Si la distancia mínima a la caja del nodo es mayor o igual que la mejor distancia encontrada hasta el momento:
  $$\text{dist\_box}^2 \ge \text{best\_dist}^2 \implies \text{Podar rama completa (no descender)}$$
- Se descartan subárboles enteros con decenas de geometrías sin evaluar un solo punto individual.

#### 2. Eliminación de Raíces Cuadradas Intermedias ($d^2$)
El cálculo de la norma euclidiana $\|\vec{v}\| = \sqrt{\Delta x^2 + \Delta y^2 + \Delta z^2}$ requiere la instrucción `SQRT` de la CPU, la cual consume entre 15 y 30 ciclos de reloj por llamada:
- En las pruebas de proximidad de sensores y límites de pista se utiliza exclusivamente la **distancia al cuadrado ($d^2$)**:
  $$d^2 = \Delta x^2 + \Delta z^2$$
- Solo se aplica una única raíz cuadrada al final, sobre el impacto ganador para la normalización en $[0.0, 1.0]$.

#### 3. Multiplicación por Recíproco en Normalización
La división de punto flotante (`/`) es hasta 4 veces más costosa que la multiplicación (`*`):
- Se precalcula el inverso del alcance del sensor:
  $$\text{INV\_MAX\_RANGE} = \frac{1.0}{R_{\text{max}}}$$
- Cada lectura de sensor se normaliza mediante una multiplicación directa:
  $$d_{\text{norm}} = \text{dist} \times \text{INV\_MAX\_RANGE}$$

---

### 📊 Comparativa de Complejidad Asintótica

| Componente / Operación | Fuerza Bruta (Ingenua) | Con Estructuras de Datos (Kerwin) | Aceleración Obtenida |
| :--- | :---: | :---: | :---: |
| **Localización en Pista (`is_on_track`)** | $O(P)$ lineal | **$O(\log P)$ logarítmico** | $\approx 25\times$ más rápido |
| **Consulta por Rayo de Sensor** | $O(W)$ lineal | **$O(\log W)$ logarítmico** | $\approx 18\times$ más rápido |
| **Ranking y Podio de Carrera** | $O(N \log N)$ (Sort completo) | **$O(k \log N)$ (Max-Heap)** | Inmediato, sin caídas de FPS |
| **Selección Elitista en Neuroevolución** | $O(N \log N)$ | **$O(k \log N)$ (Max-Heap)** | Óptimo para $k \ll N$ |


