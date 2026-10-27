-- Layer: GOLD (mart). Why: every access metric for every LGA in one place (one row per LGA).
-- Each count/ratio exists twice: a cautious version (confirmed public only) and a "_high" best case
-- that counts Unknown ownership as public (ADR-002). If the two disagree, the LGA is low-confidence.
CREATE OR REPLACE TABLE gold.mart_lga_access AS
WITH c AS (SELECT * FROM gold.config_thresholds),
fac AS (
  SELECT lga_id,
         COUNT(*) AS facilities_all,
         COUNTIF(facility_level = 'Primary') AS phc_total,
         COUNTIF(facility_level = 'Primary' AND ownership = 'Public') AS phc_public,
         COUNTIF(facility_level = 'Primary' AND ownership = 'Private') AS phc_private,
         COUNTIF(facility_level = 'Primary' AND ownership = 'Unknown') AS phc_unknown_owner,
         COUNTIF(facility_level = 'Primary' AND ownership = 'Public' AND facility_level_option != 'Health Post') AS phc_public_no_posts,
         AVG(IF(ownership != 'Unknown', 1, 0)) AS c_owner,
         AVG(IF(facility_level != 'Unknown', 1, 0)) AS c_level,
         AVG(IF(facility_level_option != 'Unknown', 1, 0)) AS c_type,
         AVG(IF(in_registry, 1, 0)) AS c_registry,
         AVG(IF(lga_name_conflict, 0, 1)) AS c_lga_agree
  FROM gold.fact_facility GROUP BY lga_id),
dist AS (
  SELECT f.lga_id,
         COUNTIF(f.ownership = 'Public') AS n_pub,
         COUNTIF(f.ownership = 'Public' AND COALESCE(f.referral_km, 999) > c.beyond_km) AS n_pub_far,
         APPROX_QUANTILES(IF(f.ownership = 'Public', f.referral_km, NULL), 100)[SAFE_OFFSET(50)] AS median_km_low,
         COUNTIF(f.ownership IN ('Public','Unknown')) AS n_hi,
         COUNTIF(f.ownership IN ('Public','Unknown') AND COALESCE(f.referral_km, 999) > c.beyond_km) AS n_hi_far,
         APPROX_QUANTILES(IF(f.ownership IN ('Public','Unknown'), f.referral_km, NULL), 100)[SAFE_OFFSET(50)] AS median_km_high
  FROM gold.fact_facility f CROSS JOIN c
  WHERE f.facility_level = 'Primary'
  GROUP BY f.lga_id),
base AS (
  SELECT d.lga_id, d.state_name, d.lga_name, d.population_2025, d.pop_density_km2,
         CASE d.density_tercile WHEN 1 THEN 'Rural-like' WHEN 2 THEN 'Mixed' ELSE 'Urban-like' END AS density_tier,
         COALESCE(fac.facilities_all, 0) AS facilities_all,
         COALESCE(fac.phc_total, 0) AS phc_total,
         COALESCE(fac.phc_public, 0) AS phc_public,
         COALESCE(fac.phc_private, 0) AS phc_private,
         COALESCE(fac.phc_unknown_owner, 0) AS phc_unknown_owner,
         COALESCE(fac.phc_public_no_posts, 0) AS phc_public_no_posts,
         COALESCE(fac.c_owner, 0) AS c_owner, COALESCE(fac.c_level, 0) AS c_level,
         COALESCE(fac.c_type, 0) AS c_type, COALESCE(fac.c_registry, 0) AS c_registry,
         COALESCE(fac.c_lga_agree, 0) AS c_lga_agree,
         COALESCE(dist.n_pub, 0) AS n_pub, COALESCE(dist.n_pub_far, 0) AS n_pub_far, dist.median_km_low,
         COALESCE(dist.n_hi, 0) AS n_hi, COALESCE(dist.n_hi_far, 0) AS n_hi_far, dist.median_km_high
  FROM gold.dim_lga d
  LEFT JOIN fac ON fac.lga_id = d.lga_id
  LEFT JOIN dist ON dist.lga_id = d.lga_id)
SELECT b.lga_id, b.state_name, b.lga_name, b.population_2025, b.pop_density_km2, b.density_tier,
  b.facilities_all, b.phc_total, b.phc_public, b.phc_private, b.phc_unknown_owner, b.phc_public_no_posts,
  SAFE_DIVIDE(b.phc_total, b.population_2025) * 10000 AS total_per_10k,
  SAFE_DIVIDE(b.phc_public, b.population_2025) * 10000 AS public_per_10k,
  SAFE_DIVIDE(b.phc_public + b.phc_unknown_owner, b.population_2025) * 10000 AS public_per_10k_high,
  COALESCE(SAFE_DIVIDE(b.population_2025, NULLIF(b.phc_public, 0)), b.population_2025) AS pop_per_public_phc,
  COALESCE(SAFE_DIVIDE(b.population_2025, NULLIF(b.phc_public + b.phc_unknown_owner, 0)), b.population_2025) AS pop_per_public_phc_high,
  COALESCE(SAFE_DIVIDE(b.population_2025, NULLIF(b.phc_public_no_posts, 0)), b.population_2025) AS pop_per_public_phc_no_posts,
  SAFE_DIVIDE(b.phc_private, b.phc_public + b.phc_private) AS private_share,
  SAFE_DIVIDE(b.phc_private, b.phc_total) AS private_share_high,
  SAFE_DIVIDE(b.phc_unknown_owner, b.phc_total) AS unknown_owner_share,
  GREATEST(0, CAST(CEIL(b.population_2025 / c.benchmark_pop_per_phc) AS INT64) - b.phc_public) AS phc_deficit,
  GREATEST(0, CAST(CEIL(b.population_2025 / c.benchmark_pop_per_phc) AS INT64) - b.phc_public - b.phc_unknown_owner) AS phc_deficit_high,
  IF(b.n_pub = 0, 1.0, SAFE_DIVIDE(b.n_pub_far, b.n_pub)) AS pct_phc_beyond_15km,
  IF(b.n_hi = 0, 1.0, SAFE_DIVIDE(b.n_hi_far, b.n_hi)) AS pct_phc_beyond_15km_high,
  b.median_km_low AS median_referral_km, b.median_km_high AS median_referral_km_high,
  (b.c_owner + b.c_level + b.c_type + b.c_registry + b.c_lga_agree) / 5 AS completeness_score
FROM base b CROSS JOIN c;
