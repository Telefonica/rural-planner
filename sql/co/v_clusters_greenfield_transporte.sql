CREATE OR REPLACE VIEW {schema}.v_clusters_greenfield_transporte as (
SELECT c.centroid as centroide,
        t.movistar_transport_id as torre_transporte_movistar_optima_2,
        distance_movistar_transport_m as distancia_torre_transporte_movistar_optima_2,
        line_of_sight_movistar as lv_torre_transporte_movistar_optima_2,
        anditel_transport_id as torre_transporte_anditel_optima_2,
        distance_anditel_transport_m as distancia_torre_transporte_anditel_optima_2,
        line_of_sight_anditel as lv_torre_transporte_anditel_optima_2,
        azteca_transport_id as torre_transporte_azteca_optima_2,
        distance_azteca_transport_m as distancia_torre_transporte_azteca_optima_2,
        line_of_sight_azteca as lv_torre_transporte_azteca_optima_2,
        atp_transport_id as torre_transporte_atp_optima_2,
        distance_atp_transport_m as distancia_torre_transporte_atp_optima_2,
        line_of_sight_atp as lv_torre_transporte_atp_optima_2,
        atc_transport_id as torre_transporte_atc_optima_2,
        distance_atc_transport_m as distancia_torre_transporte_atc_optima_2,
        line_of_sight_atc as lv_torre_transporte_atc_optima_2,
        phoenix_transport_id as torre_transporte_phoenix_optima_2,
        distance_phoenix_transport_m as distancia_torre_transporte_phoenix_optima_2,
        line_of_sight_phoenix as lv_torre_transporte_phoenix_optima_2,
        qmc_transport_id as torre_transporte_qmc_optima_2,
        distance_qmc_transport_m as distancia_torre_transporte_qmc_optima_2,
        line_of_sight_qmc as lv_torre_transporte_qmc_optima_2,
        uniti_transport_id as torre_transporte_uniti_optima_2,
        distance_uniti_transport_m as distancia_torre_transporte_uniti_optima_2,
        line_of_sight_uniti as lv_torre_transporte_uniti_optima_2
        FROM {schema}.clusters c
        LEFT JOIN {schema}.transport_greenfield_clusters t
        on c.centroid=t.centroid        
        )
