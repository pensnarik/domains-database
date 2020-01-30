create function public.update_activity
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

create function public.delete_task_from_queue
(
    aid integer,
    asession_id integer
) returns void as $$
begin
    delete
      from public.queue
     where id = aid
       and session_id = asession_id;
end;
$$ language plpgsql
   security definer;

comment on function public.delete_task_from_queue(integer, integer)
    is 'Removes task from queue, executed at the end of the task by datarace client';
