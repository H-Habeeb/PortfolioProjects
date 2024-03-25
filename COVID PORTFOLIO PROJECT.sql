/*
COVID 19 DATA EXPLORATION

Skills used: Joins, CTE'S, TEMP Tables, Windows Functions, Aggregate Functions, Creating views, Converting Data Types

*/

SELECT *
FROM PortfolioProject.dbo.CovidDeaths

SELECT *
FROM PortfolioProject.dbo.CovidVaccinations

SELECT *
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 3,4

--Select Data that we are going to be starting with

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1,2

--Total cases vs Total deaths 
--Shows likelihood of dying if covid is contracted in Nigeria


SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS int)/CAST(total_cases AS int))*100 AS DeathPercentage 
FROM PortfolioProject.dbo.CovidDeaths
WHERE location = 'Nigeria'
AND continent IS NOT NULL
ORDER BY 1,2

--likelihood of dying if covid is contracted in the states

SELECT location, date, total_cases, total_deaths, (CAST(total_deaths AS int)/CAST(total_cases AS int))*100 AS DeathPercentage 
FROM PortfolioProject.dbo.CovidDeaths
WHERE location like '%state%'
AND continent IS NOT NULL
ORDER BY 1,2

--Total Cases vs population
--Shows what percentage of population infected with covid

SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
--WHERE location like '%state%'
ORDER BY 1,2

--Countries with Highest Infection Rate Compared to Population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population))*100 AS PercentagePopulationInfected
FROM PortfolioProject.dbo.CovidDeaths
GROUP BY location, population
ORDER BY PercentagePopulationInfected DESC

--Countries with Highest Death Count per Population

SELECT location, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--Breaking Things Down By Continent
--Showing continents with the Highest death count per population

SELECT continent, MAX(CAST(total_deaths AS int)) AS TotalDeathCount
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY TotalDeathCount DESC

--Global numbers

SELECT SUM(new_cases) AS Total_Cases, SUM(CAST(new_deaths AS int)) AS Total_Deaths, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 AS DeathPercentage
FROM PortfolioProject.dbo.CovidDeaths
WHERE continent IS NOT NULL

--Total Population vs Vaccination
--Shows Percentage of Population that has received at least one covid vaccine

SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (Partition by DEA.location)
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date =VAC.date
WHERE DEA.continent IS NOT NULL
ORDER BY 2,3

--Using CTE to perform calculation on Partition BY in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated) as
(
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (Partition by DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date =VAC.date
WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3
)
SELECT *, (RollingPeopleVaccinated/population)*100
FROM PopvsVac


--Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
Insert into #PercentagePopulationVaccinated
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (Partition by DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date =VAC.date
--WHERE DEA.continent IS NOT NULL
--ORDER BY 2,3

SELECT *, (RollingPeopleVaccinated/population)*100
FROM #PercentagePopulationVaccinated


--Creating view to store data for later visualizations

CREATE VIEW PercentagePopulationVaccinated AS
SELECT DEA.continent, DEA.location, DEA.date, DEA.population, VAC.new_vaccinations,
	SUM(CAST(VAC.new_vaccinations AS FLOAT)) OVER (Partition by DEA.location ORDER BY DEA.location, DEA.date) AS RollingPeopleVaccinated
FROM PortfolioProject.dbo.CovidDeaths AS DEA
JOIN PortfolioProject.dbo.CovidVaccinations AS VAC
	ON DEA.location = VAC.location
	AND DEA.date =VAC.date
WHERE DEA.continent IS NOT NULL


SELECT *
FROM PercentagePopulationVaccinated