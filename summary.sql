-- Step 1: Final SELECT statement to join the aggregated data from subqueries and calculate the required metrics.
SELECT
    ai.client,
    ai.country,
    ai.install_date,
    -- Use COALESCE to show 0 for cohorts with no ad spend.
    COALESCE(asp.total_spend, 0) AS "ad_spend",
    ai.total_installs AS "installs",
    -- CPI: Cost Per Install. Use NULLIF to prevent division by zero.
	COALESCE(ar.d1_revenue, 0) AS "total_revenue_d1",
	COALESCE(ar.d14_revenue, 0) AS "total_revenue_d14",
    COALESCE(asp.total_spend, 0) / NULLIF(ai.total_installs, 0) AS "cpi",
    -- ARPI_D1: Average Revenue Per Install (Day 1).
    COALESCE(ar.d1_revenue, 0) / NULLIF(ai.total_installs, 0) AS "apri_d1",
    -- ARPI_D14: Average Revenue Per Install (Day 14).
    COALESCE(ar.d14_revenue, 0) / NULLIF(ai.total_installs, 0) AS "arpi_d14",
    -- ROAS_D14: Return On Ad Spend (Day 14).
    COALESCE(ar.d14_revenue, 0) / NULLIF(asp.total_spend, 0) AS "roas_d14"
FROM
    -- Subquery 1 : Count total installs per cohort.
    (
        SELECT
            client,
            country,
            country_id,
            (year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-' || LPAD(day::TEXT, 2, '0'))::DATE AS install_date,
            COUNT(user_install_id) AS total_installs
        FROM
            installs
        WHERE
            (year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-' || LPAD(day::TEXT, 2, '0'))::DATE BETWEEN '2021-12-01' AND '2021-12-15'
        GROUP BY
            client,
            country,
            country_id,
            install_date
    ) ai
-- LEFT JOIN from installs ensures we keep all install cohorts, even if they have no spend or revenue.
LEFT JOIN
    -- Subquery 2 : Calculate total ad spend.
    (
        SELECT
            client,
            country_id,
            (year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-' || LPAD(day::TEXT, 2, '0'))::DATE AS spend_date,
            SUM(spend) AS total_spend
        FROM
            spend
        GROUP BY
            client,
            country_id,
            spend_date
    ) asp ON ai.install_date = asp.spend_date AND ai.country_id = asp.country_id AND ai.client = asp.client
LEFT JOIN
    -- Calculate D1 and D14 revenue.
    (
        SELECT
            i.client,
            i.country,
            i.install_date,
            SUM(CASE WHEN ((r.year::TEXT || '-' || LPAD(r.month::TEXT, 2, '0') || '-' || LPAD(r.day::TEXT, 2, '0'))::DATE - i.install_date) <= 1 THEN r.revenue ELSE 0 END) AS d1_revenue,
            SUM(CASE WHEN ((r.year::TEXT || '-' || LPAD(r.month::TEXT, 2, '0') || '-' || LPAD(r.day::TEXT, 2, '0'))::DATE - i.install_date) <= 14 THEN r.revenue ELSE 0 END) AS d14_revenue
        FROM
            revenue r
        -- This inner join is on the base installs table to get the install date for each user.
        JOIN
            (SELECT user_install_id, client, country, (year::TEXT || '-' || LPAD(month::TEXT, 2, '0') || '-' || LPAD(day::TEXT, 2, '0'))::DATE as install_date from installs) i
            ON r.user_install_id = i.user_install_id
        WHERE
            i.install_date BETWEEN '2021-12-01' AND '2021-12-15'
        GROUP BY
            i.client,
            i.country,
            i.install_date
    ) ar ON ai.install_date = ar.install_date AND ai.country = ar.country AND ai.client = ar.client
ORDER BY
    ai.client,
    ai.country,
	ai.install_date;

