create table log.journal
(
    dt_clock      timestamptz not null default clock_timestamp(),
    dt_trans      timestamptz not null default current_timestamp(),
    site_id       bigint,
    domain        text,
    event         text
);