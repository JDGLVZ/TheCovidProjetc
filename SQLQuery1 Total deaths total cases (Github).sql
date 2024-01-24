--SELECT TOP 100 *
--FROM Proyect1.dbo.CovidDeaths
--ORDER BY 3,4

--SELECT TOP 100 *
--FROM Proyect1.dbo.CovidVaccinations
--ORDER BY 3,4

-- Selection of needed data
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM Proyect1.dbo.CovidDeaths
ORDER BY 1,2

-- Comparison between Total Cases vs Total Deaths, show the likelihood of dying if you contract covid in your country
SELECT location, date, total_cases, total_deaths,
	CASE
		WHEN total_cases <> 0 THEN (total_deaths*1.0/total_cases)*100
		ELSE NULL
	END AS Death_rate
FROM Proyect1.dbo.CovidDeaths
WHERE location like '%xico%'
ORDER BY 1,2

----This is an example of how to change a data type from a column
--ALTER TABLE Proyect1.dbo.CovidDeaths
--ALTER COLUMN new_cases int;

-- Looking at Total Cases vs Population, shows porcentage of population got COvid

SELECT location, date, total_cases, population, 
	CASE
		WHEN new_cases <> 0 THEN (total_cases*1.0/population)*100
		ELSE NULL
	END AS Infection_ratio
FROM Proyect1.dbo.CovidDeaths
WHERE location like '%xico'
ORDER BY 1,2

-- Looking countries with highest infection rate compared to population
SELECT 
	location, 
	population, 
	MAX(total_cases) AS HighestInfectionCount, 
	CAST(MAX(CASE
			WHEN new_cases <> 0 THEN ROUND ((total_cases*1.0)/population*100,2)
			ELSE 0
		END) AS DECIMAL(10,2)) AS Infection_ratio
FROM Proyect1.dbo.CovidDeaths
GROUP BY location, population
ORDER BY Infection_ratio DESC

-- Showing Countries with Highest Death Count per Population
SELECT 
	location, 
	MAX(total_deaths) AS total_deaths,
	CAST(MAX(CASE
		WHEN total_deaths <> 0 THEN ROUND((total_deaths*1.0/population)*100,2)
		ELSE 0
	END) AS DECIMAL (10,2) )AS DeathByPopulation
FROM Proyect1.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY DeathByPopulation DESC

-- BREAKING BY CONTINENT, SHOWING HIGHEST DEATH COUNT
SELECT 
	location,
	MAX(total_deaths) AS total_deaths
FROM Proyect1.dbo.CovidDeaths
WHERE continent = '' AND
	location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location
ORDER BY location

-- BREAKING BY CONTINENT, SHOWING HIGHEST DEATH COUNT ... this is just about to change the continent filter
SELECT 
	location,
	continent,
	MAX(total_deaths) AS total_deaths
FROM Proyect1.dbo.CovidDeaths
WHERE
	continent = 'Asia' AND
	location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY location, continent
ORDER BY total_deaths DESC

--- Global numbers
SELECT 
	date, 
	SUM(new_cases) AS Sum_newcases, 
	SUM(cast(new_deaths AS int)) AS Sum_newdeaths,
	CASE
		WHEN SUM(new_cases) <> 0 THEN SUM(CAST(new_deaths AS int))*1.0/SUM(new_cases) *100 
		ELSE 0
	END AS Death_percentage
FROM Proyect1.dbo.CovidDeaths
WHERE
	NOT continent = '' AND
	location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
GROUP BY date
ORDER BY 1,2

SELECT location, continent, date, new_cases, new_deaths
FROM Proyect1.dbo.CovidDeaths
WHERE
	date <= '2020-01-05'
	AND NOT continent = ''
	AND location NOT IN  ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
ORDER BY date, new_cases DESC, new_deaths DESC



-- Looking Vaccination table
Select *
From Proyect1.dbo.CovidVaccinations

-- Joining tables and looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
	SUM(CONVERT(int, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.date) AS VaccinationRollingCount,
FROM Proyect1.dbo.CovidDeaths AS dea
	JOIN Proyect1.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE
	dea.location = 'Canada' AND
	NOT dea.continent = ''
	AND NOT vac.new_vaccinations = ''
	AND dea.location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
ORDER BY 2,4

--Creating a CTE 
WITH PopvsVac (continent, location, date, population, new_vaccinations ,VaccinationRollingCount)
AS (
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
FROM Proyect1.dbo.CovidDeaths AS dea
	JOIN Proyect1.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE
	NOT dea.continent = ''
	AND NOT vac.new_vaccinations = ''
	AND dea.location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')
)
SELECT *, CAST(ROUND((VaccinationRollingCount*1.0/population)*100,2) AS decimal (12,2)) AS VaccinationPercentage
FROM PopvsVac


-- TEMP TABLE
DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
continent nvarchar(255),
location nvarchar(255),
date date,
population numeric,
New_vaccinations numeric,
VaccinationRollingCount numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
FROM Proyect1.dbo.CovidDeaths AS dea
	JOIN Proyect1.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE
	NOT dea.continent = ''
	AND NOT vac.new_vaccinations = ''
	AND dea.location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')

SELECT *, CAST(ROUND((VaccinationRollingCount*1.0/population)*100,2) AS decimal (12,2)) AS VaccinationPercentage
FROM #PercentPopulationVaccinated

--Creating  view to store data 
CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.population, dea.date, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) OVER (Partition BY dea.location ORDER BY dea.location, dea.date) AS VaccinationRollingCount
FROM Proyect1.dbo.CovidDeaths AS dea
	JOIN Proyect1.dbo.CovidVaccinations AS vac
		ON dea.location = vac.location 
		AND dea.date = vac.date
WHERE
	NOT dea.continent = ''
	AND NOT vac.new_vaccinations = ''
	AND dea.location NOT IN ('High income', 'Upper middle income', 'Lower middle income', 'Low income')

