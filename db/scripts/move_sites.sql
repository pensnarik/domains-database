with deleted as (delete from site_old where id in (select id from site_old limit 1000000) returning *)
insert into site(id, domain, encoding, size, response_code, title, server, powered_by, last_check_time, addr, last_fetch_result,
    system_tags, reference_count, create_date, last_task_id, success_count, error_count, from_site_task_id)
select t.id, t.domain, t.encoding, t.size, t.response_code, substring(t.title, 1, 500), substring(t.server, 1, 300),
       substring(t.powered_by, 1, 126), t.last_check_time, t.addr, t.last_fetch_result, t.system_tags, t.reference_count,
       t.create_date, t.last_task_id, t.success_count, t.error_count, t.from_site_task_id
from deleted t;



create function move_sites(acount integer) returns integer as $$
declare
    v integer;
begin
    with deleted as (delete from site_temp where domain in (select domain from site_temp limit 100000) returning domain),
    inserted as (select add_domain(t.domain) from deleted t)
    select sum("add_domain") into v from inserted;
    return v;
end;
$$ language plpgsql;


select domain
  from site_temp
except
select domain
  from site
