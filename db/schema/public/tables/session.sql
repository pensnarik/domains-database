create table public.session
(
    id          serial primary key,
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
    last_activity timestamptz
);

alter table only session
    add constraint session_pkey primary key (id);

create index session_last_activity_idx on session using btree (last_activity);

comment on column session.backend_pid is 'Идентификатор серверного процесса, обслуживающего сессию, полученный с помощью pg_backend_pid()';

grant select, update on public.session to dispatcher;
