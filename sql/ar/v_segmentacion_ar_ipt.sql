CREATE OR REPLACE VIEW
    {schema}.v_segmentacion_ipt
    (
        ubigeo,
        segmento_telefonica,
        segmento_overlay,
        segmento_greenfield,
        segmento_fully_unconnected
    ) AS
SELECT
    segmentation.settlement_id              AS ubigeo,
    segmentation.telefonica_organic_segment AS segmento_telefonica,
    segmentation.overlay_2g_segment         AS segmento_overlay,
    segmentation.greenfield_segment         AS segmento_greenfield,
    segmentation.fully_unconnected_segment         AS segmento_fully_unconnected    
FROM
    {schema}.segmentation_ipt;
