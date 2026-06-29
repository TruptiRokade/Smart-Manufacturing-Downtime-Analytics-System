CREATE DATABASE smart_manufacturing;
USE smart_manufacturing;
select count(*)
from smart_manufacturing_downtime_dataset;
ALTER TABLE smart_manufacturing_downtime_dataset
ADD COLUMN New_Date DATE;
SET SQL_SAFE_UPDATES = 0;

UPDATE smart_manufacturing_downtime_dataset
SET New_Date = STR_TO_DATE(Date,'%m/%d/%Y');
SELECT Date, New_Date
FROM smart_manufacturing_downtime_dataset
LIMIT 20;

-- 1. Total downtime by plant
SELECT Plant_ID, Plant_Location,
       SUM(Downtime_Minutes) AS Total_Downtime_Mins,
       ROUND(SUM(Downtime_Minutes) / 60.0, 1) AS Total_Downtime_Hours
FROM smart_manufacturing_downtime_dataset
GROUP BY Plant_ID, Plant_Location
ORDER BY Total_Downtime_Mins DESC;

-- 2. Average downtime by machine type
SELECT Machine_Type,
       COUNT(*) AS Incident_Count,
       ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
       SUM(Downtime_Minutes) AS Total_Downtime
FROM smart_manufacturing_downtime_dataset
GROUP BY Machine_Type
ORDER BY Avg_Downtime DESC;

-- 3. Downtime by shift
SELECT Shift,
       COUNT(*) AS Incidents,
       ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
       SUM(Downtime_Minutes) AS Total_Downtime
FROM smart_manufacturing_downtime_dataset
GROUP BY Shift
ORDER BY Total_Downtime DESC;

-- 4. Failure type analysis
SELECT Failure_Type,
       COUNT(*) AS Incidents,
       ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
       ROUND(AVG(Repair_Time_Minutes), 1) AS Avg_Repair_Time,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Maint_Cost
FROM smart_manufacturing_downtime_dataset
GROUP BY Failure_Type
ORDER BY Total_Maint_Cost DESC;

-- 5. Pending incident backlog by plant
SELECT Plant_Location, Status,
       COUNT(*) AS Incidents,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Plant_Location), 1) AS Pct
FROM smart_manufacturing_downtime_dataset
GROUP BY Plant_Location, Status;

-- 6. Monthly production loss trend
SELECT DATE_FORMAT(New_Date, '%Y-%m') AS Year__Month,
       ROUND(SUM(Production_Loss_Value), 2) AS Monthly_Loss_Value,
       SUM(Production_Loss_Units) AS Monthly_Loss_Units
FROM smart_manufacturing_downtime_dataset
GROUP BY DATE_FORMAT(New_Date, '%Y-%m')
ORDER BY Year__Month;

-- 7. Top 10 repeat-offender machines
SELECT Machine_ID, Machine_Type, Plant_Location,
       COUNT(*) AS Failure_Count,
       SUM(Downtime_Minutes) AS Total_Downtime,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Cost
FROM smart_manufacturing_downtime_dataset
GROUP BY Machine_ID, Machine_Type, Plant_Location
ORDER BY Failure_Count DESC
LIMIT 10;

-- 8. Technician performance ranking
SELECT Technician_ID,
       COUNT(*) AS Jobs_Handled,
       ROUND(AVG(Repair_Time_Minutes), 1) AS Avg_Repair_Time,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Cost_Handled
FROM smart_manufacturing_downtime_dataset
WHERE Status = 'Resolved'
GROUP BY Technician_ID
ORDER BY Avg_Repair_Time ASC
LIMIT 15;

-- 9. Seasonal downtime pattern (monthly)
SELECT MONTH(New_Date) AS Month_Num,
       MONTHNAME(New_Date) AS Month_Name,
       COUNT(*) AS Incidents,
       ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
       ROUND(SUM(Production_Loss_Value), 2) AS Total_Loss_Value
FROM smart_manufacturing_downtime_dataset
GROUP BY MONTH(New_Date), MONTHNAME(New_Date)
ORDER BY Month_Num;

-- 10. Year-over-year downtime comparison
SELECT YEAR(New_Date) AS Year,
       COUNT(*) AS Total_Incidents,
       SUM(Downtime_Minutes) AS Total_Downtime,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Maint_Cost,
       ROUND(SUM(Production_Loss_Value), 2) AS Total_Prod_Loss
FROM smart_manufacturing_downtime_dataset
GROUP BY YEAR(New_Date)
ORDER BY Year;

-- 11. Failure type distribution per plant
SELECT Plant_Location, Failure_Type,
       COUNT(*) AS Incidents,
       ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (PARTITION BY Plant_Location), 1) AS Pct_of_Plant
FROM smart_manufacturing_downtime_dataset
GROUP BY Plant_Location, Failure_Type
ORDER BY Plant_Location, Incidents DESC;

-- 12. Operators associated with Human Errors
SELECT Operator_ID,
       COUNT(*) AS Human_Error_Count,
       SUM(Downtime_Minutes) AS Total_Downtime_Caused
FROM smart_manufacturing_downtime_dataset
WHERE Failure_Type = 'Human Error'
GROUP BY Operator_ID
ORDER BY Human_Error_Count DESC
LIMIT 10;

-- 13. Repair efficiency ratio by failure type
SELECT Failure_Type,
       ROUND(AVG(Repair_Time_Minutes * 1.0 / NULLIF(Downtime_Minutes, 0)), 3) AS Repair_Efficiency_Ratio
FROM smart_manufacturing_downtime_dataset
GROUP BY Failure_Type
ORDER BY Repair_Efficiency_Ratio ASC;

-- 14. Top root causes overall
SELECT Root_Cause, Failure_Type,
       COUNT(*) AS Occurrences,
       ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime
FROM smart_manufacturing_downtime_dataset
GROUP BY Root_Cause, Failure_Type
ORDER BY Occurrences DESC
LIMIT 15;

-- 15. Quarterly KPI summary
SELECT YEAR(New_Date) AS Year,
       QUARTER(New_Date) AS Quarter,
       COUNT(*) AS Incidents,
       SUM(Downtime_Minutes) AS Total_Downtime,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Maint_Cost,
       ROUND(SUM(Production_Loss_Value), 2) AS Total_Prod_Loss,
       ROUND(AVG(Repair_Time_Minutes), 1) AS Avg_Repair_Time
FROM smart_manufacturing_downtime_dataset
GROUP BY YEAR(New_Date), QUARTER(New_Date)
ORDER BY Year, Quarter;

-- 16. Cost per downtime minute by failure type
SELECT Failure_Type,
       ROUND(SUM(Maintenance_Cost) / NULLIF(SUM(Downtime_Minutes), 0), 2) AS Cost_Per_Downtime_Minute
FROM smart_manufacturing_downtime_dataset
GROUP BY Failure_Type
ORDER BY Cost_Per_Downtime_Minute DESC;

-- 17. Machines with downtime > 50 incidents in a year
SELECT Machine_ID, YEAR(new_Date) AS Year,
       COUNT(*) AS Annual_Failures
FROM smart_manufacturing_downtime_dataset
GROUP BY Machine_ID, YEAR(New_Date)
HAVING COUNT(*) > 50
ORDER BY Annual_Failures DESC;

-- 18. Night shift vs other shifts comparison
SELECT
    CASE WHEN Shift = 'Night' THEN 'Night' ELSE 'Day/Afternoon' END AS Shift_Group,
    COUNT(*) AS Incidents,
    ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
    ROUND(AVG(Maintenance_Cost), 2) AS Avg_Cost
FROM smart_manufacturing_downtime_dataset
GROUP BY CASE WHEN Shift = 'Night' THEN 'Night' ELSE 'Day/Afternoon' END;

-- 19. Total financial impact by plant
SELECT Plant_Location,
       ROUND(SUM(Maintenance_Cost), 2) AS Total_Maint_Cost,
       ROUND(SUM(Production_Loss_Value), 2) AS Total_Prod_Loss,
       ROUND(SUM(Maintenance_Cost) + SUM(Production_Loss_Value), 2) AS Total_Impact
FROM smart_manufacturing_downtime_dataset
GROUP BY Plant_Location
ORDER BY Total_Impact DESC;

-- 20. Average time to resolve by plant and failure type
SELECT Plant_Location, Failure_Type,
       ROUND(AVG(Repair_Time_Minutes), 1) AS Avg_Repair_Min
FROM smart_manufacturing_downtime_dataset
WHERE Status = 'Resolved'
GROUP BY Plant_Location, Failure_Type
ORDER BY Plant_Location, Avg_Repair_Min DESC;

-- 21. Monthly incidents by failure type (pivot-style)
SELECT DATE_FORMAT(New_Date, '%Y-%m') AS Month,
       SUM(CASE WHEN Failure_Type = 'Mechanical Failure' THEN 1 ELSE 0 END) AS Mechanical,
       SUM(CASE WHEN Failure_Type = 'Electrical Failure' THEN 1 ELSE 0 END) AS Electrical,
       SUM(CASE WHEN Failure_Type = 'Sensor Failure' THEN 1 ELSE 0 END) AS Sensor,
       SUM(CASE WHEN Failure_Type = 'Overheating' THEN 1 ELSE 0 END) AS Overheating,
       SUM(CASE WHEN Failure_Type = 'Hydraulic Leak' THEN 1 ELSE 0 END) AS Hydraulic,
       SUM(CASE WHEN Failure_Type = 'Human Error' THEN 1 ELSE 0 END) AS Human_Error,
       SUM(CASE WHEN Failure_Type = 'Power Failure' THEN 1 ELSE 0 END) AS Power_Failure
FROM smart_manufacturing_downtime_dataset
GROUP BY DATE_FORMAT(New_Date, '%Y-%m')
ORDER BY Month;

-- 22. Downtime severity classification
SELECT
    CASE
        WHEN Downtime_Minutes <= 30 THEN 'Low (0–30 min)'
        WHEN Downtime_Minutes <= 120 THEN 'Medium (31–120 min)'
        WHEN Downtime_Minutes <= 240 THEN 'High (121–240 min)'
        ELSE 'Critical (>240 min)'
    END AS Severity,
    COUNT(*) AS Incidents,
    ROUND(AVG(Maintenance_Cost), 2) AS Avg_Cost,
    ROUND(SUM(Production_Loss_Value), 2) AS Total_Loss
FROM smart_manufacturing_downtime_dataset
GROUP BY 1
ORDER BY MIN(Downtime_Minutes);

-- 23. Running total of maintenance cost per plant (monthly)
SELECT Plant_Location,
       DATE_FORMAT(New_Date, '%Y-%m') AS Month,
       ROUND(SUM(Maintenance_Cost), 2) AS Monthly_Cost,
       ROUND(SUM(SUM(Maintenance_Cost)) OVER (PARTITION BY Plant_Location ORDER BY DATE_FORMAT(New_Date, '%Y-%m')), 2) AS Running_Total
FROM smart_manufacturing_downtime_dataset
GROUP BY Plant_Location, DATE_FORMAT(New_Date, '%Y-%m')
ORDER BY Plant_Location, Month;

-- 24. Incident resolution rate by technician (min. 100 jobs)
SELECT Technician_ID,
       COUNT(*) AS Total_Jobs,
       SUM(CASE WHEN Status = 'Resolved' THEN 1 ELSE 0 END) AS Resolved,
       ROUND(SUM(CASE WHEN Status = 'Resolved' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Resolution_Rate_Pct
FROM smart_manufacturing_downtime_dataset
GROUP BY Technician_ID
HAVING COUNT(*) >= 100
ORDER BY Resolution_Rate_Pct DESC;

-- 25. Weekend vs weekday downtime pattern
SELECT
    CASE WHEN DAYOFWEEK(New_Date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END AS Day_Type,
    COUNT(*) AS Incidents,
    ROUND(AVG(Downtime_Minutes), 1) AS Avg_Downtime,
    ROUND(SUM(Production_Loss_Value), 2) AS Total_Loss
FROM smart_manufacturing_downtime_dataset
GROUP BY CASE WHEN DAYOFWEEK(New_Date) IN (1, 7) THEN 'Weekend' ELSE 'Weekday' END;
