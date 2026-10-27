# ADR-004: Persistence (BigQuery sandbox tables expire after 60 days)

Status: Accepted (2026-10-27)

Context: BigQuery sandbox tables, views and partitions expire after 60 days by default.

Decision: BigQuery is the build engine, not the home of the deliverables.
- All SQL is in Git, numbered in run order; the pipeline rebuilds from three small open-data CSVs kept in data/raw_csv/.
- Power BI uses Import mode, so the .pbix keeps its data after tables expire.
- Gold tables are exported to CSV as a backup (and as the source for any live dashboard that must outlive BigQuery).
- Optional: link a billing account (the free tier still applies) and set table expiration to none.

Consequence: expiry costs a rebuild of about ten SQL files, not the project.
