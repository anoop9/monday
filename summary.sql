SELECT
  i.client,
  i.country,
  i.year,
  i.month,
  i.day,
  COALESCE(s.spend, 0) AS ad_spend,
  COUNT(DISTINCT i.user_install_id) AS installs,
  COALESCE(s.spend, 0)::float / NULLIF(COUNT(DISTINCT i.user_install_id), 0) AS cpi,
  SUM(CASE WHEN r.day <= 1 THEN r.revenue ELSE 0 END)::float / NULLIF(COUNT(DISTINCT i.user_install_id), 0) AS arpi_d1,
  SUM(CASE WHEN r.day <= 14 THEN r.revenue ELSE 0 END)::float / NULLIF(COUNT(DISTINCT i.user_install_id), 0) AS arpi_d14,
  SUM(CASE WHEN r.day <= 14 THEN r.revenue ELSE 0 END)::float / NULLIF(COALESCE(s.spend, 0), 0) AS roas_d14
FROM installs i
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
WHERE (i.year, i.month, i.day) BETWEEN (2021, 12, 1) AND (2021, 12, 15)
GROUP BY i.client, i.country, i.year, i.month, i.day, s.spend
ORDER BY i.client, i.country, i.year, i.month, i.day;