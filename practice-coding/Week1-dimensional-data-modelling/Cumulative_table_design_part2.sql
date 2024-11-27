-- PART 2
-------------------------------------------------------------------------------
-- Step1: We are going to be adding two more columns to the Players table. Let's drop it in :/

-- DROP TABLE players;

-------------------------------------------------------------------------------
-- Step2: Creating a scoring class table that defines how good the player is. 

CREATE TYPE scoring_class AS ENUM('star', 'good', 'average', 'bad');

CREATE TABLE players (
	player_name TEXT,
	height TEXT,
	college TEXT,
	country TEXT,
	draft_year TEXT,
	draft_round TEXT,
	draft_number TEXT,
	season_stats season_stats[],
	scoring_class scoring_class,
	years_since_last_season INTEGER, --> new
	current_season INTEGER, --> new
	is_active BOOLEAN, --> new
	PRIMARY KEY(player_name, current_season)
)

-------------------------------------------------------------------------------
-- Step 3: Adding the new columns in the Cumulative dimension table that we created 

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
		CASE 
			WHEN y.season_stats IS NULL
				THEN ARRAY [ROW(					
							t.season,
							t.gp,
							t.pts,
							t.reb,
							t.ast
							)::season_stats]		   
			WHEN t.season IS NOT NULL 
				THEN y.season_stats || ARRAY [ROW(		
						t.season,
						t.gp,
						t.pts,
						t.reb,
						t.ast
						)::season_stats]
				ELSE y.season_stats				
		END as season_stats,
		CASE 
			WHEN t.season IS NOT NULL
				THEN 
				CASE WHEN t.pts > 20 THEN 'star'
					 WHEN t.pts > 15 THEN 'good'
					 WHEN t.pts > 10 THEN 'average'
					 ELSE 'bad'
				END::scoring_class
			ELSE y.scoring_class
		END as scoring_class,
		CASE 
			WHEN t.season IS NOT NULL							  -- NEW: If a player starts a season - the number is zero, else if the current season is Null, this parameter increments 
				THEN 0
				ELSE y.years_since_last_season + 1
		END AS years_since_last_season,
		COALESCE(t.season, y.current_season + 1) as current_season
	FROM today t FULL OUTER JOIN yesterday y
	ON t.player_name = y.player_name

-------------------------------------------------------------------------------
-- Step 4: Running the query

-- SELECT * FROM players 
-- WHERE current_season = 2000
-- AND player_name = 'Michael Jordan'

-------------------------------------------------------------------------------
-- Step 5: Some analytics to find which player has the most improvement
-- Step 5.1: Get the first and the last season points

-- SELECT
-- 	player_name,
-- 	(season_stats[1]::season_stats).pts AS first_season,
-- 	(season_stats[CARDINALITY(season_stats)]::season_stats).pts as latest_season
-- FROM players 
-- WHERE current_season = 2001

-- Step 5.2: Divide last season by first season to see the improvement

SELECT
	player_name,
	(season_stats[CARDINALITY(season_stats)]::season_stats).pts /
	CASE 
		WHEN (season_stats[1]::season_stats).pts = 0
		THEN 1
		ELSE (season_stats[1]::season_stats).pts
	END	
FROM players 
WHERE current_season = 2001
AND scoring_class = 'star'
ORDER BY 2 DESC

/** Note: Fun fact, there is not GROUP BY here, followed by an Aggregation (Min, Max) which makes it insanely fast! 
If we are able to query the data in the Map step without the reduce step, we can parallelize this to a very high amount 
**/