-- Day 1, Relations, CRUD, and Joins

create table countries (
  country_code char(2) primary key,
  country_name text unique
);

insert into countries (country_code, country_name)
values ('us','United States'), ('mx', 'Mexico'),
       ('au','Australia'),('gb','United Kingdom'),
       ('de','Germany'),('ll','Loompaland');

-- Test the table's unique constraint.
insert into countries values ('uk','United Kingdom');
--ERROR:  duplicate key value violates unique constraint "countries_country_name_key"
--DETAIL:  Key (country_name)=(United Kingdom) already exists.

-- Query for all countries
select * from countries;

-- Remove a fake country
delete from countries where country_code = 'll';

-- Create a table with a FK to countries
create table cities (
  name text not null,
  postal_code varchar(9) check (postal_code <> ''),
  country_code char(2) references countries,
  primary key (country_code, postal_code)
);
-- implicit index "cities_pkey" created

-- Test the FK constraint
insert into cities values ('Toronto', 'M4C1B5', 'ca');
--ERROR:  insert or update on table "cities" violates foreign key constraint "cities_country_code_fkey"
--DETAIL:  Key (country_code)=(ca) is not present in table "countries".

insert into cities values ('Portland', '87200', 'us');

-- Correct the wrong zip code we just inserted
update cities set postal_code = '97205' where name = 'Portland';

-- Join countries and cities
select cities.*, country_name from cities inner join countries
  on cities.country_code = countries.country_code;

-- Create a table for venues
create table venues (
  venue_id serial primary key,
  name varchar(255),
  street_address text,
  type char(7) check (type in ('public', 'private')) default 'public',
  postal_code varchar(9),
  country_code char(2),
  foreign key (country_code, postal_code)
    references cities (country_code, postal_code) MATCH FULL
);
-- implicit sequence 'venues_venue_id_seq'
-- implicit index 'venues_pkey'

insert into venues (name, postal_code, country_code)
  values ('Crystal Ballroom', '97205', 'us');

-- Compound join venues and cities
select v.venue_id, v.name, c.name from venues v inner join cities c
  on v.postal_code=c.postal_code and v.country_code=c.country_code;

-- Perform an insert, immediately returning the auto-generated ID.
insert into venues (name, postal_code, country_code)
  values ('Voodoo Donuts', '97205', 'us') returning venue_id;

-- Create events table
create table events (
  event_id serial primary key,
  title text,
  starts timestamp,
  ends timestamp,
  venue_id integer references venues
);
-- implicit sequence 'events_event_id_seq'
-- implicit sequence 'events_venue_id_seq'
-- implicit index 'events_pkey'

insert into events (title, starts, ends, venue_id) values
  ('LARP Club',       '2012-02-15 17:30', '2012-02-15 19:30', '2'),
  ('April Fools Day', '2012-04-01 00:00', '2012-04-01 23:59', NULL),
  ('Christmas Day',   '2012-12-25 00:00', '2012-12-25 23:59', NULL);

-- Join events with venues
select e.title, v.name from events e join venues v
  on e.venue_id = v.venue_id;

-- Outer join events with venues to show all events
select e.title, v.name from events e left join venues v
  on e.venue_id = v.venue_id;

-- Create a hash index on event titles
create index events_title on events using hash (title);

select * from events where starts >= '2012-04-01';

-- Create a btree index to match range queries (like above)
create index event_starts on events using btree (starts);