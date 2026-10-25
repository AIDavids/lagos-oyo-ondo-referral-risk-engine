-- Throwaway checks (not part of the build). Run each statement separately.

-- Are facility IDs unique? (decides whether we dedupe)
SELECT COUNT(*) AS total,
       COUNT(DISTINCT globalid) AS distinct_globalid,
       COUNTIF(nhfr_uid IS NULL) AS null_nhfr_uid,
       COUNT(DISTINCT nhfr_uid) AS distinct_nhfr_uid,
       COUNT(DISTINCT CONCAT(LOWER(TRIM(facility_name)),'|',LOWER(TRIM(ward)),'|',
             CAST(ROUND(latitude,4) AS STRING),'|',CAST(ROUND(longitude,4) AS STRING))) AS distinct_name_ward_point
FROM bronze.facilities;

-- Do boundary and population LGA names match inside our 3 states? (expect 0 rows)
WITH b AS (
  SELECT statename, lganame, REGEXP_REPLACE(LOWER(lganame), r'[^a-z0-9]', '') AS k
  FROM bronze.lga_boundaries WHERE LOWER(TRIM(statename)) IN ('lagos','oyo','ondo')),
p AS (
  SELECT statename, lganame, REGEXP_REPLACE(LOWER(lganame), r'[^a-z0-9]', '') AS k
  FROM bronze.population_lga WHERE LOWER(TRIM(statename)) IN ('lagos','oyo','ondo'))
SELECT b.statename, b.lganame AS boundary_name, p.lganame AS population_name
FROM b FULL OUTER JOIN p ON LOWER(TRIM(b.statename)) = LOWER(TRIM(p.statename)) AND b.k = p.k
WHERE b.k IS NULL OR p.k IS NULL;

-- What is the shared nhfr_uid?
SELECT nhfr_uid, COUNT(*) n FROM bronze.facilities GROUP BY 1 ORDER BY n DESC LIMIT 5;

-- Are the state mismatches real border points or naming differences?
SELECT state_clean, state_assigned, COUNT(*) n FROM silver.facility_clean
WHERE state_assigned IS NOT NULL AND LOWER(state_assigned) != LOWER(state_clean)
GROUP BY 1,2 ORDER BY n DESC LIMIT 10;

-- lga_clean check: expect 774 and 0
SELECT COUNT(*) AS n, COUNTIF(population_2025 IS NULL) AS no_pop FROM silver.lga_clean;

-- phc_referral check: 'ok' should be nearly all rows
SELECT referral_status, COUNT(*) n, ROUND(AVG(referral_km),1) avg_km, ROUND(MAX(referral_km),1) max_km
FROM silver.phc_referral GROUP BY 1;
