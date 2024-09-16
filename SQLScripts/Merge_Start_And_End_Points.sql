USE [CSIPED_PRD]
GO

/****** Object:  StoredProcedure [INTERN].[Merge_Start_And_End_Points]    Script Date: 8/29/2024 10:17:15 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [INTERN].[Merge_Start_And_End_Points] 

As
Begin  
DELETE INTERN.Components_with_matches where ModuleType = 'BATEX';
With SourceTable As
	(
	SELECT 
		UserTag, LoadXML, PrcsXML, Ps
	FROM (
		SELECT 
			UserTag,
			CAST('<x>' + REPLACE([Load], ',', '</x><x>') + '</x>' AS XML) AS LoadXML,
			--CAST('<x>' + REPLACE([Prcs], '} ', '</x><x>') + '</x>' AS XML) AS PrcsXML,
			--CAST('<x>' + REPLACE([Prcs], '}{', '</element><element>') + '</element></x>' AS XML) AS PrcsXML,
			CAST('<x>' + REPLACE(REPLACE([Prcs], '}', '$'), '$', '</x><x>') + '</x>' AS XML)AS PrcsXML,
			REPLACE([Prcs], '}', ',') as Ps
		FROM [CSIPED_PRD].[dbo].[DEXT_EREF_BATEX]
		where [Load] != '\n' and [Load] != '/n' 

	) As ST ),

TransformedTable As
	(
	SELECT 
		UserTag,
		L.x.value('.', 'VARCHAR(10)') AS [Load],
		P.x.value('.', 'NVARCHAR(max)') AS [Prcs],
		'SQL_STORED_PROCEDURE' As ComponentType,
		Ps
	FROM SourceTable 
	CROSS APPLY LoadXML.nodes('/x') AS L(x)
	CROSS APPLY PrcsXML.nodes('/x') AS P(x) 
	 ),

ERDT_Source_Tab As 
	(
	SELECT 
		   SourceID,
		   ExtractionLink As Component,
		   'SQL_STORED_PROCEDURE' As ComponentType
	FROM 
		   erdt_source
	WHERE 
		   origin2 = 'SQL'

	UNION ALL
	SELECT 
		   SourceID,
		   TargetTable As Component,
		   'TABLE' As ComponentType
	FROM 
		   erdt_source
	WHERE 
		   origin2 != 'SQL'
	),
CombinedOutput As (
Select 
	t.UserTag,
	t.[Load],
	t.ComponentType as ComponentType_PRCS,
	REPLACE(REPLACE(SUBSTRING(t.[Prcs],1,LEN(t.[Prcs]) - CHARINDEX('/',REVERSE(t.[Prcs]))),'{',''),' ','') AS [Prcs],
	e.Component,
	e.ComponentType As ComponentType_Source
	from TransformedTable t left join ERDT_Source_Tab e on
	e.[SourceID] =t.[Load] where t.[Prcs] !=' '

),
TransformedCombinedOutput As (
	SELECT 
	distinct
    UserTag,
    Prcs AS Prcs,
    ComponentType_Prcs AS ComponentType
FROM CombinedOutput

UNION ALL

SELECT 
   distinct
    UserTag,
    Component AS Prcs, -- Component values are now merged as Prcs
    ComponentType_Source AS ComponentType
FROM CombinedOutput


)

INSERT INTO INTERN.Components_with_matches (Extracted_Components,Actual_table_notation,SchemaName,ModuleType,ModuleName,ModuleDefinition,DataSetName,LinkedPath, LinkType,table_name,Extracted_comp_type,Extracted_comp_Schema)
SELECT DISTINCT 
	Case When LEN([Prcs]) - LEN(REPLACE([Prcs], '.', '')) >= 1 
	THEN
	REPLACE(REPLACE(REPLACE(SUBSTRING([Prcs], 
                            LEN([Prcs]) - CHARINDEX('.', REVERSE([Prcs])) + 1, 
                            (LEN([Prcs]) - (LEN([Prcs]) - CHARINDEX('.', REVERSE([Prcs]))) + 1)), 
                            ']', ''), '[', ''), '.', '')
	Else
	Replace(Replace([Prcs],']',''),'[','')
	End,
	Case When LEN([Prcs]) - LEN(REPLACE([Prcs], '.', '')) >= 1 
	THEN
	REPLACE(REPLACE(REPLACE(SUBSTRING([Prcs], 
                            LEN([Prcs]) - CHARINDEX('.', REVERSE([Prcs])) + 1, 
                            (LEN([Prcs]) - (LEN([Prcs]) - CHARINDEX('.', REVERSE([Prcs]))) + 1)), 
                            ']', ''), '[', ''), '.', '')
	Else
	Replace(Replace([Prcs],']',''),'[','')
	End
	,'','BATEX',USERTAG,'','' ,'' , '','',ComponentType,'' FROM TransformedCombinedOutput
End


GO


