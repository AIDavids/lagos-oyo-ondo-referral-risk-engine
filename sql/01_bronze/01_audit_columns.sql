-- Layer: BRONZE. Why: bronze keeps raw rows untouched; we only add load metadata.
-- Inputs: bronze.*_raw tables uploaded from CSV. Outputs: bronze.facilities, lga_boundaries, population_lga.
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
