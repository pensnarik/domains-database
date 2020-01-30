create or replace
function public.get_less_scale(ascale varchar) returns varchar as $$
    select case when ascale = 'year' then 'month'
                when ascale = 'month' then 'day'
                when ascale = 'day' then 'hour'
                when ascale = 'hour' then 'minute'
                when ascale = 'minute' then 'log'
           else
                '?'
           end;
$$ language sql immutable;
