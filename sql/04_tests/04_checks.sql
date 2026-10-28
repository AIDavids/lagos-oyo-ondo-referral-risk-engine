-- Checks to read (not pass/fail). Paste the results back for the dashboard numbers.
-- 1. The numbers for the Overview
SELECT * FROM gold.mart_kpis;
-- 2. State scorecard
SELECT * FROM gold.mart_state_summary ORDER BY state_name;
-- 3. Are the robust LGAs simply the biggest by population? Compare ranks.
SELECT lga_name, state_name, population_2025,
       RANK() OVER (ORDER BY population_2025 DESC) AS population_rank, severity_rank, priority_rank, robust_top10, confidence
FROM gold.mart_lga_decision
WHERE robust_top10 OR severity_rank <= 8 ORDER BY population_rank;
-- 4. Confidence spread
SELECT confidence, COUNT(*) AS lgas FROM gold.mart_lga_decision GROUP BY 1 ORDER BY 1;
-- 5. Candidates available vs needed
SELECT * FROM gold.mart_candidate_cover ORDER BY candidate_type, lga_name;
-- 6. Contracting shortlist preview (top 5 per contracting LGA)
SELECT lga_name, candidate_rank, facility_name, ward, ownership_type, ROUND(km_to_nearest_public, 1) AS km
FROM gold.mart_candidates WHERE candidate_type = 'contract_private' AND candidate_rank <= 5 ORDER BY lga_name, candidate_rank;
