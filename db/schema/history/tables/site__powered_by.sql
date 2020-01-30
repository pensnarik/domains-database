create table history.site__powered_by (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    powered_by text
);

create index site__powered_by_site_id_date_from_date_till_idx on history.site__powered_by using btree (site_id, date_from, date_till);
