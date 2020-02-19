create type public.site_fetch_result as enum (
    'ok',
    'timeout',
    'connection_error',
    'too_many_redirects',
    'unknown_error',
    'too_large',
    'resolve_error',
    'unknown_encoding'
);

