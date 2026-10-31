# How to run the SQL and what to paste back

Run the files in the order below. Each file reads tables created by the files before it, so the order matters. Every file uses `CREATE OR REPLACE`, so it is safe to run any file again. If you change a file, rerun it and everything after it.

## How to run one file
1. BigQuery console > Compose new query (the + tab).
2. Open the file in your editor, copy everything, paste, click Run.
3. A file that builds tables shows "This statement created a new table named ..." once per table. Nothing to paste unless it errors.
4. Files that only read data (tests, checks) show a result table. For files with several SELECTs (04_checks), highlight one statement at a time and click Run (or Run selected).
5. To paste results: copy the whole result table including the header row and every column (a result with missing columns hides numbers).
6. If anything errors: stop, copy the red error message and name the file. Do not run later files.

## Order for the new work
| # | File | You should see | Paste back |
|---|---|---|---|
| 1 | sql/03_gold/05_scenarios_confidence.sql | 2 tables created | nothing unless an error |
| 2 | sql/03_gold/06_decision_state_kpis.sql | 3 tables created | nothing unless an error |
| 3 | sql/03_gold/07_candidates.sql | 2 tables created | nothing unless an error |
| 4 | sql/03_gold/08_geo.sql | 2 tables created (dim_lga_geo, dim_lga_tile) | nothing unless an error |
| 5 | sql/04_tests/03_gold_tests_v2.sql | "There is no data to display" | that message, or the rows |
| 6 | sql/04_tests/06_lgacode_unique.sql | "There is no data to display" | that message, or the rows |
| 7 | sql/04_tests/04_checks.sql (6 SELECTs, one at a time) | 6 result tables | all six |
| 8 | sql/04_tests/05_robustness_check.sql | 1 row | the row |

## Earlier files (already run)
00_setup, 01_bronze (01, 02), 02_silver (01 to 04), 03_gold (01 to 04), 04_tests (00, 01, 02). Only rerun these if you rebuild from scratch, in that order.

## If tables have expired (60 days)
Reload the three CSVs from data/raw_csv into dataset bronze (tables facilities_v2_raw, lga_boundaries_raw, population_lga_raw), then run every file above in numeric order, layer by layer.
