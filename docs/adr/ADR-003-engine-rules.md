# ADR-003: Engine rules and operational definitions

Status: Accepted (2026-10-27). Thresholds below were set before the results were seen.

Decisions
- Waterfall thresholds are multiples of the benchmark (1.5x, 1.0x, 1.2x, 1.0x), so changing the benchmark rescales every rule. The referral rule uses a fixed 20 km median.
- Official numbers use the cautious bound (confirmed public only); the "high" bound counts Unknown ownership as public. An LGA is low-confidence if the action flips between bounds, unknown ownership exceeds 20% of its PHCs, or completeness is below 0.60.
- Urban/rural is proxied by population-density terciles (the data has no urban/rural field).
- H2 "large share" = 25% of PHCs beyond 15 km. H3 completeness = mean of five signals (known ownership, known level, known type, registry ID present, LGA names agree), equal weights.
- Baseline: rank by total PHCs per 10k; "fine" if total >= 1 per 10k. "Total" counts primary-level facilities only.
- Priority list ranks only flagged LGAs, ordered by action severity, then deficit, then population.
- Facility location beats the facility's own state label: 94 facilities whose state label disagrees with their coordinates are assigned by coordinates and flagged.

Limitations
- Straight-line distance, not travel time. Population is a modelled 2025 estimate. Registry presence is not proof a facility functions.
- Ranking by absolute deficit favours populous LGAs; a per-capita ranking would give a different list.
