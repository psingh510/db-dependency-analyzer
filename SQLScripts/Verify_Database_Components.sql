USE [CSIPED_PRD]
GO

/****** Object:  StoredProcedure [INTERN].[Verify_Database_Components]    Script Date: 8/29/2024 10:57:59 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO


CREATE PROCEDURE [INTERN].[Verify_Database_Components]
AS
BEGIN
    
        -- Delete existing data from the tables
        DELETE FROM INTERN.Components_with_matches;
        DELETE FROM INTERN.Components_with_no_matches;

        -- Create a temporary table
        CREATE TABLE #TempModifiedRelevantTables (
            Extracted_Components VARCHAR(MAX),
            ModuleDefinition VARCHAR(MAX),
            Actual_table_notation VARCHAR(MAX),
            ExtractedSchema VARCHAR(MAX),
            SchemaName VARCHAR(MAX),
            ModuleType VARCHAR(MAX),
            ModuleName VARCHAR(MAX),
            DataSetName VARCHAR(MAX),
            LinkedPath VARCHAR(MAX),
            LinkType VARCHAR(MAX)
        );

        -- Insert data into the temporary table using the CTE
        WITH Trimmed_Relevant_Tables AS (
            SELECT 
                I.ModuleDefinition,
                REPLACE(REPLACE(REPLACE(I.Extracted_Components, CHAR(9), ''), CHAR(32), ''), CHAR(10), '') AS Extracted_Components,
                I.SchemaName, 
                I.ModuleType,
                I.ModuleName,
                I.DataSetName,
                I.LinkedPath,
                I.LinkType
            FROM INTERN.List_Of_Extracted_Components AS I
        ),

        Modified_Relevant_Tables AS (
            SELECT DISTINCT
                I.Extracted_Components,
                I.ModuleDefinition,
                CASE
                    WHEN LEN(I.Extracted_Components) - LEN(REPLACE(I.Extracted_Components, '.', '')) >= 1 
                         AND LEN(I.Extracted_Components) - LEN(REPLACE(I.Extracted_Components, ']', '')) >= 2
                        THEN REPLACE(REPLACE(REPLACE(SUBSTRING(I.Extracted_Components, 
                            LEN(I.Extracted_Components) - CHARINDEX('[', REVERSE(I.Extracted_Components)) + 1, 
                            (LEN(I.Extracted_Components) - CHARINDEX(']', REVERSE(I.Extracted_Components))) -
                            (LEN(I.Extracted_Components) - CHARINDEX('[', REVERSE(I.Extracted_Components))) + 1),
                            ']', ''), '[', ''), '.', '')
                    WHEN LEN(I.Extracted_Components) - LEN(REPLACE(I.Extracted_Components, '.', '')) >= 1
                        THEN REPLACE(REPLACE(REPLACE(SUBSTRING(I.Extracted_Components, 
                            LEN(I.Extracted_Components) - CHARINDEX('.', REVERSE(I.Extracted_Components)) + 1, 
                            (LEN(I.Extracted_Components) - (LEN(I.Extracted_Components) - CHARINDEX('.', REVERSE(I.Extracted_Components))) + 1)), 
                            ']', ''), '[', ''), '.', '')
                    ELSE LOWER(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(I.Extracted_Components, '[', ''), ']', ''), '@', ''), 'CSIPED_PRD', ''), '.', ''))
                END AS Actual_table_notation,
                CASE 
                    WHEN (LEN(CONCAT('.', I.Extracted_Components)) - CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components)))) - 1 
                         - (LEN(CONCAT('.', I.Extracted_Components)) - CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components)), CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components))) + 1)) <= 0
                        THEN '[dbo]'
                    ELSE SUBSTRING(CONCAT('.', I.Extracted_Components),
                        LEN(CONCAT('.', I.Extracted_Components)) - CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components)), CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components))) + 1) + 2,
                        (LEN(CONCAT('.', I.Extracted_Components)) - CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components)))) - 1 
                        - (LEN(CONCAT('.', I.Extracted_Components)) - CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components)), CHARINDEX('.', REVERSE(CONCAT('.', I.Extracted_Components))) + 1)))
                END AS ExtractedSchema,
                I.SchemaName, 
                I.ModuleType,
                I.ModuleName,
                I.DataSetName,
                I.LinkedPath,
                I.LinkType
            FROM Trimmed_Relevant_Tables AS I
            WHERE I.Extracted_Components IS NOT NULL
              AND I.Extracted_Components NOT LIKE '@%'
              AND I.Extracted_Components NOT LIKE '%#%'
              AND I.Extracted_Components NOT LIKE '%''%'
        )

        INSERT INTO #TempModifiedRelevantTables (
            Extracted_Components,
            ModuleDefinition,
            Actual_table_notation,
            ExtractedSchema,
            SchemaName,
            ModuleType,
            ModuleName,
            DataSetName,
            LinkedPath,
            LinkType
        )
        SELECT DISTINCT
            I.Extracted_Components,
            I.ModuleDefinition,
            I.Actual_table_notation,
            I.ExtractedSchema,
            I.SchemaName, 
            I.ModuleType,
            I.ModuleName,
            I.DataSetName,
            I.LinkedPath,
            I.LinkType
        FROM Modified_Relevant_Tables AS I;

        -- Insert matched components
        INSERT INTO INTERN.Components_with_matches (
            Extracted_Components,
            Actual_table_notation,
            SchemaName,
            ModuleType,
            ModuleName,
            ModuleDefinition,
            DataSetName,
            LinkedPath,
            LinkType,
            table_name,
            Extracted_Comp_Type,
            Extracted_Comp_Schema
        )
        SELECT DISTINCT 
            I.Extracted_Components,
            LTRIM(RTRIM(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(I.Actual_table_notation), '.', ''), CHAR(10), ''), CHAR(13), ''), CHAR(9), ''))) AS Actual_table_notation,
            I.SchemaName, 
            I.ModuleType,
            I.ModuleName, 
            I.ModuleDefinition,
            I.DataSetName,
            I.LinkedPath, 
            I.LinkType,
            T.table_name,
            T.comptype,
            I.ExtractedSchema
        FROM #TempModifiedRelevantTables AS I
        LEFT JOIN [INTERN].[List_of_components] AS T  
            ON LOWER(T.table_name) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(I.Actual_table_notation), '.', ''), CHAR(10), ''), CHAR(13), ''), CHAR(9), ''), '.', ''), ';', '')
        WHERE T.table_name IS NOT NULL;

        -- Insert unmatched components
        INSERT INTO INTERN.Components_with_no_matches (
            Extracted_Components,
            Actual_table_notation,
            SchemaName,
            ModuleType,
            ModuleName,
            ModuleDefinition,
            DataSetName,
            LinkedPath,
            LinkType,
            table_name,
            Extracted_Comp_Type,
            Extracted_Comp_Schema
        )
        SELECT DISTINCT 
            I.Extracted_Components,
            REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(I.Actual_table_notation), '.', ''), CHAR(10), ''), CHAR(13), ''), CHAR(9), ''), '.', ''), ';', '') AS Actual_table_notation,
            I.SchemaName, 
            I.ModuleType,
            I.ModuleName, 
            I.ModuleDefinition,
            I.DataSetName,
            I.LinkedPath, 
            I.LinkType,
            T.table_name,
            T.comptype,
            I.ExtractedSchema
        FROM #TempModifiedRelevantTables AS I
        LEFT JOIN [INTERN].[List_of_components] AS T  
            ON LOWER(T.table_name) = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(LOWER(I.Actual_table_notation), '.', ''), CHAR(10), ''), CHAR(13), ''), CHAR(9), ''), '.', ''), ';', '')
        WHERE T.table_name IS NULL
          AND I.Extracted_Components NOT LIKE '%sys%' 
          AND I.Extracted_Components NOT LIKE '%INFORMATION_SCHEMA%';

        -- Drop the temporary table (optional but recommended)
        DROP TABLE #TempModifiedRelevantTables;

   
END

GO


