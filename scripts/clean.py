# clean.py
# Why: BigQuery can't load .shp/.gpkg, so convert raw files to CSV once.
# Raw values are not changed; only column names are restored and text is safely quoted.
import csv
from pathlib import Path
import geopandas as gpd
 
RAW = Path(__file__).resolve().parent.parent / "raw"
print("Looking in:", RAW)

# ---------- Facilities ----------
# Use the GeoPackage if present (full column names), else the shapefile
gpkgs = list(RAW.glob("*health_facilities_v2_0.gpkg"))
src = gpkgs[0] if gpkgs else RAW / "GRID3_NGA_health_facilities_v2_0.shp"
f = gpd.read_file(src).to_crs(4326)

# Why: shapefiles truncate names to 10 chars; restore the codebook names
# so bronze matches the release notes.
f = f.rename(columns={
    "nhfr_facil": "nhfr_facility_code",
    "lga_name_d": "lga_name_disagreement",
    "ward_name_": "ward_name_disagreement",
    "facility_n": "facility_name",
    "facility_1": "facility_name_source",
    "ownership_": "ownership_type",
    "facility_l": "facility_level",
    "facility_2": "facility_level_option",
    "geocoordin": "geocoordinates_source",
    "last_updat": "last_updated",
})

# Why QUOTE_NONNUMERIC: wraps every text field in quotes and doubles any quote
# inside it, so stray " characters (e.g. ward names like Jamaa"Re C) can't break parsing.
f.drop(columns="geometry").to_csv(
    RAW / "facilities_v2_0.csv", index=False, quoting=csv.QUOTE_NONNUMERIC)
print("facilities:", len(f), "rows from", src.name)
print("facility columns:", list(f.columns))

# ---------- LGA boundaries ----------
b = gpd.read_file(RAW / "grid3_nga_boundary_vacclgas.shp").to_crs(4326)
b["geom_wkt"] = b.geometry.to_wkt()   # polygon as text; BigQuery converts it later
b.drop(columns="geometry").to_csv(
    RAW / "lga_boundaries.csv", index=False, quoting=csv.QUOTE_NONNUMERIC)
print("boundaries:", len(b), "rows")
print("boundary columns:", list(b.columns))