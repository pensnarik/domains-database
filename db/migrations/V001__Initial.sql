/* pgmigrate-encoding: utf-8 */

/* https://partner.r01.ru/zones/ru_domains.gz */

do $$
begin
    execute $sql$
      create user datatrace with password 'datatrace';
      create user dispatcher with password 'dispatcher';
    $sql$;
exception when duplicate_object then
    raise warning 'User crawler already exists';
end;
$$ language plpgsql;

create type public.tag_type_mnemonic as enum (
    'cms',
    'leadgen',
    'consultant',
    'webstat',
    'forum',
    'callback',
    'social',
    'hack',
    'calltracking',
    'tag_manager',
    'javascript'
);

create type public.tag_action_mnemonic as enum (
    'added',
    'removed'
);

create type public.operation_times_rec as (
  get_item numeric,
  resolve numeric,
  fetch_page numeric,
  parse numeric,
  search_phones numeric,
  search_emails numeric
);

create type public.task_status_mnemonic as enum (
    'new',
    'queued',
    'done',
    'error',
    'processing'
);

create type public.site_fetch_result as enum (
    'ok',
    'timeout',
    'connection_error',
    'too_many_redirects',
    'unknown_error',
    'too_large',
    'resolve_error',
    'unknown_encoding'
);

create SCHEMA history;

create table history.site__powered_by (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    powered_by text
);

create index site__powered_by_site_id_date_from_date_till_idx on history.site__powered_by using btree (site_id, date_from, date_till);

create table history.site__server (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    server text
);

create index site__server_site_id_date_from_date_till_idx on history.site__server using btree (site_id, date_from, date_till);

create table history.site__title (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    title text
);

create index site__title_site_id_date_from_date_till_idx on history.site__title using btree (site_id, date_from, date_till);

create table history.system_tag_log (
    id serial,
    site_id integer not null,
    tag_id integer not null,
    action tag_action_mnemonic not null,
    task_id integer
);

alter table only history.system_tag_log
    add constraint system_tag_log_pkey primary key (id);

create or replace
function i_site() returns trigger as $$
begin
  insert into public.site_task (site_id, task_id, domain)
  values (new.id, 5, new.domain);

  return new;
end;
$$ language plpgsql security definer;

create or replace
function u_site() returns trigger as $$
declare
  vdate_from timestamptz;
begin
  if old.title is distinct from new.title then
    update history.site__title set date_till = current_timestamp where site_id = new.id and date_till = 'infinity';
    if not found then
      vdate_from := '-infinity';
    else
      vdate_from := current_timestamp;
    end if;

    insert into history.site__title (site_id, date_from, date_till, title)
    values (new.id, vdate_from, 'infinity', new.title);

  end if;

  if old.server is distinct from new.server then
    update history.site__server set date_till = current_timestamp where site_id = new.id and date_till = 'infinity';
    if not found then
      vdate_from := '-infinity';
    else
      vdate_from := current_timestamp;
    end if;

    insert into history.site__server (site_id, date_from, date_till, server)
    values (new.id, vdate_from, 'infinity', new.server);

  end if;

  if old.powered_by is distinct from new.powered_by then
    update history.site__powered_by set date_till = current_timestamp where site_id = new.id and date_till = 'infinity';
    if not found then
      vdate_from := '-infinity';
    else
      vdate_from := current_timestamp;
    end if;

    insert into history.site__powered_by (site_id, date_from, date_till, powered_by)
    values (new.id, vdate_from, 'infinity', new.powered_by);

  end if;

  return new;
end;
$$ language plpgsql security definer;

create or replace
function public.u_site_system_tags() returns trigger as $$
begin
  -- TODO Replace 59 with variable or alias
  if 59 = any(new.system_tags) and (old.system_tags is null or (not (59 = any(old.system_tags)))) then
    /* Если для сайта найдены потенциально уязвимые ссылки - добавляем в задачу
       на проверку SQL Injection */
    insert into public.site_task (site_id, task_id, domain, job)
    select new.id, 100, new.domain, 'CheckSQLInjection'
    where not exists (select * from public.site_task where site_id = new.id and task_id = 100);
  end if;

  if old.last_fetch_result = 'ok' and new.last_fetch_result = 'ok' then
    perform public.on_system_tags_changed(new.id, new.last_task_id, coalesce(old.system_tags, '{}'::int[]) , coalesce(new.system_tags, '{}'::int[]));
  end if;
  return new;
end;
$$ language plpgsql security definer;

create or replace
function public.on_system_tags_changed(
  asite_id         bigint,
  atask_id         integer,
  aold_system_tags integer[],
  anew_system_tags integer[]
) returns void as $$
begin
  insert into history.system_tag_log (site_id, tag_id, action, task_id)
  select asite_id,
         e.tag_id,
         case when a1.i is null then 'added'::tag_action_mnemonic else 'removed'::tag_action_mnemonic end,
         atask_id
    from (select unnest(aold_system_tags) i) a1
    full outer join (select unnest(anew_system_tags) i) a2 on a1.i = a2.i
    join config.expression e on e.id = coalesce(a1.i, a2.i)
   where a1.i is null or a2.i is null;
end;
$$ language plpgsql security definer;

comment on function public.on_system_tags_changed(asite_id bigint, atask_id integer, aold_system_tags integer[], anew_system_tags integer[]) is 'Вызывается при изменении найденных тэгов';

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

create schema contact;

grant usage on schema contact to datatrace;

create table contact.email
(
  id      serial,
  site_id integer not null,
  email   text not null
);

alter table only contact.email
    add constraint email_pkey primary key (id);

create unique index email_site_id_email_idx on contact.email using btree (site_id, email);

create index email_email_vpo_idx on contact.email using btree (email varchar_pattern_ops);


create table contact.phone (
    id serial,
    site_id integer not null,
    phone text not null,
    create_date timestamptz default now(),
    domain varchar(126) not null,
    constraint phone_phone_check CHECK ((phone ~ '^\d+$'::text))
);

alter table only contact.phone
    add constraint phone_pkey primary key (id);

create unique index phone_site_id_phone_idx on contact.phone using btree (site_id, phone);

create index phone_phone_vpo_idx on contact.phone using btree (phone varchar_pattern_ops);

create index phone_phone_idx on contact.phone using btree (phone);

create or replace
function contact.add_contacts
(
    asite_id integer,
    aemails text[],
    aphones text[],
    adomain varchar default null,
    oemails out integer,
    ophones out integer
) as $$
begin
    select coalesce(sum(contact.add_email(asite_id, email)), 0) into oemails from unnest(aemails) email;
    select coalesce(sum(contact.add_phone(asite_id, phone, adomain)), 0) into ophones from unnest(aphones) phone;
end;
$$ language plpgsql;

comment on function contact.add_contacts(integer, text[], text[], varchar, out integer, out integer)
    is 'Добавляет email и телефоны, возвращает количество добаленных записей';

create or replace
function contact.add_email(
  asite_id integer,
  aemail   text
) returns integer as $$
begin
  if not exists (select * from contact.email where site_id = asite_id and email = aemail) then
    insert into contact.email (site_id, email) values (asite_id, aemail);
    return 1;
  else
    return 0;
  end if;
end;
$$ language plpgsql security definer;

comment on function contact.add_email(integer, text) is 'Добавляет email, возвращает количество (0 или 1)';

create or replace
function contact.add_phone(
  asite_id integer,
  aphone   text,
  adomain  varchar default null
) returns integer as $$
begin
  if not exists (select * from contact.phone where site_id = asite_id and phone = aphone) then
    insert into contact.phone (site_id, phone, domain) values (asite_id, aphone, adomain);
    return 1;
  else
    return 0;
  end if;
end;
$$ language plpgsql security definer;

comment on function contact.add_phone(integer, text, varchar) is 'Добавляет телефон, возвращает количество (0 или 1)';

create table public.task (
    id            serial,
    start_time    timestamptz default now(),
    end_time      timestamptz,
    priority      integer default 0 not null,
    is_active     boolean default true not null,
    description   text
);

alter table only public.task
    add constraint task_pkey primary key (id);

insert into public.task(id, description) values (5, 'New sites');
insert into public.task(id, description) values (100, 'JobCheckSQLInjection');

create table public.site_task
(
  id          serial,
  task_id     integer not null references task(id),
  site_id     integer not null,
  session_id  integer,
  domain      varchar(255),
  job         varchar(126),
  created     timestamptz default now(),
  dispatched  timestamptz
);

alter table only site_task
    add constraint site_task_pkey primary key (id);

create unique index on site_task (task_id, site_id);

create table public.session
(
    id          serial,
    ip          inet,
    version     text,
    info        text,
    hostname    varchar(255),
    instance    text,
    pid         integer,
    backend_pid integer,
    start_time  timestamptz not null default current_timestamp,
    end_time    timestamptz,
    term_signal integer,
    sites_processed integer default 0,
    jobs_dispatched integer default 0,
    last_activity timestamptz
);

alter table only session
    add constraint session_pkey primary key (id);

create index session_last_activity_idx on session using btree (last_activity);

comment on column session.backend_pid is
  'Process ID obtained by pg_backend_pid()';

grant select, update on public.session to dispatcher;

create schema core;

create schema config;

grant usage on schema config to datatrace;

create table config.tag (
    id serial,
    tag_type tag_type_mnemonic not null,
    name text not null
);

alter table only config.tag
    add constraint tag_pkey primary key (id);

grant select on config.tag to datatrace;

create table config.tag_meta (
    id serial,
    tag_id integer not null,
    name character varying(255)
);

alter table only config.tag_meta
    add constraint tag_meta_tag_id_fkey foreign key (tag_id) references config.tag(id);

alter table only config.tag_meta
    add constraint tag_meta_pkey primary key (id);

grant select on table config.tag_meta to datatrace;

create table config.tag_meta_expression (
    id serial,
    meta_id integer not null,
    expression text
);

alter table only config.tag_meta_expression
    add constraint tag_meta_expression_meta_id_fkey foreign key (meta_id) references config.tag_meta(id);

alter table only config.tag_meta_expression
    add constraint tag_meta_expression_pkey primary key (id);

grant select on config.tag_meta_expression to datatrace;

create table public.tag_meta_value (
    id serial,
    task_id integer,
    site_id integer not null,
    tag_meta_id integer not null,
    value text
);

alter table only public.tag_meta_value
    add constraint tag_meta_value_task_id_fkey foreign key (task_id) references public.task(id);

alter table only public.tag_meta_value
    add constraint tag_meta_value_tag_meta_id_fkey foreign key (tag_meta_id) references config.tag_meta(id);

alter table only public.tag_meta_value
    add constraint tag_meta_value_pkey primary key (id);

create unique index tag_meta_value_task_id_site_id_tag_meta_id_idx on public.tag_meta_value using btree (task_id, site_id, tag_meta_id);

create index tag_meta_value_task_id_idx on public.tag_meta_value using btree (task_id);

create index tag_meta_value_site_id_idx on public.tag_meta_value using btree (site_id);

create table config.expression (
    id serial,
    tag_id integer not null,
    is_active boolean default true not null,
    is_multiline boolean default false not null,
    code text not null,
    is_ignorecase boolean default false not null
);

alter table only config.expression
    add constraint expression_tag_id_fkey foreign key (tag_id) references config.tag(id);

alter table only config.expression
    add constraint expression_pkey primary key (id);

grant select on config.expression to datatrace;

create table public.queue
(
    id                  serial primary key,
    site_id             integer not null,
    session_id          integer not null,
    task_id             integer not null,
    domain              varchar(255) not null,
    job                 varchar(126),
    status              task_status_mnemonic default 'new' not null
);

create unique index queue_uniq_idx on public.queue(site_id, task_id);
create index queue_session_idx on public.queue(session_id);

grant select, delete on public.queue to dispatcher;

create or replace view public.active_sessions as
select s.id, count(*) as queued
  from session s
  left join queue q on q.session_id = s.id
where s.end_time is null
group by 1;

grant select on public.active_sessions to dispatcher;

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
) partition by range (finished_at);

create or replace
function public.save_stat
(
    adomain              varchar,
    asession_id          integer,
    ahostname            varchar,
    afetch_result        site_fetch_result,
    atraffic             integer,
    atime_get_item       numeric,
    atime_resolve        numeric,
    atime_fetch_page     numeric,
    atime_parse          numeric,
    atime_search_phones  numeric,
    atime_search_emails  numeric,
    asites_processed     smallint,
    asites_extracted     smallint,
    asites_added         smallint,
    aemails_extracted    smallint,
    aemails_added        smallint,
    aphones_extracted    smallint,
    aphones_added        smallint
) returns void as $$
begin
    insert into public.stat (domain, session_id, hostname, fetch_result, traffic, time_get_item, time_resolve,
        time_fetch_page, time_parse, time_search_phones, time_search_emails, sites_processed,
        sites_extracted, sites_added, emails_extracted, emails_added, phones_extracted,
        phones_added)
    values (adomain, asession_id, ahostname, afetch_result, atraffic, atime_get_item, atime_resolve,
        atime_fetch_page, atime_parse, atime_search_phones, atime_search_emails, asites_processed,
        asites_extracted, asites_added, aemails_extracted, aemails_added, aphones_extracted,
        aphones_added);
end;
$$ language plpgsql
   security definer;

create schema log;

grant usage on schema log to datatrace;

create table log.slow_expression
(
    id                  bigserial primary key,
    expression_source   varchar(126) not null,
    expression_id       integer not null,
    site_id             bigint not null,
    site_task_id        bigint not null,
    search_time         numeric not null check (search_time > 0),
    dt                  timestamptz not null default current_timestamp
);

grant select, insert on log.slow_expression to datatrace;
grant usage, update on sequence log.slow_expression_id_seq to datatrace;

create table log.error (
    session_id integer not null,
    site_id integer not null,
    message text,
    date_time timestamptz default clock_timestamp()
);

create index error_site_id_idx on log.error using btree (site_id);

grant select, insert on log.error to datatrace;

create table log.vulns (
    id serial,
    site_id integer not null,
    date_time timestamp(0) without time zone default now() not null,
    url text
);

alter table only log.vulns
    add constraint vulns_pkey primary key (id);

grant select, insert on log.vulns to datatrace;
grant usage, update on sequence log.vulns_id_seq to datatrace;
