create type public.task_status_mnemonic as enum (
    'new',
    'queued',
    'done',
    'error',
    'processing'
);
