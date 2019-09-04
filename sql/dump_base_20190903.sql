--
-- PostgreSQL database dump
--

-- Dumped from database version 9.5.19
-- Dumped by pg_dump version 9.5.19

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: asociacion; Type: DATABASE; Schema: -; Owner: -
--

CREATE DATABASE asociacion WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_AR.UTF-8' LC_CTYPE = 'es_AR.UTF-8';


\connect asociacion

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: sistema; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA sistema;


--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner: -
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: antiguedad(integer, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.antiguedad(id_persona integer, _fecha date DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	resultado integer;
BEGIN
    SELECT edad(fecha_ingreso, _fecha) INTO resultado FROM personas WHERE id=id_persona;
    return resultado;
END;
$$;


--
-- Name: antiguedad_dias(integer, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.antiguedad_dias(_id_persona integer, _fecha date DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	resultado integer;
BEGIN    
    SELECT (EXTRACT(epoch from age(fecha_ingreso, _fecha)) / 86400)::int INTO resultado FROM personas WHERE id=_id_persona;
    return abs(resultado);
END;
$$;


--
-- Name: dias_mes(date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.dias_mes(fecha date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    cant_dias integer;
BEGIN
	SELECT DATE_PART('days', DATE_TRUNC('month', fecha) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL ) into cant_dias;
	return cant_dias;
END;
$$;


--
-- Name: edad(date, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.edad(date, date DEFAULT NULL::date) RETURNS integer
    LANGUAGE plpgsql
    AS $_$
/* Calcula la edad exacta a la fecha ingresada a partir de la fecha nacimiento. Devuelve un entero. Evita el redondeo.  
$1 fecha de nacimiento 
$2 fecha a la cual se desea calcular la edad
*/

DECLARE
    fechanac alias for $1;
    fecha date;
    nacd integer;
    nacy integer;
    nacm integer;
    hoyd integer;
    hoym integer;
    hoyy integer;
    edad integer;
BEGIN
    IF($2 is null) THEN
  fecha:=now()::date;
    ELSE
  fecha:=$2;
    END IF;
    
    nacy:=date_part('year',fechanac); 
    nacm:=date_part('month',fechanac);
    nacd:=date_part('day',fechanac);
   
    hoyy:=date_part('year',fecha);
    hoym:=date_part('month',fecha);
    hoyd:=date_part('day',fecha);
    /* resta año actual con año nacimiento */
    edad:=hoyy-nacy;
    IF (nacm > hoym) THEN   
  edad:=edad-1;  /* ajusta edad (años no cumplidos) */
  RETURN edad;
    END IF;
    IF (nacm = hoym)THEN
        IF (nacd > hoyd)THEN
            edad:=edad-1; /* ajusta edad (años no cumplidos) */
      RETURN edad;
        END IF;
    END IF;
    RETURN edad;
END;
$_$;


--
-- Name: fecha_hasta_liquidacion(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fecha_hasta_liquidacion(id_liquidacion integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_fecha_hasta date;
BEGIN
	SELECT fecha_hasta INTO _fecha_hasta FROM liquidaciones WHERE id=id_liquidacion;
	return _fecha_hasta;
END;
$$;


--
-- Name: sp_grabar_historico_liquidacion(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_grabar_historico_liquidacion(_id_liquidacion integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
begin 
	--historico_liquidaciones
	INSERT INTO public.historico_liquidaciones(id, descripcion, periodo, fecha_desde, fecha_hasta, id_tipo_liquidacion, id_establecimiento, id_banco, fecha_pago, 
	periodo_depositado, lugar_pago, fecha_deposito, id_estado, mes, anio, nro_recibo_inicial, banco, estado, tipo_liquidacion, 
	establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad,
	id_tipo_empleador,tipo_empleador)
	select id,descripcion,periodo,fecha_desde,fecha_hasta,id_tipo_liquidacion,id_establecimiento,id_banco,fecha_pago,
	periodo_depositado,lugar_pago,fecha_deposito,id_estado,mes,anio,nro_recibo_inicial,banco, estado, tipo_liquidacion,
	establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad,
	id_tipo_empleador,tipo_empleador
	from v_liquidaciones l WHERE id=_id_liquidacion;

	--historico_liquidaciones_conceptos
	INSERT INTO public.historico_liquidaciones_conceptos(id, id_concepto, id_liquidacion, valor_fijo, concepto, codigo, formula, tipo_concepto)
	select lc.id, lc.id_concepto, lc.id_liquidacion, lc.valor_fijo, c.descripcion as concepto, codigo, formula, tipo_concepto 
	from liquidaciones_conceptos lc
	join v_conceptos c ON c.id=lc.id_concepto
	WHERE id_liquidacion=_id_liquidacion;

	--recibos
	INSERT INTO public.historico_recibos(id, nro_recibo, id_persona, total_remunerativos, total_no_remunerativos, total_deducciones, total_neto, total_basico, id_liquidacion, 
	apellido, nombre, legajo, tipo_documento, nro_documento, genero, id_estado_civil, estado_civil, fecha_nacimiento, edad, regimen, cuil, 
	id_categoria, categoria, tarea, sueldo_basico, 
	fecha_ingreso, fecha_egreso, id_tipo_contrato, tipo_contrato, id_obra_social, obra_social, codigo_obra_social, id_localidad, localidad, cp, 
	domicilio, id_nacionalidad, nacionalidad, pais, provincia)
	SELECT r.id, r.nro_recibo, r.id_persona, r.total_remunerativos, r.total_no_remunerativos, r.total_deducciones, r.total_neto, r.total_basico, r.id_liquidacion, 
	  p.apellido,p.nombre,p.legajo,p.tipo_documento,p.nro_documento,p.genero,p.id_estado_civil,p.estado_civil,p.fecha_nacimiento,edad(fecha_nacimiento),p.regimen,p.cuil,
	  p.id_categoria,p.categoria,(select string_agg(descripcion,',') from persona_tareas p1 join tareas t ON p1.id_tarea=t.id where p1.id_persona=p.id) as tarea,p.sueldo_basico,
	  p.fecha_ingreso,p.fecha_egreso,p.id_tipo_contrato,p.tipo_contrato,p.id_obra_social,p.obra_social,p.codigo_obra_social,p.id_localidad,p.localidad,p.cp,
	  p.domicilio,p.id_nacionalidad,p.nacionalidad,p.pais,p.provincia
	FROM recibos r     
	JOIN v_personas p ON p.id = r.id_persona
	WHERE id_liquidacion=_id_liquidacion;

	--recibos_acumuladores_historico
	INSERT INTO public.historico_recibos_acumuladores(id, id_acumulador, importe, id_recibo, nombre, descripcion, id_tipo_concepto, tipo_concepto)
	select ra.id, ra.id_acumulador, ra.importe, ra.id_recibo,nombre,descripcion,id_tipo_concepto,tipo_concepto 
	from recibos_acumuladores ra 
	join v_acumuladores a ON a.id=ra.id_acumulador
	WHERE id_recibo IN (SELECT id FROM recibos WHERE id_liquidacion=_id_liquidacion);

	
	--recibos_conceptos_historico
	INSERT INTO public.historico_recibos_conceptos(id, id_concepto, importe, id_recibo, concepto, codigo, formula, id_tipo_concepto, tipo_concepto, 
	mostrar_en_recibo, mostrar_si_cero, totaliza, valor_fijo, remunerativo, retencion)
	select rc.id, rc.id_concepto, rc.importe, rc.id_recibo,c.descripcion as concepto,c.codigo,c.formula,c.id_tipo_concepto,c.tipo_concepto,
	c.mostrar_en_recibo,c.mostrar_si_cero,totaliza,valor_fijo,remunerativo,retencion
	from recibos_conceptos rc 
	join v_conceptos c ON c.id=rc.id_concepto
	WHERE id_recibo IN (SELECT id FROM recibos WHERE id_liquidacion=_id_liquidacion);
END;
$$;


--
-- Name: sp_trg_ai_liquidaciones_conceptos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_trg_ai_liquidaciones_conceptos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE    
	_id_estado integer;
BEGIN	
	SELECT id_estado INTO _id_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
	IF _id_estado=1 THEN	--si el estado es PENDIENTE LIQUIDACION

		/* Inserto el nuevo concepto en todos los recibos*/
		INSERT INTO public.recibos_conceptos(id_concepto, importe, id_recibo)
		SELECT NEW.id_concepto, NEW.valor_fijo,r.id
		FROM recibos r 
		JOIN liquidaciones l ON l.id=r.id_liquidacion
		WHERE l.id=new.id_liquidacion;
		
	ELSE
		RAISE EXCEPTION 'NO SE PUEDE MODIFICAR UNA LIQUIDACION EN ESTADO %',_estado;
	END IF;
    
RETURN NEW;
END;
$$;


--
-- Name: sp_trg_ai_recibos(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_trg_ai_recibos() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE    
	_id_estado integer;
	_estado character varying(60);		--estado de la liquidacion
	_valor_fijo numeric(10,2);		--valor fijo para el concepto de una persona
	c record;				--record para guardar los registros de la liquidacion
BEGIN

	SELECT id_estado,estado INTO _id_estado,_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
	
	IF _id_estado=1 THEN	--si el estado es PENDIENTE LIQUIDACION

		/* Inserto los conceptos de la liquidacion.
		Si el concepto esta parametrizado para ciertas personas solo se cargan para esas personas */
		FOR c IN SELECT id_concepto, valor_fijo FROM liquidaciones_conceptos lc WHERE id_liquidacion = new.id_liquidacion 
		LOOP
			--Si el concepto esta parametrizado para ciertas personas, veo si esta esa persona, sino no se inserta el concepto			
			IF exists(SELECT 1 FROM conceptos_personas WHERE id_concepto=c.id_concepto) THEN

				INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo)				
				SELECT id_concepto, (CASE WHEN c.valor_fijo is NULL THEN valor_fijo ELSE c.valor_fijo END), new.id 
				FROM conceptos_personas 
				WHERE id_concepto=c.id_concepto AND id_persona=NEW.id_persona;
			
			ELSE
			--el concepto es para todas los empleados
				--si el concepto tiene un valor fijo definido en la Persona
				SELECT valor_fijo INTO _valor_fijo FROM personas_conceptos WHERE id_persona=new.id_persona AND id_concepto=c.id_concepto;
				IF(FOUND)THEN
					INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo)
					VALUES (c.id_concepto, _valor_fijo, NEW.id);
				ELSE
					INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo)
					VALUES (c.id_concepto, c.valor_fijo, NEW.id);
				END IF;
				
			END IF;
			
		END LOOP;       
			
	ELSE
		RAISE EXCEPTION 'NO SE PUEDE MODIFICAR UNA LIQUIDACION EN ESTADO %',_estado;
	END IF;
    
RETURN NEW;
END;
$$;


--
-- Name: sp_trg_au_liquidaciones(); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_trg_au_liquidaciones() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE    
	_nro_recibo integer;		
	r record;				--record para guardar los recibos de la liquidacion
BEGIN
	/*
	IF OLD.id_estado=1 AND NEW.id_estado=2 THEN
		_nro_recibo := NEW.nro_recibo_inicial;
		--Actualizo los nros de recibo 
		FOR r IN SELECT id FROM recibos WHERE id_liquidacion = new.id
		LOOP				
			UPDATE recibos SET nro_recibo=_nro_recibo WHERE id=r.id;
			_nro_recibo := _nro_recibo + 1;
		END LOOP;
	
	END IF;
	*/
	--PASA DE LIQUIDADA A CERRADA
	IF OLD.id_estado=2 AND NEW.id_estado=3 THEN

		--grabo el historico
		PERFORM sp_grabar_historico_liquidacion(NEW.id);
		
	END IF;    
RETURN NEW;
END;
$$;


--
-- Name: total_vacaciones(integer, date); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.total_vacaciones(_id_persona integer, _fecha date DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    _cant_dias integer;
    _antiguedad integer;
    _antiguedad_dias integer;
BEGIN
	SELECT antiguedad(_id_persona, _fecha) INTO _antiguedad;

	IF _antiguedad >= 1 THEN --busco en la tabla rangos por años
	
		SELECT dias into _cant_dias FROM tabla_vacaciones WHERE _antiguedad BETWEEN desde and hasta;
		
	ELSE			 --busco en la tabla rangos por dias
	
		SELECT antiguedad_dias(_id_persona,_fecha) INTO _antiguedad_dias;
		SELECT dias into _cant_dias FROM tabla_vacaciones_dias WHERE _antiguedad_dias BETWEEN desde and hasta;
	END IF;	
	return _cant_dias;
END;
$$;


SET default_with_oids = false;

--
-- Name: acumuladores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.acumuladores (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    descripcion text NOT NULL,
    id_tipo_concepto integer NOT NULL,
    remunerativo boolean DEFAULT false NOT NULL,
    valor_inicial numeric(10,2) DEFAULT 0 NOT NULL
);


--
-- Name: acumuladores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.acumuladores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: acumuladores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.acumuladores_id_seq OWNED BY public.acumuladores.id;


--
-- Name: bancos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.bancos (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: bancos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.bancos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: bancos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.bancos_id_seq OWNED BY public.bancos.id;


--
-- Name: categorias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.categorias (
    id integer NOT NULL,
    descripcion text NOT NULL,
    sueldo_basico numeric(10,2),
    valor_hora numeric(10,2),
    codigo text NOT NULL
);


--
-- Name: categorias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.categorias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: categorias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;


--
-- Name: conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conceptos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    codigo text NOT NULL,
    id_tipo_concepto integer NOT NULL,
    formula text,
    mostrar_en_recibo boolean DEFAULT false,
    totaliza boolean DEFAULT false,
    mostrar_si_cero boolean DEFAULT false NOT NULL,
    observaciones text,
    valor_fijo numeric(10,2),
    remunerativo boolean DEFAULT false NOT NULL,
    retencion boolean DEFAULT false NOT NULL
);


--
-- Name: conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.conceptos_id_seq OWNED BY public.conceptos.id;


--
-- Name: conceptos_personas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.conceptos_personas (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_persona integer NOT NULL,
    valor_fijo numeric(10,2)
);


--
-- Name: datos_actuales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datos_actuales (
    id integer NOT NULL,
    domicilio text NOT NULL,
    id_localidad integer,
    telefono_particular character varying(30),
    telefono_celular character varying(30),
    email character varying(100),
    id_estado_civil integer NOT NULL,
    id_persona integer NOT NULL
);


--
-- Name: datos_actuales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datos_actuales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datos_actuales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datos_actuales_id_seq OWNED BY public.datos_actuales.id;


--
-- Name: datos_laborales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datos_laborales (
    id integer NOT NULL,
    id_categoria integer,
    id_establecimiento integer,
    email_laboral character varying(255),
    id_persona integer NOT NULL,
    legajo integer NOT NULL,
    id_tipo_contrato integer NOT NULL,
    fecha_ingreso date,
    fecha_egreso date,
    hora_entrada time without time zone,
    hora_salida time without time zone
);


--
-- Name: datos_laborales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datos_laborales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datos_laborales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datos_laborales_id_seq OWNED BY public.datos_laborales.id;


--
-- Name: datos_salud; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.datos_salud (
    id integer NOT NULL,
    id_obra_social integer,
    observaciones_medicas character varying(255),
    id_persona integer NOT NULL
);


--
-- Name: datos_salud_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.datos_salud_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: datos_salud_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.datos_salud_id_seq OWNED BY public.datos_salud.id;


--
-- Name: establecimientos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.establecimientos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    direccion text NOT NULL,
    id_localidad integer NOT NULL,
    cuit text,
    actividad text,
    id_tipo_empleador integer
);


--
-- Name: establecimientos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.establecimientos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: establecimientos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.establecimientos_id_seq OWNED BY public.establecimientos.id;


--
-- Name: estados_civiles; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estados_civiles (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: estados_civiles_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estados_civiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estados_civiles_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estados_civiles_id_seq OWNED BY public.estados_civiles.id;


--
-- Name: estados_liquidacion; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.estados_liquidacion (
    id integer NOT NULL,
    descripcion character varying(60)
);


--
-- Name: estados_liquidacion_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.estados_liquidacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: estados_liquidacion_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.estados_liquidacion_id_seq OWNED BY public.estados_liquidacion.id;


--
-- Name: feriados; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.feriados (
    id integer NOT NULL,
    fecha date NOT NULL,
    descripcion text NOT NULL,
    hora_desde time without time zone,
    hora_hasta time without time zone
);


--
-- Name: feriados_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.feriados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: feriados_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.feriados_id_seq OWNED BY public.feriados.id;


--
-- Name: fichajes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.fichajes (
    id integer NOT NULL,
    fecha date NOT NULL,
    hora_entrada timestamp without time zone,
    hora_salida timestamp without time zone,
    horas_trabajadas numeric(10,2),
    horas_extras numeric(10,2),
    id_persona integer NOT NULL
);


--
-- Name: fichajes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.fichajes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fichajes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.fichajes_id_seq OWNED BY public.fichajes.id;


--
-- Name: generos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.generos (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: generos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.generos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: generos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.generos_id_seq OWNED BY public.generos.id;


--
-- Name: historico_liquidaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_liquidaciones (
    id integer NOT NULL,
    descripcion text NOT NULL,
    periodo date NOT NULL,
    fecha_desde date,
    fecha_hasta date,
    id_tipo_liquidacion integer NOT NULL,
    id_establecimiento integer DEFAULT 1 NOT NULL,
    id_banco integer NOT NULL,
    fecha_pago date NOT NULL,
    periodo_depositado character varying(10),
    lugar_pago text,
    fecha_deposito date,
    id_estado integer DEFAULT 1 NOT NULL,
    mes integer,
    anio integer,
    nro_recibo_inicial integer NOT NULL,
    banco text,
    estado text,
    tipo_liquidacion text,
    establecimiento text,
    direccion_establecimiento text,
    localidad_establecimiento text,
    cp_establecimiento text,
    provincia_establecimiento text,
    cuit text,
    actividad text,
    id_tipo_empleador integer,
    tipo_empleador text
);


--
-- Name: historico_liquidaciones_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_liquidaciones_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_liquidacion integer NOT NULL,
    valor_fijo numeric(10,2),
    concepto text,
    codigo text,
    formula text,
    tipo_concepto text
);


--
-- Name: historico_recibos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_recibos (
    id integer NOT NULL,
    nro_recibo integer,
    id_persona integer NOT NULL,
    total_remunerativos numeric(10,2),
    total_no_remunerativos numeric(10,2),
    total_deducciones numeric(10,2),
    total_neto numeric(10,2),
    total_basico numeric(10,2),
    id_liquidacion integer NOT NULL,
    apellido text,
    nombre text,
    legajo integer,
    tipo_documento text,
    nro_documento character varying(15),
    genero text,
    id_estado_civil integer,
    estado_civil text,
    fecha_nacimiento date,
    edad integer,
    regimen text,
    cuil text,
    id_categoria integer,
    categoria text,
    tarea text,
    sueldo_basico numeric(10,2),
    fecha_ingreso date,
    fecha_egreso date,
    id_tipo_contrato integer,
    tipo_contrato text,
    id_obra_social integer,
    obra_social text,
    codigo_obra_social text,
    id_localidad integer,
    localidad text,
    cp integer,
    domicilio text,
    id_nacionalidad integer,
    nacionalidad text,
    pais text,
    provincia text,
    id_establecimiento integer,
    establecimiento text
);


--
-- Name: historico_recibos_acumuladores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_recibos_acumuladores (
    id integer NOT NULL,
    id_acumulador integer NOT NULL,
    importe numeric(10,2) NOT NULL,
    id_recibo integer NOT NULL,
    nombre text,
    descripcion text,
    id_tipo_concepto integer,
    tipo_concepto text
);


--
-- Name: historico_recibos_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_recibos_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    importe numeric(10,2),
    id_recibo integer NOT NULL,
    concepto text,
    codigo text,
    formula text,
    id_tipo_concepto integer,
    tipo_concepto text,
    mostrar_en_recibo boolean,
    mostrar_si_cero boolean,
    totaliza boolean,
    valor_fijo numeric(10,2),
    remunerativo boolean,
    retencion boolean
);


--
-- Name: liquidaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.liquidaciones (
    id integer NOT NULL,
    descripcion text NOT NULL,
    periodo date NOT NULL,
    fecha_desde date,
    fecha_hasta date,
    id_tipo_liquidacion integer NOT NULL,
    id_establecimiento integer DEFAULT 1 NOT NULL,
    id_banco integer NOT NULL,
    fecha_pago date NOT NULL,
    periodo_depositado character varying(10),
    lugar_pago text,
    fecha_deposito date,
    id_estado integer DEFAULT 1 NOT NULL,
    mes integer,
    anio integer,
    nro_recibo_inicial integer NOT NULL
);


--
-- Name: liquidaciones_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.liquidaciones_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_liquidacion integer NOT NULL,
    valor_fijo numeric(10,2)
);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.liquidaciones_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.liquidaciones_conceptos_id_seq OWNED BY public.liquidaciones_conceptos.id;


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.liquidaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.liquidaciones_id_seq OWNED BY public.liquidaciones.id;


--
-- Name: localidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.localidades (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    cp integer NOT NULL,
    id_provincia integer NOT NULL
);


--
-- Name: localidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.localidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: localidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.localidades_id_seq OWNED BY public.localidades.id;


--
-- Name: nacionalidades; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.nacionalidades (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: nacionalidades_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.nacionalidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: nacionalidades_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.nacionalidades_id_seq OWNED BY public.nacionalidades.id;


--
-- Name: obras_sociales; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.obras_sociales (
    id integer NOT NULL,
    codigo text NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: obras_sociales_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.obras_sociales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: obras_sociales_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.obras_sociales_id_seq OWNED BY public.obras_sociales.id;


--
-- Name: paises; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.paises (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    nacionalidad character varying(60) NOT NULL
);


--
-- Name: paises_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.paises_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: paises_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.paises_id_seq OWNED BY public.paises.id;


--
-- Name: periodos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periodos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date NOT NULL,
    observaciones text
);


--
-- Name: periodos_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.periodos_detalle (
    id integer NOT NULL,
    id_persona integer NOT NULL,
    dias_trabajados numeric(10,2),
    horas_comunes numeric(10,2),
    horas_extras numeric(10,2),
    dias_vacaciones integer DEFAULT 0,
    id_periodo integer NOT NULL,
    inasistencias integer
);


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.periodos_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.periodos_detalle_id_seq OWNED BY public.periodos_detalle.id;


--
-- Name: periodos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.periodos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: periodos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.periodos_id_seq OWNED BY public.periodos.id;


--
-- Name: persona_tareas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.persona_tareas (
    id integer NOT NULL,
    id_persona integer NOT NULL,
    id_tarea integer NOT NULL
);


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.persona_tareas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.persona_tareas_id_seq OWNED BY public.persona_tareas.id;


--
-- Name: personas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personas (
    id integer NOT NULL,
    nombre character varying(100) NOT NULL,
    apellido character varying(100) NOT NULL,
    fecha_nacimiento date,
    id_tipo_documento integer NOT NULL,
    nro_documento character varying(15),
    id_genero integer NOT NULL,
    id_nacionalidad integer NOT NULL,
    activo boolean DEFAULT true NOT NULL,
    legajo integer NOT NULL,
    id_estado_civil integer NOT NULL,
    id_categoria integer NOT NULL,
    id_tipo_contrato integer NOT NULL,
    id_establecimiento integer NOT NULL,
    email text,
    fecha_ingreso date NOT NULL,
    fecha_egreso date,
    hora_entrada time without time zone NOT NULL,
    hora_salida time without time zone NOT NULL,
    id_localidad integer NOT NULL,
    domicilio text,
    piso character(2),
    departamento character(10),
    telefono_particular character varying(30),
    telefono_celular character varying(30),
    id_obra_social integer,
    cuil character varying(15) NOT NULL,
    horas_jornada numeric(10,2) NOT NULL,
    basico numeric(10,2),
    cant_hijos integer DEFAULT 0 NOT NULL,
    horas_mes numeric(10,2),
    id_regimen integer
);


--
-- Name: personas_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personas_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    valor_fijo numeric(10,2),
    id_persona integer NOT NULL
);


--
-- Name: personas_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personas_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personas_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personas_conceptos_id_seq OWNED BY public.personas_conceptos.id;


--
-- Name: personas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personas_id_seq OWNED BY public.personas.id;


--
-- Name: personas_jornadas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.personas_jornadas (
    id integer NOT NULL,
    hora_desde time without time zone NOT NULL,
    hora_hasta time without time zone NOT NULL,
    id_persona integer NOT NULL
);


--
-- Name: personas_jornadas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.personas_jornadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: personas_jornadas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.personas_jornadas_id_seq OWNED BY public.personas_jornadas.id;


--
-- Name: provincias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.provincias (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    id_pais integer NOT NULL
);


--
-- Name: provincias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.provincias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: provincias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.provincias_id_seq OWNED BY public.provincias.id;


--
-- Name: recibos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recibos (
    id integer NOT NULL,
    nro_recibo integer,
    id_persona integer NOT NULL,
    total_remunerativos numeric(10,2),
    total_no_remunerativos numeric(10,2),
    total_deducciones numeric(10,2),
    total_neto numeric(10,2),
    total_basico numeric(10,2),
    id_liquidacion integer NOT NULL,
    json_variables json
);


--
-- Name: recibos_acumuladores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recibos_acumuladores (
    id integer NOT NULL,
    id_acumulador integer NOT NULL,
    importe numeric(10,2) NOT NULL,
    id_recibo integer NOT NULL
);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recibos_acumuladores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recibos_acumuladores_id_seq OWNED BY public.recibos_acumuladores.id;


--
-- Name: recibos_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.recibos_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    importe numeric(10,2),
    id_recibo integer NOT NULL
);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recibos_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recibos_conceptos_id_seq OWNED BY public.recibos_conceptos.id;


--
-- Name: recibos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.recibos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: recibos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.recibos_id_seq OWNED BY public.recibos.id;


--
-- Name: regimenes; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.regimenes (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: regimenes_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.regimenes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: regimenes_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.regimenes_id_seq OWNED BY public.regimenes.id;


--
-- Name: tabla; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla (
    id integer NOT NULL,
    clave character varying(60) NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tabla_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_detalle (
    id integer NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    valor numeric(10,2) NOT NULL,
    tope numeric(10,2) NOT NULL,
    id_tabla integer NOT NULL
);


--
-- Name: tabla_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tabla_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tabla_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tabla_detalle_id_seq OWNED BY public.tabla_detalle.id;


--
-- Name: tabla_ganancias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_ganancias (
    id integer NOT NULL,
    anio integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tabla_ganancias_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_ganancias_detalle (
    id integer NOT NULL,
    mes integer NOT NULL,
    desde numeric(10,2) NOT NULL,
    hasta numeric(10,2),
    fijo numeric(10,2) NOT NULL,
    porcentaje numeric(10,2) NOT NULL,
    excedente numeric(10,2) NOT NULL,
    id_cabecera integer NOT NULL
);


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tabla_ganancias_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tabla_ganancias_detalle_id_seq OWNED BY public.tabla_ganancias_detalle.id;


--
-- Name: tabla_ganancias_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tabla_ganancias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tabla_ganancias_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tabla_ganancias_id_seq OWNED BY public.tabla_ganancias.id;


--
-- Name: tabla_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tabla_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tabla_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tabla_id_seq OWNED BY public.tabla.id;


--
-- Name: tabla_personas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_personas (
    id integer NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    valor numeric(10,2) NOT NULL,
    id_persona integer NOT NULL,
    id_tabla integer NOT NULL
);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tabla_personas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tabla_personas_id_seq OWNED BY public.tabla_personas.id;


--
-- Name: tabla_vacaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_vacaciones (
    id integer NOT NULL,
    desde numeric(10,2) NOT NULL,
    hasta numeric(10,2) NOT NULL,
    dias integer NOT NULL
);


--
-- Name: tabla_vacaciones_dias; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tabla_vacaciones_dias (
    id integer NOT NULL,
    desde integer NOT NULL,
    hasta integer NOT NULL,
    dias integer NOT NULL,
    descripcion text
);


--
-- Name: tareas; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tareas (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tareas_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tareas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tareas_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tareas_id_seq OWNED BY public.tareas.id;


--
-- Name: tipo_liquidacion_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipo_liquidacion_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_tipo_liquidacion integer NOT NULL
);


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipo_liquidacion_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipo_liquidacion_conceptos_id_seq OWNED BY public.tipo_liquidacion_conceptos.id;


--
-- Name: tipos_conceptos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_conceptos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    desde integer,
    hasta integer
);


--
-- Name: tipos_conceptos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_conceptos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_conceptos_id_seq OWNED BY public.tipos_conceptos.id;


--
-- Name: tipos_contratos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_contratos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    horas_mes numeric(10,2)
);


--
-- Name: tipos_contratos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_contratos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_contratos_id_seq OWNED BY public.tipos_contratos.id;


--
-- Name: tipos_documentos; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_documentos (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tipos_documentos_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_documentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_documentos_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_documentos_id_seq OWNED BY public.tipos_documentos.id;


--
-- Name: tipos_empleadores; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_empleadores (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tipos_empleadores_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_empleadores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_empleadores_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_empleadores_id_seq OWNED BY public.tipos_empleadores.id;


--
-- Name: tipos_liquidaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.tipos_liquidaciones (
    id integer NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);


--
-- Name: tipos_liquidaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.tipos_liquidaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_liquidaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.tipos_liquidaciones_id_seq OWNED BY public.tipos_liquidaciones.id;


--
-- Name: v_acumuladores; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_acumuladores AS
 SELECT a.id,
    a.nombre,
    a.descripcion,
    a.id_tipo_concepto,
    a.remunerativo,
    a.valor_inicial,
    tc.descripcion AS tipo_concepto
   FROM (public.acumuladores a
     LEFT JOIN public.tipos_conceptos tc ON ((a.id_tipo_concepto = tc.id)));


--
-- Name: v_conceptos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_conceptos AS
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
    ((('['::text || c.codigo) || '] '::text) || c.descripcion) AS descripcion_codigo,
    c.remunerativo,
    c.retencion
   FROM (public.conceptos c
     JOIN public.tipos_conceptos tc ON ((tc.id = c.id_tipo_concepto)));


--
-- Name: v_localidades; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_localidades AS
 SELECT l.id,
    l.nombre,
    l.cp,
    l.id_provincia,
    p.nombre AS provincia,
    p.id_pais,
    pa.nombre AS pais
   FROM ((public.localidades l
     JOIN public.provincias p ON ((p.id = l.id_provincia)))
     JOIN public.paises pa ON ((pa.id = p.id_pais)));


--
-- Name: v_establecimientos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_establecimientos AS
 SELECT e.id,
    e.descripcion,
    e.direccion,
    e.id_localidad,
    l.nombre AS localidad,
    l.cp,
    l.id_provincia,
    l.provincia,
    l.id_pais,
    e.cuit,
    e.actividad,
    e.id_tipo_empleador,
    te.descripcion AS tipo_empleador
   FROM ((public.establecimientos e
     LEFT JOIN public.v_localidades l ON ((e.id_localidad = l.id)))
     LEFT JOIN public.tipos_empleadores te ON ((te.id = e.id_tipo_empleador)));


--
-- Name: v_liquidaciones; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_liquidaciones AS
 SELECT l.id,
    l.id_estado,
    el.descripcion AS estado,
    l.descripcion,
    l.periodo,
    ((date_part('year'::text, l.periodo) || '-'::text) || date_part('month'::text, l.periodo)) AS periodo_descripcion,
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
    e.tipo_empleador
   FROM ((((public.liquidaciones l
     JOIN public.estados_liquidacion el ON ((el.id = l.id_estado)))
     JOIN public.tipos_liquidaciones tl ON ((tl.id = l.id_tipo_liquidacion)))
     JOIN public.v_establecimientos e ON ((e.id = l.id_establecimiento)))
     LEFT JOIN public.bancos b ON ((b.id = l.id_banco)));


--
-- Name: v_periodos_detalle; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_periodos_detalle AS
 SELECT pd.id,
    pd.id_persona,
    pd.dias_trabajados,
    pd.horas_comunes,
    pd.horas_extras,
    pd.inasistencias,
    pd.dias_vacaciones,
    pd.id_periodo,
    p.descripcion AS descripcion_periodo,
    p.anio,
    p.mes,
    p.periodo,
    p.fecha_desde,
    p.fecha_hasta
   FROM (public.periodos_detalle pd
     JOIN public.periodos p ON ((p.id = pd.id_periodo)));


--
-- Name: v_personas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_personas AS
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
    a.fecha_egreso,
    a.id_regimen,
    r.descripcion AS regimen
   FROM ((((((((((public.personas a
     LEFT JOIN public.estados_civiles ec ON ((ec.id = a.id_estado_civil)))
     LEFT JOIN public.categorias c ON ((c.id = a.id_categoria)))
     LEFT JOIN public.establecimientos es ON ((es.id = a.id_establecimiento)))
     LEFT JOIN public.obras_sociales os ON ((os.id = a.id_obra_social)))
     LEFT JOIN public.v_localidades loc ON ((loc.id = a.id_localidad)))
     LEFT JOIN public.nacionalidades n ON ((n.id = a.id_nacionalidad)))
     LEFT JOIN public.tipos_documentos td ON ((td.id = a.id_tipo_documento)))
     LEFT JOIN public.generos g ON ((g.id = a.id_genero)))
     LEFT JOIN public.tipos_contratos tc ON ((tc.id = a.id_tipo_contrato)))
     LEFT JOIN public.regimenes r ON ((r.id = a.id_regimen)));


--
-- Name: v_recibos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_recibos AS
 SELECT r.id,
    r.nro_recibo,
    r.id_persona,
    r.total_remunerativos,
    r.total_no_remunerativos,
    r.total_deducciones,
    r.total_neto,
    r.total_basico,
    r.id_liquidacion,
    (((((l.descripcion || '(Período '::text) || date_part('month'::text, l.periodo)) || '-'::text) || date_part('year'::text, l.periodo)) || ')'::text) AS descripcion_liquidacion,
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
   FROM ((public.recibos r
     JOIN public.liquidaciones l ON ((l.id = r.id_liquidacion)))
     JOIN public.v_personas p ON ((p.id = r.id_persona)));


--
-- Name: v_recibos_conceptos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_recibos_conceptos AS
 SELECT rc.id,
    rc.id_concepto,
    rc.importe,
    rc.id_recibo,
    c.descripcion AS concepto,
    c.codigo,
    ('c'::text || c.codigo) AS nombre_variable,
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
   FROM (((public.recibos_conceptos rc
     JOIN public.recibos r ON ((r.id = rc.id_recibo)))
     JOIN public.conceptos c ON ((c.id = rc.id_concepto)))
     JOIN public.liquidaciones l ON ((l.id = r.id_liquidacion)));


--
-- Name: v_recibos_conceptos_detallado; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_recibos_conceptos_detallado AS
 SELECT c.id,
    c.id_concepto,
    c.importe,
    c.id_recibo,
    c.concepto,
    c.codigo,
    c.nombre_variable,
    c.formula,
    c.mostrar_en_recibo,
    c.totaliza,
    c.id_tipo_concepto,
    c.nro_recibo,
    c.id_persona,
    c.id_liquidacion,
    c.mes,
    c.anio,
    c.periodo,
    c.liquidacion_descripcion,
    p.legajo,
    p.nombre,
    p.apellido,
    p.nro_documento,
    p.id_tipo_documento,
    p.tipo_documento,
    p.estado_civil,
    p.id_categoria,
    p.categoria,
    p.sueldo_basico,
    p.fecha_ingreso,
    p.fecha_egreso,
    p.cuil,
    p.id_establecimiento,
    p.establecimiento,
    tc.descripcion AS tipo_concepto
   FROM ((public.v_recibos_conceptos c
     JOIN public.v_personas p ON ((p.id = c.id_persona)))
     JOIN public.tipos_conceptos tc ON ((tc.id = c.id_tipo_concepto)));


--
-- Name: v_tabla_detalle; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_tabla_detalle AS
 SELECT td.id,
    td.anio,
    td.mes,
    td.periodo,
    td.valor,
    td.tope,
    td.id_tabla,
    t.descripcion AS tabla,
    t.clave
   FROM (public.tabla_detalle td
     JOIN public.tabla t ON ((t.id = td.id_tabla)));


--
-- Name: v_tabla_ganancias_detalle; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_tabla_ganancias_detalle AS
 SELECT d.id,
    d.mes,
    d.desde,
    d.hasta,
    d.fijo,
    d.porcentaje,
    d.excedente,
    d.id_cabecera,
    c.anio,
    c.descripcion,
    ((((c.anio || '-'::text) || d.mes) || '-01'::text))::date AS periodo
   FROM (public.tabla_ganancias c
     JOIN public.tabla_ganancias_detalle d ON ((c.id = d.id_cabecera)));


--
-- Name: v_tabla_personas; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_tabla_personas AS
 SELECT tp.id,
    tp.anio,
    tp.mes,
    tp.periodo,
    tp.valor,
    tp.id_persona,
    tp.id_tabla,
    t.descripcion AS tabla,
    t.clave,
    p.nombre,
    p.apellido,
    p.id_tipo_documento,
    p.nro_documento,
    p.legajo,
    ((((p.legajo || ' '::text) || (p.apellido)::text) || ' '::text) || (p.nombre)::text) AS persona_descripcion,
    ((tp.anio || '-'::text) || tp.mes) AS periodo_descripcion
   FROM ((public.tabla_personas tp
     JOIN public.tabla t ON ((t.id = tp.id_tabla)))
     JOIN public.personas p ON ((p.id = tp.id_persona)));


--
-- Name: v_tipo_liquidacion_conceptos; Type: VIEW; Schema: public; Owner: -
--

CREATE VIEW public.v_tipo_liquidacion_conceptos AS
 SELECT tlc.id,
    tlc.id_concepto,
    tlc.id_tipo_liquidacion,
    ((('['::text || c.codigo) || '] '::text) || c.descripcion) AS concepto,
    tl.descripcion AS tipo_liquidacion,
    c.codigo,
    c.valor_fijo,
    c.id_tipo_concepto,
    tc.descripcion AS tipo_concepto
   FROM (((public.tipo_liquidacion_conceptos tlc
     JOIN public.conceptos c ON ((c.id = tlc.id_concepto)))
     JOIN public.tipos_liquidaciones tl ON ((tl.id = tlc.id_tipo_liquidacion)))
     JOIN public.tipos_conceptos tc ON ((tc.id = c.id_tipo_concepto)));


--
-- Name: vacaciones; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.vacaciones (
    id integer NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date NOT NULL,
    observaciones text,
    id_persona integer NOT NULL
);


--
-- Name: vacaciones_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.vacaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: vacaciones_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.vacaciones_id_seq OWNED BY public.vacaciones.id;


--
-- Name: reservadas; Type: TABLE; Schema: sistema; Owner: -
--

CREATE TABLE sistema.reservadas (
    id integer NOT NULL,
    nombre text NOT NULL,
    descripcion text NOT NULL,
    descripcion_larga text,
    query text,
    valor_fijo text,
    id_tipo_reservada integer NOT NULL,
    id_tipo_dato integer,
    defecto text
);


--
-- Name: reservadas_id_seq; Type: SEQUENCE; Schema: sistema; Owner: -
--

CREATE SEQUENCE sistema.reservadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: reservadas_id_seq; Type: SEQUENCE OWNED BY; Schema: sistema; Owner: -
--

ALTER SEQUENCE sistema.reservadas_id_seq OWNED BY sistema.reservadas.id;


--
-- Name: tipos_datos; Type: TABLE; Schema: sistema; Owner: -
--

CREATE TABLE sistema.tipos_datos (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tipos_datos_id_seq; Type: SEQUENCE; Schema: sistema; Owner: -
--

CREATE SEQUENCE sistema.tipos_datos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_datos_id_seq; Type: SEQUENCE OWNED BY; Schema: sistema; Owner: -
--

ALTER SEQUENCE sistema.tipos_datos_id_seq OWNED BY sistema.tipos_datos.id;


--
-- Name: tipos_reservadas; Type: TABLE; Schema: sistema; Owner: -
--

CREATE TABLE sistema.tipos_reservadas (
    id integer NOT NULL,
    descripcion text NOT NULL
);


--
-- Name: tipos_reservadas_id_seq; Type: SEQUENCE; Schema: sistema; Owner: -
--

CREATE SEQUENCE sistema.tipos_reservadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: tipos_reservadas_id_seq; Type: SEQUENCE OWNED BY; Schema: sistema; Owner: -
--

ALTER SEQUENCE sistema.tipos_reservadas_id_seq OWNED BY sistema.tipos_reservadas.id;


--
-- Name: v_reservadas; Type: VIEW; Schema: sistema; Owner: -
--

CREATE VIEW sistema.v_reservadas AS
 SELECT r.id,
    r.nombre,
    r.descripcion,
    r.descripcion_larga,
    r.query,
    r.valor_fijo,
    r.id_tipo_reservada,
    r.id_tipo_dato,
    tr.descripcion AS tipo_reservada,
    td.descripcion AS tipo_dato,
    r.defecto
   FROM ((sistema.reservadas r
     LEFT JOIN sistema.tipos_reservadas tr ON ((tr.id = r.id_tipo_reservada)))
     LEFT JOIN sistema.tipos_datos td ON ((td.id = r.id_tipo_dato)));


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores ALTER COLUMN id SET DEFAULT nextval('public.acumuladores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bancos ALTER COLUMN id SET DEFAULT nextval('public.bancos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos ALTER COLUMN id SET DEFAULT nextval('public.conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales ALTER COLUMN id SET DEFAULT nextval('public.datos_actuales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales ALTER COLUMN id SET DEFAULT nextval('public.datos_laborales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud ALTER COLUMN id SET DEFAULT nextval('public.datos_salud_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos ALTER COLUMN id SET DEFAULT nextval('public.establecimientos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_civiles ALTER COLUMN id SET DEFAULT nextval('public.estados_civiles_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion ALTER COLUMN id SET DEFAULT nextval('public.estados_liquidacion_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feriados ALTER COLUMN id SET DEFAULT nextval('public.feriados_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes ALTER COLUMN id SET DEFAULT nextval('public.fichajes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generos ALTER COLUMN id SET DEFAULT nextval('public.generos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades ALTER COLUMN id SET DEFAULT nextval('public.localidades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nacionalidades ALTER COLUMN id SET DEFAULT nextval('public.nacionalidades_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obras_sociales ALTER COLUMN id SET DEFAULT nextval('public.obras_sociales_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paises ALTER COLUMN id SET DEFAULT nextval('public.paises_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos ALTER COLUMN id SET DEFAULT nextval('public.periodos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle ALTER COLUMN id SET DEFAULT nextval('public.periodos_detalle_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas ALTER COLUMN id SET DEFAULT nextval('public.persona_tareas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas ALTER COLUMN id SET DEFAULT nextval('public.personas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos ALTER COLUMN id SET DEFAULT nextval('public.personas_conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas ALTER COLUMN id SET DEFAULT nextval('public.personas_jornadas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias ALTER COLUMN id SET DEFAULT nextval('public.provincias_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos ALTER COLUMN id SET DEFAULT nextval('public.recibos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores ALTER COLUMN id SET DEFAULT nextval('public.recibos_acumuladores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.recibos_conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regimenes ALTER COLUMN id SET DEFAULT nextval('public.regimenes_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla ALTER COLUMN id SET DEFAULT nextval('public.tabla_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_detalle_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_detalle_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas ALTER COLUMN id SET DEFAULT nextval('public.tabla_personas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas ALTER COLUMN id SET DEFAULT nextval('public.tareas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipo_liquidacion_conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipos_conceptos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_contratos ALTER COLUMN id SET DEFAULT nextval('public.tipos_contratos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documentos ALTER COLUMN id SET DEFAULT nextval('public.tipos_documentos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_empleadores ALTER COLUMN id SET DEFAULT nextval('public.tipos_empleadores_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.tipos_liquidaciones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones ALTER COLUMN id SET DEFAULT nextval('public.vacaciones_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas ALTER COLUMN id SET DEFAULT nextval('sistema.reservadas_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_datos ALTER COLUMN id SET DEFAULT nextval('sistema.tipos_datos_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_reservadas ALTER COLUMN id SET DEFAULT nextval('sistema.tipos_reservadas_id_seq'::regclass);


--
-- Data for Name: acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.acumuladores VALUES (1, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, true, 0.00);
INSERT INTO public.acumuladores VALUES (2, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, false, 0.00);
INSERT INTO public.acumuladores VALUES (3, 'bruto', 'Sueldo Bruto', 1, true, 0.00);
INSERT INTO public.acumuladores VALUES (4, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, false, 0.00);
INSERT INTO public.acumuladores VALUES (5, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, false, 0.00);


--
-- Name: acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.acumuladores_id_seq', 5, true);


--
-- Data for Name: bancos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.bancos VALUES (1, 'Galicia');


--
-- Name: bancos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bancos_id_seq', 1, true);


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categorias VALUES (1, '1RA.SUPERV', 50000.00, NULL, '1');
INSERT INTO public.categorias VALUES (2, '2DA.SUPERV', 40000.00, NULL, '2');
INSERT INTO public.categorias VALUES (3, '1RA.ADM', 60000.00, NULL, '3');
INSERT INTO public.categorias VALUES (4, '2DA.ADM', 50000.00, NULL, '4');
INSERT INTO public.categorias VALUES (5, 'Maestranza', 35000.00, NULL, '5');


--
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categorias_id_seq', 5, false);


--
-- Data for Name: conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.conceptos VALUES (4, 'Idem Sueldo Basico', '90', 1, 'c1', false, false, false, 'Ver si se utiliza el concepto nro 1 directamente', NULL, false, false);
INSERT INTO public.conceptos VALUES (8, 'Jubilacion', '500', 2, 'bruto * 0.11', true, true, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (9, 'INNSJP-LEY 1903', '501', 2, 'bruto * 0.03', true, true, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (10, 'Obra Social', '502', 2, 'bruto * 0.03', true, true, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (11, 'Cuota solidaria Utedyc', '511', 2, 'bruto * 0.25', true, true, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (1, 'Sueldo Básico', '1', 1, 'basico', true, true, true, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (7, 'Horas Extras 100%', '3', 1, '( c1 / 200 ) * 1.5 *  hsextras', true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (12, 'Presentismo', '10', 1, 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (5, 'Años Reconocimiento', '101', 1, '0', false, false, false, 'La formula tiene valor 0. Este valor sera el devuelto si no tiene un valor fijo para la persona.
En el sistema anterior es el concepto #700 pero aca hay que calcularlo antes de calcular la antiguedad que es el concepto #102', NULL, false, false);
INSERT INTO public.conceptos VALUES (6, 'Antiguedad', '102', 1, 'c90 * ( antiguedad + c101 ) * 0.02', true, true, false, 'Ver si se puede cambiar a :
c1 * ( antiguedad + c101 ) * 0.02', NULL, true, true);
INSERT INTO public.conceptos VALUES (22, 'Ganancia Neta Mensual', '321', 4, 'c309-c320', false, false, false, 'Total de remuneracion bruta
-Total de Retenciones', NULL, false, false);
INSERT INTO public.conceptos VALUES (17, 'Retenciones - Jubilación', '310', 4, 'c309 * 0.11', false, false, false, 'Ver que el valor no es el mismo que se muestra en el recibo', NULL, false, false);
INSERT INTO public.conceptos VALUES (18, 'Retenciones - Obra Social', '311', 4, 'c309 * 0.03', false, false, false, 'Total de Rem Bruta * 0.03', NULL, false, false);
INSERT INTO public.conceptos VALUES (19, 'Retenciones - INNSJP', '312', 4, 'c309 * 0.03', false, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (20, 'Retenciones - Cuota Solidaridad', '313', 4, 'c309 * 0.025', false, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (21, 'Retenciones - Total Retenciones', '320', 4, 'c310 + c311 + c312 + c313', false, false, false, 'Jubilacion + obra_social +
INNSJP + Cuota Solidaridad', NULL, false, false);
INSERT INTO public.conceptos VALUES (14, 'Ganancias - Gratificaciones', '302', 4, '0', false, false, false, 'Concepto que se para calcular el total de la remuneracion bruta', 0.00, false, false);
INSERT INTO public.conceptos VALUES (16, 'Ganancias - SAC', '303', 4, '0', false, false, false, NULL, 0.00, false, false);
INSERT INTO public.conceptos VALUES (15, 'Ganancias - tot_rem_bruta', '309', 4, 'bruto +  c301 + c302 + c303', false, false, false, 'Suma el bruto + el SAC devengado + Gratificaciones + SAC??', NULL, false, false);
INSERT INTO public.conceptos VALUES (31, 'Deducciones. Prepaga', '337', 4, 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', false, false, false, 'c323 : 5%del sueldo neto', NULL, false, false);
INSERT INTO public.conceptos VALUES (37, 'Total Deducciones', '350', 4, 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', false, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (29, 'Deducciones. Cargas de familia', '333', 4, '0', false, false, false, 'Hay que ver si se usa', 0.00, false, false);
INSERT INTO public.conceptos VALUES (30, 'Deducciones. Servicio doméstico', '336', 4, '0', false, false, false, 'Ver si se usa', 0.00, false, false);
INSERT INTO public.conceptos VALUES (23, 'Ganancia Neta Acumulada', '322', 4, 'c321 + ganancia_neta_acumulada', false, false, false, 'nada', NULL, false, false);
INSERT INTO public.conceptos VALUES (32, 'Prepaga (5% del sueldo neto)', '323', 4, 'c322 * 0.05', false, false, false, 'Calculo auxiliar. 
No uso ganancia_neta_acumulada por que no tiene el mes actual.
NO!! ganancia_neta_acumulada*0.05', NULL, false, false);
INSERT INTO public.conceptos VALUES (38, 'Ganancia neta imponible', '360', 4, 'c322 - c350', false, false, false, 'Ganancia Neta Acumulada - Total Deducciones = c322 - c350', NULL, false, false);
INSERT INTO public.conceptos VALUES (25, 'Deduccion. Conyuge', '331', 4, 'si( casado , tabla("conyuge") , 0 )', false, false, false, 'SI es casado busca el valor en la tabla de conyuge en el periodo de la liquidacion SINO devuelve 0', NULL, false, false);
INSERT INTO public.conceptos VALUES (26, 'Deducciones. Hijos', '332', 4, 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', false, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (27, 'Deducciones. Ganancia no imponible', '334', 4, 'tabla("ganancia")', false, false, false, 'Trae el valor de la tabla de ganancia no imponibles para el periodo de la liquidacion', NULL, false, false);
INSERT INTO public.conceptos VALUES (28, 'Deducciones. Intereses créditos hipotecarios', '335', 4, 'informado("hipoteca")', false, false, false, 'Trae el valor informado por el empleado', NULL, false, false);
INSERT INTO public.conceptos VALUES (13, 'Ganancias - SAC Devengado', '301', 4, 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', false, false, false, 'Se usa solo para calculos.
Si se esta calculando aguinaldo calculo la diferencia entre el sac y el total devengado a mayo ó noviembre.', NULL, false, false);
INSERT INTO public.conceptos VALUES (40, 'Ganancia Escala', '370', 4, 'ganancias(c360)', false, false, false, 'Realiza el calculo final de ganancia Mensual.
Le pasa a la funcion ganancia() el valor de la "Ganancia neta imponible"(c360).', NULL, false, false);
INSERT INTO public.conceptos VALUES (41, 'S.A.C', '161', 1, 'maxsueldo / 2', true, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (39, 'IMPUESTO A LAS GANANCIAS', '515', 2, 'c370 - ganancia_acumulada', false, false, false, 'c370: Valor Final del calculo de ganancia mensual - el acumulado del año hasta el periodo de la liquidacion', NULL, false, false);
INSERT INTO public.conceptos VALUES (24, 'Deducción. Especial', '330', 4, 'tabla("especial")', false, false, false, 'Busca el valor en la tabla de deducciones especiales en el periodo de la liquidación', NULL, false, false);
INSERT INTO public.conceptos VALUES (34, 'Deducciones. Seguro de Vida', '339', 4, 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', false, false, false, 'Deducciones de seguro de vida
Si el valor informado=0 entonces 0 
Sino  Si el valor informado es <= tope entonces valor informado sino tope', NULL, false, false);
INSERT INTO public.conceptos VALUES (33, 'Deducciones. Gastos Médicos', '338', 4, 'informado("medico")', false, false, false, 'Busca el valor informado por el empleado en el periodo de la liquidación', NULL, false, false);
INSERT INTO public.conceptos VALUES (35, 'Deducciones. Donaciones', '340', 4, 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', false, false, false, 'Si el valor informado=0 entonces 0 
Sino  Si el valor informado es <= tope entonces valor informado sino tope', NULL, false, false);
INSERT INTO public.conceptos VALUES (36, 'Deducciones. Alquileres', '341', 4, 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', false, false, false, 'Si el valor informado=0 entonces 0 
Sino  Si el valor informado es <= tope entonces valor informado sino tope', NULL, false, false);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 41, true);


--
-- Data for Name: conceptos_personas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: datos_actuales; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: datos_actuales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_actuales_id_seq', 1, true);


--
-- Data for Name: datos_laborales; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: datos_laborales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_laborales_id_seq', 1, true);


--
-- Data for Name: datos_salud; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: datos_salud_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_salud_id_seq', 1, true);


--
-- Data for Name: establecimientos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.establecimientos VALUES (1, 'Asociación Médica de Luján', 'Mariano Moreno 1460', 1, '33539819769', '911200', 1);


--
-- Name: establecimientos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.establecimientos_id_seq', 1, false);


--
-- Data for Name: estados_civiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.estados_civiles VALUES (1, 'Soltero/a');
INSERT INTO public.estados_civiles VALUES (2, 'Casado/a');
INSERT INTO public.estados_civiles VALUES (3, 'Divorciado/a');


--
-- Name: estados_civiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estados_civiles_id_seq', 1, false);


--
-- Data for Name: estados_liquidacion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.estados_liquidacion VALUES (1, 'PENDIENTE LIQUIDACION');
INSERT INTO public.estados_liquidacion VALUES (2, 'LIQUIDADA');
INSERT INTO public.estados_liquidacion VALUES (3, 'CERRADA');


--
-- Name: estados_liquidacion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estados_liquidacion_id_seq', 1, false);


--
-- Data for Name: feriados; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: feriados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.feriados_id_seq', 1, false);


--
-- Data for Name: fichajes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: fichajes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fichajes_id_seq', 1, false);


--
-- Data for Name: generos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.generos VALUES (1, 'Masculino');
INSERT INTO public.generos VALUES (2, 'Femenino');


--
-- Name: generos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.generos_id_seq', 1, false);


--
-- Data for Name: historico_liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_liquidaciones VALUES (86, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 3, 1, 2019, 1, 'Galicia', 'CERRADA', 'Liquidación Mensual Normal', 'Asociación Médica de Luján', 'Mariano Moreno 1460', 'LUJAN', '3450', 'Corrientes', '33539819769', '911200', 1, 'Dec 814/01, art. 2, inc. B');


--
-- Data for Name: historico_liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_liquidaciones_conceptos VALUES (1757, 1, 86, NULL, 'Sueldo Básico', '1', 'basico', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1760, 4, 86, NULL, 'Idem Sueldo Basico', '90', 'c1', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1761, 5, 86, NULL, 'Años Reconocimiento', '101', '0', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1762, 6, 86, NULL, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1758, 7, 86, NULL, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1790, 9, 86, NULL, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1791, 10, 86, NULL, 'Obra Social', '502', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1792, 11, 86, NULL, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1759, 12, 86, NULL, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1763, 13, 86, NULL, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1764, 14, 86, 0.00, 'Ganancias - Gratificaciones', '302', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1766, 15, 86, NULL, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1765, 16, 86, 0.00, 'Ganancias - SAC', '303', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1767, 17, 86, NULL, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1768, 18, 86, NULL, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1769, 19, 86, NULL, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1770, 20, 86, NULL, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1771, 21, 86, NULL, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1772, 22, 86, NULL, 'Ganancia Neta Mensual', '321', 'c309-c320', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1773, 23, 86, NULL, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1775, 24, 86, NULL, 'Deducción. Especial', '330', 'tabla("especial")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1776, 25, 86, NULL, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1777, 26, 86, NULL, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1779, 27, 86, NULL, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1780, 28, 86, NULL, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1778, 29, 86, 0.00, 'Deducciones. Cargas de familia', '333', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1781, 30, 86, 0.00, 'Deducciones. Servicio doméstico', '336', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1782, 31, 86, NULL, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1774, 32, 86, NULL, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1783, 33, 86, NULL, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1784, 34, 86, NULL, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1785, 35, 86, NULL, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1786, 36, 86, NULL, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1787, 37, 86, NULL, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1788, 38, 86, NULL, 'Ganancia neta imponible', '360', 'c322 - c350', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1793, 39, 86, NULL, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1789, 40, 86, NULL, 'Ganancia Escala', '370', 'ganancias(c360)', 'CALCULO GANANCIAS');


--
-- Data for Name: historico_recibos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos VALUES (1316, 1, 7, 39080.00, 0.00, 12114.80, NULL, NULL, 86, 'Zeppa', 'Silvio', 40, 'DNI', '26563056', 'Masculino', 2, 'Casado/a', '1978-05-20', 41, NULL, '20265630562', 4, '2DA.ADM', NULL, 50000.00, '2017-04-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1297, 2, 8, 42595.49, 0.00, 13204.60, NULL, NULL, 86, 'Acosta', 'Claudio Daniel', 29, 'DNI', '26823601', 'Masculino', 2, 'Casado/a', '1978-07-18', 41, 'Sipa', '20268236016', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2011-04-06', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, 'Mariano Moreno 1460', 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1298, 3, 9, 49210.57, 0.00, 15255.28, NULL, NULL, 86, 'Becaj', 'Ivan Guillermo', 31, 'DNI', '26583833', 'Masculino', 1, 'Soltero/a', '1978-05-01', 41, NULL, '20265838333', 2, '2DA.SUPERV', NULL, 40000.00, '2013-06-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1299, 4, 10, 79572.58, 0.00, 24667.50, NULL, NULL, 86, 'Cano', 'Silvia Marina', 5, 'DNI', '14490100', 'Femenino', 2, 'Casado/a', '1960-12-22', 58, NULL, '27144901008', 2, '2DA.SUPERV', NULL, 40000.00, '1988-12-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1300, 5, 11, 30317.40, 0.00, 9398.39, NULL, NULL, 86, 'Cespedes Ramirez', 'Teresita', 8, 'DNI', '92727141', 'Femenino', 3, 'Divorciado/a', '1965-05-20', 54, NULL, '27927271414', 5, 'Maestranza', NULL, 35000.00, '2010-03-01', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1301, 6, 12, 41567.27, 0.00, 12885.85, NULL, NULL, 86, 'Dandrilli', 'Gisela Elizabeth', 34, 'DNI', '30939944', 'Femenino', 2, 'Casado/a', '1984-08-04', 35, NULL, '27309399442', 4, '2DA.ADM', NULL, 50000.00, '2014-02-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1302, 7, 13, 84533.20, 0.00, 26205.29, NULL, NULL, 86, 'Delgado', 'Noemi Severa', 7, 'DNI', '12904169', 'Femenino', 2, 'Casado/a', '1956-10-27', 62, NULL, '27129041698', 2, '2DA.SUPERV', NULL, 40000.00, '1986-07-14', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1303, 8, 14, 20010.00, 0.00, 6203.10, NULL, NULL, 86, 'Echenique', 'Cesar Anibal', 37, 'DNI', '27113644', 'Masculino', 1, 'Soltero/a', '1978-12-24', 40, NULL, '20271136448', 3, '1RA.ADM', NULL, 60000.00, '2015-06-01', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1304, 9, 15, 78000.00, 0.00, 24180.00, NULL, NULL, 86, 'Ferrari', 'Maria Cecilia', 26, 'DNI', '29594863', 'Femenino', 1, 'Soltero/a', '1982-07-25', 37, NULL, '27295948634', 3, '1RA.ADM', NULL, 60000.00, '2008-02-20', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1305, 10, 16, 42039.72, 0.00, 13032.31, NULL, NULL, 86, 'Ferreyra', 'Rodrigo Raul', 32, 'DNI', '34831908', 'Masculino', 1, 'Soltero/a', '1989-10-10', 29, NULL, '20348319087', 4, '2DA.ADM', NULL, 50000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1306, 11, 17, 65574.74, 0.00, 20328.17, NULL, NULL, 86, 'Frascaroli', 'Micaela Noemi', 19, 'DNI', '29233345', 'Femenino', 1, 'Soltero/a', '1982-02-27', 37, NULL, '27292333450', 2, '2DA.SUPERV', NULL, 40000.00, '2003-10-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1307, 12, 18, 57173.51, 0.00, 17723.79, NULL, NULL, 86, 'Gallesio', 'Betiana Nazareth', 21, 'DNI', '26167199', 'Femenino', 1, 'Soltero/a', '1978-01-04', 41, NULL, '27261671994', 2, '2DA.SUPERV', NULL, 40000.00, '2006-11-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1308, 13, 19, 77302.08, 0.00, 23963.64, NULL, NULL, 86, 'Herrera', 'Claudia Fabiana', 10, 'DNI', '16833436', 'Femenino', 2, 'Casado/a', '1965-04-28', 54, 'Sipa', '27168334368', 3, '1RA.ADM', 'ay.sub area', 60000.00, '1984-08-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1309, 14, 20, 54678.40, 0.00, 16950.30, NULL, NULL, 86, 'Lombardo', 'Norma Elizabeth', 27, 'DNI', '14097779', 'Femenino', 2, 'Casado/a', '1960-11-25', 58, NULL, '27140977794', 2, '2DA.SUPERV', NULL, 40000.00, '2009-08-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1310, 15, 21, 45027.03, 0.00, 13958.38, NULL, NULL, 86, 'Paccor', 'Maria Soledad', 35, 'DNI', '27033687', 'Femenino', 1, 'Soltero/a', '1979-03-05', 40, NULL, '27270336871', 3, '1RA.ADM', NULL, 60000.00, '2014-11-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1311, 16, 22, 17971.76, 0.00, 5571.24, NULL, NULL, 86, 'Paris', 'Alejandra', 39, 'DNI', '30939775', 'Femenino', 1, 'Soltero/a', '1984-05-06', 35, NULL, '23309397754', 3, '1RA.ADM', NULL, 60000.00, '2016-07-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1312, 17, 23, 51617.28, 0.00, 16001.36, NULL, NULL, 86, 'Parra', 'Jorgelina', 23, 'DNI', '25048843', 'Femenino', 1, 'Soltero/a', '1976-05-11', 43, NULL, '27250488438', 3, '1RA.ADM', NULL, 60000.00, '2007-07-02', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1313, 18, 24, 79950.39, 0.00, 24784.62, NULL, NULL, 86, 'Poletti', 'Norma', 2, 'DNI', '18601061', 'Femenino', 2, 'Casado/a', '1967-11-07', 51, NULL, '27186010618', 2, '2DA.SUPERV', NULL, 40000.00, '1986-09-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1314, 19, 25, 41950.56, 0.00, 13004.67, NULL, NULL, 86, 'Riccardo', 'Lautaro', 33, 'DNI', '32378152', 'Masculino', 1, 'Soltero/a', '1986-05-29', 33, NULL, '20323781525', 3, '1RA.ADM', NULL, 60000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);
INSERT INTO public.historico_recibos VALUES (1315, 20, 26, 99287.36, 0.00, 30779.08, NULL, NULL, 86, 'Romero', 'Ana Gladys', 3, 'DNI', '18148598', 'Femenino', 3, 'Divorciado/a', '1966-05-04', 53, NULL, '27181485987', 1, '1RA.SUPERV', NULL, 50000.00, '1986-11-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', NULL, NULL);


--
-- Data for Name: historico_recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_acumuladores VALUES (5161, 1, 39080.00, 1316, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5162, 2, 0.00, 1316, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5163, 3, 39080.00, 1316, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5164, 4, 0.00, 1316, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5165, 5, 12114.80, 1316, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5166, 1, 42595.49, 1297, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5167, 2, 0.00, 1297, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5168, 3, 42595.49, 1297, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5169, 4, 0.00, 1297, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5170, 5, 13204.60, 1297, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5171, 1, 49210.57, 1298, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5172, 2, 0.00, 1298, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5173, 3, 49210.57, 1298, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5174, 4, 0.00, 1298, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5175, 5, 15255.28, 1298, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5176, 1, 79572.58, 1299, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5177, 2, 0.00, 1299, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5178, 3, 79572.58, 1299, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5179, 4, 0.00, 1299, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5180, 5, 24667.50, 1299, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5181, 1, 30317.40, 1300, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5182, 2, 0.00, 1300, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5183, 3, 30317.40, 1300, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5184, 4, 0.00, 1300, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5185, 5, 9398.39, 1300, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5186, 1, 41567.27, 1301, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5187, 2, 0.00, 1301, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5188, 3, 41567.27, 1301, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5189, 4, 0.00, 1301, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5190, 5, 12885.85, 1301, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5191, 1, 84533.20, 1302, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5192, 2, 0.00, 1302, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5193, 3, 84533.20, 1302, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5194, 4, 0.00, 1302, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5195, 5, 26205.29, 1302, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5196, 1, 20010.00, 1303, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5197, 2, 0.00, 1303, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5198, 3, 20010.00, 1303, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5199, 4, 0.00, 1303, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5200, 5, 6203.10, 1303, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5201, 1, 78000.00, 1304, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5202, 2, 0.00, 1304, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5203, 3, 78000.00, 1304, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5204, 4, 0.00, 1304, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5205, 5, 24180.00, 1304, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5206, 1, 42039.72, 1305, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5207, 2, 0.00, 1305, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5208, 3, 42039.72, 1305, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5209, 4, 0.00, 1305, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5210, 5, 13032.31, 1305, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5211, 1, 65574.74, 1306, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5212, 2, 0.00, 1306, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5213, 3, 65574.74, 1306, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5214, 4, 0.00, 1306, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5215, 5, 20328.17, 1306, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5216, 1, 57173.51, 1307, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5217, 2, 0.00, 1307, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5218, 3, 57173.51, 1307, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5219, 4, 0.00, 1307, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5220, 5, 17723.79, 1307, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5221, 1, 77302.08, 1308, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5222, 2, 0.00, 1308, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5223, 3, 77302.08, 1308, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5224, 4, 0.00, 1308, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5225, 5, 23963.64, 1308, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5226, 1, 54678.40, 1309, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5227, 2, 0.00, 1309, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5228, 3, 54678.40, 1309, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5229, 4, 0.00, 1309, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5230, 5, 16950.30, 1309, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5231, 1, 45027.03, 1310, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5232, 2, 0.00, 1310, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5233, 3, 45027.03, 1310, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5234, 4, 0.00, 1310, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5235, 5, 13958.38, 1310, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5236, 1, 17971.76, 1311, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5237, 2, 0.00, 1311, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5238, 3, 17971.76, 1311, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5239, 4, 0.00, 1311, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5240, 5, 5571.24, 1311, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5241, 1, 51617.28, 1312, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5242, 2, 0.00, 1312, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5243, 3, 51617.28, 1312, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5244, 4, 0.00, 1312, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5245, 5, 16001.36, 1312, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5246, 1, 79950.39, 1313, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5247, 2, 0.00, 1313, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5248, 3, 79950.39, 1313, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5249, 4, 0.00, 1313, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5250, 5, 24784.62, 1313, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5251, 1, 41950.56, 1314, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5252, 2, 0.00, 1314, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5253, 3, 41950.56, 1314, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5254, 4, 0.00, 1314, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5255, 5, 13004.67, 1314, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5256, 1, 99287.36, 1315, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5257, 2, 0.00, 1315, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5258, 3, 99287.36, 1315, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5259, 4, 0.00, 1315, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (5260, 5, 30779.08, 1315, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');


--
-- Data for Name: historico_recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_conceptos VALUES (35300, 14, 0.00, 1297, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35301, 16, 0.00, 1297, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35314, 29, 0.00, 1297, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35317, 30, 0.00, 1297, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35337, 14, 0.00, 1298, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35338, 16, 0.00, 1298, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35351, 29, 0.00, 1298, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35354, 30, 0.00, 1298, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35374, 14, 0.00, 1299, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35375, 16, 0.00, 1299, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35388, 29, 0.00, 1299, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35391, 30, 0.00, 1299, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35411, 14, 0.00, 1300, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35412, 16, 0.00, 1300, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35425, 29, 0.00, 1300, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35428, 30, 0.00, 1300, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35448, 14, 0.00, 1301, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35449, 16, 0.00, 1301, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35462, 29, 0.00, 1301, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35465, 30, 0.00, 1301, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35485, 14, 0.00, 1302, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35486, 16, 0.00, 1302, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35499, 29, 0.00, 1302, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35502, 30, 0.00, 1302, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35522, 14, 0.00, 1303, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35523, 16, 0.00, 1303, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35536, 29, 0.00, 1303, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35539, 30, 0.00, 1303, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35559, 14, 0.00, 1304, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35560, 16, 0.00, 1304, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35573, 29, 0.00, 1304, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35576, 30, 0.00, 1304, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35596, 14, 0.00, 1305, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35597, 16, 0.00, 1305, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35610, 29, 0.00, 1305, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35613, 30, 0.00, 1305, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35633, 14, 0.00, 1306, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35634, 16, 0.00, 1306, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35647, 29, 0.00, 1306, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35650, 30, 0.00, 1306, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35670, 14, 0.00, 1307, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35671, 16, 0.00, 1307, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35684, 29, 0.00, 1307, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35687, 30, 0.00, 1307, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35704, 5, 3.00, 1308, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35707, 14, 0.00, 1308, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35708, 16, 0.00, 1308, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35721, 29, 0.00, 1308, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35724, 30, 0.00, 1308, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35744, 14, 0.00, 1309, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35745, 16, 0.00, 1309, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35758, 29, 0.00, 1309, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35761, 30, 0.00, 1309, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35781, 14, 0.00, 1310, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35782, 16, 0.00, 1310, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35795, 29, 0.00, 1310, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35798, 30, 0.00, 1310, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35818, 14, 0.00, 1311, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35819, 16, 0.00, 1311, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35832, 29, 0.00, 1311, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35835, 30, 0.00, 1311, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35855, 14, 0.00, 1312, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35856, 16, 0.00, 1312, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35869, 29, 0.00, 1312, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35872, 30, 0.00, 1312, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35892, 14, 0.00, 1313, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35893, 16, 0.00, 1313, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35906, 29, 0.00, 1313, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35909, 30, 0.00, 1313, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35929, 14, 0.00, 1314, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35930, 16, 0.00, 1314, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35943, 29, 0.00, 1314, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35946, 30, 0.00, 1314, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35966, 14, 0.00, 1315, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35967, 16, 0.00, 1315, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35980, 29, 0.00, 1315, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35983, 30, 0.00, 1315, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36003, 14, 0.00, 1316, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36004, 16, 0.00, 1316, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36017, 29, 0.00, 1316, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36020, 30, 0.00, 1316, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35293, 1, 34351.20, 1297, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35294, 7, 0.00, 1297, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35295, 12, 3435.12, 1297, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35296, 4, 34351.20, 1297, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35297, 5, 0.00, 1297, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35298, 6, 4809.17, 1297, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35299, 13, 3549.62, 1297, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35302, 15, 46145.11, 1297, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35303, 17, 5075.96, 1297, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35304, 18, 1384.35, 1297, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35305, 19, 1384.35, 1297, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35306, 20, 1153.63, 1297, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35307, 21, 8998.30, 1297, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35308, 22, 37146.82, 1297, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35309, 23, 37146.82, 1297, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35310, 32, 1857.34, 1297, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35311, 24, 34339.60, 1297, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35312, 25, 6669.50, 1297, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35313, 26, 0.00, 1297, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35315, 27, 7154.08, 1297, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35316, 28, 0.00, 1297, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35318, 31, 0.00, 1297, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35319, 33, 0.00, 1297, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35320, 34, 0.00, 1297, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35321, 35, 0.00, 1297, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35322, 36, 0.00, 1297, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35323, 37, 48163.18, 1297, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35324, 38, -11016.36, 1297, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35325, 40, 0.00, 1297, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35326, 9, 1277.86, 1297, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35327, 10, 1277.86, 1297, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35328, 11, 10648.87, 1297, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35329, 39, 0.00, 1297, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35330, 1, 41008.81, 1298, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35331, 7, 0.00, 1298, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35332, 12, 4100.88, 1298, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35333, 4, 41008.81, 1298, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35334, 5, 0.00, 1298, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35335, 6, 4100.88, 1298, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35336, 13, 4100.88, 1298, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35339, 15, 53311.45, 1298, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35340, 17, 5864.26, 1298, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35341, 18, 1599.34, 1298, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35342, 19, 1599.34, 1298, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35343, 20, 1332.79, 1298, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35344, 21, 10395.73, 1298, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35345, 22, 42915.72, 1298, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35346, 23, 42915.72, 1298, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35347, 32, 2145.79, 1298, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35348, 24, 34339.60, 1298, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35349, 25, 0.00, 1298, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35350, 26, 0.00, 1298, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35352, 27, 7154.08, 1298, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35353, 28, 0.00, 1298, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35355, 31, 2145.79, 1298, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35356, 33, 0.00, 1298, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35357, 34, 0.00, 1298, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35358, 35, 0.00, 1298, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35359, 36, 0.00, 1298, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35360, 37, 43639.47, 1298, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35361, 38, -723.75, 1298, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35362, 40, 0.00, 1298, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35363, 9, 1476.32, 1298, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35364, 10, 1476.32, 1298, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35365, 11, 12302.64, 1298, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35366, 39, 0.00, 1298, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35367, 1, 46807.40, 1299, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35368, 7, 0.00, 1299, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35369, 12, 4680.74, 1299, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35370, 4, 46807.40, 1299, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35371, 5, 0.00, 1299, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35372, 6, 28084.44, 1299, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35373, 13, 6631.05, 1299, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35376, 15, 86203.63, 1299, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35377, 17, 9482.40, 1299, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35378, 18, 2586.11, 1299, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35379, 19, 2586.11, 1299, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35380, 20, 2155.09, 1299, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35381, 21, 16809.71, 1299, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35382, 22, 69393.92, 1299, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35383, 23, 69393.92, 1299, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35384, 32, 3469.70, 1299, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35385, 24, 34339.60, 1299, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35386, 25, 6669.50, 1299, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35387, 26, 0.00, 1299, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35389, 27, 7154.08, 1299, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35390, 28, 0.00, 1299, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35392, 31, 0.00, 1299, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35393, 33, 0.00, 1299, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35394, 34, 0.00, 1299, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35395, 35, 0.00, 1299, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35396, 36, 0.00, 1299, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35397, 37, 48163.18, 1299, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35398, 38, 21230.74, 1299, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35399, 40, 110524.46, 1299, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35400, 9, 2387.18, 1299, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35401, 10, 2387.18, 1299, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35402, 11, 19893.15, 1299, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35403, 39, 110524.46, 1299, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35404, 1, 24061.43, 1300, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35405, 7, 0.00, 1300, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35587, 11, 19500.00, 1304, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35406, 12, 2406.14, 1300, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35407, 4, 24061.43, 1300, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35408, 5, 0.00, 1300, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35409, 6, 3849.83, 1300, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35410, 13, 2526.45, 1300, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35413, 15, 32843.85, 1300, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35414, 17, 3612.82, 1300, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35415, 18, 985.32, 1300, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35416, 19, 985.32, 1300, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35417, 20, 821.10, 1300, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35418, 21, 6404.55, 1300, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35419, 22, 26439.30, 1300, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35420, 23, 26439.30, 1300, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35421, 32, 1321.97, 1300, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35422, 24, 34339.60, 1300, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35423, 25, 0.00, 1300, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35424, 26, 0.00, 1300, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35426, 27, 7154.08, 1300, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35427, 28, 0.00, 1300, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35429, 31, 0.00, 1300, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35430, 33, 0.00, 1300, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35431, 34, 0.00, 1300, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35432, 35, 0.00, 1300, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35433, 36, 0.00, 1300, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35434, 37, 41493.68, 1300, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35435, 38, -15054.38, 1300, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35436, 40, 0.00, 1300, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35437, 9, 909.52, 1300, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35438, 10, 909.52, 1300, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35439, 11, 7579.35, 1300, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35440, 39, 0.00, 1300, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35441, 1, 35226.50, 1301, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35442, 7, 0.00, 1301, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35443, 12, 3522.65, 1301, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35444, 4, 35226.50, 1301, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35445, 5, 0.00, 1301, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35446, 6, 2818.12, 1301, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35447, 13, 3463.94, 1301, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35450, 15, 45031.21, 1301, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35451, 17, 4953.43, 1301, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35452, 18, 1350.94, 1301, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35453, 19, 1350.94, 1301, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35454, 20, 1125.78, 1301, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35455, 21, 8781.09, 1301, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35456, 22, 36250.12, 1301, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35457, 23, 36250.12, 1301, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35458, 32, 1812.51, 1301, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35459, 24, 34339.60, 1301, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35460, 25, 6669.50, 1301, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35461, 26, 0.00, 1301, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35463, 27, 7154.08, 1301, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35464, 28, 0.00, 1301, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35466, 31, 0.00, 1301, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35467, 33, 0.00, 1301, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35528, 20, 541.94, 1303, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35468, 34, 0.00, 1301, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35469, 35, 0.00, 1301, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35470, 36, 0.00, 1301, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35471, 37, 48163.18, 1301, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35472, 38, -11913.06, 1301, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35473, 40, 0.00, 1301, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35474, 9, 1247.02, 1301, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35475, 10, 1247.02, 1301, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35476, 11, 10391.82, 1301, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35477, 39, 0.00, 1301, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35478, 1, 48582.30, 1302, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35479, 7, 0.00, 1302, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35480, 12, 4858.23, 1302, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35481, 4, 48582.30, 1302, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35482, 5, 0.00, 1302, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35483, 6, 31092.67, 1302, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35484, 13, 7044.43, 1302, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35487, 15, 91577.64, 1302, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35488, 17, 10073.54, 1302, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35489, 18, 2747.33, 1302, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35490, 19, 2747.33, 1302, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35491, 20, 2289.44, 1302, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35492, 21, 17857.64, 1302, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35493, 22, 73720.00, 1302, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35494, 23, 73720.00, 1302, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35495, 32, 3686.00, 1302, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35496, 24, 34339.60, 1302, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35497, 25, 6669.50, 1302, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35498, 26, 0.00, 1302, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35500, 27, 7154.08, 1302, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35501, 28, 0.00, 1302, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35503, 31, 0.00, 1302, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35504, 33, 0.00, 1302, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35505, 34, 0.00, 1302, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35506, 35, 0.00, 1302, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35507, 36, 0.00, 1302, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35508, 37, 48163.18, 1302, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35509, 38, 25556.82, 1302, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35510, 40, 98759.12, 1302, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35511, 9, 2536.00, 1302, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35512, 10, 2536.00, 1302, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35513, 11, 21133.30, 1302, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35514, 39, 98759.12, 1302, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35515, 1, 17250.00, 1303, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35516, 7, 0.00, 1303, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35517, 12, 1725.00, 1303, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35518, 4, 17250.00, 1303, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35519, 5, 0.00, 1303, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35520, 6, 1035.00, 1303, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35521, 13, 1667.50, 1303, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35524, 15, 21677.50, 1303, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35525, 17, 2384.53, 1303, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35526, 18, 650.33, 1303, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35527, 19, 650.33, 1303, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35529, 21, 4227.11, 1303, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35530, 22, 17450.39, 1303, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35531, 23, 17450.39, 1303, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35532, 32, 872.52, 1303, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35533, 24, 34339.60, 1303, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35534, 25, 0.00, 1303, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35535, 26, 0.00, 1303, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35537, 27, 7154.08, 1303, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35538, 28, 0.00, 1303, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35540, 31, 0.00, 1303, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35541, 33, 0.00, 1303, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35542, 34, 0.00, 1303, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35543, 35, 0.00, 1303, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35544, 36, 0.00, 1303, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35545, 37, 41493.68, 1303, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35546, 38, -24043.29, 1303, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35547, 40, 0.00, 1303, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35548, 9, 600.30, 1303, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35549, 10, 600.30, 1303, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35550, 11, 5002.50, 1303, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35551, 39, 0.00, 1303, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35552, 1, 60000.00, 1304, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35553, 7, 0.00, 1304, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35554, 12, 6000.00, 1304, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35555, 4, 60000.00, 1304, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35556, 5, 0.00, 1304, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35557, 6, 12000.00, 1304, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35558, 13, 6500.00, 1304, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35561, 15, 84500.00, 1304, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35562, 17, 9295.00, 1304, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35563, 18, 2535.00, 1304, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35564, 19, 2535.00, 1304, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35565, 20, 2112.50, 1304, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35566, 21, 16477.50, 1304, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35567, 22, 68022.50, 1304, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35568, 23, 68022.50, 1304, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35569, 32, 3401.13, 1304, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35570, 24, 34339.60, 1304, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35571, 25, 0.00, 1304, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35572, 26, 0.00, 1304, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35574, 27, 7154.08, 1304, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35575, 28, 0.00, 1304, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35577, 31, 0.00, 1304, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35578, 33, 0.00, 1304, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35579, 34, 0.00, 1304, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35580, 35, 0.00, 1304, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35581, 36, 0.00, 1304, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35582, 37, 41493.68, 1304, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35583, 38, 26528.82, 1304, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35584, 40, 125003.21, 1304, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35585, 9, 2340.00, 1304, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35586, 10, 2340.00, 1304, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35588, 39, 125003.21, 1304, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35589, 1, 35033.10, 1305, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35590, 7, 0.00, 1305, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35591, 12, 3503.31, 1305, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35592, 4, 35033.10, 1305, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35593, 5, 0.00, 1305, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35594, 6, 3503.31, 1305, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35595, 13, 3503.31, 1305, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35598, 15, 45543.03, 1305, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35599, 17, 5009.73, 1305, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35600, 18, 1366.29, 1305, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35601, 19, 1366.29, 1305, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35602, 20, 1138.58, 1305, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35603, 21, 8880.89, 1305, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35604, 22, 36662.14, 1305, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35605, 23, 36662.14, 1305, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35606, 32, 1833.11, 1305, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35607, 24, 34339.60, 1305, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35608, 25, 0.00, 1305, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35609, 26, 0.00, 1305, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35611, 27, 7154.08, 1305, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35612, 28, 0.00, 1305, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35614, 31, 0.00, 1305, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35615, 33, 0.00, 1305, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35616, 34, 0.00, 1305, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35617, 35, 0.00, 1305, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35618, 36, 0.00, 1305, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35619, 37, 41493.68, 1305, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35620, 38, -4831.54, 1305, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35621, 40, 0.00, 1305, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35622, 9, 1261.19, 1305, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35623, 10, 1261.19, 1305, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35624, 11, 10509.93, 1305, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35625, 39, 0.00, 1305, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35626, 1, 46839.10, 1306, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35627, 7, 0.00, 1306, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35628, 12, 4683.91, 1306, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35629, 4, 46839.10, 1306, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35630, 5, 0.00, 1306, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35631, 6, 14051.73, 1306, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35632, 13, 5464.56, 1306, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35635, 15, 71039.30, 1306, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35636, 17, 7814.32, 1306, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35637, 18, 2131.18, 1306, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35638, 19, 2131.18, 1306, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35639, 20, 1775.98, 1306, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35640, 21, 13852.66, 1306, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35641, 22, 57186.64, 1306, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35642, 23, 57186.64, 1306, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35643, 32, 2859.33, 1306, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35644, 24, 34339.60, 1306, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35645, 25, 0.00, 1306, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35646, 26, 0.00, 1306, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35648, 27, 7154.08, 1306, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35649, 28, 0.00, 1306, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35651, 31, 0.00, 1306, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35652, 33, 0.00, 1306, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35653, 34, 0.00, 1306, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35654, 35, 0.00, 1306, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35655, 36, 0.00, 1306, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35656, 37, 41493.68, 1306, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35657, 38, 15692.96, 1306, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35658, 40, 90042.93, 1306, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35659, 9, 1967.24, 1306, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35660, 10, 1967.24, 1306, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35661, 11, 16393.69, 1306, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35662, 39, 90042.93, 1306, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35663, 1, 42666.80, 1307, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35664, 7, 0.00, 1307, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35665, 12, 4266.68, 1307, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35666, 4, 42666.80, 1307, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35667, 5, 0.00, 1307, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35668, 6, 10240.03, 1307, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35669, 13, 4764.46, 1307, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35672, 15, 61937.97, 1307, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35673, 17, 6813.18, 1307, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35674, 18, 1858.14, 1307, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35675, 19, 1858.14, 1307, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35676, 20, 1548.45, 1307, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35677, 21, 12077.90, 1307, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35678, 22, 49860.07, 1307, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35679, 23, 49860.07, 1307, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35680, 32, 2493.00, 1307, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35681, 24, 34339.60, 1307, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35682, 25, 0.00, 1307, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35683, 26, 0.00, 1307, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35685, 27, 7154.08, 1307, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35686, 28, 0.00, 1307, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35688, 31, 0.00, 1307, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35689, 33, 0.00, 1307, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35690, 34, 0.00, 1307, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35691, 35, 0.00, 1307, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35692, 36, 0.00, 1307, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35693, 37, 41493.68, 1307, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35694, 38, 8366.39, 1307, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35695, 40, 2312.41, 1307, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35696, 9, 1715.21, 1307, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35697, 10, 1715.21, 1307, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35698, 11, 14293.38, 1307, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35699, 39, 2312.41, 1307, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35700, 1, 42012.00, 1308, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35701, 7, 0.00, 1308, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35702, 12, 4201.20, 1308, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35703, 4, 42012.00, 1308, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35705, 6, 31088.88, 1308, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35706, 13, 6441.84, 1308, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35709, 15, 83743.92, 1308, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35710, 17, 9211.83, 1308, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35711, 18, 2512.32, 1308, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35712, 19, 2512.32, 1308, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35713, 20, 2093.60, 1308, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35714, 21, 16330.06, 1308, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35715, 22, 67413.86, 1308, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35716, 23, 67413.86, 1308, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35717, 32, 3370.69, 1308, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35718, 24, 34339.60, 1308, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35719, 25, 6669.50, 1308, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35720, 26, 0.00, 1308, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35722, 27, 7154.08, 1308, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35723, 28, 0.00, 1308, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35725, 31, 0.00, 1308, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35726, 33, 0.00, 1308, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35727, 34, 0.00, 1308, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35728, 35, 0.00, 1308, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35729, 36, 0.00, 1308, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35730, 37, 48163.18, 1308, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35731, 38, 19250.68, 1308, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35732, 40, 64982.96, 1308, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35733, 9, 2319.06, 1308, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35734, 10, 2319.06, 1308, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35735, 11, 19325.52, 1308, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35736, 39, 64982.96, 1308, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35737, 1, 42717.50, 1309, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35738, 7, 0.00, 1309, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35739, 12, 4271.75, 1309, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35740, 4, 42717.50, 1309, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35741, 5, 0.00, 1309, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35742, 6, 7689.15, 1309, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35743, 13, 4556.53, 1309, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35746, 15, 59234.93, 1309, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35747, 17, 6515.84, 1309, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35748, 18, 1777.05, 1309, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35749, 19, 1777.05, 1309, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35750, 20, 1480.87, 1309, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35751, 21, 11550.81, 1309, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35752, 22, 47684.12, 1309, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35753, 23, 47684.12, 1309, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35754, 32, 2384.21, 1309, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35755, 24, 34339.60, 1309, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35756, 25, 6669.50, 1309, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35757, 26, 0.00, 1309, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35759, 27, 7154.08, 1309, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35760, 28, 0.00, 1309, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35762, 31, 0.00, 1309, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35763, 33, 0.00, 1309, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35764, 34, 0.00, 1309, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35765, 35, 0.00, 1309, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35766, 36, 0.00, 1309, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35767, 37, 48163.18, 1309, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35768, 38, -479.06, 1309, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35769, 40, 0.00, 1309, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35770, 9, 1640.35, 1309, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35771, 10, 1640.35, 1309, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35772, 11, 13669.60, 1309, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35773, 39, 0.00, 1309, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35774, 1, 38158.50, 1310, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35775, 7, 0.00, 1310, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35776, 12, 3815.85, 1310, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35777, 4, 38158.50, 1310, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35778, 5, 0.00, 1310, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35779, 6, 3052.68, 1310, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35780, 13, 3752.25, 1310, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35783, 15, 48779.28, 1310, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35784, 17, 5365.72, 1310, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35785, 18, 1463.38, 1310, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35786, 19, 1463.38, 1310, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35787, 20, 1219.48, 1310, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35788, 21, 9511.96, 1310, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35789, 22, 39267.32, 1310, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35790, 23, 39267.32, 1310, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35791, 32, 1963.37, 1310, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35792, 24, 34339.60, 1310, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35793, 25, 0.00, 1310, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35794, 26, 0.00, 1310, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35796, 27, 7154.08, 1310, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35797, 28, 0.00, 1310, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35799, 31, 0.00, 1310, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35800, 33, 0.00, 1310, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35801, 34, 0.00, 1310, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35802, 35, 0.00, 1310, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35803, 36, 0.00, 1310, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35804, 37, 41493.68, 1310, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35805, 38, -2226.36, 1310, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35806, 40, 0.00, 1310, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35807, 9, 1350.81, 1310, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35808, 10, 1350.81, 1310, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35809, 11, 11256.76, 1310, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35810, 39, 0.00, 1310, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35811, 1, 15764.70, 1311, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35812, 7, 0.00, 1311, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35813, 12, 1576.47, 1311, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35814, 4, 15764.70, 1311, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35815, 5, 0.00, 1311, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35816, 6, 630.59, 1311, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35817, 13, 1497.65, 1311, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35820, 15, 19469.40, 1311, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35821, 17, 2141.63, 1311, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35822, 18, 584.08, 1311, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35823, 19, 584.08, 1311, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35824, 20, 486.74, 1311, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35825, 21, 3796.53, 1311, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35826, 22, 15672.87, 1311, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35827, 23, 15672.87, 1311, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35828, 32, 783.64, 1311, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35829, 24, 34339.60, 1311, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35830, 25, 0.00, 1311, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35831, 26, 0.00, 1311, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35833, 27, 7154.08, 1311, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35834, 28, 0.00, 1311, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35836, 31, 0.00, 1311, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35837, 33, 0.00, 1311, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35838, 34, 0.00, 1311, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35839, 35, 0.00, 1311, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35840, 36, 0.00, 1311, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35841, 37, 41493.68, 1311, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35842, 38, -25820.81, 1311, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35843, 40, 0.00, 1311, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35844, 9, 539.15, 1311, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35845, 10, 539.15, 1311, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35846, 11, 4492.94, 1311, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35847, 39, 0.00, 1311, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35848, 1, 39104.00, 1312, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35849, 7, 0.00, 1312, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35850, 12, 3910.40, 1312, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35851, 4, 39104.00, 1312, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35852, 5, 0.00, 1312, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35853, 6, 8602.88, 1312, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35854, 13, 4301.44, 1312, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35857, 15, 55918.72, 1312, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35858, 17, 6151.06, 1312, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35859, 18, 1677.56, 1312, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35860, 19, 1677.56, 1312, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35861, 20, 1397.97, 1312, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35862, 21, 10904.15, 1312, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35863, 22, 45014.57, 1312, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35864, 23, 45014.57, 1312, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35865, 32, 2250.73, 1312, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35866, 24, 34339.60, 1312, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35867, 25, 0.00, 1312, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35868, 26, 0.00, 1312, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35870, 27, 7154.08, 1312, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35871, 28, 0.00, 1312, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35873, 31, 0.00, 1312, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35874, 33, 0.00, 1312, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35875, 34, 0.00, 1312, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35876, 35, 0.00, 1312, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35877, 36, 0.00, 1312, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35878, 37, 41493.68, 1312, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35879, 38, 3520.89, 1312, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35880, 40, 7045.80, 1312, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35881, 9, 1548.52, 1312, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35882, 10, 1548.52, 1312, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35883, 11, 12904.32, 1312, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35884, 39, 7045.80, 1312, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35885, 1, 45948.50, 1313, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35886, 7, 0.00, 1313, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35887, 12, 4594.85, 1313, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35888, 4, 45948.50, 1313, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35889, 5, 0.00, 1313, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35890, 6, 29407.04, 1313, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35891, 13, 6662.53, 1313, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35894, 15, 86612.92, 1313, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35895, 17, 9527.42, 1313, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35896, 18, 2598.39, 1313, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35897, 19, 2598.39, 1313, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35898, 20, 2165.32, 1313, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35899, 21, 16889.52, 1313, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35900, 22, 69723.40, 1313, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35901, 23, 69723.40, 1313, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35902, 32, 3486.17, 1313, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35903, 24, 34339.60, 1313, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35904, 25, 6669.50, 1313, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35905, 26, 0.00, 1313, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35907, 27, 7154.08, 1313, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35908, 28, 0.00, 1313, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35910, 31, 0.00, 1313, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35911, 33, 0.00, 1313, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35912, 34, 0.00, 1313, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35913, 35, 0.00, 1313, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35914, 36, 0.00, 1313, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35915, 37, 48163.18, 1313, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35916, 38, 21560.22, 1313, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35917, 40, 118102.54, 1313, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35918, 9, 2398.51, 1313, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35919, 10, 2398.51, 1313, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35920, 11, 19987.60, 1313, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35921, 39, 118102.54, 1313, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35922, 1, 34958.80, 1314, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35923, 7, 0.00, 1314, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35924, 12, 3495.88, 1314, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35925, 4, 34958.80, 1314, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35926, 5, 0.00, 1314, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35927, 6, 3495.88, 1314, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35928, 13, 3495.88, 1314, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35931, 15, 45446.44, 1314, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35932, 17, 4999.11, 1314, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35933, 18, 1363.39, 1314, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35934, 19, 1363.39, 1314, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35935, 20, 1136.16, 1314, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35936, 21, 8862.06, 1314, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35937, 22, 36584.38, 1314, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35938, 23, 36584.38, 1314, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35939, 32, 1829.22, 1314, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35940, 24, 34339.60, 1314, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35941, 25, 0.00, 1314, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35942, 26, 0.00, 1314, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35944, 27, 7154.08, 1314, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35945, 28, 0.00, 1314, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35947, 31, 0.00, 1314, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35948, 33, 0.00, 1314, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35949, 34, 0.00, 1314, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35950, 35, 0.00, 1314, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35951, 36, 0.00, 1314, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35952, 37, 41493.68, 1314, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35953, 38, -4909.30, 1314, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35954, 40, 0.00, 1314, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35955, 9, 1258.52, 1314, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35956, 10, 1258.52, 1314, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35957, 11, 10487.64, 1314, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35958, 39, 0.00, 1314, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35959, 1, 57061.70, 1315, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35960, 7, 0.00, 1315, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35961, 12, 5706.17, 1315, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35962, 4, 57061.70, 1315, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35963, 5, 0.00, 1315, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35964, 6, 36519.49, 1315, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (35965, 13, 8273.95, 1315, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35968, 15, 107561.30, 1315, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35969, 17, 11831.74, 1315, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35970, 18, 3226.84, 1315, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35971, 19, 3226.84, 1315, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35972, 20, 2689.03, 1315, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35973, 21, 20974.45, 1315, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35974, 22, 86586.85, 1315, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35975, 23, 86586.85, 1315, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35976, 32, 4329.34, 1315, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35977, 24, 34339.60, 1315, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35978, 25, 0.00, 1315, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35979, 26, 0.00, 1315, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35981, 27, 7154.08, 1315, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35982, 28, 0.00, 1315, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35984, 31, 0.00, 1315, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35985, 33, 0.00, 1315, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35986, 34, 0.00, 1315, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35987, 35, 0.00, 1315, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35988, 36, 0.00, 1315, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35989, 37, 41493.68, 1315, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35990, 38, 45093.17, 1315, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35991, 40, 46232.49, 1315, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35992, 9, 2978.62, 1315, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35993, 10, 2978.62, 1315, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35994, 11, 24821.84, 1315, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35995, 39, 46232.49, 1315, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35996, 1, 34892.86, 1316, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35997, 7, 0.00, 1316, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35998, 12, 3489.29, 1316, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (35999, 4, 34892.86, 1316, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36000, 5, 0.00, 1316, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36001, 6, 697.86, 1316, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (36002, 13, 3256.67, 1316, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36005, 15, 42336.67, 1316, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36006, 17, 4657.03, 1316, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36007, 18, 1270.10, 1316, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36008, 19, 1270.10, 1316, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36009, 20, 1058.42, 1316, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36010, 21, 8255.65, 1316, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36011, 22, 34081.02, 1316, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36012, 23, 34081.02, 1316, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36013, 32, 1704.05, 1316, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36014, 24, 34339.60, 1316, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36015, 25, 6669.50, 1316, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36016, 26, 0.00, 1316, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36018, 27, 7154.08, 1316, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36019, 28, 0.00, 1316, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36021, 31, 0.00, 1316, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36022, 33, 0.00, 1316, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36023, 34, 0.00, 1316, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36024, 35, 0.00, 1316, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36025, 36, 0.00, 1316, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36026, 37, 48163.18, 1316, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36027, 38, -14082.16, 1316, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36028, 40, 0.00, 1316, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36029, 9, 1172.40, 1316, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36030, 10, 1172.40, 1316, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36031, 11, 9770.00, 1316, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (36032, 39, 0.00, 1316, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);


--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (86, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 3, 1, 2019, 1);


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (1757, 1, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1758, 7, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1759, 12, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1760, 4, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1761, 5, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1762, 6, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1763, 13, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1764, 14, 86, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1765, 16, 86, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1766, 15, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1767, 17, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1768, 18, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1769, 19, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1770, 20, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1771, 21, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1772, 22, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1773, 23, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1774, 32, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1775, 24, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1776, 25, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1777, 26, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1778, 29, 86, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1779, 27, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1780, 28, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1781, 30, 86, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1782, 31, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1783, 33, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1784, 34, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1785, 35, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1786, 36, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1787, 37, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1788, 38, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1789, 40, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1790, 9, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1791, 10, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1792, 11, 86, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1793, 39, 86, NULL);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 1793, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 86, true);


--
-- Data for Name: localidades; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.localidades VALUES (1, 'LUJAN', 3450, 7);


--
-- Name: localidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.localidades_id_seq', 1, true);


--
-- Data for Name: nacionalidades; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.nacionalidades VALUES (1, 'Argentino');


--
-- Name: nacionalidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.nacionalidades_id_seq', 1, false);


--
-- Data for Name: obras_sociales; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.obras_sociales VALUES (1, '406', 'swiss medical');
INSERT INTO public.obras_sociales VALUES (2, '106005', 'utedyc');
INSERT INTO public.obras_sociales VALUES (3, '123305', 'medife');
INSERT INTO public.obras_sociales VALUES (4, '125707', 'union personal');
INSERT INTO public.obras_sociales VALUES (5, '113809', 'osde');
INSERT INTO public.obras_sociales VALUES (6, '106005', 'ospedyc');
INSERT INTO public.obras_sociales VALUES (7, '104306', 'galeno');
INSERT INTO public.obras_sociales VALUES (8, '3801', 'osde inmigrantes españoles');


--
-- Name: obras_sociales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.obras_sociales_id_seq', 1, false);


--
-- Data for Name: paises; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.paises VALUES (1, 'Argentina', 'Argentino');


--
-- Name: paises_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paises_id_seq', 1, true);


--
-- Data for Name: periodos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.periodos VALUES (3, 'Test', 2019, 10, '2019-10-01', '2019-08-01', '2019-08-31', 'nada');


--
-- Data for Name: periodos_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.periodos_detalle VALUES (5, 10, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (6, 13, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (7, 11, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (8, 19, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (9, 17, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (10, 18, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (11, 23, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (12, 15, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (13, 20, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (14, 8, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (15, 9, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (16, 16, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (17, 25, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (18, 12, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (19, 21, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (20, 14, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (21, 22, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (22, 7, NULL, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (3, 24, 23.00, NULL, NULL, 0, 3, NULL);
INSERT INTO public.periodos_detalle VALUES (4, 26, 99.00, NULL, NULL, 0, 3, NULL);


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_detalle_id_seq', 22, true);


--
-- Name: periodos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_id_seq', 3, true);


--
-- Data for Name: persona_tareas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.persona_tareas VALUES (2, 2, 1);
INSERT INTO public.persona_tareas VALUES (3, 19, 1);
INSERT INTO public.persona_tareas VALUES (4, 8, 1);
INSERT INTO public.persona_tareas VALUES (5, 8, 2);


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.persona_tareas_id_seq', 5, true);


--
-- Data for Name: personas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.personas VALUES (2, 'Martin', 'Garay', '1989-05-11', 1, '34555008', 1, 1, false, 4611, 1, 1, 1, 1, 'martingaray_12@gmail.com', '2019-07-01', '2019-08-15', '08:00:00', '15:00:00', 1, 'San Vicente 1351', '1 ', 'D         ', '01122777025', '01122777025', 1, '23345550089', 7.00, 10000.00, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (12, 'Gisela Elizabeth', 'Dandrilli', '1984-08-04', 1, '30939944', 2, 1, true, 34, 2, 4, 1, 1, NULL, '2014-02-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27309399442', 7.00, 35226.50, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (13, 'Noemi Severa', 'Delgado', '1956-10-27', 1, '12904169', 2, 1, true, 7, 2, 2, 1, 1, NULL, '1986-07-14', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27129041698', 7.00, 48582.30, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (16, 'Rodrigo Raul', 'Ferreyra', '1989-10-10', 1, '34831908', 1, 1, true, 32, 1, 4, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20348319087', 7.00, 35033.10, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (17, 'Micaela Noemi', 'Frascaroli', '1982-02-27', 1, '29233345', 2, 1, true, 19, 1, 2, 1, 1, NULL, '2003-10-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27292333450', 7.00, 46839.10, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (18, 'Betiana Nazareth', 'Gallesio', '1978-01-04', 1, '26167199', 2, 1, true, 21, 1, 2, 1, 1, NULL, '2006-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27261671994', 7.00, 42666.80, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (20, 'Norma Elizabeth', 'Lombardo', '1960-11-25', 1, '14097779', 2, 1, true, 27, 2, 2, 1, 1, NULL, '2009-08-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27140977794', 7.00, 42717.50, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (21, 'Maria Soledad', 'Paccor', '1979-03-05', 1, '27033687', 2, 1, true, 35, 1, 3, 1, 1, NULL, '2014-11-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27270336871', 7.00, 38158.50, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (22, 'Alejandra', 'Paris', '1984-05-06', 1, '30939775', 2, 1, true, 39, 1, 3, 1, 1, NULL, '2016-07-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '23309397754', 7.00, 15764.70, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (23, 'Jorgelina', 'Parra', '1976-05-11', 1, '25048843', 2, 1, true, 23, 1, 3, 1, 1, NULL, '2007-07-02', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27250488438', 7.00, 39104.00, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (25, 'Lautaro', 'Riccardo', '1986-05-29', 1, '32378152', 1, 1, true, 33, 1, 3, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20323781525', 7.00, 34958.80, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (26, 'Ana Gladys', 'Romero', '1966-05-04', 1, '18148598', 2, 1, true, 3, 3, 1, 1, 1, NULL, '1986-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27181485987', 7.00, 57061.70, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (24, 'Norma', 'Poletti', '1967-11-07', 1, '18601061', 2, 1, true, 2, 2, 2, 1, 1, NULL, '1986-09-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27186010618', 7.00, 45948.50, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (15, 'Maria Cecilia', 'Ferrari', '1982-07-25', 1, '29594863', 2, 1, true, 26, 1, 3, 2, 1, NULL, '2008-02-20', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27295948634', 7.00, NULL, 0, 4.00, NULL);
INSERT INTO public.personas VALUES (14, 'Cesar Anibal', 'Echenique', '1978-12-24', 1, '27113644', 1, 1, true, 37, 1, 3, 2, 1, NULL, '2015-06-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20271136448', 7.00, 17250.00, 0, 4.00, NULL);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265630562', 7.00, 34892.86, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265838333', 7.00, 41008.81, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27144901008', 7.00, 46807.40, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27927271414', 7.00, 24061.43, 0, 4.00, NULL);
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1984-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 42012.00, 0, 8.00, 2);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, 'Mariano Moreno 1460', NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 34351.20, 0, 8.00, 2);


--
-- Data for Name: personas_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.personas_conceptos VALUES (1, 5, 3.00, 19);


--
-- Name: personas_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_conceptos_id_seq', 1, true);


--
-- Name: personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_id_seq', 26, true);


--
-- Data for Name: personas_jornadas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: personas_jornadas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_jornadas_id_seq', 1, false);


--
-- Data for Name: provincias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.provincias VALUES (1, 'Buenos Aires', 1);
INSERT INTO public.provincias VALUES (2, 'Capital Federal', 1);
INSERT INTO public.provincias VALUES (3, 'Catamarca', 1);
INSERT INTO public.provincias VALUES (4, 'Chaco', 1);
INSERT INTO public.provincias VALUES (5, 'Chubut', 1);
INSERT INTO public.provincias VALUES (6, 'Cordoba', 1);
INSERT INTO public.provincias VALUES (7, 'Corrientes', 1);
INSERT INTO public.provincias VALUES (8, 'Entre RÃ­os', 1);
INSERT INTO public.provincias VALUES (9, 'Formosa', 1);
INSERT INTO public.provincias VALUES (10, 'Jujuy', 1);
INSERT INTO public.provincias VALUES (11, 'La Pampa', 1);
INSERT INTO public.provincias VALUES (12, 'La Rioja', 1);
INSERT INTO public.provincias VALUES (13, 'Mendoza', 1);
INSERT INTO public.provincias VALUES (14, 'Misiones', 1);
INSERT INTO public.provincias VALUES (15, 'Neuquén', 1);
INSERT INTO public.provincias VALUES (16, 'Río Negro', 1);
INSERT INTO public.provincias VALUES (17, 'Salta', 1);
INSERT INTO public.provincias VALUES (18, 'San Juan', 1);
INSERT INTO public.provincias VALUES (19, 'San Luis', 1);
INSERT INTO public.provincias VALUES (20, 'Santa Cruz', 1);
INSERT INTO public.provincias VALUES (21, 'Santa Fé', 1);
INSERT INTO public.provincias VALUES (22, 'Santiago del Estero', 1);
INSERT INTO public.provincias VALUES (23, 'Tierra del Fuego', 1);
INSERT INTO public.provincias VALUES (24, 'Tucumán', 1);


--
-- Name: provincias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.provincias_id_seq', 24, true);


--
-- Data for Name: recibos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos VALUES (1316, 1, 7, 39080.00, 0.00, 12114.80, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":39080.0032,"total_no_remunerativos":"0.00","bruto":39080.0032,"total_haberes":"0.00","total_deducciones":12114.800992,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":1,"total_vacaciones":14,"basico":"34892.86","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":34892.86,"c3":0,"c10":3489.286,"c90":34892.86,"c101":0,"c102":697.8572,"c301":3256.6669333333334,"c302":"0.00","c303":"0.00","c309":42336.67013333333,"c310":4657.033714666667,"c311":1270.1001039999999,"c312":1270.1001039999999,"c313":1058.4167533333334,"c320":8255.650676000001,"c321":34081.01945733333,"c322":34081.01945733333,"c323":1704.0509728666666,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":-14082.160542666672,"c370":0,"c501":1172.4000959999998,"c502":1172.4000959999998,"c511":9770.0008,"c515":0}');
INSERT INTO public.recibos VALUES (1297, 2, 8, 42595.49, 0.00, 13204.60, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":42595.488,"total_no_remunerativos":"0.00","bruto":42595.488,"total_haberes":"0.00","total_deducciones":13204.601279999999,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":7,"total_vacaciones":21,"basico":"34351.20","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":34351.2,"c3":0,"c10":3435.12,"c90":34351.2,"c101":0,"c102":4809.168,"c301":3549.624,"c302":"0.00","c303":"0.00","c309":46145.111999999994,"c310":5075.96232,"c311":1384.3533599999998,"c312":1384.3533599999998,"c313":1153.6278,"c320":8998.296839999999,"c321":37146.81516,"c322":37146.81516,"c323":1857.340758,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":-11016.364840000002,"c370":0,"c501":1277.8646399999998,"c502":1277.8646399999998,"c511":10648.872,"c515":0}');
INSERT INTO public.recibos VALUES (1298, 3, 9, 49210.57, 0.00, 15255.28, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":49210.572,"total_no_remunerativos":"0.00","bruto":49210.572,"total_haberes":"0.00","total_deducciones":15255.277320000001,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":5,"total_vacaciones":14,"basico":"41008.81","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":41008.81,"c3":0,"c10":4100.881,"c90":41008.81,"c101":0,"c102":4100.880999999999,"c301":4100.881,"c302":"0.00","c303":"0.00","c309":53311.453,"c310":5864.25983,"c311":1599.34359,"c312":1599.34359,"c313":1332.786325,"c320":10395.733335,"c321":42915.719665,"c322":42915.719665,"c323":2145.78598325,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":2145.78598325,"c338":0,"c339":0,"c340":0,"c341":0,"c350":43639.465983250004,"c360":-723.7463182500069,"c370":0,"c501":1476.31716,"c502":1476.31716,"c511":12302.643,"c515":0}');
INSERT INTO public.recibos VALUES (1299, 4, 10, 79572.58, 0.00, 24667.50, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":79572.58,"total_no_remunerativos":"0.00","bruto":79572.58,"total_haberes":"0.00","total_deducciones":24667.4998,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":30,"total_vacaciones":35,"basico":"46807.40","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":46807.4,"c3":0,"c10":4680.740000000001,"c90":46807.4,"c101":0,"c102":28084.440000000002,"c301":6631.048333333333,"c302":"0.00","c303":"0.00","c309":86203.62833333334,"c310":9482.399116666667,"c311":2586.10885,"c312":2586.10885,"c313":2155.0907083333336,"c320":16809.707525,"c321":69393.92080833334,"c322":69393.92080833334,"c323":3469.696040416667,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":21230.740808333336,"c370":110524.45859166668,"c501":2387.1774,"c502":2387.1774,"c511":19893.145,"c515":110524.45859166668}');
INSERT INTO public.recibos VALUES (1300, 5, 11, 30317.40, 0.00, 9398.39, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":30317.4018,"total_no_remunerativos":"0.00","bruto":30317.4018,"total_haberes":"0.00","total_deducciones":9398.394558,"tiempocomp":false,"tiempoparc":true,"diastrab":"0","hstrab":"0","antiguedad":8,"total_vacaciones":21,"basico":"24061.43","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":24061.43,"c3":0,"c10":2406.143,"c90":24061.43,"c101":0,"c102":3849.8288000000002,"c301":2526.45015,"c302":"0.00","c303":"0.00","c309":32843.85195,"c310":3612.8237145,"c311":985.3155584999998,"c312":985.3155584999998,"c313":821.09629875,"c320":6404.551130249999,"c321":26439.30081975,"c322":26439.30081975,"c323":1321.9650409875,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-15054.379180250002,"c370":0,"c501":909.5220539999999,"c502":909.5220539999999,"c511":7579.35045,"c515":0}');
INSERT INTO public.recibos VALUES (1301, 6, 12, 41567.27, 0.00, 12885.85, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":41567.270000000004,"total_no_remunerativos":"0.00","bruto":41567.270000000004,"total_haberes":"0.00","total_deducciones":12885.853700000001,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":4,"total_vacaciones":14,"basico":"35226.50","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":35226.5,"c3":0,"c10":3522.65,"c90":35226.5,"c101":0,"c102":2818.12,"c301":3463.939166666667,"c302":"0.00","c303":"0.00","c309":45031.20916666667,"c310":4953.433008333333,"c311":1350.936275,"c312":1350.936275,"c313":1125.7802291666667,"c320":8781.0857875,"c321":36250.12337916667,"c322":36250.12337916667,"c323":1812.5061689583335,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":-11913.056620833333,"c370":0,"c501":1247.0181,"c502":1247.0181,"c511":10391.817500000001,"c515":0}');
INSERT INTO public.recibos VALUES (1302, 7, 13, 84533.20, 0.00, 26205.29, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":84533.202,"total_no_remunerativos":"0.00","bruto":84533.202,"total_haberes":"0.00","total_deducciones":26205.29262,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":32,"total_vacaciones":35,"basico":"48582.30","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":48582.3,"c3":0,"c10":4858.2300000000005,"c90":48582.3,"c101":0,"c102":31092.672000000002,"c301":7044.4335,"c302":"0.00","c303":"0.00","c309":91577.6355,"c310":10073.539905,"c311":2747.329065,"c312":2747.329065,"c313":2289.4408875000004,"c320":17857.6389225,"c321":73719.9965775,"c322":73719.9965775,"c323":3685.9998288750003,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":25556.8165775,"c370":98759.11759250001,"c501":2535.99606,"c502":2535.99606,"c511":21133.3005,"c515":98759.11759250001}');
INSERT INTO public.recibos VALUES (1303, 8, 14, 20010.00, 0.00, 6203.10, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":20010,"total_no_remunerativos":"0.00","bruto":20010,"total_haberes":"0.00","total_deducciones":6203.1,"tiempocomp":false,"tiempoparc":true,"diastrab":"0","hstrab":"0","antiguedad":3,"total_vacaciones":14,"basico":"17250.00","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":17250,"c3":0,"c10":1725,"c90":17250,"c101":0,"c102":1035,"c301":1667.5,"c302":"0.00","c303":"0.00","c309":21677.5,"c310":2384.525,"c311":650.3249999999999,"c312":650.3249999999999,"c313":541.9375,"c320":4227.112499999999,"c321":17450.3875,"c322":17450.3875,"c323":872.5193750000001,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-24043.2925,"c370":0,"c501":600.3,"c502":600.3,"c511":5002.5,"c515":0}');
INSERT INTO public.recibos VALUES (1304, 9, 15, 78000.00, 0.00, 24180.00, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":78000,"total_no_remunerativos":"0.00","bruto":78000,"total_haberes":"0.00","total_deducciones":24180,"tiempocomp":false,"tiempoparc":true,"diastrab":"0","hstrab":"0","antiguedad":10,"total_vacaciones":21,"basico":"60000.00","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":60000,"c3":0,"c10":6000,"c90":60000,"c101":0,"c102":12000,"c301":6500,"c302":"0.00","c303":"0.00","c309":84500,"c310":9295,"c311":2535,"c312":2535,"c313":2112.5,"c320":16477.5,"c321":68022.5,"c322":68022.5,"c323":3401.125,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":26528.82,"c370":125003.20999999996,"c501":2340,"c502":2340,"c511":19500,"c515":125003.20999999996}');
INSERT INTO public.recibos VALUES (1305, 10, 16, 42039.72, 0.00, 13032.31, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":42039.719999999994,"total_no_remunerativos":"0.00","bruto":42039.719999999994,"total_haberes":"0.00","total_deducciones":13032.313199999999,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":5,"total_vacaciones":14,"basico":"35033.10","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":35033.1,"c3":0,"c10":3503.31,"c90":35033.1,"c101":0,"c102":3503.31,"c301":3503.3099999999995,"c302":"0.00","c303":"0.00","c309":45543.02999999999,"c310":5009.733299999999,"c311":1366.2908999999997,"c312":1366.2908999999997,"c313":1138.5757499999997,"c320":8880.890849999998,"c321":36662.139149999995,"c322":36662.139149999995,"c323":1833.1069575,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-4831.540850000005,"c370":0,"c501":1261.1915999999999,"c502":1261.1915999999999,"c511":10509.929999999998,"c515":0}');
INSERT INTO public.recibos VALUES (1306, 11, 17, 65574.74, 0.00, 20328.17, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":65574.73999999999,"total_no_remunerativos":"0.00","bruto":65574.73999999999,"total_haberes":"0.00","total_deducciones":20328.1694,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":15,"total_vacaciones":28,"basico":"46839.10","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":46839.1,"c3":0,"c10":4683.91,"c90":46839.1,"c101":0,"c102":14051.73,"c301":5464.561666666666,"c302":"0.00","c303":"0.00","c309":71039.30166666665,"c310":7814.323183333332,"c311":2131.1790499999993,"c312":2131.1790499999993,"c313":1775.9825416666663,"c320":13852.663824999996,"c321":57186.637841666656,"c322":57186.637841666656,"c323":2859.331892083333,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":15692.957841666655,"c370":90042.92899166644,"c501":1967.2421999999997,"c502":1967.2421999999997,"c511":16393.684999999998,"c515":90042.92899166644}');
INSERT INTO public.recibos VALUES (1307, 12, 18, 57173.51, 0.00, 17723.79, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":57173.512,"total_no_remunerativos":"0.00","bruto":57173.512,"total_haberes":"0.00","total_deducciones":17723.78872,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":12,"total_vacaciones":28,"basico":"42666.80","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":42666.8,"c3":0,"c10":4266.68,"c90":42666.8,"c101":0,"c102":10240.032000000001,"c301":4764.459333333333,"c302":"0.00","c303":"0.00","c309":61937.971333333335,"c310":6813.176846666667,"c311":1858.13914,"c312":1858.13914,"c313":1548.4492833333334,"c320":12077.90441,"c321":49860.06692333333,"c322":49860.06692333333,"c323":2493.0033461666667,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":8366.386923333332,"c370":2312.413849999964,"c501":1715.20536,"c502":1715.20536,"c511":14293.378,"c515":2312.413849999964}');
INSERT INTO public.recibos VALUES (1308, 13, 19, 77302.08, 0.00, 23963.64, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":77302.08,"total_no_remunerativos":"0.00","bruto":77302.08,"total_haberes":"0.00","total_deducciones":23963.644800000002,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":34,"total_vacaciones":35,"basico":"42012.00","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":42012,"c3":0,"c10":4201.2,"c90":42012,"c101":"3.00","c102":31088.88,"c301":6441.84,"c302":"0.00","c303":"0.00","c309":83743.92,"c310":9211.8312,"c311":2512.3176,"c312":2512.3176,"c313":2093.598,"c320":16330.064400000001,"c321":67413.8556,"c322":67413.8556,"c323":3370.69278,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":19250.675599999995,"c370":64982.958799999855,"c501":2319.0624,"c502":2319.0624,"c511":19325.52,"c515":64982.958799999855}');
INSERT INTO public.recibos VALUES (1309, 14, 20, 54678.40, 0.00, 16950.30, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":54678.4,"total_no_remunerativos":"0.00","bruto":54678.4,"total_haberes":"0.00","total_deducciones":16950.304,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":9,"total_vacaciones":21,"basico":"42717.50","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":42717.5,"c3":0,"c10":4271.75,"c90":42717.5,"c101":0,"c102":7689.150000000001,"c301":4556.533333333334,"c302":"0.00","c303":"0.00","c309":59234.933333333334,"c310":6515.842666666666,"c311":1777.048,"c312":1777.048,"c313":1480.8733333333334,"c320":11550.812,"c321":47684.121333333336,"c322":47684.121333333336,"c323":2384.206066666667,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":-479.05866666666407,"c370":0,"c501":1640.352,"c502":1640.352,"c511":13669.6,"c515":0}');
INSERT INTO public.recibos VALUES (1310, 15, 21, 45027.03, 0.00, 13958.38, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":45027.03,"total_no_remunerativos":"0.00","bruto":45027.03,"total_haberes":"0.00","total_deducciones":13958.3793,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":4,"total_vacaciones":14,"basico":"38158.50","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":38158.5,"c3":0,"c10":3815.8500000000004,"c90":38158.5,"c101":0,"c102":3052.68,"c301":3752.2525,"c302":"0.00","c303":"0.00","c309":48779.2825,"c310":5365.721075,"c311":1463.378475,"c312":1463.378475,"c313":1219.4820625,"c320":9511.9600875,"c321":39267.3224125,"c322":39267.3224125,"c323":1963.366120625,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-2226.3575875000024,"c370":0,"c501":1350.8109,"c502":1350.8109,"c511":11256.7575,"c515":0}');
INSERT INTO public.recibos VALUES (1311, 16, 22, 17971.76, 0.00, 5571.24, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":17971.758,"total_no_remunerativos":"0.00","bruto":17971.758,"total_haberes":"0.00","total_deducciones":5571.24498,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":2,"total_vacaciones":14,"basico":"15764.70","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":15764.7,"c3":0,"c10":1576.4700000000003,"c90":15764.7,"c101":0,"c102":630.5880000000001,"c301":1497.6465,"c302":"0.00","c303":"0.00","c309":19469.4045,"c310":2141.6344950000002,"c311":584.082135,"c312":584.082135,"c313":486.7351125,"c320":3796.5338775000005,"c321":15672.8706225,"c322":15672.8706225,"c323":783.6435311250001,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-25820.8093775,"c370":0,"c501":539.15274,"c502":539.15274,"c511":4492.9395,"c515":0}');
INSERT INTO public.recibos VALUES (1312, 17, 23, 51617.28, 0.00, 16001.36, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":51617.28,"total_no_remunerativos":"0.00","bruto":51617.28,"total_haberes":"0.00","total_deducciones":16001.3568,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":11,"total_vacaciones":28,"basico":"39104.00","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":39104,"c3":0,"c10":3910.4,"c90":39104,"c101":0,"c102":8602.880000000001,"c301":4301.44,"c302":"0.00","c303":"0.00","c309":55918.72,"c310":6151.059200000001,"c311":1677.5616,"c312":1677.5616,"c313":1397.968,"c320":10904.150400000002,"c321":45014.5696,"c322":45014.5696,"c323":2250.72848,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":3520.8896000000022,"c370":7045.796400000019,"c501":1548.5184,"c502":1548.5184,"c511":12904.32,"c515":7045.796400000019}');
INSERT INTO public.recibos VALUES (1313, 18, 24, 79950.39, 0.00, 24784.62, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":79950.39,"total_no_remunerativos":"0.00","bruto":79950.39,"total_haberes":"0.00","total_deducciones":24784.6209,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":32,"total_vacaciones":35,"basico":"45948.50","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":1,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":45948.5,"c3":0,"c10":4594.85,"c90":45948.5,"c101":0,"c102":29407.04,"c301":6662.5325,"c302":"0.00","c303":"0.00","c309":86612.9225,"c310":9527.421475000001,"c311":2598.387675,"c312":2598.387675,"c313":2165.3230625,"c320":16889.519887500002,"c321":69723.4026125,"c322":69723.4026125,"c323":3486.1701306249997,"c330":"34339.60","c331":"6669.50","c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":48163.18,"c360":21560.222612499994,"c370":118102.54008749983,"c501":2398.5117,"c502":2398.5117,"c511":19987.5975,"c515":118102.54008749983}');
INSERT INTO public.recibos VALUES (1314, 19, 25, 41950.56, 0.00, 13004.67, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":41950.56,"total_no_remunerativos":"0.00","bruto":41950.56,"total_haberes":"0.00","total_deducciones":13004.673599999998,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":5,"total_vacaciones":14,"basico":"34958.80","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":34958.8,"c3":0,"c10":3495.8800000000006,"c90":34958.8,"c101":0,"c102":3495.88,"c301":3495.8799999999997,"c302":"0.00","c303":"0.00","c309":45446.439999999995,"c310":4999.108399999999,"c311":1363.3931999999998,"c312":1363.3931999999998,"c313":1136.1609999999998,"c320":8862.055799999998,"c321":36584.3842,"c322":36584.3842,"c323":1829.2192100000002,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":-4909.2958,"c370":0,"c501":1258.5167999999999,"c502":1258.5167999999999,"c511":10487.64,"c515":0}');
INSERT INTO public.recibos VALUES (1315, 20, 26, 99287.36, 0.00, 30779.08, NULL, NULL, 86, '{"diasmes":31,"calculasac":false,"total_remunerativos":99287.358,"total_no_remunerativos":"0.00","bruto":99287.358,"total_haberes":"0.00","total_deducciones":30779.08098,"tiempocomp":true,"tiempoparc":false,"diastrab":"0","hstrab":"0","antiguedad":32,"total_vacaciones":35,"basico":"57061.70","inasistencias":"0","hsextras":"0","total_remunerativos2":"0","total_no_remunerativos2":"0","diasvacac":"0","casado":0,"hijos":0,"ganancia_neta_acumulada":"0","ganancia_acumulada":"0","maxsueldo1":"0","maxsueldo2":"0","sumsac1":"0","sumsac2":"0","sumsac":"0","maxsueldo":"0","c1":57061.7,"c3":0,"c10":5706.17,"c90":57061.7,"c101":0,"c102":36519.488,"c301":8273.9465,"c302":"0.00","c303":"0.00","c309":107561.3045,"c310":11831.743495,"c311":3226.8391349999997,"c312":3226.8391349999997,"c313":2689.0326125,"c320":20974.4543775,"c321":86586.8501225,"c322":86586.8501225,"c323":4329.342506125001,"c330":"34339.60","c331":0,"c332":0,"c333":"0.00","c334":"7154.08","c335":0,"c336":"0.00","c337":0,"c338":0,"c339":0,"c340":0,"c341":0,"c350":41493.68,"c360":45093.17012250001,"c370":46232.49428750019,"c501":2978.62074,"c502":2978.62074,"c511":24821.8395,"c515":46232.49428750019}');


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (5161, 1, 39080.00, 1316);
INSERT INTO public.recibos_acumuladores VALUES (5162, 2, 0.00, 1316);
INSERT INTO public.recibos_acumuladores VALUES (5163, 3, 39080.00, 1316);
INSERT INTO public.recibos_acumuladores VALUES (5164, 4, 0.00, 1316);
INSERT INTO public.recibos_acumuladores VALUES (5165, 5, 12114.80, 1316);
INSERT INTO public.recibos_acumuladores VALUES (5166, 1, 42595.49, 1297);
INSERT INTO public.recibos_acumuladores VALUES (5167, 2, 0.00, 1297);
INSERT INTO public.recibos_acumuladores VALUES (5168, 3, 42595.49, 1297);
INSERT INTO public.recibos_acumuladores VALUES (5169, 4, 0.00, 1297);
INSERT INTO public.recibos_acumuladores VALUES (5170, 5, 13204.60, 1297);
INSERT INTO public.recibos_acumuladores VALUES (5171, 1, 49210.57, 1298);
INSERT INTO public.recibos_acumuladores VALUES (5172, 2, 0.00, 1298);
INSERT INTO public.recibos_acumuladores VALUES (5173, 3, 49210.57, 1298);
INSERT INTO public.recibos_acumuladores VALUES (5174, 4, 0.00, 1298);
INSERT INTO public.recibos_acumuladores VALUES (5175, 5, 15255.28, 1298);
INSERT INTO public.recibos_acumuladores VALUES (5176, 1, 79572.58, 1299);
INSERT INTO public.recibos_acumuladores VALUES (5177, 2, 0.00, 1299);
INSERT INTO public.recibos_acumuladores VALUES (5178, 3, 79572.58, 1299);
INSERT INTO public.recibos_acumuladores VALUES (5179, 4, 0.00, 1299);
INSERT INTO public.recibos_acumuladores VALUES (5180, 5, 24667.50, 1299);
INSERT INTO public.recibos_acumuladores VALUES (5181, 1, 30317.40, 1300);
INSERT INTO public.recibos_acumuladores VALUES (5182, 2, 0.00, 1300);
INSERT INTO public.recibos_acumuladores VALUES (5183, 3, 30317.40, 1300);
INSERT INTO public.recibos_acumuladores VALUES (5184, 4, 0.00, 1300);
INSERT INTO public.recibos_acumuladores VALUES (5185, 5, 9398.39, 1300);
INSERT INTO public.recibos_acumuladores VALUES (5186, 1, 41567.27, 1301);
INSERT INTO public.recibos_acumuladores VALUES (5187, 2, 0.00, 1301);
INSERT INTO public.recibos_acumuladores VALUES (5188, 3, 41567.27, 1301);
INSERT INTO public.recibos_acumuladores VALUES (5189, 4, 0.00, 1301);
INSERT INTO public.recibos_acumuladores VALUES (5190, 5, 12885.85, 1301);
INSERT INTO public.recibos_acumuladores VALUES (5191, 1, 84533.20, 1302);
INSERT INTO public.recibos_acumuladores VALUES (5192, 2, 0.00, 1302);
INSERT INTO public.recibos_acumuladores VALUES (5193, 3, 84533.20, 1302);
INSERT INTO public.recibos_acumuladores VALUES (5194, 4, 0.00, 1302);
INSERT INTO public.recibos_acumuladores VALUES (5195, 5, 26205.29, 1302);
INSERT INTO public.recibos_acumuladores VALUES (5196, 1, 20010.00, 1303);
INSERT INTO public.recibos_acumuladores VALUES (5197, 2, 0.00, 1303);
INSERT INTO public.recibos_acumuladores VALUES (5198, 3, 20010.00, 1303);
INSERT INTO public.recibos_acumuladores VALUES (5199, 4, 0.00, 1303);
INSERT INTO public.recibos_acumuladores VALUES (5200, 5, 6203.10, 1303);
INSERT INTO public.recibos_acumuladores VALUES (5201, 1, 78000.00, 1304);
INSERT INTO public.recibos_acumuladores VALUES (5202, 2, 0.00, 1304);
INSERT INTO public.recibos_acumuladores VALUES (5203, 3, 78000.00, 1304);
INSERT INTO public.recibos_acumuladores VALUES (5204, 4, 0.00, 1304);
INSERT INTO public.recibos_acumuladores VALUES (5205, 5, 24180.00, 1304);
INSERT INTO public.recibos_acumuladores VALUES (5206, 1, 42039.72, 1305);
INSERT INTO public.recibos_acumuladores VALUES (5207, 2, 0.00, 1305);
INSERT INTO public.recibos_acumuladores VALUES (5208, 3, 42039.72, 1305);
INSERT INTO public.recibos_acumuladores VALUES (5209, 4, 0.00, 1305);
INSERT INTO public.recibos_acumuladores VALUES (5210, 5, 13032.31, 1305);
INSERT INTO public.recibos_acumuladores VALUES (5211, 1, 65574.74, 1306);
INSERT INTO public.recibos_acumuladores VALUES (5212, 2, 0.00, 1306);
INSERT INTO public.recibos_acumuladores VALUES (5213, 3, 65574.74, 1306);
INSERT INTO public.recibos_acumuladores VALUES (5214, 4, 0.00, 1306);
INSERT INTO public.recibos_acumuladores VALUES (5215, 5, 20328.17, 1306);
INSERT INTO public.recibos_acumuladores VALUES (5216, 1, 57173.51, 1307);
INSERT INTO public.recibos_acumuladores VALUES (5217, 2, 0.00, 1307);
INSERT INTO public.recibos_acumuladores VALUES (5218, 3, 57173.51, 1307);
INSERT INTO public.recibos_acumuladores VALUES (5219, 4, 0.00, 1307);
INSERT INTO public.recibos_acumuladores VALUES (5220, 5, 17723.79, 1307);
INSERT INTO public.recibos_acumuladores VALUES (5221, 1, 77302.08, 1308);
INSERT INTO public.recibos_acumuladores VALUES (5222, 2, 0.00, 1308);
INSERT INTO public.recibos_acumuladores VALUES (5223, 3, 77302.08, 1308);
INSERT INTO public.recibos_acumuladores VALUES (5224, 4, 0.00, 1308);
INSERT INTO public.recibos_acumuladores VALUES (5225, 5, 23963.64, 1308);
INSERT INTO public.recibos_acumuladores VALUES (5226, 1, 54678.40, 1309);
INSERT INTO public.recibos_acumuladores VALUES (5227, 2, 0.00, 1309);
INSERT INTO public.recibos_acumuladores VALUES (5228, 3, 54678.40, 1309);
INSERT INTO public.recibos_acumuladores VALUES (5229, 4, 0.00, 1309);
INSERT INTO public.recibos_acumuladores VALUES (5230, 5, 16950.30, 1309);
INSERT INTO public.recibos_acumuladores VALUES (5231, 1, 45027.03, 1310);
INSERT INTO public.recibos_acumuladores VALUES (5232, 2, 0.00, 1310);
INSERT INTO public.recibos_acumuladores VALUES (5233, 3, 45027.03, 1310);
INSERT INTO public.recibos_acumuladores VALUES (5234, 4, 0.00, 1310);
INSERT INTO public.recibos_acumuladores VALUES (5235, 5, 13958.38, 1310);
INSERT INTO public.recibos_acumuladores VALUES (5236, 1, 17971.76, 1311);
INSERT INTO public.recibos_acumuladores VALUES (5237, 2, 0.00, 1311);
INSERT INTO public.recibos_acumuladores VALUES (5238, 3, 17971.76, 1311);
INSERT INTO public.recibos_acumuladores VALUES (5239, 4, 0.00, 1311);
INSERT INTO public.recibos_acumuladores VALUES (5240, 5, 5571.24, 1311);
INSERT INTO public.recibos_acumuladores VALUES (5241, 1, 51617.28, 1312);
INSERT INTO public.recibos_acumuladores VALUES (5242, 2, 0.00, 1312);
INSERT INTO public.recibos_acumuladores VALUES (5243, 3, 51617.28, 1312);
INSERT INTO public.recibos_acumuladores VALUES (5244, 4, 0.00, 1312);
INSERT INTO public.recibos_acumuladores VALUES (5245, 5, 16001.36, 1312);
INSERT INTO public.recibos_acumuladores VALUES (5246, 1, 79950.39, 1313);
INSERT INTO public.recibos_acumuladores VALUES (5247, 2, 0.00, 1313);
INSERT INTO public.recibos_acumuladores VALUES (5248, 3, 79950.39, 1313);
INSERT INTO public.recibos_acumuladores VALUES (5249, 4, 0.00, 1313);
INSERT INTO public.recibos_acumuladores VALUES (5250, 5, 24784.62, 1313);
INSERT INTO public.recibos_acumuladores VALUES (5251, 1, 41950.56, 1314);
INSERT INTO public.recibos_acumuladores VALUES (5252, 2, 0.00, 1314);
INSERT INTO public.recibos_acumuladores VALUES (5253, 3, 41950.56, 1314);
INSERT INTO public.recibos_acumuladores VALUES (5254, 4, 0.00, 1314);
INSERT INTO public.recibos_acumuladores VALUES (5255, 5, 13004.67, 1314);
INSERT INTO public.recibos_acumuladores VALUES (5256, 1, 99287.36, 1315);
INSERT INTO public.recibos_acumuladores VALUES (5257, 2, 0.00, 1315);
INSERT INTO public.recibos_acumuladores VALUES (5258, 3, 99287.36, 1315);
INSERT INTO public.recibos_acumuladores VALUES (5259, 4, 0.00, 1315);
INSERT INTO public.recibos_acumuladores VALUES (5260, 5, 30779.08, 1315);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 5260, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (35300, 14, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35301, 16, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35314, 29, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35317, 30, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35337, 14, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35338, 16, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35351, 29, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35354, 30, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35374, 14, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35375, 16, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35388, 29, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35391, 30, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35411, 14, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35412, 16, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35425, 29, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35428, 30, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35448, 14, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35449, 16, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35462, 29, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35465, 30, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35485, 14, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35486, 16, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35499, 29, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35502, 30, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35522, 14, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35523, 16, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35536, 29, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35539, 30, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35559, 14, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35560, 16, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35573, 29, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35576, 30, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35596, 14, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35597, 16, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35610, 29, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35613, 30, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35633, 14, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35634, 16, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35647, 29, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35650, 30, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35670, 14, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35671, 16, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35684, 29, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35687, 30, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35704, 5, 3.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35707, 14, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35708, 16, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35721, 29, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35724, 30, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35744, 14, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35745, 16, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35758, 29, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35761, 30, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35781, 14, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35782, 16, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35795, 29, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35798, 30, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35818, 14, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35819, 16, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35832, 29, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35835, 30, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35855, 14, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35856, 16, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35869, 29, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35872, 30, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35892, 14, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35893, 16, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35906, 29, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35909, 30, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35929, 14, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35930, 16, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35943, 29, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35946, 30, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35966, 14, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35967, 16, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35980, 29, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35983, 30, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (36003, 14, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36004, 16, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36017, 29, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36020, 30, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (35293, 1, 34351.20, 1297);
INSERT INTO public.recibos_conceptos VALUES (35294, 7, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35295, 12, 3435.12, 1297);
INSERT INTO public.recibos_conceptos VALUES (35296, 4, 34351.20, 1297);
INSERT INTO public.recibos_conceptos VALUES (35297, 5, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35298, 6, 4809.17, 1297);
INSERT INTO public.recibos_conceptos VALUES (35299, 13, 3549.62, 1297);
INSERT INTO public.recibos_conceptos VALUES (35302, 15, 46145.11, 1297);
INSERT INTO public.recibos_conceptos VALUES (35303, 17, 5075.96, 1297);
INSERT INTO public.recibos_conceptos VALUES (35304, 18, 1384.35, 1297);
INSERT INTO public.recibos_conceptos VALUES (35305, 19, 1384.35, 1297);
INSERT INTO public.recibos_conceptos VALUES (35306, 20, 1153.63, 1297);
INSERT INTO public.recibos_conceptos VALUES (35307, 21, 8998.30, 1297);
INSERT INTO public.recibos_conceptos VALUES (35308, 22, 37146.82, 1297);
INSERT INTO public.recibos_conceptos VALUES (35309, 23, 37146.82, 1297);
INSERT INTO public.recibos_conceptos VALUES (35310, 32, 1857.34, 1297);
INSERT INTO public.recibos_conceptos VALUES (35311, 24, 34339.60, 1297);
INSERT INTO public.recibos_conceptos VALUES (35312, 25, 6669.50, 1297);
INSERT INTO public.recibos_conceptos VALUES (35313, 26, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35315, 27, 7154.08, 1297);
INSERT INTO public.recibos_conceptos VALUES (35316, 28, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35318, 31, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35319, 33, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35320, 34, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35321, 35, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35322, 36, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35323, 37, 48163.18, 1297);
INSERT INTO public.recibos_conceptos VALUES (35324, 38, -11016.36, 1297);
INSERT INTO public.recibos_conceptos VALUES (35325, 40, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35326, 9, 1277.86, 1297);
INSERT INTO public.recibos_conceptos VALUES (35327, 10, 1277.86, 1297);
INSERT INTO public.recibos_conceptos VALUES (35328, 11, 10648.87, 1297);
INSERT INTO public.recibos_conceptos VALUES (35329, 39, 0.00, 1297);
INSERT INTO public.recibos_conceptos VALUES (35330, 1, 41008.81, 1298);
INSERT INTO public.recibos_conceptos VALUES (35331, 7, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35332, 12, 4100.88, 1298);
INSERT INTO public.recibos_conceptos VALUES (35333, 4, 41008.81, 1298);
INSERT INTO public.recibos_conceptos VALUES (35334, 5, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35335, 6, 4100.88, 1298);
INSERT INTO public.recibos_conceptos VALUES (35336, 13, 4100.88, 1298);
INSERT INTO public.recibos_conceptos VALUES (35339, 15, 53311.45, 1298);
INSERT INTO public.recibos_conceptos VALUES (35340, 17, 5864.26, 1298);
INSERT INTO public.recibos_conceptos VALUES (35341, 18, 1599.34, 1298);
INSERT INTO public.recibos_conceptos VALUES (35342, 19, 1599.34, 1298);
INSERT INTO public.recibos_conceptos VALUES (35343, 20, 1332.79, 1298);
INSERT INTO public.recibos_conceptos VALUES (35344, 21, 10395.73, 1298);
INSERT INTO public.recibos_conceptos VALUES (35345, 22, 42915.72, 1298);
INSERT INTO public.recibos_conceptos VALUES (35346, 23, 42915.72, 1298);
INSERT INTO public.recibos_conceptos VALUES (35347, 32, 2145.79, 1298);
INSERT INTO public.recibos_conceptos VALUES (35348, 24, 34339.60, 1298);
INSERT INTO public.recibos_conceptos VALUES (35349, 25, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35350, 26, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35352, 27, 7154.08, 1298);
INSERT INTO public.recibos_conceptos VALUES (35353, 28, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35355, 31, 2145.79, 1298);
INSERT INTO public.recibos_conceptos VALUES (35356, 33, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35357, 34, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35358, 35, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35359, 36, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35360, 37, 43639.47, 1298);
INSERT INTO public.recibos_conceptos VALUES (35361, 38, -723.75, 1298);
INSERT INTO public.recibos_conceptos VALUES (35362, 40, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35363, 9, 1476.32, 1298);
INSERT INTO public.recibos_conceptos VALUES (35364, 10, 1476.32, 1298);
INSERT INTO public.recibos_conceptos VALUES (35365, 11, 12302.64, 1298);
INSERT INTO public.recibos_conceptos VALUES (35366, 39, 0.00, 1298);
INSERT INTO public.recibos_conceptos VALUES (35367, 1, 46807.40, 1299);
INSERT INTO public.recibos_conceptos VALUES (35368, 7, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35369, 12, 4680.74, 1299);
INSERT INTO public.recibos_conceptos VALUES (35370, 4, 46807.40, 1299);
INSERT INTO public.recibos_conceptos VALUES (35371, 5, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35372, 6, 28084.44, 1299);
INSERT INTO public.recibos_conceptos VALUES (35373, 13, 6631.05, 1299);
INSERT INTO public.recibos_conceptos VALUES (35376, 15, 86203.63, 1299);
INSERT INTO public.recibos_conceptos VALUES (35377, 17, 9482.40, 1299);
INSERT INTO public.recibos_conceptos VALUES (35378, 18, 2586.11, 1299);
INSERT INTO public.recibos_conceptos VALUES (35379, 19, 2586.11, 1299);
INSERT INTO public.recibos_conceptos VALUES (35380, 20, 2155.09, 1299);
INSERT INTO public.recibos_conceptos VALUES (35381, 21, 16809.71, 1299);
INSERT INTO public.recibos_conceptos VALUES (35382, 22, 69393.92, 1299);
INSERT INTO public.recibos_conceptos VALUES (35383, 23, 69393.92, 1299);
INSERT INTO public.recibos_conceptos VALUES (35384, 32, 3469.70, 1299);
INSERT INTO public.recibos_conceptos VALUES (35385, 24, 34339.60, 1299);
INSERT INTO public.recibos_conceptos VALUES (35386, 25, 6669.50, 1299);
INSERT INTO public.recibos_conceptos VALUES (35387, 26, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35389, 27, 7154.08, 1299);
INSERT INTO public.recibos_conceptos VALUES (35390, 28, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35392, 31, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35393, 33, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35394, 34, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35395, 35, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35396, 36, 0.00, 1299);
INSERT INTO public.recibos_conceptos VALUES (35397, 37, 48163.18, 1299);
INSERT INTO public.recibos_conceptos VALUES (35398, 38, 21230.74, 1299);
INSERT INTO public.recibos_conceptos VALUES (35399, 40, 110524.46, 1299);
INSERT INTO public.recibos_conceptos VALUES (35400, 9, 2387.18, 1299);
INSERT INTO public.recibos_conceptos VALUES (35401, 10, 2387.18, 1299);
INSERT INTO public.recibos_conceptos VALUES (35402, 11, 19893.15, 1299);
INSERT INTO public.recibos_conceptos VALUES (35403, 39, 110524.46, 1299);
INSERT INTO public.recibos_conceptos VALUES (35404, 1, 24061.43, 1300);
INSERT INTO public.recibos_conceptos VALUES (35405, 7, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35406, 12, 2406.14, 1300);
INSERT INTO public.recibos_conceptos VALUES (35407, 4, 24061.43, 1300);
INSERT INTO public.recibos_conceptos VALUES (35408, 5, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35409, 6, 3849.83, 1300);
INSERT INTO public.recibos_conceptos VALUES (35410, 13, 2526.45, 1300);
INSERT INTO public.recibos_conceptos VALUES (35413, 15, 32843.85, 1300);
INSERT INTO public.recibos_conceptos VALUES (35414, 17, 3612.82, 1300);
INSERT INTO public.recibos_conceptos VALUES (35415, 18, 985.32, 1300);
INSERT INTO public.recibos_conceptos VALUES (35416, 19, 985.32, 1300);
INSERT INTO public.recibos_conceptos VALUES (35417, 20, 821.10, 1300);
INSERT INTO public.recibos_conceptos VALUES (35418, 21, 6404.55, 1300);
INSERT INTO public.recibos_conceptos VALUES (35419, 22, 26439.30, 1300);
INSERT INTO public.recibos_conceptos VALUES (35420, 23, 26439.30, 1300);
INSERT INTO public.recibos_conceptos VALUES (35421, 32, 1321.97, 1300);
INSERT INTO public.recibos_conceptos VALUES (35422, 24, 34339.60, 1300);
INSERT INTO public.recibos_conceptos VALUES (35423, 25, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35424, 26, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35426, 27, 7154.08, 1300);
INSERT INTO public.recibos_conceptos VALUES (35427, 28, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35429, 31, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35430, 33, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35431, 34, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35432, 35, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35433, 36, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35434, 37, 41493.68, 1300);
INSERT INTO public.recibos_conceptos VALUES (35435, 38, -15054.38, 1300);
INSERT INTO public.recibos_conceptos VALUES (35436, 40, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35437, 9, 909.52, 1300);
INSERT INTO public.recibos_conceptos VALUES (35438, 10, 909.52, 1300);
INSERT INTO public.recibos_conceptos VALUES (35439, 11, 7579.35, 1300);
INSERT INTO public.recibos_conceptos VALUES (35440, 39, 0.00, 1300);
INSERT INTO public.recibos_conceptos VALUES (35441, 1, 35226.50, 1301);
INSERT INTO public.recibos_conceptos VALUES (35442, 7, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35443, 12, 3522.65, 1301);
INSERT INTO public.recibos_conceptos VALUES (35444, 4, 35226.50, 1301);
INSERT INTO public.recibos_conceptos VALUES (35445, 5, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35446, 6, 2818.12, 1301);
INSERT INTO public.recibos_conceptos VALUES (35447, 13, 3463.94, 1301);
INSERT INTO public.recibos_conceptos VALUES (35450, 15, 45031.21, 1301);
INSERT INTO public.recibos_conceptos VALUES (35451, 17, 4953.43, 1301);
INSERT INTO public.recibos_conceptos VALUES (35452, 18, 1350.94, 1301);
INSERT INTO public.recibos_conceptos VALUES (35453, 19, 1350.94, 1301);
INSERT INTO public.recibos_conceptos VALUES (35454, 20, 1125.78, 1301);
INSERT INTO public.recibos_conceptos VALUES (35455, 21, 8781.09, 1301);
INSERT INTO public.recibos_conceptos VALUES (35456, 22, 36250.12, 1301);
INSERT INTO public.recibos_conceptos VALUES (35457, 23, 36250.12, 1301);
INSERT INTO public.recibos_conceptos VALUES (35458, 32, 1812.51, 1301);
INSERT INTO public.recibos_conceptos VALUES (35459, 24, 34339.60, 1301);
INSERT INTO public.recibos_conceptos VALUES (35460, 25, 6669.50, 1301);
INSERT INTO public.recibos_conceptos VALUES (35461, 26, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35463, 27, 7154.08, 1301);
INSERT INTO public.recibos_conceptos VALUES (35464, 28, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35466, 31, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35467, 33, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35468, 34, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35469, 35, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35470, 36, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35471, 37, 48163.18, 1301);
INSERT INTO public.recibos_conceptos VALUES (35472, 38, -11913.06, 1301);
INSERT INTO public.recibos_conceptos VALUES (35473, 40, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35474, 9, 1247.02, 1301);
INSERT INTO public.recibos_conceptos VALUES (35475, 10, 1247.02, 1301);
INSERT INTO public.recibos_conceptos VALUES (35476, 11, 10391.82, 1301);
INSERT INTO public.recibos_conceptos VALUES (35477, 39, 0.00, 1301);
INSERT INTO public.recibos_conceptos VALUES (35478, 1, 48582.30, 1302);
INSERT INTO public.recibos_conceptos VALUES (35479, 7, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35480, 12, 4858.23, 1302);
INSERT INTO public.recibos_conceptos VALUES (35481, 4, 48582.30, 1302);
INSERT INTO public.recibos_conceptos VALUES (35482, 5, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35483, 6, 31092.67, 1302);
INSERT INTO public.recibos_conceptos VALUES (35484, 13, 7044.43, 1302);
INSERT INTO public.recibos_conceptos VALUES (35487, 15, 91577.64, 1302);
INSERT INTO public.recibos_conceptos VALUES (35488, 17, 10073.54, 1302);
INSERT INTO public.recibos_conceptos VALUES (35489, 18, 2747.33, 1302);
INSERT INTO public.recibos_conceptos VALUES (35490, 19, 2747.33, 1302);
INSERT INTO public.recibos_conceptos VALUES (35491, 20, 2289.44, 1302);
INSERT INTO public.recibos_conceptos VALUES (35492, 21, 17857.64, 1302);
INSERT INTO public.recibos_conceptos VALUES (35493, 22, 73720.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35494, 23, 73720.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35495, 32, 3686.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35496, 24, 34339.60, 1302);
INSERT INTO public.recibos_conceptos VALUES (35497, 25, 6669.50, 1302);
INSERT INTO public.recibos_conceptos VALUES (35498, 26, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35500, 27, 7154.08, 1302);
INSERT INTO public.recibos_conceptos VALUES (35501, 28, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35503, 31, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35504, 33, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35505, 34, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35506, 35, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35507, 36, 0.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35508, 37, 48163.18, 1302);
INSERT INTO public.recibos_conceptos VALUES (35509, 38, 25556.82, 1302);
INSERT INTO public.recibos_conceptos VALUES (35510, 40, 98759.12, 1302);
INSERT INTO public.recibos_conceptos VALUES (35511, 9, 2536.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35512, 10, 2536.00, 1302);
INSERT INTO public.recibos_conceptos VALUES (35513, 11, 21133.30, 1302);
INSERT INTO public.recibos_conceptos VALUES (35514, 39, 98759.12, 1302);
INSERT INTO public.recibos_conceptos VALUES (35515, 1, 17250.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35516, 7, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35517, 12, 1725.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35518, 4, 17250.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35519, 5, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35520, 6, 1035.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35521, 13, 1667.50, 1303);
INSERT INTO public.recibos_conceptos VALUES (35524, 15, 21677.50, 1303);
INSERT INTO public.recibos_conceptos VALUES (35525, 17, 2384.53, 1303);
INSERT INTO public.recibos_conceptos VALUES (35526, 18, 650.33, 1303);
INSERT INTO public.recibos_conceptos VALUES (35527, 19, 650.33, 1303);
INSERT INTO public.recibos_conceptos VALUES (35528, 20, 541.94, 1303);
INSERT INTO public.recibos_conceptos VALUES (35529, 21, 4227.11, 1303);
INSERT INTO public.recibos_conceptos VALUES (35530, 22, 17450.39, 1303);
INSERT INTO public.recibos_conceptos VALUES (35531, 23, 17450.39, 1303);
INSERT INTO public.recibos_conceptos VALUES (35532, 32, 872.52, 1303);
INSERT INTO public.recibos_conceptos VALUES (35533, 24, 34339.60, 1303);
INSERT INTO public.recibos_conceptos VALUES (35534, 25, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35535, 26, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35537, 27, 7154.08, 1303);
INSERT INTO public.recibos_conceptos VALUES (35538, 28, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35540, 31, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35541, 33, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35542, 34, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35543, 35, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35544, 36, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35545, 37, 41493.68, 1303);
INSERT INTO public.recibos_conceptos VALUES (35546, 38, -24043.29, 1303);
INSERT INTO public.recibos_conceptos VALUES (35547, 40, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35548, 9, 600.30, 1303);
INSERT INTO public.recibos_conceptos VALUES (35549, 10, 600.30, 1303);
INSERT INTO public.recibos_conceptos VALUES (35550, 11, 5002.50, 1303);
INSERT INTO public.recibos_conceptos VALUES (35551, 39, 0.00, 1303);
INSERT INTO public.recibos_conceptos VALUES (35552, 1, 60000.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35553, 7, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35554, 12, 6000.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35555, 4, 60000.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35556, 5, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35557, 6, 12000.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35558, 13, 6500.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35561, 15, 84500.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35562, 17, 9295.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35563, 18, 2535.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35564, 19, 2535.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35565, 20, 2112.50, 1304);
INSERT INTO public.recibos_conceptos VALUES (35566, 21, 16477.50, 1304);
INSERT INTO public.recibos_conceptos VALUES (35567, 22, 68022.50, 1304);
INSERT INTO public.recibos_conceptos VALUES (35568, 23, 68022.50, 1304);
INSERT INTO public.recibos_conceptos VALUES (35569, 32, 3401.13, 1304);
INSERT INTO public.recibos_conceptos VALUES (35570, 24, 34339.60, 1304);
INSERT INTO public.recibos_conceptos VALUES (35571, 25, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35572, 26, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35574, 27, 7154.08, 1304);
INSERT INTO public.recibos_conceptos VALUES (35575, 28, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35577, 31, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35578, 33, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35579, 34, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35580, 35, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35581, 36, 0.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35582, 37, 41493.68, 1304);
INSERT INTO public.recibos_conceptos VALUES (35583, 38, 26528.82, 1304);
INSERT INTO public.recibos_conceptos VALUES (35584, 40, 125003.21, 1304);
INSERT INTO public.recibos_conceptos VALUES (35585, 9, 2340.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35586, 10, 2340.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35587, 11, 19500.00, 1304);
INSERT INTO public.recibos_conceptos VALUES (35588, 39, 125003.21, 1304);
INSERT INTO public.recibos_conceptos VALUES (35589, 1, 35033.10, 1305);
INSERT INTO public.recibos_conceptos VALUES (35590, 7, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35591, 12, 3503.31, 1305);
INSERT INTO public.recibos_conceptos VALUES (35592, 4, 35033.10, 1305);
INSERT INTO public.recibos_conceptos VALUES (35593, 5, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35594, 6, 3503.31, 1305);
INSERT INTO public.recibos_conceptos VALUES (35595, 13, 3503.31, 1305);
INSERT INTO public.recibos_conceptos VALUES (35598, 15, 45543.03, 1305);
INSERT INTO public.recibos_conceptos VALUES (35599, 17, 5009.73, 1305);
INSERT INTO public.recibos_conceptos VALUES (35600, 18, 1366.29, 1305);
INSERT INTO public.recibos_conceptos VALUES (35601, 19, 1366.29, 1305);
INSERT INTO public.recibos_conceptos VALUES (35602, 20, 1138.58, 1305);
INSERT INTO public.recibos_conceptos VALUES (35603, 21, 8880.89, 1305);
INSERT INTO public.recibos_conceptos VALUES (35604, 22, 36662.14, 1305);
INSERT INTO public.recibos_conceptos VALUES (35605, 23, 36662.14, 1305);
INSERT INTO public.recibos_conceptos VALUES (35606, 32, 1833.11, 1305);
INSERT INTO public.recibos_conceptos VALUES (35607, 24, 34339.60, 1305);
INSERT INTO public.recibos_conceptos VALUES (35608, 25, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35609, 26, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35611, 27, 7154.08, 1305);
INSERT INTO public.recibos_conceptos VALUES (35612, 28, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35614, 31, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35615, 33, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35616, 34, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35617, 35, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35618, 36, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35619, 37, 41493.68, 1305);
INSERT INTO public.recibos_conceptos VALUES (35620, 38, -4831.54, 1305);
INSERT INTO public.recibos_conceptos VALUES (35621, 40, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35622, 9, 1261.19, 1305);
INSERT INTO public.recibos_conceptos VALUES (35623, 10, 1261.19, 1305);
INSERT INTO public.recibos_conceptos VALUES (35624, 11, 10509.93, 1305);
INSERT INTO public.recibos_conceptos VALUES (35625, 39, 0.00, 1305);
INSERT INTO public.recibos_conceptos VALUES (35626, 1, 46839.10, 1306);
INSERT INTO public.recibos_conceptos VALUES (35627, 7, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35628, 12, 4683.91, 1306);
INSERT INTO public.recibos_conceptos VALUES (35629, 4, 46839.10, 1306);
INSERT INTO public.recibos_conceptos VALUES (35630, 5, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35631, 6, 14051.73, 1306);
INSERT INTO public.recibos_conceptos VALUES (35632, 13, 5464.56, 1306);
INSERT INTO public.recibos_conceptos VALUES (35635, 15, 71039.30, 1306);
INSERT INTO public.recibos_conceptos VALUES (35636, 17, 7814.32, 1306);
INSERT INTO public.recibos_conceptos VALUES (35637, 18, 2131.18, 1306);
INSERT INTO public.recibos_conceptos VALUES (35638, 19, 2131.18, 1306);
INSERT INTO public.recibos_conceptos VALUES (35639, 20, 1775.98, 1306);
INSERT INTO public.recibos_conceptos VALUES (35640, 21, 13852.66, 1306);
INSERT INTO public.recibos_conceptos VALUES (35641, 22, 57186.64, 1306);
INSERT INTO public.recibos_conceptos VALUES (35642, 23, 57186.64, 1306);
INSERT INTO public.recibos_conceptos VALUES (35643, 32, 2859.33, 1306);
INSERT INTO public.recibos_conceptos VALUES (35644, 24, 34339.60, 1306);
INSERT INTO public.recibos_conceptos VALUES (35645, 25, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35646, 26, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35648, 27, 7154.08, 1306);
INSERT INTO public.recibos_conceptos VALUES (35649, 28, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35651, 31, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35652, 33, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35653, 34, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35654, 35, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35655, 36, 0.00, 1306);
INSERT INTO public.recibos_conceptos VALUES (35656, 37, 41493.68, 1306);
INSERT INTO public.recibos_conceptos VALUES (35657, 38, 15692.96, 1306);
INSERT INTO public.recibos_conceptos VALUES (35658, 40, 90042.93, 1306);
INSERT INTO public.recibos_conceptos VALUES (35659, 9, 1967.24, 1306);
INSERT INTO public.recibos_conceptos VALUES (35660, 10, 1967.24, 1306);
INSERT INTO public.recibos_conceptos VALUES (35661, 11, 16393.69, 1306);
INSERT INTO public.recibos_conceptos VALUES (35662, 39, 90042.93, 1306);
INSERT INTO public.recibos_conceptos VALUES (35663, 1, 42666.80, 1307);
INSERT INTO public.recibos_conceptos VALUES (35664, 7, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35665, 12, 4266.68, 1307);
INSERT INTO public.recibos_conceptos VALUES (35666, 4, 42666.80, 1307);
INSERT INTO public.recibos_conceptos VALUES (35667, 5, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35668, 6, 10240.03, 1307);
INSERT INTO public.recibos_conceptos VALUES (35669, 13, 4764.46, 1307);
INSERT INTO public.recibos_conceptos VALUES (35672, 15, 61937.97, 1307);
INSERT INTO public.recibos_conceptos VALUES (35673, 17, 6813.18, 1307);
INSERT INTO public.recibos_conceptos VALUES (35674, 18, 1858.14, 1307);
INSERT INTO public.recibos_conceptos VALUES (35675, 19, 1858.14, 1307);
INSERT INTO public.recibos_conceptos VALUES (35676, 20, 1548.45, 1307);
INSERT INTO public.recibos_conceptos VALUES (35677, 21, 12077.90, 1307);
INSERT INTO public.recibos_conceptos VALUES (35678, 22, 49860.07, 1307);
INSERT INTO public.recibos_conceptos VALUES (35679, 23, 49860.07, 1307);
INSERT INTO public.recibos_conceptos VALUES (35680, 32, 2493.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35681, 24, 34339.60, 1307);
INSERT INTO public.recibos_conceptos VALUES (35682, 25, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35683, 26, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35685, 27, 7154.08, 1307);
INSERT INTO public.recibos_conceptos VALUES (35686, 28, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35688, 31, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35689, 33, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35690, 34, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35691, 35, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35692, 36, 0.00, 1307);
INSERT INTO public.recibos_conceptos VALUES (35693, 37, 41493.68, 1307);
INSERT INTO public.recibos_conceptos VALUES (35694, 38, 8366.39, 1307);
INSERT INTO public.recibos_conceptos VALUES (35695, 40, 2312.41, 1307);
INSERT INTO public.recibos_conceptos VALUES (35696, 9, 1715.21, 1307);
INSERT INTO public.recibos_conceptos VALUES (35697, 10, 1715.21, 1307);
INSERT INTO public.recibos_conceptos VALUES (35698, 11, 14293.38, 1307);
INSERT INTO public.recibos_conceptos VALUES (35699, 39, 2312.41, 1307);
INSERT INTO public.recibos_conceptos VALUES (35700, 1, 42012.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35701, 7, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35702, 12, 4201.20, 1308);
INSERT INTO public.recibos_conceptos VALUES (35703, 4, 42012.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35705, 6, 31088.88, 1308);
INSERT INTO public.recibos_conceptos VALUES (35706, 13, 6441.84, 1308);
INSERT INTO public.recibos_conceptos VALUES (35709, 15, 83743.92, 1308);
INSERT INTO public.recibos_conceptos VALUES (35710, 17, 9211.83, 1308);
INSERT INTO public.recibos_conceptos VALUES (35711, 18, 2512.32, 1308);
INSERT INTO public.recibos_conceptos VALUES (35712, 19, 2512.32, 1308);
INSERT INTO public.recibos_conceptos VALUES (35713, 20, 2093.60, 1308);
INSERT INTO public.recibos_conceptos VALUES (35714, 21, 16330.06, 1308);
INSERT INTO public.recibos_conceptos VALUES (35715, 22, 67413.86, 1308);
INSERT INTO public.recibos_conceptos VALUES (35716, 23, 67413.86, 1308);
INSERT INTO public.recibos_conceptos VALUES (35717, 32, 3370.69, 1308);
INSERT INTO public.recibos_conceptos VALUES (35718, 24, 34339.60, 1308);
INSERT INTO public.recibos_conceptos VALUES (35719, 25, 6669.50, 1308);
INSERT INTO public.recibos_conceptos VALUES (35720, 26, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35722, 27, 7154.08, 1308);
INSERT INTO public.recibos_conceptos VALUES (35723, 28, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35725, 31, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35726, 33, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35727, 34, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35728, 35, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35729, 36, 0.00, 1308);
INSERT INTO public.recibos_conceptos VALUES (35730, 37, 48163.18, 1308);
INSERT INTO public.recibos_conceptos VALUES (35731, 38, 19250.68, 1308);
INSERT INTO public.recibos_conceptos VALUES (35732, 40, 64982.96, 1308);
INSERT INTO public.recibos_conceptos VALUES (35733, 9, 2319.06, 1308);
INSERT INTO public.recibos_conceptos VALUES (35734, 10, 2319.06, 1308);
INSERT INTO public.recibos_conceptos VALUES (35735, 11, 19325.52, 1308);
INSERT INTO public.recibos_conceptos VALUES (35736, 39, 64982.96, 1308);
INSERT INTO public.recibos_conceptos VALUES (35737, 1, 42717.50, 1309);
INSERT INTO public.recibos_conceptos VALUES (35738, 7, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35739, 12, 4271.75, 1309);
INSERT INTO public.recibos_conceptos VALUES (35740, 4, 42717.50, 1309);
INSERT INTO public.recibos_conceptos VALUES (35741, 5, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35742, 6, 7689.15, 1309);
INSERT INTO public.recibos_conceptos VALUES (35743, 13, 4556.53, 1309);
INSERT INTO public.recibos_conceptos VALUES (35746, 15, 59234.93, 1309);
INSERT INTO public.recibos_conceptos VALUES (35747, 17, 6515.84, 1309);
INSERT INTO public.recibos_conceptos VALUES (35748, 18, 1777.05, 1309);
INSERT INTO public.recibos_conceptos VALUES (35749, 19, 1777.05, 1309);
INSERT INTO public.recibos_conceptos VALUES (35750, 20, 1480.87, 1309);
INSERT INTO public.recibos_conceptos VALUES (35751, 21, 11550.81, 1309);
INSERT INTO public.recibos_conceptos VALUES (35752, 22, 47684.12, 1309);
INSERT INTO public.recibos_conceptos VALUES (35753, 23, 47684.12, 1309);
INSERT INTO public.recibos_conceptos VALUES (35754, 32, 2384.21, 1309);
INSERT INTO public.recibos_conceptos VALUES (35755, 24, 34339.60, 1309);
INSERT INTO public.recibos_conceptos VALUES (35756, 25, 6669.50, 1309);
INSERT INTO public.recibos_conceptos VALUES (35757, 26, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35759, 27, 7154.08, 1309);
INSERT INTO public.recibos_conceptos VALUES (35760, 28, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35762, 31, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35763, 33, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35764, 34, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35765, 35, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35766, 36, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35767, 37, 48163.18, 1309);
INSERT INTO public.recibos_conceptos VALUES (35768, 38, -479.06, 1309);
INSERT INTO public.recibos_conceptos VALUES (35769, 40, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35770, 9, 1640.35, 1309);
INSERT INTO public.recibos_conceptos VALUES (35771, 10, 1640.35, 1309);
INSERT INTO public.recibos_conceptos VALUES (35772, 11, 13669.60, 1309);
INSERT INTO public.recibos_conceptos VALUES (35773, 39, 0.00, 1309);
INSERT INTO public.recibos_conceptos VALUES (35774, 1, 38158.50, 1310);
INSERT INTO public.recibos_conceptos VALUES (35775, 7, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35776, 12, 3815.85, 1310);
INSERT INTO public.recibos_conceptos VALUES (35777, 4, 38158.50, 1310);
INSERT INTO public.recibos_conceptos VALUES (35778, 5, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35779, 6, 3052.68, 1310);
INSERT INTO public.recibos_conceptos VALUES (35780, 13, 3752.25, 1310);
INSERT INTO public.recibos_conceptos VALUES (35783, 15, 48779.28, 1310);
INSERT INTO public.recibos_conceptos VALUES (35784, 17, 5365.72, 1310);
INSERT INTO public.recibos_conceptos VALUES (35785, 18, 1463.38, 1310);
INSERT INTO public.recibos_conceptos VALUES (35786, 19, 1463.38, 1310);
INSERT INTO public.recibos_conceptos VALUES (35787, 20, 1219.48, 1310);
INSERT INTO public.recibos_conceptos VALUES (35788, 21, 9511.96, 1310);
INSERT INTO public.recibos_conceptos VALUES (35789, 22, 39267.32, 1310);
INSERT INTO public.recibos_conceptos VALUES (35790, 23, 39267.32, 1310);
INSERT INTO public.recibos_conceptos VALUES (35791, 32, 1963.37, 1310);
INSERT INTO public.recibos_conceptos VALUES (35792, 24, 34339.60, 1310);
INSERT INTO public.recibos_conceptos VALUES (35793, 25, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35794, 26, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35796, 27, 7154.08, 1310);
INSERT INTO public.recibos_conceptos VALUES (35797, 28, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35799, 31, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35800, 33, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35801, 34, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35802, 35, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35803, 36, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35804, 37, 41493.68, 1310);
INSERT INTO public.recibos_conceptos VALUES (35805, 38, -2226.36, 1310);
INSERT INTO public.recibos_conceptos VALUES (35806, 40, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35807, 9, 1350.81, 1310);
INSERT INTO public.recibos_conceptos VALUES (35808, 10, 1350.81, 1310);
INSERT INTO public.recibos_conceptos VALUES (35809, 11, 11256.76, 1310);
INSERT INTO public.recibos_conceptos VALUES (35810, 39, 0.00, 1310);
INSERT INTO public.recibos_conceptos VALUES (35811, 1, 15764.70, 1311);
INSERT INTO public.recibos_conceptos VALUES (35812, 7, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35813, 12, 1576.47, 1311);
INSERT INTO public.recibos_conceptos VALUES (35814, 4, 15764.70, 1311);
INSERT INTO public.recibos_conceptos VALUES (35815, 5, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35816, 6, 630.59, 1311);
INSERT INTO public.recibos_conceptos VALUES (35817, 13, 1497.65, 1311);
INSERT INTO public.recibos_conceptos VALUES (35820, 15, 19469.40, 1311);
INSERT INTO public.recibos_conceptos VALUES (35821, 17, 2141.63, 1311);
INSERT INTO public.recibos_conceptos VALUES (35822, 18, 584.08, 1311);
INSERT INTO public.recibos_conceptos VALUES (35823, 19, 584.08, 1311);
INSERT INTO public.recibos_conceptos VALUES (35824, 20, 486.74, 1311);
INSERT INTO public.recibos_conceptos VALUES (35825, 21, 3796.53, 1311);
INSERT INTO public.recibos_conceptos VALUES (35826, 22, 15672.87, 1311);
INSERT INTO public.recibos_conceptos VALUES (35827, 23, 15672.87, 1311);
INSERT INTO public.recibos_conceptos VALUES (35828, 32, 783.64, 1311);
INSERT INTO public.recibos_conceptos VALUES (35829, 24, 34339.60, 1311);
INSERT INTO public.recibos_conceptos VALUES (35830, 25, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35831, 26, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35833, 27, 7154.08, 1311);
INSERT INTO public.recibos_conceptos VALUES (35834, 28, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35836, 31, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35837, 33, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35838, 34, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35839, 35, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35840, 36, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35841, 37, 41493.68, 1311);
INSERT INTO public.recibos_conceptos VALUES (35842, 38, -25820.81, 1311);
INSERT INTO public.recibos_conceptos VALUES (35843, 40, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35844, 9, 539.15, 1311);
INSERT INTO public.recibos_conceptos VALUES (35845, 10, 539.15, 1311);
INSERT INTO public.recibos_conceptos VALUES (35846, 11, 4492.94, 1311);
INSERT INTO public.recibos_conceptos VALUES (35847, 39, 0.00, 1311);
INSERT INTO public.recibos_conceptos VALUES (35848, 1, 39104.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35849, 7, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35850, 12, 3910.40, 1312);
INSERT INTO public.recibos_conceptos VALUES (35851, 4, 39104.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35852, 5, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35853, 6, 8602.88, 1312);
INSERT INTO public.recibos_conceptos VALUES (35854, 13, 4301.44, 1312);
INSERT INTO public.recibos_conceptos VALUES (35857, 15, 55918.72, 1312);
INSERT INTO public.recibos_conceptos VALUES (35858, 17, 6151.06, 1312);
INSERT INTO public.recibos_conceptos VALUES (35859, 18, 1677.56, 1312);
INSERT INTO public.recibos_conceptos VALUES (35860, 19, 1677.56, 1312);
INSERT INTO public.recibos_conceptos VALUES (35861, 20, 1397.97, 1312);
INSERT INTO public.recibos_conceptos VALUES (35862, 21, 10904.15, 1312);
INSERT INTO public.recibos_conceptos VALUES (35863, 22, 45014.57, 1312);
INSERT INTO public.recibos_conceptos VALUES (35864, 23, 45014.57, 1312);
INSERT INTO public.recibos_conceptos VALUES (35865, 32, 2250.73, 1312);
INSERT INTO public.recibos_conceptos VALUES (35866, 24, 34339.60, 1312);
INSERT INTO public.recibos_conceptos VALUES (35867, 25, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35868, 26, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35870, 27, 7154.08, 1312);
INSERT INTO public.recibos_conceptos VALUES (35871, 28, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35873, 31, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35874, 33, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35875, 34, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35876, 35, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35877, 36, 0.00, 1312);
INSERT INTO public.recibos_conceptos VALUES (35878, 37, 41493.68, 1312);
INSERT INTO public.recibos_conceptos VALUES (35879, 38, 3520.89, 1312);
INSERT INTO public.recibos_conceptos VALUES (35880, 40, 7045.80, 1312);
INSERT INTO public.recibos_conceptos VALUES (35881, 9, 1548.52, 1312);
INSERT INTO public.recibos_conceptos VALUES (35882, 10, 1548.52, 1312);
INSERT INTO public.recibos_conceptos VALUES (35883, 11, 12904.32, 1312);
INSERT INTO public.recibos_conceptos VALUES (35884, 39, 7045.80, 1312);
INSERT INTO public.recibos_conceptos VALUES (35885, 1, 45948.50, 1313);
INSERT INTO public.recibos_conceptos VALUES (35886, 7, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35887, 12, 4594.85, 1313);
INSERT INTO public.recibos_conceptos VALUES (35888, 4, 45948.50, 1313);
INSERT INTO public.recibos_conceptos VALUES (35889, 5, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35890, 6, 29407.04, 1313);
INSERT INTO public.recibos_conceptos VALUES (35891, 13, 6662.53, 1313);
INSERT INTO public.recibos_conceptos VALUES (35894, 15, 86612.92, 1313);
INSERT INTO public.recibos_conceptos VALUES (35895, 17, 9527.42, 1313);
INSERT INTO public.recibos_conceptos VALUES (35896, 18, 2598.39, 1313);
INSERT INTO public.recibos_conceptos VALUES (35897, 19, 2598.39, 1313);
INSERT INTO public.recibos_conceptos VALUES (35898, 20, 2165.32, 1313);
INSERT INTO public.recibos_conceptos VALUES (35899, 21, 16889.52, 1313);
INSERT INTO public.recibos_conceptos VALUES (35900, 22, 69723.40, 1313);
INSERT INTO public.recibos_conceptos VALUES (35901, 23, 69723.40, 1313);
INSERT INTO public.recibos_conceptos VALUES (35902, 32, 3486.17, 1313);
INSERT INTO public.recibos_conceptos VALUES (35903, 24, 34339.60, 1313);
INSERT INTO public.recibos_conceptos VALUES (35904, 25, 6669.50, 1313);
INSERT INTO public.recibos_conceptos VALUES (35905, 26, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35907, 27, 7154.08, 1313);
INSERT INTO public.recibos_conceptos VALUES (35908, 28, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35910, 31, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35911, 33, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35912, 34, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35913, 35, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35914, 36, 0.00, 1313);
INSERT INTO public.recibos_conceptos VALUES (35915, 37, 48163.18, 1313);
INSERT INTO public.recibos_conceptos VALUES (35916, 38, 21560.22, 1313);
INSERT INTO public.recibos_conceptos VALUES (35917, 40, 118102.54, 1313);
INSERT INTO public.recibos_conceptos VALUES (35918, 9, 2398.51, 1313);
INSERT INTO public.recibos_conceptos VALUES (35919, 10, 2398.51, 1313);
INSERT INTO public.recibos_conceptos VALUES (35920, 11, 19987.60, 1313);
INSERT INTO public.recibos_conceptos VALUES (35921, 39, 118102.54, 1313);
INSERT INTO public.recibos_conceptos VALUES (35922, 1, 34958.80, 1314);
INSERT INTO public.recibos_conceptos VALUES (35923, 7, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35924, 12, 3495.88, 1314);
INSERT INTO public.recibos_conceptos VALUES (35925, 4, 34958.80, 1314);
INSERT INTO public.recibos_conceptos VALUES (35926, 5, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35927, 6, 3495.88, 1314);
INSERT INTO public.recibos_conceptos VALUES (35928, 13, 3495.88, 1314);
INSERT INTO public.recibos_conceptos VALUES (35931, 15, 45446.44, 1314);
INSERT INTO public.recibos_conceptos VALUES (35932, 17, 4999.11, 1314);
INSERT INTO public.recibos_conceptos VALUES (35933, 18, 1363.39, 1314);
INSERT INTO public.recibos_conceptos VALUES (35934, 19, 1363.39, 1314);
INSERT INTO public.recibos_conceptos VALUES (35935, 20, 1136.16, 1314);
INSERT INTO public.recibos_conceptos VALUES (35936, 21, 8862.06, 1314);
INSERT INTO public.recibos_conceptos VALUES (35937, 22, 36584.38, 1314);
INSERT INTO public.recibos_conceptos VALUES (35938, 23, 36584.38, 1314);
INSERT INTO public.recibos_conceptos VALUES (35939, 32, 1829.22, 1314);
INSERT INTO public.recibos_conceptos VALUES (35940, 24, 34339.60, 1314);
INSERT INTO public.recibos_conceptos VALUES (35941, 25, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35942, 26, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35944, 27, 7154.08, 1314);
INSERT INTO public.recibos_conceptos VALUES (35945, 28, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35947, 31, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35948, 33, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35949, 34, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35950, 35, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35951, 36, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35952, 37, 41493.68, 1314);
INSERT INTO public.recibos_conceptos VALUES (35953, 38, -4909.30, 1314);
INSERT INTO public.recibos_conceptos VALUES (35954, 40, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35955, 9, 1258.52, 1314);
INSERT INTO public.recibos_conceptos VALUES (35956, 10, 1258.52, 1314);
INSERT INTO public.recibos_conceptos VALUES (35957, 11, 10487.64, 1314);
INSERT INTO public.recibos_conceptos VALUES (35958, 39, 0.00, 1314);
INSERT INTO public.recibos_conceptos VALUES (35959, 1, 57061.70, 1315);
INSERT INTO public.recibos_conceptos VALUES (35960, 7, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35961, 12, 5706.17, 1315);
INSERT INTO public.recibos_conceptos VALUES (35962, 4, 57061.70, 1315);
INSERT INTO public.recibos_conceptos VALUES (35963, 5, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35964, 6, 36519.49, 1315);
INSERT INTO public.recibos_conceptos VALUES (35965, 13, 8273.95, 1315);
INSERT INTO public.recibos_conceptos VALUES (35968, 15, 107561.30, 1315);
INSERT INTO public.recibos_conceptos VALUES (35969, 17, 11831.74, 1315);
INSERT INTO public.recibos_conceptos VALUES (35970, 18, 3226.84, 1315);
INSERT INTO public.recibos_conceptos VALUES (35971, 19, 3226.84, 1315);
INSERT INTO public.recibos_conceptos VALUES (35972, 20, 2689.03, 1315);
INSERT INTO public.recibos_conceptos VALUES (35973, 21, 20974.45, 1315);
INSERT INTO public.recibos_conceptos VALUES (35974, 22, 86586.85, 1315);
INSERT INTO public.recibos_conceptos VALUES (35975, 23, 86586.85, 1315);
INSERT INTO public.recibos_conceptos VALUES (35976, 32, 4329.34, 1315);
INSERT INTO public.recibos_conceptos VALUES (35977, 24, 34339.60, 1315);
INSERT INTO public.recibos_conceptos VALUES (35978, 25, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35979, 26, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35981, 27, 7154.08, 1315);
INSERT INTO public.recibos_conceptos VALUES (35982, 28, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35984, 31, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35985, 33, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35986, 34, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35987, 35, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35988, 36, 0.00, 1315);
INSERT INTO public.recibos_conceptos VALUES (35989, 37, 41493.68, 1315);
INSERT INTO public.recibos_conceptos VALUES (35990, 38, 45093.17, 1315);
INSERT INTO public.recibos_conceptos VALUES (35991, 40, 46232.49, 1315);
INSERT INTO public.recibos_conceptos VALUES (35992, 9, 2978.62, 1315);
INSERT INTO public.recibos_conceptos VALUES (35993, 10, 2978.62, 1315);
INSERT INTO public.recibos_conceptos VALUES (35994, 11, 24821.84, 1315);
INSERT INTO public.recibos_conceptos VALUES (35995, 39, 46232.49, 1315);
INSERT INTO public.recibos_conceptos VALUES (35996, 1, 34892.86, 1316);
INSERT INTO public.recibos_conceptos VALUES (35997, 7, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (35998, 12, 3489.29, 1316);
INSERT INTO public.recibos_conceptos VALUES (35999, 4, 34892.86, 1316);
INSERT INTO public.recibos_conceptos VALUES (36000, 5, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36001, 6, 697.86, 1316);
INSERT INTO public.recibos_conceptos VALUES (36002, 13, 3256.67, 1316);
INSERT INTO public.recibos_conceptos VALUES (36005, 15, 42336.67, 1316);
INSERT INTO public.recibos_conceptos VALUES (36006, 17, 4657.03, 1316);
INSERT INTO public.recibos_conceptos VALUES (36007, 18, 1270.10, 1316);
INSERT INTO public.recibos_conceptos VALUES (36008, 19, 1270.10, 1316);
INSERT INTO public.recibos_conceptos VALUES (36009, 20, 1058.42, 1316);
INSERT INTO public.recibos_conceptos VALUES (36010, 21, 8255.65, 1316);
INSERT INTO public.recibos_conceptos VALUES (36011, 22, 34081.02, 1316);
INSERT INTO public.recibos_conceptos VALUES (36012, 23, 34081.02, 1316);
INSERT INTO public.recibos_conceptos VALUES (36013, 32, 1704.05, 1316);
INSERT INTO public.recibos_conceptos VALUES (36014, 24, 34339.60, 1316);
INSERT INTO public.recibos_conceptos VALUES (36015, 25, 6669.50, 1316);
INSERT INTO public.recibos_conceptos VALUES (36016, 26, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36018, 27, 7154.08, 1316);
INSERT INTO public.recibos_conceptos VALUES (36019, 28, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36021, 31, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36022, 33, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36023, 34, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36024, 35, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36025, 36, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36026, 37, 48163.18, 1316);
INSERT INTO public.recibos_conceptos VALUES (36027, 38, -14082.16, 1316);
INSERT INTO public.recibos_conceptos VALUES (36028, 40, 0.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36029, 9, 1172.40, 1316);
INSERT INTO public.recibos_conceptos VALUES (36030, 10, 1172.40, 1316);
INSERT INTO public.recibos_conceptos VALUES (36031, 11, 9770.00, 1316);
INSERT INTO public.recibos_conceptos VALUES (36032, 39, 0.00, 1316);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 36032, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 1316, true);


--
-- Data for Name: regimenes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.regimenes VALUES (1, 'Reparto');
INSERT INTO public.regimenes VALUES (2, 'Sipa');
INSERT INTO public.regimenes VALUES (3, 'Capitalización');


--
-- Name: regimenes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.regimenes_id_seq', 1, false);


--
-- Data for Name: tabla; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla VALUES (2, 'conyuge', 'Deducciones Cónyuge');
INSERT INTO public.tabla VALUES (3, 'hijo', 'Deducciones Hijo');
INSERT INTO public.tabla VALUES (4, 'familia', 'Cargas de familia');
INSERT INTO public.tabla VALUES (5, 'ganancia', 'Ganancia no imponible');
INSERT INTO public.tabla VALUES (6, 'hipoteca', 'Intereses créditos hipotecarios');
INSERT INTO public.tabla VALUES (7, 'segurovida', 'Seguro de Vida');
INSERT INTO public.tabla VALUES (8, 'prepaga', 'Prepaga');
INSERT INTO public.tabla VALUES (11, 'alquiler', 'Alquileres');
INSERT INTO public.tabla VALUES (10, 'donacion', 'Donaciones');
INSERT INTO public.tabla VALUES (9, 'medico', 'Gastos médicos');
INSERT INTO public.tabla VALUES (1, 'especial', 'Deducciones Especiales');


--
-- Data for Name: tabla_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_detalle VALUES (97, 2019, 1, '2019-01-01', 0.00, 2205.62, 10);
INSERT INTO public.tabla_detalle VALUES (98, 2019, 2, '2019-02-01', 0.00, 4327.69, 10);
INSERT INTO public.tabla_detalle VALUES (99, 2019, 3, '2019-03-01', 0.00, 6488.88, 10);
INSERT INTO public.tabla_detalle VALUES (10, 2019, 10, '2019-10-01', 343395.95, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (11, 2019, 11, '2019-11-01', 377735.55, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (12, 2019, 12, '2019-12-01', 412075.14, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (13, 2019, 1, '2019-01-01', 6669.50, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (14, 2019, 2, '2019-02-01', 13339.00, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (15, 2019, 3, '2019-03-01', 20008.49, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (16, 2019, 4, '2019-04-01', 26677.99, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (17, 2019, 5, '2019-05-01', 33347.49, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (18, 2019, 6, '2019-06-01', 40016.99, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (19, 2019, 7, '2019-07-01', 46686.48, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (20, 2019, 8, '2019-08-01', 53355.98, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (21, 2019, 9, '2019-09-01', 60025.48, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (22, 2019, 10, '2019-10-01', 66694.98, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (23, 2019, 11, '2019-11-01', 73364.47, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (24, 2019, 12, '2019-12-01', 80033.97, 0.00, 2);
INSERT INTO public.tabla_detalle VALUES (25, 2019, 1, '2019-01-01', 3363.45, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (26, 2019, 2, '2019-02-01', 6726.91, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (27, 2019, 3, '2019-03-01', 10090.36, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (28, 2019, 4, '2019-04-01', 13453.81, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (29, 2019, 5, '2019-05-01', 16817.26, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (30, 2019, 6, '2019-06-01', 20180.72, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (31, 2019, 7, '2019-07-01', 23544.17, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (32, 2019, 8, '2019-08-01', 26907.62, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (33, 2019, 9, '2019-09-01', 30271.07, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (34, 2019, 10, '2019-10-01', 33634.53, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (35, 2019, 11, '2019-11-01', 36997.98, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (36, 2019, 12, '2019-12-01', 40361.43, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (37, 2019, 1, '2019-01-01', 3363.45, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (38, 2019, 2, '2019-02-01', 6726.91, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (39, 2019, 3, '2019-03-01', 10090.36, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (40, 2019, 4, '2019-04-01', 13453.81, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (41, 2019, 5, '2019-05-01', 16817.26, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (42, 2019, 6, '2019-06-01', 20180.72, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (43, 2019, 7, '2019-07-01', 23544.17, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (44, 2019, 8, '2019-08-01', 26907.62, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (45, 2019, 9, '2019-09-01', 30271.07, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (46, 2019, 10, '2019-10-01', 33634.53, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (47, 2019, 11, '2019-11-01', 36997.98, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (48, 2019, 12, '2019-12-01', 40361.43, 0.00, 4);
INSERT INTO public.tabla_detalle VALUES (49, 2019, 1, '2019-01-01', 7154.08, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (50, 2019, 2, '2019-02-01', 14308.17, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (51, 2019, 3, '2019-03-01', 21462.25, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (52, 2019, 4, '2019-04-01', 28616.33, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (53, 2019, 5, '2019-05-01', 35770.41, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (54, 2019, 6, '2019-06-01', 42924.50, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (55, 2019, 7, '2019-07-01', 50078.58, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (56, 2019, 8, '2019-08-01', 57232.66, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (57, 2019, 9, '2019-09-01', 64386.74, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (58, 2019, 10, '2019-10-01', 71540.83, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (59, 2019, 11, '2019-11-01', 78694.91, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (60, 2019, 12, '2019-12-01', 85848.99, 0.00, 5);
INSERT INTO public.tabla_detalle VALUES (61, 2019, 1, '2019-01-01', 0.00, 1000.00, 7);
INSERT INTO public.tabla_detalle VALUES (62, 2019, 2, '2019-02-01', 0.00, 2000.00, 7);
INSERT INTO public.tabla_detalle VALUES (63, 2019, 3, '2019-03-01', 0.00, 3000.00, 7);
INSERT INTO public.tabla_detalle VALUES (64, 2019, 4, '2019-04-01', 0.00, 4000.00, 7);
INSERT INTO public.tabla_detalle VALUES (65, 2019, 5, '2019-05-01', 0.00, 5000.00, 7);
INSERT INTO public.tabla_detalle VALUES (66, 2019, 6, '2019-06-01', 0.00, 6000.00, 7);
INSERT INTO public.tabla_detalle VALUES (67, 2019, 7, '2019-07-01', 0.00, 7000.00, 7);
INSERT INTO public.tabla_detalle VALUES (68, 2019, 8, '2019-08-01', 0.00, 8000.00, 7);
INSERT INTO public.tabla_detalle VALUES (69, 2019, 9, '2019-09-01', 0.00, 9000.00, 7);
INSERT INTO public.tabla_detalle VALUES (70, 2019, 10, '2019-10-01', 0.00, 10000.00, 7);
INSERT INTO public.tabla_detalle VALUES (71, 2019, 11, '2019-11-01', 0.00, 11000.00, 7);
INSERT INTO public.tabla_detalle VALUES (72, 2019, 12, '2019-12-01', 0.00, 12000.00, 7);
INSERT INTO public.tabla_detalle VALUES (73, 2019, 1, '2019-01-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (74, 2019, 2, '2019-02-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (75, 2019, 3, '2019-03-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (76, 2019, 4, '2019-04-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (77, 2019, 5, '2019-05-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (78, 2019, 6, '2019-06-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (79, 2019, 7, '2019-07-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (80, 2019, 8, '2019-08-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (81, 2019, 9, '2019-09-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (82, 2019, 10, '2019-10-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (83, 2019, 11, '2019-11-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (84, 2019, 12, '2019-12-01', 0.00, 0.00, 8);
INSERT INTO public.tabla_detalle VALUES (94, 2019, 10, '2019-10-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (95, 2019, 11, '2019-11-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (96, 2019, 12, '2019-12-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (106, 2019, 10, '2019-10-01', 0.00, 16542.51, 10);
INSERT INTO public.tabla_detalle VALUES (107, 2019, 11, '2019-11-01', 0.00, 16542.51, 10);
INSERT INTO public.tabla_detalle VALUES (108, 2019, 12, '2019-12-01', 0.00, 17525.68, 10);
INSERT INTO public.tabla_detalle VALUES (109, 2019, 1, '2019-01-01', 0.00, 5576.49, 11);
INSERT INTO public.tabla_detalle VALUES (110, 2019, 2, '2019-02-01', 0.00, 11152.99, 11);
INSERT INTO public.tabla_detalle VALUES (111, 2019, 3, '2019-03-01', 0.00, 16729.48, 11);
INSERT INTO public.tabla_detalle VALUES (112, 2019, 4, '2019-04-01', 0.00, 22305.97, 11);
INSERT INTO public.tabla_detalle VALUES (113, 2019, 5, '2019-05-01', 0.00, 27882.46, 11);
INSERT INTO public.tabla_detalle VALUES (114, 2019, 6, '2019-06-01', 0.00, 33458.96, 11);
INSERT INTO public.tabla_detalle VALUES (115, 2019, 7, '2019-07-01', 0.00, 39035.45, 11);
INSERT INTO public.tabla_detalle VALUES (116, 2019, 8, '2019-08-01', 0.00, 44611.94, 11);
INSERT INTO public.tabla_detalle VALUES (117, 2019, 9, '2019-09-01', 0.00, 50188.43, 11);
INSERT INTO public.tabla_detalle VALUES (118, 2019, 10, '2019-10-01', 0.00, 55764.93, 11);
INSERT INTO public.tabla_detalle VALUES (119, 2019, 11, '2019-11-01', 0.00, 61341.42, 11);
INSERT INTO public.tabla_detalle VALUES (120, 2019, 12, '2019-12-01', 0.00, 66917.91, 11);
INSERT INTO public.tabla_detalle VALUES (100, 2019, 4, '2019-04-01', 0.00, 8633.71, 10);
INSERT INTO public.tabla_detalle VALUES (101, 2019, 5, '2019-05-01', 0.00, 11235.59, 10);
INSERT INTO public.tabla_detalle VALUES (102, 2019, 6, '2019-06-01', 0.00, 13944.76, 10);
INSERT INTO public.tabla_detalle VALUES (103, 2019, 7, '2019-07-01', 0.00, 16542.51, 10);
INSERT INTO public.tabla_detalle VALUES (104, 2019, 8, '2019-08-01', 0.00, 16542.51, 10);
INSERT INTO public.tabla_detalle VALUES (105, 2019, 9, '2019-09-01', 0.00, 16542.51, 10);
INSERT INTO public.tabla_detalle VALUES (85, 2019, 1, '2019-01-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (86, 2019, 2, '2019-02-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (87, 2019, 3, '2019-03-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (88, 2019, 4, '2019-04-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (89, 2019, 5, '2019-05-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (90, 2019, 6, '2019-06-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (91, 2019, 7, '2019-07-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (92, 2019, 8, '2019-08-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (93, 2019, 9, '2019-09-01', 0.00, 0.00, 9);
INSERT INTO public.tabla_detalle VALUES (4, 2019, 4, '2019-04-01', 137358.38, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (5, 2019, 5, '2019-05-01', 171697.98, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (6, 2019, 6, '2019-06-01', 206037.57, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (7, 2019, 7, '2019-07-01', 240377.17, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (8, 2019, 8, '2019-08-01', 274716.76, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (9, 2019, 9, '2019-09-01', 309056.36, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (1, 2019, 1, '2019-01-01', 34339.60, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (2, 2019, 2, '2019-02-01', 68679.19, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (3, 2019, 3, '2019-03-01', 103018.79, 0.00, 1);


--
-- Name: tabla_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_detalle_id_seq', 120, true);


--
-- Data for Name: tabla_ganancias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_ganancias VALUES (2, 2019, 'Tabla Ganancias 2019');


--
-- Data for Name: tabla_ganancias_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_ganancias_detalle VALUES (6, 1, 0.00, 2753.32, 0.00, 5.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (7, 1, 2753.32, 5506.63, 137.67, 9.00, 2753.32, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (8, 1, 5506.63, 8259.95, 385.46, 12.00, 5506.63, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (9, 1, 8259.95, 11013.27, 715.86, 15.00, 8259.95, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (10, 1, 11013.27, 16519.90, 1128.86, 19.00, 11013.27, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (11, 1, 16519.90, 22026.54, 2175.12, 23.00, 16519.90, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (12, 1, 22026.54, 33039.81, 3441.65, 27.00, 22026.54, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (13, 1, 33039.81, 44053.08, 6415.23, 31.00, 33039.81, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (14, 1, 44053.08, 999999.00, 9829.34, 35.00, 44053.08, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (15, 2, 0.00, 5506.63, 0.00, 5.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (16, 2, 5506.63, 11013.27, 275.33, 9.00, 5506.63, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (17, 2, 11013.27, 16519.90, 770.93, 12.00, 11013.27, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (18, 2, 16519.90, 22026.54, 1431.73, 15.00, 16519.90, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (19, 2, 22026.54, 33039.81, 2257.72, 19.00, 22026.54, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (20, 2, 33039.81, 44053.08, 4350.24, 23.00, 33039.81, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (21, 2, 44053.08, 66079.61, 6883.29, 27.00, 44053.08, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (22, 2, 66079.61, 88106.15, 12830.46, 31.00, 66079.61, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (23, 2, 88106.15, 999999.00, 19658.69, 35.00, 88106.15, 2);


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_detalle_id_seq', 23, true);


--
-- Name: tabla_ganancias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_id_seq', 2, true);


--
-- Name: tabla_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_id_seq', 11, true);


--
-- Data for Name: tabla_personas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_personas VALUES (1, 2019, 12, '2019-12-01', 5000.00, 8, 1);
INSERT INTO public.tabla_personas VALUES (2, 2019, 2, '2019-02-01', 10000.00, 8, 4);
INSERT INTO public.tabla_personas VALUES (3, 2019, 1, '2019-01-01', 2803.22, 9, 8);
INSERT INTO public.tabla_personas VALUES (4, 2019, 2, '2019-02-01', 3161.11, 9, 8);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 4, true);


--
-- Data for Name: tabla_vacaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_vacaciones VALUES (1, 1.00, 5.00, 14);
INSERT INTO public.tabla_vacaciones VALUES (2, 5.00, 10.00, 21);
INSERT INTO public.tabla_vacaciones VALUES (3, 10.00, 20.00, 28);
INSERT INTO public.tabla_vacaciones VALUES (4, 20.00, 99.00, 35);


--
-- Data for Name: tabla_vacaciones_dias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_vacaciones_dias VALUES (5, 140, 182, 5, 'Más de 20 semanas de trabajo');
INSERT INTO public.tabla_vacaciones_dias VALUES (3, 84, 111, 3, 'Entre 12 y 15 semanas de trabajo');
INSERT INTO public.tabla_vacaciones_dias VALUES (2, 56, 83, 2, 'Entre 8 y 11 semanas de trabajo');
INSERT INTO public.tabla_vacaciones_dias VALUES (1, 28, 55, 1, 'Entre 4 y 7 semanas de trabajo');
INSERT INTO public.tabla_vacaciones_dias VALUES (4, 112, 139, 4, 'Entre 16 y 19 semanas de trabajo');


--
-- Data for Name: tareas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tareas VALUES (1, 'ay.sub area');
INSERT INTO public.tareas VALUES (2, 'facturacion');
INSERT INTO public.tareas VALUES (3, 'convenios');
INSERT INTO public.tareas VALUES (4, 'maestr.y serv.');
INSERT INTO public.tareas VALUES (5, 'ioma');
INSERT INTO public.tareas VALUES (6, 'Encargada');
INSERT INTO public.tareas VALUES (7, 'sub area ioma');
INSERT INTO public.tareas VALUES (8, 'fact.ioma');
INSERT INTO public.tareas VALUES (9, 'Area Contable');
INSERT INTO public.tareas VALUES (10, 'Secretaria');
INSERT INTO public.tareas VALUES (11, 'Responsable');
INSERT INTO public.tareas VALUES (12, 'Ad./Jefa de Personal');


--
-- Name: tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tareas_id_seq', 1, false);


--
-- Data for Name: tipo_liquidacion_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipo_liquidacion_conceptos VALUES (1, 1, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (6, 4, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (7, 5, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (8, 6, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (9, 7, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (10, 10, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (11, 9, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (12, 11, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (13, 12, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (14, 13, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (15, 14, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (16, 16, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (17, 15, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (18, 17, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (19, 18, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (20, 19, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (21, 20, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (22, 21, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (23, 22, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (25, 23, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (26, 32, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (27, 24, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (28, 25, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (29, 26, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (30, 29, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (31, 27, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (32, 28, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (33, 30, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (34, 31, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (36, 33, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (37, 34, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (38, 35, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (39, 36, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (40, 37, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (41, 38, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (42, 40, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (43, 39, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (44, 1, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (45, 4, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (46, 5, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (47, 6, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (48, 7, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (49, 10, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (50, 9, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (51, 11, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (52, 12, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (53, 13, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (54, 14, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (55, 16, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (56, 15, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (57, 17, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (58, 18, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (59, 19, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (60, 20, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (61, 21, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (62, 22, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (63, 23, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (64, 32, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (65, 24, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (66, 25, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (67, 26, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (68, 29, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (69, 27, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (70, 28, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (71, 30, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (72, 31, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (73, 33, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (74, 34, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (75, 35, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (76, 36, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (77, 37, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (78, 38, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (79, 40, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (80, 39, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (81, 1, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (82, 4, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (83, 5, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (84, 6, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (85, 7, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (86, 10, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (87, 9, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (88, 11, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (89, 12, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (90, 13, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (91, 14, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (92, 16, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (93, 15, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (94, 17, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (95, 18, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (96, 19, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (97, 20, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (98, 21, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (99, 22, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (100, 23, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (101, 32, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (102, 24, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (103, 25, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (104, 26, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (105, 29, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (106, 27, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (107, 28, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (108, 30, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (109, 31, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (110, 33, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (111, 34, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (112, 35, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (113, 36, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (114, 37, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (115, 38, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (116, 40, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (117, 39, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (118, 41, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (119, 41, 4);


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 119, true);


--
-- Data for Name: tipos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_conceptos VALUES (3, 'ASIGNACIONES F.', NULL, NULL);
INSERT INTO public.tipos_conceptos VALUES (1, 'HABERES', 1, 299);
INSERT INTO public.tipos_conceptos VALUES (4, 'CALCULO GANANCIAS', 300, 399);
INSERT INTO public.tipos_conceptos VALUES (2, 'DEDUCCIONES', 500, 599);


--
-- Name: tipos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_conceptos_id_seq', 4, true);


--
-- Data for Name: tipos_contratos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_contratos VALUES (1, 'a tiempo comp.', NULL);
INSERT INTO public.tipos_contratos VALUES (2, 'a tiempo parcial', NULL);


--
-- Name: tipos_contratos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_contratos_id_seq', 1, false);


--
-- Data for Name: tipos_documentos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_documentos VALUES (1, 'DNI');
INSERT INTO public.tipos_documentos VALUES (2, 'CI');
INSERT INTO public.tipos_documentos VALUES (3, 'LE');
INSERT INTO public.tipos_documentos VALUES (4, 'LC');


--
-- Name: tipos_documentos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_documentos_id_seq', 1, false);


--
-- Data for Name: tipos_empleadores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_empleadores VALUES (1, 'Dec 814/01, art. 2, inc. B');


--
-- Name: tipos_empleadores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_empleadores_id_seq', 1, true);


--
-- Data for Name: tipos_liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_liquidaciones VALUES (1, 'Liquidación Mensual Normal', true);
INSERT INTO public.tipos_liquidaciones VALUES (3, '1er Semestre SAC', true);
INSERT INTO public.tipos_liquidaciones VALUES (4, '2do Semestre SAC', true);
INSERT INTO public.tipos_liquidaciones VALUES (5, 'Despido Con Causa', true);
INSERT INTO public.tipos_liquidaciones VALUES (6, 'Despido sin Causa', true);
INSERT INTO public.tipos_liquidaciones VALUES (2, 'Vacaciones', false);


--
-- Name: tipos_liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_liquidaciones_id_seq', 6, true);


--
-- Data for Name: vacaciones; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: vacaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vacaciones_id_seq', 1, false);


--
-- Data for Name: reservadas; Type: TABLE DATA; Schema: sistema; Owner: -
--

INSERT INTO sistema.reservadas VALUES (4, 'diasmes', 'Cantidad del mes', 'Cantidad del mes a liquidar. Tabla: liquidacion.periodo', 'select dias_mes(periodo) as resultado from liquidaciones where id={ID_LIQUIDACION}', NULL, 1, 1, NULL);
INSERT INTO sistema.reservadas VALUES (5, 'tiempocomp', 'Trabaja a tiempo completo', 'Devuelve verdadero si el trabajador tiene contrato a tiempo completo', 'SELECT (id_tipo_contrato=1) as resultado FROM personas WHERE id={ID_PERSONA}', NULL, 2, 2, 'false');
INSERT INTO sistema.reservadas VALUES (6, 'tiempoparc', 'Trabaja a tiempo parcial', 'Devuelve verdadero si el trabajador tiene contrato a tiempo parcial', 'SELECT (id_tipo_contrato=2) as resultado FROM personas WHERE id={ID_PERSONA}', NULL, 2, 2, 'false');
INSERT INTO sistema.reservadas VALUES (7, 'diastrab', 'Dias Trabajados en el mes', 'Cantidad de dias tabajados en el mes', 'SELECT COALESCE(dias_trabajados,0) as resultado 
FROM v_periodos_detalle 
WHERE id_persona={ID_PERSONA} 
AND periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION});', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (3, 'hstrab', 'Total Horas Trabajadas', 'Total de "horas comunes" trabajadas al mes', 'SELECT COALESCE(horas_comunes,0) as resultado 
FROM v_periodos_detalle 
WHERE id_persona={ID_PERSONA} 
	AND periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION});', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (2, 'antiguedad', 'ANTIGUEDAD', 'Trae la antiguedad en años del empleado calculada a la fecha hasta de la liquidacion', 'SELECT antiguedad({ID_PERSONA}, (SELECT fecha_hasta from liquidaciones where id={ID_LIQUIDACION}) ) as resultado;', NULL, 2, 1, '0');
INSERT INTO sistema.reservadas VALUES (12, 'total_deducciones', 'Total deducciones', 'Esta variable se inicializa con 0 y a medida que se calculan los conceptos de DEDUCCIONES se va incrementando.
El valor de la misma puede variar durante la liquidacion. Si se necesita el valor final, debe usarse luego de haberse calculado todos los conceptos de tipo: DEDUCCIONES.', NULL, '0', 2, 4, NULL);
INSERT INTO sistema.reservadas VALUES (11, 'total_vacaciones', 'Total Dias de Vacaciones', 'Devuelve la cantidad de dias que tiene de vacaciones segun la antiguedad calculada a la fecha hasta de la liquidacion', 'SELECT total_vacaciones({ID_PERSONA}, fecha_hasta_liquidacion({ID_LIQUIDACION})) as resultado;', NULL, 2, 1, '0');
INSERT INTO sistema.reservadas VALUES (9, 'bruto', 'BRUTO', 'Este se inicializa en 0 y el liquidador se encarga de ir sumandole los conceptos que sean de haberes REMUNERATIVOS y que tengan el tilde TOTALIZA.
El bruto se puede usar en cualquier momento de la liquidacion, pero  se tiene que tener en cuenta que hasta no termine todo el calculo de haberes este valor puede cambiar', '0', '0', 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (1, 'basico', 'Sueldo Basico', 'Busca el basico particular del empleado y si no lo encuentra trae el de la categoria correspondiente del empleado', 'select (case when basico is not null then basico 
	else (SELECT sueldo_basico FROM categorias WHERE id=id_categoria) end) as resultado 
from personas WHERE id={ID_PERSONA};', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (14, 'inasistencias', 'Cantidad de Inasistencias', 'Devuelve la cantidad de inasistencias que la persona tuvo en el periodo. No se deben cargar las inasistencias justificadas, estas se deben cargar como un dia mas trabajado.', 'SELECT inasistencias as resultado 
FROM v_periodos_detalle 
WHERE periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION})
AND id_persona={ID_PERSONA};', NULL, 2, 1, '0');
INSERT INTO sistema.reservadas VALUES (8, 'hsextras', 'Horas Extras', 'Trae de la planilla del periodo las horas extras.', 'SELECT horas_extras as resultado 
FROM v_periodos_detalle 
WHERE periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION})
AND id_persona={ID_PERSONA};', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (13, 'total_remunerativos2', 'Total de Haberes Remunerativos', 'Calcula el total de haberes remunerativos', NULL, '0', 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (15, 'total_no_remunerativos2', 'Total de haberes no remunerativos', 'Calcula el total de haberes no remunerativos', NULL, '0', 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (10, 'diasvacac', 'Dias de Vacaciones', 'Dias que se toma de Vacaciones en el mes', 'SELECT COALESCE(dias_vacaciones,0) as resultado 
FROM v_periodos_detalle 
WHERE id_persona={ID_PERSONA} 
AND periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION});', NULL, 2, 1, '0');
INSERT INTO sistema.reservadas VALUES (16, 'casado', 'Devuelve verdadero si es casado', 'Busca que el estado civil sea igual a CASADO/A', 'SELECT CASE WHEN id_estado_civil=2 THEN 1 ELSE 0 END as resultado 
FROM personas 
WHERE id={ID_PERSONA};', NULL, 2, 2, '0');
INSERT INTO sistema.reservadas VALUES (17, 'hijos', 'Devuelve la cantidad de hijos', 'Devuelve la cantidad de hijos del empleado', 'SELECT cant_hijos as resultado 
FROM personas 
WHERE id={ID_PERSONA};', NULL, 2, 1, '0');
INSERT INTO sistema.reservadas VALUES (18, 'ganancia_neta_acumulada', 'Ganancia Neta Acumulada', 'Calcula la Ganancia Neta Acumulada desde el mes 1 hasta el periodo de la liquidación.
Suma el concepto de "Ganancia Neta Mensual" de cada mes (código 321).', 'select sum(importe) as resultado 
from v_recibos_conceptos 
where id_persona={ID_PERSONA} and codigo=''321''
and anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION});', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (19, 'ganancia_acumulada', 'Ganancia Acumulada', 'Calcula la Ganancia Acumulada (la que se muestra en el recibo) desde el mes 1 hasta el periodo de la liquidación.
Suma el concepto de "" de cada mes (código 515).', 'select sum(importe) as resultado 
from v_recibos_conceptos 
where id_persona={ID_PERSONA} and codigo=''515''
and anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION});', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (21, 'maxsueldo1', 'Mayor Sueldo 1er Semestre', 'Devuelve el maximo sueldo_bruto entre ENERO y MAYO.
Toma el valor del acumulador sueldo_bruto.', 'SELECT importe as resultado 
FROM recibos_acumuladores ra
JOIN recibos r ON r.id=ra.id_recibo 
JOIN liquidaciones l ON l.id=r.id_liquidacion
WHERE id_acumulador=3 and r.id_persona={ID_PERSONA} 
and l.anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION}) and mes IN (1,2,3,4,5);', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (22, 'maxsueldo2', 'Mayor Sueldo 2do Semestre', 'Devuelve el maximo sueldo_bruto entre JULIO y NOVIEMBRE.
Toma el valor del acumulador sueldo_bruto.', 'SELECT importe as resultado 
FROM recibos_acumuladores ra
JOIN recibos r ON r.id=ra.id_recibo 
JOIN liquidaciones l ON l.id=r.id_liquidacion
WHERE id_acumulador=3 and r.id_persona={ID_PERSONA} 
and l.anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION}) and mes IN (7,8,9,10,11);', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (23, 'sumsac1', 'SAC proporcional descontado a Mayo', 'SAC proporcional descontado a Mayo', 'SELECT sum(importe) as resultado
FROM v_recibos_conceptos 
WHERE codigo=''301'' AND id_persona={ID_PERSONA} 
AND anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION}) AND mes in (1,2,3,4,5);', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (24, 'sumsac2', 'SAC proporcional descontado a Noviembre', 'SAC proporcional descontado a Noviembre', 'SELECT sum(importe) as resultado
FROM v_recibos_conceptos
WHERE codigo=''301'' AND id_persona={ID_PERSONA} 
AND anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION}) AND mes in (7,8,9,10,11);', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (20, 'calculasac', 'Liquidacion SAC', '', 'SELECT case when id_tipo_liquidacion in (3,4) then true else false end as resultado FROM liquidaciones where id={ID_LIQUIDACION};', NULL, 1, 2, '0');
INSERT INTO sistema.reservadas VALUES (26, 'sumsac', 'SAC proporcional descontado', 'Devuelve el SAC proporcional descontado a Mayo ó  SAC proporcional descontado a Noviembre', 'SELECT CASE 
	WHEN mes=6 THEN
		(SELECT sum(importe) as resultado
		FROM v_recibos_conceptos 
		WHERE codigo=''301'' AND id_persona={ID_PERSONA} 
		AND anio=l.anio AND mes in (1,2,3,4,5))
	WHEN mes =12 THEN
		(SELECT sum(importe) as resultado
		FROM v_recibos_conceptos 
		WHERE codigo=''301'' AND id_persona={ID_PERSONA} 
		AND anio=l.anio and mes IN (7,8,9,10,11))
	END as resultado
FROM liquidaciones l
WHERE l.id={ID_LIQUIDACION};', NULL, 2, 4, '0');
INSERT INTO sistema.reservadas VALUES (25, 'maxsueldo', 'Mayor Sueldo Semestre SAC', 'Calcula el mayor sueldo en el semestre de la liquidacion. 
Se calcula en el mes 6(enero-mayo) y 12(julio-noviembre).', 'SELECT CASE 
	WHEN mes=6 THEN
		(SELECT max(importe) as resultado 
		FROM recibos_acumuladores ra
		JOIN recibos r ON r.id=ra.id_recibo 
		JOIN liquidaciones l1 ON l1.id=r.id_liquidacion
		WHERE id_acumulador=3 and r.id_persona={ID_PERSONA}
		and l1.anio=l.anio and l1.mes IN (1,2,3,4,5))
	WHEN mes =12 THEN
		(SELECT max(importe) as resultado 
		FROM recibos_acumuladores ra
		JOIN recibos r ON r.id=ra.id_recibo 
		JOIN liquidaciones l1 ON l1.id=r.id_liquidacion
		WHERE id_acumulador=3 and r.id_persona={ID_PERSONA}
		and l1.anio=l.anio and l1.mes IN (7,8,9,10,11))
	END as resultado
FROM liquidaciones l
WHERE l.id={ID_LIQUIDACION};', NULL, 2, 4, '0');


--
-- Name: reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.reservadas_id_seq', 26, true);


--
-- Data for Name: tipos_datos; Type: TABLE DATA; Schema: sistema; Owner: -
--

INSERT INTO sistema.tipos_datos VALUES (1, 'INTEGER');
INSERT INTO sistema.tipos_datos VALUES (2, 'BOOLEAN');
INSERT INTO sistema.tipos_datos VALUES (3, 'TEXT');
INSERT INTO sistema.tipos_datos VALUES (4, 'NUMERIC');


--
-- Name: tipos_datos_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.tipos_datos_id_seq', 1, false);


--
-- Data for Name: tipos_reservadas; Type: TABLE DATA; Schema: sistema; Owner: -
--

INSERT INTO sistema.tipos_reservadas VALUES (1, 'LIQUIDACION');
INSERT INTO sistema.tipos_reservadas VALUES (2, 'PERSONA');


--
-- Name: tipos_reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.tipos_reservadas_id_seq', 1, false);


--
-- Name: persona_tareas_id_persona_id_tarea_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT persona_tareas_id_persona_id_tarea_unique UNIQUE (id_persona, id_tarea);


--
-- Name: pk_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT pk_acumuladores PRIMARY KEY (id);


--
-- Name: pk_bancos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bancos
    ADD CONSTRAINT pk_bancos PRIMARY KEY (id);


--
-- Name: pk_categorias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT pk_categorias PRIMARY KEY (id);


--
-- Name: pk_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT pk_conceptos PRIMARY KEY (id);


--
-- Name: pk_conceptos_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT pk_conceptos_personas PRIMARY KEY (id);


--
-- Name: pk_datos_actuales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT pk_datos_actuales PRIMARY KEY (id);


--
-- Name: pk_datos_laborales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT pk_datos_laborales PRIMARY KEY (id);


--
-- Name: pk_datos_salud; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT pk_datos_salud PRIMARY KEY (id);


--
-- Name: pk_establecimientos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT pk_establecimientos PRIMARY KEY (id);


--
-- Name: pk_estados_civiles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_civiles
    ADD CONSTRAINT pk_estados_civiles PRIMARY KEY (id);


--
-- Name: pk_estados_liquidacion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT pk_estados_liquidacion PRIMARY KEY (id);


--
-- Name: pk_feriados; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feriados
    ADD CONSTRAINT pk_feriados PRIMARY KEY (id);


--
-- Name: pk_fichajes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT pk_fichajes PRIMARY KEY (id);


--
-- Name: pk_generos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generos
    ADD CONSTRAINT pk_generos PRIMARY KEY (id);


--
-- Name: pk_liquidaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_liquidaciones
    ADD CONSTRAINT pk_liquidaciones PRIMARY KEY (id);


--
-- Name: pk_liquidaciones2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT pk_liquidaciones2 PRIMARY KEY (id);


--
-- Name: pk_liquidaciones_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT pk_liquidaciones_conceptos PRIMARY KEY (id);


--
-- Name: pk_liquidaciones_conceptos_historico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_liquidaciones_conceptos
    ADD CONSTRAINT pk_liquidaciones_conceptos_historico PRIMARY KEY (id);


--
-- Name: pk_liquidaciones_historico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_liquidaciones
    ADD CONSTRAINT pk_liquidaciones_historico PRIMARY KEY (id);


--
-- Name: pk_localidad; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT pk_localidad PRIMARY KEY (id);


--
-- Name: pk_nacionalidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nacionalidades
    ADD CONSTRAINT pk_nacionalidades PRIMARY KEY (id);


--
-- Name: pk_obras_sociales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obras_sociales
    ADD CONSTRAINT pk_obras_sociales PRIMARY KEY (id);


--
-- Name: pk_paises; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (id);


--
-- Name: pk_periodo_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT pk_periodo_detalle PRIMARY KEY (id);


--
-- Name: pk_periodos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT pk_periodos PRIMARY KEY (id);


--
-- Name: pk_persona_tareas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT pk_persona_tareas PRIMARY KEY (id);


--
-- Name: pk_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT pk_personas PRIMARY KEY (id);


--
-- Name: pk_personas_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT pk_personas_conceptos PRIMARY KEY (id);


--
-- Name: pk_personas_jornadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT pk_personas_jornadas PRIMARY KEY (id);


--
-- Name: pk_provincias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT pk_provincias PRIMARY KEY (id);


--
-- Name: pk_recibos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT pk_recibos PRIMARY KEY (id);


--
-- Name: pk_recibos_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT pk_recibos_acumuladores PRIMARY KEY (id);


--
-- Name: pk_recibos_acumuladores_historico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT pk_recibos_acumuladores_historico PRIMARY KEY (id);


--
-- Name: pk_recibos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos PRIMARY KEY (id);


--
-- Name: pk_recibos_conceptos_historico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos_historico PRIMARY KEY (id);


--
-- Name: pk_recibos_historico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT pk_recibos_historico PRIMARY KEY (id);


--
-- Name: pk_regimenes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regimenes
    ADD CONSTRAINT pk_regimenes PRIMARY KEY (id);


--
-- Name: pk_tabla; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla
    ADD CONSTRAINT pk_tabla PRIMARY KEY (id);


--
-- Name: pk_tabla_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT pk_tabla_detalle PRIMARY KEY (id);


--
-- Name: pk_tabla_ganancias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id);


--
-- Name: pk_tabla_ganancias_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT pk_tabla_ganancias_detalle PRIMARY KEY (id);


--
-- Name: pk_tabla_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT pk_tabla_personas PRIMARY KEY (id);


--
-- Name: pk_tabla_vacaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_vacaciones
    ADD CONSTRAINT pk_tabla_vacaciones PRIMARY KEY (id);


--
-- Name: pk_tabla_vacaciones_dias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_vacaciones_dias
    ADD CONSTRAINT pk_tabla_vacaciones_dias PRIMARY KEY (id);


--
-- Name: pk_tareas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT pk_tareas PRIMARY KEY (id);


--
-- Name: pk_tipo_liquidacion_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT pk_tipo_liquidacion_conceptos PRIMARY KEY (id);


--
-- Name: pk_tipos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_conceptos
    ADD CONSTRAINT pk_tipos_conceptos PRIMARY KEY (id);


--
-- Name: pk_tipos_documentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documentos
    ADD CONSTRAINT pk_tipos_documentos PRIMARY KEY (id);


--
-- Name: pk_tipos_empleadores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_empleadores
    ADD CONSTRAINT pk_tipos_empleadores PRIMARY KEY (id);


--
-- Name: pk_vacaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT pk_vacaciones PRIMARY KEY (id);


--
-- Name: tipos_contratos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_contratos
    ADD CONSTRAINT tipos_contratos_pkey PRIMARY KEY (id);


--
-- Name: uk_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT uk_conceptos UNIQUE (codigo);


--
-- Name: uk_conceptos_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT uk_conceptos_personas UNIQUE (id_concepto, id_persona);


--
-- Name: uk_estados_liquidacion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT uk_estados_liquidacion UNIQUE (descripcion);


--
-- Name: uk_liquidaciones_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT uk_liquidaciones_conceptos UNIQUE (id_concepto, id_liquidacion);


--
-- Name: uk_periodos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT uk_periodos UNIQUE (periodo);


--
-- Name: uk_personas_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT uk_personas_conceptos UNIQUE (id_persona, id_concepto);


--
-- Name: uk_personas_dni; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT uk_personas_dni UNIQUE (id_tipo_documento, nro_documento);


--
-- Name: uk_recibos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT uk_recibos UNIQUE (id_liquidacion, id_persona);


--
-- Name: uk_recibos_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladores UNIQUE (id_recibo, id_acumulador);


--
-- Name: uk_recibos_acumuladoresh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladoresh UNIQUE (id_recibo, id_acumulador);


--
-- Name: uk_recibos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT uk_recibos_conceptos UNIQUE (id_concepto, id_recibo);


--
-- Name: uk_recibos_conceptosh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT uk_recibos_conceptosh UNIQUE (id_concepto, id_recibo);


--
-- Name: uk_recibosh; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT uk_recibosh UNIQUE (id_liquidacion, id_persona);


--
-- Name: uk_tabla; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla
    ADD CONSTRAINT uk_tabla UNIQUE (clave);


--
-- Name: uk_tabla_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT uk_tabla_detalle UNIQUE (id_tabla, anio, mes);


--
-- Name: uk_tabla_ganancias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT uk_tabla_ganancias UNIQUE (anio);


--
-- Name: uk_tabla_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT uk_tabla_personas UNIQUE (id_tabla, anio, mes);


--
-- Name: uk_tipo_liquidacion_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT uk_tipo_liquidacion_conceptos UNIQUE (id_concepto, id_tipo_liquidacion);


--
-- Name: pk_reservadas; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT pk_reservadas PRIMARY KEY (id);


--
-- Name: pk_tipos_datos; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_datos
    ADD CONSTRAINT pk_tipos_datos PRIMARY KEY (id);


--
-- Name: pk_tipos_reservadas; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_reservadas
    ADD CONSTRAINT pk_tipos_reservadas PRIMARY KEY (id);


--
-- Name: trg_ai_liquidaciones_conceptos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ai_liquidaciones_conceptos AFTER INSERT ON public.liquidaciones_conceptos FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_ai_liquidaciones_conceptos();


--
-- Name: trg_ai_recibos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ai_recibos AFTER INSERT ON public.recibos FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_ai_recibos();


--
-- Name: trg_au_liquidaciones; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_au_liquidaciones AFTER UPDATE ON public.liquidaciones FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_au_liquidaciones();


--
-- Name: conceptos_id_tipo_concepto_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT conceptos_id_tipo_concepto_foreign FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);


--
-- Name: establecimientos_id_localidad_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT establecimientos_id_localidad_foreign FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);


--
-- Name: fk_acumuladores__tipo_concepto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT fk_acumuladores__tipo_concepto FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);


--
-- Name: fk_conceptos_personas__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: fk_conceptos_personas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_datos_actuales__estado_civil; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__estado_civil FOREIGN KEY (id_estado_civil) REFERENCES public.estados_civiles(id);


--
-- Name: fk_datos_actuales__peresona; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__peresona FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_datos_actuales_localidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales_localidades FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);


--
-- Name: fk_datos_laborales__categorias; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__categorias FOREIGN KEY (id_categoria) REFERENCES public.categorias(id);


--
-- Name: fk_datos_laborales__establecimiento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__establecimiento FOREIGN KEY (id_establecimiento) REFERENCES public.establecimientos(id);


--
-- Name: fk_datos_laborales__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_datos_laborales__tipos_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__tipos_contratos FOREIGN KEY (id_tipo_contrato) REFERENCES public.tipos_contratos(id);


--
-- Name: fk_datos_salud__obra_social; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__obra_social FOREIGN KEY (id_obra_social) REFERENCES public.obras_sociales(id);


--
-- Name: fk_datos_salud__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_establecimientos__tipo_empleador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT fk_establecimientos__tipo_empleador FOREIGN KEY (id_tipo_empleador) REFERENCES public.tipos_empleadores(id);


--
-- Name: fk_fichajes__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT fk_fichajes__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_liquidacion__estado; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidacion__estado FOREIGN KEY (id_estado) REFERENCES public.estados_liquidacion(id);


--
-- Name: fk_liquidaciones__bancos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__bancos FOREIGN KEY (id_banco) REFERENCES public.bancos(id);


--
-- Name: fk_liquidaciones__tipos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__tipos FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);


--
-- Name: fk_liquidaciones_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: fk_liquidaciones_conceptos__liquidaciones; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);


--
-- Name: fk_liquidaciones_conceptos_h__liquidacionesh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos_h__liquidacionesh FOREIGN KEY (id_liquidacion) REFERENCES public.historico_liquidaciones(id);


--
-- Name: fk_liquidaciones_historico__liquidaciones; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_liquidaciones
    ADD CONSTRAINT fk_liquidaciones_historico__liquidaciones FOREIGN KEY (id) REFERENCES public.liquidaciones(id);


--
-- Name: fk_localidad_provincia; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT fk_localidad_provincia FOREIGN KEY (id_provincia) REFERENCES public.provincias(id);


--
-- Name: fk_periodo_detalle__periodo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__periodo FOREIGN KEY (id_periodo) REFERENCES public.periodos(id);


--
-- Name: fk_periodo_detalle__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_persona__nacionalidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_persona__nacionalidades FOREIGN KEY (id_nacionalidad) REFERENCES public.nacionalidades(id);


--
-- Name: fk_personas__generos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_personas__generos FOREIGN KEY (id_genero) REFERENCES public.generos(id);


--
-- Name: fk_personas_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: fk_personas_conceptos__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_personas_jornadas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT fk_personas_jornadas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_personas_tareas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT fk_personas_tareas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_provincias_pais; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT fk_provincias_pais FOREIGN KEY (id_pais) REFERENCES public.paises(id);


--
-- Name: fk_recibos__liquidaciones; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);


--
-- Name: fk_recibos__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_recibos_acumuladores__acumulador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__acumulador FOREIGN KEY (id_acumulador) REFERENCES public.acumuladores(id);


--
-- Name: fk_recibos_acumuladores__recibo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id);


--
-- Name: fk_recibos_acumuladoresh__reciboh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladoresh__reciboh FOREIGN KEY (id_recibo) REFERENCES public.historico_recibos(id);


--
-- Name: fk_recibos_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: fk_recibos_conceptos__recibo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id);


--
-- Name: fk_recibos_conceptos__reciboh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__reciboh FOREIGN KEY (id_recibo) REFERENCES public.historico_recibos(id);


--
-- Name: fk_recibos_historico__liquidacionesh; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT fk_recibos_historico__liquidacionesh FOREIGN KEY (id_liquidacion) REFERENCES public.historico_liquidaciones(id);


--
-- Name: fk_tabla_detalle__tabla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT fk_tabla_detalle__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);


--
-- Name: fk_tabla_ganancias_detalle__cabecera; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT fk_tabla_ganancias_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES public.tabla_ganancias(id);


--
-- Name: fk_tabla_personas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_tabla_personas__tabla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);


--
-- Name: fk_tipo_liquidacion_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: fk_tipo_liquidacion_conceptos__tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__tipo FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);


--
-- Name: fk_vacaciones__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT fk_vacaciones__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: fk_reservadas__tipos_datos; Type: FK CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_reservadas__tipos_datos FOREIGN KEY (id_tipo_dato) REFERENCES sistema.tipos_datos(id);


--
-- Name: fk_tipos_reservadas__reservadas; Type: FK CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_tipos_reservadas__reservadas FOREIGN KEY (id_tipo_reservada) REFERENCES sistema.tipos_reservadas(id);


--
-- PostgreSQL database dump complete
--

