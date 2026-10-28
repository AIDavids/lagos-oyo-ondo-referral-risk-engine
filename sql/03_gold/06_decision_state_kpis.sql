-- Layer: GOLD (mart). Why: one decision table per LGA that the dashboard reads (action label, confidence,
-- robust flag, severity rank), plus the state summary and the Overview KPIs. One definition per number.
CREATE OR REPLACE TABLE gold.mart_lga_decision AS
SELECT p.*,
  CASE p.action_low
    WHEN 'Public capacity gap' THEN 'Add public clinics'
    WHEN 'Contract private clinics into state insurance' THEN 'Contract private clinics'
    WHEN 'Critical capital build' THEN 'Critical gap: add clinics and referral access'
    WHEN 'Referral bottleneck: ambulance' THEN 'Fund ambulances'
    ELSE 'No action now' END AS action_label,
  c.settings_same, c.settings_total, c.share_same, c.confidence,
  COALESCE(r.scenarios_in_top10 = 9, FALSE) AS robust_top10,   -- top 10 in all 9 target/distance settings (confirmed owners)
  -- severity view: worst people-per-public-clinic first, flagged LGAs only
  IF(p.action_low = 'Monitor', NULL,
     ROW_NUMBER() OVER (ORDER BY IF(p.action_low = 'Monitor', 1, 0), p.pop_per_public_phc DESC)) AS severity_rank
FROM gold.mart_lga_policy p
LEFT JOIN gold.mart_confidence c ON c.lga_id = p.lga_id
LEFT JOIN gold.mart_priority_robustness r ON r.lga_id = p.lga_id;

CREATE OR REPLACE TABLE gold.mart_state_summary AS
SELECT state_name,
  COUNT(*) AS lgas,
  COUNTIF(public_deficit) AS lgas_short,
  COUNTIF(action_label = 'Add public clinics') AS n_add,
  COUNTIF(action_label = 'Contract private clinics') AS n_contract,
  COUNTIF(action_label = 'No action now') AS n_none,
  SUM(population_2025) AS population,
  SUM(IF(public_deficit, population_2025, 0)) AS population_in_short_lgas,
  SAFE_DIVIDE(SUM(population_2025), NULLIF(SUM(phc_public), 0)) AS people_per_public_clinic,
  SUM(phc_deficit) AS clinics_needed,
  ARRAY_AGG(lga_name ORDER BY pop_per_public_phc ASC LIMIT 1)[OFFSET(0)] AS best_served_lga,
  ARRAY_AGG(lga_name ORDER BY pop_per_public_phc DESC LIMIT 1)[OFFSET(0)] AS most_in_need_lga
FROM gold.mart_lga_decision
GROUP BY state_name;

CREATE OR REPLACE TABLE gold.mart_kpis AS
SELECT COUNT(*) AS lgas_assessed,
  COUNTIF(public_deficit) AS lgas_short,
  (SELECT COUNTIF(public_per_10k_high < 1) FROM gold.mart_lga_access) AS lgas_short_if_unknown_public,
  COUNTIF(h1_case) AS hidden_gaps,                      -- short LGAs that look fine when all primary clinics are counted
  SUM(population_2025) AS population_total,
  SUM(IF(public_deficit, population_2025, 0)) AS population_in_short_lgas,
  SAFE_DIVIDE(SUM(IF(public_deficit, population_2025, 0)), SUM(population_2025)) AS pct_population_short,
  SUM(phc_deficit) AS clinics_needed,
  (SELECT SAFE_DIVIDE(COUNTIF(COALESCE(referral_km, 999) > 15), COUNT(*))
     FROM gold.fact_facility WHERE facility_level = 'Primary') AS pct_clinics_beyond_15km,
  (SELECT APPROX_QUANTILES(referral_km, 100)[OFFSET(50)]
     FROM gold.fact_facility WHERE facility_level = 'Primary') AS median_referral_km,
  (SELECT SAFE_DIVIDE(COUNTIF(ownership = 'Unknown'), COUNT(*))
     FROM gold.fact_facility WHERE facility_level = 'Primary') AS unknown_owner_share
FROM gold.mart_lga_decision;
