create table config.tag (
    id serial,
    tag_type tag_type_mnemonic not null,
    name text not null
);

alter table only config.tag
    add constraint tag_pkey primary key (id);

grant select on config.tag to datatrace;
