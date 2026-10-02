#include "QuadTree.hpp"
#include <algorithm>

QuadTree::QuadTree(BoundingBox2D bound, int cap, int maxD, int curD)
    : boundary(bound),
      capacity(cap),
      maxDepth(maxD),
      currentDepth(curD),
      isDivided(false),
      northWest(nullptr),
      northEast(nullptr),
      southWest(nullptr),
      southEast(nullptr)
{
}

void QuadTree::Subdivide() {
    float halfW = boundary.width / 2.0f;
    float halfH = boundary.height / 2.0f;

    northWest = std::make_unique<QuadTree>(
        BoundingBox2D{ boundary.x, boundary.y, halfW, halfH },
        capacity, maxDepth, currentDepth + 1
    );
    northEast = std::make_unique<QuadTree>(
        BoundingBox2D{ boundary.x + halfW, boundary.y, halfW, halfH },
        capacity, maxDepth, currentDepth + 1
    );
    southWest = std::make_unique<QuadTree>(
        BoundingBox2D{ boundary.x, boundary.y + halfH, halfW, halfH },
        capacity, maxDepth, currentDepth + 1
    );
    southEast = std::make_unique<QuadTree>(
        BoundingBox2D{ boundary.x + halfW, boundary.y + halfH, halfW, halfH },
        capacity, maxDepth, currentDepth + 1
    );

    isDivided = true;

    // Redistribuir los segmentos almacenados en este nodo hacia sus hijos
    for (const auto& seg : segments) {
        northWest->Insert(seg);
        northEast->Insert(seg);
        southWest->Insert(seg);
        southEast->Insert(seg);
    }
    segments.clear();
}

bool QuadTree::Insert(const LineSegment& segment) {
    if (!boundary.IntersectsSegment(segment)) {
        return false;
    }

    if (!isDivided) {
        if ((int)segments.size() < capacity || currentDepth >= maxDepth) {
            segments.push_back(segment);
            return true;
        }
        Subdivide();
    }

    bool inserted = false;
    if (northWest->Insert(segment)) inserted = true;
    if (northEast->Insert(segment)) inserted = true;
    if (southWest->Insert(segment)) inserted = true;
    if (southEast->Insert(segment)) inserted = true;

    return inserted;
}

void QuadTree::QueryRange(const BoundingBox2D& range, std::vector<LineSegment>& found) const {
    if (!boundary.IntersectsBox(range)) {
        return;
    }

    if (!isDivided) {
        for (const auto& seg : segments) {
            if (range.IntersectsSegment(seg)) {
                found.push_back(seg);
            }
        }
    } else {
        northWest->QueryRange(range, found);
        northEast->QueryRange(range, found);
        southWest->QueryRange(range, found);
        southEast->QueryRange(range, found);
    }
}

void QuadTree::QueryRay(Vector2 rayStart, Vector2 rayEnd, std::vector<LineSegment>& found) const {
    float minX = std::min(rayStart.x, rayEnd.x);
    float maxX = std::max(rayStart.x, rayEnd.x);
    float minY = std::min(rayStart.y, rayEnd.y);
    float maxY = std::max(rayStart.y, rayEnd.y);

    BoundingBox2D rayBox = {
        minX,
        minY,
        std::max(1.0f, maxX - minX),
        std::max(1.0f, maxY - minY)
    };

    std::vector<LineSegment> candidates;
    QueryRange(rayBox, candidates);

    // Deduplicación para asegurar que cada segmento candidato solo se evalúe una vez
    for (const auto& cand : candidates) {
        bool exists = false;
        for (const auto& item : found) {
            if (item == cand) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            found.push_back(cand);
        }
    }
}

void QuadTree::QueryBox(const BoundingBox2D& box, std::vector<LineSegment>& found) const {
    std::vector<LineSegment> candidates;
    QueryRange(box, candidates);

    for (const auto& cand : candidates) {
        bool exists = false;
        for (const auto& item : found) {
            if (item == cand) {
                exists = true;
                break;
            }
        }
        if (!exists) {
            found.push_back(cand);
        }
    }
}

void QuadTree::Clear() {
    segments.clear();
    isDivided = false;
    northWest.reset();
    northEast.reset();
    southWest.reset();
    southEast.reset();
}

void QuadTree::DrawDebug() const {
    // Dibujar límites del cuadrante
    Rectangle rect = { boundary.x, boundary.y, boundary.width, boundary.height };
    DrawRectangleLinesEx(rect, 1.0f, Fade(SKYBLUE, 0.25f));

    if (isDivided) {
        northWest->DrawDebug();
        northEast->DrawDebug();
        southWest->DrawDebug();
        southEast->DrawDebug();
    }
}

int QuadTree::GetTotalNodes() const {
    if (!isDivided) return 1;
    return 1 + northWest->GetTotalNodes()
             + northEast->GetTotalNodes()
             + southWest->GetTotalNodes()
             + southEast->GetTotalNodes();
}

int QuadTree::GetTotalSegments() const {
    if (!isDivided) return (int)segments.size();
    return northWest->GetTotalSegments()
         + northEast->GetTotalSegments()
         + southWest->GetTotalSegments()
         + southEast->GetTotalSegments();
}

int QuadTree::GetMaxDepthReached() const {
    if (!isDivided) return currentDepth;
    return std::max({
        northWest->GetMaxDepthReached(),
        northEast->GetMaxDepthReached(),
        southWest->GetMaxDepthReached(),
        southEast->GetMaxDepthReached()
    });
}
