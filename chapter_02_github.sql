-- Use the ACCOUNTADMIN role for full administrative privileges
USE ROLE ACCOUNTADMIN;

-- Create or replace an API integration for GitHub access
CREATE OR REPLACE API INTEGRATION git_sample_integration
  API_PROVIDER = git_https_api
  API_ALLOWED_PREFIXES = ('https://github.com/joonyoo')
  ENABLED = TRUE;

-- Create or replace the 'lessons' database for lesson materials
CREATE OR REPLACE DATABASE lessons
    comment = 'Database containing lesson materials from the book "Snowflake Cloud Data Engineer" by Joon Yoo'
  ;

-- Create the 'resources' schema within the 'lessons' database
CREATE SCHEMA resources
    comment = 'Schema containing resources used in the Snowflake Cloud Data Engineer book'  ;

-- Set the context to use the 'resources' schema
USE SCHEMA lessons.resources;
-- Create or replace a Git repository object in Snowflake, linking to the GitHub repo
CREATE OR REPLACE GIT REPOSITORY cloud_data_engineer_book_resources
    API_INTEGRATION = git_sample_integration
    ORIGIN = 'https://github.com/joonyoo/snowflake-cloud-data-engineer';


-- List the properties of the git repository stage
DESCRIBE GIT REPOSITORY cloud_data_engineer_book_resources;

-- List the contents of the 'main' branch in the Git repository stage
LIST @cloud_data_engineer_book_resources/branches/main;





-- Fetch the latest changes from the Git repository
-- This ensures that the local copy of the repository is up-to-date with the remote repository
-- This is necessary to ensure that the latest changes are reflected in the Snowflake environment
-- The FETCH command updates the local repository with any new commits from the remote repository
-- It is important to run this command before listing branches or accessing specific files
ALTER GIT REPOSITORY cloud_data_engineer_book_resources FETCH;


-- List the branches in the Git repository to verify the available branches
SHOW GIT BRANCHES in GIT REPOSITORY cloud_data_engineer_book_resources;

-- List the contents of the 'welcome' branch in the Git repository stage
list @cloud_data_engineer_book_resources/branches/welcome;

-- Execute the SQL script located in the 'welcome' branch of the Git repository stage
-- This command runs the SQL script that contains a simple welcome message
execute immediate FROM @cloud_data_engineer_book_resources/branches/welcome/welcome.sql;

