/* =================================================================================================
   Project      : Enterprise Financial Profitability & Cost-to-Serve Optimization
   Script       : 01_Database_Initialization.sql
   Purpose      : Initialize the project database and create the required schemas.
   Author       : Eslam Eid
   ================================================================================================= */


/* =================================================================================================
   01. Database Initialization
   ================================================================================================= */

USE master;
GO

IF DB_ID(N'Enterprise_Profitability') IS NULL
BEGIN
    CREATE DATABASE Enterprise_Profitability;
END;
GO


/* =================================================================================================
   02. Database Verification
   ================================================================================================= */

IF DB_ID(N'Enterprise_Profitability') IS NULL
BEGIN
    THROW 50001, 
          'Database [Enterprise_Profitability] could not be created.', 
          1;
END;
GO

PRINT 'Database [Enterprise_Profitability] is ready.';
GO


/* =================================================================================================
   03. Switch to Project Database
   ================================================================================================= */

USE Enterprise_Profitability;
GO


/* =================================================================================================
   04. Schema Initialization
   ================================================================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'stg'
)
BEGIN
    EXEC(N'CREATE SCHEMA stg');
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'core'
)
BEGIN
    EXEC(N'CREATE SCHEMA core');
END;
GO


IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'rpt'
)
BEGIN
    EXEC(N'CREATE SCHEMA rpt');
END;
GO


/* =================================================================================================
   05. Schema Verification
   ================================================================================================= */

IF NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'stg'
)
OR NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'core'
)
OR NOT EXISTS
(
    SELECT 1
    FROM sys.schemas
    WHERE name = N'rpt'
)
BEGIN
    THROW 50002,
          'One or more required project schemas could not be created.',
          1;
END;
GO

PRINT 'Project schemas [stg], [core], and [rpt] are ready.';
GO