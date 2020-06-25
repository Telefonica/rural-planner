import pandas as pd
import numpy as np
import math
import networkx as nx
from networkx import *

def solve_fiber_path(row, owner, fiber_nodes_owner, G1):

    current_node = str(int(row['node_id']))
    
    paths = nx.single_source_dijkstra_path(G1, current_node)
    lengths = nx.single_source_dijkstra_path_length(G1, current_node)

    all_paths_from_fiber = { node: paths[node] for node in fiber_nodes_owner }
    all_lengths_from_fiber = { node: lengths[node] for node in fiber_nodes_owner }

    if(len(all_paths_from_fiber) > 0):
        optimal_node = min(all_lengths_from_fiber, key=all_lengths_from_fiber.get)

        optimal_path = paths[optimal_node]
        optimal_path_length = lengths[optimal_node]
    else:
        optimal_path = [None]
        optimal_path_length = None

    output = pd.Series({('length_' + owner): optimal_path_length, ('path_' + owner): optimal_path, 
                    ('fiber_node_' + owner): optimal_path[-1]})
    return output



def solve_mw_path(row, owner, fiber_nodes_owner, G1, df_edges):

    current_node = str(int(row['node_id']))
    
    paths = nx.single_source_dijkstra_path(G1, current_node)
    lengths = nx.single_source_dijkstra_path_length(G1, current_node)

    all_paths_from_fiber = { node: paths[node] for node in fiber_nodes_owner if node in paths}
    all_lengths_from_fiber = { node: lengths[node] for node in fiber_nodes_owner if node in lengths}

    if(len(all_paths_from_fiber) > 0):
        optimal_node = min(all_lengths_from_fiber, key=all_lengths_from_fiber.get)
        optimal_path_length = lengths[optimal_node]

        sites_optimal = {k: v for k, v in all_lengths_from_fiber.items() if v == optimal_path_length}
        df_sites_optimal = pd.DataFrame.from_dict(sites_optimal, orient = 'index')
        df_sites_optimal['tower_id'] = df_sites_optimal.index
        df_sites_optimal.columns = ['length', 'tower_id']
        df_sites_optimal = df_sites_optimal[['tower_id', 'length']]

        candidates = list(df_sites_optimal['tower_id'])

        paths_optimal = {k: v for k, v in all_paths_from_fiber.items() if k in candidates}
        df_paths_optimal = pd.DataFrame.from_dict(paths_optimal, orient = 'index')

        df_paths_optimal['node'] = df_paths_optimal.index
        df_paths_optimal = df_paths_optimal[['node', 0, 1]]
        df_paths_optimal.columns = ['node', 'site', 'last_hop']

        last_hops = list(df_paths_optimal['last_hop'])
        final_site_list = list(df_paths_optimal['site'])

        priority_list = df_edges.ix[(df_edges['tower_id_1'].astype(str).isin(last_hops) 
                                     & df_edges['tower_id_2'].astype(str).isin(final_site_list)) |
                (df_edges['tower_id_2'].astype(str).isin(last_hops) & 
                 df_edges['tower_id_1'].astype(str).isin(final_site_list))].sort_values('distance')
        towers_priority = list(priority_list[['tower_id_1', 'tower_id_2']].astype(str).iloc[0])

        df_optimal_site = df_paths_optimal.ix[df_paths_optimal['last_hop'].isin(towers_priority)]
        optimal_node = df_optimal_site['node'].iloc[0]

        optimal_path = paths[optimal_node]
        optimal_path_length = lengths[optimal_node]

    else:
        optimal_path = [None]
        optimal_path_length = None

    output = pd.Series({('length_' + owner): optimal_path_length, ('path_' + owner): optimal_path, 
                    ('fiber_node_' + owner): optimal_path[-1]})
    return output