-- Select the Target Database
USE EPC_Manchester;
GO

--------------------------------------------------------------------------------------
-- STEP 1: RAW DATA TABLE SETUP
--------------------------------------------------------------------------------------

-- Drop existing table if it exists to allow for a clean re-creation
IF OBJECT_ID('dbo.epc_raw', 'U') IS NOT NULL
    DROP TABLE dbo.epc_raw;
GO

-- Create the raw data table with all columns as VARCHAR(MAX) to handle all incoming CSV data types without errors
CREATE TABLE dbo.epc_raw (
    -- Identification & Location Columns
    LMK_KEY VARCHAR(MAX),
    ADDRESS1 VARCHAR(MAX),
    ADDRESS2 VARCHAR(MAX),
    ADDRESS3 VARCHAR(MAX),
    POSTCODE VARCHAR(MAX),
    BUILDING_REFERENCE_NUMBER VARCHAR(MAX),

    -- Ratings & Efficiency Columns
    CURRENT_ENERGY_RATING VARCHAR(MAX),
    POTENTIAL_ENERGY_RATING VARCHAR(MAX),
    CURRENT_ENERGY_EFFICIENCY VARCHAR(MAX),
    POTENTIAL_ENERGY_EFFICIENCY VARCHAR(MAX),

    -- Property Details Columns
    PROPERTY_TYPE VARCHAR(MAX),
    BUILT_FORM VARCHAR(MAX),
    
    -- Dates & Admin Columns
    INSPECTION_DATE VARCHAR(MAX),
    LOCAL_AUTHORITY VARCHAR(MAX),
    CONSTITUENCY VARCHAR(MAX),
    COUNTY VARCHAR(MAX),
    LODGEMENT_DATE VARCHAR(MAX),
    TRANSACTION_TYPE VARCHAR(MAX),
    
    -- Environmental & Numeric Data Columns
    ENVIRONMENT_IMPACT_CURRENT VARCHAR(MAX),
    ENVIRONMENT_IMPACT_POTENTIAL VARCHAR(MAX),
    CO2_EMISSIONS_CURRENT VARCHAR(MAX),      
    CO2_EMISSIONS_POTENTIAL VARCHAR(MAX),
    ENERGY_CONSUMPTION_CURRENT VARCHAR(MAX),  
    ENERGY_CONSUMPTION_POTENTIAL VARCHAR(MAX),
    TOTAL_FLOOR_AREA VARCHAR(MAX),           
    MAIN_FUEL VARCHAR(MAX),                  
    
    -- Cost Columns
    HEATING_COST_CURRENT VARCHAR(MAX),
    HEATING_COST_POTENTIAL VARCHAR(MAX),
    HOT_WATER_COST_CURRENT VARCHAR(MAX),
    HOT_WATER_COST_POTENTIAL VARCHAR(MAX),
    LIGHTING_COST_CURRENT VARCHAR(MAX),
    LIGHTING_COST_POTENTIAL VARCHAR(MAX)
);
GO

--------------------------------------------------------------------------------------
-- STEP 2: BULK DATA IMPORT
--------------------------------------------------------------------------------------

-- Import data from the CSV file into the raw table
-- NOTE: The file path 'C:\Temp\certificates.csv' must be accessible by the SQL Server service account
BULK INSERT dbo.epc_raw
FROM 'C:\Temp\certificates.csv'
WITH (
    FIRSTROW = 2,               -- Skip the header row
    FIELDTERMINATOR = ',',      -- CSV delimiter
    ROWTERMINATOR = '0x0a',     -- Standard line feed
    DATAFILETYPE = 'char'
);
GO

-- Verification: Check the count and the first 10 rows of the imported data
SELECT COUNT(*) AS RawRowCount FROM dbo.epc_raw;
SELECT TOP 10 * FROM dbo.epc_raw;
GO

--------------------------------------------------------------------------------------
-- STEP 3: DATA CLEANING AND VIEW CREATION (For Power BI)
--------------------------------------------------------------------------------------

-- Drop the previous cleaned view if it exists
IF OBJECT_ID('dbo.vw_EPC_Cleaned_2014_2024', 'V') IS NOT NULL
    DROP VIEW dbo.vw_EPC_Cleaned_2014_2024;
GO

-- Create a view to perform all cleaning, filtering, and transformation required for analysis
CREATE VIEW dbo.vw_EPC_Cleaned_2014_2024
AS
WITH EPC_Ordinal_Ratings AS (
    SELECT
        T1.LMK_KEY,
        -- Convert Date fields, setting invalid dates to NULL
        TRY_CAST(T1.INSPECTION_DATE AS DATE) AS InspectionDate,
        TRY_CAST(T1.LODGEMENT_DATE AS DATE) AS LodgementDate,
        
        -- Cleanse Energy Ratings (A-G only)
        CASE WHEN T1.CURRENT_ENERGY_RATING IN ('A','B','C','D','E','F','G') THEN T1.CURRENT_ENERGY_RATING ELSE NULL END AS CurrentEnergyRating,
        CASE WHEN T1.POTENTIAL_ENERGY_RATING IN ('A','B','C','D','E','F','G') THEN T1.POTENTIAL_ENERGY_RATING ELSE NULL END AS PotentialEnergyRating,

        -- Select descriptive/location columns
        T1.PROPERTY_TYPE,
        T1.BUILT_FORM,
        T1.POSTCODE,
        T1.LOCAL_AUTHORITY,
        T1.CONSTITUENCY,
        T1.MAIN_FUEL,
        T1.TRANSACTION_TYPE,
        
        -- Convert numeric columns to FLOAT, replacing errors/NULLs with 0 for aggregation safety
        ISNULL(TRY_CAST(T1.CO2_EMISSIONS_CURRENT AS FLOAT), 0) AS CO2EmissionsCurrent,  
        ISNULL(TRY_CAST(T1.ENERGY_CONSUMPTION_CURRENT AS FLOAT), 0) AS EnergyConsumptionCurrent,
        ISNULL(TRY_CAST(T1.TOTAL_FLOOR_AREA AS FLOAT), 0) AS TotalFloorArea, 

        -- Create ordinal ranks (1=A, 7=G) for comparison and analysis
        CASE T1.CURRENT_ENERGY_RATING 
            WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3 WHEN 'D' THEN 4 
            WHEN 'E' THEN 5 WHEN 'F' THEN 6 WHEN 'G' THEN 7 ELSE 8 END AS CurrentRatingRank,
        
        CASE T1.POTENTIAL_ENERGY_RATING 
            WHEN 'A' THEN 1 WHEN 'B' THEN 2 WHEN 'C' THEN 3 WHEN 'D' THEN 4 
            WHEN 'E' THEN 5 WHEN 'F' THEN 6 WHEN 'G' THEN 7 ELSE 8 END AS PotentialRatingRank
            
    FROM 
        dbo.epc_raw AS T1
    WHERE
        -- Filter: Only include records lodged between 2014 and 2024
        TRY_CAST(T1.LODGEMENT_DATE AS DATE) >= '2014-01-01'
        AND TRY_CAST(T1.LODGEMENT_DATE AS DATE) <= '2024-12-31'
)
SELECT 
    *,
    -- Create the KPI flag: 1 if the potential rating is better (lower rank) than the current rating
    CASE 
        WHEN CurrentRatingRank > PotentialRatingRank THEN 1 
        ELSE 0 
    END AS PotentialImprovementFlag
FROM 
    EPC_Ordinal_Ratings
WHERE 
    CurrentEnergyRating IS NOT NULL -- Final filter: Exclude records with unreadable/invalid current ratings
    AND CO2EmissionsCurrent > 0; -- Final filter: Exclude records with zero/null emissions for better averaging

GO

-- Verification: Check the final row count and the first 5 rows of the cleaned view
SELECT COUNT(*) AS CleanedRowCount_2014_2024 FROM dbo.vw_EPC_Cleaned_2014_2024;
SELECT TOP 5 * FROM dbo.vw_EPC_Cleaned_2014_2024;
GO