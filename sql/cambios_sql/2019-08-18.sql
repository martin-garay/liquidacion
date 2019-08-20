alter table recibos_conceptos alter column importe drop not null;

create or replace view v_recibos as 
select r.*,      
    l.descripcion||'(Período '||extract(month from l.periodo)||'-'||extract(year from l.periodo)||')' as descripcion_liquidacion,
    l.periodo,
    nombre,apellido,nro_documento,tipo_documento,legajo,id_categoria,categoria,id_tipo_contrato,tipo_contrato
from recibos r 
join liquidaciones l ON l.id=r.id_liquidacion
join v_personas p ON p.id=r.id_persona;

--agrego periodo_descripcion (anio-mes)
drop view v_liquidaciones;
CREATE OR REPLACE VIEW public.v_liquidaciones AS 
SELECT l.id,
    l.id_estado,
    el.descripcion AS estado,
    l.descripcion,
    l.periodo,
    extract(year from l.periodo)||'-'||extract(month from l.periodo) as periodo_descripcion,
    l.fecha_desde,
    l.fecha_hasta,
    l.id_tipo_liquidacion,
    l.id_establecimiento,
    l.id_banco,
    l.fecha_pago,
    l.periodo_depositado AS mes,
    l.lugar_pago,
    tl.descripcion AS tipo_liquidacion,
    e.descripcion AS establecimiento,
    b.descripcion AS banco
FROM liquidaciones l
JOIN estados_liquidacion el ON el.id = l.id_estado
JOIN tipos_liquidaciones tl ON tl.id = l.id_tipo_liquidacion
JOIN establecimientos e ON e.id = l.id_establecimiento
LEFT JOIN bancos b ON b.id = l.id_banco;

--faltaban 2 campos antes de poder crear la vista: agregados el 20-08-2019
alter table conceptos add column mostrar_en_recibo boolean not null default false;
alter table conceptos add column totaliza boolean not null default false;

create or replace view v_recibos_conceptos as
select rc.*,
    c.descripcion as concepto,c.codigo,'c'||c.codigo as nombre_variable,c.formula,c.mostrar_en_recibo,c.totaliza,c.id_tipo_concepto,
    nro_recibo,id_persona,id_liquidacion
from recibos_conceptos rc
join recibos r ON r.id=rc.id_recibo
join conceptos c ON c.id=rc.id_concepto;
