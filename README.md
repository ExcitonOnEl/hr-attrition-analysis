# HR Attrition Analysis using SQL + Power BI

This is a two-page Power BI report built from a raw HR export. The question behind it is one a manager can actually do something about: are we losing the people we wanted to keep, and if so, why?

The answer was a bit uncomfortable. 85.6% of the people who left were rated Fully Meets or Exceeds, so the company is mostly losing good performers rather than weak ones.

![Page 1: Attrition Overview](Images/Atrrition%20Overview_page-0001.jpg)

---

## Context first (before I made any charts)

I based the approach on Cole Nussbaumer Knaflic's *Storytelling with Data: A Data Visualization Guide for Business Professionals*. Her point is that you work out the context before you open any charting tool: who the audience is, what they need to do, and what the data needs to tell them. If you skip that step you tend to end up with a page full of charts that nobody acts on.

Here's how that played out for this project.

**Who:** an Organisation Development or HR lead who owns retention and has a limited budget for interventions.

**What they need to do:** decide where that budget goes. A pay problem and a management problem need different fixes, and picking the wrong one wastes money and time.

**What the data has to say:** most of the exits are regrettable, and the causes OD can fix are split almost evenly between pay and culture. A compensation review by itself would only deal with about half of them.

Every visual on the two pages is there to back up that last point. I dropped anything that didn't help.

---

## The questions

**Page 1: how bad is it, and where?**
1. What is the overall turnover rate?
2. Which department carries the most risk?
3. What reasons do people give for leaving?

**Page 2: why, and can we do anything about it?**
4. Are the leavers good performers or poor ones?
5. Does low engagement or satisfaction show up before people go?
6. Which root causes can OD influence, and which are outside its reach?

---

## From raw file to answer

**1. Got the dataset.** I used the [Human Resources Data Set](https://www.kaggle.com/datasets/rhuebner/human-resources-data-set) (HRDataset_v14). It has 311 employees in one wide CSV, with demographics, employment history and performance all in the same table.

**2. Split it into three tables.** A flat file works in a spreadsheet but makes a messy data model. I broke it into `Personal_Data`, `Employee_Data` and `Performance_Data`, keyed on `EmpID`, so the joins stay simple. (`SQL/01. CREATING TABLE and MODIFICATION.sql`)

**3. Fixed the dates.** Every date came in as text in `MM/DD/YYYY`, and birth dates only had a two-digit year. I parsed each one into a proper `DATE` column and kept the original string next to it so I could check my work.

**4. Built analysis views.** There are three views, one for each part of the report. They're all row-level so the Power BI slicers can filter them. (`SQL/02. CREATING VIEW.sql`)

- `vw_Attrition_Detail`: one row per employee, with a resignation year and a terminated flag. Used on Page 1.
- `vw_Reason_Performance`: exit reason against performance rating, plus a root-cause category. Used for the Page 2 matrix and category chart.
- `vw_Leaver_Profile`: engagement, satisfaction, tenure and absences. Used for the Page 2 cards and engagement chart.

**5. Validated everything.** I checked row counts, the terminated split, the regrettable-loss count, category totals and tenure ranges, and wrote the expected value next to each check. (`SQL/03. TABLE and VIEW Validation.sql`)

**6. Modelled and visualised in Power BI.** I wrote DAX measures for turnover rate, regrettable loss rate and the leaver averages, and synced the Department and Year slicers across both pages.

---

## Problems I ran into

**Two-digit birth years.** Postgres reads a two-digit year as the current century, so `to_date('07/10/83', ...)` gives you 2083 instead of 1983. All the birth years in this file fall between 1951 and 1992, so I hardcoded a `19` prefix. It wouldn't work for every dataset, but I checked the range first and it's correct for this one.

**A tenure bug I almost missed.** My first tenure calculation wrapped the date subtraction in `EXTRACT(EPOCH ...)`. In Postgres, `date - date` returns an integer number of days, not an interval, and `EXTRACT` won't accept an integer, so the view would have failed. I removed the wrapper and divided the day count by 365.25 instead.

**Views that couldn't be filtered.** My first attempt summarised turnover by department inside SQL. That looked fine until I added the Year slicer and realised the yearly detail was already gone, so the filter had nothing to work with. I rebuilt the views at row level and let Power BI handle the aggregation, and after that the slicers worked.

**Active employees in the reasons chart.** Current staff have `TermReason = 'N/A-StillEmployed'`, so my first "top reasons" chart had a 207-person bar at the top that pushed the real reasons down. A visual-level filter on the terminated flag fixed it. It's an easy one to miss.

**No fixed observation window.** The dataset doesn't give a clean period per employee to annualise over. So I report cumulative turnover (everyone who has left divided by everyone in the file) and label it that way, rather than calling it an annual rate.

---

## Why I picked each chart

**Turnover rate by department: horizontal bars instead of a donut.**
I started with a donut and then dropped it. A donut shows what share of all leavers came from each department, but the question I cared about was which department loses the biggest fraction of its own staff. The bar chart shows that rate directly, sorts from worst to best, and is much easier to compare than pie slices. I also added a colour gradient so the ranking is visible from the shading as well as the length.

**Top reasons for leaving: ranked horizontal bars.**
This one is about ranking categories, and some labels are long ("career change", "no-call, no-show"). Horizontal bars keep the labels readable, and sorting by count puts the biggest reason at the top.

**Reason × performance: a shaded matrix.**
Page 2 depends on seeing two things together: why someone left and how well they were performing. A matrix shows both at once. I shaded the cells red where strong performers cluster, so the pattern stands out before you read the numbers.

**Engagement by reason: bars with a baseline.**
There's one engagement number per reason, so plain bars are enough. What makes the chart useful is the reference line at the retained-employee average. A score of 3.9 doesn't look bad on its own, but next to a 4.12 baseline you can see which groups had already disengaged before they left.

**Root cause: four bars, two in colour and two in grey.**
I'd point a manager to this chart first. I grouped seventeen exit reasons into four causes, and the two that OD can influence, Pay and Culture, are tied at 31 people each. Those two are coloured and the other two are grey, which makes it obvious where the effort should go.

![Page 2: Why Are They Leaving](Images/Atrrition%20Overview_page-0002.jpg)

---

## What I found

85.6% of exits are regrettable. The people leaving are mostly good at their jobs.

The fixable causes are split evenly. Pay/Market (31) and Culture/Workload (31) are tied, and OD has some control over both. A compensation review would only cover half of that, so it needs to go alongside manager coaching and a proper look at workload. The other two causes, Life Circumstances (24) and Conduct (18), aren't really things a retention programme can change, so I'd keep an eye on them but not spend budget there.

If you have to pick one place to start, I'd pick Production. It has the highest turnover rate and the most staff, so it loses the most people in absolute terms.

---

## Limitations

**It's a lifetime rate, not an annual one.** The turnover figure covers the whole dataset. "About a third of everyone who's worked here has left" is accurate. "A third of staff leave every year" is not.

**Small departments are noisy.** Software Engineering shows 36% turnover, but that's out of eleven people, so two exits shift it a lot. I'd trust the rates for the big departments more than the small ones.

**Page 2 gets thin when you filter it.** Once you split leavers by reason, several rows are down to one or two people. An average engagement score based on one person doesn't tell you much.

**Exit forms aren't always honest.** Reasons like "another position" and "more money" come from exit paperwork, and someone leaving because of a bad manager will often write down something more polite. I'd treat the reasons as a starting point for follow-up.

**This doesn't prove cause.** Low engagement among the "unhappy" leavers doesn't show that disengagement is what made them leave. The report points to where to look, but it can't confirm the cause.

---

## What I'd do next

- Recalculate turnover per year once there's a defined time window, so it can be properly annualised.
- Add manager-level data to see whether the "unhappy" and "career change" groups come from particular teams rather than whole departments.
- Bring recruitment source into the performance view to check whether some hiring channels produce people who both perform better and stay longer.
- If real exit-interview notes exist, compare them with the checkbox reasons to see how much they differ.

---

## Repository

```
HR_Atrittion_Analysis/
├── SQL/
│   ├── 01. CREATING TABLE and MODIFICATION.sql
│   ├── 02. CREATING VIEW.sql
│   └── 03. TABLE and VIEW Validation.sql
├── Power BI/
│   └── Atrrition Overview.pbix
└── Images/
    ├── Atrrition Overview_page-0001.jpg
    └── Atrrition Overview_page-0002.jpg
```

## Tools

PostgreSQL · pgAdmin · Power BI Desktop · DAX

## Data

[Human Resources Data Set (HRDataset_v14)](https://www.kaggle.com/datasets/rhuebner/human-resources-data-set): 311 employees, 36 columns.
