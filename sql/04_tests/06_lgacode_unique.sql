-- Assertion: every LGA has a unique, non-empty code (needed to join data to the map shapes). ZERO ROWS = PASS.
SELECT lgacode, COUNT(*) AS n FROM gold.dim_lga_geo GROUP BY lgacode HAVING COUNT(*) > 1
UNION ALL SELECT 'MISSING', COUNT(*) FROM gold.dim_lga_geo WHERE lgacode IS NULL OR lgacode = '' HAVING COUNT(*) > 0
UNION ALL SELECT 'NOT_71', COUNT(*) FROM gold.dim_lga_geo HAVING COUNT(*) != 71;
