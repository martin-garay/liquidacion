--si esta cargado este valor se toma para la liquidacion sino se levanta el de la categoria
alter table personas add column basico numeric(10,2);

--cambio la columna legajo de text to integer
DROP VIEW v_recibos ;
DROP VIEW public.v_personas;
alter table personas  alter column legajo TYPE integer;
CREATE OR REPLACE VIEW public.v_personas AS 
SELECT a.legajo,
    a.id,
    a.nombre,
    a.apellido,
    a.fecha_nacimiento,
    a.id_tipo_documento,
    a.nro_documento,
    a.cuil,
    a.id_genero,
    a.id_nacionalidad,
    a.activo,
    a.domicilio,
    g.descripcion AS genero,
    td.descripcion AS tipo_documento,
    a.id_localidad,
    loc.nombre AS localidad,
    loc.cp,
    loc.provincia,
    loc.pais,
    n.descripcion AS nacionalidad,
    a.telefono_particular,
    a.telefono_celular,
    a.email,
    a.id_estado_civil,
    ec.descripcion AS estado_civil,
    a.id_categoria,
    c.descripcion AS categoria,
    a.id_establecimiento,
    es.descripcion AS establecimiento,
    a.id_obra_social,
    os.descripcion AS obra_social,
    os.codigo AS codigo_obra_social,
    c.sueldo_basico,
    c.valor_hora,
    a.id_tipo_contrato,
    tc.descripcion AS tipo_contrato,
    a.horas_jornada
FROM personas a
LEFT JOIN estados_civiles ec ON ec.id = a.id_estado_civil
LEFT JOIN categorias c ON c.id = a.id_categoria
LEFT JOIN establecimientos es ON es.id = a.id_establecimiento
LEFT JOIN obras_sociales os ON os.id = a.id_obra_social
LEFT JOIN v_localidades loc ON loc.id = a.id_localidad
LEFT JOIN nacionalidades n ON n.id = a.id_nacionalidad
LEFT JOIN tipos_documentos td ON td.id = a.id_tipo_documento
LEFT JOIN generos g ON g.id = a.id_genero
LEFT JOIN tipos_contratos tc ON tc.id = a.id_tipo_contrato;
CREATE OR REPLACE VIEW public.v_recibos AS 
SELECT r.id,
    r.nro_recibo,
    r.id_persona,
    r.total_remunerativos,
    r.total_no_remunerativos,
    r.total_deducciones,
    r.total_neto,
    r.total_basico,
    r.id_liquidacion,
    ((((l.descripcion || '(Período '::text) || date_part('month'::text, l.periodo)) || '-'::text) || date_part('year'::text, l.periodo)) || ')'::text AS descripcion_liquidacion,
    l.periodo,
    p.nombre,
    p.apellido,
    p.nro_documento,
    p.tipo_documento,
    p.legajo,
    p.id_categoria,
    p.categoria,
    p.id_tipo_contrato,
    p.tipo_contrato
FROM recibos r
JOIN liquidaciones l ON l.id = r.id_liquidacion
JOIN v_personas p ON p.id = r.id_persona;

--agrego un campo activas para las liquidaciones
alter table tipos_liquidaciones add column activo boolean not null default true;

ALTER TABLE public.conceptos ADD COLUMN observaciones text;

ALTER TABLE public.fichajes_resumen ADD COLUMN dias_vacaciones integer;
ALTER TABLE public.fichajes_resumen ALTER COLUMN dias_vacaciones SET DEFAULT 0;

alter table conceptos add column valor_fijo numeric(10,2);

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
    c.observaciones
FROM conceptos c
JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;

CREATE OR REPLACE VIEW public.v_tipo_liquidacion_conceptos AS 
SELECT tlc.id,
		tlc.id_concepto,
		tlc.id_tipo_liquidacion,
		(('['::text || c.codigo) || '] '::text) || c.descripcion AS concepto,
		tl.descripcion AS tipo_liquidacion,
		c.codigo,
		c.valor_fijo
FROM tipo_liquidacion_conceptos tlc
JOIN conceptos c ON c.id = tlc.id_concepto
JOIN tipos_liquidaciones tl ON tl.id = tlc.id_tipo_liquidacion;

--agrego uk al codigo de concepto
alter table conceptos add constraint uk_conceptos unique(codigo);