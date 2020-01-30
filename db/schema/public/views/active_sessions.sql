create or replace view public.active_sessions as
select s.id, count(*) as queued
  from session s
  left join queue q on q.session_id = s.id
where s.end_time is null
group by 1;

grant select on public.active_sessions to dispatcher;
