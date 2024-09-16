import re
import pandas as pd

def extract_tables_views(df,column_name):
    pattern = r'[\s\n\t]+(?:FROM|from|From|join|JOIN|INSERT INTO|insert into|EXEC|Exec)[\s\n\t]+((?:\[[\w]+\]\.[\s]*\[[\w\s^\(^\)]+\]+[\s\;]+|[\w]+\.[\s]*\[[\w\s^\(^\)]+\]+|\[[a-zA-Z0-9\_\.\s]+\][\s\;]+|iPED_PRD.dbo.\[[\w\s^\(^\)]+\]|[^\s\(\)\;]+))'
    open_query_pattern = r'[\s\n\t]+(?:FROM|from)[\s\n\t]+(?:OPENQUERY|openquery)[\s\n\t]*\([\s\n\t]*[a-zA-Z0-9\@\_\\.\[\]]+,[\s\n\t\']+([\s\S]*\'[\s\n\t]*\))'
    
    
    df[column_name] = df[column_name].apply(lambda x: re.sub(open_query_pattern, ' ', x))
    df['Extracted_Components'] = df[column_name].str.findall(pattern)
    
    transformed_df = df.explode('Extracted_Components').drop_duplicates(keep='first')
    print(transformed_df)
    
    return transformed_df
