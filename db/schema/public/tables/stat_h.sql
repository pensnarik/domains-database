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
