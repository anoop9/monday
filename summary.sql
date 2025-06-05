SELECT
    r.client,
    r.country,
    r.install_date,
    s.ad_spend,
    r.installs,
    s.ad_spend / r.installs  AS cpi,
	r.total_revenue_d1,
	r.total_revenue_d14,
    r.total_revenue_d1 / r.installs  AS arpi_d1,
    r.total_revenue_d14 / r.installs AS arpi_d14,
    r.total_revenue_d14 / s.ad_spend AS roas_d14
FROM (
    SELECT
        i.client,
        i.country,
        i.country_id,
        TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') AS install_date,
        COUNT(DISTINCT i.user_install_id) AS installs,
        SUM(CASE
                WHEN TO_DATE(r.year::TEXT || '-' || r.month::TEXT || '-' || r.day::TEXT, 'YYYY-MM-DD')
                     <= TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') + INTERVAL '1 day'
                THEN r.revenue ELSE 0
            END) AS total_revenue_d1,
        SUM(CASE
                WHEN TO_DATE(r.year::TEXT || '-' || r.month::TEXT || '-' || r.day::TEXT, 'YYYY-MM-DD')
                     <= TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD') + INTERVAL '14 days'
                THEN r.revenue ELSE 0
            END) AS total_revenue_d14
    FROM installs i
    LEFT JOIN revenue r
        ON i.user_install_id = r.user_install_id
    WHERE TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD')
          BETWEEN '2021-12-01' AND '2021-12-15'
    GROUP BY i.client, i.country, i.country_id, TO_DATE(i.year::TEXT || '-' || i.month::TEXT || '-' || i.day::TEXT, 'YYYY-MM-DD')
) r
LEFT JOIN (
    SELECT
        client,
        country_id,
        TO_DATE(year::TEXT || '-' || month::TEXT || '-' || day::TEXT, 'YYYY-MM-DD') AS spend_date,
        SUM(spend) AS ad_spend
    FROM spend
    GROUP BY client, country_id, spend_date
) s
ON r.client = s.client
   AND r.country_id = s.country_id
   AND r.install_date = s.spend_date
ORDER BY r.client, r.country, r.install_date;
