
-- Data Cleaning Project 1

-- 1.	Remove Duplicates
-- 2.	Standardization
-- 3.	Null Values or Blank Values
-- 4.	Remove Any columns



-- PARTITION BY () This defines how the data is grouped. With the same values for: company, location, etc are treated as one group.
-- ROW_NUMBER() OVER() where ROW_NUMBER() is a window function that assigns a sequential number to each row within a group.
-- Common Table Expression (CTE)
-- This explanation demonstrates:
-- Understanding of CTEs
-- Understanding of window functions
-- Understanding of data cleaning workflows
-- Ability to explain SQL clearly and logically
-- Awareness of real‑world use cases (deduplication)






Select *
FROM layoffs; 

-- Q. Create a duplicate yable for stagging for "layoffs Table"?

CREATE TABLE layoffs_staging 
LIKE layoffs;

SELECT *
FROM layoffs_staging;

-- Q. Instert all the same data in layoffs_staging as in layoffs table?

INSERT layoffs_staging
Select *
FROM layoffs;

SELECT *
FROM layoffs_staging;

-- Q. Create/assign unique Row Numbers for each row to identify any duplicates entries in the data?

-- A. Created a unique row using window function to assign a row number to each record based on a set of columns that define a duplicate with the goal to identify or remove duplicate rows in a staging table

SELECT *,
ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging;

-- Q. Find Duplicates in the the table?

-- Used a Common Table Expression (CTE) combined with a window function to identify duplicate rows in the layoffs_staging table so the duplicates can be isolated and removed.


WITH duplicate_cte AS
(SELECT *,ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num

FROM layoffs_staging
)
SELECT *
FROM duplicate_cte
WHERE row_num >1;


-- Q.Create a another staging table to prepare and remove duplicate rows?

-- A. 

-- Creaeted Table

CREATE TABLE `layoffs_staging2` (
  `company` text,
  `location` text,
  `industry` text,
  `total_laid_off` int(11) DEFAULT NULL,
  `percentage_laid_off` text,
  `date` text,
  `stage` text,
  `country` text,
  `funds_raised_millions` int(11) DEFAULT NULL,
  `Row_num` INT
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;

-- Checked table is created successfully
SELECT *
FROM layoffs_staging2;

-- Inserted the Data from layoffs_staging

INSERT INTO layoffs_staging2
(SELECT *,ROW_NUMBER() OVER(PARTITION BY company, location, industry, total_laid_off, `date`, stage, country, funds_raised_millions) AS row_num
FROM layoffs_staging
);

-- Checked the Data  is inserted Succesfully and identlfied the duplicates

SELECT *
FROM layoffs_staging2
WHERE row_num > 1 ;

-- Searched some companies to make dues and confirm they are duplicate entried

SELECT *
FROM layoffs_staging2
WHERE company = 'Wildlife Studios';

-- Deleted the duplicate rows no more entries showing WHERE row_num > 1

DELETE 
FROM layoffs_staging2
WHERE row_num > 1 ;


-- ========================================================================================    Standardisation of the DATA ====================================================


-- Q. Trim white spaces if any and update the Table layoffs_staging2 ?

-- A. Trimed the whites sapced and update the table 

SELECT *
FROM layoffs_staging2;

SELECT company, (TRIM(company))
FROM layoffs_staging2;

UPDATE layoffs_staging2
SET company = TRIM(company);


-- Q.Check any similar match looking names and update them as neccesssary

-- A. In Indusry section Crypto was showing Crypto Currency a couple of times. Updated to Crypto to match the rest of the related to Crypto Industry

SELECT DISTINCT industry
FROM layoffs_staging2
ORDER BY 1;

SELECT *
FROM layoffs_staging2
WHERE industry LIKE 'Crypto%';

UPDATE layoffs_staging2
SET industry = 'Crypto'
WHERE industry LIKE 'Crypto%';

-- Q. Fix any naming conventions in the table 

-- A. Checked Country "United States" is showing a . in the end "United States."
SELECT DISTINCT country
FROM layoffs_staging2
WHERE country LIKE 'United States%'
ORDER BY 1;

-- Tested first 
SELECT DISTINCT country, TRIM(TRAILING'.'FROM country)
FROM layoffs_staging2
ORDER BY 1;

-- Then updated by runnng the TRIM functionality

UPDATE layoffs_staging2
SET country = TRIM(TRAILING'.'FROM country)
WHERE country LIKE 'United States%';

-- Q. Change Date Type and Layout for date column

-- Tested first

SELECT`date`,
STR_TO_DATE(`date`,'%m/%d/%Y')
FROM layoffs_staging2;

-- updated the layout

UPDATE layoffs_staging2
SET `date` = STR_TO_DATE(`date`,'%m/%d/%Y');

-- Updated the date Type from text to DATE

ALTER TABLE layoffs_staging2
MODIFY COLUMN `date` DATE;

-- ========================================================================================    REMOVE NULL and BLANK Values ====================================================

-- Q.  if one row for a company has a blank or NULL industry, but another row for that same company has a valid industry, hoe can we safely update the missing values.
-- A. I used a self‑join update to backfill missing industry values by matching each incomplete row with another row from the same company that contains a valid industry.

-- Checked Industry was missing for Companies like Juul,Airbnb and Carvana but had one correct entries for each.

SELECT *
FROM layoffs_staging2
WHERE company IS NULL OR company IN ('', ' ')
   OR location IS NULL OR location IN ('', ' ')
   OR industry IS NULL OR industry IN ('', ' ')
   OR total_laid_off IS NULL
   OR percentage_laid_off IS NULL OR percentage_laid_off IN ('', ' ')
   OR date IS NULL OR date IN ('', ' ')
   OR stage IS NULL OR stage IN ('', ' ')
   OR country IS NULL OR country IN ('', ' ')
   OR funds_raised_millions IS NULL
   OR row_num IS NULL;

SELECT *
FROM layoffs_staging2
WHERE industry IS NULL OR industry IN ('', ' ');

SELECT *
FROM layoffs_staging2
WHERE Company = 'Airbnb';

-- Selfjoin test check - Self‑join on the same table
-- t1 represents rows with missing industry values.
-- t2 represents rows with valid industry values.
-- The join condition ensures both rows belong to the same company.


SELECT *
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '' OR t1.industry = ' ')
  AND t2.industry IS NOT NULL
  AND t2.industry <> ''
  AND t2.industry <> ' ';

SELECT t1.company, t1.industry, t2.company, t2.industry
FROM layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
WHERE (t1.industry IS NULL OR t1.industry = '' OR t1.industry = ' ')
  AND t2.industry IS NOT NULL
  AND t2.industry <> ''
  AND t2.industry <> ' ';
  
-- selfjoined and updated

UPDATE layoffs_staging2 t1
JOIN layoffs_staging2 t2
  ON t1.company = t2.company
SET t1.industry = t2.industry
WHERE (t1.industry IS NULL OR t1.industry = '' OR t1.industry = ' ')
  AND t2.industry IS NOT NULL
  AND t2.industry <> ''
  AND t2.industry <> ' ';


-- ============================================= Remove any unwanted Rows/ Columns ======================================================

-- Q. check any cells with NULL Values in it?

SELECT *
FROM layoffs_staging2
WHERE (total_laid_off is NULL or total_laid_off = '' or total_laid_off = ' ' or total_laid_off = 'NULL');

SELECT *
FROM layoffs_staging2
WHERE (percentage_laid_off is NULL or percentage_laid_off = '' or percentage_laid_off = ' ' or percentage_laid_off = 'NULL');

SELECT *
FROM layoffs_staging2
WHERE percentage_laid_off = 'NULL';


-- Q. Remove the Row_num column?

ALTER TABLE layoffs_staging2
DROP COLUMN row_num;

