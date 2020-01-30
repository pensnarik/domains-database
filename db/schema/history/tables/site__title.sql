create table history.site__title (
    site_id integer not null,
    date_from timestamptz not null,
    date_till timestamptz not null,
    title text
);

create index site__title_site_id_date_from_date_till_idx on history.site__title using btree (site_id, date_from, date_till);
