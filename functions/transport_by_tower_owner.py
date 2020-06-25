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
    
def transport_by_tower_owner(parser, owners, owner_name, query_path, query_path_all, column_name):
    # Import data    
    sql_path =  parser['sql_path']
    country_folder = parser['country_folder']
    schema = parser['transport_by_tower_params']['schema']

    table_infrastructure = parser['transport_by_tower_params']['table_infrastructure']
    table_clusters = parser['clustering_params']['output_table']
    table_settlements = parser['clustering_params']['table_settlements']
    table_transport = parser['transport_by_tower_params']['output_table']
    table_transport_clusters = parser['transport_gf_cl_params']['output_table']


    mw_radius = int(parser['transport_by_tower_params']['mw_radius'])
    fiber_radius = int(parser['transport_by_tower_params']['fiber_radius'])
    los_interval = int(parser['transport_by_tower_params']['los_interval'])
    height_offset = int(parser['transport_by_tower_params']['height_offset'])
    distance_offset = int(parser['transport_by_tower_params']['distance_offset'])
    sources_omit = parser['transport_by_tower_params']['sources_omit']
    
    owners_tx = dict(parser['transport_by_tower_params']['owners_tx'])

    third_party_owners = parser['transport_by_tower_params']['third_party_owners']
    regional_owners = parser['transport_by_tower_params']['regional_owners']
    tef_alias = (owners_tx.keys() - (regional_owners + third_party_owners)).pop()

    apikey = parser['api_config']['apikey']

    with open(query_path) as file, open(query_path_all) as file_all, database(parser) as db:
        query = file.read()
        query_formatted = query.format(schema = schema, table = table_infrastructure, table_clusters = table_clusters, radius = mw_radius, owners = (','.join('\'{0}\''.format(w) for w in owners)), sources_omit = (','.join('\'{0}\''.format(s) for s in sources_omit)),
                                      table_transport = table_transport, fiber_radius = fiber_radius, 
                                      mw_radius = mw_radius, tef_alias = tef_alias,
                                      table_transport_clusters = table_transport_clusters,
                                      table_settlements = table_settlements)
        df_towers = pd.read_sql_query(query_formatted, con = db)
        
        query_all = file_all.read()
        query_formatted_all = query_all.format(schema = schema, table = table_infrastructure, table_clusters = table_clusters, sources_omit = (','.join('\'{0}\''.format(s) for s in sources_omit)),
                                      table_transport = table_transport, fiber_radius = fiber_radius, 
                                      mw_radius = mw_radius, tef_alias = tef_alias,
                                      table_transport_clusters = table_transport_clusters,
                                      table_settlements = table_settlements)
        df_towers_all = pd.read_sql_query(query_formatted_all, con = db)
        
    #Calculation of nearest transport point.
    #We calculate for each tower the nearest transport tower (with either radio or fiber) from : Movistar, regional projects and third parties (third parties only if we did not find any previous Movistar transport with line of sight).
    #We prioritize those with line of sight and if there are none, by the smallest additional height to add to any of the two towers: origin or destination.

    #Some simple modifications
    df_towers.distance = df_towers.distance.round()
    df_towers.tower_height_1 = df_towers.tower_height_1.fillna(0)
    df_towers.tower_height_2 = df_towers.tower_height_2.fillna(0)

    #Unique towers to calculate nearest transport (unique IDs in tower_id_1)
    df_towers_unique = df_towers.copy(deep = True)
    df_towers_unique = df_towers_unique[column_name].drop_duplicates().reset_index().drop('index',1)

    #List of unique IDs
    list_towers_to_process = df_towers_unique[column_name]

    #All existint towers
    list_all_towers = df_towers_all[column_name]

    #Initialization

    df_towers_all[owner_name + '_transport_id'] = math.nan
    df_towers_all['distance_' + owner_name + '_transport_m'] = math.nan
    df_towers_all['line_of_sight_' + owner_name] = False
    df_towers_all['additional_height_tower_1_' + owner_name + '_m'] = math.nan
    df_towers_all['additional_height_tower_2_' + owner_name + '_m'] = math.nan
 
    #Those towers that already have radio or fiber are automatically assigned to themselves.
    #The case where, even though the tower does not have fiber and radio, we did not find any tower with transport nearby, will be left as NULL

    #Case where tower has owners' tx
    df_towers_all.loc[
        (~ df_towers_all[column_name].isin(list_towers_to_process)) & 
        (df_towers_all['owner'].isin(owners)) &
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)), owner_name + '_transport_id'] = df_towers_all.loc[(~ df_towers_all[column_name].isin(list_towers_to_process)) &                                                                                                                  
                       (df_towers_all['owner'].isin(owners)) &
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)),                                                                                                                    
                       column_name] 
    df_towers_all.loc[
        (~ df_towers_all[column_name].isin(list_towers_to_process)) & 
        (df_towers_all['owner'].isin(owners)) & 
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)), 'distance_' + owner_name + '_transport_m'] = 0

    df_towers_all.loc[
        (~ df_towers_all[column_name].isin(list_towers_to_process)) & 
        (df_towers_all['owner'].isin(owners)) & 
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)),'line_of_sight_' + owner_name] = True
    df_towers_all.loc[
        (~ df_towers_all[column_name].isin(list_towers_to_process)) & 
        (df_towers_all['owner'].isin(owners)) & 
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)),'additional_height_tower_1_' + owner_name + '_m'] = 0
    df_towers_all.loc[
        (~ df_towers_all[column_name].isin(list_towers_to_process)) & 
        (df_towers_all['owner'].isin(owners)) & 
        ((df_towers_all['radio'] == True) | (df_towers_all['fiber'] == True)),'additional_height_tower_2_' + owner_name + '_m'] = 0


    #Number of towers to process:
    n_towers = len(df_towers_unique)


    #We loop through all the unique tower IDs, for each one of them we will search all possible candidates (all towers within 50 km with transport -separately by Movistar and third parties)
    for x in range(0,n_towers):

        print("Iteration: " + str(x) + "/" + str(n_towers) + "   " + str(datetime.now()))

        #Tower for the current iteration (we search towers nearby this one)
        tower_iteration = df_towers_unique[column_name][x]
        tower_iteration_info = df_towers.loc[df_towers[column_name] == tower_iteration]

        #Data frame with all the rows where the tower_id_1 index is that of the tower we are analyzing
        df_iteration = df_towers.copy(deep = True)
        df_iteration = df_iteration.loc[df_iteration[column_name] == tower_iteration]
        df_iteration = df_iteration.reset_index(drop = True)

        #Number of iterations for this specific tower
        n_iterations = len(df_iteration)

        min_additional_height = 10000 #Big number

        #We loop through each candidate (towers with transport within a 20-km radius)
        for y in range(0, n_iterations):

            #Current tower to evaluate
            tower_2_iteration = df_iteration['tower_id_2'].iloc[y]
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
            if(df_iteration['distance'][y] < los_interval):
                line_of_sight = True
                flag_los = False
                #print("Skip for distance too small")
                #Case where the candidate tower belongs to Movistar
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, owner_name + '_transport_id'] = tower_2_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'distance_' + owner_name + '_transport_m'] = distance_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'line_of_sight_' + owner_name] = line_of_sight
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_1_' + owner_name + '_m'] = 0
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_2_' + owner_name + '_m'] = 0
                break


            #If none of the conditions above is true, we evaluate if there is line of sight and save the outputs
            output = check_los(apikey, origin, destination, tower_height_1, tower_height_2, los_interval, height_offset, distance_offset)

            line_of_sight = output[0]
            flag_los = output[1]
            df_points = output[2]
            additional_height_1 = output[3]
            additional_height_2 = output[4]


            #If we did find line of sight, we save the tower. If it is Movistar, we finish the process and stop searching for more candidates. 
            #If we finish searching all Movistars and there is no LoS we go for regional and then for 3rd parties
            if(line_of_sight):
                #print("Entered in line of sight")
                #print(owner_name)
                line_of_sight = True
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, owner_name + '_transport_id'] = tower_2_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'distance_' + owner_name + '_transport_m'] = distance_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'line_of_sight_' + owner_name] = line_of_sight
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_1_' + owner_name + '_m'] = additional_height_1
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_2_' + owner_name + '_m'] = additional_height_2
                break

            #If we did NOT find line of sight but the tower is within a small distance, we save the tower. 
            if(not(line_of_sight) and distance_iteration <= fiber_radius):
                #print("Entered in line of sight")
                line_of_sight = False
                #print("...and then to third-parties chunk")
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, owner_name + '_transport_id'] = tower_2_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'distance_' + owner_name + '_transport_m'] = distance_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'line_of_sight_' + owner_name] = line_of_sight
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_1_' + owner_name + '_m'] = 0
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_2_' + owner_name + '_m'] = 0
                break


            #If there is not line of sight, we update the best option prioritizing by the smallest additional height.
            if(not(line_of_sight) and (min(additional_height_1, additional_height_2) < min_additional_height)):                
                #print("Entered in NO line of sight") 
                min_additional_height = min(additional_height_1, additional_height_2)
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, owner_name + '_transport_id'] = tower_2_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'distance_' + owner_name + '_transport_m'] = distance_iteration
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'line_of_sight_' + owner_name] = line_of_sight
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_1_' + owner_name + '_m'] = additional_height_1
                df_towers_all.loc[df_towers_all[column_name] == tower_iteration, 'additional_height_tower_2_' + owner_name + '_m'] = additional_height_2
    
    df_towers_all = df_towers_all[[column_name,
                                    owner_name + '_transport_id',
                                    'distance_' + owner_name + '_transport_m',
                                    'line_of_sight_' + owner_name,
                                    'additional_height_tower_1_' + owner_name + '_m',
                                    'additional_height_tower_2_' + owner_name + '_m']]
    return df_towers_all
