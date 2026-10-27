# ADR-001: Day-0 data go/no-go

Status: Accepted (2026-10-25)

Decision: GO.

Evidence
- All three sources exist, are open (CC BY 4.0) and cover Lagos, Oyo and Ondo.
- Facilities: GRID3 NGA Health Facilities v2.0 (51,022 rows; ownership, level, type, coordinates, state/LGA).
- Population: WorldPop/GRID3 NGA Population v3.0, LGA table (774 rows, 2025 estimate).
- Boundaries: GRID3 LGA boundaries shapefile (774 polygons).

Choices
- Facilities = v2.0 (documented codebook). v3.0 (Aug 2026) kept as a comparison until its release notes and column meanings are confirmed.

Risks and mitigation
- Facility data is not validated by government; population is modelled (2025), boundaries are older (confirm year from the shapefile XML).
- Names differ across files: facilities are assigned to LGAs by location (ST_WITHIN); population joins to boundaries by normalised state + LGA name, with unmatched rows logged.
- All limits are reported publicly.
