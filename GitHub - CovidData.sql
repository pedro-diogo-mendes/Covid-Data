SELECT *
FROM [CovidData].[dbo].[CovidData]



-- Total Cases vs Total Deaths
-- I want to know the % of death in case of infection, everyday.
SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF (total_cases, 0))*100 AS DeathPercentage
FROM [CovidData].[dbo].[CovidData]
ORDER BY 1, 2

-- In the Portuguese case:
SELECT location, date, total_cases, total_deaths, (total_deaths/NULLIF (total_cases, 0))*100 AS DeathPercentage
FROM [CovidData].[dbo].[CovidData]
WHERE location = 'Portugal'
ORDER BY 1, 2



-- Total Cases VS Population
-- I want to know the percentage of the population that has been infected, per day cumulatively, per country.
-- I just want to know the numbers from the beginning of the first cases ultil the end of the pandemic decreed by the WHO on 05-05-2023.
SELECT location, date, population, total_cases, (total_cases/population)*100 AS PercentPopulationInfected
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2023-05-05' AND continent <> ' '
ORDER BY 1, 2

-- Which country has the highest percentage of infections compared to its population?
SELECT location, population, MAX(total_cases) AS TotalInfections, MAX((total_cases/population)*100) AS PercentPopulationInfected
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2023-05-05' AND continent <> ' '
GROUP BY population, location
ORDER BY 4 DESC



-- Which country had the most deaths?
SELECT location, MAX(total_deaths) AS TotalDeaths
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2023-05-05' AND continent <> ' '
GROUP BY location
ORDER BY 2 DESC

-- Compared to the population, which country has been most affected?
SELECT location, MAX(total_deaths) AS TotalDeaths, MAX((total_deaths/population)*100) AS PercentPopulationDead
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2023-05-05' AND continent <> ' '
GROUP BY location
ORDER BY 3 DESC

-- Which continent had the most deaths?
SELECT location, MAX(total_deaths) AS TotalDeaths
FROM [CovidData].[dbo].[CovidData]
WHERE location = 'Europe' OR location = 'North America' OR location = 'Asia' OR location = 'South America' OR location = 'Africa' OR location = 'Oceania' AND date BETWEEN '2020-01-05' AND '2023-05-05'
GROUP BY location
ORDER BY 2 DESC

-- Fazer agora a % de mortes por população nos continentes
SELECT location, MAX(total_deaths) AS TotalDeaths, population, MAX((total_deaths/population)*100) AS PercentPopulationDead
FROM [CovidData].[dbo].[CovidData]
WHERE location = 'Europe' OR location = 'North America' OR location = 'Asia' OR location = 'South America' OR location = 'Africa' OR location = 'Oceania' AND date BETWEEN '2020-01-05' AND '2023-05-05'
GROUP BY location, population
ORDER BY 4 DESC

-- GLOBAL NUMBERS
SELECT SUM(total_cases) AS TotalCases, SUM(new_deaths) AS TotalDeaths, (SUM(new_deaths)/SUM(new_cases))*100 AS PercentageDeaths
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' ' AND date BETWEEN '2020-01-05' AND '2023-05-05'
ORDER BY 1



-- VACCINATION

-- How many people have been vaccinated, comulatively, over the days?
SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS TotalVaccinations
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '
ORDER BY 2, 3



-- Verificar a percentagem de pessoas que foram vacinadas na população
WITH CTE_PeopleVaccinated AS
(
SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS TotalVaccinations
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '
)
SELECT continent, location, date, population, new_vaccinations, TotalVaccinations, (TotalVaccinations/population)*100 AS PercentagePopulationVaccinated
FROM CTE_PeopleVaccinated
ORDER BY 2, 3

-- Same question using a TEMP TABLE now
DROP TABLE IF EXISTS #PercentagePopulationVaccinated
CREATE TABLE #PercentagePopulationVaccinated
(
continent varchar(50),
location varchar(50),
date varchar(50),
population numeric,
new_vaccinations numeric,
TotalVaccinations numeric
)

INSERT INTO #PercentagePopulationVaccinated
SELECT continent, location, date, population, new_vaccinations, SUM(new_vaccinations) OVER (PARTITION BY location ORDER BY location, date) AS TotalVaccinations
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '

SELECT *, (TotalVaccinations/population)*100 AS PercentagePopulationVaccinated
FROM #PercentagePopulationVaccinated
ORDER BY location, date



-- Percentage of people FULLY vaccinated
SELECT location, population, MAX((people_fully_vaccinated/population)*100) AS PercentagePopulationFullyVaccinated
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '
GROUP BY location, population
ORDER BY 3 DESC



-- Create a view to save data for later for visualizations.
CREATE VIEW PercentagePopulationVaccinated AS
SELECT location, population, MAX((people_fully_vaccinated/population)*100) AS PercentagePopulationFullyVaccinated
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '
GROUP BY location, population



-- Let's see if some indicators have a correlation with deaths, for later charts.
SELECT location,
	   MAX(total_deaths) AS MaxTotalDeaths,
	   population_density,
	   median_age,
	   gdp_per_capita,
	   cardiovasc_death_rate,
	   diabetes_prevalence,
	   female_smokers,
	   male_smokers,
	   life_expectancy,
	   human_development_index
FROM [CovidData].[dbo].[CovidData]
WHERE continent <> ' '  AND date BETWEEN '2020-01-05' AND '2023-05-05'
GROUP BY location, population_density, median_age, gdp_per_capita, cardiovasc_death_rate, diabetes_prevalence, female_smokers, male_smokers, life_expectancy, human_development_index
ORDER BY 1, 2



-- Vamos verificar quando Portugal teve 5 milhões de vacinas administradas, o que significa que cerca de 50% da população teve pelo menos 1 dose da vacina
SELECT date, location, total_cases, total_vaccinations, population, ((SUM(total_cases)+SUM(total_vaccinations))/population)*100 AS HerdImmunity
FROM [CovidData].[dbo].[CovidData]
WHERE location = 'Portugal'
GROUP BY date, location, total_cases, total_vaccinations, population
ORDER BY 1
-- Herd immunity in Portugal was reached on 04-06-2021 in which 70% of the population was vaccinated or contracted the virus.



-- I'm gonna check the before and after the herd immunity in relation to deaths, to see if there's any correlation between vaccination decreasing deaths.
-- Before:
SELECT location, MAX(total_deaths) AS TotalMortes, MAX((total_deaths/population)*100) AS PercentagePopulationDead
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2021-06-04' AND location = 'Portugal'
GROUP BY location

-- After:
SELECT location, MAX(total_deaths) AS TotalMortes, MAX((total_deaths/population)*100) AS PercentagePopulationDead
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2021-06-04' AND '2023-05-05' AND location = 'Portugal'
GROUP BY location
ORDER BY 3 DESC

-- Compare the two numbers in one table:
WITH CTE_DeathsPortugalBeforeVaccination AS
(
SELECT location, MAX(total_deaths) AS TotalDeathsBeforeVaccine
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2021-06-04' AND location = 'Portugal'
GROUP BY location
)
SELECT TotalDeathsBeforeVaccine, MAX(total_deaths)-TotalDeathsBeforeVaccine AS TotalDeathsAfterVaccine
FROM CTE_DeathsPortugalBeforeVaccination
JOIN [CovidData].[dbo].[CovidData]
	ON CTE_DeathsPortugalBeforeVaccination.location = [CovidData].[dbo].[CovidData].location
WHERE date BETWEEN '2021-06-04' AND '2023-05-05'
GROUP BY TotalDeathsBeforeVaccine;



-- Let's look at the total number of confirmed cases in these seasons to understand if the vaccine was effective in preventing the spread of the virus.
WITH CTE_CasesPortugalBeforeVaccination AS
(
SELECT location, MAX(total_cases) AS TotalCasesBeforeVaccine
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2021-06-04' AND location = 'Portugal'
GROUP BY location
)
SELECT TotalCasesBeforeVaccine, MAX(total_cases)-TotalCasesBeforeVaccine AS TotalCasesAfterVaccine
FROM CTE_CasesPortugalBeforeVaccination
JOIN [CovidData].[dbo].[CovidData]
	ON CTE_CasesPortugalBeforeVaccination.location = [CovidData].[dbo].[CovidData].location
WHERE date BETWEEN '2021-06-04' AND '2023-05-05'
GROUP BY TotalCasesBeforeVaccine



-- Let's look at the effectiveness of the vaccine over time.
SELECT date, location, SUM(new_cases) OVER (PARTITION BY location ORDER BY location, date) AS TotalCases, SUM(new_deaths) OVER (PARTITION BY location ORDER BY location, date) AS TotalDeaths
FROM [CovidData].[dbo].[CovidData]
WHERE date BETWEEN '2020-01-05' AND '2023-05-05' AND location = 'Portugal'
ORDER BY 1