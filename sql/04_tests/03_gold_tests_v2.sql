-- Assertion tests for the v2 tables. ZERO ROWS = PASS.
SELECT 'T13_actions_do_not_sum_to_lgas' AS test, COUNT(*) AS found FROM gold.mart_lga_decision HAVING COUNT(*) != 71
UNION ALL SELECT 'T14_scenarios_not_1278', COUNT(*) FROM gold.mart_scenarios HAVING COUNT(*) != 71 * 18
UNION ALL SELECT 'T15_confidence_not_71', COUNT(*) FROM gold.mart_confidence HAVING COUNT(*) != 71
UNION ALL SELECT 'T16_confidence_out_of_range', COUNT(*) FROM gold.mart_confidence WHERE share_same NOT BETWEEN 0 AND 1 HAVING COUNT(*) > 0
UNION ALL SELECT 'T17_base_scenario_differs_from_policy', COUNT(*) FROM gold.mart_scenarios s JOIN gold.mart_lga_policy p ON p.lga_id = s.lga_id WHERE s.scenario = 'bench=10000|km=15|confirmed' AND s.action != p.action_low HAVING COUNT(*) > 0
UNION ALL SELECT 'T18_state_lgas_not_71', SUM(lgas) FROM gold.mart_state_summary HAVING SUM(lgas) != 71
UNION ALL SELECT 'T19_state_short_not_equal_kpi', ABS(a.n - k.lgas_short) FROM (SELECT SUM(lgas_short) n FROM gold.mart_state_summary) a, gold.mart_kpis k WHERE a.n != k.lgas_short
UNION ALL SELECT 'T20_action_split_not_equal_short', ABS(a.n - k.lgas_short) FROM (SELECT SUM(n_add + n_contract) n FROM gold.mart_state_summary) a, gold.mart_kpis k WHERE a.n != k.lgas_short
UNION ALL SELECT 'T21_hidden_gaps_more_than_short', COUNT(*) FROM gold.mart_kpis WHERE hidden_gaps > lgas_short HAVING COUNT(*) > 0
UNION ALL SELECT 'T22_candidate_wrong_lga_action', COUNT(*) FROM gold.mart_candidates c JOIN gold.mart_lga_decision d ON d.lga_id = c.lga_id
  WHERE (c.candidate_type = 'contract_private' AND d.action_label != 'Contract private clinics')
     OR (c.candidate_type = 'upgrade_public_post' AND d.action_label != 'Add public clinics') HAVING COUNT(*) > 0
UNION ALL SELECT 'T23_range_below_short', COUNT(*) FROM gold.mart_kpis WHERE lgas_short_if_unknown_public > lgas_short HAVING COUNT(*) > 0;
