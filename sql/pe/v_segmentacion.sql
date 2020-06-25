CREATE OR REPLACE VIEW
    {schema}.v_segmentacion
    (
        ubigeo,
        segmento_telefonica,
        segmento_overlay,
        segmento_greenfield
    ) AS
SELECT
    segmentation.settlement_id              AS ubigeo,
    segmentation.telefonica_organic_segment AS segmento_telefonica,
    segmentation.overlay_2g_segment         AS segmento_overlay,
    segmentation.greenfield_segment         AS segmento_greenfield
FROM
    {schema}.segmentation;
