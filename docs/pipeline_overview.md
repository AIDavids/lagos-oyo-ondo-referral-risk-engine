# Pipeline overview: SQL and DAX in one place

## SQL layers
| Layer | File | What it does | Tables produced | Used by |
|---|---|---|---|---|
| Setup | 00_setup/01 | Creates the three datasets | bronze, silver, gold | all |
| Bronze | 01_bronze/01 | Adds load metadata to the raw uploads | facilities, lga_boundaries, population_lga | silver |
| Silver | 02_silver/01 | Clean LGA polygons plus 2025 population | lga_clean | facility_clean, gold |
| Silver | 02_silver/02 | Valid point per facility, standard names, LGA by location | facility_clean | everything downstream |
| Silver | 02_silver/03 | Logs every data-quality issue with a rule code | dq_audit | About page |
| Silver | 02_silver/04 | Nearest hospital for every primary facility | phc_referral | distance metrics |
| Gold | 03_gold/01 | Thresholds, dimensions, facts, funnel | config_thresholds, dim_lga, dim_facility_type, fact_facility, fact_dq_audit, fact_funnel | marts |
| Gold | 03_gold/02 | Every access metric per LGA | mart_lga_access | policy |
| Gold | 03_gold/03 | Decision rules (first match wins) plus baseline | mart_lga_policy | decision |
| Gold | 03_gold/04 | 9 target x distance scenarios (top-10 stability) | mart_sensitivity, mart_top10_stability, mart_priority_robustness | Reliability |
| Gold | 03_gold/05 | 18 scenarios per LGA and confidence | mart_scenarios, mart_confidence | Reliability, profile |
| Gold | 03_gold/06 | Decision table, state summary, Overview KPIs | mart_lga_decision, mart_state_summary, mart_kpis | Overview, Priorities |
| Gold | 03_gold/07 | Candidate clinics and cover | mart_candidates, mart_candidate_cover | Priorities, profile |
| Gold | 03_gold/08 | LGA codes, centroids, labels | dim_lga_geo | maps |

## Power BI layer (DAX in powerbi/measures.dax)
| Measure group | Examples | Reads from (SQL) | Page |
|---|---|---|---|
| Counts and KPIs | LGAs Short, Hidden Gaps, People In Short LGAs, Clinics Needed | mart_lga_decision, mart_kpis | Overview |
| Dynamic text | Headline, Subheadline, Range Text | the counts above | Overview |
| Selected LGA | Selected LGA ID, Selected Action, Confidence Text, Profile Sentence | mart_lga_decision | Overview, Profile |
| Action colours | Action Fill, Action Text Color | Selected Action | Overview, Profile |
| Cover | Cover Ratio, Cover Label, Cover Text | mart_candidate_cover | Priorities, Profile |
| Ranking toggle | Rank Value | pop_per_public_phc, phc_deficit | Priorities |
| Reliability | Same Action Flag | mart_scenarios, mart_confidence | Reliability |
Rule: decisions and numbers are computed in SQL (versioned, tested). DAX only selects, formats and reacts to clicks. If a DAX measure starts re-deriving a decision, move it into SQL.

## Where each dashboard number comes from
31 short, 23 add, 8 contract, 40 none: mart_lga_decision. Range 21: mart_kpis. Hidden gaps 24: mart_kpis. People and clinics needed: mart_kpis. Cover: mart_candidate_cover. Confidence: mart_confidence.
