CREATE MATERIALIZED VIEW tenki_gold AS
SELECT
  date_format(ymd, 'yyyy-MM') AS ym,
  area_2 AS area,
  AVG(`平均気温（℃）計測値`) AS temp
FROM tenki_silver
GROUP BY date_format(ymd, 'yyyy-MM'), area