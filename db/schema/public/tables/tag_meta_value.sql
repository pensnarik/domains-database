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
