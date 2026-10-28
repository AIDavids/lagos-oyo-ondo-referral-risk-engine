-- Layer: GOLD (mart). Why: confidence must be measured, not asserted. We re-run the decision rules in
-- 18 settings (3 targets x 3 hospital limits x 2 ownership views) for every LGA, then count how often
-- an LGA keeps the action it gets in the base case. 71 LGAs x 18 settings = 1,278 rows.
CREATE OR REPLACE TABLE gold.mart_scenarios AS
WITH c AS (SELECT * FROM gold.config_thresholds),
scen AS (
  SELECT b AS benchmark, k AS beyond_km, v AS owner_view,
         CONCAT('bench=', CAST(b AS STRING), '|km=', CAST(k AS STRING), '|', v) AS scenario
  FROM UNNEST([10000, 20000, 30000]) AS b
  CROSS JOIN UNNEST([10, 15, 20]) AS k
  CROSS JOIN UNNEST(['confirmed', 'include_unknown']) AS v),
far AS (  -- share of public primary clinics beyond the hospital limit, per setting
  SELECT f.lga_id, s.scenario,
    COUNTIF(IF(s.owner_view = 'confirmed', f.ownership = 'Public', f.ownership IN ('Public','Unknown'))) AS n_pub,
    COUNTIF(IF(s.owner_view = 'confirmed', f.ownership = 'Public', f.ownership IN ('Public','Unknown'))
            AND COALESCE(f.referral_km, 999) > s.beyond_km) AS n_far
  FROM gold.fact_facility f CROSS JOIN scen s
  WHERE f.facility_level = 'Primary'
  GROUP BY f.lga_id, s.scenario),
x AS (
  SELECT a.lga_id, a.state_name, a.lga_name, a.population_2025, a.phc_public, a.phc_unknown_owner,
         s.scenario, s.benchmark, s.beyond_km, s.owner_view,
         IF(s.owner_view = 'confirmed', a.pop_per_public_phc, a.pop_per_public_phc_high) AS ppp,
         IF(s.owner_view = 'confirmed', a.private_share, a.private_share_high) AS pshare,
         IF(s.owner_view = 'confirmed', a.median_referral_km, a.median_referral_km_high) AS med_km,
         IF(COALESCE(fr.n_pub, 0) = 0, 1.0, SAFE_DIVIDE(fr.n_far, fr.n_pub)) AS pct_far
  FROM gold.mart_lga_access a CROSS JOIN scen s
  LEFT JOIN far fr ON fr.lga_id = a.lga_id AND fr.scenario = s.scenario),
y AS (
  SELECT x.*,
    GREATEST(0, CAST(CEIL(x.population_2025 / x.benchmark) AS INT64) - x.phc_public
                - IF(x.owner_view = 'confirmed', 0, x.phc_unknown_owner)) AS phc_deficit,
    CASE
      WHEN x.ppp > c.critical_mult * x.benchmark AND x.pct_far >= c.critical_pct_beyond THEN 'Critical capital build'
      WHEN x.ppp <= c.ambulance_mult * x.benchmark AND x.med_km > c.median_referral_km_cut THEN 'Referral bottleneck: ambulance'
      WHEN x.ppp > c.contract_mult * x.benchmark AND x.pshare >= c.contract_private_share THEN 'Contract private clinics into state insurance'
      WHEN x.ppp > c.gap_mult * x.benchmark THEN 'Public capacity gap'
      ELSE 'Monitor' END AS action
  FROM x CROSS JOIN c)
SELECT * FROM y;

-- Confidence = share of the 18 settings where the LGA keeps its base-case action
-- (base = 1 per 10,000, 15 km, confirmed owners). High >= 90%, Medium 60-89%, Low < 60%.
CREATE OR REPLACE TABLE gold.mart_confidence AS
WITH base AS (SELECT lga_id, action AS base_action FROM gold.mart_scenarios WHERE scenario = 'bench=10000|km=15|confirmed')
SELECT s.lga_id, b.base_action,
       COUNTIF(s.action = b.base_action) AS settings_same,
       COUNT(*) AS settings_total,
       SAFE_DIVIDE(COUNTIF(s.action = b.base_action), COUNT(*)) AS share_same,
       CASE WHEN SAFE_DIVIDE(COUNTIF(s.action = b.base_action), COUNT(*)) >= 0.9 THEN 'High'
            WHEN SAFE_DIVIDE(COUNTIF(s.action = b.base_action), COUNT(*)) >= 0.6 THEN 'Medium'
            ELSE 'Low' END AS confidence
FROM gold.mart_scenarios s JOIN base b ON s.lga_id = b.lga_id
GROUP BY s.lga_id, b.base_action;
