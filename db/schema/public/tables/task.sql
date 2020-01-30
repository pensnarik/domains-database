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
