-- Layer: GOLD (mart). Why: applies the decision rules (a "waterfall": the first rule that matches wins),
-- once per ownership bound. If the two bounds disagree, the LGA is flagged low-confidence.
-- Also adds the baseline ("dumb" approach: rank by total clinics per 10k) for the engine-vs-baseline proof.
CREATE OR REPLACE TABLE gold.mart_lga_policy AS
WITH c AS (SELECT * FROM gold.config_thresholds),
w AS (
  SELECT a.*, c.benchmark_pop_per_phc, c.unknown_owner_share_max, c.completeness_min,
    CASE
      WHEN a.pop_per_public_phc > c.critical_mult * c.benchmark_pop_per_phc AND a.pct_phc_beyond_15km >= c.critical_pct_beyond THEN 'Critical capital build'
      WHEN a.pop_per_public_phc <= c.ambulance_mult * c.benchmark_pop_per_phc AND a.median_referral_km > c.median_referral_km_cut THEN 'Referral bottleneck: ambulance'
      WHEN a.pop_per_public_phc > c.contract_mult * c.benchmark_pop_per_phc AND a.private_share >= c.contract_private_share THEN 'Contract private clinics into state insurance'
      WHEN a.pop_per_public_phc > c.gap_mult * c.benchmark_pop_per_phc THEN 'Public capacity gap'
      ELSE 'Monitor' END AS action_low,
    CASE
      WHEN a.pop_per_public_phc_high > c.critical_mult * c.benchmark_pop_per_phc AND a.pct_phc_beyond_15km_high >= c.critical_pct_beyond THEN 'Critical capital build'
      WHEN a.pop_per_public_phc_high <= c.ambulance_mult * c.benchmark_pop_per_phc AND a.median_referral_km_high > c.median_referral_km_cut THEN 'Referral bottleneck: ambulance'
      WHEN a.pop_per_public_phc_high > c.contract_mult * c.benchmark_pop_per_phc AND a.private_share_high >= c.contract_private_share THEN 'Contract private clinics into state insurance'
      WHEN a.pop_per_public_phc_high > c.gap_mult * c.benchmark_pop_per_phc THEN 'Public capacity gap'
      ELSE 'Monitor' END AS action_high
  FROM gold.mart_lga_access a CROSS JOIN c),
v AS (
  SELECT w.*,
    CASE action_low WHEN 'Critical capital build' THEN 1 WHEN 'Referral bottleneck: ambulance' THEN 2
         WHEN 'Contract private clinics into state insurance' THEN 3 WHEN 'Public capacity gap' THEN 4 ELSE 5 END AS action_order,
    action_low != action_high AS flips_between_bounds,
    (action_low != action_high
      OR COALESCE(unknown_owner_share > unknown_owner_share_max, FALSE)
      OR completeness_score < completeness_min) AS low_confidence_flag,
    total_per_10k >= 10000 / benchmark_pop_per_phc AS baseline_says_fine,
    public_per_10k < 10000 / benchmark_pop_per_phc AS public_deficit,
    action_low IN ('Critical capital build','Public capacity gap') AS is_build_action
  FROM w)
SELECT v.*,
  RANK() OVER (ORDER BY total_per_10k ASC) AS baseline_rank,
  IF(action_low = 'Monitor', NULL,
     ROW_NUMBER() OVER (ORDER BY action_order, phc_deficit DESC, population_2025 DESC)) AS priority_rank,
  (baseline_says_fine AND public_deficit) AS h1_case,
  (action_low != 'Monitor') AS engine_flags
FROM v;
