create table history.site__server (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    server text
);

create index site__server_site_id_date_from_date_till_idx on history.site__server using btree (site_id, date_from, date_till);
