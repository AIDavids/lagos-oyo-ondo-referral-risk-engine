# Hypotheses (H1-H4)

Written in the project plan (TDD v4) before any data was downloaded, and recorded in
this repo as a dated commit. The commit date of this file is the reference date.
Note: value-level profiling of bronze (category counts, state counts, coordinate checks)
was run on 2026-10-25; the hypotheses below were not changed after seeing it.

| # | I expect... | because... | If I'm wrong, I'll see... |
|---|---|---|---|
| H1 | Some LGAs have total clinic density >= 1 per 10k but public density < 1 per 10k | urban and peri-urban supply is dominated by private for-profit clinics | public density tracks total density closely; few or no LGAs have total >= 1 but public < 1 |
| H2 | Some LGAs with adequate PHC coverage still have a large share of PHCs > 15 km from a secondary/tertiary hospital | hospitals cluster in state capitals and big towns, rural PHCs don't | median PHC-to-hospital distance < 15 km in nearly all LGAs with adequate coverage |
| H3 | Rural LGAs have lower registry completeness than urban ones | field listing and updates are weaker away from cities | completeness scores are similar across urban and rural LGAs |
| H4 | The top-priority LGAs are robust: they stay on the priority list when thresholds change | the worst gaps are large, not marginal | more than half of the top-10 LGAs change when benchmark (10k/20k/30k) or distance (10/15/20 km) changes |

Measurement note for H3: the source (GRID3 v2.0) already removed records without usable
coordinates, so completeness uses Unknown ownership, Unknown level/type and LGA-name
disagreement, not missing coordinates.
