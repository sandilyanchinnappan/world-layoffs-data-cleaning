-- ==========================================
-- WORLD LAYOFFS DATA CLEANING PROJECT
-- ==========================================

-- ------------------------------------------
-- STEP 1: INITIAL DATABASE SETUP & STAGING
-- ------------------------------------------
CREATE DATABASE IF NOT EXISTS world_layoffs;
USE world_layoffs;

-- Create a staging table so raw data stays intact
CREATE TABLE IF NOT EXISTS layoffs_staging LIKE layoffs;

INSERT INTO layoffs_staging
SELECT * FROM layoffs;


-- ------------------------------------------
-- STEP 2: REMOVE DUPLICATES
-- ------------------------------------------

-- Create second staging table with an added row_num column to allow row deletion
CREATE TABLE IF NOT EXISTS `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int DEFAULT NULL,
  `row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- Insert data into staging2 while computing row numbers to flag duplicates
INSERT INTO layoffs_staging2
SELECT *,
  ROW_NUMBER() OVER (
    PARTITION BY company, location, industry, total_laid_off, 
                 percentage_laid_off, `date`, stage, country, funds_raised_millions
  ) AS row_num
FROM layoffs_staging;

-- Delete flagged duplicate rows
DELETE 
FROM layoffs_staging2
WHERE row_num > 1;


-- ------------------------------------------
-- STEP 3: STANDARDIZE DATA
-- ------------------------------------------

-- 1. Trim leading and trailing whitespace from company names
UPDATE layoffs_staging2
SET company = TRIM(company);

-- 2. Standardize industry names (e.g., 'Cryptocurrency' -> 'Crypto')
UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- 3. Fix country names with trailing periods (e.g., 'United States.')
UPDATE layoffs_staging2
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';

-- 4. Convert text dates to MySQL DATE format and modify column type
UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;


-- ------------------------------------------
-- STEP 4: HANDLE NULL AND BLANK VALUES
-- ------------------------------------------

-- Convert empty string industries into NULLs so they can be populated
UPDATE layoffs_staging2
SET industry = NULL
WHERE industry = '';

-- Self-join to populate missing industry values from identical company entries
UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
  AND t1.location = t2.location
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
  AND t2.industry IS NOT NULL;


-- ------------------------------------------
-- STEP 5: REMOVE UNNECESSARY ROWS & COLUMNS
-- ------------------------------------------

-- Remove rows where both layoff metrics are missing (unusable for analysis)
DELETE 
FROM layoffs_staging2
WHERE total_laid_off IS NULL
  AND percentage_laid_off IS NULL;

-- Drop the temporary row_num column created during duplicate removal
ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

-- Preview final cleaned dataset
SELECT * FROM layoffs_staging2;