#pragma once
#include <vector>
#include <stdexcept>
#include <utility>

// Estructura de Datos Avanzada: Max-Heap (Cola de Prioridad) para Programación 3
// Permite ordenar y seleccionar eficientemente a los mejores individuos en O(k log n)
template <typename T, typename Compare = std::less<T>>
class MaxHeap {
public:
    MaxHeap(Compare comparator = Compare())
        : comp(comparator)
    {
    }

    // Inserción en O(log n)
    void Push(const T& item) {
        heap.push_back(item);
        SiftUp(heap.size() - 1);
    }

    // Extracción del elemento máximo en O(log n)
    T PopMax() {
        if (IsEmpty()) {
            throw std::runtime_error("Intento de PopMax en un MaxHeap vacío.");
        }
        T maxValue = heap[0];
        heap[0] = heap.back();
        heap.pop_back();

        if (!heap.empty()) {
            SiftDown(0);
        }
        return maxValue;
    }

    // Consulta del máximo en O(1)
    const T& PeekMax() const {
        if (IsEmpty()) {
            throw std::runtime_error("Intento de PeekMax en un MaxHeap vacío.");
        }
        return heap[0];
    }

    bool IsEmpty() const {
        return heap.empty();
    }

    size_t Size() const {
        return heap.size();
    }

    void Clear() {
        heap.clear();
    }

private:
    void SiftUp(size_t index) {
        while (index > 0) {
            size_t parent = (index - 1) / 2;
            if (comp(heap[parent], heap[index])) {
                std::swap(heap[parent], heap[index]);
                index = parent;
            } else {
                break;
            }
        }
    }

    void SiftDown(size_t index) {
        size_t size = heap.size();
        while (true) {
            size_t largest = index;
            size_t left = 2 * index + 1;
            size_t right = 2 * index + 2;

            if (left < size && comp(heap[largest], heap[left])) {
                largest = left;
            }
            if (right < size && comp(heap[largest], heap[right])) {
                largest = right;
            }

            if (largest != index) {
                std::swap(heap[index], heap[largest]);
                index = largest;
            } else {
                break;
            }
        }
    }

    std::vector<T> heap;
    Compare comp;
};
