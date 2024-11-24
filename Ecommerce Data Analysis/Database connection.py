#SQL Server Connection

import pandas as pd
import pypyodbc as odbc

DRIVER_NAME = 'SQL SERVER'
SERVER_NAME = '#Server Name'
DATABASE = '#DB Name'

connectionString = f"""
DRIVER={{{DRIVER_NAME}}};
SERVER={SERVER_NAME};
DATABASE={DATABASE};
Trust_Connection=yes;

"""
conn = odbc.connect(connectionString)
print(conn)