CREATE OR REPLACE VIEW public.v_recibos_conceptos AS 
 SELECT rc.id,
    rc.id_concepto,
    rc.importe,
    rc.id_recibo,
    c.descripcion AS concepto,
    c.codigo,
    'c'::text || c.codigo AS nombre_variable,
    c.formula,
    c.mostrar_en_recibo,
    c.totaliza,
    c.id_tipo_concepto,
    r.nro_recibo,
    r.id_persona,
    r.id_liquidacion,
    l.mes,
    l.anio,
    l.periodo,
    l.descripcion AS liquidacion_descripcion
   FROM recibos_conceptos rc
     JOIN recibos r ON r.id = rc.id_recibo
     JOIN conceptos c ON c.id = rc.id_concepto
     JOIN liquidaciones l ON l.id = r.id_liquidacion;


create view v_recibos_conceptos_detallado as
select c.*,
	p.legajo,p.nombre,p.apellido,p.nro_documento,p.id_tipo_documento,tipo_documento,
	estado_civil,id_categoria,categoria,sueldo_basico,fecha_ingreso,fecha_egreso,cuil,
	id_establecimiento, establecimiento
from v_recibos_conceptos c 
join v_personas p ON p.id=c.id_persona;