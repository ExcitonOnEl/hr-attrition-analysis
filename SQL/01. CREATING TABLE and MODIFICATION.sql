-- 1. PERSONAL DATA
CREATE TABLE Personal_Data(
  	EmpID INT PRIMARY KEY,
    Employee_Name VARCHAR(100) NOT NULL,
    DOB VARCHAR(10),
    Sex VARCHAR(10) NOT NULL,
    MaritalDesc VARCHAR(10) NOT NULL,
    CitizenDesc VARCHAR(20) NOT NULL,
    HispanicLatino VARCHAR(20) NOT NULL,
    RaceDesc VARCHAR(20) NOT NULL,
    State VARCHAR(20) NOT NULL,
    Zip VARCHAR(10),
	DateOfBirth DATE
);

-- 2. EMPLOYEE DATA
CREATE TABLE Employee_Data(
	EmpID INT PRIMARY KEY,
    Employee_Name VARCHAR(100) NOT NULL,
    Position VARCHAR(30) NOT NULL,
    Department VARCHAR(30) NOT NULL,
    ManagerName VARCHAR(100),
    ManagerID INT,
    DateofHire VARCHAR(30) NOT NULL,
    DateofTermination VARCHAR(30),
    TermReason VARCHAR(100),
    EmploymentStatus VARCHAR(30),
    RecruitmentSource VARCHAR(30)NOT NULL,
    FromDiversityJobFairID INT NOT NULL,
    Salary INT NOT NULL,
	DOHire DATE,
	DOResignation DATE
);

-- 3. PERFORMANCE DATA
CREATE TABLE Performance_Data (
	EmpID INT PRIMARY KEY,
    Employee_Name VARCHAR(100) NOT NULL,
    PerformanceScore VARCHAR(20) NOT NULL,
    EngagementSurvey FLOAT,
    EmpSatisfaction INT,
    SpecialProjectsCount INT NOT NULL,
    LastPerformanceReview_Date VARCHAR(10) NOT NULL,
    DaysLateLast30 INT NOT NULL,
    Absences INT NOT NULL,
    LastReviewDATE DATE
);

---- Konversi Salah Variabel, not necessary to change the data type of ManagerID and RaceDesc if the data is already in the correct format. 
-- However, if you want to ensure that the data types are consistent, you can use the following ALTER TABLE statements:
ALTER TABLE employee_data ALTER COLUMN ManagerID TYPE NUMERIC;
ALTER TABLE personal_data ALTER COLUMN RaceDesc TYPE VARCHAR(50);

---- Date modification, because the date format in the original data is not consistent, 
-- we need to convert the date strings to proper DATE format using TO_DATE function. The following UPDATE statements will convert the date strings to DATE format for each relevant column in the tables.
UPDATE personal_data
	SET DateOfBirth = TO_DATE(LEFT(DOB,6) ||'19'||RIGHT(DOB,2),'MM/DD/YYYY')
	WHERE DOB IS NOT NULL AND DOB !=' ';

UPDATE Employee_Data
	SET DOHire = TO_DATE (DateofHire,'MM/DD/YYYY')
	WHERE DateofHire IS NOT NULL AND DateofHire !=' ';

UPDATE Employee_Data
	SET DOResignation = TO_DATE(DateofTermination, 'MM/DD/YYYY')
	WHERE DateofTermination IS NOT NULL 
  		AND DateofTermination != '' 
 		AND DateofTermination != ' ';

UPDATE Performance_Data
	SET LastReviewDATE = TO_DATE(LastPerformanceReview_Date,'MM/DD/YYYY')
	WHERE LastPerformanceReview_Date IS NOT NULL AND LastPerformanceReview_Date !=' ';