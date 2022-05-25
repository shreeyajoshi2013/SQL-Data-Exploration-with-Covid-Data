----------------------------------------Covid 19 Data Exploration----------------------------------------- 

--Skills used: JOINs, CTE's, Temp Tables, Windows Functions, Aggregate Functions, 
--             Creating Views, Converting Data Types 
----------------------------------------------------------------------------------------------------------

SELECT *
FROM CovidData.dbo.CovidDeaths
WHERE continent is not null
ORDER BY 3,4;

SELECT * 
FROM CovidData.dbo.CovidVaccinations
ORDER BY location,date;


--Looking at the data used in most of the cases in this project
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidData.dbo.CovidDeaths
ORDER BY location, date;



--Analysis: Total Cases Vs Total Deaths
--Showing the likelihood of dying if a person contracts covid in his/her country

SELECT location, date, total_cases, total_deaths, 
	(total_deaths/total_cases)* 100 as DeathPercentage
FROM CovidData.dbo.CovidDeaths 
WHERE location LIKE '%United States%'	
ORDER BY location, date;



--Analysis: Total Cases Vs Population
--Showing how much percentage of the population got covid

SELECT location, date, total_cases, total_deaths, 
ROUND((total_deaths/population)* 100, 3) as PercentPopulationInfected
FROM CovidData.dbo.CovidDeaths 
WHERE location like '%United States%'
ORDER BY location, date;


--Showing the countries with the highest infection rate as compared to population

SELECT location, population, 
MAX(total_cases) as HighestInfectionCount, 
ROUND(MAX(total_cases/population)* 100, 2) as PercentPopulationInfected
FROM CovidData.dbo.CovidDeaths 
GROUP BY location, population
ORDER BY PercentPopulationInfected desc;


--Showing the countries with highest death count per population (where the continent not null)

SELECT location, 
MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidDeaths 
WHERE continent is not null
GROUP BY location
ORDER BY TotalDeathCount desc;



--Showing the countries with highest death count per population (where the continent is null)

SELECT location, 
MAX(CAST(total_deaths as int)) as TotalDeathCount
FROM CovidData.dbo.CovidDeaths 
WHERE continent is null
GROUP BY location
ORDER BY TotalDeathCount desc;



--Showing the global numbers- total cases, total deaths and death percentage accross the world on each date available in the data

SELECT date, 
	SUM(new_cases) as sum_new_cases, 
	SUM(CAST(new_deaths as int)) as sum_new_deaths,  
	ROUND(SUM(CAST(new_deaths as int))/SUM(new_cases)*100, 2) as DeathPercentage
FROM CovidData.dbo.CovidDeaths 
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY date,sum_new_deaths;



--Analysis: Total Population Vs Vaccinations
--Showing the total number of people in the world that have been vaccinated by that date

SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(CONVERT(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date ) as rolling_people_vaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
on dea.location = vac.location 
AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL
ORDER BY dea.continent,  dea.location ;



--Analysis: Total Population Vs Vaccinations
--Showing the total number of people in the world that have been vaccinated by that date and its percentage (Using CTE)

WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
	(
		SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
		SUM(convert(bigint, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
		FROM CovidData.dbo.CovidVaccinations AS vac
		JOIN CovidData.dbo.CovidDeaths AS dea
		ON dea.location = vac.location and dea.date = vac.date 
		WHERE dea.continent is not null
	)
SELECT *,
	ROUND((RollingPeopleVaccinated/Population)*100, 2) PercentPplVaccinatedOnDate
FROM PopvsVac;



--Analysis: Total Population Vs Vaccinations
--Showing the total number of people in the world that have been vaccinated by that date and its percentage (By creating temperory table)

DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
	(
		continent NVARCHAR(255),
		location NVARCHAR(255),
		date DATETIME,
		Population NUMERIC,
		new_vaccination NUMERIC,
		RollingPeopleVaccinated	NUMERIC
	)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(convert(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date) 
	as RollingPeopleVaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
on dea.location = vac.location and dea.date = vac.date 
WHERE dea.continent is not null;

SELECT *,(RollingPeopleVaccinated/Population)*100 as PercentPplVaccinatedOnDate
FROM #PercentPopulationVaccinated;




--Showing the total number of people in the world that have been vaccinated by that date (Using view)

Create View  PercentPopulationVaccinated AS 
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
	SUM(convert(bigint, vac.new_vaccinations)) over (Partition BY dea.location ORDER BY dea.location, dea.date) as RollingPeopleVaccinated
FROM CovidData.dbo.CovidVaccinations AS vac
JOIN CovidData.dbo.CovidDeaths AS dea
ON dea.location = vac.location 
	AND dea.date = vac.date 
WHERE dea.continent IS NOT NULL;


--DROP VIEW PercentPopulationVaccinated;

SELECT * FROM PercentPopulationVaccinated;
