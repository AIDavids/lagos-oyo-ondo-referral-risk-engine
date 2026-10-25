-- 1. Do the coded columns hold what the codebook says? (confirms my column mapping)
SELECT 'ownership' AS col, ownership AS v, COUNT(*) n FROM bronze.facilities GROUP BY 2
UNION ALL SELECT 'facility_level', facility_level, COUNT(*) FROM bronze.facilities GROUP BY 2
UNION ALL SELECT 'ownership_type', ownership_type, COUNT(*) FROM bronze.facilities GROUP BY 2
UNION ALL SELECT 'facility_level_option', facility_level_option, COUNT(*) FROM bronze.facilities GROUP BY 2
ORDER BY col, n DESC;

-- 2. Rows per state in facilities (spot spelling variants)
SELECT state, COUNT(*) n FROM bronze.facilities GROUP BY state ORDER BY n DESC;

-- 3. Can every boundary polygon be parsed?
SELECT COUNT(*) AS total,
       COUNTIF(SAFE.ST_GEOGFROMTEXT(geom_wkt, make_valid => TRUE) IS NULL) AS unparsable
FROM bronze.lga_boundaries;

-- 4. Do the three states line up across the three tables?
SELECT 'facilities' AS src, state AS name, COUNT(*) n FROM bronze.facilities
WHERE LOWER(state) IN ('lagos','oyo','ondo') GROUP BY 2
UNION ALL SELECT 'boundaries', statename, COUNT(*) FROM bronze.lga_boundaries
WHERE LOWER(statename) IN ('lagos','oyo','ondo') GROUP BY 2
UNION ALL SELECT 'population', statename, COUNT(*) FROM bronze.population_lga
WHERE LOWER(statename) IN ('lagos','oyo','ondo') GROUP BY 2;

-- 5. Basic coordinate sanity (bad points can't be located later)
SELECT COUNT(*) AS total,
       COUNTIF(latitude IS NULL OR longitude IS NULL) AS missing_coords,
       COUNTIF(longitude NOT BETWEEN 2.5 AND 15 OR latitude NOT BETWEEN 4 AND 14) AS outside_nigeria_box
FROM bronze.facilities;