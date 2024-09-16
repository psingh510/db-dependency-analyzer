import pyodbc
from sqlalchemy import create_engine
from config import SQL_SERVER_CONFIG

def get_pyodbc_connection():
    config = SQL_SERVER_CONFIG
    connection_string = f"DRIVER={config['driver']};SERVER={config['server_name']};DATABASE={config['database_name']};UID={config['username']};PWD={config['password']}"
    return pyodbc.connect(connection_string)

def get_sqlalchemy_engine():
    config = SQL_SERVER_CONFIG
    connection_string = f"mssql+pyodbc://{config['username']}:{config['password']}@{config['server_name']}/{config['database_name']}?driver={config['driver'].replace(' ', '+')}"
    return create_engine(connection_string)
cnxn = get_pyodbc_connection()