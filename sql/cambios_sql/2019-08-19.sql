alter table sistema.reservadas add column defecto text;
CREATE OR REPLACE VIEW sistema.v_reservadas AS 
	SELECT r.id,
	r.nombre,
	r.descripcion,
	r.descripcion_larga,
	r.query,
	r.valor,
	r.id_tipo_reservada,
	r.id_tipo_dato,
	tr.descripcion AS tipo_reservada,
	td.descripcion AS tipo_dato,
	r.defecto
FROM sistema.reservadas r
 LEFT JOIN sistema.tipos_reservadas tr ON tr.id = r.id_tipo_reservada
 LEFT JOIN sistema.tipos_datos td ON td.id = r.id_tipo_dato;


alter table conceptos add column mostrar_si_cero boolean not null default false;
CREATE OR REPLACE VIEW public.v_conceptos AS 
SELECT c.id,
	c.descripcion,
	c.codigo,
	c.id_tipo_concepto,
	c.formula,
	tc.descripcion AS tipo_concepto,
	c.mostrar_en_recibo,
	c.totaliza,
	c.mostrar_si_cero
FROM conceptos c
JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;
