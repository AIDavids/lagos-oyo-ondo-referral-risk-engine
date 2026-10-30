# ADR-005: Confidence, candidate lists and one-definition numbers

Status: Accepted (2026-10-28)

Decisions
- Confidence = share of 6 data checks (3 hospital limits x 2 ownership views, at the 1-per-10,000 target) in which an LGA keeps its base-case action. High = 6 of 6, Medium = 4-5, Low = 3 or fewer. The target is a policy choice and is shown separately. A first version over 18 settings (including targets) labelled 25 of 71 LGAs Low mainly because they flip at looser targets, which says nothing about data quality, so it was changed.
- Candidate lists exclude staff, barracks and agency clinics and rank down facilities whose ward label disagrees with their location.
- Contracting feasibility is reported as cover (candidates available / clinics needed). Alimosho and Ikorodu are about 1.05x: contracting alone is unrealistic there.
- Default ranking on Priorities is people per public clinic (severity); clinics missing (volume) is the alternative.
- "Short of public clinics" (31) and "hidden gaps" (24) are different numbers. Hidden gaps are short LGAs that look fine when every primary clinic is counted.
- Candidates are context-sensitive: contracting LGAs list private primary clinics; add-public LGAs list public Health Posts to upgrade. Ranked by registry ID, known type, then distance from the nearest public clinic (furthest first).
- Priority rank (volume) uses clinics missing; severity rank uses people per public clinic. The dashboard offers both.

Consequences
- Candidates are leads, not approvals: the registry cannot confirm staffing, equipment or opening status.
- Distances are straight lines, capped at 30 km when no public clinic is within range.
- Cover label: Comfortable (2x or more), Tight (1 to 2x), Not enough (under 1x). The 2x bar is our own rule of thumb, not a published standard, and is labelled that way on the dashboard.
