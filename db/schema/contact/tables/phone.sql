create table contact.phone (
    id serial,
    site_id integer not null,
    phone text not null,
    create_date timestamp(0) without time zone default now(),
    domain varchar(126) not null,
    constraint phone_phone_check CHECK ((phone ~ '^\d+$'::text))
);

alter table only contact.phone
    add constraint phone_pkey primary key (id);

create unique index phone_site_id_phone_idx on contact.phone using btree (site_id, phone);

create index phone_phone_vpo_idx on contact.phone using btree (phone varchar_pattern_ops);

create index phone_phone_idx on contact.phone using btree (phone);
