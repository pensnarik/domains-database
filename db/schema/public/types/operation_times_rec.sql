create type public.operation_times_rec as (
	get_item numeric,
	resolve numeric,
	fetch_page numeric,
	parse numeric,
	search_phones numeric,
	search_emails numeric
);
