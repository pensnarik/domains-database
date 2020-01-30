create VIEW stat_new_m as
 select date_trunc('m'::text, site.create_date) as date_trunc,
    count(*) as count
   from site
  WHERE (site.create_date > (now() - '00:20:00'::interval))
  GROUP BY (date_trunc('m'::text, site.create_date))
  ORDER BY (date_trunc('m'::text, site.create_date));

