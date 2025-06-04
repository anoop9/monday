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
  AND r.year = i.year
  AND r.month = i.month
  AND r.day = i.day
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
Then Check eda.ipynb for visualization

## Recommendations for Next Steps

- Increase marketing spend in US, DE and GB , the top-performing countries to leverage high ARPI_D14 and ROAS_D14.
- Monitor CPI and ROAS_D14 to ensure marketing efficiency remains high as spend increases.
- Analyze user behavior in these countries to identify drivers of high ARPI_D14 and replicate successful strategies elsewhere.
- Experiment with new ad creatives and channels to further optimize CPI and maximize installs.
- Watch for signs of market saturation in installs and ARPI_D14 trends to optimize future campaigns.

# Part 3. LTV prediction

Check ltv.ipynb

## LTV Estimation Approach

- Used ARPI_D1 and ARPI_D14 from summary.csv for US users in Fruit Battle.
- Fitted a linear regression to extrapolate ARPI to day 28 (assumed user lifetime).
- Estimated LTV as ARPI_D28 from the regression.
- Visualized the ARPI curve and regression fit.

# Part 4. AB Testing

Check abtest.ipynb

Explanation:
- Calculates ARPI_D1 and D1 Retention rates for both groups.
- Performs two-sample t-test for ARPI_D1 and z-test for proportions for D1 Retention.

#### Recommendation

- **Statistical Significance:**
    - ARPI_D1: Significant
    - D1 Retention: Significant
- **Power:**
    - ARPI_D1: Insufficient
    - D1 Retention: Sufficient

- **Should the feature be rolled out?**
    -  No, more data or further testing is needed.

- **Is there enough evidence?**
    - No

- **If not significant, what next?**
    - Increase sample size or run the test longer to achieve sufficient power and statistical significance.
