/*
Middle East Economic Indicators Analysis (2009–2024)
Data Source: World Bank Open Data
Objective: Analyze macroeconomic indicators in the Middle East over 15 years using SQL Server.
*/

-- Explore the dataset
SELECT *
FROM PortfolioProjects..WorldBankData

USE PortfolioProjects
ALTER TABLE WorldBankData
DROP COLUMN Country_Code, Time_Code

-- Aggregated Snapshot for BI Tools
CREATE OR ALTER VIEW ViewCleanData AS SELECT  
    Country_Name AS Country,
    Time AS Year,
    GDP_current AS GDP,
    GDP_per_capita AS GDPPerCapita,
    Population_total AS Population,
    Unemployment_total AS Unemployment,
    External_debt_stocks AS ExternalDebt,
    Trade_of_GDP AS Trade,
    Foreign_direct_investment AS ForeignInvestment,
    Inflation_consumer_prices AS Inflation
FROM WorldBankData

select * from ViewCleanData
ORDER BY 1,2 DESC

-- GDP Growth of Iran by Year
WITH GDP_Growth AS (
    SELECT Country, Year, GDP,
        LAG(GDP, 1) OVER (PARTITION BY Country ORDER BY Year) AS PrevYearGDP
    FROM ViewCleanData
)
SELECT 
    Country, Year, GDP,
    ROUND(((GDP - PrevYearGDP) / NULLIF(PrevYearGDP, 0)) * 100, 2) AS GDPGrowthPercent
FROM GDP_Growth
WHERE PrevYearGDP IS NOT NULL AND Country LIKE 'Iran%'
ORDER BY Year

-- Average Unemployment Rate by Country
SELECT 
    Country,
    ROUND(AVG(Unemployment), 2) AS AvgUnemployment
FROM ViewCleanData
WHERE Unemployment IS NOT NULL
GROUP BY Country
ORDER BY AvgUnemployment

-- Ranking Countries by External Debt
SELECT 
    Country,
    Year,
    ExternalDebt,
    RANK() OVER (PARTITION BY Year ORDER BY ExternalDebt DESC) AS DebtRank
FROM ViewCleanData
WHERE ExternalDebt IS NOT NULL
ORDER BY Year, DebtRank

-- Get Indicators by Year
DROP PROCEDURE IF EXISTS GetIndicatorsByYear
GO
CREATE PROCEDURE GetIndicatorsByYear @TargetYear INT
AS
    SELECT
        Country,
        GDP,
        Population,
        Unemployment,
        ExternalDebt,
        Trade,
        ForeignInvestment,
        Inflation
    FROM PortfolioProjects..ViewCleanData
    WHERE Year = @TargetYear 
    ORDER BY GDP DESC

-- Example
EXEC GetIndicatorsByYear @TargetYear = 2022

-- Some Basic Info Insights: 
-- Most Populated Country of Middle East
SELECT TOP 1 Country, Population
FROM ViewCleanData
WHERE Population IS NOT NULL
ORDER BY Population DESC

-- Some Correlations
SELECT 
    CORR(ForeignInvestment, Inflation) AS FICORRINF
FROM ViewCleanData
WHERE ForeignInvestment IS NOT NULL AND Inflation IS NOT NULL;
-- -0.007 As a Result
-- The slight negative value means if anything, there’s a minimal inverse trend

SELECT
    (COUNT(*) * SUM(ForeignInvestment * Unemployment) -
     SUM(ForeignInvestment) * SUM(Unemployment)) /
    SQRT(
        (COUNT(*) * SUM(ForeignInvestment * ForeignInvestment) - POWER(SUM(ForeignInvestment), 2)) *
        (COUNT(*) * SUM(Unemployment * Unemployment) - POWER(SUM(Unemployment), 2))
    ) AS FICORRUNE
FROM ViewCleanData
WHERE ForeignInvestment IS NOT NULL AND Unemployment IS NOT NULL;
-- -0.01 As a Result
-- That meams there’s a weak inverse trend


