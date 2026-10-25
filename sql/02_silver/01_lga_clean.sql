-- Layer: SILVER. Why: one clean row per LGA with a repaired polygon and its 2025 population.
-- Names are matched on a normalised key (lowercase, letters/digits only) because spellings
-- differ across sources; unmatched rows stay visible (LEFT JOIN), never silently dropped.
CREATE OR REPLACE TABLE silver.lga_clean AS
SELECT b.globalid AS lga_id, b.lgacode, b.statecode,
       TRIM(b.statename) AS state_name, TRIM(b.lganame) AS lga_name,
       ST_GEOGFROMTEXT(b.geom_wkt, make_valid => TRUE) AS geog,
       p.population AS population_2025,
       IF(p.population IS NULL, 'no_population_match', 'name_key') AS pop_match_method
FROM bronze.lga_boundaries b
LEFT JOIN bronze.population_lga p
  ON LOWER(TRIM(p.statename)) = LOWER(TRIM(b.statename))
 AND REGEXP_REPLACE(LOWER(p.lganame), r'[^a-z0-9]', '') = REGEXP_REPLACE(LOWER(b.lganame), r'[^a-z0-9]', '');
