== Find ==
1) http://www.postgresql.org/docs/9.1/static/functions-aggregate.html
2) GUI database tool? no thank you.

== Do ==
1) Create a rule that captures DELETEs on venues and instead sets the active flag to FALSE.

CREATE RULE deactivate_venues as on delete to venues do instead
  update venues set active = FALSE where name = old.name;

2) Replace the month_count temporary table with a call to generate_series(a,b).

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

3) Build a pivot table that displays every day in a single month.

select * from crosstab(
   'select extract(week from generate_series::date) as week, NULL as dow, NULL as count
      from generate_series(''2012-02-01'', ''2012-02-29'', interval ''1 week'')
   UNION
   select extract(week from starts) as week,
   extract(dow from starts) as dow, count(*)
   from events group by starts, ends, week
   having (starts,ends) overlaps (DATE ''2012-02-01'', DATE ''2012-02-29'') order by week',
  'select * from generate_series(0,6)'
) as (
  week int,
  sun int, mon int, tue int, wed int, thu int, fri int, sat int
) order by week;

-- example output:
 week | sun | mon | tue | wed | thu | fri | sat
------+-----+-----+-----+-----+-----+-----+-----
    5 |     |     |     |     |     |     |
    6 |     |   1 |     |     |     |     |
    7 |     |     |   1 |   1 |     |     |
    8 |   1 |     |     |     |     |     |
    9 |     |     |     |     |     |     |
