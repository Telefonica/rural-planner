from .utils import database, elevation_google
from .check_los import check_los
import pandas as pd
import srtm
import geopy
import math
from geohelper import distance 
from geohelper import bearing
from configobj import ConfigObj
from datetime import datetime
    
def transport_by_tower_iterative(parser):
    # Import data    
    los_interval = int(parser['tower_to_tower_los_params']['los_interval'])
    height_offset = int(parser['transport_by_tower_params']['height_offset'])
    height_offset_jungle = int(parser['tower_to_tower_los_params']['height_offset_jungle'])
    distance_offset = int(parser['transport_by_tower_params']['distance_offset'])
    sources_omit = parser['transport_by_tower_params']['sources_omit']

    apikey = parser['api_config']['apikey']
    
    query_path = sql_path + '/' + country_folder + '/' + 'tower_to_tower_los_iteration_inputs.sql'
    query_path_all = sql_path + '/' + country_folder + '/' + 'tranpsort_by_tower_load_towers.sql'

    with open(query_path_all) as file_all, database(parser) as db:
        query_all = file_all.read()
        query_formatted_all = query_all.format(schema = schema, table_towers = table_towers, sources_omit = (','.join('\'{0}\''.format(s) for s in sources_omit)))
        df_towers_all = pd.read_sql_query(query_formatted_all, con = db)
    
    for x in range(0, n_towers):
    
        #Tower for the current iteration (we search towers nearby this one)
        tower_iteration = list_towers_to_process[x]

        print("Iteration: " + str(x) + "/" + str(n_towers) + "   " + str(datetime.now()))

        dat = { "tower_id" : tower_iteration }    
        
        with open(query_path) as file, database(parser) as db:
            query = file.read()
            query_formatted = query.format(schema = schema, table_towers = table_towers, mw_radius = mw_radius,
                                           tower_iteration = tower_iteration, table_orography = table_orography, sources_omit = (','.join('\'{0}\''.format(s) for s in sources_omit)))
            df_iteration = pd.read_sql_query(query_formatted, con = db)
            

        if len(df_iteration['tower_id_2'])==1 & (df_iteration['tower_id_2'][0] is None):
            df_towers_all = df_towers_all.append(dat, ignore_index = True)
            break

        df_iteration.distance = df_iteration.distance.round()
        df_iteration.tower_height_1 = df_iteration.tower_height_1.fillna(0)
        df_iteration.tower_height_2 = df_iteration.tower_height_2.fillna(0)

        #Number of iterations for this specific tower
        n_iterations = len(df_iteration)

        min_additional_height = 10000 #Big number


        #We loop through each candidate (towers with transport within a 20-km radius)
        for y in range(0, n_iterations):

            #Current tower to evaluate
            tower_2_iteration = df_iteration['tower_id_2'].iloc[y]
            
            if((df_iteration['orography_1'][x] == 'JUNGLE') & (df_iteration['orography_2'][x] == 'JUNGLE')):
                height_offset = hoeight_offset_jungle

            distance_iteration = df_iteration['distance'].iloc[y]
            #If we do not have lat, long for any of the towers (should never happen)
            if(pd.isnull(df_iteration['latitude_1'][y]) or 
               pd.isnull(df_iteration['longitude_1'][y])or 
               pd.isnull(df_iteration['latitude_2'][y]) or 
               pd.isnull(df_iteration['longitude_2'][y])):
                #print("Skip for lack of lat long")
                continue

            #We define origin and destination (towers 1 and 2)
            origin = geopy.Point(df_iteration['latitude_1'][y], df_iteration['longitude_1'][y])
            destination = geopy.Point(df_iteration['latitude_2'][y], df_iteration['longitude_2'][y])

            tower_height_1 = df_iteration['tower_height_1'][y]
            tower_height_2 = df_iteration['tower_height_2'][y]

            #If they are too close to apply the line of sight algorithm, we assume they do have line of sight since it is a very small distance
            if(df_iteration['distance'].iloc[y] < interval):
                line_of_sight = True
                flag_los = False
                dat["tower_id_2"] = tower_2_iteration
                dat["line_of_sight"] = line_of_sight
                dat["additional_height_tower_1"] = 0
                dat["additional_height_tower_2"] = 0
                dat["error_flag"] = flag_los
                df_towers_all = df_towers_all.append(dat, ignore_index = True)
                break
                
            #If none of the conditions above is true, we evaluate if there is line of sight and save the outputs
            output = check_los(origin, destination, tower_height_1, tower_height_2, interval, distance_offset, height_offset)

            line_of_sight = output[0]
            flag_los = output[1]
            df_points = output[2]
            additional_height_1 = output[3]
            additional_height_2 = output[4]

            #If we did find line of sight, we save the tower. 
            if(line_of_sight):
                #print("Entered in line of sight")
                line_of_sight = True
                dat["tower_id_2"] = tower_2_iteration
                dat["line_of_sight"] = line_of_sight
                dat["additional_height_tower_1"] = 0
                dat["additional_height_tower_2"] = 0
                dat["error_flag"] = flag_los
                df_towers_all = df_towers_all.append(dat, ignore_index = True)
                break

            #If there is not line of sight, we update the best option prioritizing by the smallest additional height.
            if(not(line_of_sight)):
                if(min(additional_height_1, additional_height_2) < min_additional_height):
                    min_additional_height = min(additional_height_1, additional_height_2)
                    dat["tower_id_2"] = tower_2_iteration
                    dat["line_of_sight"] = line_of_sight
                    dat["additional_height_tower_1"] = additional_height_1
                    dat["additional_height_tower_2"] = additional_height_2
                    dat["error_flag"] = flag_los
                    df_towers_all = df_towers_all.append(dat, ignore_index = True)
            
    
    return df_towers_all
