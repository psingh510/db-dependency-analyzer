USE [CSIPED_PRD]
GO

SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

Create procedure [INTERN].[Extract_With_Command_Tables_proc]
As
Begin
 
delete from INTERN.With_Command_Tables_Matches
Insert into INTERN.With_Command_Tables_Matches (Extracted_Components,Actual_table_notation,SchemaName, ModuleType,ModuleName ,ModuleDefinition)

Select distinct N.Extracted_Components, N.Actual_table_notation, N.SchemaName,N.ModuleType, N.ModuleName,N.ModuleDefinition 
from INTERN.Components_with_no_matches as N
left join INTERN.With_Command_Tables as W on Replace(Replace(W.Extracted_Components,'[',''),']','') = Replace(Replace(N.Extracted_Components  ,'[',''),']','')

WHERE NOT EXISTS (
    SELECT 1
    FROM sys.servers
    WHERE is_linked = 1
    AND N.Extracted_Components LIKE '%' + name + '%' or W.Extracted_Components is not null 
)

and N.Extracted_Components not in ('openquery','OPENXML')



END
GO


