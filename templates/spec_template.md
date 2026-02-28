# Shared Specification

## Project Overview

(Brief description of what the swarm is building)

## Coordinate System

(Define the shared coordinate space, units, boundaries)

## Scale Reference

(Define entity sizes, distances, heights)

## Material Palette

All agents must use these exact materials for visual consistency:

| Name | Type | albedo_color | roughness | Notes |
|------|------|-------------|-----------|-------|
| (name) | StandardMaterial3D | (r, g, b) | (0-1) | (usage) |

## Collision Export Convention

Each task must export collision data as:

```
func _collision_boxes() -> Array[Dictionary]:
    return [
        {"min_x": -5, "max_x": 5, "min_z": -5, "max_z": 5, "height": 10},
    ]
```

The composer task collects these into the server-side map.

## Naming Conventions

- Scenes: `snake_case.tscn`
- Scripts: `snake_case.gd`
- Nodes: `PascalCase`
- Materials: `snake_case`

## Integration Points

(Define how sub-scenes connect — spawn points, bridge endpoints, path intersections)
