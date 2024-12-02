/** PART 2: An incremental way to model an scd data that is scalable. This is an
an alternative way to model an scd data from part 1
**/
-------------------------------------------------------------------------------
-- Step 1: Checking if the scd data has changed over the recent years. 

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT * FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	)

-- SELECT * FROM last_season_scd
-- SELECT * FROM historical_scd

-------------------------------------------------------------------------------
-- Step 2: Let's think how we are planning to model this
/** For the last season to current season, some values may change. We want to add one
if the record remains the same while if the records do change we want to add a new record in. 
**/

SELECT ts.player_name, ts.scoring_class, ts.is_active,
	   ls.scoring_class, ls.is_active
FROM this_season_data ts
	 LEFT JOIN last_season_scd ls
	 ON ts.player_name = ls.player_name


-- Step 2.1: Now that we know there are some records changing, we can add the above query
-- to the CDF as unchanged_records with some changes

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT * FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),
	unchanged_records AS(
		SELECT ts.player_name, ts.scoring_class, ts.is_active, 
			   ts.current_season as end_season, 
			   ls.start_season, ls.is_active
		FROM this_season_data ts
			 JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE ls.player_name = ts.player_name
				AND ts.is_active = ls.is_active
	)

-- SELECT * FROM unchanged_records

-------------------------------------------------------------------------------

-- Step 3: Now we need to add the changing records to the CDF. The issue here is
-- that we will have two records, the one that has changed and the other that has ended. 
-- because of this we will need to use STRUCT as we have two different records and we would
-- like to make it one. 


CREATE TYPE scd_type AS (                      --> Created as we need a scoring_class type for array
						scoring_class scoring_class,
						is_active boolean,
						start_season INTEGER,
						end_season INTEGER
)

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT * FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),
	unchanged_records AS(
		SELECT ts.player_name, ts.scoring_class, ts.is_active, 
			   ts.current_season as end_season, 
			   ls.start_season, ls.is_active
		FROM this_season_data ts
			 JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE ls.player_name = ts.player_name
				AND ts.is_active = ls.is_active
	),
	changed_records AS (
		SELECT ts.player_name,
			   UNNEST(ARRAY [                   -- We'll need to create a TYPE as it's postgres
					ROW(
						 ls.scoring_class,
						 ls.is_active,
						 ls.start_season,
						 ls.end_season

					   )::scd_type,
					 ROW(
						 ts.scoring_class,
						 ts.is_active,
						 ts.current_season,
						 ts.current_season
						 
					   )::scd_type
			   ]) as records
		FROM this_season_data ts
			 LEFT JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE (ls.player_name <> ts.player_name)
				OR ts.is_active <> ls.is_active
	)
	
SELECT * FROM changed_records

/** You can see that there are two records - old record and the new record. 
For example, check for Aaron Henry **/

-------------------------------------------------------------------------------
-- Step 4: Now let's unnest the changed records


CREATE TYPE scd_type AS (                    
						scoring_class scoring_class,
						is_active boolean,
						start_season INTEGER,
						end_season INTEGER
)

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT * FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),
	unchanged_records AS(
		SELECT ts.player_name, ts.scoring_class, ts.is_active, 
			   ts.current_season as end_season, 
			   ls.start_season, ls.is_active
		FROM this_season_data ts
			 JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE ls.player_name = ts.player_name
				AND ts.is_active = ls.is_active
	),
	changed_records AS (
		SELECT ts.player_name,
			   UNNEST(ARRAY [               
					ROW(
						 ls.scoring_class,
						 ls.is_active,
						 ls.start_season,
						 ls.end_season

					   )::scd_type,
					 ROW(
						 ts.scoring_class,
						 ts.is_active,
						 ts.current_season,
						 ts.current_season
						 
					   )::scd_type
			   ]) as records
		FROM this_season_data ts
			 LEFT JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE (ls.player_name <> ts.player_name)
				OR ts.is_active <> ls.is_active
				
	),
	unnested_changed_records AS (
		SELECT player_name,
			   (records::scd_type).scoring_class,
			   (records::scd_type).is_active,
			   (records::scd_type).start_season,
			   (records::scd_type).end_season
	 	FROM changed_records
	)

SELECT * FROM unnested_changed_records


-- Again 2 records after this query 
 
-------------------------------------------------------------------------------
-- Step 5:	New records

CREATE TYPE scd_type AS (                    
						scoring_class scoring_class,
						is_active boolean,
						start_season INTEGER,
						end_season INTEGER
)

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT * FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),
	unchanged_records AS(
		SELECT ts.player_name, ts.scoring_class, ts.is_active, 
			   ts.current_season as end_season, 
			   ls.start_season, ls.is_active
		FROM this_season_data ts
			 JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE ls.player_name = ts.player_name
				AND ts.is_active = ls.is_active
	),
	changed_records AS (
		SELECT ts.player_name,
			   UNNEST(ARRAY [               
					ROW(
						 ls.scoring_class,
						 ls.is_active,
						 ls.start_season,
						 ls.end_season

					   )::scd_type,
					 ROW(
						 ts.scoring_class,
						 ts.is_active,
						 ts.current_season,
						 ts.current_season
						 
					   )::scd_type
			   ]) as records
		FROM this_season_data ts
			 LEFT JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE (ls.player_name <> ts.player_name)
				OR ts.is_active <> ls.is_active
				
	),
	unnested_changed_records AS (
		SELECT player_name,
			   (records::scd_type).scoring_class,
			   (records::scd_type).is_active,
			   (records::scd_type).start_season,
			   (records::scd_type).end_season
	 	FROM changed_records
	),
	new_records AS (

		SELECT ts.player_name,
			   ts.scoring_class,
			   ts.is_active,
			   ts.current_season AS start_season,
			   ts.current_season AS end_season
		FROM this_season_data ts
		LEFT JOIN last_season_scd ls
		ON ts.player_name = ls.player_name
			 	WHERE ls.player_name IS NULL
	)


-------------------------------------------------------------------------------
-- Step 6: Union all records

CREATE TYPE scd_type AS (                    
						scoring_class scoring_class,
						is_active boolean,
						start_season INTEGER,
						end_season INTEGER
)

WITH last_season_scd AS (
	SELECT * FROM players_scd
	WHERE current_season = 2021
	AND end_season = 2021
),
	historical_scd AS (
		SELECT player_name,
			   scoring_class,
			   is_active,
			   start_season,
			   end_season
		FROM players_scd
		WHERE current_season = 2021
		AND end_season < 2021
	),
	
	this_season_data AS (
		SELECT * FROM players
		WHERE current_season = 2022
	),
	unchanged_records AS(
		SELECT ts.player_name, ts.scoring_class, ts.is_active,
			   ls.start_season,
			   ts.current_season as end_season
		FROM this_season_data ts
			 JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE ls.player_name = ts.player_name
				AND ts.is_active = ls.is_active
	),
	changed_records AS (
		SELECT ts.player_name,
			   UNNEST(ARRAY [               
					ROW(
						 ls.scoring_class,
						 ls.is_active,
						 ls.start_season,
						 ls.end_season

					   )::scd_type,
					 ROW(
						 ts.scoring_class,
						 ts.is_active,
						 ts.current_season,
						 ts.current_season
						 
					   )::scd_type
			   ]) as records
		FROM this_season_data ts
			 LEFT JOIN last_season_scd ls
			 ON ts.player_name = ls.player_name
			 	WHERE (ls.player_name <> ts.player_name)
				OR ts.is_active <> ls.is_active
				
	),
	unnested_changed_records AS (
		SELECT player_name,
			   (records::scd_type).scoring_class,
			   (records::scd_type).is_active,
			   (records::scd_type).start_season,
			   (records::scd_type).end_season
	 	FROM changed_records
	),
	new_records AS (

		SELECT ts.player_name,
			   ts.scoring_class,
			   ts.is_active,
			   ts.current_season AS start_season,
			   ts.current_season AS end_season
		FROM this_season_data ts
		LEFT JOIN last_season_scd ls
		ON ts.player_name = ls.player_name
			 	WHERE ls.player_name IS NULL
	)



SELECT * FROM historical_scd
UNION ALL

SELECT * FROM unchanged_records
UNION ALL

SELECT * FROM unnested_changed_records
UNION ALL

SELECT * FROM new_records

