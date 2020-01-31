create view encoding_stat as
select distinct lower(encoding),
       round((count(*) over (partition by lower(encoding)) / count(*) over()::numeric)*100, 2)
  from site
 where encoding is not null
 order by 2 desc limit 20;

create view last_stat as
select date_trunc('hour', finished_at) as dt,
       sum(sites_processed) as processed,
       sum(sites_extracted) as extracted,
       sum(sites_added) as added,
       pg_size_pretty(sum(traffic)) as traffic
  from stat
 where finished_at is not null
   and finished_at > now() - interval '10 hours'
   and finished_at < now()
 group by 1 order by 1 desc;

create view detailed_stat as
with st_stat as (
    select date_trunc('h', dt) dt,
           count(*) as added
      from site_task
    where task_id = 5 group by 1
)
select ls.dt,
       ls.processed,
       ls.extracted,
       ls.traffic,
       st.added as site_task_added,
       ls.added as stat_added,
       ls.added - st.added as delta,
       case when extracted > 0 then
         round(ls.added / extracted::numeric * 100.0, 2)
       else 0 end as ece
  from last_stat ls
  join st_stat st on st.dt = ls.dt
  order by 1 desc;
