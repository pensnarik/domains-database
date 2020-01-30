create VIEW stat_new_h as
 select date_trunc('h'::text, site.create_date) as date_trunc,
    count(*) as count
   from site
  WHERE (site.create_date > (now() - '20:00:00'::interval))
  GROUP BY (date_trunc('h'::text, site.create_date))
  ORDER BY (date_trunc('h'::text, site.create_date));

