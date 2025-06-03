/* ----------------------------------------------------------------------------------
 Title:         World Life Expectancy Project
 Author:        Scott Solik
 Last Modified: April 22, 2025
 Description:   Data Cleaning and Exploratory Date Analysis on dataset containing 
                life expectancy data for 193 countries from 2007 - 2022
-------------------------------------------------------------------------------------*/

/*---------------------------------------------
World Life Expectancy Project: Data Cleaning
----------------------------------------------*/

-- Import data using Table Date Import Wizard

-- Validate successful data load
SELECT *
FROM world_life_expectancy;

-- Rename column to simplify syntax
ALTER TABLE world_life_expectancy RENAME COLUMN `Life expectancy` TO `Life_expectancy`;

-- Identify duplicates: Ensure there is only one row per country, per year
SELECT country, year, CONCAT(country, year), COUNT(CONCAT(Country, Year))
FROM world_life_expectancy
GROUP BY country, year, CONCAT(country, year)
HAVING COUNT(CONCAT(Country, Year)) > 1;

-- Delete duplicate rows
DELETE FROM world_life_expectancy
WHERE row_id IN (
	SELECT row_id
	FROM (
		SELECT row_id, 
		ROW_NUMBER() OVER(PARTITION BY CONCAT(country, year) ORDER BY CONCAT(country, year)) AS row_num
		FROM world_life_expectancy
		) AS row_table
		WHERE row_num > 1
);

-- Identify records with blank Status field
SELECT *
FROM world_life_expectancy
WHERE status = '';

-- Impute missing Status values using records for the same country from other years
UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
SET t1.status = 'Developing'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developing';

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
SET t1.status = 'Developed'
WHERE t1.status = ''
AND t2.status <> ''
AND t2.status = 'Developed';

-- Identify records with blank Life_expectancy field
SELECT *
FROM world_life_expectancy
WHERE Life_expectancy = '';

-- Impute missing Life_expectancy values using the average Life_expectancy values for that country from the year before and the year after
SELECT 
	t1.Country, 
    t1.year, 
    t1.Life_expectancy,
    t2.Country, 
    t2.year, 
    t2.Life_expectancy,
	t3.Country, 
    t3.year, 
    t3.Life_expectancy,
    ROUND(((t2.Life_expectancy + t3.Life_expectancy) / 2),1) AS avg
FROM world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1
JOIN world_life_expectancy t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1
WHERE t1.Life_expectancy = '';

UPDATE world_life_expectancy t1
JOIN world_life_expectancy t2
	ON t1.country = t2.country
    AND t1.year = t2.year - 1
JOIN world_life_expectancy t3
	ON t1.country = t3.country
    AND t1.year = t3.year + 1
SET t1.Life_expectancy = ROUND(((t2.Life_expectancy + t3.Life_expectancy) / 2),1)
WHERE t1.Life_expectancy = '';


/* ----------------------------------------------------------------------
World Life Expectancy Project: Exploratory Data Analysis (2007 - 2022)
-------------------------------------------------------------------------*/

-- Preview the dataset
SELECT * FROM world_life_expectancy;

-- Determine the range of years covered
SELECT MAX(year), MIN(year), MAX(year) - MIN(year) AS number_of_years FROM world_life_expectancy;

-- Count how many unique countries are included (expected: 193)
SELECT COUNT(DISTINCT(country)) FROM world_life_expectancy;

-- For each country, show the min and max life expectancy (excluding invalid zero values)
SELECT country, MIN(Life_expectancy), MAX(Life_expectancy)
FROM world_life_expectancy
GROUP BY country
HAVING MIN(Life_expectancy) <> 0 AND MAX(Life_expectancy) <> 0
ORDER BY country DESC;

-- Show life expectancy change per country over time
SELECT country, MIN(Life_expectancy), MAX(Life_expectancy),
ROUND(MAX(Life_expectancy) - MIN(Life_expectancy),1) AS life_ex_change
FROM world_life_expectancy
GROUP BY country
HAVING MIN(Life_expectancy) <> 0 AND MAX(Life_expectancy) <> 0
ORDER BY life_ex_change ASC;

-- Identify the country with the highest life expectancy
SELECT country, MIN(Life_expectancy), MAX(Life_expectancy)
FROM world_life_expectancy
GROUP BY country
HAVING MIN(Life_expectancy) <> 0 AND MAX(Life_expectancy) <> 0
ORDER BY MAX(Life_expectancy) DESC;

-- Show average life expectancy globally by year
SELECT year, ROUND(AVG(Life_expectancy),2) AS avg_life_expectancy
FROM world_life_expectancy
WHERE Life_expectancy <> 0
GROUP BY year
ORDER BY year;

-- Check average life expectancy vs average GDP per country
SELECT country, ROUND(AVG(Life_expectancy),2) AS avg_life_ex, ROUND(AVG(gdp),1) AS avg_gdp
FROM world_life_expectancy
GROUP BY country
HAVING avg_life_ex <> 0 AND avg_gdp <> 0
ORDER BY avg_life_ex DESC;

-- GDP group comparison using CASE statement (high/low GDP and corresponding life expectancy)
SELECT
    SUM(CASE WHEN gdp >= 1500 THEN 1 ELSE 0 END) AS High_GDP_Count,
    AVG(CASE WHEN gdp >= 1500 THEN Life_expectancy ELSE NULL END) AS High_GDP_Life_Expectancy,
    SUM(CASE WHEN gdp <= 1500 THEN 1 ELSE 0 END) AS Low_GDP_Count,
    AVG(CASE WHEN gdp <= 1500 THEN Life_expectancy ELSE NULL END) AS Low_GDP_Life_Expectancy
FROM world_life_expectancy;

-- Compare average life expectancy by development status (Developed vs Developing)
SELECT status, ROUND(AVG(Life_expectancy),1) AS avg_life_expectancy
FROM world_life_expectancy
GROUP BY status;

-- Count countries by development status
SELECT status, COUNT(DISTINCT Country) AS country_count
FROM world_life_expectancy
GROUP BY status;

-- Show average life expectancy and number of countries per development status
SELECT status, COUNT(DISTINCT Country) AS country_count, ROUND(AVG(Life_expectancy),1) AS avg_life_expectancy
FROM world_life_expectancy
GROUP BY status;

-- Track adult mortality trends using rolling totals per country
SELECT Country, year, Life_expectancy, `Adult Mortality`,
SUM(`Adult Mortality`) OVER(PARTITION BY country ORDER BY year) AS rolling_total
FROM world_life_expectancy;

/* ---------------------------------------------------
   Export output to csv to visualize in Tableau
------------------------------------------------------*/