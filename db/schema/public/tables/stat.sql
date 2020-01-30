create table public.stat
(
    finished_at         timestamptz not null default now(),
    domain              varchar(255),
    session_id          integer not null,
    hostname            varchar(126) not null,
    fetch_result        site_fetch_result,
    traffic             integer not null default 0,
    time_get_item       numeric,
    time_resolve        numeric,
    time_fetch_page     numeric,
    time_parse          numeric,
    time_search_phones  numeric,
    time_search_emails  numeric,
    sites_processed     smallint not null default 0,
    sites_extracted     smallint not null default 0,
    sites_added         smallint not null default 0,
    emails_extracted    smallint not null default 0,
    emails_added        smallint not null default 0,
    phones_extracted    smallint not null default 0,
    phones_added        smallint not null default 0
);

create index stat_finished_at_idx on public.stat(finished_at);
create index stat_session_id_idx on public.stat(session_id);
