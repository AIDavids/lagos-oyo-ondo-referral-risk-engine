-- Robustness check (read, not pass/fail): how close are clinics to PUBLIC hospitals only?
-- The base metric counts any facility the registry labels Secondary or Tertiary, including small private hospitals.
WITH phc AS (SELECT globalid, geog FROM silver.facility_clean WHERE facility_level = 'Primary' AND LOWER(state_assigned) IN ('lagos','oyo','ondo')),
hosp AS (SELECT geog FROM silver.facility_clean WHERE facility_level IN ('Secondary','Tertiary') AND ownership = 'Public'),
d AS (SELECT p.globalid, MIN(ST_DISTANCE(p.geog, h.geog)) / 1000 AS km FROM phc p LEFT JOIN hosp h ON ST_DWITHIN(p.geog, h.geog, 150000) GROUP BY 1)
SELECT COUNT(*) AS primary_clinics, SAFE_DIVIDE(COUNTIF(COALESCE(km, 999) > 15), COUNT(*)) AS pct_beyond_15km,
       APPROX_QUANTILES(km, 100)[OFFSET(50)] AS median_km, MAX(km) AS max_km FROM d;
