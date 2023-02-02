SELECT
	f.name,
	f.release_year, 
	ROUND(AVG(r.rating), 2) AS avg_rating,
	
	COUNT(user_id) AS num_of_votes
FROM ratings r
INNER JOIN films f
	ON r.movie_id = f.movie_id
WHERE r.rating IS NOT NULL
GROUP BY 1, 2
ORDER BY 3 DESC
	