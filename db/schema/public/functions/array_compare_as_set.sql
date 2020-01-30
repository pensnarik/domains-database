create or replace
function array_compare_as_set(anyarray, anyarray) returns boolean as $$
select CasE
  WHEN array_dims($1) <> array_dims($2) THEN
    'f'
  WHEN array_length($1,1) <> array_length($2,1) THEN
    'f'
  ELSE
    NOT EXISTS (
        select 1
        from unnest($1) a 
        FULL JOIN unnest($2) b on (a=b) 
        WHERE a is NULL or b is NULL
    )
  END
$$ language sql immutable;

