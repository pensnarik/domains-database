create or replace view current_sessions as
    select *, ((sites_processed / extract('epoch' from now() - start_time))::numeric * 60.0)::int as speed
from session
where end_time is null
order by hostname, instance::int;
