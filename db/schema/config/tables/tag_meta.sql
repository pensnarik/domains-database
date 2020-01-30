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
