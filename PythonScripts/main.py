# main.py

import pandas as pd
from data_cleaning import clean_module_definition
from table_extraction import extract_tables_views
from database_connection import get_pyodbc_connection, get_sqlalchemy_engine
from sqlalchemy.exc import SQLAlchemyError

def main():
    # Connect to SQL Server
    cnxn = get_pyodbc_connection()
    engine = get_sqlalchemy_engine()
    
    # Fetch data from [CSIPED_PRD].[BKUP].[CURRENT_MODULES]
    query = "SELECT ModuleDefinition, SchemaName, ModuleName, ModuleType FROM [CURRENT_MODULES]"
    data = pd.read_sql(query, cnxn)
    df = pd.DataFrame(data)

    # Fetch data from INTERN.CURRENT_SSRS_Datasets_With_LinkedObject
    query2 = "SELECT QueryDefinition, ObjectName, ObjectType, DatasetName, LinkedPath, LinkType FROM DUMMY_Object"
    data2 = pd.read_sql(query2, cnxn)
    df2 = pd.DataFrame(data2)
    
    # Clean and process data for [CSIPED_PRD].[BKUP].[CURRENT_MODULES]
    df['ModuleDefinition'] = df['ModuleDefinition'].apply(clean_module_definition)
    final_df = extract_tables_views(df,'ModuleDefinition')

    # Clean and process data for INTERN.CURRENT_SSRS_Datasets_With_LinkedObject
    df2['QueryDefinition'] = df2['QueryDefinition'].apply(clean_module_definition)
    final_df2 = extract_tables_views(df2,'QueryDefinition')
    final_df_exploded = final_df2.rename(columns={'QueryDefinition' : 'ModuleDefinition',
    'ObjectName' : 'ModuleName',
    'ObjectType' : 'ModuleType'})

    #Combing two different dataframes
    result = pd.concat([final_df, final_df_exploded], ignore_index=True)
    print(result)

    # Perform database operations
    cnxn.cursor().execute("DELETE FROM [INTERN].[TABLE3]")
    cnxn.commit()
    
    # Create SQLAlchemy engine
    try:
        result.to_sql('TABLE3', engine, if_exists = 'append', schema = 'INTERN', index = False)
        
    except SQLAlchemyError as e:
        print(f"SQLAlchemy error occurred: {e}")

    except Exception as e:
        print(f"An unexpected error occurred: {e}")

    finally:
        # Dispose of the engine to release resources
        if 'engine' in locals():
            
            cnxn.close()
            engine.dispose()
     

if __name__ == "__main__":
    main()
