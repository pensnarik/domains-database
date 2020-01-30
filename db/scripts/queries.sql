select (t.operation_times).get_item +
       (t.operation_times).resolve +
       (t.operation_times).fetch_page +
       (t.operation_times).parse +
       (t.operation_times).search_phones +
       (t.operation_times).search_emails,
* from site_task t order by end_time desc nulls last limit 100;

select date_trunc('h', end_time),
       sum(sites_processed),
       sum(sites_extracted),
       sum(sites_added),
       sum(phones_extracted),
       sum(emails_extracted),
       sum(phones_added),
       sum(emails_added),
       avg((t.operation_times).get_item +
           (t.operation_times).resolve +
           (t.operation_times).fetch_page +
           (t.operation_times).parse +
           (t.operation_times).search_phones +
           (t.operation_times).search_emails)
  from site_task t
 where session_id > 1137
   and status = 'error'
   --and fetch_result = 'ok'
group by 1 order by 1 desc limit 20;
