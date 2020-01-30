create SEQUENCE site_id_seq
    START with 14876206
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

grant select,USAGE on SEQUENCE site_id_seq to group_write;

