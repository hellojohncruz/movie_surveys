-- Drop survey table if it exists and create a new one from CSV file
DROP TABLE IF EXISTS public.surveys CASCADE;

CREATE TABLE IF NOT EXISTS public.surveys
(
    "Timestamp" timestamp with time zone,
    "Avengers: Endgame (2019)" character(70) COLLATE pg_catalog."default",
    "The Lion King (2019)" character(70) COLLATE pg_catalog."default",
    "Joker (2019)" character(70) COLLATE pg_catalog."default",
    "Everything Everywhere All at Once (2022)" character(70) COLLATE pg_catalog."default",
    "The Matrix Resurrections (2021)" character(70) COLLATE pg_catalog."default",
    "King Richard (2021)" character(70) COLLATE pg_catalog."default"
)

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.surveys
    OWNER to postgres;

-- Access CSV from path
copy surveys from 'CSV survey filepath' delimiter ',' HEADER csv;

-- Add new column for each user who submitted a survey
ALTER TABLE public.surveys
	ADD COLUMN user_id serial NOT NULL;
	
-- Update user_id column to become PK
ALTER TABLE public.surveys
	ADD PRIMARY KEY (user_id);

-------------------------------------------------------------------------------------

-- Create a new table for the films and its release year listed in each column header. 
DROP TABLE IF EXISTS public.films CASCADE;

CREATE TABLE public.films
(
    movie_id serial NOT NULL,
    name character(75),
	release_year integer,
    PRIMARY KEY (movie_id)
);

INSERT INTO 
	public.films(name, release_year)
SELECT 
	movie_name,
	CAST(release_year AS INTEGER) AS release_year
FROM(
	SELECT 
		SPLIT_PART(column_name, '(', 1) AS movie_name,
		SPLIT_PART(SPLIT_PART(column_name, '(', 2), ')', 1) AS release_year
	FROM information_schema.columns
	WHERE table_schema = 'public'
		AND table_name   = 'surveys'
	ORDER BY release_year
	OFFSET 2
	) AS t1
;

-------------------------------------------------------------------------------------

-- Create ratings table from original survey table by unpivoting the columns and 'melting' them to long format. 

DROP TABLE IF EXISTS public.ratings CASCADE;

CREATE TABLE public.ratings
(
    survey_id serial NOT NULL,
	datetimeid timestamp with time zone,
	user_id integer,
	rating integer,
    PRIMARY KEY (survey_id),
	movie_id integer REFERENCES films (movie_id)
);

INSERT INTO 
	public.ratings(datetimeid, user_id, movie_id, rating)
SELECT
	datetimeid,
	user_id,
	movie_id,
	CASE 
		WHEN txt_rating LIKE '[N/A]' THEN 0
		ELSE CAST(txt_rating AS integer) 
	END AS rating	
FROM(
	SELECT 
		"Timestamp" AS datetimeid,
		user_id, 
		movie_id,
		SPLIT_PART(full_rating, ' ', 1) AS txt_rating
	FROM(
		SELECT s."Timestamp", s.user_id, val.*
		FROM surveys s,
		LATERAL(
			VALUES
				(1, s."Avengers: Endgame (2019)"),
				(2, s."The Lion King (2019)"),
				(3, s."Joker (2019)"),
				(4, s."Everything Everywhere All at Once (2022)"),
				(5, s."The Matrix Resurrections (2021)"),
				(6, s."King Richard (2021)")
			) AS val (movie_id, full_rating)
	) AS t1
) AS t2
;