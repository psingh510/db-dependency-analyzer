import csv
import pyodbc
import pandas as pd
import re
from sqlalchemy import create_engine

# sql server connection
server_name = 'XXX'
database_name = 'YYY'
username = 'abc'
password = 'qwerty'
driver = 'ODBC Driver 13 for SQL Server'

cnxn = pyodbc.connect(driver='{SQL Server}', host=server_name, database=database_name, user=username, password=password)

query = ("SELECT ModuleDefinition FROM TABLE1")

data = pd.read_sql(query, cnxn)
df = pd.DataFrame(data)

cnxn.cursor().execute("DELETE FROM TABLE2")
cnxn.commit()
cnxn.close()


comment_pattern = r'--[^\n]*'
comment_pattern_2 = r'\/\*+\s*[a-zA-Z0-9\s\:\[\]\.\_\/\@]*\*+\/'




df['ModuleDefinition']= df['ModuleDefinition'].str.strip()
df['ModuleDefinition'] = df['ModuleDefinition'].apply(lambda x: re.sub(comment_pattern, ' ', x) if x is not None else x)
df['ModuleDefinition'] = df['ModuleDefinition'].apply(lambda x: re.sub(comment_pattern_2, ' ', x) if x is not None else x)

pattern = r'(?:[\s\n\t\;]*WITH|[\s\n\t\;]*with|[\s\n\t\;]*With|[\s\n\t\;]*\)\s*\,)[\s\n\t]*(\[.*?\]+|\[.*?\]+[a-zA-Z0-9\@\_\\.\[\]]*|[a-zA-Z0-9\@\_\.\[\]]*)[\s\n\t]+(?:AS|as|As|\()'

declare_pattern = r'(?:DECLARE|declare)[\s\n\t]*(\[.*?\]+|\[.*?\]+[a-zA-Z0-9\@\_\\.\[\]]*|[a-zA-Z0-9\@\_\.\[\]]*)[\s\n\t]+'


df['Extracted_Components'] = df['ModuleDefinition'].str.findall(pattern)
df['Extracted_Components'] += df['ModuleDefinition'].str.findall(declare_pattern)


final_df = df
final_df_exploded = final_df.explode('Extracted_Components')
final_df_exploded = final_df_exploded.drop_duplicates(keep = 'first')






# Create connection string
connection_string = f'mssql+pyodbc://{username}:{password}@{server_name}/{database_name}?driver={driver.replace(" ", "+")}'

# Create SQLAlchemy engine
engine = create_engine(connection_string)
final_df_exploded.to_sql('TABLE2', engine, if_exists = 'append', schema = 'INTERN', index = False)
