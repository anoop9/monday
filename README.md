# Steps

- Installed Postgresql and pgadmin 
- Installed Python3 and jupyter notebook

created a user named 'admin' and database named 'test'. Granted all privileges to the 'admin' user to 'test' database
```
CREATE USER admin WITH PASSWORD 'admin';
CREATE DATABASE test;
GRANT ALL PRIVILEGES ON DATABASE test TO admin;
```

- hostname: localhost
- port: 5432
- username: admin
- password: admin
- db: test

# Part 1
## Section 1.1: Create database and associated tables

Due to large file size and to avoid data loss, the **tableimport.ipynb** is used to import csv files and 
convert to postgresql tables.

### spend table
- Total imported number of rows : 102

### installs table

- Total imported number of rows : 81752 
### revenue table

- Total imported number of rows : 2126539

## Section 1.2: Query - sql code

- This query aggregates by client, country, and install date.
- It uses COALESCE and NULLIF to handle division by zero and missing data.
- The date range is set for 2021-12-01 to 2021-12-15.
```
SELECT
  i.client,
  i.country,
  i.year,
  i.month,
  i.day,
  COALESCE(SUM(s.spend), 0) AS ad_spend,
  COUNT(DISTINCT i.user_install_id) AS installs,
  CASE WHEN COUNT(DISTINCT i.user_install_id) > 0 THEN COALESCE(SUM(s.spend), 0)::float / COUNT(DISTINCT i.user_install_id) ELSE 0 END AS cpi,
  CASE WHEN COUNT(DISTINCT i.user_install_id) > 0 THEN SUM(CASE WHEN r.day <= 1 THEN r.revenue ELSE 0 END)::float / COUNT(DISTINCT i.user_install_id) ELSE 0 END AS arpi_d1,
  CASE WHEN COUNT(DISTINCT i.user_install_id) > 0 THEN SUM(CASE WHEN r.day <= 14 THEN r.revenue ELSE 0 END)::float / COUNT(DISTINCT i.user_install_id) ELSE 0 END AS arpi_d14,
  CASE WHEN COALESCE(SUM(s.spend), 0) > 0 THEN SUM(CASE WHEN r.day <= 14 THEN r.revenue ELSE 0 END)::float / COALESCE(SUM(s.spend), 0) ELSE 0 END AS roas_d14
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
WHERE
  (i.year, i.month, i.day) BETWEEN (2021, 12, 1) AND (2021, 12, 15)
GROUP BY
  i.client, i.country, i.year, i.month, i.day
ORDER BY
  i.client, i.country, i.year, i.month, i.day;
```
## Section 1.2: Summary table - csv
Check summary.csv in this folder


# Part 2. EDA

### Install python 3
```
 #Then install a virtual evnironment
 
 python3 -m venv .venv 
 
 #activate venv
 source .venv/bin/activate 
 
 pip install pandas matplotlib seaborn

```

Then Check eda.ipynb for plots and visulaization


## Recommendations:


- **Increase marketing spend** in these top-performing countries to leverage high ARPI_D14 and ROAS_D14, as shown in the bar plots.
- **Analyze user behavior** in these countries to identify what drives higher revenue and engagement.
- **Experiment with new ad creatives and channels** to further optimize CPI and maximize installs, as CPI is reasonable relative to returns.
- **Monitor for market saturation** and diminishing returns as spend increases, using trends in the visualized metrics.


# Part 3. LTV prediction

Check ltv.ipynb

# Part 4. AB Testing

Check abtest.ipynb