CREATE MATERIALIZED VIEW g_tenki AS
SELECT
  date_format(ymd, 'yyyy-MM') AS ym,
  area_2 AS area,
  AVG(`平均気温（℃）計測値`) AS temp
FROM s_tenki
GROUP BY date_format(ymd, 'yyyy-MM'), area