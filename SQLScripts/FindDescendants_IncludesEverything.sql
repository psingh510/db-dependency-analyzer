USE [CSIPED_PRD]
GO

/****** Object:  StoredProcedure [INTERN].[FindDescendants_IncludesEverything]    Script Date: 8/29/2024 10:41:44 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [INTERN].[FindDescendants_IncludesEverything]
AS
BEGIN
  
        EXEC [INTERN].[Merge_Start_And_End_Points];

        -- Delete existing data from the table
        DELETE FROM INTERN.DescendantsTable;

        -- Define Common Table Expressions (CTEs)
        WITH DistinctDBComponents AS (
            SELECT DISTINCT 
                ModuleName, 
                MODULETYPE, 
                Actual_table_notation,  
                EXTRACTED_COMP_SCHEMA, 
                EXTRACTED_COMP_TYPE, 
                SchemaName 
            FROM INTERN.Components_with_matches
        ),

        Tree AS (
            -- Anchor query: select all starting points and their initial level
            SELECT DISTINCT 
                d.ModuleName AS Parent,
                d.MODULETYPE AS Parent_ModuleType,
                d.SchemaName AS ParentSchema,
                d.Actual_table_notation AS Child,
                d.EXTRACTED_COMP_TYPE AS Child_ModuleType,
                d.EXTRACTED_COMP_SCHEMA AS ChildSchema,
                0 AS Level
            FROM DistinctDBComponents d
            WHERE NOT EXISTS (
                SELECT 1
                FROM DistinctDBComponents sub
                WHERE Replace(Replace(d.ModuleName,'[',''),']','') = Replace(Replace(sub.Actual_table_notation,'[',''),']','')
                AND d.MODULETYPE = sub.EXTRACTED_COMP_TYPE
            )
            UNION ALL

            -- Recursive query: select child nodes and their respective parents
            SELECT
                t.Child AS Parent,
                t.Child_ModuleType AS Parent_ModuleType,
                t.ChildSchema AS ParentSchema,
                r.Actual_table_notation AS Child,
                r.EXTRACTED_COMP_TYPE AS Child_ModuleType,
                r.EXTRACTED_COMP_SCHEMA AS ChildSchema,
                t.Level + 1 AS Level
            FROM Tree t
            JOIN DistinctDBComponents r 
                ON r.ModuleName = t.Child 
                AND r.MODULETYPE = t.Child_ModuleType
            WHERE Replace(Replace(t.Parent,'[',''),']','') != Replace(Replace(r.Actual_table_notation ,'[',''),']','')
                AND t.Parent_ModuleType != r.EXTRACTED_COMP_TYPE
        )
	
        -- Insert the hierarchical structure into the target table
        INSERT INTO INTERN.DescendantsTable(
            Parent,
            Parent_ModuleType,
            ParentSchema,
            Child,
            ChildModuleType,
            ChildSchema,
            Level
        )
        SELECT DISTINCT
            Parent,
            Parent_ModuleType,
            ParentSchema,
            Child,
            Child_ModuleType,
            ChildSchema,
            Level
        FROM Tree
        ORDER BY 
            Level, 
            Parent, 
            Child; -- Order by Root, Level, Parent, and Child for clarity

      
END


GO


