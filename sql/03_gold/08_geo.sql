-- Layer: GOLD (dimension). Why: one row per LGA with the official code (key for the Power BI shape map),
-- a centroid (for the phone dot map) and a 3-letter label. Codes can repeat; use the tooltip for the full name.
-- lgacode is cast to text so it matches the TopoJSON property exactly (31018 as text, never as a number).
CREATE OR REPLACE TABLE gold.dim_lga_geo AS
SELECT d.lga_id, CAST(d.lgacode AS STRING) AS lgacode, d.lga_name, d.state_name,
       ST_X(ST_CENTROID(l.geog)) AS centroid_lon,
       ST_Y(ST_CENTROID(l.geog)) AS centroid_lat,
       UPPER(SUBSTR(REGEXP_REPLACE(d.lga_name, r'[^A-Za-z]', ''), 1, 3)) AS lga_label
FROM gold.dim_lga d JOIN silver.lga_clean l ON l.lga_id = d.lga_id;
