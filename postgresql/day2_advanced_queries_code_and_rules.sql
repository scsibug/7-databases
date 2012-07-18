-- Additional data
insert into countries (country_code, country_name) values ('ca', 'Canada');
insert into cities (name, postal_code, country_code) values ('Fort Worth', '76118', 'us');
insert into cities (name, postal_code, country_code) values ('Addison', '75001', 'us');
insert into venues (name, street_address, type, postal_code, country_code, active) values
  ('My Place', '123 My Way', 'public', '76118', 'us', TRUE);
insert into venues (name, street_address, type, postal_code, country_code, active) values
  ('ThoughtWorks', '15455 Dallas Parkway', 'public', '75001', 'us', TRUE);
insert into events (title, starts, ends, venue_id) values
  ('Geek Night', '2012-07-18 17:30', '2012-07-18 21:00',
    (select venue_id from venues where name = 'ThoughtWorks')
  );

-- Sample data from book
insert into events (title, starts, ends, venue_id) values
  ('Moby', '2012-02-06 21:00', '2012-02-06 23:00',
    (select venue_id from venues where name = 'Crystal Ballroom')
  );
insert into events (title, starts, ends, venue_id) values
  ('Wedding', '2012-02-26 21:00', '2012-02-26 23:00',
    (select venue_id from venues where name = 'Voodoo Donuts')
  );
insert into events (title, starts, ends, venue_id) values
  ('Dinner with Mom', '2012-07-18 18:00', '2012-07-18 20:30',
    (select venue_id from venues where name = 'My Place')
  );
insert into events (title, starts, ends) values
  ('Valentine''s Day', '2012-02-14 00:00', '2012-02-14 23:59');

-- Aggregate Queries
select count(title) from events where title like '%Day%';

select min(starts), max(ends)
  from events inner join venues
    on events.venue_id = venues.venue_id
  where venues.name = 'Crystal Ballroom';

-- Counting events by venue the hard way
select count(*) from events where venue_id = 1;
select count(*) from events where venue_id = 2;
select count(*) from events where venue_id = 3;
select count(*) from events where venue_id = 4;

-- Grouping
select venue_id, count(*) from events group by venue_id;

-- Grouping with Having
select venue_id, count(*) from events group by venue_id
  having count(*) >= 2 and venue_id is not null;

-- Unique values
select venue_id from events group by venue_id;

-- Unique values with DISTINCT
select distinct venue_id from events;

-- Transactions and Rollbacks
begin transaction;
  delete from events;
rollback;
select * from events;

-- Stored procedures
create or replace function add_event
  (title text, starts timestamp, ends timestamp, venue text, postal varchar(9), country char(2))
returns boolean as $$
declare
  did_insert boolean := false;
  found_count integer;
  the_venue_id integer;
begin
  select venue_id into the_venue_id
  from venues v
  where v.postal_code=postal and v.country_code=country and v.name ilike venue
  limit 1;

  if the_venue_id is null then
    insert into venues (name, postal_code, country_code)
    values (venue, postal, country)
    returning venue_id into the_venue_id;

    did_insert := true;
  end if;

  -- Note: not an "error", as in some programming languages
  -- 'notice' is just a log message.  'exception' would throw a real exception and abort a transaction.
  raise notice 'Venue found %', the_venue_id;

  insert into events (title, starts, ends, venue_id)
  values (title, starts, ends, the_venue_id);

  return did_insert;
end;
$$ language plpgsql;

-- Call stored procedure
select add_event('House Party', '2012-05-03 23:00', '2012-05-04 02:00', 'Run''s House', '97205', 'us');

-- Create table for logs
create table logs (
  event_id integer,
  old_title varchar(255),
  old_starts timestamp,
  old_ends timestamp,
  logged_at timestamp default current_timestamp
);

-- Function for logging changes
create or replace function log_event() returns trigger as $$
declare
begin
  insert into logs (event_id, old_title, old_starts, old_ends)
  values (old.event_id, old.title, old.starts, old.ends);
  raise notice 'Someone just changed event #%', old.event_id;
  return new;
end;
$$ language plpgsql;

-- Call function as trigger
create trigger log_events
  after update on events
  for each row execute procedure log_event();

-- Update an event (demonstrate trigger execution)
update events set ends='2012-05-04 01:00' where title = 'House Party';
-- NOTICE:  Someone just changed event #10

-- Show logs
select * from logs;

-- Creating Views
create view holidays as
  select event_id as holiday_id, title as name, starts as date
  from events
  where title like '%Day%' and venue_id is null;

-- Updating views
alter table events
  add colors text array;

create or replace view holidays as
  select event_id as holiday_id, title as name, starts as date, colors
  from events
  where title like '%Day%' and venue_id is null;

-- Views cannot be update directly
update holidays set colors = '{"red", "green"}' where name = 'Christmas Day';
--ERROR:  cannot update view "holidays"
--HINT:  You need an unconditional ON UPDATE DO INSTEAD rule or an INSTEAD OF UPDATE trigger.

-- Query plans
explain verbose select * from holidays;
--                                QUERY PLAN
---------------------------------------------------------------------------
-- Seq Scan on public.events  (cost=0.00..1.04 rows=1 width=76)
--   Output: events.event_id, events.title, events.starts, events.colors
--   Filter: ((events.venue_id IS NULL) AND (events.title ~~ '%Day%'::text))
--(3 rows)

--Rules
create rule update_holidays as on update to holidays do instead
  update events
  set title = new.name,
      starts = new.date,
      colors = new.colors
  where title = old.name;

update holidays set colors = '{"red", "green"}' where name = 'Christmas Day';

--
select extract(year from starts) as year,
  extract(month from starts) as month, count(*)
  from events group by year, month;

-- A temporary table for months
create temporary table month_count(month int);
insert into month_count values (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12);

select * from crosstab(
  'select extract(year from starts) as year,
    extract(month from starts) as month, count(*)
    from events group by year, month',
  'select * from month_count'
) as (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int,
  jul int, aug int, sep int, oct int, nov int, dec int
) order by year;


-- Without the need for a temporary table (homework)
select * from crosstab(
  'select extract(year from starts) as year,
    extract(month from starts) as month, count(*)
    from events group by year, month',
  'select * from generate_series(1,12)'
) as (
  year int,
  jan int, feb int, mar int, apr int, may int, jun int,
  jul int, aug int, sep int, oct int, nov int, dec int
) order by year;

