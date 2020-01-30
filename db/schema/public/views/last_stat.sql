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
