-- Layer: SILVER. Why: every issue gets a logged rule code instead of a silent fix.
-- Feeds the data-quality page and H3. Nothing is rejected: bronze = silver + 0 rejected; issues are flagged.
CREATE OR REPLACE TABLE silver.dq_audit AS
SELECT globalid, 'NO_POLYGON_MATCH' AS rule_code, 'flagged' AS action, 'point inside no LGA polygon' AS detail
FROM silver.facility_clean WHERE match_method = 'no_polygon_match'
UNION ALL SELECT globalid, 'STATE_MISMATCH', 'flagged', CONCAT(state_clean, ' vs ', state_assigned)
FROM silver.facility_clean
WHERE state_assigned IS NOT NULL AND LOWER(state_assigned) != LOWER(state_clean)
UNION ALL SELECT globalid, 'LGA_NAME_SOURCES_DISAGREE', 'flagged', 'source LGA names disagree'
FROM silver.facility_clean WHERE SAFE_CAST(lga_name_disagreement AS FLOAT64) = 1
UNION ALL SELECT globalid, 'OWNERSHIP_UNKNOWN', 'flagged', 'ownership = Unknown'
FROM silver.facility_clean WHERE ownership = 'Unknown'
UNION ALL SELECT globalid, 'LEVEL_UNKNOWN', 'flagged', 'facility_level = Unknown'
FROM silver.facility_clean WHERE facility_level = 'Unknown'
UNION ALL SELECT globalid, 'TYPE_UNKNOWN', 'flagged', 'facility_level_option = Unknown'
FROM silver.facility_clean WHERE facility_level_option = 'Unknown';
