import re
import glob
from zipfile import ZipFile
import requests
import shapefile
import geopandas
import urllib
from urllib import request
import os
from pandas.io import sql
import sqlalchemy
from sqlalchemy import create_engine, text
from sqlalchemy.types import INTEGER
from datetime import datetime
import math
from .utils import database, wkb_hexer


#Download shapefiles for roads defined in WFSs requests and upload to database
def download_roads(parser, road_type):
    output_path = parser['path_finder_roads_params']['output_path']
    output_filename = parser['path_finder_roads_params']['output_filename']
    output_table = parser['path_finder_roads_params']['roads_table']
    
    road_types = dict(parser['path_finder_roads_params']['road_types'])
    
    filename_zip = str(output_path + '/' + output_filename + '.zip')
    shp_file = output_path + '/' + output_filename + '/' + re.search('=MTC_pg:(.*)&outputFormat', road_types[road_type]['url']).group(1)  + '.shp'
    
    if(~os.path.exists(shp_file)):        
        local_filename, headers = urllib.request.urlretrieve(road_types[road_type]['url'], filename_zip)
        zip_ref = ZipFile(filename_zip, 'r')
        zip_ref.extractall(output_path + '/' + output_filename)
        zip_ref.close()
    
    roads = geopandas.read_file(shp_file)
    
    roads['geometry'] = roads['geometry'].apply(wkb_hexer)
    roads['hct_lbl'] = road_types[road_type]['type']    
    
    roads.rename(columns={"geometry": "geom"}, inplace=True)
    
    return roads
    
#Define function that turns: 
#roads with a format of line strings to equally distributed points at a distance d from one another

#These points will be used to project the cluster population onto the closest point. 
#It enables the process to compare points (cluster centroids) with points (road points) instead of points to lines
#Once the population of a cluster is projected onto the road point, we will know how many people are unlocked if we deploy
#FO in that point.

def roads_to_points(parser, distance):
    
    sql_path = parser['sql_path']
    country_folder = parser['country_folder']
    
    schema = parser['path_finder_roads_params']['schema']
    roads_table = parser['path_finder_roads_params']['roads_table_dump']
    
    query_path = sql_path + '/' + country_folder + '/' + 'path_finder_roads_get_roads_lines.sql'
    
    with open(query_path) as file, database(parser) as db:
        query = file.read()
        query_formatted = query.format(schema = schema, table_roads = roads_table)
        roads_raw = pd.read_sql_query(query_formatted, db)
    
    roads_output = pd.DataFrame()
    #For each road stretch, we will turn it into a set of points
    for row in roads_raw.itertuples():
        row = row._asdict()
        print('X ' + str(row['Index']) + ' / ' + str(len(roads_raw)) + ' ' + str(datetime.now()))
        
        #Current road's parameters
        id_iteration = row['stretch_id']
        length_iteration = row['stretch_length']
        
        #For very short stretches, we just take start and end points.
        #For longer ones, we create a linear distribution of points
        if(length_iteration < 1000):
            n_stretches = 2
        else: n_stretches = (math.ceil((length_iteration/1000)/distance))
        
        #We create the linear distribution point by point
        for y in range(0, n_stretches+1):
            
            k = float(y)/float(n_stretches)
            
            query_path = sql_path + '/' + country_folder + '/' + 'path_finder_roads_to_points.sql'
            
            with open(query_path) as file, database(parser) as db:
                query = file.read()
                query_formatted = query.format(schema = schema,
                                   k = k,
                                   table_roads = roads_table,
                                   id_iteration = id_iteration,
                                   length_iteration = length_iteration)
                road_point_iteration = pd.read_sql_query(query_formatted, db)
                
            roads_output = roads_output.append(road_point_iteration)
            del road_point_iteration
            
    return roads_output