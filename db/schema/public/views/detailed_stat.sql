CREATE OR REPLACE VIEW public.detailed_stat AS
 WITH st_stat AS (
         SELECT date_trunc('h'::text, site_task.dt) AS dt,
            count(*) AS added
           FROM site_task
          WHERE site_task.task_id = 5
          GROUP BY (date_trunc('h'::text, site_task.dt))
        )
 SELECT ls.dt,
    ls.processed,
    ls.extracted,
    ls.traffic,
    coalesce(st.added, 0) AS site_task_added,
    ls.added AS stat_added,
    ls.added - coalesce(st.added, 0) AS delta,
        CASE
            WHEN ls.processed > 0 THEN round(ls.added::numeric / ls.processed::numeric * 100.0, 2)
            ELSE 0::numeric
        END AS ece
   FROM last_stat ls
   LEFT JOIN st_stat st ON st.dt = ls.dt
  ORDER BY ls.dt DESC;
