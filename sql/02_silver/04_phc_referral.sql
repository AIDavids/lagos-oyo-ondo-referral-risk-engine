-- Layer: SILVER. Why: H2 and the "ambulance" recommendation depend on how far each primary facility
-- is from a hospital. ST_DWITHIN is the cheap filter (hospitals within 150 km), ST_DISTANCE ranks them,
-- and facilities with no hospital in range stay in the table with a flag.
CREATE OR REPLACE TABLE silver.phc_referral AS
WITH phc AS (
  SELECT globalid, geog FROM silver.facility_clean
  WHERE facility_level = 'Primary'
    AND LOWER(state_assigned) IN ('lagos','oyo','ondo')),
hosp AS (
  SELECT globalid, geog FROM silver.facility_clean
  WHERE facility_level IN ('Secondary','Tertiary')),
nearest AS (
  SELECT p.globalid, h.globalid AS referral_id,
         ST_DISTANCE(p.geog, h.geog) / 1000 AS referral_km
  FROM phc p JOIN hosp h ON ST_DWITHIN(p.geog, h.geog, 150000)
  WHERE TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY p.globalid ORDER BY ST_DISTANCE(p.geog, h.geog)) = 1)
SELECT p.globalid, n.referral_id, n.referral_km,
       IF(n.referral_id IS NULL, 'no_hospital_within_150km', 'ok') AS referral_status
FROM phc p LEFT JOIN nearest n USING (globalid);
