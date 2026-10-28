# ADR-005: Confidence, candidate lists and one-definition numbers

Status: Accepted (2026-10-28)

Decisions
- Confidence = share of 18 settings (3 targets x 3 hospital limits x 2 ownership views) in which an LGA keeps its base-case action. High 90%+, Medium 60-89%, Low under 60%. This replaces the earlier low-confidence flag.
- "Short of public clinics" (31) and "hidden gaps" (24) are different numbers. Hidden gaps are short LGAs that look fine when every primary clinic is counted.
- Candidates are context-sensitive: contracting LGAs list private primary clinics; add-public LGAs list public Health Posts to upgrade. Ranked by registry ID, known type, then distance from the nearest public clinic (furthest first).
- Priority rank (volume) uses clinics missing; severity rank uses people per public clinic. The dashboard offers both.

Consequences
- Candidates are leads, not approvals: the registry cannot confirm staffing, equipment or opening status.
- Distances are straight lines, capped at 30 km when no public clinic is within range.
