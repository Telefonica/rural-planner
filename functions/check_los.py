#Load libraries
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import math
import geopy
from geopy.distance import vincenty
from geopy.distance import VincentyDistance
import srtm
from geohelper import distance 
from geohelper import bearing
import sys
from datetime import datetime
import os
from .utils import elevation_google

## Lambda set for freq=11GHz
def check_los(apikey, origin, destination, tower_height_1, tower_height_2, interval, height_offset, distance_offset, fresnel = True, curvature = True, landa= 0.0273):

    #Import API for elevation
    elevation_data = srtm.get_data(srtm3 = True)

    # Get initial and final altitudes
    H1 = elevation_data.get_elevation(origin.latitude, origin.longitude)
    H2 = elevation_data.get_elevation(destination.latitude, destination.longitude)
        
    #Initialize the error flag that returns True if there has been any issue with the API
    flag_error = False
    
    #If the API did not find altitudes for either the origin or the destination, then we skip the whole process and return
    #True by default but with the flag_error set to True as well.
    #If we did not get data for any of them, we try with Google's API. 
    #If it does not work, we skip with Line of Sight as False
    
    if(pd.isnull(H1)):
        H1 = elevation_google(origin.latitude, origin.longitude, apikey)
           
    if(pd.isnull(H2)):
        H2 = elevation_google(destination.latitude, destination.longitude, apikey)
    
    if(pd.isnull(H1) or pd.isnull(H2)):
        line_of_sight = False
        flag_error  = True
        return (line_of_sight, flag_error, pd.DataFrame({'Lat': [], 'Lon': [], 'Alt': []}), 0, 0)
    
    # Bearing (orientation or azimuth, same thing) needed to go in a straight line from origin to destination
    azimuth = bearing.initial_compass_bearing(origin.latitude, origin.longitude, destination.latitude, destination.longitude)

    # Distance origin-destination
    distance_total = distance.get_distance(origin.latitude, origin.longitude, destination.latitude, destination.longitude)

    # Number of intermediate points where we will evaluate the altitude
    number_segments = int(distance_total / interval)    
    
    
    # Initialize the current point variable and the list of latitudes, longitudes, altitudes and intermediate distances
    current_point = origin
    lats = []
    longs = []
    alts = []
    dis = []
    los = []

    k=4/3
    radio_tierra = 6370000


    # Insert the first set of data
    lats.insert(len(lats), float(origin.latitude))
    longs.insert(len(longs), float(origin.longitude))
    alts.insert(len(alts), float(H1))
    dis.insert(len(dis), 0)
    los.insert(len(los), True)

    # Initialize line_of_sight to True and rest of variables to zero
    line_of_sight = True
    max_alt = 0
    
    delta_height_tower_1 = 0
    delta_height_tower_2 = 0
    max_dt1 = 0
    max_dt2 = 0
    radio_fresnel = 0
    flecha = 0

    # We start evaluating the altitude of all intermediate points between origin and destination
    for y in range(0, number_segments):

        # Evaluate altitude and distance of intermediate point
        destination_intermediate = VincentyDistance(meters=interval).destination(current_point, azimuth)
        altitude = elevation_data.get_elevation(destination_intermediate.latitude, destination_intermediate.longitude)
        di = distance.get_distance(origin.latitude, origin.longitude, destination_intermediate.latitude, destination_intermediate.longitude)
        
        if(di >= distance_offset and abs(di-distance_total) >= distance_offset):
            tree_height_iteration = height_offset
        else: 
            tree_height_iteration = 0
        
        # If the API returned a valid altitude, we evaluate conditions. Otherwise we skip the process and we will return
        # Line of sight as True and flag_error as True as well
        if altitude:
            
            altitude = altitude + tree_height_iteration
            
            recta_los = H1 + tower_height_1 + (H2 - H1 + tower_height_2 - tower_height_1) * di / distance_total
            
            if(distance_total-di >= 0): # Para solucionar error ultima iteración
                if (fresnel is True):
                    radio_fresnel = 0.6 * np.sqrt(landa*di*(distance_total-di)/distance_total)
                else:
                    radio_fresnel = 0
                if (curvature is True):
                    flecha = di*(distance_total-di)/(2*k*radio_tierra)
                else:
                    flecha = 0

            # Geometric conditions to be met if there is NOT line of sight because of this point
            if altitude >= (recta_los-radio_fresnel-flecha):
                #print(recta_los)
                # In this case there is no line of sight and we proceed to calculate geometrically the additional altitude we would
                # need at both ends (separately) in order to have line of sight
                line_of_sight = False
                delta_height_tower_1 = (di/(distance_total - di))*((altitude + radio_fresnel + flecha - H1)*distance_total/di + H1 - H2 - tower_height_2) - tower_height_1
                delta_height_tower_2 = (altitude + radio_fresnel + flecha - H1 - tower_height_1)*distance_total/di + H1 - H2 + tower_height_1 - tower_height_2
                
                #We update the value of these additional altitudes if it is greater than the additional altitudes calculated previously
                if(delta_height_tower_1 > max_dt1):
                    max_dt1 = delta_height_tower_1
                if(delta_height_tower_2 > max_dt2):
                    max_dt2 = delta_height_tower_2

            # Insert at the end of the lists of points the new values obtained
            lats.insert(len(lats), float(destination_intermediate.latitude))
            longs.insert(len(longs), float(destination_intermediate.longitude))
            alts.insert(len(alts), float(altitude))
            dis.insert(len(dis), float(di))
            los.insert(len(los), bool(line_of_sight))


        # Update intermediate point for next iteration
        current_point = destination_intermediate

    # Once we finish evaluating everything we create a data frame with all the information
    data = [('Lat', lats), ('Long', longs), ('Alt', alts), ('Di', dis), ('LoS', los)]
    df = pd.DataFrame.from_items(data,columns=['Lat','Long', 'Alt', 'Di', 'LoS'])
    
    #df = pandas.DataFrame({'Lat': lats, 'Long': longs, 'Alt': alts, 'Di': dis, 'LoS': los})
    
    #If we do not have enough points (either 0,1 or it failed to get the altitude of 20% of more of the intermediate points)
    if(len(df) <= 1 or len(df)<0.5*number_segments):
        line_of_sight = False
        flag_error = True
    
    # We return line of sight (True or False), flag_error (True or False), data frame with the data, and the max values of the
    # additional height needed.
    return (line_of_sight, flag_error, df, max_dt1, max_dt2)