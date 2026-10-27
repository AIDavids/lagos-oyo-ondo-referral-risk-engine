-- Assertion tests: each returns a row only if something is wrong. ZERO ROWS = PASS.
SELECT 'T1_dim_lga_not_71' AS test, COUNT(*) AS found FROM gold.dim_lga HAVING COUNT(*) != 71
UNION ALL SELECT 'T2_access_not_71', COUNT(*) FROM gold.mart_lga_access HAVING COUNT(*) != 71
UNION ALL SELECT 'T3_policy_not_71', COUNT(*) FROM gold.mart_lga_policy HAVING COUNT(*) != 71
UNION ALL SELECT 'T4_null_population', COUNT(*) FROM gold.dim_lga WHERE population_2025 IS NULL HAVING COUNT(*) > 0
UNION ALL SELECT 'T5_duplicate_lga', COUNT(*) FROM (SELECT lga_id FROM gold.mart_lga_access GROUP BY 1 HAVING COUNT(*) > 1) HAVING COUNT(*) > 0
UNION ALL SELECT 'T6_owner_split_wrong', COUNT(*) FROM gold.mart_lga_access WHERE phc_public + phc_private + phc_unknown_owner != phc_total HAVING COUNT(*) > 0
UNION ALL SELECT 'T7_bronze_vs_silver', a.n - b.n FROM (SELECT COUNT(*) n FROM bronze.facilities) a, (SELECT COUNT(*) n FROM silver.facility_clean) b WHERE a.n != b.n
UNION ALL SELECT 'T8_primary_not_reconciled', s.n - m.n FROM (SELECT COUNT(*) n FROM gold.fact_facility WHERE facility_level = 'Primary') s, (SELECT SUM(phc_total) n FROM gold.mart_lga_access) m WHERE s.n != m.n
UNION ALL SELECT 'T9_referral_not_covering_phc', s.n - r.n FROM (SELECT COUNT(*) n FROM gold.fact_facility WHERE facility_level = 'Primary') s, (SELECT COUNT(*) n FROM silver.phc_referral) r WHERE s.n != r.n
UNION ALL SELECT 'T10_null_action', COUNT(*) FROM gold.mart_lga_policy WHERE action_low IS NULL OR action_high IS NULL HAVING COUNT(*) > 0
UNION ALL SELECT 'T11_pct_out_of_range', COUNT(*) FROM gold.mart_lga_access WHERE pct_phc_beyond_15km NOT BETWEEN 0 AND 1 OR completeness_score NOT BETWEEN 0 AND 1 HAVING COUNT(*) > 0
UNION ALL SELECT 'T12_sensitivity_base_differs_from_policy', COUNT(*) FROM gold.mart_sensitivity s JOIN gold.mart_lga_policy p ON s.lga_id = p.lga_id WHERE s.scenario = 'bench=10000|km=15' AND s.action != p.action_low HAVING COUNT(*) > 0;
