# Steps

```
CREATE USER admin WITH PASSWORD 'admin';  # Create the user admin
CREATE DATABASE test;
GRANT ALL PRIVILEGES ON DATABASE test TO admin;


```

postgres
hostname: localhost
port: 5432
username: admin
password: admin
db: test

# Part 1:
## Section 1.1: Table creation sqls

### spend table

```

CREATE TABLE spend (
country_id INTEGER,
client VARCHAR(255),
year INTEGER,
month INTEGER,
day INTEGER,
spend NUMERIC(18,8)
);

```



1. spend colum truncated to 8 decimal places

### installs table

```
CREATE TABLE installs (
country VARCHAR(2),
country_id INTEGER,
user_install_id UUID,
client VARCHAR(255),
year INTEGER,
month INTEGER,
day INTEGER
);
```

### revenue table

```
CREATE TABLE revenue (
country VARCHAR(2),
client VARCHAR(255),
year INTEGER,
month INTEGER,
day INTEGER,
user_install_id UUID,
revenue NUMERIC(18,8)
);
```


1. revenue colum truncated to 8 decimal places

## Section 1.2: Query - sql code

```
SELECT
  i.client,
  i.country,
  i.year,
  i.month,
  i.day,
  COALESCE(SUM(s.spend), 0) AS ad_spend,
  COUNT(i.user_install_id) AS installs,
  CASE WHEN COUNT(i.user_install_id) > 0 THEN COALESCE(SUM(s.spend), 0) / COUNT(i.user_install_id) ELSE 0 END AS cpi,
  -- ARPI D1: revenue on install day
  ROUND(SUM(CASE WHEN r.year = i.year AND r.month = i.month AND r.day = i.day THEN r.revenue ELSE 0 END) / NULLIF(COUNT(i.user_install_id), 0), 8) AS arpi_d1,
  -- ARPI D14: revenue within 14 days of install
  ROUND(SUM(CASE WHEN (r.year, r.month, r.day) BETWEEN (i.year, i.month, i.day) AND (i.year, i.month, i.day + 13) THEN r.revenue ELSE 0 END) / NULLIF(COUNT(i.user_install_id), 0), 8) AS arpi_d14,
  -- ROAS D14: revenue within 14 days / ad spend
  CASE WHEN COALESCE(SUM(s.spend), 0) > 0
    THEN ROUND(SUM(CASE WHEN (r.year, r.month, r.day) BETWEEN (i.year, i.month, i.day) AND (i.year, i.month, i.day + 13) THEN r.revenue ELSE 0 END) / SUM(s.spend), 8)
    ELSE 0
  END AS roas_d14
FROM
  installs i
LEFT JOIN spend s
  ON s.client = i.client
  AND s.country_id = i.country_id
  AND s.year = i.year
  AND s.month = i.month
  AND s.day = i.day
LEFT JOIN revenue r
  ON r.client = i.client
  AND r.country = i.country
  AND r.user_install_id = i.user_install_id
  -- revenue date will be filtered in aggregation
WHERE
  (i.year, i.month, i.day) BETWEEN (2021, 12, 1) AND (2021, 12, 15)
GROUP BY
  i.client, i.country, i.year, i.month, i.day
ORDER BY
  i.client, i.country, i.year, i.month, i.day;

```
## Section 1.2: Summary table - csv
Check summary.csv in this folder