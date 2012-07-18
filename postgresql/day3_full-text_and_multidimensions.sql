create table genres (
  name text unique,
  position integer
);

create table movies (
  movie_id serial primary key,
  title text,
  genre cube
);

create table actors (
  actor_id serial primary key,
  name text
);

create table movies_actors (
  movie_id integer references movies not null,
  actor_id integer references actors not null,
  unique (movie_id, actor_id)
);

create index movies_actors_movie_id on movies_actors (movie_id);
create index movies_actors_actor_id on movies_actors (actor_id);
create index movies_genres_cube on movies using gist (genre);

-- load data with psql -d book -f movie_data.sql

-- Case insensitive searching
select title from movies where title ilike 'stardust%';

-- ensure stardust is not at the end of the title
select title from movies where title ilike 'stardust_%';

-- Regex searches (not-match case insensitive)
select count(*) from movies where title !~* '^the.*';

-- Index title for regex searches
create index movies_title_pattern on movies (lower(title) text_pattern_ops);

-- Levenshtein distance
select levenshtein('bat', 'fads');

-- Find close matches with levenshtein distance
select movie_id, title, levenshtein(lower(title), lower('a hard day night')) as distance from movies order by distance;

-- Trigrams
select show_trgm('Avatar');

-- Create a trigram index on movie titles
create index movies_title_trigram on movies
  using gist (title gist_trgm_ops);

select * from movies where title % 'Avatre';

-- Full-text search
select title from movies
  where title @@ 'night & day';

-- language-specific version
select title from movies
  where to_tsvector(title) @@ to_tsquery('english', 'night &amp; day');

-- stop words are ignored
select * from movies where title @@ to_tsquery('english', 'a');

-- Different dictionaries have different stop words:
select to_tsvector('english', 'A Hard Day''s Night');
--  'day':3 'hard':2 'night':5
select to_tsvector('simple', 'A Hard Day''s Night');
--  'a':1 'day':3 'hard':2 'night':5 's':4

-- Calling the lexer directly
select ts_lexize('english_stem', 'Day''s');
-- {day}

-- Now, in german (if we had the dictionary installed)
--select ts_lexize('german', 'was machst du gerade?');

-- Explain query plan
explain
select * from movies
  where title @@ 'night & day';
--                        QUERY PLAN
----------------------------------------------------------
-- Seq Scan on movies  (cost=0.00..175.07 rows=3 width=315)
--   Filter: (title @@ 'night & day'::text)
--(2 rows)

-- Create GIN for movie titles
create index movies_title_searchable on movies
  using gin(to_tsvector('english', title));

-- Index only works for english searches
explain
select * from movies
  where to_tsvector('english', title) @@ 'night & day';
--                                            QUERY PLAN
--------------------------------------------------------------------------------------------------
-- Bitmap Heap Scan on movies  (cost=20.00..24.02 rows=1 width=315)
--   Recheck Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)
--   ->  Bitmap Index Scan on movies_title_searchable  (cost=0.00..20.00 rows=1 width=0)
--         Index Cond: (to_tsvector('english'::regconfig, title) @@ '''night'' & ''day'''::tsquery)

-- Metaphones
-- This doesn't work
select * from actors where name = 'Broos Wlis';
-- Trigrams don't help either
select * from actors where name % 'Broos Wlis';

-- Book changed the misspelling of "Wils"?
select title from movies natural join movies_actors natural join actors where
  metaphone(name, 6) = metaphone('Broos Wils', 6);

-- Variety of metaphone/soundex representations
select name, dmetaphone(name), dmetaphone_alt(name), metaphone(name, 8), soundex(name) from actors;

-- Combining string maches
select * from actors where metaphone(name,8) % metaphone('Robin Williams', 8)
  order by levenshtein(lower('Robin Williams'), lower(name));

-- A less effective example
select * from actors where dmetaphone(name) % dmetaphone('Ron');

-- Multidimensional Hypercube
select name, cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position) as score
  from genres g
  where cube_ur_coord('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)', position) > 0;

-- Order movies by distance from star wars.
select *, cube_distance(genre, '(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)') dist
  from movies order by dist;

-- enlarge a cube (creating a bounding cube)
select cube_enlarge('(1,1)', 1, 2);

-- The contains operator, @>, to bound the search and improve performance
select title, cube_distance(genre, '(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)') dist
  from movies
  where cube_enlarge ('(0,7,0,0,0,0,0,0,0,7,0,0,0,0,10,0,0,0)'::cube, 5, 18) @> genre
  order by dist;

-- subselect
select m.movie_id, m.title
  from movies m, (select genre, title from movies where title = 'Mad Max') s
  where cube_enlarge(s.genre, 5, 18) @> m.genre and s.title <> m.title
  order by cube_distance(m.genre, s.genre)
  limit 10;
