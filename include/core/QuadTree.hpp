#pragma once
#include "Geometry.hpp"
#include <vector>
#include <memory>

class QuadTree {
public:
    QuadTree(BoundingBox2D boundary, int capacity = 4, int maxDepth = 6, int currentDepth = 0);
    ~QuadTree() = default;

    // Inserción de un segmento de línea en el árbol espacial
    bool Insert(const LineSegment& segment);

    // Consulta de segmentos candidatos dentro de una región (AABB)
    void QueryRange(const BoundingBox2D& range, std::vector<LineSegment>& found) const;

    // Consulta de segmentos candidatos que puedan intersectar un rayo
    void QueryRay(Vector2 rayStart, Vector2 rayEnd, std::vector<LineSegment>& found) const;

    // Consulta de segmentos candidatos para una caja de colisión del auto
    void QueryBox(const BoundingBox2D& box, std::vector<LineSegment>& found) const;

    // Limpiar todos los nodos y segmentos
    void Clear();

    // Dibuja las subdivisiones de los cuadrantes para depuración y visualización académica
    void DrawDebug() const;

    // Métricas del árbol
    int GetTotalNodes() const;
    int GetTotalSegments() const;
    int GetMaxDepthReached() const;

private:
    void Subdivide();

    BoundingBox2D boundary;
    int capacity;
    int maxDepth;
    int currentDepth;
    bool isDivided;

    std::vector<LineSegment> segments;

    std::unique_ptr<QuadTree> northWest;
    std::unique_ptr<QuadTree> northEast;
    std::unique_ptr<QuadTree> southWest;
    std::unique_ptr<QuadTree> southEast;
};
