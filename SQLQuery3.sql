SELECT *
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY location, date;

-- Things used commonly
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Portfolio_project..CovidDeaths
ORDER BY location, date;

-- total cases vs total deaths
-- Shows likelyhood of death once infected
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 AS death_percentage
FROM Portfolio_project..CovidDeaths
WHERE location LIKE '%states%' and continent IS NOT NULL
ORDER BY location, date;

-- total cases vs population
--percentage of population with covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS percentage_pop_infected
FROM Portfolio_project..CovidDeaths
WHERE location LIKE '%states%' and continent IS NOT NULL
ORDER BY location, date;

-- Countries with highest infection value vs population
SELECT location, MAX(total_cases) AS highest_infection_count, population, MAX((total_cases/population) * 100) AS percentage_pop_infected
FROM Portfolio_project..CovidDeaths
GROUP BY location, population
ORDER BY percentage_pop_infected DESC;

-- highest death count
SELECT location, MAX(CAST(total_deaths AS INT)) AS deaths_count
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY deaths_count DESC;

-- highest death count vs population
SELECT location, MAX(CAST(total_deaths AS INT)) AS highest_deaths_count, population, MAX((total_deaths/population) * 100) AS percentage_pop_death
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percentage_pop_death DESC;

-- Total deaths per continent
SELECT DISTINCT(continent), SUM(MAX(CAST(total_deaths AS INT))) OVER(PARTITION BY continent) AS death_count
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent
ORDER BY death_count, continent;

SELECT location, MAX(CAST(total_deaths as INT))
FROM Portfolio_project..CovidDeaths
WHERE continent IS NULL
GROUP BY location;


-- continent with highest death count vs population
SELECT 
	DISTINCT(continent), 
	SUM(MAX(CAST(total_deaths AS INT))) OVER(PARTITION BY continent) AS death_count,
	SUM(MAX(population)) OVER (PARTITION BY continent) AS continental_population
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent;



-- Global numbers
SELECT date, SUM(new_cases) AS total_cases_today, SUM(CAST(new_deaths AS INT)) as total_deaths_today, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date ASC;

SELECT *
FROM Portfolio_project..CovidDeaths
WHERE location LIKE '%World%'
ORDER BY date ASC;


-- Looking at total population vs total vaccinations
-- Use CTE

WITH popvsvac AS (
SELECT 
	a.continent, 
	a.location, 
	a.date, 
	a.population, 
	b.new_vaccinations,
	SUM(CAST(b.new_vaccinations AS BIGINT)) OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS rolling_people_vaccinated
FROM Portfolio_project..CovidDeaths AS a
JOIN Portfolio_project..CovidVaccinations AS b
ON a.location = b.location AND a.date = b.date
WHERE a.continent IS NOT NULL
-- ORDER BY a.location, a.date
)
SELECT *, (rolling_people_vaccinated/population) * 100
FROM popvsvac;


--Temp table
DROP TABLE IF EXISTS #percentage_pop_vaccinated
CREATE TABLE #percentage_pop_vaccinated(
	continent NVARCHAR(255), 
	location NVARCHAR(255), 
	date DATETIME, 
	population NUMERIC, 
	new_vaccinations NUMERIC,
	rolling_vac NUMERIC
)

INSERT INTO #percentage_pop_vaccinated
	SELECT 
	a.continent, 
	a.location, 
	a.date, 
	a.population, 
	b.new_vaccinations,
	SUM(CAST(b.new_vaccinations AS BIGINT)) OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS rolling_people_vaccinated
	FROM Portfolio_project..CovidDeaths AS a
	JOIN Portfolio_project..CovidVaccinations AS b
	ON a.location = b.location AND a.date = b.date
	WHERE a.continent IS NOT NULL;

SELECT *, (rolling_vac/population)*100 AS percentage_vaccinated
FROM #percentage_pop_vaccinated;



-- Creating views for later data visualization
DROP VIEW IF EXISTS percentage_vaccinated
USE Portfolio_project
GO
CREATE VIEW percentage_vaccinated AS
SELECT 
	a.continent, 
	a.location, 
	a.date, 
	a.population, 
	b.new_vaccinations,
	SUM(CAST(b.new_vaccinations AS BIGINT)) OVER (PARTITION BY a.location ORDER BY a.location, a.date) AS rolling_people_vaccinated
	FROM Portfolio_project..CovidDeaths AS a
	JOIN Portfolio_project..CovidVaccinations AS b
	ON a.location = b.location AND a.date = b.date
	WHERE a.continent IS NOT NULL;


DROP VIEW IF EXISTS covid_evo_global
USE Portfolio_project;
GO
CREATE VIEW covid_evo_global AS
SELECT date, SUM(new_cases) AS total_cases_today, SUM(CAST(new_deaths AS INT)) as total_deaths_today, (SUM(CAST(new_deaths AS INT))/SUM(new_cases))*100 AS death_percentage
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date;


USE Portfolio_project;
GO
CREATE VIEW cases_rel_deaths AS
SELECT 
	a.date,
	a.location,
	SUM(new_cases) OVER(PARTITION BY a.location ORDER BY a.location, a.date) AS total_cases_to_date,
	SUM(CAST(a.new_deaths AS BIGINT)) OVER(PARTITION BY a.location ORDER BY a.location, a.date) AS total_deaths_to_date
FROM Portfolio_project..CovidDeaths AS a
JOIN Portfolio_project..CovidVaccinations AS b
ON a.date = b.date AND a.location = b.location
WHERE a.continent IS NOT NULL;


-- Queries for tableau data visualization

-- 1 total deaths and cases Global
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS BIGINT)) AS total_deaths, (SUM(CAST(new_deaths AS BIGINT))/SUM(new_cases))*100 AS death_percentage
FROM Portfolio_project..CovidDeaths
WHERE location LIKE '%World%';

-- 2 total death count in each continent
SELECT DISTINCT(continent), SUM(MAX(CAST(total_deaths AS BIGINT))) OVER (PARTITION BY continent) AS total_cont_deaths
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, continent
ORDER BY total_cont_deaths DESC;

--3 percent of pop infected by country
SELECT location, population, SUM(new_cases) AS total_cases, (SUM(new_cases)/population) * 100 AS percent_pop_infected
FROM Portfolio_project..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population
ORDER BY percent_pop_infected DESC;

--4 percent of pop infected by country by date desc
SELECT location, population, date, MAX(total_cases) as total_cases_to_date, (MAX(total_cases/population)) * 100 AS percent_pop_infected
FROM Portfolio_project..CovidDeaths
GROUP BY location, population, date
ORDER BY percent_pop_infected DESC , date DESC;
