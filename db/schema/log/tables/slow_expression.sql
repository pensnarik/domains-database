create table log.slow_expression
(
    id                  bigserial primary key,
    expression_source   varchar(126) not null,
    expression_id       integer not null,
    site_id             bigint not null,
    site_task_id        bigint not null,
    search_time         numeric not null check (search_time > 0),
    dt                  timestamptz not null default current_timestamp
);

grant select, insert on log.slow_expression to datatrace;
