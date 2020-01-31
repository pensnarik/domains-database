/* pgmigrate-encoding: utf-8 */

create SCHEMA report;

grant usage on schema report to datatrace;

create or replace
function report.stat
(
    adate_from timestamptz,
    adate_till timestamptz,
    ahostname  varchar default null,
    ainterval char default 'm'
) returns table
(
    date_time         timestamptz,
    date_time_ux      bigint,
    parsed_sites      integer,
    new_sites         integer,
    new_emails        integer,
    new_phones        integer,
    avg_get_item      numeric,
    avg_resolve       numeric,
    avg_fetch_page    numeric,
    avg_parse         numeric,
    avg_search_phones numeric,
    avg_search_emails numeric,
    avg_total         numeric,
    sessions          integer,
    traffic           bigint
) as $$
declare
  vtable text; vsql text; vmin_date timestamptz;
begin
    adate_from := date_trunc(ainterval, adate_from);
    adate_till := date_trunc(ainterval, adate_till);
    select min(start_time) from public.session into vmin_date;

    vsql := $sql$
    with last_updated as (select coalesce(max(finished_at), $1)::timestamp as dt_last from public.stat_{interval})

    select public.update_stat(t::timestamp, '{interval}')
      from generate_series((select dt_last from last_updated), $2, interval '1 {interval}') t
    $sql$;

    vsql := replace(vsql, '{interval}', ainterval);

    raise notice '%', vsql;

    execute vsql using vmin_date, adate_till;

    vsql := $sql$
    with sessions as (
      select t.finished_at,
             t.hostname,
             max(t.sessions) as sessions
        from public.stat_{interval} t
       where t.finished_at >= $2 and t.finished_at < $3
         and (t.hostname = $1 or $1 is null)
       group by 1, 2
    ), statistics as (
      select *, row_number() over (partition by t.finished_at, t.hostname order by t.finished_at, t.hostname, t.fetch_result) as rn
        from public.stat_{interval} t
       where t.finished_at >= $2 and t.finished_at < $3
         and (t.hostname = $1 or $1 is null)
    )
    select t.d,
           extract('epoch' from t.d)::bigint * 1000,
           coalesce(sum(st.sites_processed), 0)::integer as parsed_sites,
           coalesce(sum(st.sites_added), 0)::integer as new_sites,
           coalesce(sum(st.emails_added), 0)::integer as new_emails,
           coalesce(sum(st.phones_added), 0)::integer as new_phones,
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_get_item else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_resolve else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_fetch_page else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_parse else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_search_phones else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_search_emails else null end), 3), 0),
           coalesce(round(avg(case when st.fetch_result = 'ok' then time_get_item + time_resolve + time_fetch_page + time_parse +
                    time_search_phones + time_search_emails else null end), 3), 0),
           coalesce(case when $1 is null then sum(case when rn = 1 then s.sessions else 0 end)::integer else max(s.sessions) end, 0)::integer,
           coalesce(sum(st.traffic), 0)::bigint
      from (select generate_series($2, $3, interval '1 {interval}') d) t
      left join statistics st
        on t.d = st.finished_at
       and (st.hostname = $1 or $1 is null)
      left join sessions s
        on t.d = s.finished_at
       and s.hostname = st.hostname
     where t.d >= $2 and t.d < $3
     group by 1, 2
     order by 1 desc;
     $sql$;

     vsql := replace(vsql, '{interval}', ainterval);

     return query execute vsql using ahostname, adate_from, adate_till;
end;
$$ language plpgsql;


create or replace
function report.hosts_stat
(
    adate_from timestamptz,
    adate_till timestamptz,
    ainterval char default 'm'
) returns table
(
    date_time timestamptz,
    date_time_ux bigint,
    host varchar,
    parsed_sites integer,
    avg_total numeric
) as $$
declare
  vtable text; vsql text;
begin
    adate_from := date_trunc(ainterval, adate_from);
    adate_till := date_trunc(ainterval, adate_till);

    vsql := $sql$
    with hosts as (
      select distinct hostname
        from public.stat_{interval} st
       where st.finished_at >= $1 and st.finished_at <= $2
    )
    select d.t,
           extract('epoch' from d.t)::bigint * 1000,
           d.hostname,
           coalesce(sum(st.sites_processed), 0)::integer as parsed_sites,
           coalesce(round(avg(time_get_item + time_resolve + time_fetch_page + time_parse +
              time_search_phones + time_search_emails), 2), 0)
      from (select t, hostname from generate_series($1, $2, interval '1 {interval}') t join hosts on true) d
      left join public.stat_{interval} st
        on st.finished_at = d.t
       and st.hostname = d.hostname
     where d.t >= $1 and d.t <= $2
     group by 1, 2, 3
     order by 1 desc;
     $sql$;

     vsql := replace(vsql, '{interval}', ainterval);

     return query execute vsql using adate_from, adate_till;
end;
$$ language plpgsql;

CREATE OR REPLACE
FUNCTION report.status_log
(
  adate_from timestamptz,
  adate_till timestamptz,
  ahostname character varying DEFAULT NULL::character varying,
  ainterval character DEFAULT 'm'::bpchar
) RETURNS TABLE
(
  date_time timestamptz,
  date_time_ux bigint,
  num_ok bigint,
  num_timeout bigint,
  num_connection_error bigint,
  num_too_many_redirects bigint,
  num_unknown_error bigint,
  num_too_large bigint,
  num_resolve_error bigint
)
AS $$
declare
  vtable text; vsql text;
begin
    adate_from := date_trunc(ainterval, adate_from);
    adate_till := date_trunc(ainterval, adate_till);

    vsql := $sql$
    select t.d,
           extract('epoch' from t.d)::bigint * 1000,
           coalesce(sum(case when fetch_result = 'ok'                 then st.sites_processed else 0 end), 0) as num_ok,
           coalesce(sum(case when fetch_result = 'timeout'            then st.sites_processed else 0 end), 0) as num_timeout,
           coalesce(sum(case when fetch_result = 'connection_error'   then st.sites_processed else 0 end), 0) as num_connection_error,
           coalesce(sum(case when fetch_result = 'too_many_redirects' then st.sites_processed else 0 end), 0) as num_too_many_redirects,
           coalesce(sum(case when fetch_result = 'unknown_error'      then st.sites_processed else 0 end), 0) as num_unknown_error,
           coalesce(sum(case when fetch_result = 'too_large'          then st.sites_processed else 0 end), 0) as num_too_large,
           coalesce(sum(case when fetch_result = 'resolve_error'      then st.sites_processed else 0 end), 0) as num_resolve_error
      from (select generate_series($2, $3, interval '1 {interval}') d) t
      left join public.stat_{interval} st
        on t.d = st.finished_at
       and (st.hostname = $1 or $1 is null)
     where t.d >= $2 and t.d <= $3
     group by 1, 2
     order by 1 desc;
     $sql$;

     vsql := replace(vsql, '{interval}', ainterval);

     return query execute vsql using ahostname, adate_from, adate_till;
end;
$$ LANGUAGE plpgsql;

create table public.stat_m
(
    finished_at         timestamptz not null,
    hostname            varchar(126) not null,
    sessions            smallint not null default 0,
    fetch_result        site_fetch_result,
    traffic             bigint not null default 0,
    time_get_item       numeric(10,3),
    time_resolve        numeric(10,3),
    time_fetch_page     numeric(10,3),
    time_parse          numeric(10,3),
    time_search_phones  numeric(10,3),
    time_search_emails   numeric(10,3),
    sites_processed     integer not null default 0,
    sites_extracted     integer not null default 0,
    sites_added         integer not null default 0,
    emails_extracted    integer not null default 0,
    emails_added        integer not null default 0,
    phones_extracted    integer not null default 0,
    phones_added        integer not null default 0
);

create unique index on public.stat_m (finished_at, hostname, fetch_result);

create table public.stat_h
(
    finished_at         timestamptz not null,
    hostname            varchar(126) not null,
    sessions            smallint not null default 0,
    fetch_result        site_fetch_result,
    traffic             bigint not null default 0,
    time_get_item       numeric(10,3),
    time_resolve        numeric(10,3),
    time_fetch_page     numeric(10,3),
    time_parse          numeric(10,3),
    time_search_phones  numeric(10,3),
    time_search_emails  numeric(10,3),
    sites_processed     integer not null default 0,
    sites_extracted     integer not null default 0,
    sites_added         integer not null default 0,
    emails_extracted    integer not null default 0,
    emails_added        integer not null default 0,
    phones_extracted    integer not null default 0,
    phones_added        integer not null default 0
);

create unique index on public.stat_h (finished_at, hostname, fetch_result);

create table public.stat_d
(
    finished_at         timestamptz not null,
    hostname            varchar(126) not null,
    sessions            smallint not null default 0,
    fetch_result        site_fetch_result,
    traffic             bigint not null default 0,
    time_get_item       numeric(10,3),
    time_resolve        numeric(10,3),
    time_fetch_page     numeric(10,3),
    time_parse          numeric(10,3),
    time_search_phones  numeric(10,3),
    time_search_emails  numeric(10,3),
    sites_processed     integer not null default 0,
    sites_extracted     integer not null default 0,
    sites_added         integer not null default 0,
    emails_extracted    integer not null default 0,
    emails_added        integer not null default 0,
    phones_extracted    integer not null default 0,
    phones_added        integer not null default 0
);

create unique index on public.stat_d (finished_at, hostname, fetch_result);

create or replace
function public.update_stat(afinished_at timestamp, ainterval char) returns integer as $$
declare
    vresult integer; sql text;
    vtable text; vsql_delete text;
begin
    if afinished_at < '2018-01-01 00:00:00' then
        return 0;
    end if;

    raise warning 'update_stat(%, %)', afinished_at, ainterval;

    vsql_delete := $sql$delete from public.stat_{interval} where finished_at = date_trunc('{interval}', $1)$sql$;
    vsql_delete := replace(vsql_delete, '{interval}', ainterval);

    execute vsql_delete using afinished_at;

    sql := $sql$
    with hosts as (
      select hostname, count(distinct session_id) as sessions
        from public.stat
       where finished_at >= date_trunc('{interval}', $1)
         and finished_at < date_trunc('{interval}', $1) + interval '1 {interval}'
       group by 1
    ), cnt as (
    insert into public.stat_{interval} (finished_at, hostname, fetch_result, sessions, traffic, time_get_item, time_resolve,
        time_fetch_page, time_parse, time_search_phones, time_search_emails, sites_processed,
        sites_extracted, sites_added, emails_extracted, emails_added, phones_extracted,
        phones_added)
    select date_trunc('{interval}', finished_at), st.hostname, fetch_result, h.sessions, sum(traffic), avg(time_get_item), avg(time_resolve),
        avg(time_fetch_page), avg(time_parse), avg(time_search_phones), avg(time_search_emails), sum(sites_processed),
        sum(sites_extracted), sum(sites_added), sum(emails_extracted), sum(emails_added), sum(phones_extracted),
        sum(phones_added)
    from public.stat st
    join hosts h on h.hostname = st.hostname
    where finished_at >= date_trunc('{interval}', $1) and finished_at < date_trunc('{interval}', $1) + interval '1 {interval}'
    group by 1, 2, 3, 4
    returning *
    ) select count(*) from cnt;
    $sql$;

    sql := replace(sql, '{interval}', ainterval);

    execute sql into vresult using afinished_at;

    return vresult;
end;
$$ language plpgsql;

create or replace
function public.search
(
    adomain      varchar,
    aaddr        inet default null,
    aphone       varchar default null,
    alast_domain varchar default null
) returns table
(
    id                bigint,
    domain            varchar,
    encoding          varchar,
    response_code     smallint,
    title             varchar,
    server            varchar,
    powered_by        varchar,
    last_check_time   timestamptz,
    addr              inet[],
    last_fetch_result site_fetch_result,
    system_tags       integer[],
    system_tags_str   varchar,
    create_date       timestamptz
) as $$
declare
    vsql text;
begin
    if (adomain is null and aaddr is null and aphone is null) or
       (adomain is not null and length(adomain) < 3) then
       raise warning 'Invalid arguments';
       return;
    end if;

    vsql := $sql$
    with phones as
    (
      select distinct ph.domain
        from contact.phone ph
       where ph.phone like $3 || '%'
         and $3 is not null
    ), data as (
      select s.id, s.domain, s.encoding, s.response_code, s.title,
             s.server, s.powered_by, s.last_check_time, s.addr,
             s.last_fetch_result, s.system_tags, config.tags_as_str(s.system_tags),
             s.create_date
        from site s
       where (s.domain like $1 || '%' or $1 is null)
         and (s.domain in (select domain from phones) or $3 is null)
         and (array[$2] <@ s.addr or $2 is null)
         and (s.domain > $4 or $4 is null)
    ) select * from data order by domain limit 100;
    $sql$;

    return query
      execute vsql using adomain, aaddr, aphone, alast_domain;
end;
$$ language plpgsql set enable_seqscan = 'off';

create or replace
function config.tags_as_str(atags integer[]) returns varchar as $$
    select string_agg(name, ', ')
      from config.expression e
      join config.tag t
        on t.id = e.tag_id
     where e.id = any(atags);
$$ language sql immutable;
