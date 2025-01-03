-- Creating the custom type 'films' with fields 'film', 'rating', 'votes', and 'filmid'
CREATE TYPE films AS (
    film TEXT,
    rating FLOAT,
    votes INT,
    filmid INT
);
-- Creating the enum type 'quality_class' with possible values
CREATE TYPE quality_class AS ENUM ('star', 'good', 'average', 'bad');
CREATE TABLE actors (
    actor_id SERIAL PRIMARY KEY,
    actor_name VARCHAR(100),  -- Single column for actor name
    films films[],  -- An array of custom type 'films'
    quality_class quality_class,  -- Using the custom enum type 'quality_class'
    is_active BOOLEAN
);
WITH 
years AS (
    SELECT generate_series(MIN(year), MAX(year)) AS season
    FROM actor_films
),
p AS (
    SELECT
        actor AS actor_name,
        MIN(year) AS first_season
    FROM actor_films
    GROUP BY actor
), 
actors_and_seasons AS (
    SELECT *
    FROM p
    JOIN years y
        ON p.first_season <= y.season
), 
films_agg AS (
    SELECT
        aas.actor_name,
        aas.season,
        ARRAY_REMOVE(
            ARRAY_AGG(
                CASE
                    WHEN af.season IS NOT NULL
                        THEN ROW(
                            af.film,
                            af.rating,
                            af.votes,
                            af.filmid
                        )::films
                END)
            OVER (PARTITION BY aas.actor_name ORDER BY COALESCE(aas.season, af.year)),
            NULL
        ) AS films
    FROM actors_and_seasons aas
    LEFT JOIN actor_films af
        ON aas.actor_name = af.actor
        AND aas.season = af.year
    ORDER BY aas.actor_name, aas.season
), 
static AS (
    SELECT
        actor AS actor_name,
        AVG(rating) AS avg_rating,
        BOOL_OR(EXTRACT(YEAR FROM CURRENT_DATE) = year) AS is_active
    FROM actor_films
    GROUP BY actor
)
INSERT INTO actors (actor_name, films, quality_class, is_active)
SELECT
    f.actor_name,
    f.films,
    CASE
        WHEN s.avg_rating > 8 THEN 'star'
        WHEN s.avg_rating > 7 THEN 'good'
        WHEN s.avg_rating > 6 THEN 'average'
        ELSE 'bad'
    END::quality_class AS quality_class,
    s.is_active
FROM films_agg f
JOIN static s
    ON f.actor_name = s.actor_name;

CREATE TABLE actors_history_scd (
    actor_id INT,
    actor_name VARCHAR(100),  -- Single column for actor name
    films films[],  -- An array of custom type 'films'
    quality_class quality_class,  -- Using the custom enum type 'quality_class'
    is_active BOOLEAN,
    start_date DATE,
    end_date DATE,
    PRIMARY KEY (actor_id, start_date),
    FOREIGN KEY (actor_id) REFERENCES actors(actor_id)
);

--backfill query
INSERT INTO actors_history_scd (actor_id, actor_name, films, quality_class, is_active, start_date, end_date)
SELECT actor_id, actor_name, films, quality_class, is_active, CURRENT_DATE, NULL
FROM actors;

-- Incremental query Close out the previous active records
UPDATE actors_history_scd
SET end_date = CURRENT_DATE
WHERE end_date IS NULL
AND actor_id IN (SELECT actor_id FROM actors);

-- Insert new records
INSERT INTO actors_history_scd (actor_id, actor_name, films, quality_class, is_active, start_date, end_date)
SELECT actor_id, actor_name, films, quality_class, is_active, CURRENT_DATE, NULL
FROM actors;