-- Why: bronze keeps raw rows untouched; we only add load metadata.
CREATE OR REPLACE TABLE bronze.facilities AS
SELECT *, CURRENT_TIMESTAMP() AS _loaded_at,
       'GRID3_NGA_health_facilities_v2_0.shp' AS _source_file
FROM bronze.facilities_v2_raw;

CREATE OR REPLACE TABLE bronze.lga_boundaries AS
SELECT *, CURRENT_TIMESTAMP() AS _loaded_at,
       'grid3_nga_boundary_vacclgas.shp' AS _source_file
FROM bronze.lga_boundaries_raw;

CREATE OR REPLACE TABLE bronze.population_lga AS
SELECT *, CURRENT_TIMESTAMP() AS _loaded_at,
       'lga_pop_total_scaled.csv' AS _source_file
FROM bronze.population_lga_raw;



-- 1. Do the coded columns hold what the codebook says? (fixes my column mapping if not)
SELECT 'ownership' AS col, ownership AS v, COUNT(*) n FROM bronze.facilities GROUP BY 2
UNION ALL SELECT 'facility_level', facility_level, COUNT(*) FROM bronze.facilities GROUP BY 2
UNION ALL SELECT 'ownership_type', ownership_type, COUNT(*) FROM bronze.facilities GROUP BY 2
ORDER BY col, n DESC;

-- 2. Rows per state (look for the three states and spelling variants)
SELECT state, COUNT(*) n FROM bronze.facilities GROUP BY state ORDER BY n DESC;

-- 3. Can every boundary polygon be parsed?
SELECT COUNT(*) AS total,
       COUNTIF(SAFE.ST_GEOGFROMTEXT(geom_wkt, make_valid => TRUE) IS NULL) AS unparsable
FROM bronze.lga_boundaries;