-- Layer: GOLD (mart). Why (H4): re-run the same rules under 9 scenarios (benchmark 10k/20k/30k x distance
-- 10/15/20 km) and measure how stable the top-10 priority list is.
CREATE OR REPLACE TABLE gold.mart_sensitivity AS
WITH c AS (SELECT * FROM gold.config_thresholds),
scen AS (
  SELECT b AS benchmark, k AS beyond_km,
         CONCAT('bench=', CAST(b AS STRING), '|km=', CAST(k AS STRING)) AS scenario
  FROM UNNEST([10000, 20000, 30000]) AS b CROSS JOIN UNNEST([10, 15, 20]) AS k),
far AS (
  SELECT f.lga_id, s.scenario,
         COUNTIF(f.ownership = 'Public') AS n_pub,
         COUNTIF(f.ownership = 'Public' AND COALESCE(f.referral_km, 999) > s.beyond_km) AS n_far
  FROM gold.fact_facility f CROSS JOIN scen s
  WHERE f.facility_level = 'Primary'
  GROUP BY f.lga_id, s.scenario),
x AS (
  SELECT a.lga_id, a.state_name, a.lga_name, a.population_2025, a.phc_public,
         a.pop_per_public_phc, a.private_share, a.median_referral_km,
         s.scenario, s.benchmark, s.beyond_km,
         IF(COALESCE(fr.n_pub, 0) = 0, 1.0, SAFE_DIVIDE(fr.n_far, fr.n_pub)) AS pct_far
  FROM gold.mart_lga_access a CROSS JOIN scen s
  LEFT JOIN far fr ON fr.lga_id = a.lga_id AND fr.scenario = s.scenario),
y AS (
  SELECT x.*,
    GREATEST(0, CAST(CEIL(x.population_2025 / x.benchmark) AS INT64) - x.phc_public) AS phc_deficit,
    CASE
      WHEN x.pop_per_public_phc > c.critical_mult * x.benchmark AND x.pct_far >= c.critical_pct_beyond THEN 'Critical capital build'
      WHEN x.pop_per_public_phc <= c.ambulance_mult * x.benchmark AND x.median_referral_km > c.median_referral_km_cut THEN 'Referral bottleneck: ambulance'
      WHEN x.pop_per_public_phc > c.contract_mult * x.benchmark AND x.private_share >= c.contract_private_share THEN 'Contract private clinics into state insurance'
      WHEN x.pop_per_public_phc > c.gap_mult * x.benchmark THEN 'Public capacity gap'
      ELSE 'Monitor' END AS action
  FROM x CROSS JOIN c),
z AS (
  SELECT y.*,
    CASE action WHEN 'Critical capital build' THEN 1 WHEN 'Referral bottleneck: ambulance' THEN 2
         WHEN 'Contract private clinics into state insurance' THEN 3 WHEN 'Public capacity gap' THEN 4 ELSE 5 END AS action_order
  FROM y)
SELECT z.*,
  IF(action = 'Monitor', NULL,
     ROW_NUMBER() OVER (PARTITION BY scenario ORDER BY action_order, phc_deficit DESC, population_2025 DESC)) AS priority_rank
FROM z;

-- How many of the base-scenario top-10 stay in the top-10 under each scenario?
CREATE OR REPLACE TABLE gold.mart_top10_stability AS
WITH t AS (SELECT scenario, lga_id FROM gold.mart_sensitivity WHERE priority_rank <= 10),
base AS (SELECT lga_id FROM t WHERE scenario = 'bench=10000|km=15')
SELECT t.scenario, COUNT(*) AS n_in_top10, COUNTIF(b.lga_id IS NOT NULL) AS overlap_with_base
FROM t LEFT JOIN base b ON t.lga_id = b.lga_id
GROUP BY t.scenario;

-- Which LGAs appear in the top-10 most often?
CREATE OR REPLACE TABLE gold.mart_priority_robustness AS
SELECT s.lga_id, s.state_name, s.lga_name,
       COUNTIF(s.priority_rank <= 10) AS scenarios_in_top10, COUNT(*) AS scenarios
FROM gold.mart_sensitivity s
GROUP BY 1, 2, 3
HAVING COUNTIF(s.priority_rank <= 10) > 0;
