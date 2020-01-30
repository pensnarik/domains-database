create table contact.email (
    id serial,
    site_id integer not null,
    email text not null,
    create_date timestamp(0) without time zone default now()
);

alter table only contact.email
    add constraint email_site_id_fkey foreign key (site_id) references site(id);

alter table only contact.email
    add constraint email_pkey primary key (id);

create unique index email_site_id_email_idx on contact.email using btree (site_id, email);

create index email_email_vpo_idx on contact.email using btree (email varchar_pattern_ops);

