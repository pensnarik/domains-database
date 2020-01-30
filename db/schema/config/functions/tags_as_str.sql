create or replace
function config.tags_as_str(atags integer[]) returns varchar as $$
    select string_agg(name, ', ')
      from config.expression e
      join config.tag t
        on t.id = e.tag_id
     where e.id = any(atags);
$$ language sql immutable;
