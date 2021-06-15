/* QUESTION 1
What are the top 10 family movies based on rental count?
*/

WITH sub AS (SELECT f.title Title, c.name category, 
                    CASE WHEN c.name IN ('Animation','Children','Classics','Comedy','Family','Music') THEN 'Family' ELSE 'Not Family' END AS family_movie, r.rental_id rental_id
               FROM inventory i
                     JOIN rental r
                       ON r.inventory_id = i.inventory_id

                     JOIN film f
                       ON i.film_id = f.film_id

                     JOIN film_category fc
                       ON fc.film_id = f.film_id

                     JOIN category c
                       ON fc.category_id = c.category_id
                     ORDER BY 2,1)

SELECT DISTINCT sub.title, sub.category,
                COUNT(sub.rental_id) OVER (Partition BY sub.title) AS rental_count
  FROM sub
 WHERE sub.family_movie = 'Family'
 ORDER BY 3 DESC

/* QUESTION 2
What is the count of movies per quartile based on rental duration, for all family friendly movie categories?
*/

WITH sub AS (SELECT f.title Title, f.rental_duration rental_duration, c.name category, 
                    CASE WHEN c.name IN ('Animation','Children','Classics','Comedy','Family','Music') THEN 'Family' 
                         ELSE 'Not Family' 
                     END AS family_movie
               FROM film f
                     JOIN film_category fc
                       ON fc.film_id = f.film_id

                     JOIN category c
                       ON c.category_id = fc.category_id),
     sub2 AS (SELECT sub.title,
                     sub.category,
                     sub.family_movie,
                     sub.rental_duration, 
                     NTILE(4) OVER (ORDER BY rental_duration) AS standard_quartile
                FROM sub
               WHERE family_movie = 'Family') 

SELECT category, standard_quartile, COUNT(title)
  FROM sub2
 GROUP BY 1,2
 ORDER BY 1,2

/* QUESTION 3
What is the number of rental orders each store has fulfilled for each month?
*/

SELECT DATE_PART('month',r.rental_date) rental_month, 
       DATE_PART('year',r.rental_date) rental_year,
       s.store_id, 
       COUNT(r.rental_id)
  FROM rental r
       JOIN staff st
         ON r.staff_id = st.staff_id

       JOIN store s
         ON s.store_id = st.store_id
 GROUP BY 1,2,3
 ORDER BY 4 DESC

/* QUESTION 4
For Top 10 paying customers, what is the difference across their monthly payments during 2007?
*/

WITH sub AS (SELECT CONCAT(c.first_name,' ',c.last_name) AS Name,
                    p.customer_id AS customer_id,
                    SUM(p.amount) AS Lifetime_amount
               FROM payment p
                     JOIN customer c
                       ON c.customer_id = p.customer_id
              GROUP BY 1,2
              ORDER BY 3 DESC
              LIMIT 10), 
     sub2 AS (SELECT DISTINCT DATE_TRUNC('month',p.payment_date) AS pay_mon,
                              sub.name AS name,
                              COUNT(p.payment_id) OVER (PARTITION BY sub.name,DATE_TRUNC('month',p.payment_date)) AS pay_countpermon,
                              SUM(p.amount) OVER (PARTITION BY sub.name,DATE_TRUNC('month',p.payment_date)) AS pay_amount
                FROM payment p
                     JOIN sub
                       ON sub.customer_id = p.customer_id
               ORDER BY 2,1)

SELECT *,LAG(sub2.pay_amount) OVER (PARTITION BY sub2.name ORDER BY 2,1) AS lag,
       sub2.pay_amount - LAG(sub2.pay_amount) OVER (PARTITION BY sub2.name ORDER BY 2,1) AS lag_difference
  FROM sub2     