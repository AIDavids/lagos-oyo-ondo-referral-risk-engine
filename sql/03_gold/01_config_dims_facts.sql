-- Layer: GOLD. Why: gold is what the dashboards read. This file builds the control table (thresholds),
-- the dimensions (LGAs, facility types), the facts (facilities, quality log) and the reconciliation funnel.
-- Power BI and Looker read gold only, so they cannot disagree with each other.

-- One thresholds table drives every rule: change a threshold by editing one row.
CREATE OR REPLACE TABLE gold.config_thresholds AS
SELECT 10000 AS benchmark_pop_per_phc,      -- 1 public PHC per 10,000 people (verify the official wording)
       15.0 AS beyond_km,                   -- a PHC is "isolated" if its nearest hospital is farther
       20.0 AS median_referral_km_cut,      -- referral-bottleneck rule
       1.5 AS critical_mult, 1.0 AS ambulance_mult, 1.2 AS contract_mult, 1.0 AS gap_mult,  -- x benchmark
       0.5 AS critical_pct_beyond, 0.65 AS contract_private_share,
       0.20 AS unknown_owner_share_max, 0.60 AS completeness_min;

-- One row per in-scope LGA, with area, density and a density tercile (urban/rural proxy).
CREATE OR REPLACE TABLE gold.dim_lga AS
SELECT lga_id, lgacode, state_name, lga_name, population_2025,
       ST_AREA(geog) / 1e6 AS area_km2,
       SAFE_DIVIDE(population_2025, ST_AREA(geog) / 1e6) AS pop_density_km2,
       NTILE(3) OVER (ORDER BY SAFE_DIVIDE(population_2025, ST_AREA(geog) / 1e6)) AS density_tercile
FROM silver.lga_clean
WHERE LOWER(state_name) IN ('lagos','oyo','ondo');

CREATE OR REPLACE TABLE gold.dim_facility_type AS
SELECT ROW_NUMBER() OVER (ORDER BY facility_level, facility_level_option) AS facility_type_key,
       facility_level, facility_level_option
FROM (SELECT DISTINCT facility_level, facility_level_option FROM silver.facility_clean);

CREATE OR REPLACE TABLE gold.fact_facility AS
SELECT f.globalid, f.lga_id, t.facility_type_key, f.facility_name_clean AS facility_name,
       f.ownership, f.ownership_type, f.facility_level, f.facility_level_option,
       f.latitude, f.longitude,
       (f.nhfr_uid IS NOT NULL AND f.nhfr_uid != 0) AS in_registry,   -- nhfr_uid = 0 is the "no registry ID" placeholder
       COALESCE(SAFE_CAST(f.lga_name_disagreement AS FLOAT64) = 1, FALSE) AS lga_name_conflict,
       r.referral_km, r.referral_status
FROM silver.facility_clean f
JOIN gold.dim_lga d ON f.lga_id = d.lga_id
LEFT JOIN gold.dim_facility_type t
  ON t.facility_level = f.facility_level AND t.facility_level_option = f.facility_level_option
LEFT JOIN silver.phc_referral r ON r.globalid = f.globalid;

CREATE OR REPLACE TABLE gold.fact_dq_audit AS
SELECT a.* FROM silver.dq_audit a JOIN gold.fact_facility f ON a.globalid = f.globalid;

-- Bronze-to-gold funnel: every step is counted so nothing disappears silently.
CREATE OR REPLACE TABLE gold.fact_funnel AS
SELECT 1 AS step, 'Bronze: facilities loaded' AS stage, COUNT(*) AS n FROM bronze.facilities
UNION ALL SELECT 2, 'Silver: facilities kept (none rejected)', COUNT(*) FROM silver.facility_clean
UNION ALL SELECT 3, 'Located inside an LGA polygon', COUNTIF(match_method = 'st_within') FROM silver.facility_clean
UNION ALL SELECT 4, 'In scope: Lagos, Oyo, Ondo', COUNT(*) FROM gold.fact_facility
UNION ALL SELECT 5, 'Primary-level facilities in scope', COUNTIF(facility_level = 'Primary') FROM gold.fact_facility
UNION ALL SELECT 6, 'Primary with known ownership', COUNTIF(facility_level = 'Primary' AND ownership IN ('Public','Private')) FROM gold.fact_facility
UNION ALL SELECT 7, 'Confirmed public primary', COUNTIF(facility_level = 'Primary' AND ownership = 'Public') FROM gold.fact_facility;
