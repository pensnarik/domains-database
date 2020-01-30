create schema partitions;

grant usage on schema partitions to datatrace;

create function partitions.create_site_partition(partition text) returns text as $$
declare
  sql text;
begin
  sql := format
  (
    $sql$
      create table partitions.site__%1$s partition of public.site
      (
        primary key (id)
      ) for values in ('%1$s');

      create trigger i_site__%1$s
        after insert on partitions.site__%1$s
        for each row execute procedure i_site();

      create trigger u_site__%1$s
        after update of title, server, powered_by on partitions.site__%1$s
        for each row execute procedure u_site();

      create trigger u_site__%1$s_system_tags
        after update of system_tags on partitions.site__%1$s
        for each row execute procedure u_site_system_tags();

      create index site__%1$s_last_check_time_idx
        on partitions.site__%1$s using btree (last_check_time);

      create index site__%1$s_create_date_idx
        on partitions.site__%1$s using btree (create_date);

      create index site__%1$s_system_tags_gin_idx
        on partitions.site__%1$s using gin (system_tags);

      create unique index site__%1$s_domain_vpo_idx
        on partitions.site__%1$s using btree (domain varchar_pattern_ops);
    $sql$,
    partition
  );
  EXECUTE sql;
  RETURN 'partitions.site__' || partition;
end;
$$ language plpgsql;

create function partitions.create_stat_partition(partition date) returns text as $$
declare
    sql text;
begin
    sql := format($sql$
        create table partitions.stat__%1$s partition of public.stat
        for values from ('%2$s') to ('%3$s');

        create index stat__%1$s_finished_at on partitions.stat__%1$s (finished_at);
    $sql$,
    to_char(partition, 'YYYY_MM_DD'),
    to_char(partition, 'YYYY-MM-DD 00:00:00+00'),
    to_char(partition + interval '1 day', 'YYYY-MM-DD 00:00:00+00')
    );
    EXECUTE sql;
    RETURN 'partitions.stat__' || to_char(partition, 'YYYY_MM_DD');
end;
$$ language plpgsql;

select partitions.create_site_partition(lpad(to_hex(i), 2, '0'))
  from generate_series(0, 255) i;

select partitions.create_stat_partition(d::date)
  from generate_series(current_date::date, current_date + interval '1 year', interval '1 day') d;
