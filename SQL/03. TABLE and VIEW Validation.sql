--- 0. Table Validation
-------------------------
-- 0.1 Validation
SELECT COUNT(*) FROM Personal_Data;    -- should be 311
SELECT COUNT(*) FROM Employee_Data;    -- should be 311
SELECT COUNT(*) FROM Performance_Data; -- should be 311

-- 0.2 Validation -spot-check the generated date columns actually computed
SELECT EmpID, DOB, DateofBirth FROM Personal_Data LIMIT 5;
SELECT EmpID, lastperformancereview_date, lastreviewdate FROM public.performance_data LIMIT 5;
SELECT EmpID, dateofhire, dohire, dateoftermination, doresignation FROM public.employee_data;




--- 1. Page 1 - Attrition detail validation
-----------------------------------------------
-- 1.1 Row count should match total employees
SELECT COUNT(*) FROM vw_Attrition_Detail;  -- expect 311
 
-- 1.2 Leavers only (ResignationYear populated only for terminated)
SELECT COUNT(*) FROM vw_Attrition_Detail
WHERE ResignationYear IS NOT NULL;  -- expect 104

-- 1.3 IsTerminated flag should split 207 active / 104 terminated
SELECT IsTerminated, COUNT(*)
FROM vw_Attrition_Detail
GROUP BY IsTerminated;  -- expect 0 -> 207, 1 -> 104



--- 2. Page 2 - vw validation
---------------------------
-- 2.1 Validation vw page 2, vw_Reason_Performance
SELECT TermCategory, COUNT(*) FROM vw_Reason_Performance
WHERE IsTerminated = 1
GROUP BY TermCategory ORDER BY COUNT(*) DESC;
-- expect: Pay/Market 31, Culture/Workload 31, Life Circumstances 24, Conduct/Involuntary 18

-- 2.2 Validation vw page 2, vw,Leaver_Profile
-- Row count should match total employees
SELECT COUNT(*) FROM vw_Leaver_Profile;  -- expect 311
 
-- 2.3 Tenure sanity: no negative tenure, no absurd outliers
SELECT MIN(TenureYears), MAX(TenureYears)
FROM vw_Leaver_Profile
WHERE IsTerminated = 1;
-- expect MIN > 0, MAX reasonable (single digits given hire-date range)