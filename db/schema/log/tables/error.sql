create table log.error (
    session_id integer not null,
    site_id integer not null,
    message text,
    date_time timestamptz default clock_timestamp()
);

create index error_site_id_idx on log.error using btree (site_id);

grant select, insert on log.error to datatrace;
