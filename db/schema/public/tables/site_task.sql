create table public.site_task
(
  id          serial,
  task_id     integer not null references task(id),
  site_id     integer not null,
  domain      varchar(255),
  job         varchar(126),
  dt          timestamptz default now()
);

alter table only site_task
    add constraint site_task_pkey primary key (id);

create unique index on site_task (task_id, site_id);
