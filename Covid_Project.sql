select *
from covid_deaths_vac..deaths
order by 3



select location, date, total_cases, new_cases, total_deaths, population
from covid_deaths_vac..deaths
order by 1,2

--total cases vs total deaths
--shows the chance of deaths if you contract covid in a Country
select location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Death_percentage
from covid_deaths_vac..deaths
where location like '%south africa%'
order by 1,2


--total cases vs population
--shows the percentage of population with covid
select location, date, total_cases, population, (total_cases/population)*100 as Cases_Percentage
from covid_deaths_vac..deaths
where location like '%south africa%'
order by 1,2


--countries with highest infection rate per population as at 25 july 2025
select continent, location, total_cases, total_deaths, population, ((total_cases/population)*100) as pop_Cases_Percentage, ((total_deaths/population)*100) as pop_Death_percentage, ((total_deaths/total_cases)*100) as cases_Death_percentage
from covid_deaths_vac..deaths
where ((date = '2021-07-25 00:00:00.000') and (total_deaths > 1000))
--group by continent, location
order by continent, pop_Death_percentage desc


--deaths count by continent
select location, population, max(total_cases) as total_cases, MAX(cast(total_deaths as int)) as
total_death_count, ((MAX(cast(total_deaths as int))/population)*100) as death_percentage,
 ((MAX(cast(total_cases as int))/population)*100) as cases_percentage
from covid_deaths_vac..deaths
where continent is null
group by location, population
order by total_death_count desc


select *
from covid_deaths_vac..vaccinations
order by 3, 4

--population vs vaccinations
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 1,2,3,4


--population vs vaccinations by cumulative daily vaccines
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as cumlative_daily_vac
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

--new vaccinations per day per continent
select dea.continent, dea.date, sum(cast(vac.new_vaccinations as int)) as cumlative_vac
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
group by dea.continent, dea.date
order by 1,2,3


--Using CTE

with PopvsVac (Continent, Location, Date, Population, New_Vaccinations, Cumlative_daily_vac)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as cumlative_daily_vac
--(cumlative_daily_vac/population)*100 (cant use a newly created column for culaculations hence we use a context)
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
select *, (cumlative_daily_vac/population)*100 as percentage_cum_daily_vac
from PopvsVac


-- Using Temp Table

Drop Table if exists #PercentPopVac
Create Table #PercentPopVac
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_Vaccinations numeric,
Cumlative_daily_vac numeric
)

Insert into PercentPopVac
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as cumlative_daily_vac
--(cumlative_daily_vac/population)*100 (cant use a newly created column for culaculations hence we use a context)
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
select *, (cumlative_daily_vac/population)*100 as percentage_cum_daily_vac
from #PercentPopVac



--creating view to store data for later visualisation

create view CumPopVac as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(convert(int, vac.new_vaccinations)) over (partition by dea.location order by dea.location, dea.date) as cumlative_daily_vac
--(cumlative_daily_vac/population)*100 (cant use a newly created column for culaculations hence we use a context)
from covid_deaths_vac..deaths dea
join covid_deaths_vac..vaccinations vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3

select *
from CumPopVac