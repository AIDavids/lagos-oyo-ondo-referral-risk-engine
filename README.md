# Healthcare Access & Referral Risk Decision Engine (Lagos, Oyo, Ondo)

**Question.** Which LGAs in Lagos, Oyo and Ondo have the largest gaps in public primary care access and emergency referral safety, so a State Ministry of Health or Health Insurance Agency can decide where to build public clinics, where to contract private clinics into the insurance scheme, and where to fund ambulances?

**Pipeline.** Bronze (raw, untouched) -> Silver (cleaned, located by LGA, nearest hospital, quality log) -> Gold (star schema, policy engine, sensitivity) -> dashboards.
SQL is in `sql/`, numbered in run order. Decisions are in `docs/adr/`. Results are in `docs/results.md`. Hypotheses were written down before the data was analysed (`docs/hypotheses.md`).

**Rebuild.** Upload the three CSVs in `data/raw_csv/` to a BigQuery dataset `bronze`, then run the files in `sql/01_bronze`, `sql/02_silver`, `sql/03_gold` in order, then `sql/04_tests` (zero rows = pass).

## Data sources and attribution (CC BY 4.0)
- Facilities: CIESIN, Columbia University (2024). GRID3 NGA - Health Facilities v2.0. New York: GRID3. https://doi.org/10.7916/kv1n-0743
- Population: Nnanatu C.C., Gadiaga A., Abbott T.J., Chamberlain H., Lazar A.N., Tatem A.J. (2025). Modelled gridded population estimates for Nigeria 2025 version 3.0. WorldPop, University of Southampton. https://dx.doi.org/10.5258/SOTON/WP00782
- LGA boundaries: GRID3 NGA operational LGA boundaries (confirm exact title and year from the shapefile metadata and add here).

## Limitations
Straight-line distance is not travel time; population is a modelled 2025 estimate; registry presence does not prove a facility is functional; thresholds are policy assumptions (sensitivity is shown); source data is not validated by government.

## Note on tools
Built with AI assistance (Claude) for code drafting; all decisions, definitions and results are documented in the ADRs and were reviewed by the author.
