
--1
SELECT COUNT(DISTINCT(GAMES)) FROM dbo.AthleteEvents

--2 
SELECT DISTINCT(GAMES), Year, Season, City FROM dbo.AthleteEvents ORDER BY YEAR ASC

--3
with cte as
(
	select games, re.region
	FROM dbo.AthleteEvents AE
	JOIN nocRegions re ON re.NOC = AE.NOC
	GROUP BY games, re.region
)
SELECT games, COUNT(*) AS particpatingNation FROM cte GROUP BY Games ORDER BY Games

--4
CREATE TABLE  #temptable1(games varchar(200), Year int, participatingNations int);
TRUNCATE TABLE #temptable1;
with cte as
(
	SELECT GAMES,re.region AS region, year
	FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions re
	ON re.NOC = AE.NOC
	GROUP BY games,re.region,Year
) 
INSERT INTO #temptable1(games, year, participatingNations)
SELECT games,YEAR,COUNT(*) as participatingNation  FROM cte
	GROUP BY year,Games
	ORDER BY Count(*);

SELECT TOP 1 CONCAT(games,'-',participatingNations) FROM #temptable1 ORDER BY participatingNations

SELECT TOP 1 CONCAT(games,'-',participatingNations) FROM #temptable1 ORDER BY participatingNations DESC;



--5
--DECLARE @countVar INT;
--SET @countVar =
--(select count(distinct games) from dbo.AthleteEvents);

WITH countries AS
(
	select games,re.region AS region FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions re
	ON re.Noc = AE.NOC
	GROUP BY games,re.region
),
totalCountries AS 
(SELECT COUNT(distinct games)  AS totalGames FROM dbo.AthleteEvents),
countriespart AS
(SELECT region,count(1) AS counter FROM countries GROUP BY region)
SELECT region,counter FROM countriespart JOIN totalCountries ON countriespart.counter = totalCountries.totalGames ORDER BY region;

--6
WITH summerOlympics AS 
(
	SELECT COUNT(distinct games) AS totalSummerOlympic FROM dbo.AthleteEvents WHERE Season = 'Summer'
),
sports AS
(
	SELECT games, sport  FROM dbo.AthleteEvents WHERE Season = 'Summer' GROUP BY games,Sport 
),
totalCOunt AS 
(
	SELECT sport, COUNT(games) AS gamesCOunt FROM sports GROUP BY sport
)
SELECT * FROM totalCOunt tc JOIN summerOlympics so ON tc.gamesCOunt = so.totalSummerOlympic ORDER BY sport DESC;


--7
WITH distinctSport AS
(
	select distinct Games AS games,Sport FROM dbo.AthleteEvents  GROUP BY Sport,Games --ORDER BY games
),
countsport AS
(
	SELECT sport,count(*) sportCountGameWise FROM distinctSport GROUP BY sport
)

select cs.sport,cs.sportCountGameWise, di.games from countsport cs
JOIN distinctSport di
ON di.Sport = cs.Sport
WHERE sportCountGameWise<=(SELECT MIN(sportCountGameWise) FROM countsport)ORDER BY sportCountGameWise 

--8 total number of sprots played in each olympic games

WITH gameSportList AS
(
	select distinct(games) ,sport from dbo.AthleteEvents GROUP BY Games,Sport --order by games 
), gamesWiseSpotCount AS
(
	SELECT games,count(*) AS counter FROM gameSportList GROUP BY games
)SELECT * FROM gamesWiseSpotCount ORDER BY counter DESC

--9 Fetch oldest athlete to win a gold medal

WITH nonaAge AS
(
	select Name, sex, age, team, games, city, sport, event, medal FROM dbo.AthleteEvents
	WHERE age NOT IN('NA') AND Medal = 'Gold' 
),
oldGoldMedal AS
(
	SELECT * FROM nonaAge WHERE Age = (SELECT MAX(Age) FROM nonaAge) 
)
SELECT * FROM oldGoldMedal


--10

--DECLARE @male FLOAT;
--DECLARE @female FLOAT;
--WITH male AS
--(
--	(SET @male = (SELECT COUNT(*) as maleCount from dbo.athleteEvents WHERE sex = 'M'))
--),
--female AS
--(
--	SELECT COUNT(*) as femaleCount FROM dbo.AthleteEvents WHERE sex = 'F'
--)
--((SELECT maleCount FROM male)/(SELECT femaleCount FROM female))

--11
WITH goldMedal AS
(
	SELECT Name, nr.region AS region, medal FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions nr
	ON AE.NOC = nr.NOC
	WHERE medal = 'Gold'
),
playerWise AS
(
	SELECT Name, region, COUNT(Name) AS medalCount FROM goldMedal GROUP BY name,region
)

SELECT * FROM playerWise ORDER BY medalCount DESC

--12
WITH Medals AS
(
	SELECT Name, nr.region AS region, medal FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions nr
	ON AE.NOC = nr.NOC
	WHERE medal NOT IN('NA')
),
playerWise AS
(
	SELECT Name, region,  COUNT(Medal) AS medalCount FROM Medals GROUP BY name,region
)

SELECT * FROM playerWise ORDER BY medalCount DESC

--13
WITH goldMedal AS
(
	SELECT nr.region AS region, medal FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions nr
	ON AE.NOC = nr.NOC
	WHERE medal NOT IN ('NA')
),
playerWise AS
(
	SELECT region, COUNT(medal) AS medalCount, ROW_NUMBER() OVER(ORDER BY COUNT(medal) DESC) AS rank  FROM goldMedal GROUP BY region
)

SELECT * FROM playerWise 
--ORDER BY medalCount DESC


--14
WITH Medals AS
(
	SELECT nr.region AS region, medal FROM dbo.AthleteEvents AE
	JOIN dbo.nocRegions nr
	ON AE.NOC = nr.NOC
	WHERE medal NOT IN ('NA')
),
goldWise AS
(
	SELECT region, COUNT(medal) AS goldCount FROM Medals WHERE medal= 'Gold' GROUP BY region 
),
silverWise AS 
(
	SELECT region, COUNT(medal) AS silverCount FROM Medals WHERE medal= 'Silver' GROUP BY region 
),
bronzeWise AS 
(
	SELECT region, COUNT(medal) AS bronzeCount FROM Medals WHERE medal= 'Bronze' GROUP BY region 
)
SELECT DISTINCT (me.region),gw.goldCount, sw.silverCount, bw.bronzeCount FROM medals me
JOIN goldWise   gw ON gw.region = me.region
JOIN silverWise sw ON sw.region = me.region
JOIN bronzewise bw ON bw.region = me.region
ORDER BY gw.goldCount DESC




with t1 as (
     --using this CTE to PIVOT medal rows into Columns
	Select Medal, n.region as Country,
		  case when Medal like '%Gold%' then 'Gold' end as Gold,
		  case when Medal like '%Silver%' then 'Silver' end as Silver,
		  case when Medal like '%Bronze%' then 'Bronze' end as Bronze
	From [dbo].[athleteevents] e
	Join [dbo].[nocregions] n on e.NOC = n.NOC
	--Where Medal like '%Gold%' or Medal like'%Silver%' or Medal like'%Bronze%' 
	--group by Medal, n.region
	),
t2 as (
	--counting the medals for each country
	Select Country, COUNT(Gold) as gold_cnt,COUNT(Silver) as silver_cnt,COUNT(Bronze) as bronze_cnt
	From t1
	group by Country 
	) 
select * , gold_cnt+silver_cnt+bronze_cnt as total
from t2 
order by gold_cnt desc

--15
WITH medalColTab AS
(
	SELECT games, nr.region, 
		CASE WHEN(ae.Medal) LIKE '%Gold' THEN 'Gold' END AS Gold,
		CASE WHEN(ae.Medal) LIKE '%Silver' THEN 'Silver' END AS Silver,
		CASE WHEN(ae.Medal) LIKE '%Bronze' THEN 'Bronze' END AS Bronze
	FROM dbo.AthleteEvents ae
	JOIN dbo.nocRegions nr
	ON ae.NOC = nr.NOC
)
SELECT games, region, COUNT(Gold) AS Gold, COUNT(Silver) AS Silver, COUNT(Bronze) AS Bronze 
FROM medalColTab
GROUP BY games, region
ORDER BY games, region

--16 Identify which country won the most gold, most silver and most bronze medals in each olympic games


