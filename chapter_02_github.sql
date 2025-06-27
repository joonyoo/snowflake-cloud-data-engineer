-- Use the ACCOUNTADMIN role for full administrative privileges
USE ROLE ACCOUNTADMIN;

-- Create or replace an API integration for GitHub access
CREATE OR REPLACE API INTEGRATION git_sample_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/joonyoo')
  ENABLED = TRUE;

-- Create or replace the 'lessons' database for lesson materials
create or replace database lessons
    comment = 'Database containing lesson materials from the book "Snowflake Cloud Data Engineer" by Joon Yoo'
  ;

-- Create the 'resources' schema within the 'lessons' database
create schema resources
    comment = 'Schema containing resources used in the Snowflake Cloud Data Engineer book'  ;

-- Create or replace a Git repository object in Snowflake, linking to the GitHub repo
CREATE OR REPLACE GIT REPOSITORY cloud_data_engineer_book_resources
    API_INTEGRATION = git_sample_integration
    ORIGIN = 'https://github.com/joonyoo/snowflake-cloud-data-engineer';

-- List the contents of the 'main' branch in the Git repository stage
ls @cloud_data_engineer_book_resources/branches/main;

-- List the contents of the 'feature/chapter02.git_stages' branch in the Git repository stage
ls @cloud_data_engineer_book_resources/branches/feature/chapter02.git_stages