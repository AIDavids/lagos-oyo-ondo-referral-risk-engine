-- Layer: GOLD (mart). Why: turn each recommendation into names. The panel is context-sensitive:
--  * Contract LGAs  -> private primary clinics to approach (contract_private)
--  * Add-public LGAs -> public Health Posts to upgrade (upgrade_public_post)
-- Ranked: registered first, ward label agrees with location, owner type known, facility type known, then furthest from a public clinic (they fill the biggest gap).
-- "Public clinic" for the distance = public primary facility that is not a Health Post.
CREATE OR REPLACE TABLE gold.mart_candidates AS
WITH d AS (SELECT lga_id, lga_name, state_name, action_low, phc_deficit FROM gold.mart_lga_decision),
pts AS (
  SELECT f.globalid, f.lga_id, f.facility_name, s.ward, f.ownership, f.ownership_type,
         f.facility_level_option, f.in_registry, f.lga_name_conflict, s.lga AS registry_lga, s.lga_assigned, REGEXP_EXTRACT(s.ward, r'\(([^)]+)\)') AS ward_lga_hint, ST_GEOGPOINT(f.longitude, f.latitude) AS geog
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
-- drop staff, barracks and agency clinics: they are not open to the public, so cannot be contracted
cand AS (SELECT * FROM sel WHERE candidate_type IS NOT NULL
         AND NOT REGEXP_CONTAINS(LOWER(facility_name), r'\bstaff\b|barrack|police|army|prison|lsdpc')),
near AS (
  SELECT c.globalid, MIN(ST_DISTANCE(c.geog, r.geog)) / 1000 AS km_to_public
  FROM cand c LEFT JOIN pub_ref r ON r.globalid != c.globalid AND ST_DWITHIN(c.geog, r.geog, 30000)
  GROUP BY c.globalid)
SELECT c.lga_id, c.lga_name, c.state_name, c.candidate_type, c.globalid, c.facility_name, c.ward,
       c.ownership_type, c.facility_level_option, c.in_registry,
       COALESCE(n.km_to_public, 30) AS km_to_nearest_public,   -- 30 = none within 30 km (capped)
       ROW_NUMBER() OVER (PARTITION BY c.lga_id, c.candidate_type
         ORDER BY c.in_registry DESC,
           -- rank down clinics whose registry LGA differs from the LGA their point falls in (border or label errors)
           (REGEXP_REPLACE(LOWER(c.registry_lga), r'[^a-z0-9]', '') != REGEXP_REPLACE(LOWER(c.lga_assigned), r'[^a-z0-9]', '')),
           -- rank down clinics whose ward label names another LGA, e.g. 'Ijegun (Amuwo Odofin)' inside Alimosho
           (c.ward_lga_hint IS NOT NULL
            AND NOT (STARTS_WITH(REGEXP_REPLACE(LOWER(c.lga_assigned), r'[^a-z0-9]', ''), REGEXP_REPLACE(LOWER(c.ward_lga_hint), r'[^a-z0-9]', ''))
                  OR STARTS_WITH(REGEXP_REPLACE(LOWER(c.ward_lga_hint), r'[^a-z0-9]', ''), REGEXP_REPLACE(LOWER(c.lga_assigned), r'[^a-z0-9]', '')))),
           c.lga_name_conflict, (c.ownership_type = 'Unknown'), (c.facility_level_option = 'Unknown'), COALESCE(n.km_to_public, 30) DESC) AS candidate_rank
FROM cand c LEFT JOIN near n ON n.globalid = c.globalid;

-- How many candidates exist per LGA versus clinics needed ("cover")
CREATE OR REPLACE TABLE gold.mart_candidate_cover AS
SELECT c.lga_id, c.lga_name, c.state_name, c.candidate_type,
       COUNT(*) AS candidates_available, ANY_VALUE(d.phc_deficit) AS clinics_needed,
       SAFE_DIVIDE(COUNT(*), NULLIF(ANY_VALUE(d.phc_deficit), 0)) AS cover_ratio,
       -- Our rule of thumb (a judgement, not a published standard): 2x or more is comfortable, because some
       -- candidates will be closed, too small, low quality or unwilling. 1-2x is tight. Under 1x is not enough.
       CASE WHEN SAFE_DIVIDE(COUNT(*), NULLIF(ANY_VALUE(d.phc_deficit), 0)) >= 2 THEN 'Comfortable'
            WHEN SAFE_DIVIDE(COUNT(*), NULLIF(ANY_VALUE(d.phc_deficit), 0)) >= 1 THEN 'Tight'
            ELSE 'Not enough' END AS cover_label
FROM gold.mart_candidates c JOIN gold.mart_lga_decision d ON d.lga_id = c.lga_id
GROUP BY c.lga_id, c.lga_name, c.state_name, c.candidate_type;
