# 🏎️ Versión Godot Engine 4 (GDExtension C++)

Esta rama contiene la versión de **NeuroGenetica** integrada con **Godot 4** mediante **GDExtension**, manteniendo intacto el núcleo de Inteligencia Artificial (Redes Neuronales Feedforward y Algoritmo Genético) escrito en **C++17**.

---

## 🚀 Cómo probarlo en tu computadora (Para compañeros de equipo)

### Opción Rápida (Sin compilar nada)
La librería de C++ ya viene precompilada (`godot_project/bin/libneurogenetica.windows.template_debug.x86_64.dll`), por lo que **no necesitas tener instalado GCC, SCons ni Python para probarla**:

1. **Instalar Godot 4**:
   * Si tienes Windows, abre una terminal y ejecuta:
     ```powershell
     winget install GodotEngine.GodotEngine
     ```
   * O descárgalo directamente desde [godotengine.org/download](https://godotengine.org/download).
2. **Ejecutar la simulación**:
   * Haz doble clic en **`ejecutar_juego_godot.bat`**.
   * Verás la ventana con 30 autos aprendiendo a conducir con sus sensores en tiempo real.

---

### Opción con Editor de Godot
Si quieres explorar la pista, los sensores o la interfaz gráfica:
1. Haz doble clic en **`abrir_editor_godot.bat`** (o abre Godot e importa la carpeta `godot_project`).
2. Presiona **`F5`** para correr la simulación desde el editor.

---

## 🎮 Controles en el Juego

| Tecla / Control | Acción |
| :--- | :--- |
| **`Espacio`** | Acelera la simulación (**1x**, **2x**, **5x**). |
| **`R`** | Fuerza el fin de la generación actual y evoluciona a la siguiente. |
| **`ESC` / `Alt+F4`** | Salir del juego. |

---

## 🛠️ Recompilación de C++ (Opcional para desarrolladores)
Si modificas los archivos en `src/ai/` o `src/godot/`:
1. Instala SCons: `pip install scons`
2. Ejecuta: **`compilar_libreria_godot.bat`**

