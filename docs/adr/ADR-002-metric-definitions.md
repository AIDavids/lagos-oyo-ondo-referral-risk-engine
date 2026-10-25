# ADR-002: Metric definitions and treatment of unknowns

Status: Accepted (2026-10-25)

Decisions
1. Public vs private comes from `ownership`. `ownership_type` (38% Unknown) is used for detail only.
2. Unknown ownership (4,626 rows, ~9%) is its own category, never assumed. Lower bound = confirmed public only; upper bound = Unknown counted as public. LGAs whose recommendation flips between bounds get a low-confidence flag.
3. PHC = `facility_level = 'Primary'`. Health Posts are included; a sensitivity run excludes them.
4. Referral hospital = Secondary or Tertiary, any ownership. Facilities with Unknown level (334) are excluded from both groups and flagged.
5. Duplicates: none found on globalid or name+ward+point; nothing removed in silver. Everything is flagged in silver.dq_audit, not deleted.

Consequences
- Headline numbers are cautious; the uncertainty from unknown ownership is visible rather than hidden.
- Referral distance is straight-line and ignores hospital ownership: a stated limitation.
