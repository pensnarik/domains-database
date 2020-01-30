create SEQUENCE page_id
    START with 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

grant select,USAGE on SEQUENCE page_id to group_write;

