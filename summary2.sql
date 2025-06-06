SELECT
    r.client,
    r.country,
    r.install_date,
    s.ad_spend,
    r.installs,
    -- Calculate Cost Per Install (CPI).
    -- This assumes 's.ad_spend' and 'r.installs' are not zero or null.
    s.ad_spend / r.installs  AS cpi,
    r.total_revenue_d1,
    r.total_revenue_d14,
    -- Calculate Average Revenue Per Install for Day 1 (ARPI_D1).
    r.total_revenue_d1 / r.installs  AS arpi_d1,
    -- Calculate Average Revenue Per Install for Day 14 (ARPI_D14).
    r.total_revenue_d14 / r.installs AS arpi_d14,
    -- Calculate Return On Ad Spend for Day 14 (ROAS_D14).
    -- This also assumes 's.ad_spend' is not zero or null.
    r.total_revenue_d14 / s.ad_spend AS roas_d14
FROM (
    -- Subquery 'r': Aggregates install data and calculates D1 and D14 revenue for each cohort.
    -- This subquery forms the basis for our cohort analysis, linking installs to their subsequent revenue.
    SELECT
        i.client,
        i.country,
        i.country_id,
        -- Convert year, month, day columns from 'installs' table into a proper DATE format.
        TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') AS install_date,
        -- Count distinct user installs for each cohort.
        COUNT(DISTINCT i.user_install_id) AS installs,
        -- Calculate total revenue generated within 1 day of install.
        -- Uses a CASE statement to sum revenue only if the revenue date is within 1 day of the install date.
        SUM(CASE
                WHEN TO_DATE(r.year::TEXT || '-' || r.month::TEXT || '-' || r.day::TEXT, 'YYYY-MM-DD')
                     <= TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') + INTERVAL '1 day'
                THEN r.revenue ELSE 0
            END) AS total_revenue_d1,
        -- Calculate total revenue generated within 14 days of install.
        -- Uses a CASE statement to sum revenue only if the revenue date is within 14 days of the install date.
        SUM(CASE
                WHEN TO_DATE(r.year::TEXT || '-' || r.month::TEXT || '-' || r.day::TEXT, 'YYYY-MM-DD')
                     <= TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') + INTERVAL '14 days'
                THEN r.revenue ELSE 0
            END) AS total_revenue_d14
    FROM installs i
    -- LEFT JOIN with 'revenue' table ensures all installs are included,
    -- even if they haven't generated any revenue yet.
    LEFT JOIN revenue r
        ON i.user_install_id = r.user_install_id
    WHERE TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD')
          -- Filter installs within a specific date range for cohort analysis.
          BETWEEN '2021-12-01' AND '2021-12-15'
    GROUP BY i.client, i.country, i.country_id, TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD')
) r
-- LEFT JOIN with subquery 's' to bring in ad spend data.
-- This ensures that all install cohorts (from 'r') are kept, even if there's no matching ad spend.
LEFT JOIN (
    -- Subquery 's': Aggregates total ad spend for each client, country, and date.
    SELECT
        client,
        country_id,
        -- Convert year, month, day columns from 'spend' table into a proper DATE format.
        TO_DATE(year::TEXT || '-' || month::TEXT || '-' || day::TEXT, 'YYYY-MM-DD') AS spend_date,
        SUM(spend) AS ad_spend
    FROM spend
    GROUP BY client, country_id, spend_date
) s
ON r.client = s.client
   AND r.country_id = s.country_id
   AND r.install_date = s.spend_date -- Join spend data on the install date (cohort date).
ORDER BY r.client, r.country, r.install_date; -- Order the results for better readability and analysis.