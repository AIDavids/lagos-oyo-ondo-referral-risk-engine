ADR-001: Day-0 data go/no-go

Decision: GO.

Evidence: all three sources exist, are open (CC BY 4.0), and cover the three states.

Facilities v2.0 has ownership, level, type, coordinates, state/LGA.

Population has one row per LGA; boundaries have 774 polygons.

Choices: facilities = v2.0 (documented codebook). v3.0 (Aug 2026) kept as a

comparison until its release notes and column meanings are confirmed.

Risks: not validated; population 2025 modelled; boundaries 2020; names differ across files.

Mitigation: join facilities by location (ST\_WITHIN); join population to boundaries by

state+LGA name and log unmatched rows; report all limits publicly.

