CREATE TABLE public.tabla_ganancias(
  id serial NOT NULL,
  minimo numeric(10,2) NOT NULL,
  maximo numeric(10,2),
  base numeric(10,2) NOT NULL,
  porcentaje numeric(10,2) NOT NULL,
  CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id)
);

create table tabla_vacaciones(
	id serial not null,
	desde numeric(10,2) not null,
	hasta numeric(10,2) not null,
	dias integer not null,	
	constraint pk_tabla_vacaciones primary key(id)
);

CREATE TABLE public.tabla_vacaciones_dias(
  id serial NOT NULL,
  desde integer NOT NULL,
  hasta integer NOT NULL,
  dias integer NOT NULL,
  CONSTRAINT pk_tabla_vacaciones_dias PRIMARY KEY (id)
);

alter table tabla_vacaciones_dias add column descripcion text;


/* 
---------------------------------------------------------------------------------
TRABAJADO A LA TARDE 
---------------------------------------------------------------------------------
*/
drop table fichajes;
drop table fichajes_resumen;

CREATE TABLE public.fichajes(
  id serial NOT NULL,
  fecha date NOT NULL,
  hora_entrada timestamp without time zone,
  hora_salida timestamp without time zone,
  horas_trabajadas numeric(10,2),
  horas_extras numeric(10,2),
  id_persona integer NOT NULL,
  CONSTRAINT pk_fichajes PRIMARY KEY (id),
  CONSTRAINT fk_fichajes__personas FOREIGN KEY (id_persona) REFERENCES public.personas (id)
);
CREATE TABLE public.periodos(
  id serial not null,
  descripcion text not null,
  anio integer not null,
  mes integer not null,
  periodo date not null,
  fecha_desde date NOT NULL,
  fecha_hasta date NOT NULL,
  constraint pk_periodos PRIMARY KEY (id)
);
CREATE TABLE public.periodos_detalle(
  id serial NOT NULL,
  id_persona integer NOT NULL, 
  dias_trabajados numeric(10,2),
  horas_comunes numeric(10,2),
  horas_extras numeric(10,2),
  inasistencias_justificadas numeric(10,2),
  inasistencias_injustificadas numeric(10,2),
  dias_vacaciones integer DEFAULT 0,
  id_periodo integer not null,
  CONSTRAINT pk_periodo_detalle PRIMARY KEY (id),
  CONSTRAINT fk_periodo_detalle__personas FOREIGN KEY (id_persona) REFERENCES public.personas (id),
  CONSTRAINT fk_periodo_detalle__periodo FOREIGN KEY (id_periodo) REFERENCES public.periodos(id)  
);

alter table periodos add column observaciones text;

ALTER TABLE public.periodos ADD CONSTRAINT uk_periodos UNIQUE(periodo);

create view v_periodos_detalle as
select pd.*, p.descripcion as descripcion_periodo,p.anio,p.mes,p.periodo,p.fecha_desde,p.fecha_hasta
FROM periodos_detalle pd 
JOIN periodos p ON p.id=pd.id_periodo;


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
    a.horas_jornada,
    a.fecha_ingreso,
    a.fecha_egreso
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

CREATE OR REPLACE FUNCTION public.antiguedad(id_persona integer,_fecha date default now())
  RETURNS integer AS
$BODY$
DECLARE
  resultado integer;
BEGIN
    SELECT edad(fecha_ingreso, _fecha) INTO resultado FROM personas WHERE id=id_persona;
    return resultado;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION public.antiguedad_dias(_id_persona integer, _fecha date default now())
  RETURNS integer AS
$BODY$
DECLARE
  resultado integer;
BEGIN    
    SELECT (EXTRACT(epoch from age(fecha_ingreso, _fecha)) / 86400)::int INTO resultado FROM personas WHERE id=_id_persona;
    return abs(resultado);
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE FUNCTION public.total_vacaciones(_id_persona integer, _fecha date default now())
  RETURNS integer AS
  /* DEvuelve el total de vacaciones en dias de acuerdo a la tabla de vacaciones*/
$BODY$
DECLARE
    _cant_dias integer;
    _antiguedad integer;
    _antiguedad_dias integer;
BEGIN
  SELECT antiguedad(_id_persona, _fecha) INTO _antiguedad;

  IF _antiguedad >= 1 THEN --busco en la tabla rangos por años
  
    SELECT dias into _cant_dias FROM tabla_vacaciones WHERE _antiguedad BETWEEN desde and hasta;
    
  ELSE       --busco en la tabla rangos por dias
  
    SELECT antiguedad_dias(_id_persona,_fecha) INTO _antiguedad_dias;
    SELECT dias into _cant_dias FROM tabla_vacaciones_dias WHERE _antiguedad_dias BETWEEN desde and hasta;
  END IF; 
  return _cant_dias;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

CREATE OR REPLACE FUNCTION public.fecha_hasta_liquidacion(id_liquidacion integer)
  RETURNS date AS
$BODY$
DECLARE 
  _fecha_hasta date;
BEGIN
  SELECT fecha_hasta INTO _fecha_hasta FROM liquidaciones WHERE id=id_liquidacion;
  return _fecha_hasta;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;
