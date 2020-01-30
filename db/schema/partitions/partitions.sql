create function public.create_site_partition(partition text) returns text as $$
declare
  sql text;
begin
  sql := format
  (
    $sql$
      create table public.site__%1$s partition of public.site
      (
        primary key (id)
      ) for values in ('%1$s');

      create trigger i_site__%1$s after insert on site__%1$s for each row execute procedure i_site();

      create trigger u_site__%1$s after update of title, server, powered_by on site__%1$s for each row execute procedure u_site();

      create trigger u_site__%1$s_system_tags after update of system_tags on site__%1$s for each row execute procedure u_site_system_tags();

      create index site__%1$s_last_check_time_idx on site__%1$s using btree (last_check_time);

      create index site__%1$s_create_date_idx on site__%1$s using btree (create_date);

      create index site__%1$s_system_tags_gin_idx on site__%1$s using gin (system_tags);

      create unique index site__%1$s_domain_vpo_idx on site__%1$s using btree (domain varchar_pattern_ops);
    $sql$,
    partition
  );
  EXECUTE sql;
  RETURN 'public.site__' || partition;
end;
$$ language plpgsql;

select public.create_site_partition(lpad(to_hex(i), 2, '0'))
  from generate_series(0, 255) i;