-------------------------------------- Data Exploration Project-----------------------------------------

SELECT *
FROM BootcampDB.covidDeath_data cdd 
WHERE continent is not null -- where continent is null we get the entire contient (not what we want)
ORDER BY 3,4 -- location and date

SELECT * 
FROM BootcampDB.covidVaccination_data cvd 
ORDER BY 3,4;
---------------------------------------------------------------------------------------------------------

-- select data that we're going to be using


SELECT location, date, total_cases, new_cases, total_deaths, population
FROM BootcampDB.covidDeath_data cdd;

---------------------------------------------------------------------------------------------------------


-- looking at total cases v total deaths
-- shows the likihood of dying if you contract covid in your country (rough estimates)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM BootcampDB.covidDeath_data cdd
ORDER BY 1,2;
	/*eg. if we go to row with most recent data on location like afghanistan we see that death percentage is ~ 3.7 
	 *    therefore there's currently a 3.7% chance of death if you contract covid-19 and live in afghanistan*/
---------------------------------------------------------------------------------------------------------

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM BootcampDB.covidDeath_data cdd
WHERE location like '%states%'
ORDER BY 1,2;
	-- USA data showing that at of 4/12/23 death percentage ~ 1.09, even lower than that of afghanistan
---------------------------------------------------------------------------------------------------------

SELECT date, MAX(((total_deaths/total_cases)*100)) AS max_death
FROM BootcampDB.covidDeath_data cdd
WHERE location like '%states%'
GROUP BY date
ORDER BY 2 DESC;
	-- shows that the highest rates of death occurred in the summer of 2020 at almost 8.7%

---------------------------------------------------------------------------------------------------------
-- total case v population
-- what percentage of the population has gotten covid

SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM BootcampDB.covidDeath_data cdd
WHERE location = 'United States'
ORDER BY date DESC;


---------------------------------------------------------------------------------------------------------
-- what countries have greatest/highest infection rate compare to population
SELECT location, population, 
		MAX(total_cases) as highest_infection_count, 
		MAX((total_cases/population))*100 AS percent_population_infected
FROM BootcampDB.covidDeath_data cdd
GROUP BY location, population
ORDER BY 4 DESC;

---------------------------------------------------------------------------------------------------------
                           Break down total death counts by continent
--------------------------------------------------------------------------------------------------------- 
SELECT location , MAX(total_deaths) as total_death_count
FROM BootcampDB.covidDeath_data cdd
WHERE continent IS NULL AND location NOT IN ('Lower middle income', 'Low income', 'High Income', 'Upper middle income')
GROUP BY location 
ORDER BY 2 DESC;

/* this shows total deaths as of date data was downloaded by continent excluding breakdown by income
 * it still includes counts for World and European Union which are not continents so I want to explore
 *     this further
 * Because I am not sure if the Europe count includes European Union or is meant to show counts for 
 * countries outside of the European Union I want to investigate. I am exploring this for the purpose
 * of accuracy. If the counts for Europe are inclusive of countries within the the European Union
 * we don't need the European Union counts specifically. We also don't need to include World counts 
 * when we're solely concerned with continental total but it is useful to know becasue we can sum all 
 * continents and then use it as a reference.
 */
---------------------------------------------------------------------------------------------------------
                                  Researching Continent Counts
---------------------------------------------------------------------------------------------------------

WITH continents AS
	(SELECT location , MAX(total_deaths) as total_death_count
	FROM BootcampDB.covidDeath_data cdd
	WHERE continent IS NULL 
	AND location NOT IN ('Lower middle income', 'Low income', 'High Income', 'Upper middle income')
	GROUP BY location)
SELECT SUM(total_death_count)
FROM continents
WHERE location NOT IN ('World','European Union');
	/*
	 * -- this number matches with the total number of deaths in the world, off by about 5 (not significant)
	 */
---------------------------------------------------------------------------------------------------------
         Researching which countries were European Union verus Non-European Union and then isolated and 
         calculating the sums for each to clarify that the results of the previous query are accurate
---------------------------------------------------------------------------------------------------------

-- checking europenan uniion numbers 
WITH EU AS (SELECT location, MAX(total_deaths) as total_death_count
FROM BootcampDB.covidDeath_data cdd
WHERE location in ('Austria','Belgium','Bulgaria','Croatia','Cyprus', 'Northern Cyprus', 'Czechia','Denmark','Estonia',
					'Finland','France','Germany','Hungary','Ireland','Italy','Latavia','Lithuania','Luxembourg',
					'Malta','Netherlands','Poland','Portugal','Romania','Slovokia','Spain','Sweden') -- countries in EU
GROUP BY location)
SELECT SUM(total_death_count)
FROM EU;
-- total death in European Union: 1,150,459 
---------------------------------------------------------------------------------------------------------
-- checking non-EU numbers
WITH non_EU AS (SELECT location,MAX(total_deaths) as total_death_count
FROM BootcampDB.covidDeath_data cdd
WHERE location in ('Albania','Andorra','Armenia','Azerbaijan','Belarus','Bosnia and Herzegovina','Georgia',
'Iceland','Kosovo','Liechtenstein','Monaco','Montenegro','Norway','Russia','Serbia',
'Switzerland','Turkey','Ukraine','United Kingdom') -- non-EU countries
GROUP BY location)
SELECT SUM(total_death_count) AS total_death_count_NON_EU
FROM non_EU;

-- total death in non-European Union: 929,829
---------------------------------------------------------------------------------------------------------
                                         Research Conclusion
---------------------------------------------------------------------------------------------------------
* total for Europe = 2,038,559 
* total for EU + non-EU = 1,150,459 + 929,829 = 2,080,288
* these numbers are roughly the same possibly missing one country in the automatic Europe count via issue
     with labelling
* difference of 41,759
* also proves that european union does need to be include in a query about contients because theres 
* counting overlap just like with world

---------------------------------------------------------------------------------------------------------
-- global numbers
---------------------------------------------------------------------------------------------------------

-- sum of all new cases = total cases
SELECT date, SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage 
FROM BootcampDB.covidDeath_data cdd  
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2;
  -- gives total globally on a day

-- total cases globally and
SELECT SUM(new_cases) AS total_cases, SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(new_cases)*100 AS death_percentage 
FROM BootcampDB.covidDeath_data cdd  
WHERE continent IS NOT NULL
ORDER BY 1,2;
---------------------------------------------------------------------------------------------------------
-- joining both tables check
SELECT *
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date

---------------------------------------------------------------------------------------------------------
-- looking at global population v vaccination
SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations 
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3 

 


---------------------------------------------------------------------------------------------------------
 -- using new vaccinations per day instead of total vaccination
 -- we want to do a rolling count
-- as new vaccinations increase we the number to grow in the column to it's right
-- using partition by, windows function
	-- partiton by is used to to divide the result set into partitions and perform computation
	-- on each subset of partitioned data
SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations,
SUM(cvd.new_vaccinations) OVER (PARTITION BY cdd.location ORDER BY cdd.location, cdd.date) AS rolling_count_vaxed -- want the count to restart everytime it's at new location
	-- date seperates in out 
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3
---------------------------------------------------------------------------------------------------------
-- looking at total population v vaccination
-- using CTE 
WITH pop_vaxed AS (SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations,
       SUM(cvd.new_vaccinations) OVER (PARTITION BY cdd.location ORDER BY cdd.location, cdd.date) AS rolling_count_vaxed
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3)
-- rolling number of percent vaxed
SELECT *, (rolling_count_vaxed/population)*100 AS rolling_pct_vaxed
FROM pop_vaxed
---------------------------------------------------------------------------------------------------------
/*-- temp table version 
DROP TEMPORARY TABLE IF EXISTS pct_vaxed;

CREATE TEMPORARY TABLE pct_vaxed (
  continent varchar(50),
  location varchar(50),
  date datetime,
  population double, 
  new_vaccinations varchar(50,
  rolling_count_vaxed varchar(50)
);

INSERT INTO pct_vaxed
SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations,
       SUM(cvd.new_vaccinations) OVER (PARTITION BY cdd.location ORDER BY cdd.location, cdd.date) AS rolling_count_vaxed
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3;

-- rolling number of percent vaxed
SELECT *, (rolling_count_vaxed/population)*100 AS rolling_pct_vaxed
FROM pct_vaxed

		-- COULD NOT GET THIS TO WORK */
---------------------------------------------------------------------------------------------------------
-- creating view to store data for late viz
CREATE VIEW pct_pop_vaxed AS
SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations,
       SUM(cvd.new_vaccinations) OVER (PARTITION BY cdd.location ORDER BY cdd.location, cdd.date) AS rolling_count_vaxed
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3
 -- can create more view to work from 
 -- can connect tableau to a view (with full version)
---------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------

