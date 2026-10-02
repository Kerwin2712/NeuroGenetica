#include "QuadTree.hpp"
#include <iostream>
#include <cassert>
#include <cmath>

void TestQuadTreeCreation() {
    BoundingBox2D box = { 0.0f, 0.0f, 100.0f, 100.0f };
    QuadTree qt(box, 4, 4);

    assert(qt.GetTotalNodes() == 1);
    assert(qt.GetTotalSegments() == 0);
    std::cout << "[PASS] TestQuadTreeCreation\n";
}

void TestQuadTreeInsertionAndSubdivision() {
    BoundingBox2D box = { 0.0f, 0.0f, 100.0f, 100.0f };
    QuadTree qt(box, 2, 4); // Capacidad 2

    LineSegment s1 = { { 10.0f, 10.0f }, { 20.0f, 20.0f }, 1 };
    LineSegment s2 = { { 30.0f, 30.0f }, { 40.0f, 40.0f }, 2 };
    assert(qt.Insert(s1));
    assert(qt.Insert(s2));
    assert(qt.GetTotalNodes() == 1);

    // Al insertar el tercer segmento debe subdividirse
    LineSegment s3 = { { 80.0f, 80.0f }, { 90.0f, 90.0f }, 3 };
    assert(qt.Insert(s3));
    assert(qt.GetTotalNodes() > 1); // Ahora tiene 4 hijos
    std::cout << "[PASS] TestQuadTreeInsertionAndSubdivision\n";
}

void TestQuadTreeSpatialRangeQuery() {
    BoundingBox2D box = { 0.0f, 0.0f, 1000.0f, 1000.0f };
    QuadTree qt(box, 2, 5);

    // Segmento en la esquina superior izquierda
    LineSegment topSeg = { { 50.0f, 50.0f }, { 150.0f, 50.0f }, 10 };
    // Segmento en la esquina inferior derecha
    LineSegment bottomSeg = { { 850.0f, 850.0f }, { 950.0f, 850.0f }, 20 };

    qt.Insert(topSeg);
    qt.Insert(bottomSeg);

    // Consultar solo la región superior izquierda
    BoundingBox2D topRegion = { 0.0f, 0.0f, 300.0f, 300.0f };
    std::vector<LineSegment> found;
    qt.QueryRange(topRegion, found);

    assert(found.size() == 1);
    assert(found[0].id == 10);

    // Consultar la región inferior derecha
    BoundingBox2D bottomRegion = { 700.0f, 700.0f, 300.0f, 300.0f };
    found.clear();
    qt.QueryRange(bottomRegion, found);

    assert(found.size() == 1);
    assert(found[0].id == 20);

    std::cout << "[PASS] TestQuadTreeSpatialRangeQuery (Podado espacial verificado)\n";
}

void TestLineIntersectionMath() {
    Vector2 p1 = { 0.0f, 0.0f };
    Vector2 p2 = { 10.0f, 10.0f };
    Vector2 p3 = { 0.0f, 10.0f };
    Vector2 p4 = { 10.0f, 0.0f };

    Vector2 hit;
    float t;
    bool intersects = CheckLineIntersection(p1, p2, p3, p4, hit, t);

    assert(intersects);
    assert(std::abs(hit.x - 5.0f) < 1e-4f);
    assert(std::abs(hit.y - 5.0f) < 1e-4f);
    assert(std::abs(t - 0.5f) < 1e-4f);

    // Segmentos paralelos
    Vector2 p5 = { 0.0f, 5.0f };
    Vector2 p6 = { 10.0f, 15.0f };
    bool parallelIntersects = CheckLineIntersection(p1, p2, p5, p6, hit, t);
    assert(!parallelIntersects);

    std::cout << "[PASS] TestLineIntersectionMath\n";
}

int main() {
    std::cout << "=== EJECUTANDO TESTS UNITARIOS: QUADTREE Y GEOMETRIA ===\n";
    TestQuadTreeCreation();
    TestQuadTreeInsertionAndSubdivision();
    TestQuadTreeSpatialRangeQuery();
    TestLineIntersectionMath();
    std::cout << "=== TODOS LOS TESTS PASARON EXITOSAMENTE (4/4) ===\n";
    return 0;
}
