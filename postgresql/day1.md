== Find ==
1) http://www.postgresql.org/docs/current/static/index.html
2) \h keyword for SQL command description and syntax.
   \? for psql commands
3) "MATCH FULL will not allow one column of a multicolumn foreign key to be null unless all foreign key columns are null."
  http://www.postgresql.org/docs/9.1/static/sql-createtable.html

== Do ==
1) Select all the tables we created (and only those) from pg_class.

  select relname from pg_class where
    relnamespace = (select oid from pg_namespace where nspname = 'public')
    and relkind = 'r';

'public' is the default schema, and allows us to only see what we have created (eliminating system-created relations).  Restricting to kind 'r' shows only the ordinary tables (no indexes, sequences, views, etc.).

2) Write a query that finds the country name of the LARP Club event.
  select c.country_code from
    events e join venues v
      on e.venue_id = v.venue_id
    join cities c
      on v.postal_code=c.postal_code and v.country_code=c.country_code
  where e.title = 'LARP Club';

3) Alter the venues table to contain a boolean column called active, with the default value of TRUE.
  alter table venues add active boolean default TRUE;


