#Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import psycopg2
import sys
from pandas.io import sql
import sqlalchemy
from sqlalchemy import create_engine, text
from sqlalchemy.types import INTEGER
from datetime import datetime
import urllib
from urllib import request
import json
import os
from configobj import ConfigObj
import contextlib
import shapefile
import geopandas

def elevation_google(latitude, longitude, apikey):
    url = "https://maps.googleapis.com/maps/api/elevation/json"
    request = urllib.request.urlopen(url+"?locations="+str(latitude)+","+str(longitude)+"&key="+apikey)
    response = json.loads(request.read().decode())
    result = response["results"][0]
    elevation = float(result["elevation"])
    return elevation
    
def print_full(x):
    pd.set_option('display.max_rows', len(x))
    print(x)
    pd.reset_option('display.max_rows')
    
@contextlib.contextmanager
def database(parser):
    ## Read credentials
    database_name   = parser['db_config']['database_name']
    user_name       = parser['db_config']['user_name']
    password        = parser['db_config']['password']
    host            = parser['db_config']['host']
    port            = parser['db_config']['port']
    
    """
    connection = db.engine.connect()
    transaction = connection.begin()
    try:
        connection.execute("NOTIFY DHCP")
        transaction.commit()
    except:
        transaction.rollback()"""
    
    try:
        #Open Connection
        conn_string = "postgresql://%s:%s@%s:%s/%s" % (user_name, password, host, port, database_name)
        engine = create_engine(conn_string)
        connection = engine.connect()

        yield connection
    
    finally:
        #Close connection
        connection.close()
        engine.dispose()
        del engine
    
"""
def assign_value(x):
    if x.values[0] is None:
        return None
    else:
        return df_output.loc[x.name, x.values[0]]
"""

# Function to generate WKB hex
def wkb_hexer(line):
    return line.wkb_hex
