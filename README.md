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

Check summary.sql 

#### We want all revenue events for a given installed user within 14 days after their install date. So in total revenue calculation which is used for ARPI_D[N], the revenue date is not filtered BETWEEN '2021-12-01' AND '2021-12-15'. 
- That would exclude revenue for users who installed on 2021-12-15 but earned revenue on 2021-12-16 or later (which is within D14). 
- It would cut off valid D1 and D14 revenue, especially toward the end of your install window. eg: 2021-12-15 → 2021-12-29 (D14)


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
Then Check eda.ipynb for visualization and recommendations

# Part 3. LTV prediction

Check ltv.ipynb for visualization

**Approach**:
- Load and filter data: Use summary.csv, filter for fruit_battle, country == US, and install dates between 2021-12-01 and 2021-12-15.
- Prepare ARPI values: For each install date, get arpi_d1 and arpi_d14 (average revenue per install at day 1 and day 14) and caluclate the mean arpi_d1 and arpi_d14.
- Use linear regression with points (1, ARPI_D1) and (14, ARPI_D14). 
- Extrapolate to predict overall ARPI at day 28, which serves as the estimated LTV.
- Visualize: Plot ARPI over time and show the regression line extended to day 28 to visualize the LTV estimate.


**Estimated LTV (ARPI_D28) for US: 0.528**


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
