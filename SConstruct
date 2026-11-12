#!/usr/bin/env python
import os

env = SConscript("godot-cpp/SConstruct")

# Rutas de encabezados: tu IA y las clases de Godot
env.Append(CPPPATH=[
    "include/ai",
    "src/godot"
])

sources = [
    "src/ai/NeuralNetwork.cpp",
    "src/godot/GodotBrain.cpp",
    "src/godot/register_types.cpp"
]

library = env.SharedLibrary(
    "godot_project/bin/libneurogenetica{}{}".format(env["suffix"], env["SHLIBSUFFIX"]),
    source=sources
)

env.NoCache(library)
Default(library)

