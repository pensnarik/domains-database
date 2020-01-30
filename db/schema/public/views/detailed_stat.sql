create VIEW detailed_stat as
 select date_trunc('m'::text, site.last_check_time) as date_trunc,
    sum(
        CasE
            WHEN (site.last_fetch_result = 'ok'::site_fetch_result) THEN 1
            ELSE 0
        END) as result_ok,
    sum(
        CasE
            WHEN (site.last_fetch_result = 'timeout'::site_fetch_result) THEN 1
            ELSE 0
        END) as result_timeout,
    sum(
        CasE
            WHEN (site.last_fetch_result = 'resolve_error'::site_fetch_result) THEN 1
            ELSE 0
        END) as result_resolve_error,
    count(*) as result_total
   from site
  WHERE (site.last_check_time > (now() - '01:00:00'::interval))
  GROUP BY (date_trunc('m'::text, site.last_check_time))
  ORDER BY (date_trunc('m'::text, site.last_check_time)) DESC;

grant select on table detailed_stat to stat;

