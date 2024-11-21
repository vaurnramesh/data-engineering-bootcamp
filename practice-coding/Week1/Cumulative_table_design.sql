SELECT * FROM player_seasons;


-- WHERE player_name = 'A.C. Green';
/* The idea here is that there are many duplicate fields 
and it is good to seperate them out for a good data modelling. 
Joining becomes hard downstream if the modelling isn't great. */

/* Creating a struct where we extract unique values like the season 
results for each players */

CREATE TYPE season_stats AS (
    season INTEGER,
    gp INTEGER,
    pts REAL,
    reb REAL,
    ast REAL
);

CREATE TABLE players (
	player_name TEXT,
	height TEXT,
	college TEXT,
	country TEXT,
	draft_year TEXT,
	draft_round TEXT,
	draft_number TEXT,
	season_stats season_stats[], -- array of the season stats
	current_season INTEGER, -- As we do outer joins, this will be the latest value
	PRIMARY KEY(player_name, current_season)
)


-- Step 1: Below is going to give us the cumulation between today and yesterday


-- WITH yesterday AS (
-- 	SELECT * FROM players
-- 	WHERE current_season = 1995
-- ),
-- 	today AS (
-- 		SELECT * FROM player_seasons
-- 		WHERE season = 1996
-- 	)

-- SELECT * FROM today t FULL OUTER JOIN yesterday y
-- 	ON t.player_name = y.player_name


-- After running the query, you'll see everything from yesterday is null 
-------------------------------------------------------------------------------
-- Step 2: Now we want to coallesce the values that are not changing 


-- WITH yesterday AS (
-- 	SELECT * FROM players
-- 	WHERE current_season = 1995
-- ),
-- 	today AS (
-- 		SELECT * FROM player_seasons
-- 		WHERE season = 1996
-- 	)

-- SELECT
-- 		COALESCE(t.player_name, y.player_name) as player_name,
--         COALESCE(t.height, y.height) as height,
--         COALESCE(t.college, y.college) as college,
--         COALESCE(t.country, y.country) as country,
--         COALESCE(t.draft_year, y.draft_year) as draft_year,
--         COALESCE(t.draft_round, y.draft_round) as draft_round,
--         COALESCE(t.draft_number, y.draft_number)
		
	
-- 	FROM today t FULL OUTER JOIN yesterday y
-- 		ON t.player_name = y.player_name


-- Running this we get only results for today (looks lame :P) but this is called the SEED QUERY because yesterday is null

-------------------------------------------------------------------------------
-- Step 3: Now we are gonna add the seasons array - just to see if yesterdays value is still there 

-- WITH yesterday AS (
-- 	SELECT * FROM players
-- 	WHERE current_season = 1995
-- ),
-- 	today AS (
-- 		SELECT * FROM player_seasons
-- 		WHERE season = 1996
-- 	)

-- SELECT
-- 		COALESCE(t.player_name, y.player_name) as player_name,
--         COALESCE(t.height, y.height) as height,
--         COALESCE(t.college, y.college) as college,
--         COALESCE(t.country, y.country) as country,
--         COALESCE(t.draft_year, y.draft_year) as draft_year,
--         COALESCE(t.draft_round, y.draft_round) as draft_round,
--         COALESCE(t.draft_number, y.draft_number) as draft_number,
-- 		CASE WHEN y.season_stats IS NULL
-- 			THEN ARRAY [ROW(					-- We want to do an array concat that slowly builds up the value of the array
-- 						t.season,
-- 						t.gp,
-- 						t.pts,
-- 						t.reb,
-- 						t.ast
-- 						)::season_stats]		-- The colon|colon will type cast it to season_stats array       
-- 		ELSE y.season_stats || ARRAY [ROW(		-- Concat with yesterday if NOT NULL
-- 						t.season,
-- 						t.gp,
-- 						t.pts,
-- 						t.reb,
-- 						t.ast
-- 						)::season_stats]
-- 		END as season_stats,
	
-- 	FROM today t FULL OUTER JOIN yesterday y
-- 		ON t.player_name = y.player_name

-------------------------------------------------------------------------------
-- Step 4: There is another case when if todays value is null - if it's a RETIRED player		

-- WITH yesterday AS (
-- 	SELECT * FROM players
-- 	WHERE current_season = 1995
-- ),
-- 	today AS (
-- 		SELECT * FROM player_seasons
-- 		WHERE season = 1996
-- 	)

-- SELECT
-- 		COALESCE(t.player_name, y.player_name) as player_name,
--         COALESCE(t.height, y.height) as height,
--         COALESCE(t.college, y.college) as college,
--         COALESCE(t.country, y.country) as country,
--         COALESCE(t.draft_year, y.draft_year) as draft_year,
--         COALESCE(t.draft_round, y.draft_round) as draft_round,
--         COALESCE(t.draft_number, y.draft_number) as draft_number,
-- 		CASE WHEN y.season_stats IS NULL
-- 			THEN ARRAY [ROW(					
-- 						t.season,
-- 						t.gp,
-- 						t.pts,
-- 						t.reb,
-- 						t.ast
-- 						)::season_stats]		   
-- 		WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY [ROW(		
-- 						t.season,
-- 						t.gp,
-- 						t.pts,
-- 						t.reb,
-- 						t.ast
-- 						)::season_stats]
-- 		ELSE y.season_stats				
-- 		END as season_stats,
-- 		COALESCE(t.season, y.current_season + 1) as current_season -- The final variable of the players table is modelled properly :)
-- 	FROM today t FULL OUTER JOIN yesterday y
-- 		ON t.player_name = y.player_name
	

-- After running this we can see the current season is 1996 as that's the start of the data. All data from 1995 will be NULL.

-------------------------------------------------------------------------------

-- Step 5: Creating this as a pipeline changing the current season to 1996 - 2001

INSERT INTO players
WITH yesterday AS (
	SELECT * FROM players
	WHERE current_season = 2000
),
	today AS (
		SELECT * FROM player_seasons
		WHERE season = 2001
	)

SELECT
		COALESCE(t.player_name, y.player_name) as player_name,
        COALESCE(t.height, y.height) as height,
        COALESCE(t.college, y.college) as college,
        COALESCE(t.country, y.country) as country,
        COALESCE(t.draft_year, y.draft_year) as draft_year,
        COALESCE(t.draft_round, y.draft_round) as draft_round,
        COALESCE(t.draft_number, y.draft_number) as draft_number,
		CASE WHEN y.season_stats IS NULL
			THEN ARRAY [ROW(					
						t.season,
						t.gp,
						t.pts,
						t.reb,
						t.ast
						)::season_stats]		   
		WHEN t.season IS NOT NULL THEN y.season_stats || ARRAY [ROW(		
						t.season,
						t.gp,
						t.pts,
						t.reb,
						t.ast
						)::season_stats]
		ELSE y.season_stats				
		END as season_stats,
		COALESCE(t.season, y.current_season + 1) as current_season -- The final variable of the players table is modelled properly :)
	FROM today t FULL OUTER JOIN yesterday y
		ON t.player_name = y.player_name

-------------------------------------------------------------------------------

-- Step 6: Let's see some interesting stats for Michael Jordan 

-- SELECT * FROM players 
-- WHERE current_season = 2001 
-- AND player_name = 'Michael Jordan'

-- You can see his season stats in an array - "{""(1996,82,29.6,5.9,4.3)"",""(1997,82,28.7,5.8,3.5)"",""(2001,60,22.9,5.7,5.2)""}"
-- Apparently he retired in 1997 and rejoined basket ball in 2001. 
-- Now that we have all information in a flattened format, do you think we can unpack it again or is it going to be some hectic stuff? 

-------------------------------------------------------------------------------
-- Step 7: Unnesting: This opens up the array 

-- SELECT player_name, UNNEST(season_stats) AS season_stats FROM players 
-- WHERE current_season = 2001
-- AND player_name = 'Michael Jordan'

-------------------------------------------------------------------------------
-- Step 8: If you want to unnest it even further - using individual columns, we can use a CTE (POWERFULL!)

WITH unnested AS (
	SELECT player_name, UNNEST(season_stats)::season_stats AS season_stats -- casting to season stats
	FROM players 
	WHERE current_season = 2001
	AND player_name = 'Michael Jordan'
)

SELECT player_name, 
		(season_stats::season_stats).* -- The casted season stats array and unwrapping all the columns using ".*"
FROM unnested

	   
