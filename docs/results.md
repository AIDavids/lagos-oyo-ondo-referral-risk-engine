# Results (3 states, 71 LGAs, 2025 population)

| Hypothesis | Result | Verdict |
|---|---|---|
| H1 | 24 LGAs look adequate by total density but have a public deficit; 14 still do if all Unknown-ownership facilities are counted as public | Confirmed, robust to ownership uncertainty |
| H2 | Of 40 LGAs with adequate public coverage, 39 have a median clinic-to-hospital distance under 15 km (max 17.8 km); 5 have >= 25% of clinics beyond 15 km | Rejected as stated (small isolated pocket) |
| H3 | Completeness: rural-like 0.901, mixed 0.870, urban-like 0.868 (ranges overlap) | Rejected (direction reversed, gaps small) |
| H4 | Top-10 identical across distance thresholds; at a 20k benchmark 5 of 10 remain, at 30k only 4 LGAs are flagged | Rejected for benchmark changes, confirmed for distance changes |

Robust priorities (top-10 in all 9 scenarios): Alimosho, Eti Osa, Ido, Ikorodu.

Engine vs baseline
- 24 LGAs look fine to the baseline but have a public deficit; the engine flags all 24.
- 8 of 31 deficit LGAs (26%) get "contract private clinics" rather than "build".
- 4 of the engine's top 10 are also in the baseline's top 10.
- 15 of 71 LGAs carry a low-confidence flag.
- Actions: Monitor 40, Public capacity gap 23, Contract private clinics 8. No LGA triggered "Critical capital build" or "Referral bottleneck".

Reading: in these three states the gap is public capacity, not remoteness, and the benchmark choice changes the answer far more than the distance rule.
