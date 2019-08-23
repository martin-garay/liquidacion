create table conceptos_personas(
	id serial not null,
	id_concepto integer not null,
	id_persona integer not null,
	valor_fijo numeric(10,2),
	constraint pk_conceptos_personas primary key(id),
	constraint fk_conceptos_personas__conceptos foreign key (id_concepto) references conceptos(id),
	constraint fk_conceptos_personas__personas foreign key (id_persona) references personas(id),
	constraint uk_conceptos_personas unique(id_concepto,id_persona)
);

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
    (('['::text || c.codigo) || '] '::text) || c.descripcion as descripcion_codigo
   FROM conceptos c
     JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;