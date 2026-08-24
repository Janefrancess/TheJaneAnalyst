SELECT *
FROM layoffs_staging;

-- 1. Remove Duplicates
-- 2. Standardize the data
-- 3. Null values or blank values
-- 4. Remove any unnecessary columns or rows


-- Create a staging database to preserve original database. This duplicates the rows
CREATE TABLE layoffs_staging 
LIKE layoffs;

-- Insert all data into dupliacted database
INSERT layoffs_staging
SELECT * 
FROM layoffs;



-- 1. Remove Duplicates

-- right click on layoffs_staging
-- On the options, click "copy to clipboard" and "create statement", paste code below.
-- Add an INT variable i.e `row_num`, then run the code below
-- What you did is create a copy of staging database layoffs_staging2 and added a new row "row_num"
CREATE TABLE `layoffs_staging1` (
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


SELECT * 
FROM layoffs_staging1;


-- Inserts all data and generated numbers in "Row_num" to aid identifying duplicates.
INSERT INTO layoffs_staging1
SELECT *,
ROW_NUMBER() OVER(
PARTITION BY company, location, 
industry, total_laid_off, percentage_laid_off, `date`, stage, 
country, funds_raised_millions) AS row_num
FROM layoffs_staging;

SELECT *
FROM layoffs_staging2
WHERE row_num > 1;

-- Delete duplicate rows
DELETE
FROM layoffs_staging1
WHERE row_num > 1;



-- 2. Standardize the data

-- Company row
SELECT company, TRIM(company)
FROM layoffs_staging1;

UPDATE layoffs_staging1
SET company = TRIM(company);

-- Industry row
SELECT DISTINCT industry
FROM layoffs_staging1;

UPDATE layoffs_staging1
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Location is fine, move to check country

-- Country row
-- Remove period(.) from data
SELECT DISTINCT country, TRIM(TRAILING '.' FROM country)
FROM layoffs_staging1
ORDER BY 1;

-- Update country colunm where it is 'United states'
UPDATE layoffs_staging1
SET country = TRIM(TRAILING '.' FROM country)
WHERE country LIKE 'United States%';


-- Date formating
SELECT `date`,
STR_TO_DATE(`date`, '%m/%d/%Y')
FROM layoffs_staging1;

UPDATE layoffs_staging1 
SET `date` = STR_TO_DATE(`date`, '%m/%d/%Y');

ALTER TABLE layoffs_staging1
MODIFY COLUMN `date` DATE;

SELECT `date`
FROM layoffs_staging1;



-- 3. Null values or blank values
-- Change blank columns to NULL in INDUSTRY row.

UPDATE layoffs_staging1
SET industry = NULL
WHERE industry = '';

SELECT *
FROM layoffs_staging1
WHERE industry IS NULL
OR industry = '';

-- Check if company has other records entry without NULL industry
SELECT *
FROM layoffs_staging1
WHERE company LIKE 'Airbnb';

SELECT t1.industry, t2.industry
FROM layoffs_staging1 t1
JOIN layoffs_staging1 t2
	ON t1.company = t2.company
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;

UPDATE layoffs_staging1 t1
JOIN layoffs_staging1 t2
	ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE t1.industry IS NULL
AND t2.industry IS NOT NULL;


-- 4. Remove any unnecessary columns or rows

-- Handling useless records, where total-laid-off and percentage-laid-off is NULL
SELECT *
FROM layoffs_staging1
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

DELETE
FROM layoffs_staging1
WHERE total_laid_off IS NULL
AND percentage_laid_off IS NULL;

-- Drop row_num
ALTER TABLE layoffs_staging1
DROP COLUMN row_num;

SELECT *
FROM layoffs_staging1;