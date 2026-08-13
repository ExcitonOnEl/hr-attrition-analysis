# HR Attrition Analysis using SQL + Power BI

A two-page Power BI report that starts from a raw HR export and ends with a question a manager can act on: are we losing the people we wanted to keep, and if so, why?

The short answer turned out to be uncomfortable. 85.6% of the people who left were rated Fully Meets or Exceeds. This company isn't shedding weak performers. It's losing good ones.

![Page 1 — Attrition Overview](Images/Atrrition%20Overview_page-0001.jpg)

---

## Context first (before any chart got made)

I built this around the *Storytelling with Data: A Data Visualization Guide for Business Professionals* by Cole Nussbaumer Knaflic, which argues that you sort out the context before you touch a single visual. Three questions come before the design work: who is this for, what do they need to do with it, and what is the single thing the data needs to say. Skip that and you get a wall of charts that impresses nobody and changes nothing.

So the context here:

**Who** : an Organisation Development or HR lead who owns retention and has a limited budget for interventions.

**What they need to do** : decide where to spend that budget. A pay problem and a management problem need different money and different people. Guessing wrong wastes both.

**The one thing the data has to say** : most of the exits are regrettable, and the fixable causes split almost evenly between pay and culture, so a compensation review on its own only addresses half of them.

Everything on the two pages exists to support that sentence. If a chart didn't help someone act on it, it didn't make the cut.

---

## The questions

**Page 1 — how bad is it, and where?**
1. What is the overall turnover rate?
2. Which department carries the most risk?
3. What reasons do people give for leaving?

**Page 2 — why, and can we do anything about it?**
4. Are the leavers good performers or poor ones?
5. Is low engagement or satisfaction visible before people go?
6. Which root causes can OD actually influence, and which are outside its reach?

---

## From raw file to answer

**1. Got the dataset.** The [Human Resources Data Set](https://www.kaggle.com/datasets/rhuebner/human-resources-data-set) (HRDataset_v14) — 311 employees, one wide CSV with demographics, employment history, and performance all jammed into a single table.

**2. Split it into three tables.** One flat file is fine for a spreadsheet and bad for a model. I broke it into `Personal_Data`, `Employee_Data`, and `Performance_Data`, keyed on `EmpID`, so each concern lives on its own and joins stay clean. (`SQL/01. CREATING TABLE and MODIFICATION.sql`)

**3. Fixed the dates.** Every date arrived as text in `MM/DD/YYYY`, and birthdays came in with a two-digit year. I parsed each one into a real `DATE` column and left the original string beside it, so nothing got silently overwritten.

**4. Built analysis views.** Three views, each mapped to one part of the report, all row-level so Power BI slicers can filter and recalculate live. (`SQL/02. CREATING VIEW.sql`)

- `vw_Attrition_Detail` = one row per employee, with a resignation year and a terminated flag. Feeds Page 1.
- `vw_Reason_Performance` = exit reason crossed with performance rating, plus a root-cause category. Feeds the Page 2 matrix and the category chart.
- `vw_Leaver_Profile` = engagement, satisfaction, tenure, absences. Feeds the Page 2 cards and the engagement chart.

**5. Validated everything.** Row counts, the terminated split, the regrettable-loss count, category totals, tenure sanity. Each check has its expected value written next to it. (`SQL/03. TABLE and VIEW Validation.sql`)

**6. Modelled and visualised in Power BI.** DAX measures for turnover rate, regrettable loss rate, and the leaver averages, with Department and Year slicers synced across both pages.

---

## Constraints, and what I did about them

**Two-digit birth years.** Postgres reads a two-digit year against the current century, so `to_date('07/10/83', ...)` returns 2083, not 1983. Every birth year in the file falls between 1951 and 1992, so I hardcoded a `19` prefix. Blunt, but it's right for this data, and I checked before trusting it.

**A date-difference bug I nearly shipped.** My first tenure calculation wrapped the date subtraction in `EXTRACT(EPOCH ...)`. It turns out `date - date` in Postgres returns an integer number of days, not an interval, and `EXTRACT` refuses to run on an integer. The view would have failed outright. The fix was to drop the wrapper and divide the day count by 365.25. Simpler, and it actually runs.

**Pre-aggregated views that couldn't be filtered.** My first attempt summarised turnover by department inside SQL. It looked fine until I added the Year slicer and realised the yearly detail had already been collapsed away, so the filter had nothing to bite on. I rebuilt the views at the row level and let Power BI do the aggregating, which is what made the slicers work.

**An active-employee value that poisoned a chart.** Active staff carry `TermReason = 'N/A-StillEmployed'`, so a naive "top reasons" chart put a 207-person bar at the top and buried the real reasons. A visual-level filter on the terminated flag fixes it. Easy to miss, ugly when you do.

**The dataset has no fixed observation window.** There's no clean per-employee period to annualise over, so I report cumulative turnover (everyone who ever left over everyone in the file) and label it as such rather than dressing it up as an annual rate it isn't.

---

## Why each chart is the chart it is

**Turnover rate by department — horizontal bars, not a donut.**
I actually started with a donut here and threw it out. A donut answers "what share of leavers came from each department," which is a different question from "which department loses the highest fraction of its own people." The bar chart shows the real rate, sorts cleanly from worst to best, and lets you compare two departments by length instead of by guessing at pie slices. The bars carry a colour gradient too, so the ranking reads twice — once by length, once by shade.

**Top reasons for leaving — ranked horizontal bars.**
This is a rank-the-categories question with long text labels like "career change" and "no-call, no-show." Horizontal bars let the labels sit flat and readable, and sorting by count puts the biggest problem on top where the eye lands first.

**Reason × performance — a heat-shaded matrix.**
Page 2 hinges on two facts sitting together: why someone left, and how good they were. A matrix is the one layout that shows both axes at once. Shading the cells red where the strong performers pile up means you spot the problem before you've read a single number.

**Engagement by reason — bars against a baseline.**
Engagement is one number per reason, so bars are enough. The trick is the reference line at the retained-employee average. Without it, 3.9 looks fine. Against a 4.12 baseline, you can see which groups were quietly checked out before they left.

**Root cause — four bars, two coloured, two greyed.**
This is the panel that earns the budget. Grouping seventeen messy reasons into four causes shows that the two OD can actually move, Pay and Culture, are tied at 31 people each. Colouring those two and greying the other two makes the argument without a sentence of explanation: here is where to look, here is where not to bother.

![Page 2 — Why Are They Leaving](Images/Atrrition%20Overview_page-0002.jpg)

---

## The verdict

85.6% of exits are regrettable. The company is losing good people, not weak ones.

The fixable causes split down the middle. Pay/Market (31) and Culture/Workload (31) are tied, and both sit inside OD's control. A compensation review on its own only touches half of them, so it has to run alongside manager coaching and an honest look at workload. The other two causes, Life Circumstances (24) and Conduct (18), aren't things you can retain someone out of, so they belong on a watch list rather than a budget line.

If you can only start in one place, start with Production. It has the highest turnover rate and the largest headcount, which makes it the biggest absolute loss in the building.

---

## Where this analysis is thin

**It's a lifetime rate, not an annual one.** The turnover figure covers the whole span of the dataset. Read as "a third of everyone who's worked here has left," it's accurate. Read as "a third leave every year," it's wrong.

**Small departments swing hard.** Software Engineering posts a 36% turnover rate off eleven people, and two exits move a number that small a long way. The big department bars mean something. The tiny ones deserve a raised eyebrow, not a reorg.

**Page 2 runs thin once you slice it.** Split the leavers by reason and several rows drop to one or two people. An average engagement score built on a single person isn't a finding. It's an anecdote wearing a decimal point.

**Nobody tells the exit form the whole truth.** "Another position" and "more money" come off exit paperwork. Someone escaping a bad manager often writes down the polite version instead. The reasons are a lead worth chasing, not a diagnosis to bank on.

**And none of this proves cause.** Low engagement sitting next to the "unhappy" leavers doesn't mean the disengagement pushed them out the door. The dashboard shows you where to look. It can't tell you that you've found it.

---

## What I'd do next

Rerun turnover per year once the window is defined, so the number can be annualised properly. Bring in manager-level detail to see whether the "unhappy" and "career change" clusters trace back to specific teams rather than whole departments. Pull recruitment source into the performance view to check whether some hiring channels produce both stronger performers and longer stayers. And if real exit-interview text exists, run it against the checkbox reasons to see how far the two diverge.

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

[Human Resources Data Set (HRDataset_v14)](https://www.kaggle.com/datasets/rhuebner/human-resources-data-set) — 311 employees, 36 columns.
