-- Layer: SETUP. Why: the three pipeline layers. All in the US location so tables can be joined across them.
CREATE SCHEMA IF NOT EXISTS bronze OPTIONS (location = 'US');
CREATE SCHEMA IF NOT EXISTS silver OPTIONS (location = 'US');
CREATE SCHEMA IF NOT EXISTS gold   OPTIONS (location = 'US');
