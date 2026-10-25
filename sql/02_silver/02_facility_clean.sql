-- Layer: SILVER. Why: valid point per facility, standard names, and the LGA it falls inside.
-- Originals are kept (f.*); rows with no polygon match are flagged, never dropped.
-- Longitude comes FIRST in ST_GEOGPOINT. QUALIFY needs a WHERE in BigQuery, hence WHERE TRUE.
CREATE OR REPLACE TABLE silver.facility_clean AS
WITH pts AS (
  SELECT f.*,
         ST_GEOGPOINT(f.longitude, f.latitude) AS geog,
         CASE WHEN LOWER(TRIM(f.state)) = 'fct' THEN 'FCT' ELSE INITCAP(TRIM(f.state)) END AS state_clean,
         TRIM(f.facility_name) AS facility_name_clean
  FROM bronze.facilities f
),
matched AS (
  SELECT p.globalid, l.lga_id, l.lga_name AS lga_assigned, l.state_name AS state_assigned
  FROM pts p JOIN silver.lga_clean l ON ST_WITHIN(p.geog, l.geog)
  WHERE TRUE
  QUALIFY ROW_NUMBER() OVER (PARTITION BY p.globalid ORDER BY l.lga_id) = 1
)
SELECT p.*, m.lga_id, m.lga_assigned, m.state_assigned,
       IF(m.lga_id IS NULL, 'no_polygon_match', 'st_within') AS match_method
FROM pts p LEFT JOIN matched m ON p.globalid = m.globalid;
