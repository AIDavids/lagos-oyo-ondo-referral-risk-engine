# Dashboard design and build notes (v4)

Layout reference: the "PHC Dashboard Layout v4" canvas (10 boards: 5 desktop, 5 phone). Everything in [brackets] on the boards is a placeholder until Power BI is connected to gold.

## 1. Decisions after three reviews (mine, and two outside opinions)

**Adopted**
- One definition per number (section 2). The Reliability page had mislabelled a figure (24) as "LGAs short"; fixed.
- Reliability becomes a stability matrix (top 12 LGAs x 18 settings) instead of bars. One verdict vocabulary: Robust, Sensitive, Not robust.
- "Robust to these tests", never "certain".
- Hospital-distance claims use "clinics 15+ km from a hospital (straight line)" and a median, not an average and a maximum. The headline no longer says "distance is not the problem".
- Confidence is defined (section 2) and tied to the Reliability page.
- Unknown owners shown as a range on the Overview.
- Rank toggle on Priorities: clinics missing (volume) or people per clinic (severity). Volume alone favours the most populous LGAs.
- Contracting shortlist with names and wards for the 8 contracting LGAs (section 4).
- Action band on the recommendation card: "Add public clinics" is the main action and gets the strongest visual weight.
- Dashboard name is "PHC Access, public clinic gaps". "Referral risk engine" overstated what the findings show.
- Drop "Fig." prefixes in the dashboard (keep them in the written report). Fold the target into the rail.
- Rule 1 renamed "Critical gap: add clinics and referral access" so it is distinct from "Add public clinics". Rule thresholds shown as numbers.

**Not adopted, with reasons**
- Dot strip on phone: does not scale from 3 to 300+ facilities. Phone uses a stacked ownership bar. The dot map (locations) stays on desktop.
- Hiding Reliability and About on phone: you wanted mobile users to get the whole flow, so they sit under a "More" tab.
- Decorative extra pages and chart types. Depth goes into existing pages.

**Parked for v2 (and why)**
- Share of people within 5 km of a public clinic: best extra metric, but needs the WorldPop raster processed to points. Too heavy for the deadline. State it as a limitation: per-LGA ratios can hide sparse areas.
- Ward-level view (no ward data for our three states loaded), population-density overlay on the dot map, cost "size of the prize" (no cost data).

## 2. Number dictionary
| Term | Definition | Value |
|---|---|---|
| LGAs assessed | LGAs in Lagos, Oyo, Ondo | 71 |
| Short of public clinics | Public clinics per 10,000 people below 1 (confirmed public only) | 31 (23 add + 8 contract) |
| Range | Same count if Unknown-owner primary clinics count as public | [x] to 31, compute |
| Hidden gaps | Short LGAs whose total primary clinics (any owner) per 10,000 is 1 or more | 24 of 31 |
| Robust LGAs | In the top 10 under all 9 target/distance settings (confirmed owners) | 4 |
| Confidence | Share of 18 settings (3 targets x 3 hospital limits x 2 ownership views) where the LGA keeps its base-case action. High 90%+, Medium 60-89%, Low under 60% | compute |
| Priority rank | Action severity, then clinics missing, then population (volume view). Severity view: people per public clinic | |
| Clinics 15+ km from a hospital | Share of primary clinics whose nearest hospital is beyond 15 km, straight line | compute |

Note: the old low-confidence flag (15 LGAs) is replaced by the confidence definition above. Update the "15" on the boards when recomputed.

## 3. SQL to add next (gold)
1. Count of short LGAs under "unknown owners as public" (the range).
2. `mart_scenarios`: 18 rows per LGA (1,278 rows) with the action under each setting. Confidence columns come from it.
3. `severity_rank` in `mart_lga_policy`.
4. `mart_state_summary`: LGAs short, people per public clinic, best-served and most-in-need LGA per state.
5. Overview totals: people in short LGAs and share, clinics needed in total, share of clinics 15+ km from a hospital, median distance.
6. Check: are the 4 robust LGAs simply the 4 biggest by population? Compare with the severity rank.
7. Contracting shortlist table (section 4).
8. Reconciliation tests: 23 + 8 + 40 = 71, state splits sum to totals, every KPI equals the sum of its parts.

## 4. Contracting shortlist
For each of the 8 contracting LGAs, list private primary clinics ranked by: (1) registry ID present, (2) type known, (3) distance to the nearest public clinic, furthest first (they fill the biggest gap). Columns: clinic, ward, level and for-profit/not-for-profit, km from nearest public clinic, registry ID. Show top 5 per LGA, with "[n] available vs [n] needed (cover [x]x)". Export button. Caveat on the page: candidates only; verify staffing and opening status before contracting (the registry cannot confirm either).

## 5. Map decision
Desktop: real LGA shapes (shape map from TopoJSON, key = LGA code), three small multiples, with a split bar and people affected under each state. Test it first. Fallback and phone: labelled square tiles built as a scatter chart from snapped LGA centroids (native, tappable, no TopoJSON). The hexagons on the boards are a stand-in for either. Phone layouts can only use visuals that already exist on the desktop page, so the tile scatter lives on the desktop page (off-canvas if needed).

## 6. Target and limitations
"1 public clinic per 10,000" is a planning assumption: the low end of national guidance for a Primary Health Centre (10,000 to 20,000 people). We count every primary-level facility, including smaller clinics and health posts, so gaps may be understated; listed does not mean functional. Check the NPHCDA minimum-standards source before quoting wording publicly.

## 7. Build order
1. Test the shape map (1 hour). 2. Overview + Priorities. 3. LGA Profile (drill-through). 4. Reliability matrix. 5. About. 6. Phone layouts. 7. Alt text, tab order, final reconciliation.

## 8. Update (2026-10-28)
- **Findings page** added (after LGA Profile): four findings, each with a headline, one number and a "so what". This is normal in consulting work when kept short. It carries the "why we separate public from private" explanation. Hypothesis tests stay in the written report.
- **Priorities table:** 31 rows scroll in a fixed-height table with a sticky header. Default is the Top 10 for the chosen ranking, with Top 10 / Top 20 / All. Filters: state and action.
- **Candidates panel** follows the selected LGA's action: contracting LGAs show private clinics to approach; add-public LGAs show public Health Posts to upgrade; no-action LGAs show an empty state.
- **People per public clinic** = LGA population divided by public primary clinics (0 clinics = whole population). Higher is worse. Target: 10,000.
- **Hidden gaps** = short LGAs that look fine when private clinics are counted (24 of 31).
- **LGA Profile** gains: "How we reached this recommendation" (the four rules in order, with pass or fail), a confidence strip (18 settings), and a peer comparison.
- Run order: sql/03_gold/05, 06, 07, then sql/04_tests/03_gold_tests_v2.sql (zero rows = pass), then 04_checks.sql.

## 9. Update after first run (2026-10-29)
- Real results: 71 LGAs, 31 short (range 21 to 31 if unknown owners count as public), 24 hidden gaps, 18.8 million people (69%) in short LGAs, 999 clinics needed. All 8 contracting LGAs are in Lagos.
- The four robust LGAs (Alimosho, Ikorodu, Eti Osa, Ido) are both the four largest and the four with the most people per public clinic, so the finding is not an artefact of ranking by volume.
- Alimosho and Ikorodu are contracting LGAs where private clinics barely cover the gap (about 1.05x). Upgrade candidates (public health posts) are far fewer than clinics needed in most add-public LGAs: new construction is the main lever.
- Confidence redefined over 6 data checks (see ADR-005). Default ranking = people per public clinic.
