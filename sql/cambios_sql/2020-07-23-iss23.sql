alter table liquidaciones add column hoja_inicial integer ;

CREATE OR REPLACE VIEW public.v_liquidaciones AS 
 SELECT l.id,
    l.id_estado,
    el.descripcion AS estado,
    l.descripcion,
    l.periodo,
    (date_part('year'::text, l.periodo) || '-'::text) || date_part('month'::text, l.periodo) AS periodo_descripcion,
    l.fecha_desde,
    l.fecha_hasta,
    l.id_tipo_liquidacion,
    l.id_establecimiento,
    l.id_banco,
    l.fecha_pago,
    l.periodo_depositado,
    l.lugar_pago,
    tl.descripcion AS tipo_liquidacion,
    e.descripcion AS establecimiento,
    b.descripcion AS banco,
    l.mes,
    l.anio,
    l.fecha_deposito,
    l.nro_recibo_inicial,
    e.direccion AS direccion_establecimiento,
    e.localidad AS localidad_establecimiento,
    e.cp AS cp_establecimiento,
    e.provincia AS provincia_establecimiento,
    e.cuit,
    e.actividad,
    e.id_tipo_empleador,
    e.tipo_empleador,
    l.fecha_carga_social,
    l.mes_carga_social,
    l.total_remunerativos,
    l.total_no_remunerativos,
    l.total_deducciones,
    l.total_neto,
    l.hoja_inicial
FROM liquidaciones l
JOIN estados_liquidacion el ON el.id = l.id_estado
JOIN tipos_liquidaciones tl ON tl.id = l.id_tipo_liquidacion
JOIN v_establecimientos e ON e.id = l.id_establecimiento
LEFT JOIN bancos b ON b.id = l.id_banco;

