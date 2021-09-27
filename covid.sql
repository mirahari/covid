-- SELECT DATA

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Covid19..CovidDeaths$
ORDER BY 1,2


-- Total cases VS Total deaths (Likelihood of death)

SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as death_rate
FROM Covid19..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Total cases vs Population

SELECT location, date, population, total_cases, (total_cases/population)*100 as infection_rate
FROM Covid19..CovidDeaths$
WHERE location like '%states%'
ORDER BY 1,2


-- Countries with Highest Infection Rate compared to Population

SELECT location, population, MAX(total_cases) as highest_infection_count, MAX(total_cases/population)*100 as 
	max_infection_rate
FROM Covid19..CovidDeaths$
GROUP BY location, population
ORDER BY max_infection_pct DESC


-- Countries with Highest Death Count per Population

SELECT location, MAX(cast(total_deaths AS INT)) as highest_death_count
FROM Covid19..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY highest_death_count DESC


-- Continent with Highest Death Count

--SELECT continent, MAX(cast(total_deaths AS INT)) as highest_death_count
--FROM Covid19..CovidDeaths$
--WHERE continent IS NOT NULL
--GROUP BY continent
--ORDER BY highest_death_count DESC

SELECT location, MAX(cast(total_deaths AS INT)) as highest_death_count
FROM Covid19..CovidDeaths$
WHERE continent IS NULL
GROUP BY location
ORDER BY highest_death_count DESC


-- Global Numbers by Date

SELECT date, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_rate
FROM Covid19..CovidDeaths$
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1,2


-- Total

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths,
	SUM(cast(new_deaths as int))/SUM(new_cases)*100 as death_rate
FROM Covid19..CovidDeaths$
WHERE continent IS NOT NULL
ORDER BY 1,2


-- Total Population vs Vaccinations

SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,	
	SUM(CONVERT(BIGINT, vax.new_vaccinations)) OVER (PARTITION BY dth.location ORDER BY dth.location, dth.date)
	AS rolling_vaxxed
FROM Covid19..CovidDeaths$ dth
JOIN Covid19..CovidVax$ vax
	ON dth.location = vax.location
	AND dth.date = vax.date
	WHERE dth.continent IS NOT NULL
ORDER BY 2,3


-- USE CTE

WITH POPvsVAX (continent, location, date, population, new_vaccinations, rolling_vaxxed) AS 
(
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,	
	SUM(cast(vax.new_vaccinations AS BIGINT)) OVER (PARTITION BY dth.location ORDER BY dth.location, dth.date)
	AS rolling_vaxxed
FROM Covid19..CovidDeaths$ dth
JOIN Covid19..CovidVax$ vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
)
SELECT *, (rolling_vaxxed/population)*100 AS vax_rate
FROM POPvsVAX


-- TEMP TABLE

DROP TABLE IF EXISTS #VaxPop
CREATE TABLE #VaxPop 
(
continent NVARCHAR(255),
location NVARCHAR(255),
date DATETIME,
population NUMERIC,
new_vaccinations NUMERIC,
rolling_vaxxed NUMERIC
)

INSERT INTO #VaxPop 
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,	
	SUM(cast(vax.new_vaccinations AS BIGINT)) OVER (PARTITION BY dth.location ORDER BY dth.location, dth.date)
	AS rolling_vaxxed
FROM Covid19..CovidDeaths$ dth
JOIN Covid19..CovidVax$ vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
ORDER BY 2,3

SELECT *, (rolling_vaxxed/population)*100 AS vax_rate
FROM #VaxPop


-- CREATE VIEW FOR VISUALISATION

CREATE VIEW vaxxed_population AS
SELECT dth.continent, dth.location, dth.date, dth.population, vax.new_vaccinations,	
	SUM(cast(vax.new_vaccinations AS BIGINT)) OVER (PARTITION BY dth.location ORDER BY dth.location, dth.date)
	AS rolling_vaxxed
FROM Covid19..CovidDeaths$ dth
JOIN Covid19..CovidVax$ vax
	ON dth.location = vax.location
	AND dth.date = vax.date
WHERE dth.continent IS NOT NULL
