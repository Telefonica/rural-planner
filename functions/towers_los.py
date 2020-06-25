import pandas as pd
import numpy as np
import math
import geopy
from geopy.distance import vincenty
from geopy.distance import VincentyDistance
import srtm
from geohelper import distance 
from geohelper import bearing
from .utils import elevation_google
from .check_los import check_los

def towers_los(row, elevation_data=None, interval=30, tower_height=30):

    if not elevation_data:
        elevation_data = srtm.get_data()
    
    # Tower IDs
    tower_1 = row['node_id']
    tower_2 = row['centroid']
    
    # Tower Heights
    tower_height_1 = tower_height
    tower_height_2 = row['tower_height']
    
    # Skip missing lat long
    if row[['latitude_road', 'longitude_road', 
            'latitude_centroid', 'longitude_centroid']].isnull().sum() > 0:
        print("Skip for lack of lat long")
        output = pd.Series({'line_of_sight': False, 'error_flag': True, 
                            'add_height_tower_1': math.nan, 'add_height_tower_2': math.nan})
        return output
        
    
    # Origin and destination
    origin = geopy.Point(row['latitude_road'], row['longitude_road'])
    destination = geopy.Point(row['latitude_centroid'], row['longitude_centroid'])
    
    # We calculate altitudes of both points
    H1 = elevation_data.get_elevation(origin.latitude, origin.longitude, approximate=True)
    H2 = elevation_data.get_elevation(destination.latitude, destination.longitude, approximate=True)
    
    # If we did not get data for any of them, we try with Google's API. 
    # If it does not work, we skip with Line of Sight as False
    if(pd.isnull(H1)):
        H1 = elevation_google(origin.latitude, origin.longitude)
            
    if(pd.isnull(H2)):
        H2 = elevation_google(destination.latitude, destination.longitude)
        
    if(pd.isnull(H1) or pd.isnull(H2)):
        print("Skip for lack of H1 H2")
        output = pd.Series({'line_of_sight': False, 'error_flag': True, 
                            'add_height_tower_1': math.nan, 'add_height_tower_2': math.nan})
        return output

    
    distance_offset = 1000
    tree_height = 20 if row['orography'] == 'JUNGLE' else 0
       
    #If none of the conditions above is true, we evaluate if there is line of sight and save the outputs
    (line_of_sight, flag_los, _, 
     additional_height_1, additional_height_2) = check_los(origin, destination, 
                                                           tower_height_1, tower_height_2, 
                                                           interval, tree_height, distance_offset)
    
    
    output = pd.Series({'line_of_sight': line_of_sight, 'error_flag': flag_los, 
                        'add_height_tower_1': additional_height_1, 
                        'add_height_tower_2': additional_height_2})
        
    return output