CREATE OR REPLACE VIEW public.v_conceptos AS 
 SELECT c.id,
    c.descripcion,
    c.codigo,
    c.id_tipo_concepto,
    c.formula,
    tc.descripcion AS tipo_concepto,
    c.mostrar_en_recibo,
    c.totaliza,
    c.mostrar_si_cero,
    c.valor_fijo,
    c.observaciones,
    (('['::text || c.codigo) || '] '::text) || c.descripcion AS descripcion_codigo,
    c.remunerativo,
    c.retencion
   FROM conceptos c
     JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;

--agrego un rango a los tipos de conceptos
alter table tipos_conceptos add column desde integer;
alter table tipos_conceptos add column hasta integer;