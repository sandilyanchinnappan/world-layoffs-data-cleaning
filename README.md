# World Layoffs Data Cleaning & Preprocessing (MySQL)

## 📌 Project Overview
Data cleaning is a critical first step in the data analytics lifecycle. Raw, unrefined datasets often contain duplicate records, inconsistent formatting, structural anomalies, and missing values that can lead to skewed analyses and flawed business decisions.

This project demonstrates a comprehensive end-to-end data cleaning workflow using **MySQL Workbench** on a real-world dataset covering global technological and corporate layoffs. The goal is to transform messy, unorganized raw data into a reliable, standardized, and production-ready staging environment suitable for exploratory data analysis (EDA) and reporting.

---

## 🏗️ Architecture & Data Staging Strategy

A primary rule of data engineering and database administration is **never modify raw data directly**. To preserve data lineage and maintain rollback capabilities, a multi-tier staging pipeline was implemented:

1. **`layoffs` (Raw Table):** Unmodified raw source data directly imported from the source CSV.
2. **`layoffs_staging` (First Staging Tier):** An exact structural copy of the raw table used to begin structural transformations.
3. **`layoffs_staging2` (Second Staging Tier):** An enhanced schema featuring helper metrics (such as window function outputs) to enable row-level operations (e.g., duplicate deletion) before finalized schema alterations.

---

## 🛠️ Data Cleaning Process & Methodology

The data transformation pipeline follows five structured phases:

### 1. Removing Duplicates
Because the dataset lacked a unique primary key column, identifying true duplicates required comparing all attributes across records.
* **Technique:** Leveraged MySQL's `ROW_NUMBER()` window function partitioned over every business field (`company`, `location`, `industry`, `total_laid_off`, `percentage_laid_off`, `date`, `stage`, `country`, `funds_raised_millions`).
* **Execution:** Populated `layoffs_staging2` with computed row numbers and executed a targeted deletion for records where `row_num > 1`.

### 2. Data Standardization
Inconsistent string representations and formatting errors were cleaned to prepare the data for aggregation:
* **Whitespace Trimming:** Applied `TRIM()` on textual fields like `company` to purge non-visible leading/trailing spaces.
* **Industry Categorization:** Consolidated fragmented categories (e.g., standardizing `Crypto`, `Cryptocurrency`, and `Crypto Currency` under a uniform `'Crypto'` label).
* **Geographical Cleanups:** Resolved trailing punctuation in country fields (e.g., correcting `'United States.'` to `'United States'`) using `TRIM(TRAILING '.' FROM country)`.
* **Date Parsing & Schema Modification:** Transformed string representations of dates (`'MM/DD/YYYY'`) into standard MySQL date objects using `STR_TO_DATE()`, followed by modifying the column data type from `TEXT` to `DATE`.

### 3. Handling Null & Blank Values
Missing data was evaluated systematically to preserve maximum statistical utility:
* **Empty String Normalization:** Converted empty string literals (`''`) to native SQL `NULL`s to facilitate conditional joins and aggregation behavior.
* **Intelligent Data Imputation:** Executed a self-join (`JOIN`) matching on `company` and `location` to backfill missing `industry` records using valid entries from other layoff events by the same company.
* **Controlled NULL Retention:** Preserved `NULL` values in numeric metrics (`total_laid_off`, `percentage_laid_off`) where baseline company sizes were unknown, avoiding arbitrary zeros that would distort future `AVG()` or distribution queries.

### 4. Row & Column Pruning
To optimize query performance and data density:
* **Irrelevant Record Deletion:** Deleted rows where **both** `total_laid_off` and `percentage_laid_off` were `NULL`, as these records provided no quantitative value for layoff analysis.
* **Schema Refinement:** Dropped temporary windowing columns (`row_num`) via `ALTER TABLE ... DROP COLUMN` to leave a clean, normalized production schema.

---

## 🧰 Tech Stack & Tools Used
* **Database Engine:** MySQL 8.0
* **Management Tool:** MySQL Workbench
* **SQL Concepts Applied:** Window Functions (`ROW_NUMBER()`, `PARTITION BY`), Self-Joins, String Manipulation (`TRIM`, `STR_TO_DATE`), DDL Operations (`ALTER TABLE`, `MODIFY`), Data Imputation, and CTEs.

---
