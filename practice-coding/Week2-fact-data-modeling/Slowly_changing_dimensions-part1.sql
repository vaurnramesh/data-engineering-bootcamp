-- PART - 1
-------------------------------------------------------------------------------
-- Step1:

-- SELECT player_name, scoring_class, is_active
-- FROM players
-- WHERE current_season = 2022;

-- We first want to see if we have access to the players, scoring class and their activity
-- We also want to track changes in two columns, ie scoring_class and is_active.
-- The point of SCD table is to track multiple changing columns

-------------------------------------------------------------------------------
-- Step2: Create a type 2 SCD table

CREATE TABLE players_scd (
	player_name TEXT,
	scoring_class scoring_class, --> tracking column 1
	is_active BOOLEAN,			  --> tracking column 2
	current_season INTEGER,      --> last column
	start_season INTEGER,        --> time range
	end_season INTEGER,			  --> time range
	PRIMARY KEY(player_name, start_season)
)

-------------------------------------------------------------------------------
-- Step3: How long has each player in the dimension? 
-- We do that using window function! 

WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
)

SELECT * FROM with_previous

-- We start noticing that some previous_is_active records are null because the player may not have been present in the previous season


-------------------------------------------------------------------------------
-- Step 4: Now we can add a scoring class, is_active class indicator to check if it has changed in time

WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
)

SELECT *, 
		CASE 
			WHEN scoring_class <> previous_scoring_class 
				THEN 1 
				ELSE 0 
			END as scoring_class_change_indicator,
		CASE 
			WHEN is_active <> previous_is_active 
				THEN 1 
				ELSE 0
			END as is_active_change_indicator	
FROM with_previous

-------------------------------------------------------------------------------
-- Step 5: It get's complicated to read if we have two indicators. Let's try having one indicator

WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
),

with_indicators AS (
	SELECT *, 
			CASE 
				WHEN scoring_class <> previous_scoring_class THEN 1
				WHEN is_active <> previous_is_active THEN 1
					ELSE 0 
				END as change_indicator
	FROM with_previous
)

SELECT * 
FROM with_indicators

-------------------------------------------------------------------------------
-- Step 6: Now let's add a streak identifier to sum up the change_indicator

WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
),

with_indicators AS (
	SELECT *, 
			CASE 
				WHEN scoring_class <> previous_scoring_class THEN 1
				WHEN is_active <> previous_is_active THEN 1
					ELSE 0 
				END as change_indicator
	FROM with_previous
)

SELECT *,
		 SUM(change_indicator) OVER (
										PARTITION BY player_name
										ORDER BY current_season
									) AS streak_identifier
		 
FROM with_indicators
WHERE player_name = ''

/** Some info about A.J. Bramlett: He started playing in 1999 as a bad player and never played a season. 
Hence his change_indicator is 1 and streak identifier is 1

Now try putting in Tracy MacGrady and you'll see how much he has changed throughout his career. 
**/

-------------------------------------------------------------------------------
-- Step 7: We now have 3 window functions :) The idea in this step to squash the repeated value. These 
-- repeated values are coming up because of with_previous, with_indicators and with_streaks

WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
	WHERE current_season <= 2021
),

with_indicators AS (
	SELECT *, 
			CASE 
				WHEN scoring_class <> previous_scoring_class THEN 1
				WHEN is_active <> previous_is_active THEN 1
					ELSE 0 
				END as change_indicator
	FROM with_previous
),

with_streaks AS (
	SELECT *,
			 SUM(change_indicator) OVER (
										 PARTITION BY player_name
										 ORDER BY current_season
										 ) AS streak_identifier
	FROM with_indicators									 
)


-- Now that we have the streak identifier and change indicators to tell us the story overtime. Let's squash 
-- the repeated player names

SELECT player_name,
	   streak_identifier,
	   is_active,
	   scoring_class,
	   MIN(current_season) as start_season,
	   MAX(current_season) as end_season,
	   2021 as current_season
FROM with_streaks
GROUP BY player_name, streak_identifier, is_active, scoring_class
ORDER BY player_name

-------------------------------------------------------------------------------
-- Step 8: Finally, inserting into players_scd

INSERT INTO players_scd
WITH with_previous AS (SELECT 
			player_name,
			current_season,
			scoring_class,
			is_active,
			LAG(scoring_class, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_scoring_class,
			LAG(is_active, 1) OVER (
										PARTITION BY player_name
										ORDER BY current_season
										) as previous_is_active
			
	FROM players
	WHERE current_season <= 2021
),

with_indicators AS (
	SELECT *, 
			CASE 
				WHEN scoring_class <> previous_scoring_class THEN 1
				WHEN is_active <> previous_is_active THEN 1
					ELSE 0 
				END as change_indicator
	FROM with_previous
),

with_streaks AS (
	SELECT *,
			 SUM(change_indicator) OVER (
										 PARTITION BY player_name
										 ORDER BY current_season
										 ) AS streak_identifier
	FROM with_indicators									 
)

SELECT player_name,
	   scoring_class,
	   is_active,
	   2021 as current_season,
	   MIN(current_season) as start_season,
	   MAX(current_season) as end_season	   
FROM with_streaks
GROUP BY player_name, streak_identifier, is_active, scoring_class
ORDER BY player_name

/** This query works great and should be used. A small caveat is if one of the dimensions
are changing more frequently than expected, we could end up with OOME. 
That's not a huge concern for the time being but something that should be 
kept in mind **/
