-- Layer: GOLD (mart). Why: turn each recommendation into names. The panel is context-sensitive:
--  * Contract LGAs  -> private primary clinics to approach (contract_private)
--  * Add-public LGAs -> public Health Posts to upgrade (upgrade_public_post)
-- Ranked: registered first, type known, then furthest from a public clinic (they fill the biggest gap).
-- "Public clinic" for the distance = public primary facility that is not a Health Post.
CREATE OR REPLACE TABLE gold.mart_candidates AS
WITH d AS (SELECT lga_id, lga_name, state_name, action_low, phc_deficit FROM gold.mart_lga_decision),
pts AS (
  SELECT f.globalid, f.lga_id, f.facility_name, s.ward, f.ownership, f.ownership_type,
         f.facility_level_option, f.in_registry, ST_GEOGPOINT(f.longitude, f.latitude) AS geog
  FROM gold.fact_facility f
  JOIN silver.facility_clean s ON s.globalid = f.globalid
  WHERE f.facility_level = 'Primary'),
pub_ref AS (SELECT globalid, geog FROM pts WHERE ownership = 'Public' AND facility_level_option != 'Health Post'),
sel AS (
  SELECT p.*, d.lga_name, d.state_name, d.phc_deficit,
    CASE WHEN d.action_low = 'Contract private clinics into state insurance' AND p.ownership = 'Private' THEN 'contract_private'
         WHEN d.action_low = 'Public capacity gap' AND p.ownership = 'Public' AND p.facility_level_option = 'Health Post' THEN 'upgrade_public_post'
    END AS candidate_type
  FROM pts p JOIN d ON d.lga_id = p.lga_id),
cand AS (SELECT * FROM sel WHERE candidate_type IS NOT NULL),
near AS (
  SELECT c.globalid, MIN(ST_DISTANCE(c.geog, r.geog)) / 1000 AS km_to_public
  FROM cand c LEFT JOIN pub_ref r ON r.globalid != c.globalid AND ST_DWITHIN(c.geog, r.geog, 30000)
  GROUP BY c.globalid)
SELECT c.lga_id, c.lga_name, c.state_name, c.candidate_type, c.globalid, c.facility_name, c.ward,
       c.ownership_type, c.facility_level_option, c.in_registry,
       COALESCE(n.km_to_public, 30) AS km_to_nearest_public,   -- 30 = none within 30 km (capped)
       ROW_NUMBER() OVER (PARTITION BY c.lga_id, c.candidate_type
         ORDER BY c.in_registry DESC, (c.facility_level_option = 'Unknown'), COALESCE(n.km_to_public, 30) DESC) AS candidate_rank
FROM cand c LEFT JOIN near n ON n.globalid = c.globalid;

-- How many candidates exist per LGA versus clinics needed ("cover")
CREATE OR REPLACE TABLE gold.mart_candidate_cover AS
SELECT c.lga_id, c.lga_name, c.state_name, c.candidate_type,
       COUNT(*) AS candidates_available, ANY_VALUE(d.phc_deficit) AS clinics_needed,
       SAFE_DIVIDE(COUNT(*), NULLIF(ANY_VALUE(d.phc_deficit), 0)) AS cover_ratio
FROM gold.mart_candidates c JOIN gold.mart_lga_decision d ON d.lga_id = c.lga_id
GROUP BY c.lga_id, c.lga_name, c.state_name, c.candidate_type;
