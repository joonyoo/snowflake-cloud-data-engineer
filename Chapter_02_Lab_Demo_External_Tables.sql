-- ==============================================
-- LAB EXERCISE: WORKING WITH SNOWFLAKE STAGES AND EXTERNAL TABLES
-- ROLE: SYSADMIN (Ensure you are using the SYSADMIN role before proceeding)
-- ==============================================

-- STEP 1: CREATE A DATABASE AND SCHEMA
-- This ensures a dedicated workspace for this lab exercise.

CREATE IF NOT EXISTS lessons;
CREATE OR REPLACE SCHEMA chapter_02_lab_demo;

-- Set the context to use the new database and schema.
USE schema chapter_02_lab_demo;

-- ==============================================
-- STEP 2: CREATE AN EXTERNAL STAGE
-- A stage is a storage location in Snowflake that provides access to external data.
-- This stage connects to an open AWS S3 dataset containing earthquake data.
-- More information on the dataset: https://registry.opendata.aws/southern-california-earthquakes/
-- ==============================================

CREATE OR REPLACE STAGE DEMO.RAW.EARTHQUAKES 
    URL = 's3://scedc-pds/';

-- Verify that the stage is accessible by listing its contents.
LIST @DEMO.RAW.EARTHQUAKES/earthquake_catalog;

-- ==============================================
-- STEP 3: CREATE AN EXTERNAL TABLE FOR EARTHQUAKE DATA
-- External tables allow querying data stored externally without loading it into Snowflake.
-- This table is built from CSV files stored in the S3 stage.
-- ==============================================

CREATE OR REPLACE EXTERNAL TABLE DEMO.RAW.EARTHQUAKE_CATALOG
(
    PREFIX VARCHAR AS (VALUE:c1::VARCHAR),  -- File path prefix
    MS_FILENAME VARCHAR AS (VALUE:c2::VARCHAR),  -- Mainshock filename
    PHASE_FILENAME VARCHAR AS (VALUE:c3::VARCHAR),  -- Phase data filename
    ORIGIN_DATETIME TIMESTAMP AS COALESCE(
        TRY_TO_TIMESTAMP(VALUE:c4::STRING, 'YYYY-MM-DD HH24:MI:SS.FF3'), 
        TRY_TO_TIMESTAMP(SUBSTR(VALUE:c4::STRING, 1, 10))
    ),  -- Event timestamp
    ET VARCHAR AS (VALUE:c5::VARCHAR),  
    GT VARCHAR AS (VALUE:c6::VARCHAR),  
    MAG VARCHAR AS (VALUE:c7::VARCHAR),  -- Magnitude of the earthquake
    M VARCHAR AS (VALUE:c8::VARCHAR),  
    LAT VARCHAR AS (VALUE:c9::VARCHAR),  -- Latitude
    LON VARCHAR AS (VALUE:c10::VARCHAR),  -- Longitude
    DEPTH VARCHAR AS (VALUE:c11::VARCHAR),  -- Depth of the earthquake
    Q VARCHAR AS (VALUE:c12::VARCHAR),  
    EVID VARCHAR AS (VALUE:c13::VARCHAR),  -- Event ID
    NPH VARCHAR AS (VALUE:c14::VARCHAR),  
    NGRM VARCHAR AS (VALUE:c15::VARCHAR)
)
WITH LOCATION = @EARTHQUAKES/earthquake_catalogs/index/csv/
FILE_FORMAT = (
    TYPE = CSV 
    SKIP_HEADER = 1  -- Skip the header row in CSV files
);

-- ==============================================
-- STEP 4: CREATE A QUERY WAREHOUSE
-- Warehouses are required for running queries.
-- This warehouse is configured to automatically suspend after 30 seconds of inactivity.
-- ==============================================

CREATE WAREHOUSE QUERY_WH
    INITIALLY_SUSPENDED = TRUE
    AUTO_SUSPEND = 30;

-- ==============================================
-- STEP 5: QUERY THE EXTERNAL TABLE
-- Fetch a sample of 10,000 records from the earthquake catalog.
-- ==============================================

SELECT *
FROM DEMO.RAW.EARTHQUAKE_CATALOG
LIMIT 10000;

-- ==============================================
-- STEP 6: WORK WITH PARQUET FILES
-- List all available Parquet files in the earthquake dataset.
-- Parquet is a more efficient columnar format compared to CSV.
-- ==============================================

LIST @DEMO.RAW.EARTHQUAKES/earthquake_catalogs 
PATTERN = '.*parquet$';

-- Create a file format object for Parquet files.
CREATE FILE FORMAT DEMO.RAW.MYPARQUETFORMAT  
    TYPE = PARQUET;

-- Query the first column from a specific Parquet file.
SELECT $1
FROM @DEMO.RAW.EARTHQUAKES/earthquake_catalogs/index/parquet/year=2021/2021_catalog_index.parquet
(FILE_FORMAT => DEMO.RAW.MYPARQUETFORMAT);


-- ==============================================
-- END OF LAB EXERCISE
-- ==============================================