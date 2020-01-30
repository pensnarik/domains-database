create table public.site (
    id                  bigserial not null,
    domain              character varying(255) not null,
    encoding            varchar(20),
    size                integer,
    response_code       smallint,
    title               varchar(500),
    server              varchar(300),
    powered_by          varchar(126),
    last_check_time     timestamptz,
    addr                inet[],
    last_fetch_result   site_fetch_result,
    system_tags         integer[],
    reference_count     integer,
    create_date         timestamptz default now() not null,
    last_task_id        integer,
    success_count       smallint default 0,
    error_count         smallint default 0,
    constraint site_domain_check CHECK (((domain)::text ~ '([a-z0-9-]+){1,3}\.[a-z]{2,}'::text))
) partition by list (left(md5(domain), 2));

grant select, update on site to datatrace;
