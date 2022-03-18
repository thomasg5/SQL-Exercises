-- SQL SERVER EXERCISES
-- Data source: https://www.kaggle.com/silicon99/dft-accident-data

-- SOLUTIONS

--1) How many accidents happened per accident severity?

SELECT Accident_Severity, COUNT(*) AS count_accid 
FROM Accidents
GROUP BY Accident_Severity
ORDER BY Accident_Severity;


--2) What was the severity of the accident with most vehicles involved?

SELECT Accident_Index, Accident_Severity, Number_of_Vehicles 
FROM Accidents
WHERE Number_of_Vehicles IN (SELECT MAX(Number_of_Vehicles) FROM Accidents);


--3) How many casualties occurred between January and April in 2006?

SELECT COUNT(*) AS casualties_count
FROM Casualties 
INNER JOIN Accidents ON Casualties.Accident_Index = Accidents.Accident_Index
WHERE Accidents.Date BETWEEN '2006-01-01' AND '2006-04-30';


--4) What were the top 3 months per year with the most accidents?

WITH tb1 AS (
SELECT year, month, COUNT(*) AS count_accid, ROW_NUMBER() OVER(PARTITION BY year ORDER BY COUNT(*) DESC) AS rk
FROM (
	SELECT *, FORMAT(Date, 'MMMM') AS month, YEAR(Date) AS year
	FROM Accidents
	) AS temp
GROUP BY year, month
)

SELECT * FROM tb1 WHERE rk < 4;


--5) What was the percentage of accidents in urban and rural accidents?

DECLARE @total REAL;
SET @total = (SELECT COUNT(*) FROM Accidents);

SELECT LocalType, COUNT(*) AS count_accid, ROUND(COUNT(*) / @total, 2) AS perct 
FROM (SELECT *, CASE WHEN Urban_or_Rural_Area = 1 THEN 'Urban' WHEN Urban_or_Rural_Area = 2 THEN 'Rural' ELSE '' END AS LocalType
		FROM Accidents
		WHERE Urban_or_Rural_Area <> 3) AS temp
GROUP BY LocalType;


--6) Which accidents involved three or more casualties from the same age band (ignoring -1 records)?

SELECT DISTINCT Accident_Index, Age_Band_of_Casualty 
FROM (
	SELECT Accident_Index, Age_Band_of_Casualty, CASE WHEN LEAD(Accident_Index) OVER(ORDER BY Accident_Index) = Accident_Index 
		AND LEAD(Age_Band_of_Casualty) OVER(ORDER BY Accident_Index) = Age_Band_of_Casualty 
		AND LEAD(Age_Band_of_Casualty, 2) OVER(ORDER BY Accident_Index) = Age_Band_of_Casualty THEN 'Match'
		ELSE 'Not' END AS checker
	FROM Casualties
	WHERE Age_Band_of_Casualty <> -1) AS temp
WHERE checker = 'Match';


--7) What was the average age among casualties on bike accidents with at least 5 victims?

SELECT C.Accident_Index, AVG(Age_of_Casualty) AS avg_age 
FROM Casualties AS C
INNER JOIN Vehicles AS V ON C.Accident_Index = V.Accident_Index
WHERE V.Vehicle_Type = 1 AND C.Accident_Index IN (SELECT Accident_Index FROM Casualties GROUP BY Accident_Index HAVING COUNT(*) > 4)
GROUP BY C.Accident_Index;


--8) What was the amount of fatal casualties in accidents occurred at roads with 30 km/h speed limit?

SELECT COUNT(C.Accident_Index) AS fatal_count
FROM Accidents AS A
INNER JOIN Casualties AS C ON A.Accident_Index = C.Accident_Index
WHERE C.Casualty_Severity = 1 AND A.Speed_limit = 30;


--9) Among accidents involving only 1 car, dense rank the top 5 engine capacity per driver age band (ignoring -1 records in both fields).

WITH tb1 AS (
	SELECT V.Age_Band_of_Driver, temp.Engine_Capacity_CC, DENSE_RANK() OVER(PARTITION BY V.Age_Band_of_Driver ORDER BY temp.Engine_Capacity_CC DESC) AS rk
	FROM (
		SELECT Accident_Index, Engine_Capacity_CC, COUNT(*) AS count_accid
		FROM Vehicles
		WHERE Vehicle_Type = 9 AND Engine_Capacity_CC <> -1
		GROUP BY Accident_Index, Engine_Capacity_CC
		) AS temp
	INNER JOIN Vehicles AS V ON temp.Accident_Index = V.Accident_Index
	WHERE count_accid = 1 AND V.Age_Band_of_Driver <> -1
	GROUP BY V.Age_Band_of_Driver, temp.Engine_Capacity_CC
)

SELECT * FROM tb1 WHERE rk < 6
ORDER BY Age_Band_of_Driver, Engine_Capacity_CC DESC;


--10) Which accidents involved different vehicle types including type n� 23?

SELECT DISTINCT A.Accident_Index, A.Vehicle_Type AS first_vehicle, B.Vehicle_Type AS second_vehicle FROM Vehicles AS A, Vehicles AS B
WHERE A.Accident_Index = B.Accident_Index AND A.Vehicle_Type <> B.Vehicle_Type AND A.Vehicle_Type = 23;
