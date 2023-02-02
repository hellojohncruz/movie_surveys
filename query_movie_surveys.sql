SELECT
	r.datetimeid,
	r.user_id,
	f.name,
	r.rating,
	f.release_year
FROM ratings r
INNER JOIN films f
	ON r.movie_id = f.movie_id
	