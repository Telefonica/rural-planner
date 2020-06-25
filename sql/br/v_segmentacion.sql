CREATE OR REPLACE VIEW
    {schema}.v_segmentacion
    (
        codigo_setor,
        segmento_telefonica,
        segmento_overlay,
        segmento_greenfield,
        segmento_sin_conectar
    ) AS
SELECT
    segmentation.settlement_id              AS codigo_setor,
    segmentation.telefonica_organic_segment AS segmento_telefonica,
    segmentation.overlay_2g_segment         AS segmento_overlay,
    segmentation.greenfield_segment         AS segmento_greenfield,
    segmentation.fully_unconnected_segment AS segmento_sin_conectar
FROM
    {schema}.segmentation;