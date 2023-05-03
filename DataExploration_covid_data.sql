--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------
--                             Data Exploration Project                            --
--------------------------------------------------------------------------------------
--------------------------------------------------------------------------------------



--------------------------------------------------------------------------------------
--                         CREATE COVID DEATH DATA TABLE                            --
--------------------------------------------------------------------------------------
CREATE TABLE BootcampDB.covidDeath_data
AS SELECT iso_code,
continent, 
location, 
population,
date,
total_cases,
new_cases,
new_cases_smoothed,
total_deaths,
new_deaths,
new_deaths_smoothed,
total_cases_per_million,
new_cases_per_million,
new_cases_smoothed_per_million,
total_deaths_per_million,
new_deaths_per_million,
new_deaths_smoothed_per_million,
reproduction_rate,
icu_patients,
icu_patients_per_million,
hosp_patients,
hosp_patients_per_million,
weekly_icu_admissions,
weekly_icu_admissions_per_million,
weekly_hosp_admissions,
weekly_hosp_admissions_per_million

FROM BootcampDB.covid_data;



--------------------------------------------------------------------------------------
--                       CREATE COVID VACCINATION DATA TABLES                       --
--------------------------------------------------------------------------------------
CREATE TABLE BootcampDB.covidVaccination_data
AS SELECT iso_code,
continent,
location,
date,
total_tests,
new_tests,
total_tests_per_thousand,
new_tests_per_thousand,
new_tests_smoothed,
new_tests_smoothed_per_thousand,
positive_rate,
tests_per_case,
tests_units,
total_vaccinations,
people_vaccinated,
people_fully_vaccinated,
total_boosters,
new_vaccinations,
new_vaccinations_smoothed,
total_vaccinations_per_hundred,
people_vaccinated_per_hundred,
people_fully_vaccinated_per_hundred,
total_boosters_per_hundred,
new_vaccinations_smoothed_per_million,
new_people_vaccinated_smoothed,
new_people_vaccinated_smoothed_per_hundred,
stringency_index,
population_density,
median_age,
aged_65_older,
aged_70_older,
gdp_per_capita,
extreme_poverty,
cardiovasc_death_rate,
diabetes_prevalence,
female_smokers,
male_smokers,
handwashing_facilities,
hospital_beds_per_thousand,
life_expectancy,
human_development_index,
excess_mortality_cumulative_absolute,
excess_mortality_cumulative,
excess_mortality,
excess_mortality_cumulative_per_million

FROM BootcampDB.covid_data;

--------------------------------------------------------------------------------------
--              SELECTING COVID DEATH DATA WE'RE INTERESTED IN                      --
--------------------------------------------------------------------------------------
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM BootcampDB.covidDeath_data cdd;

--------------------------------------------------------------------------------------
--                       TOTAL CASES V. TOTAL DEATH                                 --         
--------------------------------------------------------------------------------------
-- shows the likihood of dying if you contract covid in your country (rough estimates)
SELECT location, date, total_cases, total_deaths, 
       (total_deaths/total_cases)*100 AS death_percentage
FROM BootcampDB.covidDeath_data cdd
ORDER BY 1,2;
	
-- death percentage specifically in the United States
SELECT location, date, total_cases, total_deaths, 
       (total_deaths/total_cases)*100 AS death_percentage
FROM BootcampDB.covidDeath_data cdd
WHERE location like '%states%'
ORDER BY 1,2;
	
-- highest rates of death by day 
SELECT date, MAX(((total_deaths/total_cases)*100)) AS max_death
FROM BootcampDB.covidDeath_data cdd
WHERE location like '%states%'
GROUP BY date
ORDER BY 2 DESC;
	-- shows that the highest rates of death occurred in the summer of 2020 at almost 8.7%

--------------------------------------------------------------------------------------
--                       TOTAL CASES V. POPULATION                                  --         
--------------------------------------------------------------------------------------
-- percentageS of the population has gotten covid
SELECT location, date, total_cases, population, (total_cases/population)*100 AS cases_percentage
FROM BootcampDB.covidDeath_data cdd
WHERE location = 'United States'
ORDER BY date DESC;

-- what countries have greatest/highest infection rate compare to population
SELECT location, population, 
		MAX(total_cases) as highest_infection_count, 
		MAX((total_cases/population))*100 AS percent_population_infected
FROM BootcampDB.covidDeath_data cdd
GROUP BY location, population
ORDER BY 4 DESC;

--------------------------------------------------------------------------------------
--                  BREAK DOWN OF TOTAL DEATH COUNT BY CONTINENT                    --
-------------------------------------------------------------------------------------- 
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
--------------------------------------------------------------------------------------
--                       RESEARCHING CONTINENT COUNTS                               --
--------------------------------------------------------------------------------------
-- using a CTE to see if the totals are equal to the total world deaths

WITH continents AS
	(SELECT location , MAX(total_deaths) as total_death_count
	FROM BootcampDB.covidDeath_data cdd
	WHERE continent IS NULL 
	AND location NOT IN ('Lower middle income', 'Low income', 'High Income', 'Upper middle income')
	GROUP BY location)
SELECT SUM(total_death_count)
FROM continents
WHERE location NOT IN ('World','European Union');
-- this number matches with the total number of deaths in the world, off by about 5 (not significant)
	
--------------------------------------------------------------------------------------
/*
Researched which countries were in European Union verus Non-European Union and then 
isolated and calculating the sums for each to clarify that the results of the 
previous query are accurate.
*/
--------------------------------------------------------------------------------------
-- checking european uniion numbers 
WITH EU AS (SELECT location, MAX(total_deaths) as total_death_count
FROM BootcampDB.covidDeath_data cdd
WHERE location in ('Austria','Belgium','Bulgaria','Croatia','Cyprus', 'Northern Cyprus', 'Czechia','Denmark','Estonia',
					'Finland','France','Germany','Hungary','Ireland','Italy','Latavia','Lithuania','Luxembourg',
					'Malta','Netherlands','Poland','Portugal','Romania','Slovokia','Spain','Sweden') -- countries in EU
GROUP BY location)
SELECT SUM(total_death_count)
FROM EU;
-- total death in European Union: 1,150,459 
--------------------------------------------------------------------------------------
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
--------------------------------------------------------------------------------------
--                              RESEARCH CONCLUSIONS                                --
--------------------------------------------------------------------------------------
* total for Europe = 2,038,559 
* total for EU + non-EU = 1,150,459 + 929,829 = 2,080,288
* these numbers are roughly the same possibly missing one country in the automatic Europe count via issue
     with labelling
* difference of 41,759
* also proves that european union does need to be include in a query about contients because theres 
* counting overlap just like with world

--------------------------------------------------------------------------------------
--                              GLOBAL NUMBERS                                --
--------------------------------------------------------------------------------------
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

-- joining both tables check
SELECT *
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date

-- looking at global population v vaccination
SELECT cdd.continent, cdd.location, cdd.date, cdd.population, cvd.new_vaccinations 
FROM BootcampDB.covidDeath_data cdd 
JOIN BootcampDB.covidVaccination_data cvd 
ON cdd.location = cvd.location 
AND cdd.date = cvd.date
WHERE cdd.continent IS NOT NULL 
ORDER BY 2,3 

 
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
--------------------------------------------------------------------------------------
--                              CREATING A VIEW                                     --
--------------------------------------------------------------------------------------
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


