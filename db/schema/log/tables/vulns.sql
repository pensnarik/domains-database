create table log.vulns (
    id serial,
    site_id integer not null,
    date_time timestamp(0) without time zone default now() not null,
    url text
);

alter table only log.vulns
    add constraint vulns_pkey primary key (id);

grant select, insert on log.vulns to datatrace;
grant usage, update on sequence log.vulns_id_seq to datatrace;
