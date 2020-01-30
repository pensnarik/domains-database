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
