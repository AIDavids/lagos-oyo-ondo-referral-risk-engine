-- Assertion: every LGA has a unique, non-empty code (needed to join data to the map shapes). ZERO ROWS = PASS.
SELECT lgacode, COUNT(*) AS n FROM gold.dim_lga_geo GROUP BY lgacode HAVING COUNT(*) > 1
UNION ALL SELECT 'MISSING', COUNT(*) FROM gold.dim_lga_geo WHERE lgacode IS NULL OR lgacode = '' HAVING COUNT(*) > 0
UNION ALL SELECT 'NOT_71', COUNT(*) FROM gold.dim_lga_geo HAVING COUNT(*) != 71
UNION ALL SELECT 'TILE_DUPLICATE', COUNT(*) FROM (SELECT state_name, tile_row, tile_col FROM gold.dim_lga_tile GROUP BY 1,2,3 HAVING COUNT(*) > 1) HAVING COUNT(*) > 0
UNION ALL SELECT 'TILES_NOT_71', COUNT(*) FROM gold.dim_lga_tile HAVING COUNT(*) != 71;
