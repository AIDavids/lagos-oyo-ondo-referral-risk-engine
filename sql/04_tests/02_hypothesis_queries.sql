-- The queries that answer H1-H4 and the engine-vs-baseline comparison. Run each statement separately.

-- H1: LGAs that look adequate by total density but have a public deficit (low bound / high bound)
SELECT COUNTIF(total_per_10k >= 1 AND public_per_10k < 1) AS h1_low_bound,
       COUNTIF(total_per_10k >= 1 AND public_per_10k_high < 1) AS h1_high_bound, COUNT(*) AS lgas
FROM gold.mart_lga_access;

-- H2: among LGAs with adequate public coverage, how isolated are their PHCs? ("large share" = 25%)
SELECT COUNT(*) AS adequate_lgas, COUNTIF(median_referral_km < 15) AS median_under_15km,
       COUNTIF(pct_phc_beyond_15km >= 0.25) AS large_share_isolated,
       ROUND(MAX(median_referral_km), 1) AS max_median_km
FROM gold.mart_lga_access WHERE public_per_10k >= 1;

-- H3: registry completeness by density tier
SELECT density_tier, COUNT(*) AS n, ROUND(AVG(completeness_score), 3) AS avg_completeness,
       ROUND(MIN(completeness_score), 3) AS min_c, ROUND(MAX(completeness_score), 3) AS max_c
FROM gold.mart_lga_access GROUP BY 1 ORDER BY 1;

-- H4: top-10 stability across the 9 scenarios, then the robust LGAs
SELECT * FROM gold.mart_top10_stability ORDER BY scenario;
SELECT * FROM gold.mart_priority_robustness ORDER BY scenarios_in_top10 DESC, lga_name LIMIT 15;

-- Engine vs baseline
SELECT COUNTIF(h1_case) AS baseline_fine_but_public_deficit,
       COUNTIF(baseline_says_fine AND engine_flags) AS baseline_fine_engine_flags,
       COUNTIF(public_deficit) AS deficit_lgas,
       COUNTIF(public_deficit AND NOT is_build_action) AS deficit_not_build,
       COUNTIF(baseline_rank <= 10 AND priority_rank <= 10) AS top10_overlap_with_baseline,
       COUNTIF(low_confidence_flag) AS low_confidence_lgas
FROM gold.mart_lga_policy;
SELECT action_low, COUNT(*) AS lgas FROM gold.mart_lga_policy GROUP BY 1 ORDER BY 2 DESC;
