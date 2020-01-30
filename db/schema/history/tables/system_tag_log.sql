create table history.system_tag_log (
    id serial,
    site_id integer not null,
    tag_id integer not null,
    action tag_action_mnemonic not null,
    task_id integer
);

alter table only history.system_tag_log
    add constraint system_tag_log_pkey primary key (id);
