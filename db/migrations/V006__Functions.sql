create or replace
function public.update_activity
(
    asession_id integer,
    asites_processed_delta integer
) returns void as $$
begin
    update public.session
       set sites_processed = sites_processed + asites_processed_delta,
           last_activity = now()
     where id = asession_id;
end;
$$ language plpgsql
   security definer;

comment on function public.update_activity(integer, integer)
    is 'Increases sites_processed for the given session by asites_processed_delta';

create or replace
function public.delete_task_from_queue
(
    aid integer,
    asession_id integer
) returns void as $$
begin
    delete
      from public.queue
     where id = aid
       and session_id = asession_id;

    update public.session
       set jobs_dispatched = jobs_dispatched - 1
     where id = asession_id;
end;
$$ language plpgsql
   security definer;

comment on function public.delete_task_from_queue(integer, integer)
    is 'Removes task from queue, executed at the end of the task by datarace client';

create or replace
function public.dispatch_to_session
(
    asession_id integer,
    acount      integer
) returns integer as $$
declare
    vresult integer := 0;
begin
    with records as (
      select st.*
        from public.site_task st
       where dispatched is null
         and not exists (select * from public.task where id = st.task_id and not is_active)
       limit acount
    ),
    updated as (
      update public.site_task
         set dispatched = now(),
             session_id = asession_id
       where id in (select id from records)
      returning id
    ),
    result as (
      insert into public.queue (session_id, site_id, task_id, domain, job)
    select asession_id, st.site_id, st.task_id, st.domain, st.job
      from records st
      returning 1 as r
    )
    select sum(r) into vresult from result;

    update public.session set jobs_dispatched = jobs_dispatched + vresult
     where id = asession_id
       and vresult > 0;

    return vresult;
end;
$$ language plpgsql
   security definer;

comment on function public.dispatch_to_session(integer, integer)
  is 'Dispatches acount of tasks from site_task to the given session. Called by datatrace-dispatcher';

create or replace
function public.revoke_tasks_from_session(
    asession_id integer
) returns integer as $$
declare
    vresult integer;
begin
    with deleted as (
      delete
        from public.queue q
       where q.session_id = asession_id
      returning task_id
    )
    update public.site_task t
       set dispatched = null,
           session_id = null
      from deleted d
     where t.id = d.task_id;

     get diagnostics vresult := row_count;

     update public.session set jobs_dispatched = 0 where id = asession_id;

     return vresult;
end;
$$ language plpgsql;

create or replace
function public.dispatch(ajobs_count integer) returns integer as $$
declare
    vsession_id integer;
    vjobs_count integer := 0;
    vtotal_jobs_count integer := 0;
begin
    -- Revoke jobs from dead sessions
    perform public.revoke_tasks_from_session(id)
       from public.session
      where end_time is not null
        and jobs_dispatched > 0;

     -- Dispath tasks among active sessions
    for vsession_id in (
        select id
          from public.session
         where end_time is null
           and jobs_dispatched < ajobs_count * 2 -- to keep the queue small enough
    )
    loop
        vjobs_count := public.dispatch_to_session(vsession_id, ajobs_count);
        vtotal_jobs_count := vtotal_jobs_count + vjobs_count;

        if vjobs_count < ajobs_count then
            exit;
        end if;
    end loop;

    return vtotal_jobs_count;
end;
$$ language plpgsql;

create or replace
function init_session(
  ainfo     text,
  aversion  varchar,
  ahostname text default null::text,
  ainstance text default null::text,
  apid      integer default 0
) returns integer as $$
declare
  vid integer;
begin
  insert into session (ip, info, version, hostname, instance, pid, backend_pid)
  values (inet_client_addr(), ainfo, aversion, ahostname, ainstance, apid, pg_backend_pid())
  returning id into vid;

  return vid;
end;
$$ language plpgsql security definer;

comment on function public.init_session(text, varchar, text, text, integer)
  is 'Session initialization';

create or replace
function public.end_session
(
    aid integer,
    asignal integer default null::integer
) returns void as $$
begin
  perform public.revoke_tasks_from_session(aid);

  update session
     set end_time = current_timestamp,
         term_signal = asignal
   where id = aid;
end;
$$ language plpgsql security definer;

create or replace
function public.add_domain(
  adomain                text,
  askip_reference_update boolean default true
) returns integer as $$
declare
  vcount integer := 0;
  vpartition text := left(md5((adomain)::text), 2);
  vexists integer;
begin
  if not askip_reference_update then
    execute format($sql$
    update partitions.site__%1$s
       set reference_count = coalesce(reference_count, 0) + 1
     where domain = adomain;
    $sql$, vpartition);
  end if;

  if not exists (
    select *
      from public.site
     where domain = adomain
       and left(md5(domain), 2) = vpartition
  ) then
    execute format($sql$
    insert into partitions.site__%1$s (domain)
    values ($1);
    $sql$, vpartition) using adomain;

    return 1;
  else
    return 0;
  end if;

exception when unique_violation then
  return 0;
end;
$$ language plpgsql security definer;

comment on function public.add_domain(text, boolean)
  is 'Adds new domain, returns new domains count (1 or 0)';

create or replace
function public.add_domains
(
  adomains           text[]
) returns integer as $$
declare
  vcount integer := 0;
begin
  select sum(public.add_domain(domain))
    into vcount
    from unnest(adomains) domain;

  return vcount;
end;
$$ language plpgsql security definer;

comment on function public.add_domains(text[])
  is 'Adds new domains, returns new domains count';

create or replace
function public.save_tag_meta_value
(
    asite_id     integer,
    atask_id     integer,
    atag_meta_id integer,
    avalue       text
) returns integer as $$
begin
    update public.tag_meta_value
       set value = avalue
     where task_id = atask_id
       and site_id = asite_id
       and tag_meta_id = atag_meta_id;

    if not found then
        insert into public.tag_meta_value(site_id, task_id, tag_meta_id, value)
        values (asite_id, atask_id, atag_meta_id, avalue);

        return 1;
    else
        return 0;
    end if;
end;
$$ language plpgsql security definer;

create or replace
function public.get_next_item
(
    asession_id integer,
    atask_id    integer default null
) returns table (
    id           integer,
    site_id      integer,
    task_id      integer,
    domain       varchar,
    job          varchar
) as $$
begin
    return query
    select q.id,
           q.site_id,
           q.task_id,
           q.domain,
           q.job
      from public.queue q
     where q.session_id = asession_id
       and (q.task_id = atask_id or atask_id is null)
     limit 1;
end;
$$ language plpgsql
   security definer
   set enable_seqscan to 'off';
