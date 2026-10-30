# Power BI build steps (fast path)

## 0. Data (20 min)
1. Get data > Google BigQuery > project nigeria-health-engine > dataset gold. Choose **Import** (not DirectQuery). If sign-in fails, run `SELECT * FROM gold.<table>` in BigQuery, Save results > CSV, and load the CSVs.
2. Tables: mart_lga_decision, mart_kpis, mart_state_summary, mart_candidates, mart_candidate_cover, mart_scenarios, mart_confidence, mart_priority_robustness, fact_facility, dim_lga_geo, fact_funnel.
3. Model view: mart_lga_decision[lga_id] one-to-many to fact_facility, mart_candidates, mart_candidate_cover, mart_scenarios, dim_lga_geo (single direction). mart_scenarios[lga_id] many-to-one to mart_confidence[lga_id]. mart_state_summary[state_name] one-to-many to mart_lga_decision (state_name). Leave mart_kpis and fact_funnel unrelated.
4. View > Themes > Browse for themes > powerbi/theme.json. Page background is #EEF2F4. Set page size to 1280 x 720.
5. Create table "_Measures" and paste powerbi/measures.dax. Create the disconnected table "Rank By".
6. fact_facility new column: Dot Type = IF(fact_facility[facility_level] IN {"Secondary","Tertiary"}, "Hospital", SWITCH(fact_facility[ownership], "Public", "Public clinic", "Private", "Private clinic", "Owner unknown")).
7. Edit interactions: set every visual to Filter, not Highlight.

## 1. Overview (about 2 hours)
- Rail: rectangle (#0B2530) + page navigator + slicers (state, ownership view). Headline: card with [Headline]; subheadline: card with [Subheadline].
- 4 KPI cards: [People In Short LGAs], [Clinics Needed], [Hidden Gaps], [Pct Clinics Beyond 15km]. Add an info icon tooltip with the definition.
- Map (real LGA shapes, one Shape map per state): Visualizations > Shape map. Format > Map settings > Add map > Browse > powerbi/lga_three_states.topojson. Location = dim_lga_geo[lgacode] (set the column data type to Text first), Legend = mart_lga_decision[action_label], Tooltips = lga_name, people per public clinic, confidence. Add a visual-level filter state_name = Lagos / Oyo / Ondo on each of the three copies. Keep Auto zoom on, turn off labels and legend inside the map, set the border to white 0.75 pt. Colours: Add public clinics #B4281E, Contract private clinics #FFFFFF with a red border (or the hatch look via #E8B4AF), No action now #C9D3D8.
- Test the shape map first (10 minutes). If the file is rejected, regenerate it with mapshaper.org: load the shapefile, run `-filter 'statename=="Lagos" || statename=="Oyo" || statename=="Ondo"'`, `-simplify 20% keep-shapes`, `-filter-fields lgacode,lganame,statename`, then Export > TopoJSON.
- Phone only: a scatter chart (X = dim_lga_geo[centroid_lon], Y = centroid_lat, Legend = action_label, Details = lga_label) placed off-canvas on the desktop page and pulled into the phone layout, because tiny LGAs such as Lagos Island are hard to tap as shapes.
- State split: 100% stacked bar from mart_state_summary (n_add, n_contract, n_none). Scorecard table from the same table.
- Recommendation card: text cards with [Selected LGA], [Selected Action] (background = [Action Fill], font = [Action Text Color] via conditional formatting > field value), [Confidence Text], [Cover Text]. A button "Open full profile" with Drill through action.
- Default selection: use a bookmark with the top LGA selected, or rely on the [Selected LGA ID] default.

## 2. Priorities (1.5 hours)
- Table: lga_name, state_name, action_label, pop_per_public_phc, phc_deficit, confidence, robust star. Visual filter: action_label is not "No action now"; Top N by [Rank Value].
- Slicer from "Rank By" (buttons). Candidates table: mart_candidates filtered by candidate_rank <= 5 and the selected LGA. Cover text above it.

## 3. LGA Profile (2 hours)
- Drill-through page filtered by lga_name. Header [Selected LGA]. Action card as on Overview.
- Vitals: bullet or bar visuals with target lines (10,000 per clinic; 15 km).
- Facility dots: scatter, X = fact_facility[longitude], Y = latitude, Legend = Dot Type. Hospitals use a square marker, larger size.
- Ownership bar: stacked bar of ownership counts. Rank cards: RANKX measures.

## 4. Findings, Reliability, About (2 hours)
- Findings: text boxes + cards (static text plus numbers from [Hidden Gaps] etc.).
- Reliability: matrix, rows = lga_name (top 12 by robust/severity), columns = owner_view > benchmark > beyond_km, values = [Same Action Flag] with background colour rules (1 teal, 0 white with red border).
- About: table of rules (static), funnel from fact_funnel, text boxes for limits.

## 5. Phone (1.5 hours)
View > Phone layout, per page. Overview: headline, 2 KPIs, state slicer, one scatter map, action card. Priorities: table (top 5). Profile: action card, vitals, ownership bar. Visuals must already exist on the desktop page.

## 6. Final checks (30 min)
Alt text on every visual, tab order, titles written as findings, reconcile KPIs with 04_checks.sql (31, 21, 24, 999).
