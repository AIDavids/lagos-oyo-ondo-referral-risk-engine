-- Layer: GOLD (dimension). Why: Power BI draws each LGA as a labelled dot on a scatter chart (no basemap, no TopoJSON),
-- so it needs one centroid (longitude, latitude) and a 3-letter code per LGA. Codes can repeat; use the tooltip for the full name.
CREATE OR REPLACE TABLE gold.dim_lga_geo AS
SELECT d.lga_id, d.lga_name, d.state_name,
       ST_X(ST_CENTROID(l.geog)) AS centroid_lon,
       ST_Y(ST_CENTROID(l.geog)) AS centroid_lat,
       UPPER(SUBSTR(REGEXP_REPLACE(d.lga_name, r'[^A-Za-z]', ''), 1, 3)) AS lga_code
FROM gold.dim_lga d JOIN silver.lga_clean l ON l.lga_id = d.lga_id;
