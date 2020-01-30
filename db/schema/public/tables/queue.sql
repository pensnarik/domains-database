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

grant delete on public.queue to dispatcher;
