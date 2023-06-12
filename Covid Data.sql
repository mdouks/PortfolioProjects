
SELECT *
FROM PortfolioProject1..CovidDeaths$
order by 3, 4


/*
SELECT *
FROM PortfolioProject1..CovidVaccinations$
order by 3, 4 
*/


-- Select Data that we are going to be using 

SELECT  location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject1..CovidDeaths$
order by 1,2

 -- Looking at Total Cases vs Total Deaths
 -- Shows likelihood of dying if you contract covid in your country
 SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
 FROM PortfolioProject1..CovidDeaths$
 WHERE location like '%australia%'
 order by 1,2


 -- Looking at Total Cases vs Population
 -- Shows what percentage of population got covid
  SELECT location, date, population, total_cases, (total_cases/population)*100 as InfectionRate
 FROM PortfolioProject1..CovidDeaths$
 WHERE location like '%australia%'
 order by 1,2 


 -- Looking at countries with highest infection rates compared to population
 SELECT location, population, MAX(total_cases) as HighestInfectionCount, MAX((total_cases/population))*100 as PercentPopulationInfected
 FROM PortfolioProject1..CovidDeaths$
 Group by location, population
 order by PercentPopulationInfected DESC


 -- Looking at countries with highest death count per population
 SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
 FROM PortfolioProject1..CovidDeaths$
 WHERE continent is not null
 GROUP BY location
 ORDER BY TotalDeathCount desc

  -- LET'S BREAK THINGS DOWN BY CONTINENT

  -- Right Way
 SELECT location, MAX(cast(total_deaths as int)) as TotalDeathCount
 FROM PortfolioProject1..CovidDeaths$
 WHERE continent is null
 GROUP BY location
 ORDER BY TotalDeathCount desc

 -- Best way for drill down effect visualization
  SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
 FROM PortfolioProject1..CovidDeaths$
 WHERE continent is not null
 GROUP BY continent
 ORDER BY TotalDeathCount DESC


 -- Showing continents with the highest death count per population
 SELECT continent, MAX(cast(total_deaths as int)) as TotalDeathCount
FROM PortfolioProject1..CovidDeaths$
WHERE continent is not null
GROUP BY continent
ORDER BY TotalDeathCount DESC

-- GLOBAL NUMBERS

-- By day
SELECT date, SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (SUM(CAST(new_deaths as int))/SUM(new_cases) * 100) as DeathPercentage--, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject1..CovidDeaths$
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- In total
SELECT SUM(new_cases) as TotalCases, SUM(cast(new_deaths as int)) as TotalDeaths, (SUM(CAST(new_deaths as int))/SUM(new_cases) * 100) as DeathPercentage--, total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
FROM PortfolioProject1..CovidDeaths$
ORDER BY 1,2


-- JOINING Death and Vaccination tables
SELECT *
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date


-- Looking at Total Population vs Vaccinations
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2 


-- Rolling count of each countries vaccination numbers
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinationCount
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
ORDER BY 1,2 


-- USE CTE
WITH PopvsVac (Continent, location, date, population, new_vaccinations, RollingPeopleVaccinated)
as
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinationCount
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2 
)
SELECT *, (RollingPeopleVaccinated/population) * 100 as VaccinationPercentage
FROM PopvsVac


-- TEMP TABLE
DROP Table if exists #PercentPopulationVaccinated
CREATE Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinationCount
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2 

SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated



-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS
Create View PercentPopulationVaccinated as
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CAST(vac.new_vaccinations as int)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingVaccinationCount
FROM PortfolioProject1..CovidDeaths$ dea
JOIN PortfolioProject1..CovidVaccinations$ vac
	ON dea.location = vac.location
	and dea.date = vac.date
WHERE dea.continent is not null
--ORDER BY 1,2 

SELECT * 
FROM PercentPopulationVaccinated