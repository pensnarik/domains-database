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
