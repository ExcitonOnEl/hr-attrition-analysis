-------------------------------
-- PAGE 1 — Attrition Overview
-------------------------------
CREATE VIEW vw_Attrition_Detail AS
SELECT
    e.EmpID,
    e.Employee_Name,
    e.Position,
    e.Department,
    e.ManagerName,
    e.RecruitmentSource,
    e.EmploymentStatus,
    e.TermReason,
    e.DOHire,
    e.DOResignation,
    EXTRACT(YEAR FROM e.DOResignation) AS ResignationYear,
    CASE WHEN e.EmploymentStatus = 'Active' THEN 0 ELSE 1 END AS IsTerminated
FROM Employee_Data e;

-----------------------------
-- PAGE 2 — Why They Leave
-----------------------------
-- Exit reason and performance rating, with root-cause grouping.
-- Powers the Reason and Performance matrix and the root-cause
CREATE VIEW vw_Reason_Performance AS
SELECT
    e.EmpID,
    e.Department,
    e.TermReason,
    p.PerformanceScore,
    CASE WHEN e.EmploymentStatus = 'Active' THEN 0 ELSE 1 END AS IsTerminated,
    CASE WHEN p.PerformanceScore IN ('Exceeds', 'Fully Meets') THEN 1 ELSE 0 END AS IsGoodPerformer,
    CASE
        WHEN e.TermReason IN ('Another position', 'more money') THEN 'Pay / Market'
        WHEN e.TermReason IN ('unhappy', 'career change', 'hours') THEN 'Culture / Workload'
        WHEN e.TermReason IN ('attendance', 'performance', 'no-call, no-show',
                               'gross misconduct', 'Learned that he is a gangster',
                               'Fatal attraction') THEN 'Conduct / Involuntary'
        WHEN e.TermReason IN ('return to school', 'relocation out of area', 'retiring',
                               'military', 'maternity leave - did not return',
                               'medical issues') THEN 'Life Circumstances'
        ELSE 'Other'
    END AS TermCategory
FROM employee_data e
JOIN performance_data p ON e.EmpID = p.EmpID;

-- Leaver behavioral profile: engagement, satisfaction, tenure, absences.
-- Powers the leaver KPI cards and the engagement-by-reason bar chart.
CREATE VIEW vw_Leaver_Profile AS
SELECT
    e.EmpID,
    e.Department,
    e.TermReason,
    EXTRACT(YEAR FROM e.DOResignation) AS ResignationYear,
    ROUND((e.DOResignation - e.DOHire) / 365.25, 2) AS TenureYears,
    p.EngagementSurvey,
    p.EmpSatisfaction,
    p.SpecialProjectsCount,
    p.Absences,
    CASE WHEN e.EmploymentStatus = 'Active' THEN 0 ELSE 1 END AS IsTerminated
FROM employee_data e
JOIN performance_data p ON e.EmpID = p.EmpID;