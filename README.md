# Energy-Performance-Analysis-of-Manchester-Local-Authorities
Project OverviewThis project provides a comprehensive analysis of the Energy Performance Certificate (EPC) trends for residential properties across Manchester Local Authorities over a ten-year period. The study leverages SQL Server for robust data engineering and Power BI for interactive visualization to track energy efficiency improvements and carbon emission trends.

Key Features
Data Pipeline: Managed the ingestion of the EPC Domestic Dataset (England and Wales) into a SQL environment using BULK INSERT.
Data Transformation: Performed cleaning via SQL Views, utilizing TRY_CAST for date normalization, handling missing values, and implementing rating ranking logic ($A=1$ to $G=7$).
Interactive Dashboard: Developed a Power BI model featuring slicers for Property Type, Constituency, and Energy Rating.
Emission Tracking: Analyzed the relationship between heating fuel types (e.g., Gas vs. Electric) and $CO_{2}$ outputs.

Core Findings
Efficiency Gains: There is a notable shift from lower-rated properties (E-G) toward middle-tier ratings (C-D) between 2014 and 2024.
Emission Reductions: Average $CO_{2}$ emissions have decreased as Manchester's housing stock becomes more energy-efficient.
Fuel Dominance: Gas remains the primary heating fuel, though there is a gradual, slight increase in low-carbon electric alternatives.

Technologies
UsedDatabase: SQL Server (T-SQL)
Visualization: Power BI (DAX) 
Dataset: EPC Domestic Dataset
