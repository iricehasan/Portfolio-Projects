SELECT *
FROM PortfolioProject1.dbo.CovidDeaths

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1.dbo.CovidDeaths
ORDER BY location, date


-- Looking at Total Cases vs. Total Deaths

SELECT location, date, total_cases, new_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths
ORDER BY location, date


-- I live in Turkey, so let's look at the death percentage in Turkey

SELECT location, date, total_cases, new_cases, total_deaths, (CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE location = 'Turkey'
ORDER BY location, date

-- Let's find the average death percentage

/*
SELECT location, AVG(total_cases), AVG(new_cases), AVG(total_deaths), AVG(CAST(total_deaths AS float)/CAST(total_cases AS float))*100 AS AvgDeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths
GROUP BY location
ORDER BY location

*/

-- Looking at the total cases vs. population to find out what percentage of the population got covid
-- Using CAST since total_cases and population are integer, division of two integers give 0

SELECT location, date, total_cases, population, (CAST(total_cases AS float)/ CAST(population AS float))*100 AS PopulationInfectedPercentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE location = 'Turkey'
ORDER BY location, date

-- The country that has the highest infection rate compared to population

SELECT location, MAX(total_cases) AS HighestInfectionCount, population, MAX(CAST(total_cases AS float)/ CAST(population AS float))*100 AS PopulationInfectedPercentage
FROM PortfolioProject1.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PopulationInfectedPercentage DESC

-- How many people have died

SELECT location, SUM(new_deaths) AS TotalDeath, population, SUM(CAST(total_deaths AS float)/ CAST(population AS float))*100 AS PopulationDeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE Continent IS NOT NULL
GROUP BY location, population
ORDER BY PopulationDeathPercentage DESC

-- which country has the highest death

SELECT location, MAX(total_deaths) AS MaxDeath, population
FROM PortfolioProject1.dbo.CovidDeaths
GROUP BY location, population
ORDER BY MaxDeath DESC

-- comparing the continents by maximum death counts

SELECT continent, MAX(total_deaths) AS MaxDeath
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY MaxDeath DESC

/*
SELECT location, MAX(total_deaths) AS MaxDeath
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NULL
GROUP BY location
ORDER BY MaxDeath DESC
*/

-- Global

SELECT SUM(new_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, SUM(CAST(new_deaths AS float))/SUM(CAST(new_cases AS float))*100 AS DeathPercentage
FROM PortfolioProject1.dbo.CovidDeaths
WHERE continent IS NOT NULL

-- Now let's explore the CovidVaccinations Table

SELECT * 
FROM PortfolioProject1.dbo.CovidVaccinations

-- Joining the two tables

SELECT *
FROM PortfolioProject1.dbo.CovidDeaths AS dea
JOIN PortfolioProject1.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date

-- Looking at total vaccinations vs population

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
FROM PortfolioProject1.dbo.CovidDeaths AS dea
JOIN PortfolioProject1.dbo.CovidVaccinations AS vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent, dea.location, dea.date

-- Using CTE to perform Calculation on Partition By in previous query

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject1.dbo.CovidDeaths AS dea
JOIN PortfolioProject1.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (RollingPeopleVaccinated/Population)*100
FROM PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject1.dbo.CovidDeaths AS dea
JOIN PortfolioProject1.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentPopulationVaccinated


-- Creating View to store data for later visualizations

CREATE View PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(vac.new_vaccinations) OVER (PARTITION BY dea.Location ORDER BY dea.location, dea.Date) AS RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
FROM PortfolioProject1.dbo.CovidDeaths AS dea
JOIN PortfolioProject1.dbo.CovidVaccinations AS vac
	ON dea.location = vac.location
	AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
