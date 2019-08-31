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
	establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad)        
	select id,descripcion,periodo,fecha_desde,fecha_hasta,id_tipo_liquidacion,id_establecimiento,id_banco,fecha_pago,
	periodo_depositado,lugar_pago,fecha_deposito,id_estado,mes,anio,nro_recibo_inicial,banco, estado, tipo_liquidacion,
	establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad
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
	IF OLD.id_estado=1 AND NEW.id_estado=2 THEN
		_nro_recibo := NEW.nro_recibo_inicial;
		/* Actualizo los nros de recibo */
		FOR r IN SELECT id FROM recibos WHERE id_liquidacion = new.id
		LOOP				
			UPDATE recibos SET nro_recibo=_nro_recibo WHERE id=r.id;
			_nro_recibo := _nro_recibo + 1;
		END LOOP;
		
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
    actividad text
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
    provincia text
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
    id_liquidacion integer NOT NULL
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
    e.actividad
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

INSERT INTO public.historico_liquidaciones VALUES (75, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 2, 1, 2019, 200, 'Galicia', 'LIQUIDADA', 'Liquidación Mensual Normal', 'Asociación Médica de Luján', 'Mariano Moreno 1460', 'LUJAN', '3450', 'Corrientes', '33539819769', '911200');


--
-- Data for Name: historico_liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_liquidaciones_conceptos VALUES (1350, 1, 75, NULL, 'Sueldo Básico', '1', 'basico', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1351, 7, 75, NULL, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1352, 12, 75, NULL, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1353, 4, 75, NULL, 'Idem Sueldo Basico', '90', 'c1', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1354, 5, 75, NULL, 'Años Reconocimiento', '101', '0', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1355, 6, 75, NULL, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1356, 13, 75, NULL, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1357, 14, 75, 0.00, 'Ganancias - Gratificaciones', '302', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1358, 16, 75, 0.00, 'Ganancias - SAC', '303', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1359, 15, 75, NULL, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1360, 17, 75, NULL, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1361, 18, 75, NULL, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1362, 19, 75, NULL, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1363, 20, 75, NULL, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1364, 21, 75, NULL, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1365, 22, 75, NULL, 'Ganancia Neta Mensual', '321', 'c309-c320', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1366, 23, 75, NULL, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1367, 32, 75, NULL, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1368, 24, 75, NULL, 'Deducción. Especial', '330', 'tabla("especial")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1369, 25, 75, NULL, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1370, 26, 75, NULL, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1371, 29, 75, 0.00, 'Deducciones. Cargas de familia', '333', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1372, 27, 75, NULL, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1373, 28, 75, NULL, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1374, 30, 75, 0.00, 'Deducciones. Servicio doméstico', '336', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1375, 31, 75, NULL, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1376, 33, 75, NULL, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1377, 34, 75, NULL, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1378, 35, 75, NULL, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1379, 36, 75, NULL, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1380, 37, 75, NULL, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1381, 38, 75, NULL, 'Ganancia neta imponible', '360', 'c322 - c350', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1382, 40, 75, NULL, 'Ganancia Escala', '370', 'ganancias(c360)', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1383, 9, 75, NULL, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1384, 10, 75, NULL, 'Obra Social', '502', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1385, 11, 75, NULL, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (1386, 39, 75, NULL, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 'DEDUCCIONES');


--
-- Data for Name: historico_recibos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos VALUES (1081, 204, 12, NULL, NULL, NULL, NULL, NULL, 75, 'Dandrilli', 'Gisela Elizabeth', 34, 'DNI', '30939944', 'Femenino', 2, 'Casado/a', '1984-08-04', 35, NULL, '27309399442', 4, '2DA.ADM', NULL, 50000.00, '2014-02-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1082, 205, 13, NULL, NULL, NULL, NULL, NULL, 75, 'Delgado', 'Noemi Severa', 7, 'DNI', '12904169', 'Femenino', 2, 'Casado/a', '1956-10-27', 62, NULL, '27129041698', 2, '2DA.SUPERV', NULL, 40000.00, '1986-07-14', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1085, 208, 16, NULL, NULL, NULL, NULL, NULL, 75, 'Ferreyra', 'Rodrigo Raul', 32, 'DNI', '34831908', 'Masculino', 1, 'Soltero/a', '1989-10-10', 29, NULL, '20348319087', 4, '2DA.ADM', NULL, 50000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1086, 209, 17, NULL, NULL, NULL, NULL, NULL, 75, 'Frascaroli', 'Micaela Noemi', 19, 'DNI', '29233345', 'Femenino', 1, 'Soltero/a', '1982-02-27', 37, NULL, '27292333450', 2, '2DA.SUPERV', NULL, 40000.00, '2003-10-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1087, 210, 18, NULL, NULL, NULL, NULL, NULL, 75, 'Gallesio', 'Betiana Nazareth', 21, 'DNI', '26167199', 'Femenino', 1, 'Soltero/a', '1978-01-04', 41, NULL, '27261671994', 2, '2DA.SUPERV', NULL, 40000.00, '2006-11-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1089, 212, 20, NULL, NULL, NULL, NULL, NULL, 75, 'Lombardo', 'Norma Elizabeth', 27, 'DNI', '14097779', 'Femenino', 2, 'Casado/a', '1960-11-25', 58, NULL, '27140977794', 2, '2DA.SUPERV', NULL, 40000.00, '2009-08-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1090, 213, 21, NULL, NULL, NULL, NULL, NULL, 75, 'Paccor', 'Maria Soledad', 35, 'DNI', '27033687', 'Femenino', 1, 'Soltero/a', '1979-03-05', 40, NULL, '27270336871', 3, '1RA.ADM', NULL, 60000.00, '2014-11-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1091, 214, 22, NULL, NULL, NULL, NULL, NULL, 75, 'Paris', 'Alejandra', 39, 'DNI', '30939775', 'Femenino', 1, 'Soltero/a', '1984-05-06', 35, NULL, '23309397754', 3, '1RA.ADM', NULL, 60000.00, '2016-07-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1092, 215, 23, NULL, NULL, NULL, NULL, NULL, 75, 'Parra', 'Jorgelina', 23, 'DNI', '25048843', 'Femenino', 1, 'Soltero/a', '1976-05-11', 43, NULL, '27250488438', 3, '1RA.ADM', NULL, 60000.00, '2007-07-02', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1094, 217, 25, NULL, NULL, NULL, NULL, NULL, 75, 'Riccardo', 'Lautaro', 33, 'DNI', '32378152', 'Masculino', 1, 'Soltero/a', '1986-05-29', 33, NULL, '20323781525', 3, '1RA.ADM', NULL, 60000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1095, 218, 26, NULL, NULL, NULL, NULL, NULL, 75, 'Romero', 'Ana Gladys', 3, 'DNI', '18148598', 'Femenino', 3, 'Divorciado/a', '1966-05-04', 53, NULL, '27181485987', 1, '1RA.SUPERV', NULL, 50000.00, '1986-11-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1093, 216, 24, NULL, NULL, NULL, NULL, NULL, 75, 'Poletti', 'Norma', 2, 'DNI', '18601061', 'Femenino', 2, 'Casado/a', '1967-11-07', 51, NULL, '27186010618', 2, '2DA.SUPERV', NULL, 40000.00, '1986-09-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1084, 207, 15, NULL, NULL, NULL, NULL, NULL, 75, 'Ferrari', 'Maria Cecilia', 26, 'DNI', '29594863', 'Femenino', 1, 'Soltero/a', '1982-07-25', 37, NULL, '27295948634', 3, '1RA.ADM', NULL, 60000.00, '2008-02-20', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1083, 206, 14, NULL, NULL, NULL, NULL, NULL, 75, 'Echenique', 'Cesar Anibal', 37, 'DNI', '27113644', 'Masculino', 1, 'Soltero/a', '1978-12-24', 40, NULL, '20271136448', 3, '1RA.ADM', NULL, 60000.00, '2015-06-01', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1088, 211, 19, NULL, NULL, NULL, NULL, NULL, 75, 'Herrera', 'Claudia Fabiana', 10, 'DNI', '16833436', 'Femenino', 2, 'Casado/a', '1965-04-28', 54, NULL, '27168334368', 3, '1RA.ADM', 'ay.sub area', 60000.00, '1984-08-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1096, 219, 7, NULL, NULL, NULL, NULL, NULL, 75, 'Zeppa', 'Silvio', 40, 'DNI', '26563056', 'Masculino', 2, 'Casado/a', '1978-05-20', 41, NULL, '20265630562', 4, '2DA.ADM', NULL, 50000.00, '2017-04-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1078, 201, 9, NULL, NULL, NULL, NULL, NULL, 75, 'Becaj', 'Ivan Guillermo', 31, 'DNI', '26583833', 'Masculino', 1, 'Soltero/a', '1978-05-01', 41, NULL, '20265838333', 2, '2DA.SUPERV', NULL, 40000.00, '2013-06-03', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1079, 202, 10, NULL, NULL, NULL, NULL, NULL, 75, 'Cano', 'Silvia Marina', 5, 'DNI', '14490100', 'Femenino', 2, 'Casado/a', '1960-12-22', 58, NULL, '27144901008', 2, '2DA.SUPERV', NULL, 40000.00, '1988-12-01', NULL, 1, 'a tiempo comp.', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1080, 203, 11, NULL, NULL, NULL, NULL, NULL, 75, 'Cespedes Ramirez', 'Teresita', 8, 'DNI', '92727141', 'Femenino', 3, 'Divorciado/a', '1965-05-20', 54, NULL, '27927271414', 5, 'Maestranza', NULL, 35000.00, '2010-03-01', NULL, 2, 'a tiempo parcial', NULL, NULL, NULL, 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');
INSERT INTO public.historico_recibos VALUES (1077, 200, 8, NULL, NULL, NULL, NULL, NULL, 75, 'Acosta', 'Claudio Daniel', 29, 'DNI', '26823601', 'Masculino', 2, 'Casado/a', '1978-07-18', 41, NULL, '20268236016', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2011-04-06', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes');


--
-- Data for Name: historico_recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_acumuladores VALUES (3861, 1, 39080.00, 1096, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3862, 2, 0.00, 1096, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3863, 3, 39080.00, 1096, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3864, 4, 0.00, 1096, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3865, 5, 12114.80, 1096, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3866, 1, 42595.49, 1077, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3867, 2, 0.00, 1077, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3868, 3, 42595.49, 1077, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3869, 4, 0.00, 1077, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3870, 5, 13204.60, 1077, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3871, 1, 49210.57, 1078, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3872, 2, 0.00, 1078, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3873, 3, 49210.57, 1078, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3874, 4, 0.00, 1078, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3875, 5, 15255.28, 1078, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3876, 1, 79572.58, 1079, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3877, 2, 0.00, 1079, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3878, 3, 79572.58, 1079, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3879, 4, 0.00, 1079, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3880, 5, 24667.50, 1079, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3881, 1, 30317.40, 1080, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3882, 2, 0.00, 1080, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3883, 3, 30317.40, 1080, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3884, 4, 0.00, 1080, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3885, 5, 9398.39, 1080, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3886, 1, 41567.27, 1081, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3887, 2, 0.00, 1081, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3888, 3, 41567.27, 1081, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3889, 4, 0.00, 1081, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3890, 5, 12885.85, 1081, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3891, 1, 84533.20, 1082, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3892, 2, 0.00, 1082, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3893, 3, 84533.20, 1082, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3894, 4, 0.00, 1082, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3895, 5, 26205.29, 1082, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3896, 1, 20010.00, 1083, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3897, 2, 0.00, 1083, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3898, 3, 20010.00, 1083, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3899, 4, 0.00, 1083, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3900, 5, 6203.10, 1083, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3901, 1, 78000.00, 1084, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3902, 2, 0.00, 1084, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3903, 3, 78000.00, 1084, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3904, 4, 0.00, 1084, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3905, 5, 24180.00, 1084, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3906, 1, 42039.72, 1085, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3907, 2, 0.00, 1085, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3908, 3, 42039.72, 1085, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3909, 4, 0.00, 1085, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3910, 5, 13032.31, 1085, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3911, 1, 65574.74, 1086, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3912, 2, 0.00, 1086, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3913, 3, 65574.74, 1086, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3914, 4, 0.00, 1086, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3915, 5, 20328.17, 1086, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3916, 1, 57173.51, 1087, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3917, 2, 0.00, 1087, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3918, 3, 57173.51, 1087, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3919, 4, 0.00, 1087, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3920, 5, 17723.79, 1087, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3921, 1, 77302.08, 1088, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3922, 2, 0.00, 1088, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3923, 3, 77302.08, 1088, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3924, 4, 0.00, 1088, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3925, 5, 23963.64, 1088, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3926, 1, 54678.40, 1089, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3927, 2, 0.00, 1089, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3928, 3, 54678.40, 1089, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3929, 4, 0.00, 1089, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3930, 5, 16950.30, 1089, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3931, 1, 45027.03, 1090, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3932, 2, 0.00, 1090, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3933, 3, 45027.03, 1090, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3934, 4, 0.00, 1090, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3935, 5, 13958.38, 1090, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3936, 1, 17971.76, 1091, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3937, 2, 0.00, 1091, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3938, 3, 17971.76, 1091, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3939, 4, 0.00, 1091, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3940, 5, 5571.24, 1091, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3941, 1, 51617.28, 1092, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3942, 2, 0.00, 1092, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3943, 3, 51617.28, 1092, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3944, 4, 0.00, 1092, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3945, 5, 16001.36, 1092, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3946, 1, 79950.39, 1093, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3947, 2, 0.00, 1093, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3948, 3, 79950.39, 1093, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3949, 4, 0.00, 1093, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3950, 5, 24784.62, 1093, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3951, 1, 41950.56, 1094, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3952, 2, 0.00, 1094, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3953, 3, 41950.56, 1094, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3954, 4, 0.00, 1094, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3955, 5, 13004.67, 1094, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3956, 1, 99287.36, 1095, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3957, 2, 0.00, 1095, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3958, 3, 99287.36, 1095, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3959, 4, 0.00, 1095, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (3960, 5, 30779.08, 1095, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');


--
-- Data for Name: historico_recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_conceptos VALUES (27160, 14, 0.00, 1077, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27161, 16, 0.00, 1077, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27174, 29, 0.00, 1077, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27177, 30, 0.00, 1077, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27197, 14, 0.00, 1078, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27198, 16, 0.00, 1078, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27211, 29, 0.00, 1078, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27214, 30, 0.00, 1078, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27234, 14, 0.00, 1079, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27235, 16, 0.00, 1079, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27248, 29, 0.00, 1079, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27251, 30, 0.00, 1079, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27271, 14, 0.00, 1080, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27272, 16, 0.00, 1080, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27285, 29, 0.00, 1080, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27288, 30, 0.00, 1080, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27308, 14, 0.00, 1081, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27309, 16, 0.00, 1081, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27322, 29, 0.00, 1081, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27325, 30, 0.00, 1081, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27345, 14, 0.00, 1082, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27346, 16, 0.00, 1082, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27359, 29, 0.00, 1082, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27362, 30, 0.00, 1082, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27382, 14, 0.00, 1083, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27383, 16, 0.00, 1083, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27396, 29, 0.00, 1083, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27399, 30, 0.00, 1083, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27419, 14, 0.00, 1084, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27420, 16, 0.00, 1084, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27433, 29, 0.00, 1084, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27436, 30, 0.00, 1084, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27456, 14, 0.00, 1085, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27457, 16, 0.00, 1085, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27470, 29, 0.00, 1085, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27473, 30, 0.00, 1085, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27493, 14, 0.00, 1086, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27494, 16, 0.00, 1086, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27507, 29, 0.00, 1086, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27510, 30, 0.00, 1086, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27530, 14, 0.00, 1087, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27531, 16, 0.00, 1087, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27544, 29, 0.00, 1087, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27547, 30, 0.00, 1087, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27564, 5, 3.00, 1088, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27567, 14, 0.00, 1088, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27568, 16, 0.00, 1088, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27581, 29, 0.00, 1088, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27584, 30, 0.00, 1088, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27604, 14, 0.00, 1089, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27605, 16, 0.00, 1089, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27618, 29, 0.00, 1089, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27621, 30, 0.00, 1089, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27641, 14, 0.00, 1090, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27642, 16, 0.00, 1090, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27655, 29, 0.00, 1090, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27658, 30, 0.00, 1090, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27678, 14, 0.00, 1091, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27679, 16, 0.00, 1091, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27692, 29, 0.00, 1091, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27695, 30, 0.00, 1091, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27715, 14, 0.00, 1092, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27716, 16, 0.00, 1092, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27729, 29, 0.00, 1092, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27732, 30, 0.00, 1092, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27752, 14, 0.00, 1093, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27753, 16, 0.00, 1093, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27766, 29, 0.00, 1093, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27769, 30, 0.00, 1093, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27789, 14, 0.00, 1094, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27790, 16, 0.00, 1094, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27803, 29, 0.00, 1094, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27806, 30, 0.00, 1094, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27826, 14, 0.00, 1095, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27827, 16, 0.00, 1095, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27840, 29, 0.00, 1095, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27843, 30, 0.00, 1095, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27863, 14, 0.00, 1096, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27864, 16, 0.00, 1096, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27877, 29, 0.00, 1096, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27880, 30, 0.00, 1096, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27153, 1, 34351.20, 1077, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27154, 7, 0.00, 1077, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27155, 12, 3435.12, 1077, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27156, 4, 34351.20, 1077, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27157, 5, 0.00, 1077, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27158, 6, 4809.17, 1077, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27159, 13, 3549.62, 1077, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27162, 15, 46145.11, 1077, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27163, 17, 5075.96, 1077, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27164, 18, 1384.35, 1077, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27165, 19, 1384.35, 1077, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27166, 20, 1153.63, 1077, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27167, 21, 8998.30, 1077, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27168, 22, 37146.82, 1077, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27169, 23, 37146.82, 1077, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27170, 32, 1857.34, 1077, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27171, 24, 34339.60, 1077, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27172, 25, 6669.50, 1077, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27173, 26, 0.00, 1077, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27175, 27, 7154.08, 1077, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27176, 28, 0.00, 1077, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27178, 31, 0.00, 1077, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27179, 33, 0.00, 1077, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27180, 34, 0.00, 1077, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27181, 35, 0.00, 1077, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27182, 36, 0.00, 1077, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27183, 37, 48163.18, 1077, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27184, 38, -11016.36, 1077, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27185, 40, 0.00, 1077, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27186, 9, 1277.86, 1077, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27187, 10, 1277.86, 1077, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27188, 11, 10648.87, 1077, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27189, 39, 0.00, 1077, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27190, 1, 41008.81, 1078, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27191, 7, 0.00, 1078, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27192, 12, 4100.88, 1078, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27193, 4, 41008.81, 1078, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27194, 5, 0.00, 1078, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27195, 6, 4100.88, 1078, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27196, 13, 4100.88, 1078, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27199, 15, 53311.45, 1078, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27200, 17, 5864.26, 1078, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27201, 18, 1599.34, 1078, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27202, 19, 1599.34, 1078, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27203, 20, 1332.79, 1078, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27204, 21, 10395.73, 1078, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27205, 22, 42915.72, 1078, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27206, 23, 42915.72, 1078, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27207, 32, 2145.79, 1078, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27208, 24, 34339.60, 1078, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27209, 25, 0.00, 1078, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27210, 26, 0.00, 1078, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27212, 27, 7154.08, 1078, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27213, 28, 0.00, 1078, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27215, 31, 2145.79, 1078, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27216, 33, 0.00, 1078, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27217, 34, 0.00, 1078, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27218, 35, 0.00, 1078, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27219, 36, 0.00, 1078, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27220, 37, 43639.47, 1078, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27221, 38, -723.75, 1078, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27222, 40, 0.00, 1078, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27223, 9, 1476.32, 1078, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27224, 10, 1476.32, 1078, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27225, 11, 12302.64, 1078, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27226, 39, 0.00, 1078, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27227, 1, 46807.40, 1079, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27228, 7, 0.00, 1079, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27229, 12, 4680.74, 1079, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27230, 4, 46807.40, 1079, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27231, 5, 0.00, 1079, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27232, 6, 28084.44, 1079, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27233, 13, 6631.05, 1079, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27236, 15, 86203.63, 1079, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27237, 17, 9482.40, 1079, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27238, 18, 2586.11, 1079, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27239, 19, 2586.11, 1079, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27240, 20, 2155.09, 1079, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27241, 21, 16809.71, 1079, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27242, 22, 69393.92, 1079, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27243, 23, 69393.92, 1079, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27244, 32, 3469.70, 1079, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27245, 24, 34339.60, 1079, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27246, 25, 6669.50, 1079, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27247, 26, 0.00, 1079, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27249, 27, 7154.08, 1079, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27250, 28, 0.00, 1079, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27252, 31, 0.00, 1079, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27253, 33, 0.00, 1079, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27254, 34, 0.00, 1079, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27255, 35, 0.00, 1079, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27256, 36, 0.00, 1079, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27257, 37, 48163.18, 1079, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27258, 38, 21230.74, 1079, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27259, 40, 110524.46, 1079, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27260, 9, 2387.18, 1079, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27261, 10, 2387.18, 1079, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27262, 11, 19893.15, 1079, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27263, 39, 110524.46, 1079, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27264, 1, 24061.43, 1080, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27265, 7, 0.00, 1080, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27447, 11, 19500.00, 1084, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27266, 12, 2406.14, 1080, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27267, 4, 24061.43, 1080, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27268, 5, 0.00, 1080, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27269, 6, 3849.83, 1080, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27270, 13, 2526.45, 1080, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27273, 15, 32843.85, 1080, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27274, 17, 3612.82, 1080, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27275, 18, 985.32, 1080, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27276, 19, 985.32, 1080, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27277, 20, 821.10, 1080, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27278, 21, 6404.55, 1080, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27279, 22, 26439.30, 1080, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27280, 23, 26439.30, 1080, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27281, 32, 1321.97, 1080, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27282, 24, 34339.60, 1080, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27283, 25, 0.00, 1080, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27284, 26, 0.00, 1080, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27286, 27, 7154.08, 1080, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27287, 28, 0.00, 1080, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27289, 31, 0.00, 1080, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27290, 33, 0.00, 1080, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27291, 34, 0.00, 1080, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27292, 35, 0.00, 1080, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27293, 36, 0.00, 1080, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27294, 37, 41493.68, 1080, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27295, 38, -15054.38, 1080, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27296, 40, 0.00, 1080, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27297, 9, 909.52, 1080, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27298, 10, 909.52, 1080, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27299, 11, 7579.35, 1080, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27300, 39, 0.00, 1080, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27301, 1, 35226.50, 1081, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27302, 7, 0.00, 1081, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27303, 12, 3522.65, 1081, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27304, 4, 35226.50, 1081, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27305, 5, 0.00, 1081, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27306, 6, 2818.12, 1081, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27307, 13, 3463.94, 1081, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27310, 15, 45031.21, 1081, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27311, 17, 4953.43, 1081, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27312, 18, 1350.94, 1081, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27313, 19, 1350.94, 1081, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27314, 20, 1125.78, 1081, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27315, 21, 8781.09, 1081, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27316, 22, 36250.12, 1081, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27317, 23, 36250.12, 1081, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27318, 32, 1812.51, 1081, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27319, 24, 34339.60, 1081, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27320, 25, 6669.50, 1081, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27321, 26, 0.00, 1081, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27323, 27, 7154.08, 1081, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27324, 28, 0.00, 1081, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27326, 31, 0.00, 1081, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27327, 33, 0.00, 1081, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27388, 20, 541.94, 1083, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27328, 34, 0.00, 1081, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27329, 35, 0.00, 1081, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27330, 36, 0.00, 1081, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27331, 37, 48163.18, 1081, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27332, 38, -11913.06, 1081, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27333, 40, 0.00, 1081, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27334, 9, 1247.02, 1081, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27335, 10, 1247.02, 1081, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27336, 11, 10391.82, 1081, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27337, 39, 0.00, 1081, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27338, 1, 48582.30, 1082, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27339, 7, 0.00, 1082, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27340, 12, 4858.23, 1082, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27341, 4, 48582.30, 1082, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27342, 5, 0.00, 1082, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27343, 6, 31092.67, 1082, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27344, 13, 7044.43, 1082, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27347, 15, 91577.64, 1082, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27348, 17, 10073.54, 1082, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27349, 18, 2747.33, 1082, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27350, 19, 2747.33, 1082, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27351, 20, 2289.44, 1082, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27352, 21, 17857.64, 1082, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27353, 22, 73720.00, 1082, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27354, 23, 73720.00, 1082, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27355, 32, 3686.00, 1082, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27356, 24, 34339.60, 1082, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27357, 25, 6669.50, 1082, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27358, 26, 0.00, 1082, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27360, 27, 7154.08, 1082, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27361, 28, 0.00, 1082, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27363, 31, 0.00, 1082, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27364, 33, 0.00, 1082, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27365, 34, 0.00, 1082, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27366, 35, 0.00, 1082, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27367, 36, 0.00, 1082, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27368, 37, 48163.18, 1082, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27369, 38, 25556.82, 1082, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27370, 40, 98759.12, 1082, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27371, 9, 2536.00, 1082, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27372, 10, 2536.00, 1082, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27373, 11, 21133.30, 1082, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27374, 39, 98759.12, 1082, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27375, 1, 17250.00, 1083, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27376, 7, 0.00, 1083, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27377, 12, 1725.00, 1083, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27378, 4, 17250.00, 1083, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27379, 5, 0.00, 1083, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27380, 6, 1035.00, 1083, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27381, 13, 1667.50, 1083, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27384, 15, 21677.50, 1083, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27385, 17, 2384.53, 1083, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27386, 18, 650.33, 1083, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27387, 19, 650.33, 1083, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27389, 21, 4227.11, 1083, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27390, 22, 17450.39, 1083, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27391, 23, 17450.39, 1083, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27392, 32, 872.52, 1083, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27393, 24, 34339.60, 1083, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27394, 25, 0.00, 1083, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27395, 26, 0.00, 1083, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27397, 27, 7154.08, 1083, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27398, 28, 0.00, 1083, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27400, 31, 0.00, 1083, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27401, 33, 0.00, 1083, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27402, 34, 0.00, 1083, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27403, 35, 0.00, 1083, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27404, 36, 0.00, 1083, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27405, 37, 41493.68, 1083, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27406, 38, -24043.29, 1083, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27407, 40, 0.00, 1083, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27408, 9, 600.30, 1083, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27409, 10, 600.30, 1083, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27410, 11, 5002.50, 1083, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27411, 39, 0.00, 1083, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27412, 1, 60000.00, 1084, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27413, 7, 0.00, 1084, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27414, 12, 6000.00, 1084, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27415, 4, 60000.00, 1084, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27416, 5, 0.00, 1084, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27417, 6, 12000.00, 1084, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27418, 13, 6500.00, 1084, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27421, 15, 84500.00, 1084, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27422, 17, 9295.00, 1084, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27423, 18, 2535.00, 1084, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27424, 19, 2535.00, 1084, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27425, 20, 2112.50, 1084, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27426, 21, 16477.50, 1084, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27427, 22, 68022.50, 1084, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27428, 23, 68022.50, 1084, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27429, 32, 3401.13, 1084, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27430, 24, 34339.60, 1084, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27431, 25, 0.00, 1084, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27432, 26, 0.00, 1084, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27434, 27, 7154.08, 1084, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27435, 28, 0.00, 1084, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27437, 31, 0.00, 1084, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27438, 33, 0.00, 1084, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27439, 34, 0.00, 1084, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27440, 35, 0.00, 1084, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27441, 36, 0.00, 1084, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27442, 37, 41493.68, 1084, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27443, 38, 26528.82, 1084, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27444, 40, 125003.21, 1084, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27445, 9, 2340.00, 1084, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27446, 10, 2340.00, 1084, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27448, 39, 125003.21, 1084, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27449, 1, 35033.10, 1085, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27450, 7, 0.00, 1085, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27451, 12, 3503.31, 1085, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27452, 4, 35033.10, 1085, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27453, 5, 0.00, 1085, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27454, 6, 3503.31, 1085, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27455, 13, 3503.31, 1085, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27458, 15, 45543.03, 1085, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27459, 17, 5009.73, 1085, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27460, 18, 1366.29, 1085, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27461, 19, 1366.29, 1085, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27462, 20, 1138.58, 1085, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27463, 21, 8880.89, 1085, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27464, 22, 36662.14, 1085, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27465, 23, 36662.14, 1085, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27466, 32, 1833.11, 1085, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27467, 24, 34339.60, 1085, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27468, 25, 0.00, 1085, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27469, 26, 0.00, 1085, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27471, 27, 7154.08, 1085, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27472, 28, 0.00, 1085, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27474, 31, 0.00, 1085, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27475, 33, 0.00, 1085, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27476, 34, 0.00, 1085, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27477, 35, 0.00, 1085, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27478, 36, 0.00, 1085, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27479, 37, 41493.68, 1085, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27480, 38, -4831.54, 1085, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27481, 40, 0.00, 1085, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27482, 9, 1261.19, 1085, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27483, 10, 1261.19, 1085, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27484, 11, 10509.93, 1085, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27485, 39, 0.00, 1085, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27486, 1, 46839.10, 1086, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27487, 7, 0.00, 1086, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27488, 12, 4683.91, 1086, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27489, 4, 46839.10, 1086, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27490, 5, 0.00, 1086, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27491, 6, 14051.73, 1086, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27492, 13, 5464.56, 1086, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27495, 15, 71039.30, 1086, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27496, 17, 7814.32, 1086, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27497, 18, 2131.18, 1086, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27498, 19, 2131.18, 1086, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27499, 20, 1775.98, 1086, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27500, 21, 13852.66, 1086, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27501, 22, 57186.64, 1086, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27502, 23, 57186.64, 1086, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27503, 32, 2859.33, 1086, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27504, 24, 34339.60, 1086, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27505, 25, 0.00, 1086, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27506, 26, 0.00, 1086, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27508, 27, 7154.08, 1086, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27509, 28, 0.00, 1086, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27511, 31, 0.00, 1086, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27512, 33, 0.00, 1086, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27513, 34, 0.00, 1086, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27514, 35, 0.00, 1086, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27515, 36, 0.00, 1086, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27516, 37, 41493.68, 1086, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27517, 38, 15692.96, 1086, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27518, 40, 90042.93, 1086, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27519, 9, 1967.24, 1086, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27520, 10, 1967.24, 1086, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27521, 11, 16393.69, 1086, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27522, 39, 90042.93, 1086, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27523, 1, 42666.80, 1087, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27524, 7, 0.00, 1087, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27525, 12, 4266.68, 1087, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27526, 4, 42666.80, 1087, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27527, 5, 0.00, 1087, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27528, 6, 10240.03, 1087, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27529, 13, 4764.46, 1087, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27532, 15, 61937.97, 1087, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27533, 17, 6813.18, 1087, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27534, 18, 1858.14, 1087, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27535, 19, 1858.14, 1087, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27536, 20, 1548.45, 1087, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27537, 21, 12077.90, 1087, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27538, 22, 49860.07, 1087, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27539, 23, 49860.07, 1087, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27540, 32, 2493.00, 1087, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27541, 24, 34339.60, 1087, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27542, 25, 0.00, 1087, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27543, 26, 0.00, 1087, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27545, 27, 7154.08, 1087, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27546, 28, 0.00, 1087, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27548, 31, 0.00, 1087, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27549, 33, 0.00, 1087, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27550, 34, 0.00, 1087, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27551, 35, 0.00, 1087, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27552, 36, 0.00, 1087, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27553, 37, 41493.68, 1087, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27554, 38, 8366.39, 1087, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27555, 40, 2312.41, 1087, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27556, 9, 1715.21, 1087, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27557, 10, 1715.21, 1087, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27558, 11, 14293.38, 1087, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27559, 39, 2312.41, 1087, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27560, 1, 42012.00, 1088, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27561, 7, 0.00, 1088, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27562, 12, 4201.20, 1088, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27563, 4, 42012.00, 1088, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27565, 6, 31088.88, 1088, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27566, 13, 6441.84, 1088, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27569, 15, 83743.92, 1088, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27570, 17, 9211.83, 1088, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27571, 18, 2512.32, 1088, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27572, 19, 2512.32, 1088, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27573, 20, 2093.60, 1088, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27574, 21, 16330.06, 1088, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27575, 22, 67413.86, 1088, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27576, 23, 67413.86, 1088, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27577, 32, 3370.69, 1088, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27578, 24, 34339.60, 1088, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27579, 25, 6669.50, 1088, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27580, 26, 0.00, 1088, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27582, 27, 7154.08, 1088, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27583, 28, 0.00, 1088, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27585, 31, 0.00, 1088, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27586, 33, 0.00, 1088, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27587, 34, 0.00, 1088, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27588, 35, 0.00, 1088, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27589, 36, 0.00, 1088, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27590, 37, 48163.18, 1088, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27591, 38, 19250.68, 1088, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27592, 40, 64982.96, 1088, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27593, 9, 2319.06, 1088, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27594, 10, 2319.06, 1088, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27595, 11, 19325.52, 1088, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27596, 39, 64982.96, 1088, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27597, 1, 42717.50, 1089, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27598, 7, 0.00, 1089, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27599, 12, 4271.75, 1089, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27600, 4, 42717.50, 1089, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27601, 5, 0.00, 1089, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27602, 6, 7689.15, 1089, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27603, 13, 4556.53, 1089, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27606, 15, 59234.93, 1089, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27607, 17, 6515.84, 1089, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27608, 18, 1777.05, 1089, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27609, 19, 1777.05, 1089, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27610, 20, 1480.87, 1089, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27611, 21, 11550.81, 1089, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27612, 22, 47684.12, 1089, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27613, 23, 47684.12, 1089, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27614, 32, 2384.21, 1089, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27615, 24, 34339.60, 1089, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27616, 25, 6669.50, 1089, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27617, 26, 0.00, 1089, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27619, 27, 7154.08, 1089, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27620, 28, 0.00, 1089, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27622, 31, 0.00, 1089, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27623, 33, 0.00, 1089, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27624, 34, 0.00, 1089, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27625, 35, 0.00, 1089, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27626, 36, 0.00, 1089, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27627, 37, 48163.18, 1089, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27628, 38, -479.06, 1089, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27629, 40, 0.00, 1089, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27630, 9, 1640.35, 1089, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27631, 10, 1640.35, 1089, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27632, 11, 13669.60, 1089, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27633, 39, 0.00, 1089, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27634, 1, 38158.50, 1090, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27635, 7, 0.00, 1090, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27636, 12, 3815.85, 1090, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27637, 4, 38158.50, 1090, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27638, 5, 0.00, 1090, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27639, 6, 3052.68, 1090, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27640, 13, 3752.25, 1090, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27643, 15, 48779.28, 1090, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27644, 17, 5365.72, 1090, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27645, 18, 1463.38, 1090, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27646, 19, 1463.38, 1090, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27647, 20, 1219.48, 1090, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27648, 21, 9511.96, 1090, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27649, 22, 39267.32, 1090, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27650, 23, 39267.32, 1090, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27651, 32, 1963.37, 1090, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27652, 24, 34339.60, 1090, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27653, 25, 0.00, 1090, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27654, 26, 0.00, 1090, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27656, 27, 7154.08, 1090, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27657, 28, 0.00, 1090, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27659, 31, 0.00, 1090, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27660, 33, 0.00, 1090, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27661, 34, 0.00, 1090, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27662, 35, 0.00, 1090, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27663, 36, 0.00, 1090, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27664, 37, 41493.68, 1090, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27665, 38, -2226.36, 1090, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27666, 40, 0.00, 1090, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27667, 9, 1350.81, 1090, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27668, 10, 1350.81, 1090, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27669, 11, 11256.76, 1090, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27670, 39, 0.00, 1090, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27671, 1, 15764.70, 1091, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27672, 7, 0.00, 1091, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27673, 12, 1576.47, 1091, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27674, 4, 15764.70, 1091, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27675, 5, 0.00, 1091, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27676, 6, 630.59, 1091, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27677, 13, 1497.65, 1091, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27680, 15, 19469.40, 1091, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27681, 17, 2141.63, 1091, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27682, 18, 584.08, 1091, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27683, 19, 584.08, 1091, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27684, 20, 486.74, 1091, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27685, 21, 3796.53, 1091, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27686, 22, 15672.87, 1091, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27687, 23, 15672.87, 1091, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27688, 32, 783.64, 1091, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27689, 24, 34339.60, 1091, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27690, 25, 0.00, 1091, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27691, 26, 0.00, 1091, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27693, 27, 7154.08, 1091, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27694, 28, 0.00, 1091, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27696, 31, 0.00, 1091, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27697, 33, 0.00, 1091, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27698, 34, 0.00, 1091, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27699, 35, 0.00, 1091, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27700, 36, 0.00, 1091, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27701, 37, 41493.68, 1091, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27702, 38, -25820.81, 1091, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27703, 40, 0.00, 1091, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27704, 9, 539.15, 1091, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27705, 10, 539.15, 1091, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27706, 11, 4492.94, 1091, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27707, 39, 0.00, 1091, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27708, 1, 39104.00, 1092, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27709, 7, 0.00, 1092, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27710, 12, 3910.40, 1092, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27711, 4, 39104.00, 1092, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27712, 5, 0.00, 1092, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27713, 6, 8602.88, 1092, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27714, 13, 4301.44, 1092, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27717, 15, 55918.72, 1092, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27718, 17, 6151.06, 1092, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27719, 18, 1677.56, 1092, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27720, 19, 1677.56, 1092, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27721, 20, 1397.97, 1092, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27722, 21, 10904.15, 1092, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27723, 22, 45014.57, 1092, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27724, 23, 45014.57, 1092, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27725, 32, 2250.73, 1092, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27726, 24, 34339.60, 1092, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27727, 25, 0.00, 1092, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27728, 26, 0.00, 1092, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27730, 27, 7154.08, 1092, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27731, 28, 0.00, 1092, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27733, 31, 0.00, 1092, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27734, 33, 0.00, 1092, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27735, 34, 0.00, 1092, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27736, 35, 0.00, 1092, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27737, 36, 0.00, 1092, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27738, 37, 41493.68, 1092, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27739, 38, 3520.89, 1092, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27740, 40, 7045.80, 1092, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27741, 9, 1548.52, 1092, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27742, 10, 1548.52, 1092, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27743, 11, 12904.32, 1092, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27744, 39, 7045.80, 1092, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27745, 1, 45948.50, 1093, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27746, 7, 0.00, 1093, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27747, 12, 4594.85, 1093, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27748, 4, 45948.50, 1093, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27749, 5, 0.00, 1093, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27750, 6, 29407.04, 1093, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27751, 13, 6662.53, 1093, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27754, 15, 86612.92, 1093, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27755, 17, 9527.42, 1093, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27756, 18, 2598.39, 1093, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27757, 19, 2598.39, 1093, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27758, 20, 2165.32, 1093, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27759, 21, 16889.52, 1093, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27760, 22, 69723.40, 1093, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27761, 23, 69723.40, 1093, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27762, 32, 3486.17, 1093, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27763, 24, 34339.60, 1093, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27764, 25, 6669.50, 1093, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27765, 26, 0.00, 1093, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27767, 27, 7154.08, 1093, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27768, 28, 0.00, 1093, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27770, 31, 0.00, 1093, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27771, 33, 0.00, 1093, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27772, 34, 0.00, 1093, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27773, 35, 0.00, 1093, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27774, 36, 0.00, 1093, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27775, 37, 48163.18, 1093, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27776, 38, 21560.22, 1093, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27777, 40, 118102.54, 1093, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27778, 9, 2398.51, 1093, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27779, 10, 2398.51, 1093, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27780, 11, 19987.60, 1093, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27781, 39, 118102.54, 1093, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27782, 1, 34958.80, 1094, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27783, 7, 0.00, 1094, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27784, 12, 3495.88, 1094, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27785, 4, 34958.80, 1094, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27786, 5, 0.00, 1094, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27787, 6, 3495.88, 1094, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27788, 13, 3495.88, 1094, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27791, 15, 45446.44, 1094, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27792, 17, 4999.11, 1094, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27793, 18, 1363.39, 1094, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27794, 19, 1363.39, 1094, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27795, 20, 1136.16, 1094, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27796, 21, 8862.06, 1094, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27797, 22, 36584.38, 1094, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27798, 23, 36584.38, 1094, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27799, 32, 1829.22, 1094, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27800, 24, 34339.60, 1094, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27801, 25, 0.00, 1094, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27802, 26, 0.00, 1094, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27804, 27, 7154.08, 1094, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27805, 28, 0.00, 1094, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27807, 31, 0.00, 1094, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27808, 33, 0.00, 1094, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27809, 34, 0.00, 1094, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27810, 35, 0.00, 1094, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27811, 36, 0.00, 1094, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27812, 37, 41493.68, 1094, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27813, 38, -4909.30, 1094, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27814, 40, 0.00, 1094, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27815, 9, 1258.52, 1094, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27816, 10, 1258.52, 1094, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27817, 11, 10487.64, 1094, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27818, 39, 0.00, 1094, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27819, 1, 57061.70, 1095, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27820, 7, 0.00, 1095, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27821, 12, 5706.17, 1095, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27822, 4, 57061.70, 1095, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27823, 5, 0.00, 1095, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27824, 6, 36519.49, 1095, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27825, 13, 8273.95, 1095, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27828, 15, 107561.30, 1095, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27829, 17, 11831.74, 1095, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27830, 18, 3226.84, 1095, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27831, 19, 3226.84, 1095, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27832, 20, 2689.03, 1095, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27833, 21, 20974.45, 1095, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27834, 22, 86586.85, 1095, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27835, 23, 86586.85, 1095, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27836, 32, 4329.34, 1095, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27837, 24, 34339.60, 1095, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27838, 25, 0.00, 1095, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27839, 26, 0.00, 1095, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27841, 27, 7154.08, 1095, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27842, 28, 0.00, 1095, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27844, 31, 0.00, 1095, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27845, 33, 0.00, 1095, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27846, 34, 0.00, 1095, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27847, 35, 0.00, 1095, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27848, 36, 0.00, 1095, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27849, 37, 41493.68, 1095, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27850, 38, 45093.17, 1095, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27851, 40, 46232.49, 1095, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27852, 9, 2978.62, 1095, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27853, 10, 2978.62, 1095, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27854, 11, 24821.84, 1095, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27855, 39, 46232.49, 1095, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27856, 1, 34892.86, 1096, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27857, 7, 0.00, 1096, 'Horas Extras 100%', '3', '( c1 / 200 ) * 1.5 *  hsextras', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27858, 12, 3489.29, 1096, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27859, 4, 34892.86, 1096, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27860, 5, 0.00, 1096, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27861, 6, 697.86, 1096, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (27862, 13, 3256.67, 1096, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27865, 15, 42336.67, 1096, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27866, 17, 4657.03, 1096, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27867, 18, 1270.10, 1096, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27868, 19, 1270.10, 1096, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27869, 20, 1058.42, 1096, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27870, 21, 8255.65, 1096, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27871, 22, 34081.02, 1096, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27872, 23, 34081.02, 1096, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27873, 32, 1704.05, 1096, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27874, 24, 34339.60, 1096, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27875, 25, 6669.50, 1096, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27876, 26, 0.00, 1096, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27878, 27, 7154.08, 1096, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27879, 28, 0.00, 1096, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27881, 31, 0.00, 1096, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27882, 33, 0.00, 1096, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27883, 34, 0.00, 1096, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27884, 35, 0.00, 1096, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27885, 36, 0.00, 1096, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27886, 37, 48163.18, 1096, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27887, 38, -14082.16, 1096, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27888, 40, 0.00, 1096, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27889, 9, 1172.40, 1096, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27890, 10, 1172.40, 1096, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27891, 11, 9770.00, 1096, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (27892, 39, 0.00, 1096, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);


--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (75, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 2, 1, 2019, 200);
INSERT INTO public.liquidaciones VALUES (76, 'Liquidacion Febrero 2019', '2019-02-01', '2019-02-01', '2019-02-28', 1, 1, 1, '2019-03-01', '02 2019', 'Luján', '2019-03-01', 2, 2, 2019, 220);


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (1350, 1, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1351, 7, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1352, 12, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1353, 4, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1354, 5, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1355, 6, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1356, 13, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1357, 14, 75, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1358, 16, 75, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1359, 15, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1360, 17, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1361, 18, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1362, 19, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1363, 20, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1364, 21, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1365, 22, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1366, 23, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1367, 32, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1368, 24, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1369, 25, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1370, 26, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1371, 29, 75, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1372, 27, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1373, 28, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1374, 30, 75, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1375, 31, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1376, 33, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1377, 34, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1378, 35, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1379, 36, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1380, 37, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1381, 38, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1382, 40, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1383, 9, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1384, 10, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1385, 11, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1386, 39, 75, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1387, 1, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1388, 7, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1389, 12, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1390, 4, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1391, 5, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1392, 6, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1393, 13, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1394, 14, 76, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1395, 16, 76, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1396, 15, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1397, 17, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1398, 18, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1399, 19, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1400, 20, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1401, 21, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1402, 22, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1403, 23, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1404, 32, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1405, 24, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1406, 25, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1407, 26, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1408, 29, 76, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1409, 27, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1410, 28, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1411, 30, 76, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (1412, 31, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1413, 33, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1414, 34, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1415, 35, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1416, 36, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1417, 37, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1418, 38, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1419, 40, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1420, 9, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1421, 10, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1422, 11, 76, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (1423, 39, 76, NULL);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 1423, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 76, true);


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
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1984-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 42012.00, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265630562', 7.00, 34892.86, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265838333', 7.00, 41008.81, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27144901008', 7.00, 46807.40, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27927271414', 7.00, 24061.43, 0, 4.00, NULL);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 34351.20, 0, 8.00, NULL);


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

INSERT INTO public.recibos VALUES (1077, 200, 8, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1078, 201, 9, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1079, 202, 10, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1080, 203, 11, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1081, 204, 12, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1082, 205, 13, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1083, 206, 14, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1084, 207, 15, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1085, 208, 16, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1086, 209, 17, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1087, 210, 18, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1088, 211, 19, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1089, 212, 20, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1090, 213, 21, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1091, 214, 22, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1092, 215, 23, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1093, 216, 24, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1094, 217, 25, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1095, 218, 26, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1096, 219, 7, NULL, NULL, NULL, NULL, NULL, 75);
INSERT INTO public.recibos VALUES (1097, 220, 8, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1098, 221, 9, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1099, 222, 10, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1100, 223, 11, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1101, 224, 12, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1102, 225, 13, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1103, 226, 14, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1104, 227, 15, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1105, 228, 16, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1106, 229, 17, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1107, 230, 18, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1108, 231, 19, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1109, 232, 20, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1110, 233, 21, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1111, 234, 22, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1112, 235, 23, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1113, 236, 24, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1114, 237, 25, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1115, 238, 26, NULL, NULL, NULL, NULL, NULL, 76);
INSERT INTO public.recibos VALUES (1116, 239, 7, NULL, NULL, NULL, NULL, NULL, 76);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (3861, 1, 39080.00, 1096);
INSERT INTO public.recibos_acumuladores VALUES (3862, 2, 0.00, 1096);
INSERT INTO public.recibos_acumuladores VALUES (3863, 3, 39080.00, 1096);
INSERT INTO public.recibos_acumuladores VALUES (3864, 4, 0.00, 1096);
INSERT INTO public.recibos_acumuladores VALUES (3865, 5, 12114.80, 1096);
INSERT INTO public.recibos_acumuladores VALUES (3866, 1, 42595.49, 1077);
INSERT INTO public.recibos_acumuladores VALUES (3867, 2, 0.00, 1077);
INSERT INTO public.recibos_acumuladores VALUES (3868, 3, 42595.49, 1077);
INSERT INTO public.recibos_acumuladores VALUES (3869, 4, 0.00, 1077);
INSERT INTO public.recibos_acumuladores VALUES (3870, 5, 13204.60, 1077);
INSERT INTO public.recibos_acumuladores VALUES (3871, 1, 49210.57, 1078);
INSERT INTO public.recibos_acumuladores VALUES (3872, 2, 0.00, 1078);
INSERT INTO public.recibos_acumuladores VALUES (3873, 3, 49210.57, 1078);
INSERT INTO public.recibos_acumuladores VALUES (3874, 4, 0.00, 1078);
INSERT INTO public.recibos_acumuladores VALUES (3875, 5, 15255.28, 1078);
INSERT INTO public.recibos_acumuladores VALUES (3876, 1, 79572.58, 1079);
INSERT INTO public.recibos_acumuladores VALUES (3877, 2, 0.00, 1079);
INSERT INTO public.recibos_acumuladores VALUES (3878, 3, 79572.58, 1079);
INSERT INTO public.recibos_acumuladores VALUES (3879, 4, 0.00, 1079);
INSERT INTO public.recibos_acumuladores VALUES (3880, 5, 24667.50, 1079);
INSERT INTO public.recibos_acumuladores VALUES (3881, 1, 30317.40, 1080);
INSERT INTO public.recibos_acumuladores VALUES (3882, 2, 0.00, 1080);
INSERT INTO public.recibos_acumuladores VALUES (3883, 3, 30317.40, 1080);
INSERT INTO public.recibos_acumuladores VALUES (3884, 4, 0.00, 1080);
INSERT INTO public.recibos_acumuladores VALUES (3885, 5, 9398.39, 1080);
INSERT INTO public.recibos_acumuladores VALUES (3886, 1, 41567.27, 1081);
INSERT INTO public.recibos_acumuladores VALUES (3887, 2, 0.00, 1081);
INSERT INTO public.recibos_acumuladores VALUES (3888, 3, 41567.27, 1081);
INSERT INTO public.recibos_acumuladores VALUES (3889, 4, 0.00, 1081);
INSERT INTO public.recibos_acumuladores VALUES (3890, 5, 12885.85, 1081);
INSERT INTO public.recibos_acumuladores VALUES (3891, 1, 84533.20, 1082);
INSERT INTO public.recibos_acumuladores VALUES (3892, 2, 0.00, 1082);
INSERT INTO public.recibos_acumuladores VALUES (3893, 3, 84533.20, 1082);
INSERT INTO public.recibos_acumuladores VALUES (3894, 4, 0.00, 1082);
INSERT INTO public.recibos_acumuladores VALUES (3895, 5, 26205.29, 1082);
INSERT INTO public.recibos_acumuladores VALUES (3896, 1, 20010.00, 1083);
INSERT INTO public.recibos_acumuladores VALUES (3897, 2, 0.00, 1083);
INSERT INTO public.recibos_acumuladores VALUES (3898, 3, 20010.00, 1083);
INSERT INTO public.recibos_acumuladores VALUES (3899, 4, 0.00, 1083);
INSERT INTO public.recibos_acumuladores VALUES (3900, 5, 6203.10, 1083);
INSERT INTO public.recibos_acumuladores VALUES (3901, 1, 78000.00, 1084);
INSERT INTO public.recibos_acumuladores VALUES (3902, 2, 0.00, 1084);
INSERT INTO public.recibos_acumuladores VALUES (3903, 3, 78000.00, 1084);
INSERT INTO public.recibos_acumuladores VALUES (3904, 4, 0.00, 1084);
INSERT INTO public.recibos_acumuladores VALUES (3905, 5, 24180.00, 1084);
INSERT INTO public.recibos_acumuladores VALUES (3906, 1, 42039.72, 1085);
INSERT INTO public.recibos_acumuladores VALUES (3907, 2, 0.00, 1085);
INSERT INTO public.recibos_acumuladores VALUES (3908, 3, 42039.72, 1085);
INSERT INTO public.recibos_acumuladores VALUES (3909, 4, 0.00, 1085);
INSERT INTO public.recibos_acumuladores VALUES (3910, 5, 13032.31, 1085);
INSERT INTO public.recibos_acumuladores VALUES (3911, 1, 65574.74, 1086);
INSERT INTO public.recibos_acumuladores VALUES (3912, 2, 0.00, 1086);
INSERT INTO public.recibos_acumuladores VALUES (3913, 3, 65574.74, 1086);
INSERT INTO public.recibos_acumuladores VALUES (3914, 4, 0.00, 1086);
INSERT INTO public.recibos_acumuladores VALUES (3915, 5, 20328.17, 1086);
INSERT INTO public.recibos_acumuladores VALUES (3916, 1, 57173.51, 1087);
INSERT INTO public.recibos_acumuladores VALUES (3917, 2, 0.00, 1087);
INSERT INTO public.recibos_acumuladores VALUES (3918, 3, 57173.51, 1087);
INSERT INTO public.recibos_acumuladores VALUES (3919, 4, 0.00, 1087);
INSERT INTO public.recibos_acumuladores VALUES (3920, 5, 17723.79, 1087);
INSERT INTO public.recibos_acumuladores VALUES (3921, 1, 77302.08, 1088);
INSERT INTO public.recibos_acumuladores VALUES (3922, 2, 0.00, 1088);
INSERT INTO public.recibos_acumuladores VALUES (3923, 3, 77302.08, 1088);
INSERT INTO public.recibos_acumuladores VALUES (3924, 4, 0.00, 1088);
INSERT INTO public.recibos_acumuladores VALUES (3925, 5, 23963.64, 1088);
INSERT INTO public.recibos_acumuladores VALUES (3926, 1, 54678.40, 1089);
INSERT INTO public.recibos_acumuladores VALUES (3927, 2, 0.00, 1089);
INSERT INTO public.recibos_acumuladores VALUES (3928, 3, 54678.40, 1089);
INSERT INTO public.recibos_acumuladores VALUES (3929, 4, 0.00, 1089);
INSERT INTO public.recibos_acumuladores VALUES (3930, 5, 16950.30, 1089);
INSERT INTO public.recibos_acumuladores VALUES (3931, 1, 45027.03, 1090);
INSERT INTO public.recibos_acumuladores VALUES (3932, 2, 0.00, 1090);
INSERT INTO public.recibos_acumuladores VALUES (3933, 3, 45027.03, 1090);
INSERT INTO public.recibos_acumuladores VALUES (3934, 4, 0.00, 1090);
INSERT INTO public.recibos_acumuladores VALUES (3935, 5, 13958.38, 1090);
INSERT INTO public.recibos_acumuladores VALUES (3936, 1, 17971.76, 1091);
INSERT INTO public.recibos_acumuladores VALUES (3937, 2, 0.00, 1091);
INSERT INTO public.recibos_acumuladores VALUES (3938, 3, 17971.76, 1091);
INSERT INTO public.recibos_acumuladores VALUES (3939, 4, 0.00, 1091);
INSERT INTO public.recibos_acumuladores VALUES (3940, 5, 5571.24, 1091);
INSERT INTO public.recibos_acumuladores VALUES (3941, 1, 51617.28, 1092);
INSERT INTO public.recibos_acumuladores VALUES (3942, 2, 0.00, 1092);
INSERT INTO public.recibos_acumuladores VALUES (3943, 3, 51617.28, 1092);
INSERT INTO public.recibos_acumuladores VALUES (3944, 4, 0.00, 1092);
INSERT INTO public.recibos_acumuladores VALUES (3945, 5, 16001.36, 1092);
INSERT INTO public.recibos_acumuladores VALUES (3946, 1, 79950.39, 1093);
INSERT INTO public.recibos_acumuladores VALUES (3947, 2, 0.00, 1093);
INSERT INTO public.recibos_acumuladores VALUES (3948, 3, 79950.39, 1093);
INSERT INTO public.recibos_acumuladores VALUES (3949, 4, 0.00, 1093);
INSERT INTO public.recibos_acumuladores VALUES (3950, 5, 24784.62, 1093);
INSERT INTO public.recibos_acumuladores VALUES (3951, 1, 41950.56, 1094);
INSERT INTO public.recibos_acumuladores VALUES (3952, 2, 0.00, 1094);
INSERT INTO public.recibos_acumuladores VALUES (3953, 3, 41950.56, 1094);
INSERT INTO public.recibos_acumuladores VALUES (3954, 4, 0.00, 1094);
INSERT INTO public.recibos_acumuladores VALUES (3955, 5, 13004.67, 1094);
INSERT INTO public.recibos_acumuladores VALUES (3956, 1, 99287.36, 1095);
INSERT INTO public.recibos_acumuladores VALUES (3957, 2, 0.00, 1095);
INSERT INTO public.recibos_acumuladores VALUES (3958, 3, 99287.36, 1095);
INSERT INTO public.recibos_acumuladores VALUES (3959, 4, 0.00, 1095);
INSERT INTO public.recibos_acumuladores VALUES (3960, 5, 30779.08, 1095);
INSERT INTO public.recibos_acumuladores VALUES (3961, 1, 42595.49, 1097);
INSERT INTO public.recibos_acumuladores VALUES (3962, 2, 0.00, 1097);
INSERT INTO public.recibos_acumuladores VALUES (3963, 3, 42595.49, 1097);
INSERT INTO public.recibos_acumuladores VALUES (3964, 4, 0.00, 1097);
INSERT INTO public.recibos_acumuladores VALUES (3965, 5, 13204.60, 1097);
INSERT INTO public.recibos_acumuladores VALUES (3966, 1, 49210.57, 1098);
INSERT INTO public.recibos_acumuladores VALUES (3967, 2, 0.00, 1098);
INSERT INTO public.recibos_acumuladores VALUES (3968, 3, 49210.57, 1098);
INSERT INTO public.recibos_acumuladores VALUES (3969, 4, 0.00, 1098);
INSERT INTO public.recibos_acumuladores VALUES (3970, 5, 15255.28, 1098);
INSERT INTO public.recibos_acumuladores VALUES (3971, 1, 79572.58, 1099);
INSERT INTO public.recibos_acumuladores VALUES (3972, 2, 0.00, 1099);
INSERT INTO public.recibos_acumuladores VALUES (3973, 3, 79572.58, 1099);
INSERT INTO public.recibos_acumuladores VALUES (3974, 4, 0.00, 1099);
INSERT INTO public.recibos_acumuladores VALUES (3975, 5, 24667.50, 1099);
INSERT INTO public.recibos_acumuladores VALUES (3976, 1, 30317.40, 1100);
INSERT INTO public.recibos_acumuladores VALUES (3977, 2, 0.00, 1100);
INSERT INTO public.recibos_acumuladores VALUES (3978, 3, 30317.40, 1100);
INSERT INTO public.recibos_acumuladores VALUES (3979, 4, 0.00, 1100);
INSERT INTO public.recibos_acumuladores VALUES (3980, 5, 9398.39, 1100);
INSERT INTO public.recibos_acumuladores VALUES (3981, 1, 42271.80, 1101);
INSERT INTO public.recibos_acumuladores VALUES (3982, 2, 0.00, 1101);
INSERT INTO public.recibos_acumuladores VALUES (3983, 3, 42271.80, 1101);
INSERT INTO public.recibos_acumuladores VALUES (3984, 4, 0.00, 1101);
INSERT INTO public.recibos_acumuladores VALUES (3985, 5, 13104.26, 1101);
INSERT INTO public.recibos_acumuladores VALUES (3986, 1, 84533.20, 1102);
INSERT INTO public.recibos_acumuladores VALUES (3987, 2, 0.00, 1102);
INSERT INTO public.recibos_acumuladores VALUES (3988, 3, 84533.20, 1102);
INSERT INTO public.recibos_acumuladores VALUES (3989, 4, 0.00, 1102);
INSERT INTO public.recibos_acumuladores VALUES (3990, 5, 26205.29, 1102);
INSERT INTO public.recibos_acumuladores VALUES (3991, 1, 20010.00, 1103);
INSERT INTO public.recibos_acumuladores VALUES (3992, 2, 0.00, 1103);
INSERT INTO public.recibos_acumuladores VALUES (3993, 3, 20010.00, 1103);
INSERT INTO public.recibos_acumuladores VALUES (3994, 4, 0.00, 1103);
INSERT INTO public.recibos_acumuladores VALUES (3995, 5, 6203.10, 1103);
INSERT INTO public.recibos_acumuladores VALUES (3996, 1, 79200.00, 1104);
INSERT INTO public.recibos_acumuladores VALUES (3997, 2, 0.00, 1104);
INSERT INTO public.recibos_acumuladores VALUES (3998, 3, 79200.00, 1104);
INSERT INTO public.recibos_acumuladores VALUES (3999, 4, 0.00, 1104);
INSERT INTO public.recibos_acumuladores VALUES (4000, 5, 24552.00, 1104);
INSERT INTO public.recibos_acumuladores VALUES (4001, 1, 42039.72, 1105);
INSERT INTO public.recibos_acumuladores VALUES (4002, 2, 0.00, 1105);
INSERT INTO public.recibos_acumuladores VALUES (4003, 3, 42039.72, 1105);
INSERT INTO public.recibos_acumuladores VALUES (4004, 4, 0.00, 1105);
INSERT INTO public.recibos_acumuladores VALUES (4005, 5, 13032.31, 1105);
INSERT INTO public.recibos_acumuladores VALUES (4006, 1, 65574.74, 1106);
INSERT INTO public.recibos_acumuladores VALUES (4007, 2, 0.00, 1106);
INSERT INTO public.recibos_acumuladores VALUES (4008, 3, 65574.74, 1106);
INSERT INTO public.recibos_acumuladores VALUES (4009, 4, 0.00, 1106);
INSERT INTO public.recibos_acumuladores VALUES (4010, 5, 20328.17, 1106);
INSERT INTO public.recibos_acumuladores VALUES (4011, 1, 57173.51, 1107);
INSERT INTO public.recibos_acumuladores VALUES (4012, 2, 0.00, 1107);
INSERT INTO public.recibos_acumuladores VALUES (4013, 3, 57173.51, 1107);
INSERT INTO public.recibos_acumuladores VALUES (4014, 4, 0.00, 1107);
INSERT INTO public.recibos_acumuladores VALUES (4015, 5, 17723.79, 1107);
INSERT INTO public.recibos_acumuladores VALUES (4016, 1, 77302.08, 1108);
INSERT INTO public.recibos_acumuladores VALUES (4017, 2, 0.00, 1108);
INSERT INTO public.recibos_acumuladores VALUES (4018, 3, 77302.08, 1108);
INSERT INTO public.recibos_acumuladores VALUES (4019, 4, 0.00, 1108);
INSERT INTO public.recibos_acumuladores VALUES (4020, 5, 23963.64, 1108);
INSERT INTO public.recibos_acumuladores VALUES (4021, 1, 54678.40, 1109);
INSERT INTO public.recibos_acumuladores VALUES (4022, 2, 0.00, 1109);
INSERT INTO public.recibos_acumuladores VALUES (4023, 3, 54678.40, 1109);
INSERT INTO public.recibos_acumuladores VALUES (4024, 4, 0.00, 1109);
INSERT INTO public.recibos_acumuladores VALUES (4025, 5, 16950.30, 1109);
INSERT INTO public.recibos_acumuladores VALUES (4026, 1, 45027.03, 1110);
INSERT INTO public.recibos_acumuladores VALUES (4027, 2, 0.00, 1110);
INSERT INTO public.recibos_acumuladores VALUES (4028, 3, 45027.03, 1110);
INSERT INTO public.recibos_acumuladores VALUES (4029, 4, 0.00, 1110);
INSERT INTO public.recibos_acumuladores VALUES (4030, 5, 13958.38, 1110);
INSERT INTO public.recibos_acumuladores VALUES (4031, 1, 17971.76, 1111);
INSERT INTO public.recibos_acumuladores VALUES (4032, 2, 0.00, 1111);
INSERT INTO public.recibos_acumuladores VALUES (4033, 3, 17971.76, 1111);
INSERT INTO public.recibos_acumuladores VALUES (4034, 4, 0.00, 1111);
INSERT INTO public.recibos_acumuladores VALUES (4035, 5, 5571.24, 1111);
INSERT INTO public.recibos_acumuladores VALUES (4036, 1, 51617.28, 1112);
INSERT INTO public.recibos_acumuladores VALUES (4037, 2, 0.00, 1112);
INSERT INTO public.recibos_acumuladores VALUES (4038, 3, 51617.28, 1112);
INSERT INTO public.recibos_acumuladores VALUES (4039, 4, 0.00, 1112);
INSERT INTO public.recibos_acumuladores VALUES (4040, 5, 16001.36, 1112);
INSERT INTO public.recibos_acumuladores VALUES (4041, 1, 79950.39, 1113);
INSERT INTO public.recibos_acumuladores VALUES (4042, 2, 0.00, 1113);
INSERT INTO public.recibos_acumuladores VALUES (4043, 3, 79950.39, 1113);
INSERT INTO public.recibos_acumuladores VALUES (4044, 4, 0.00, 1113);
INSERT INTO public.recibos_acumuladores VALUES (4045, 5, 24784.62, 1113);
INSERT INTO public.recibos_acumuladores VALUES (4046, 1, 41950.56, 1114);
INSERT INTO public.recibos_acumuladores VALUES (4047, 2, 0.00, 1114);
INSERT INTO public.recibos_acumuladores VALUES (4048, 3, 41950.56, 1114);
INSERT INTO public.recibos_acumuladores VALUES (4049, 4, 0.00, 1114);
INSERT INTO public.recibos_acumuladores VALUES (4050, 5, 13004.67, 1114);
INSERT INTO public.recibos_acumuladores VALUES (4051, 1, 99287.36, 1115);
INSERT INTO public.recibos_acumuladores VALUES (4052, 2, 0.00, 1115);
INSERT INTO public.recibos_acumuladores VALUES (4053, 3, 99287.36, 1115);
INSERT INTO public.recibos_acumuladores VALUES (4054, 4, 0.00, 1115);
INSERT INTO public.recibos_acumuladores VALUES (4055, 5, 30779.08, 1115);
INSERT INTO public.recibos_acumuladores VALUES (4056, 1, 39080.00, 1116);
INSERT INTO public.recibos_acumuladores VALUES (4057, 2, 0.00, 1116);
INSERT INTO public.recibos_acumuladores VALUES (4058, 3, 39080.00, 1116);
INSERT INTO public.recibos_acumuladores VALUES (4059, 4, 0.00, 1116);
INSERT INTO public.recibos_acumuladores VALUES (4060, 5, 12114.80, 1116);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 4060, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (27160, 14, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27161, 16, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27900, 14, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27901, 16, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27174, 29, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27177, 30, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27914, 29, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27917, 30, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27197, 14, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27198, 16, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27937, 14, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27938, 16, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27211, 29, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27214, 30, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27951, 29, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27954, 30, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27234, 14, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27235, 16, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27974, 14, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27975, 16, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27248, 29, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27251, 30, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27988, 29, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27991, 30, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27271, 14, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27272, 16, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27285, 29, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (28011, 14, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28012, 16, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (27288, 30, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (28025, 29, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28028, 30, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (27308, 14, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27309, 16, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27322, 29, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27325, 30, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (28048, 14, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28049, 16, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28062, 29, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (27345, 14, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27346, 16, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (28065, 30, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (27359, 29, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27362, 30, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (28085, 14, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28086, 16, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (27382, 14, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27383, 16, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (28099, 29, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28102, 30, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (27396, 29, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27399, 30, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (28122, 14, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28123, 16, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (27419, 14, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27420, 16, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (28136, 29, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28139, 30, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (27433, 29, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27436, 30, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (28159, 14, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28160, 16, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (27456, 14, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27457, 16, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (28173, 29, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (27470, 29, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (28176, 30, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (27473, 30, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (28196, 14, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (27493, 14, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27494, 16, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (28197, 16, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (27507, 29, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (28210, 29, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (27510, 30, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (28213, 30, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (27530, 14, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27531, 16, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (28233, 14, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28234, 16, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (27544, 29, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27547, 30, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (28247, 29, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28250, 30, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (27564, 5, 3.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27567, 14, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27568, 16, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (28270, 14, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28271, 16, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (27581, 29, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27584, 30, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (28284, 29, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28287, 30, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (27604, 14, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27605, 16, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (28304, 5, 3.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (27618, 29, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (28307, 14, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28308, 16, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (27621, 30, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (28321, 29, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28324, 30, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (27641, 14, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27642, 16, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27655, 29, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27658, 30, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (28344, 14, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28345, 16, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28358, 29, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (27678, 14, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27679, 16, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (28361, 30, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (27692, 29, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27695, 30, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (28381, 14, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28382, 16, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (27715, 14, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27716, 16, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (28395, 29, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28398, 30, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (27729, 29, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27732, 30, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (28418, 14, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28419, 16, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (27752, 14, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27753, 16, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (28432, 29, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28435, 30, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (27766, 29, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27769, 30, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (28455, 14, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28456, 16, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (27789, 14, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27790, 16, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (28469, 29, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (27803, 29, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (28472, 30, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (27806, 30, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (28492, 14, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (27826, 14, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27827, 16, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (28493, 16, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (27840, 29, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (28506, 29, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (27843, 30, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (28509, 30, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (27863, 14, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27864, 16, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (28529, 14, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28530, 16, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (27877, 29, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27880, 30, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (28543, 29, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28546, 30, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (27153, 1, 34351.20, 1077);
INSERT INTO public.recibos_conceptos VALUES (27154, 7, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27155, 12, 3435.12, 1077);
INSERT INTO public.recibos_conceptos VALUES (27156, 4, 34351.20, 1077);
INSERT INTO public.recibos_conceptos VALUES (27157, 5, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27158, 6, 4809.17, 1077);
INSERT INTO public.recibos_conceptos VALUES (27159, 13, 3549.62, 1077);
INSERT INTO public.recibos_conceptos VALUES (27162, 15, 46145.11, 1077);
INSERT INTO public.recibos_conceptos VALUES (27163, 17, 5075.96, 1077);
INSERT INTO public.recibos_conceptos VALUES (27164, 18, 1384.35, 1077);
INSERT INTO public.recibos_conceptos VALUES (27165, 19, 1384.35, 1077);
INSERT INTO public.recibos_conceptos VALUES (27166, 20, 1153.63, 1077);
INSERT INTO public.recibos_conceptos VALUES (27167, 21, 8998.30, 1077);
INSERT INTO public.recibos_conceptos VALUES (27168, 22, 37146.82, 1077);
INSERT INTO public.recibos_conceptos VALUES (27169, 23, 37146.82, 1077);
INSERT INTO public.recibos_conceptos VALUES (27170, 32, 1857.34, 1077);
INSERT INTO public.recibos_conceptos VALUES (27171, 24, 34339.60, 1077);
INSERT INTO public.recibos_conceptos VALUES (27172, 25, 6669.50, 1077);
INSERT INTO public.recibos_conceptos VALUES (27173, 26, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27175, 27, 7154.08, 1077);
INSERT INTO public.recibos_conceptos VALUES (27176, 28, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27178, 31, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27179, 33, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27180, 34, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27181, 35, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27182, 36, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27183, 37, 48163.18, 1077);
INSERT INTO public.recibos_conceptos VALUES (27184, 38, -11016.36, 1077);
INSERT INTO public.recibos_conceptos VALUES (27185, 40, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27186, 9, 1277.86, 1077);
INSERT INTO public.recibos_conceptos VALUES (27187, 10, 1277.86, 1077);
INSERT INTO public.recibos_conceptos VALUES (27188, 11, 10648.87, 1077);
INSERT INTO public.recibos_conceptos VALUES (27189, 39, 0.00, 1077);
INSERT INTO public.recibos_conceptos VALUES (27190, 1, 41008.81, 1078);
INSERT INTO public.recibos_conceptos VALUES (27191, 7, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27192, 12, 4100.88, 1078);
INSERT INTO public.recibos_conceptos VALUES (27193, 4, 41008.81, 1078);
INSERT INTO public.recibos_conceptos VALUES (27194, 5, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27195, 6, 4100.88, 1078);
INSERT INTO public.recibos_conceptos VALUES (27196, 13, 4100.88, 1078);
INSERT INTO public.recibos_conceptos VALUES (27199, 15, 53311.45, 1078);
INSERT INTO public.recibos_conceptos VALUES (27200, 17, 5864.26, 1078);
INSERT INTO public.recibos_conceptos VALUES (27201, 18, 1599.34, 1078);
INSERT INTO public.recibos_conceptos VALUES (27202, 19, 1599.34, 1078);
INSERT INTO public.recibos_conceptos VALUES (27203, 20, 1332.79, 1078);
INSERT INTO public.recibos_conceptos VALUES (27204, 21, 10395.73, 1078);
INSERT INTO public.recibos_conceptos VALUES (27205, 22, 42915.72, 1078);
INSERT INTO public.recibos_conceptos VALUES (27206, 23, 42915.72, 1078);
INSERT INTO public.recibos_conceptos VALUES (27207, 32, 2145.79, 1078);
INSERT INTO public.recibos_conceptos VALUES (27208, 24, 34339.60, 1078);
INSERT INTO public.recibos_conceptos VALUES (27209, 25, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27210, 26, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27212, 27, 7154.08, 1078);
INSERT INTO public.recibos_conceptos VALUES (27213, 28, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27215, 31, 2145.79, 1078);
INSERT INTO public.recibos_conceptos VALUES (27216, 33, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27217, 34, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27218, 35, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27219, 36, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27220, 37, 43639.47, 1078);
INSERT INTO public.recibos_conceptos VALUES (27221, 38, -723.75, 1078);
INSERT INTO public.recibos_conceptos VALUES (27222, 40, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27223, 9, 1476.32, 1078);
INSERT INTO public.recibos_conceptos VALUES (27224, 10, 1476.32, 1078);
INSERT INTO public.recibos_conceptos VALUES (27225, 11, 12302.64, 1078);
INSERT INTO public.recibos_conceptos VALUES (27226, 39, 0.00, 1078);
INSERT INTO public.recibos_conceptos VALUES (27227, 1, 46807.40, 1079);
INSERT INTO public.recibos_conceptos VALUES (27228, 7, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27229, 12, 4680.74, 1079);
INSERT INTO public.recibos_conceptos VALUES (27230, 4, 46807.40, 1079);
INSERT INTO public.recibos_conceptos VALUES (27231, 5, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27232, 6, 28084.44, 1079);
INSERT INTO public.recibos_conceptos VALUES (27233, 13, 6631.05, 1079);
INSERT INTO public.recibos_conceptos VALUES (27236, 15, 86203.63, 1079);
INSERT INTO public.recibos_conceptos VALUES (27237, 17, 9482.40, 1079);
INSERT INTO public.recibos_conceptos VALUES (27238, 18, 2586.11, 1079);
INSERT INTO public.recibos_conceptos VALUES (27239, 19, 2586.11, 1079);
INSERT INTO public.recibos_conceptos VALUES (27240, 20, 2155.09, 1079);
INSERT INTO public.recibos_conceptos VALUES (27241, 21, 16809.71, 1079);
INSERT INTO public.recibos_conceptos VALUES (27242, 22, 69393.92, 1079);
INSERT INTO public.recibos_conceptos VALUES (27243, 23, 69393.92, 1079);
INSERT INTO public.recibos_conceptos VALUES (27244, 32, 3469.70, 1079);
INSERT INTO public.recibos_conceptos VALUES (27245, 24, 34339.60, 1079);
INSERT INTO public.recibos_conceptos VALUES (27246, 25, 6669.50, 1079);
INSERT INTO public.recibos_conceptos VALUES (27247, 26, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27249, 27, 7154.08, 1079);
INSERT INTO public.recibos_conceptos VALUES (27250, 28, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27252, 31, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27253, 33, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27254, 34, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27255, 35, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27256, 36, 0.00, 1079);
INSERT INTO public.recibos_conceptos VALUES (27257, 37, 48163.18, 1079);
INSERT INTO public.recibos_conceptos VALUES (27258, 38, 21230.74, 1079);
INSERT INTO public.recibos_conceptos VALUES (27259, 40, 110524.46, 1079);
INSERT INTO public.recibos_conceptos VALUES (27260, 9, 2387.18, 1079);
INSERT INTO public.recibos_conceptos VALUES (27261, 10, 2387.18, 1079);
INSERT INTO public.recibos_conceptos VALUES (27262, 11, 19893.15, 1079);
INSERT INTO public.recibos_conceptos VALUES (27263, 39, 110524.46, 1079);
INSERT INTO public.recibos_conceptos VALUES (27264, 1, 24061.43, 1080);
INSERT INTO public.recibos_conceptos VALUES (27265, 7, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27266, 12, 2406.14, 1080);
INSERT INTO public.recibos_conceptos VALUES (27267, 4, 24061.43, 1080);
INSERT INTO public.recibos_conceptos VALUES (27268, 5, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27269, 6, 3849.83, 1080);
INSERT INTO public.recibos_conceptos VALUES (27270, 13, 2526.45, 1080);
INSERT INTO public.recibos_conceptos VALUES (27273, 15, 32843.85, 1080);
INSERT INTO public.recibos_conceptos VALUES (27274, 17, 3612.82, 1080);
INSERT INTO public.recibos_conceptos VALUES (27275, 18, 985.32, 1080);
INSERT INTO public.recibos_conceptos VALUES (27276, 19, 985.32, 1080);
INSERT INTO public.recibos_conceptos VALUES (27277, 20, 821.10, 1080);
INSERT INTO public.recibos_conceptos VALUES (27278, 21, 6404.55, 1080);
INSERT INTO public.recibos_conceptos VALUES (27279, 22, 26439.30, 1080);
INSERT INTO public.recibos_conceptos VALUES (27280, 23, 26439.30, 1080);
INSERT INTO public.recibos_conceptos VALUES (27281, 32, 1321.97, 1080);
INSERT INTO public.recibos_conceptos VALUES (27282, 24, 34339.60, 1080);
INSERT INTO public.recibos_conceptos VALUES (27283, 25, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27284, 26, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27286, 27, 7154.08, 1080);
INSERT INTO public.recibos_conceptos VALUES (27287, 28, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27289, 31, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27290, 33, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27291, 34, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27292, 35, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27293, 36, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27294, 37, 41493.68, 1080);
INSERT INTO public.recibos_conceptos VALUES (27295, 38, -15054.38, 1080);
INSERT INTO public.recibos_conceptos VALUES (27296, 40, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27297, 9, 909.52, 1080);
INSERT INTO public.recibos_conceptos VALUES (27298, 10, 909.52, 1080);
INSERT INTO public.recibos_conceptos VALUES (27299, 11, 7579.35, 1080);
INSERT INTO public.recibos_conceptos VALUES (27300, 39, 0.00, 1080);
INSERT INTO public.recibos_conceptos VALUES (27301, 1, 35226.50, 1081);
INSERT INTO public.recibos_conceptos VALUES (27302, 7, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27303, 12, 3522.65, 1081);
INSERT INTO public.recibos_conceptos VALUES (27304, 4, 35226.50, 1081);
INSERT INTO public.recibos_conceptos VALUES (27305, 5, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27306, 6, 2818.12, 1081);
INSERT INTO public.recibos_conceptos VALUES (27307, 13, 3463.94, 1081);
INSERT INTO public.recibos_conceptos VALUES (27310, 15, 45031.21, 1081);
INSERT INTO public.recibos_conceptos VALUES (27311, 17, 4953.43, 1081);
INSERT INTO public.recibos_conceptos VALUES (27312, 18, 1350.94, 1081);
INSERT INTO public.recibos_conceptos VALUES (27313, 19, 1350.94, 1081);
INSERT INTO public.recibos_conceptos VALUES (27314, 20, 1125.78, 1081);
INSERT INTO public.recibos_conceptos VALUES (27315, 21, 8781.09, 1081);
INSERT INTO public.recibos_conceptos VALUES (27316, 22, 36250.12, 1081);
INSERT INTO public.recibos_conceptos VALUES (27317, 23, 36250.12, 1081);
INSERT INTO public.recibos_conceptos VALUES (27318, 32, 1812.51, 1081);
INSERT INTO public.recibos_conceptos VALUES (27319, 24, 34339.60, 1081);
INSERT INTO public.recibos_conceptos VALUES (27320, 25, 6669.50, 1081);
INSERT INTO public.recibos_conceptos VALUES (27321, 26, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27323, 27, 7154.08, 1081);
INSERT INTO public.recibos_conceptos VALUES (27324, 28, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27326, 31, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27327, 33, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27328, 34, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27329, 35, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27330, 36, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27331, 37, 48163.18, 1081);
INSERT INTO public.recibos_conceptos VALUES (27332, 38, -11913.06, 1081);
INSERT INTO public.recibos_conceptos VALUES (27333, 40, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27334, 9, 1247.02, 1081);
INSERT INTO public.recibos_conceptos VALUES (27335, 10, 1247.02, 1081);
INSERT INTO public.recibos_conceptos VALUES (27336, 11, 10391.82, 1081);
INSERT INTO public.recibos_conceptos VALUES (27337, 39, 0.00, 1081);
INSERT INTO public.recibos_conceptos VALUES (27338, 1, 48582.30, 1082);
INSERT INTO public.recibos_conceptos VALUES (27339, 7, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27340, 12, 4858.23, 1082);
INSERT INTO public.recibos_conceptos VALUES (27341, 4, 48582.30, 1082);
INSERT INTO public.recibos_conceptos VALUES (27342, 5, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27343, 6, 31092.67, 1082);
INSERT INTO public.recibos_conceptos VALUES (27344, 13, 7044.43, 1082);
INSERT INTO public.recibos_conceptos VALUES (27347, 15, 91577.64, 1082);
INSERT INTO public.recibos_conceptos VALUES (27348, 17, 10073.54, 1082);
INSERT INTO public.recibos_conceptos VALUES (27349, 18, 2747.33, 1082);
INSERT INTO public.recibos_conceptos VALUES (27350, 19, 2747.33, 1082);
INSERT INTO public.recibos_conceptos VALUES (27351, 20, 2289.44, 1082);
INSERT INTO public.recibos_conceptos VALUES (27352, 21, 17857.64, 1082);
INSERT INTO public.recibos_conceptos VALUES (27353, 22, 73720.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27354, 23, 73720.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27355, 32, 3686.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27356, 24, 34339.60, 1082);
INSERT INTO public.recibos_conceptos VALUES (27357, 25, 6669.50, 1082);
INSERT INTO public.recibos_conceptos VALUES (27358, 26, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27360, 27, 7154.08, 1082);
INSERT INTO public.recibos_conceptos VALUES (27361, 28, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27363, 31, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27364, 33, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27365, 34, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27366, 35, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27367, 36, 0.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27368, 37, 48163.18, 1082);
INSERT INTO public.recibos_conceptos VALUES (27369, 38, 25556.82, 1082);
INSERT INTO public.recibos_conceptos VALUES (27370, 40, 98759.12, 1082);
INSERT INTO public.recibos_conceptos VALUES (27371, 9, 2536.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27372, 10, 2536.00, 1082);
INSERT INTO public.recibos_conceptos VALUES (27373, 11, 21133.30, 1082);
INSERT INTO public.recibos_conceptos VALUES (27374, 39, 98759.12, 1082);
INSERT INTO public.recibos_conceptos VALUES (27375, 1, 17250.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27376, 7, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27377, 12, 1725.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27378, 4, 17250.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27379, 5, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27380, 6, 1035.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27381, 13, 1667.50, 1083);
INSERT INTO public.recibos_conceptos VALUES (27384, 15, 21677.50, 1083);
INSERT INTO public.recibos_conceptos VALUES (27385, 17, 2384.53, 1083);
INSERT INTO public.recibos_conceptos VALUES (27386, 18, 650.33, 1083);
INSERT INTO public.recibos_conceptos VALUES (27387, 19, 650.33, 1083);
INSERT INTO public.recibos_conceptos VALUES (27388, 20, 541.94, 1083);
INSERT INTO public.recibos_conceptos VALUES (27389, 21, 4227.11, 1083);
INSERT INTO public.recibos_conceptos VALUES (27390, 22, 17450.39, 1083);
INSERT INTO public.recibos_conceptos VALUES (27391, 23, 17450.39, 1083);
INSERT INTO public.recibos_conceptos VALUES (27392, 32, 872.52, 1083);
INSERT INTO public.recibos_conceptos VALUES (27393, 24, 34339.60, 1083);
INSERT INTO public.recibos_conceptos VALUES (27394, 25, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27395, 26, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27397, 27, 7154.08, 1083);
INSERT INTO public.recibos_conceptos VALUES (27398, 28, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27400, 31, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27401, 33, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27402, 34, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27403, 35, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27404, 36, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27405, 37, 41493.68, 1083);
INSERT INTO public.recibos_conceptos VALUES (27406, 38, -24043.29, 1083);
INSERT INTO public.recibos_conceptos VALUES (27407, 40, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27408, 9, 600.30, 1083);
INSERT INTO public.recibos_conceptos VALUES (27409, 10, 600.30, 1083);
INSERT INTO public.recibos_conceptos VALUES (27410, 11, 5002.50, 1083);
INSERT INTO public.recibos_conceptos VALUES (27411, 39, 0.00, 1083);
INSERT INTO public.recibos_conceptos VALUES (27412, 1, 60000.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27413, 7, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27414, 12, 6000.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27415, 4, 60000.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27416, 5, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27417, 6, 12000.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27418, 13, 6500.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27421, 15, 84500.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27422, 17, 9295.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27423, 18, 2535.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27424, 19, 2535.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27425, 20, 2112.50, 1084);
INSERT INTO public.recibos_conceptos VALUES (27426, 21, 16477.50, 1084);
INSERT INTO public.recibos_conceptos VALUES (27427, 22, 68022.50, 1084);
INSERT INTO public.recibos_conceptos VALUES (27428, 23, 68022.50, 1084);
INSERT INTO public.recibos_conceptos VALUES (27429, 32, 3401.13, 1084);
INSERT INTO public.recibos_conceptos VALUES (27430, 24, 34339.60, 1084);
INSERT INTO public.recibos_conceptos VALUES (27431, 25, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27432, 26, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27434, 27, 7154.08, 1084);
INSERT INTO public.recibos_conceptos VALUES (27435, 28, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27437, 31, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27438, 33, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27439, 34, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27440, 35, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27441, 36, 0.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27442, 37, 41493.68, 1084);
INSERT INTO public.recibos_conceptos VALUES (27443, 38, 26528.82, 1084);
INSERT INTO public.recibos_conceptos VALUES (27444, 40, 125003.21, 1084);
INSERT INTO public.recibos_conceptos VALUES (27445, 9, 2340.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27446, 10, 2340.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27447, 11, 19500.00, 1084);
INSERT INTO public.recibos_conceptos VALUES (27448, 39, 125003.21, 1084);
INSERT INTO public.recibos_conceptos VALUES (27449, 1, 35033.10, 1085);
INSERT INTO public.recibos_conceptos VALUES (27450, 7, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27451, 12, 3503.31, 1085);
INSERT INTO public.recibos_conceptos VALUES (27452, 4, 35033.10, 1085);
INSERT INTO public.recibos_conceptos VALUES (27453, 5, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27454, 6, 3503.31, 1085);
INSERT INTO public.recibos_conceptos VALUES (27455, 13, 3503.31, 1085);
INSERT INTO public.recibos_conceptos VALUES (27458, 15, 45543.03, 1085);
INSERT INTO public.recibos_conceptos VALUES (27459, 17, 5009.73, 1085);
INSERT INTO public.recibos_conceptos VALUES (27460, 18, 1366.29, 1085);
INSERT INTO public.recibos_conceptos VALUES (27461, 19, 1366.29, 1085);
INSERT INTO public.recibos_conceptos VALUES (27462, 20, 1138.58, 1085);
INSERT INTO public.recibos_conceptos VALUES (27463, 21, 8880.89, 1085);
INSERT INTO public.recibos_conceptos VALUES (27464, 22, 36662.14, 1085);
INSERT INTO public.recibos_conceptos VALUES (27465, 23, 36662.14, 1085);
INSERT INTO public.recibos_conceptos VALUES (27466, 32, 1833.11, 1085);
INSERT INTO public.recibos_conceptos VALUES (27467, 24, 34339.60, 1085);
INSERT INTO public.recibos_conceptos VALUES (27468, 25, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27469, 26, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27471, 27, 7154.08, 1085);
INSERT INTO public.recibos_conceptos VALUES (27472, 28, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27474, 31, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27475, 33, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27476, 34, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27477, 35, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27478, 36, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27479, 37, 41493.68, 1085);
INSERT INTO public.recibos_conceptos VALUES (27480, 38, -4831.54, 1085);
INSERT INTO public.recibos_conceptos VALUES (27481, 40, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27482, 9, 1261.19, 1085);
INSERT INTO public.recibos_conceptos VALUES (27483, 10, 1261.19, 1085);
INSERT INTO public.recibos_conceptos VALUES (27484, 11, 10509.93, 1085);
INSERT INTO public.recibos_conceptos VALUES (27485, 39, 0.00, 1085);
INSERT INTO public.recibos_conceptos VALUES (27486, 1, 46839.10, 1086);
INSERT INTO public.recibos_conceptos VALUES (27487, 7, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27488, 12, 4683.91, 1086);
INSERT INTO public.recibos_conceptos VALUES (27489, 4, 46839.10, 1086);
INSERT INTO public.recibos_conceptos VALUES (27490, 5, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27491, 6, 14051.73, 1086);
INSERT INTO public.recibos_conceptos VALUES (27492, 13, 5464.56, 1086);
INSERT INTO public.recibos_conceptos VALUES (27495, 15, 71039.30, 1086);
INSERT INTO public.recibos_conceptos VALUES (27496, 17, 7814.32, 1086);
INSERT INTO public.recibos_conceptos VALUES (27497, 18, 2131.18, 1086);
INSERT INTO public.recibos_conceptos VALUES (27498, 19, 2131.18, 1086);
INSERT INTO public.recibos_conceptos VALUES (27499, 20, 1775.98, 1086);
INSERT INTO public.recibos_conceptos VALUES (27500, 21, 13852.66, 1086);
INSERT INTO public.recibos_conceptos VALUES (27501, 22, 57186.64, 1086);
INSERT INTO public.recibos_conceptos VALUES (27502, 23, 57186.64, 1086);
INSERT INTO public.recibos_conceptos VALUES (27503, 32, 2859.33, 1086);
INSERT INTO public.recibos_conceptos VALUES (27504, 24, 34339.60, 1086);
INSERT INTO public.recibos_conceptos VALUES (27505, 25, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27506, 26, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27508, 27, 7154.08, 1086);
INSERT INTO public.recibos_conceptos VALUES (27509, 28, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27511, 31, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27512, 33, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27513, 34, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27514, 35, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27515, 36, 0.00, 1086);
INSERT INTO public.recibos_conceptos VALUES (27516, 37, 41493.68, 1086);
INSERT INTO public.recibos_conceptos VALUES (27517, 38, 15692.96, 1086);
INSERT INTO public.recibos_conceptos VALUES (27518, 40, 90042.93, 1086);
INSERT INTO public.recibos_conceptos VALUES (27519, 9, 1967.24, 1086);
INSERT INTO public.recibos_conceptos VALUES (27520, 10, 1967.24, 1086);
INSERT INTO public.recibos_conceptos VALUES (27521, 11, 16393.69, 1086);
INSERT INTO public.recibos_conceptos VALUES (27522, 39, 90042.93, 1086);
INSERT INTO public.recibos_conceptos VALUES (27523, 1, 42666.80, 1087);
INSERT INTO public.recibos_conceptos VALUES (27524, 7, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27525, 12, 4266.68, 1087);
INSERT INTO public.recibos_conceptos VALUES (27526, 4, 42666.80, 1087);
INSERT INTO public.recibos_conceptos VALUES (27527, 5, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27528, 6, 10240.03, 1087);
INSERT INTO public.recibos_conceptos VALUES (27529, 13, 4764.46, 1087);
INSERT INTO public.recibos_conceptos VALUES (27532, 15, 61937.97, 1087);
INSERT INTO public.recibos_conceptos VALUES (27533, 17, 6813.18, 1087);
INSERT INTO public.recibos_conceptos VALUES (27534, 18, 1858.14, 1087);
INSERT INTO public.recibos_conceptos VALUES (27535, 19, 1858.14, 1087);
INSERT INTO public.recibos_conceptos VALUES (27536, 20, 1548.45, 1087);
INSERT INTO public.recibos_conceptos VALUES (27537, 21, 12077.90, 1087);
INSERT INTO public.recibos_conceptos VALUES (27538, 22, 49860.07, 1087);
INSERT INTO public.recibos_conceptos VALUES (27539, 23, 49860.07, 1087);
INSERT INTO public.recibos_conceptos VALUES (27540, 32, 2493.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27541, 24, 34339.60, 1087);
INSERT INTO public.recibos_conceptos VALUES (27542, 25, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27543, 26, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27545, 27, 7154.08, 1087);
INSERT INTO public.recibos_conceptos VALUES (27546, 28, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27548, 31, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27549, 33, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27550, 34, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27551, 35, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27552, 36, 0.00, 1087);
INSERT INTO public.recibos_conceptos VALUES (27553, 37, 41493.68, 1087);
INSERT INTO public.recibos_conceptos VALUES (27554, 38, 8366.39, 1087);
INSERT INTO public.recibos_conceptos VALUES (27555, 40, 2312.41, 1087);
INSERT INTO public.recibos_conceptos VALUES (27556, 9, 1715.21, 1087);
INSERT INTO public.recibos_conceptos VALUES (27557, 10, 1715.21, 1087);
INSERT INTO public.recibos_conceptos VALUES (27558, 11, 14293.38, 1087);
INSERT INTO public.recibos_conceptos VALUES (27559, 39, 2312.41, 1087);
INSERT INTO public.recibos_conceptos VALUES (27560, 1, 42012.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27561, 7, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27562, 12, 4201.20, 1088);
INSERT INTO public.recibos_conceptos VALUES (27563, 4, 42012.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27565, 6, 31088.88, 1088);
INSERT INTO public.recibos_conceptos VALUES (27566, 13, 6441.84, 1088);
INSERT INTO public.recibos_conceptos VALUES (27569, 15, 83743.92, 1088);
INSERT INTO public.recibos_conceptos VALUES (27570, 17, 9211.83, 1088);
INSERT INTO public.recibos_conceptos VALUES (27571, 18, 2512.32, 1088);
INSERT INTO public.recibos_conceptos VALUES (27572, 19, 2512.32, 1088);
INSERT INTO public.recibos_conceptos VALUES (27573, 20, 2093.60, 1088);
INSERT INTO public.recibos_conceptos VALUES (27574, 21, 16330.06, 1088);
INSERT INTO public.recibos_conceptos VALUES (27575, 22, 67413.86, 1088);
INSERT INTO public.recibos_conceptos VALUES (27576, 23, 67413.86, 1088);
INSERT INTO public.recibos_conceptos VALUES (27577, 32, 3370.69, 1088);
INSERT INTO public.recibos_conceptos VALUES (27578, 24, 34339.60, 1088);
INSERT INTO public.recibos_conceptos VALUES (27579, 25, 6669.50, 1088);
INSERT INTO public.recibos_conceptos VALUES (27580, 26, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27582, 27, 7154.08, 1088);
INSERT INTO public.recibos_conceptos VALUES (27583, 28, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27585, 31, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27586, 33, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27587, 34, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27588, 35, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27589, 36, 0.00, 1088);
INSERT INTO public.recibos_conceptos VALUES (27590, 37, 48163.18, 1088);
INSERT INTO public.recibos_conceptos VALUES (27591, 38, 19250.68, 1088);
INSERT INTO public.recibos_conceptos VALUES (27592, 40, 64982.96, 1088);
INSERT INTO public.recibos_conceptos VALUES (27593, 9, 2319.06, 1088);
INSERT INTO public.recibos_conceptos VALUES (27594, 10, 2319.06, 1088);
INSERT INTO public.recibos_conceptos VALUES (27595, 11, 19325.52, 1088);
INSERT INTO public.recibos_conceptos VALUES (27596, 39, 64982.96, 1088);
INSERT INTO public.recibos_conceptos VALUES (27597, 1, 42717.50, 1089);
INSERT INTO public.recibos_conceptos VALUES (27598, 7, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27599, 12, 4271.75, 1089);
INSERT INTO public.recibos_conceptos VALUES (27600, 4, 42717.50, 1089);
INSERT INTO public.recibos_conceptos VALUES (27601, 5, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27602, 6, 7689.15, 1089);
INSERT INTO public.recibos_conceptos VALUES (27603, 13, 4556.53, 1089);
INSERT INTO public.recibos_conceptos VALUES (27606, 15, 59234.93, 1089);
INSERT INTO public.recibos_conceptos VALUES (27607, 17, 6515.84, 1089);
INSERT INTO public.recibos_conceptos VALUES (27608, 18, 1777.05, 1089);
INSERT INTO public.recibos_conceptos VALUES (27609, 19, 1777.05, 1089);
INSERT INTO public.recibos_conceptos VALUES (27610, 20, 1480.87, 1089);
INSERT INTO public.recibos_conceptos VALUES (27611, 21, 11550.81, 1089);
INSERT INTO public.recibos_conceptos VALUES (27612, 22, 47684.12, 1089);
INSERT INTO public.recibos_conceptos VALUES (27613, 23, 47684.12, 1089);
INSERT INTO public.recibos_conceptos VALUES (27614, 32, 2384.21, 1089);
INSERT INTO public.recibos_conceptos VALUES (27615, 24, 34339.60, 1089);
INSERT INTO public.recibos_conceptos VALUES (27616, 25, 6669.50, 1089);
INSERT INTO public.recibos_conceptos VALUES (27617, 26, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27619, 27, 7154.08, 1089);
INSERT INTO public.recibos_conceptos VALUES (27620, 28, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27622, 31, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27623, 33, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27624, 34, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27625, 35, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27626, 36, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27627, 37, 48163.18, 1089);
INSERT INTO public.recibos_conceptos VALUES (27628, 38, -479.06, 1089);
INSERT INTO public.recibos_conceptos VALUES (27629, 40, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27630, 9, 1640.35, 1089);
INSERT INTO public.recibos_conceptos VALUES (27631, 10, 1640.35, 1089);
INSERT INTO public.recibos_conceptos VALUES (27632, 11, 13669.60, 1089);
INSERT INTO public.recibos_conceptos VALUES (27633, 39, 0.00, 1089);
INSERT INTO public.recibos_conceptos VALUES (27634, 1, 38158.50, 1090);
INSERT INTO public.recibos_conceptos VALUES (27635, 7, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27636, 12, 3815.85, 1090);
INSERT INTO public.recibos_conceptos VALUES (27637, 4, 38158.50, 1090);
INSERT INTO public.recibos_conceptos VALUES (27638, 5, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27639, 6, 3052.68, 1090);
INSERT INTO public.recibos_conceptos VALUES (27640, 13, 3752.25, 1090);
INSERT INTO public.recibos_conceptos VALUES (27643, 15, 48779.28, 1090);
INSERT INTO public.recibos_conceptos VALUES (27644, 17, 5365.72, 1090);
INSERT INTO public.recibos_conceptos VALUES (27645, 18, 1463.38, 1090);
INSERT INTO public.recibos_conceptos VALUES (27646, 19, 1463.38, 1090);
INSERT INTO public.recibos_conceptos VALUES (27647, 20, 1219.48, 1090);
INSERT INTO public.recibos_conceptos VALUES (27648, 21, 9511.96, 1090);
INSERT INTO public.recibos_conceptos VALUES (27649, 22, 39267.32, 1090);
INSERT INTO public.recibos_conceptos VALUES (27650, 23, 39267.32, 1090);
INSERT INTO public.recibos_conceptos VALUES (27651, 32, 1963.37, 1090);
INSERT INTO public.recibos_conceptos VALUES (27652, 24, 34339.60, 1090);
INSERT INTO public.recibos_conceptos VALUES (27653, 25, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27654, 26, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27656, 27, 7154.08, 1090);
INSERT INTO public.recibos_conceptos VALUES (27657, 28, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27659, 31, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27660, 33, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27661, 34, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27662, 35, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27663, 36, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27664, 37, 41493.68, 1090);
INSERT INTO public.recibos_conceptos VALUES (27665, 38, -2226.36, 1090);
INSERT INTO public.recibos_conceptos VALUES (27666, 40, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27667, 9, 1350.81, 1090);
INSERT INTO public.recibos_conceptos VALUES (27668, 10, 1350.81, 1090);
INSERT INTO public.recibos_conceptos VALUES (27669, 11, 11256.76, 1090);
INSERT INTO public.recibos_conceptos VALUES (27670, 39, 0.00, 1090);
INSERT INTO public.recibos_conceptos VALUES (27671, 1, 15764.70, 1091);
INSERT INTO public.recibos_conceptos VALUES (27672, 7, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27673, 12, 1576.47, 1091);
INSERT INTO public.recibos_conceptos VALUES (27674, 4, 15764.70, 1091);
INSERT INTO public.recibos_conceptos VALUES (27675, 5, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27676, 6, 630.59, 1091);
INSERT INTO public.recibos_conceptos VALUES (27677, 13, 1497.65, 1091);
INSERT INTO public.recibos_conceptos VALUES (27680, 15, 19469.40, 1091);
INSERT INTO public.recibos_conceptos VALUES (27681, 17, 2141.63, 1091);
INSERT INTO public.recibos_conceptos VALUES (27682, 18, 584.08, 1091);
INSERT INTO public.recibos_conceptos VALUES (27683, 19, 584.08, 1091);
INSERT INTO public.recibos_conceptos VALUES (27684, 20, 486.74, 1091);
INSERT INTO public.recibos_conceptos VALUES (27685, 21, 3796.53, 1091);
INSERT INTO public.recibos_conceptos VALUES (27686, 22, 15672.87, 1091);
INSERT INTO public.recibos_conceptos VALUES (27687, 23, 15672.87, 1091);
INSERT INTO public.recibos_conceptos VALUES (27688, 32, 783.64, 1091);
INSERT INTO public.recibos_conceptos VALUES (27689, 24, 34339.60, 1091);
INSERT INTO public.recibos_conceptos VALUES (27690, 25, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27691, 26, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27693, 27, 7154.08, 1091);
INSERT INTO public.recibos_conceptos VALUES (27694, 28, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27696, 31, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27697, 33, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27698, 34, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27699, 35, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27700, 36, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27701, 37, 41493.68, 1091);
INSERT INTO public.recibos_conceptos VALUES (27702, 38, -25820.81, 1091);
INSERT INTO public.recibos_conceptos VALUES (27703, 40, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27704, 9, 539.15, 1091);
INSERT INTO public.recibos_conceptos VALUES (27705, 10, 539.15, 1091);
INSERT INTO public.recibos_conceptos VALUES (27706, 11, 4492.94, 1091);
INSERT INTO public.recibos_conceptos VALUES (27707, 39, 0.00, 1091);
INSERT INTO public.recibos_conceptos VALUES (27708, 1, 39104.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27709, 7, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27710, 12, 3910.40, 1092);
INSERT INTO public.recibos_conceptos VALUES (27711, 4, 39104.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27712, 5, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27713, 6, 8602.88, 1092);
INSERT INTO public.recibos_conceptos VALUES (27714, 13, 4301.44, 1092);
INSERT INTO public.recibos_conceptos VALUES (27717, 15, 55918.72, 1092);
INSERT INTO public.recibos_conceptos VALUES (27718, 17, 6151.06, 1092);
INSERT INTO public.recibos_conceptos VALUES (27719, 18, 1677.56, 1092);
INSERT INTO public.recibos_conceptos VALUES (27720, 19, 1677.56, 1092);
INSERT INTO public.recibos_conceptos VALUES (27721, 20, 1397.97, 1092);
INSERT INTO public.recibos_conceptos VALUES (27722, 21, 10904.15, 1092);
INSERT INTO public.recibos_conceptos VALUES (27723, 22, 45014.57, 1092);
INSERT INTO public.recibos_conceptos VALUES (27724, 23, 45014.57, 1092);
INSERT INTO public.recibos_conceptos VALUES (27725, 32, 2250.73, 1092);
INSERT INTO public.recibos_conceptos VALUES (27726, 24, 34339.60, 1092);
INSERT INTO public.recibos_conceptos VALUES (27727, 25, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27728, 26, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27730, 27, 7154.08, 1092);
INSERT INTO public.recibos_conceptos VALUES (27731, 28, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27733, 31, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27734, 33, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27735, 34, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27736, 35, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27737, 36, 0.00, 1092);
INSERT INTO public.recibos_conceptos VALUES (27738, 37, 41493.68, 1092);
INSERT INTO public.recibos_conceptos VALUES (27739, 38, 3520.89, 1092);
INSERT INTO public.recibos_conceptos VALUES (27740, 40, 7045.80, 1092);
INSERT INTO public.recibos_conceptos VALUES (27741, 9, 1548.52, 1092);
INSERT INTO public.recibos_conceptos VALUES (27742, 10, 1548.52, 1092);
INSERT INTO public.recibos_conceptos VALUES (27743, 11, 12904.32, 1092);
INSERT INTO public.recibos_conceptos VALUES (27744, 39, 7045.80, 1092);
INSERT INTO public.recibos_conceptos VALUES (27745, 1, 45948.50, 1093);
INSERT INTO public.recibos_conceptos VALUES (27746, 7, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27747, 12, 4594.85, 1093);
INSERT INTO public.recibos_conceptos VALUES (27748, 4, 45948.50, 1093);
INSERT INTO public.recibos_conceptos VALUES (27749, 5, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27750, 6, 29407.04, 1093);
INSERT INTO public.recibos_conceptos VALUES (27751, 13, 6662.53, 1093);
INSERT INTO public.recibos_conceptos VALUES (27754, 15, 86612.92, 1093);
INSERT INTO public.recibos_conceptos VALUES (27755, 17, 9527.42, 1093);
INSERT INTO public.recibos_conceptos VALUES (27756, 18, 2598.39, 1093);
INSERT INTO public.recibos_conceptos VALUES (27757, 19, 2598.39, 1093);
INSERT INTO public.recibos_conceptos VALUES (27758, 20, 2165.32, 1093);
INSERT INTO public.recibos_conceptos VALUES (27759, 21, 16889.52, 1093);
INSERT INTO public.recibos_conceptos VALUES (27760, 22, 69723.40, 1093);
INSERT INTO public.recibos_conceptos VALUES (27761, 23, 69723.40, 1093);
INSERT INTO public.recibos_conceptos VALUES (27762, 32, 3486.17, 1093);
INSERT INTO public.recibos_conceptos VALUES (27763, 24, 34339.60, 1093);
INSERT INTO public.recibos_conceptos VALUES (27764, 25, 6669.50, 1093);
INSERT INTO public.recibos_conceptos VALUES (27765, 26, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27767, 27, 7154.08, 1093);
INSERT INTO public.recibos_conceptos VALUES (27768, 28, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27770, 31, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27771, 33, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27772, 34, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27773, 35, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27774, 36, 0.00, 1093);
INSERT INTO public.recibos_conceptos VALUES (27775, 37, 48163.18, 1093);
INSERT INTO public.recibos_conceptos VALUES (27776, 38, 21560.22, 1093);
INSERT INTO public.recibos_conceptos VALUES (27777, 40, 118102.54, 1093);
INSERT INTO public.recibos_conceptos VALUES (27778, 9, 2398.51, 1093);
INSERT INTO public.recibos_conceptos VALUES (27779, 10, 2398.51, 1093);
INSERT INTO public.recibos_conceptos VALUES (27780, 11, 19987.60, 1093);
INSERT INTO public.recibos_conceptos VALUES (27781, 39, 118102.54, 1093);
INSERT INTO public.recibos_conceptos VALUES (27782, 1, 34958.80, 1094);
INSERT INTO public.recibos_conceptos VALUES (27783, 7, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27784, 12, 3495.88, 1094);
INSERT INTO public.recibos_conceptos VALUES (27785, 4, 34958.80, 1094);
INSERT INTO public.recibos_conceptos VALUES (27786, 5, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27787, 6, 3495.88, 1094);
INSERT INTO public.recibos_conceptos VALUES (27788, 13, 3495.88, 1094);
INSERT INTO public.recibos_conceptos VALUES (27791, 15, 45446.44, 1094);
INSERT INTO public.recibos_conceptos VALUES (27792, 17, 4999.11, 1094);
INSERT INTO public.recibos_conceptos VALUES (27793, 18, 1363.39, 1094);
INSERT INTO public.recibos_conceptos VALUES (27794, 19, 1363.39, 1094);
INSERT INTO public.recibos_conceptos VALUES (27795, 20, 1136.16, 1094);
INSERT INTO public.recibos_conceptos VALUES (27796, 21, 8862.06, 1094);
INSERT INTO public.recibos_conceptos VALUES (27797, 22, 36584.38, 1094);
INSERT INTO public.recibos_conceptos VALUES (27798, 23, 36584.38, 1094);
INSERT INTO public.recibos_conceptos VALUES (27799, 32, 1829.22, 1094);
INSERT INTO public.recibos_conceptos VALUES (27800, 24, 34339.60, 1094);
INSERT INTO public.recibos_conceptos VALUES (27801, 25, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27802, 26, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27804, 27, 7154.08, 1094);
INSERT INTO public.recibos_conceptos VALUES (27805, 28, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27807, 31, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27808, 33, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27809, 34, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27810, 35, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27811, 36, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27812, 37, 41493.68, 1094);
INSERT INTO public.recibos_conceptos VALUES (27813, 38, -4909.30, 1094);
INSERT INTO public.recibos_conceptos VALUES (27814, 40, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27815, 9, 1258.52, 1094);
INSERT INTO public.recibos_conceptos VALUES (27816, 10, 1258.52, 1094);
INSERT INTO public.recibos_conceptos VALUES (27817, 11, 10487.64, 1094);
INSERT INTO public.recibos_conceptos VALUES (27818, 39, 0.00, 1094);
INSERT INTO public.recibos_conceptos VALUES (27819, 1, 57061.70, 1095);
INSERT INTO public.recibos_conceptos VALUES (27820, 7, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27821, 12, 5706.17, 1095);
INSERT INTO public.recibos_conceptos VALUES (27822, 4, 57061.70, 1095);
INSERT INTO public.recibos_conceptos VALUES (27823, 5, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27824, 6, 36519.49, 1095);
INSERT INTO public.recibos_conceptos VALUES (27825, 13, 8273.95, 1095);
INSERT INTO public.recibos_conceptos VALUES (27828, 15, 107561.30, 1095);
INSERT INTO public.recibos_conceptos VALUES (27829, 17, 11831.74, 1095);
INSERT INTO public.recibos_conceptos VALUES (27830, 18, 3226.84, 1095);
INSERT INTO public.recibos_conceptos VALUES (27831, 19, 3226.84, 1095);
INSERT INTO public.recibos_conceptos VALUES (27832, 20, 2689.03, 1095);
INSERT INTO public.recibos_conceptos VALUES (27833, 21, 20974.45, 1095);
INSERT INTO public.recibos_conceptos VALUES (27834, 22, 86586.85, 1095);
INSERT INTO public.recibos_conceptos VALUES (27835, 23, 86586.85, 1095);
INSERT INTO public.recibos_conceptos VALUES (27836, 32, 4329.34, 1095);
INSERT INTO public.recibos_conceptos VALUES (27837, 24, 34339.60, 1095);
INSERT INTO public.recibos_conceptos VALUES (27838, 25, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27839, 26, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27841, 27, 7154.08, 1095);
INSERT INTO public.recibos_conceptos VALUES (27842, 28, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27844, 31, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27845, 33, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27846, 34, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27847, 35, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27848, 36, 0.00, 1095);
INSERT INTO public.recibos_conceptos VALUES (27849, 37, 41493.68, 1095);
INSERT INTO public.recibos_conceptos VALUES (27850, 38, 45093.17, 1095);
INSERT INTO public.recibos_conceptos VALUES (27851, 40, 46232.49, 1095);
INSERT INTO public.recibos_conceptos VALUES (27852, 9, 2978.62, 1095);
INSERT INTO public.recibos_conceptos VALUES (27853, 10, 2978.62, 1095);
INSERT INTO public.recibos_conceptos VALUES (27854, 11, 24821.84, 1095);
INSERT INTO public.recibos_conceptos VALUES (27855, 39, 46232.49, 1095);
INSERT INTO public.recibos_conceptos VALUES (27856, 1, 34892.86, 1096);
INSERT INTO public.recibos_conceptos VALUES (27857, 7, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27858, 12, 3489.29, 1096);
INSERT INTO public.recibos_conceptos VALUES (27859, 4, 34892.86, 1096);
INSERT INTO public.recibos_conceptos VALUES (27860, 5, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27861, 6, 697.86, 1096);
INSERT INTO public.recibos_conceptos VALUES (27862, 13, 3256.67, 1096);
INSERT INTO public.recibos_conceptos VALUES (27865, 15, 42336.67, 1096);
INSERT INTO public.recibos_conceptos VALUES (27866, 17, 4657.03, 1096);
INSERT INTO public.recibos_conceptos VALUES (27867, 18, 1270.10, 1096);
INSERT INTO public.recibos_conceptos VALUES (27868, 19, 1270.10, 1096);
INSERT INTO public.recibos_conceptos VALUES (27869, 20, 1058.42, 1096);
INSERT INTO public.recibos_conceptos VALUES (27870, 21, 8255.65, 1096);
INSERT INTO public.recibos_conceptos VALUES (27871, 22, 34081.02, 1096);
INSERT INTO public.recibos_conceptos VALUES (27872, 23, 34081.02, 1096);
INSERT INTO public.recibos_conceptos VALUES (27873, 32, 1704.05, 1096);
INSERT INTO public.recibos_conceptos VALUES (27874, 24, 34339.60, 1096);
INSERT INTO public.recibos_conceptos VALUES (27875, 25, 6669.50, 1096);
INSERT INTO public.recibos_conceptos VALUES (27876, 26, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27878, 27, 7154.08, 1096);
INSERT INTO public.recibos_conceptos VALUES (27879, 28, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27881, 31, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27882, 33, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27883, 34, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27884, 35, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27885, 36, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27886, 37, 48163.18, 1096);
INSERT INTO public.recibos_conceptos VALUES (27887, 38, -14082.16, 1096);
INSERT INTO public.recibos_conceptos VALUES (27888, 40, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27889, 9, 1172.40, 1096);
INSERT INTO public.recibos_conceptos VALUES (27890, 10, 1172.40, 1096);
INSERT INTO public.recibos_conceptos VALUES (27891, 11, 9770.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (27892, 39, 0.00, 1096);
INSERT INTO public.recibos_conceptos VALUES (28566, 14, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28567, 16, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28580, 29, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28583, 30, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28603, 14, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28604, 16, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28617, 29, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28620, 30, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (27893, 1, 34351.20, 1097);
INSERT INTO public.recibos_conceptos VALUES (27894, 7, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27895, 12, 3435.12, 1097);
INSERT INTO public.recibos_conceptos VALUES (27896, 4, 34351.20, 1097);
INSERT INTO public.recibos_conceptos VALUES (27897, 5, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27898, 6, 4809.17, 1097);
INSERT INTO public.recibos_conceptos VALUES (27899, 13, 3549.62, 1097);
INSERT INTO public.recibos_conceptos VALUES (27902, 15, 46145.11, 1097);
INSERT INTO public.recibos_conceptos VALUES (27903, 17, 5075.96, 1097);
INSERT INTO public.recibos_conceptos VALUES (27904, 18, 1384.35, 1097);
INSERT INTO public.recibos_conceptos VALUES (27905, 19, 1384.35, 1097);
INSERT INTO public.recibos_conceptos VALUES (27906, 20, 1153.63, 1097);
INSERT INTO public.recibos_conceptos VALUES (27907, 21, 8998.30, 1097);
INSERT INTO public.recibos_conceptos VALUES (27908, 22, 37146.82, 1097);
INSERT INTO public.recibos_conceptos VALUES (27909, 23, 74293.64, 1097);
INSERT INTO public.recibos_conceptos VALUES (27910, 32, 3714.68, 1097);
INSERT INTO public.recibos_conceptos VALUES (27911, 24, 68679.19, 1097);
INSERT INTO public.recibos_conceptos VALUES (27912, 25, 13339.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27913, 26, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27915, 27, 14308.17, 1097);
INSERT INTO public.recibos_conceptos VALUES (27916, 28, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27918, 31, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27919, 33, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27920, 34, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27921, 35, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27922, 36, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27923, 37, 96326.36, 1097);
INSERT INTO public.recibos_conceptos VALUES (27924, 38, -22032.72, 1097);
INSERT INTO public.recibos_conceptos VALUES (27925, 40, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27926, 9, 1277.86, 1097);
INSERT INTO public.recibos_conceptos VALUES (27927, 10, 1277.86, 1097);
INSERT INTO public.recibos_conceptos VALUES (27928, 11, 10648.87, 1097);
INSERT INTO public.recibos_conceptos VALUES (27929, 39, 0.00, 1097);
INSERT INTO public.recibos_conceptos VALUES (27930, 1, 41008.81, 1098);
INSERT INTO public.recibos_conceptos VALUES (27931, 7, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27932, 12, 4100.88, 1098);
INSERT INTO public.recibos_conceptos VALUES (27933, 4, 41008.81, 1098);
INSERT INTO public.recibos_conceptos VALUES (27934, 5, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27935, 6, 4100.88, 1098);
INSERT INTO public.recibos_conceptos VALUES (27936, 13, 4100.88, 1098);
INSERT INTO public.recibos_conceptos VALUES (27939, 15, 53311.45, 1098);
INSERT INTO public.recibos_conceptos VALUES (27940, 17, 5864.26, 1098);
INSERT INTO public.recibos_conceptos VALUES (27941, 18, 1599.34, 1098);
INSERT INTO public.recibos_conceptos VALUES (27942, 19, 1599.34, 1098);
INSERT INTO public.recibos_conceptos VALUES (27943, 20, 1332.79, 1098);
INSERT INTO public.recibos_conceptos VALUES (27944, 21, 10395.73, 1098);
INSERT INTO public.recibos_conceptos VALUES (27945, 22, 42915.72, 1098);
INSERT INTO public.recibos_conceptos VALUES (27946, 23, 85831.44, 1098);
INSERT INTO public.recibos_conceptos VALUES (27947, 32, 4291.57, 1098);
INSERT INTO public.recibos_conceptos VALUES (27948, 24, 68679.19, 1098);
INSERT INTO public.recibos_conceptos VALUES (27949, 25, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27950, 26, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27952, 27, 14308.17, 1098);
INSERT INTO public.recibos_conceptos VALUES (27953, 28, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27955, 31, 3161.11, 1098);
INSERT INTO public.recibos_conceptos VALUES (27956, 33, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27957, 34, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27958, 35, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27959, 36, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27960, 37, 86148.47, 1098);
INSERT INTO public.recibos_conceptos VALUES (27961, 38, -317.03, 1098);
INSERT INTO public.recibos_conceptos VALUES (27962, 40, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27963, 9, 1476.32, 1098);
INSERT INTO public.recibos_conceptos VALUES (27964, 10, 1476.32, 1098);
INSERT INTO public.recibos_conceptos VALUES (27965, 11, 12302.64, 1098);
INSERT INTO public.recibos_conceptos VALUES (27966, 39, 0.00, 1098);
INSERT INTO public.recibos_conceptos VALUES (27967, 1, 46807.40, 1099);
INSERT INTO public.recibos_conceptos VALUES (27968, 7, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27969, 12, 4680.74, 1099);
INSERT INTO public.recibos_conceptos VALUES (27970, 4, 46807.40, 1099);
INSERT INTO public.recibos_conceptos VALUES (27971, 5, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27972, 6, 28084.44, 1099);
INSERT INTO public.recibos_conceptos VALUES (27973, 13, 6631.05, 1099);
INSERT INTO public.recibos_conceptos VALUES (27976, 15, 86203.63, 1099);
INSERT INTO public.recibos_conceptos VALUES (27977, 17, 9482.40, 1099);
INSERT INTO public.recibos_conceptos VALUES (27978, 18, 2586.11, 1099);
INSERT INTO public.recibos_conceptos VALUES (27979, 19, 2586.11, 1099);
INSERT INTO public.recibos_conceptos VALUES (27980, 20, 2155.09, 1099);
INSERT INTO public.recibos_conceptos VALUES (27981, 21, 16809.71, 1099);
INSERT INTO public.recibos_conceptos VALUES (27982, 22, 69393.92, 1099);
INSERT INTO public.recibos_conceptos VALUES (27983, 23, 138787.84, 1099);
INSERT INTO public.recibos_conceptos VALUES (27984, 32, 6939.39, 1099);
INSERT INTO public.recibos_conceptos VALUES (27985, 24, 68679.19, 1099);
INSERT INTO public.recibos_conceptos VALUES (27986, 25, 13339.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27987, 26, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27989, 27, 14308.17, 1099);
INSERT INTO public.recibos_conceptos VALUES (27990, 28, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27992, 31, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27993, 33, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27994, 34, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27995, 35, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27996, 36, 0.00, 1099);
INSERT INTO public.recibos_conceptos VALUES (27997, 37, 96326.36, 1099);
INSERT INTO public.recibos_conceptos VALUES (27998, 38, 42461.48, 1099);
INSERT INTO public.recibos_conceptos VALUES (27999, 40, 221048.67, 1099);
INSERT INTO public.recibos_conceptos VALUES (28000, 9, 2387.18, 1099);
INSERT INTO public.recibos_conceptos VALUES (28001, 10, 2387.18, 1099);
INSERT INTO public.recibos_conceptos VALUES (28002, 11, 19893.15, 1099);
INSERT INTO public.recibos_conceptos VALUES (28003, 39, 110524.21, 1099);
INSERT INTO public.recibos_conceptos VALUES (28004, 1, 24061.43, 1100);
INSERT INTO public.recibos_conceptos VALUES (28005, 7, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28006, 12, 2406.14, 1100);
INSERT INTO public.recibos_conceptos VALUES (28007, 4, 24061.43, 1100);
INSERT INTO public.recibos_conceptos VALUES (28008, 5, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28009, 6, 3849.83, 1100);
INSERT INTO public.recibos_conceptos VALUES (28010, 13, 2526.45, 1100);
INSERT INTO public.recibos_conceptos VALUES (28013, 15, 32843.85, 1100);
INSERT INTO public.recibos_conceptos VALUES (28014, 17, 3612.82, 1100);
INSERT INTO public.recibos_conceptos VALUES (28015, 18, 985.32, 1100);
INSERT INTO public.recibos_conceptos VALUES (28016, 19, 985.32, 1100);
INSERT INTO public.recibos_conceptos VALUES (28017, 20, 821.10, 1100);
INSERT INTO public.recibos_conceptos VALUES (28018, 21, 6404.55, 1100);
INSERT INTO public.recibos_conceptos VALUES (28019, 22, 26439.30, 1100);
INSERT INTO public.recibos_conceptos VALUES (28020, 23, 52878.60, 1100);
INSERT INTO public.recibos_conceptos VALUES (28021, 32, 2643.93, 1100);
INSERT INTO public.recibos_conceptos VALUES (28022, 24, 68679.19, 1100);
INSERT INTO public.recibos_conceptos VALUES (28023, 25, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28024, 26, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28026, 27, 14308.17, 1100);
INSERT INTO public.recibos_conceptos VALUES (28027, 28, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28029, 31, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28030, 33, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28031, 34, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28032, 35, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28033, 36, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28034, 37, 82987.36, 1100);
INSERT INTO public.recibos_conceptos VALUES (28035, 38, -30108.76, 1100);
INSERT INTO public.recibos_conceptos VALUES (28036, 40, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28037, 9, 909.52, 1100);
INSERT INTO public.recibos_conceptos VALUES (28038, 10, 909.52, 1100);
INSERT INTO public.recibos_conceptos VALUES (28039, 11, 7579.35, 1100);
INSERT INTO public.recibos_conceptos VALUES (28040, 39, 0.00, 1100);
INSERT INTO public.recibos_conceptos VALUES (28041, 1, 35226.50, 1101);
INSERT INTO public.recibos_conceptos VALUES (28042, 7, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28043, 12, 3522.65, 1101);
INSERT INTO public.recibos_conceptos VALUES (28044, 4, 35226.50, 1101);
INSERT INTO public.recibos_conceptos VALUES (28045, 5, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28046, 6, 3522.65, 1101);
INSERT INTO public.recibos_conceptos VALUES (28047, 13, 3522.65, 1101);
INSERT INTO public.recibos_conceptos VALUES (28050, 15, 45794.45, 1101);
INSERT INTO public.recibos_conceptos VALUES (28051, 17, 5037.39, 1101);
INSERT INTO public.recibos_conceptos VALUES (28052, 18, 1373.83, 1101);
INSERT INTO public.recibos_conceptos VALUES (28053, 19, 1373.83, 1101);
INSERT INTO public.recibos_conceptos VALUES (28054, 20, 1144.86, 1101);
INSERT INTO public.recibos_conceptos VALUES (28055, 21, 8929.92, 1101);
INSERT INTO public.recibos_conceptos VALUES (28056, 22, 36864.53, 1101);
INSERT INTO public.recibos_conceptos VALUES (28057, 23, 73114.65, 1101);
INSERT INTO public.recibos_conceptos VALUES (28058, 32, 3655.73, 1101);
INSERT INTO public.recibos_conceptos VALUES (28059, 24, 68679.19, 1101);
INSERT INTO public.recibos_conceptos VALUES (28060, 25, 13339.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28061, 26, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28063, 27, 14308.17, 1101);
INSERT INTO public.recibos_conceptos VALUES (28064, 28, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28066, 31, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28067, 33, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28068, 34, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28069, 35, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28070, 36, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28071, 37, 96326.36, 1101);
INSERT INTO public.recibos_conceptos VALUES (28072, 38, -23211.71, 1101);
INSERT INTO public.recibos_conceptos VALUES (28073, 40, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28074, 9, 1268.15, 1101);
INSERT INTO public.recibos_conceptos VALUES (28075, 10, 1268.15, 1101);
INSERT INTO public.recibos_conceptos VALUES (28076, 11, 10567.95, 1101);
INSERT INTO public.recibos_conceptos VALUES (28077, 39, 0.00, 1101);
INSERT INTO public.recibos_conceptos VALUES (28078, 1, 48582.30, 1102);
INSERT INTO public.recibos_conceptos VALUES (28079, 7, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28080, 12, 4858.23, 1102);
INSERT INTO public.recibos_conceptos VALUES (28081, 4, 48582.30, 1102);
INSERT INTO public.recibos_conceptos VALUES (28082, 5, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28083, 6, 31092.67, 1102);
INSERT INTO public.recibos_conceptos VALUES (28084, 13, 7044.43, 1102);
INSERT INTO public.recibos_conceptos VALUES (28087, 15, 91577.64, 1102);
INSERT INTO public.recibos_conceptos VALUES (28088, 17, 10073.54, 1102);
INSERT INTO public.recibos_conceptos VALUES (28089, 18, 2747.33, 1102);
INSERT INTO public.recibos_conceptos VALUES (28090, 19, 2747.33, 1102);
INSERT INTO public.recibos_conceptos VALUES (28091, 20, 2289.44, 1102);
INSERT INTO public.recibos_conceptos VALUES (28092, 21, 17857.64, 1102);
INSERT INTO public.recibos_conceptos VALUES (28093, 22, 73720.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28094, 23, 147440.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28095, 32, 7372.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28096, 24, 68679.19, 1102);
INSERT INTO public.recibos_conceptos VALUES (28097, 25, 13339.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28098, 26, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28100, 27, 14308.17, 1102);
INSERT INTO public.recibos_conceptos VALUES (28101, 28, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28103, 31, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28104, 33, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28105, 34, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28106, 35, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28107, 36, 0.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28108, 37, 96326.36, 1102);
INSERT INTO public.recibos_conceptos VALUES (28109, 38, 51113.64, 1102);
INSERT INTO public.recibos_conceptos VALUES (28110, 40, 197518.32, 1102);
INSERT INTO public.recibos_conceptos VALUES (28111, 9, 2536.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28112, 10, 2536.00, 1102);
INSERT INTO public.recibos_conceptos VALUES (28113, 11, 21133.30, 1102);
INSERT INTO public.recibos_conceptos VALUES (28114, 39, 98759.20, 1102);
INSERT INTO public.recibos_conceptos VALUES (28115, 1, 17250.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28116, 7, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28117, 12, 1725.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28118, 4, 17250.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28119, 5, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28120, 6, 1035.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28121, 13, 1667.50, 1103);
INSERT INTO public.recibos_conceptos VALUES (28124, 15, 21677.50, 1103);
INSERT INTO public.recibos_conceptos VALUES (28125, 17, 2384.53, 1103);
INSERT INTO public.recibos_conceptos VALUES (28126, 18, 650.33, 1103);
INSERT INTO public.recibos_conceptos VALUES (28127, 19, 650.33, 1103);
INSERT INTO public.recibos_conceptos VALUES (28128, 20, 541.94, 1103);
INSERT INTO public.recibos_conceptos VALUES (28129, 21, 4227.11, 1103);
INSERT INTO public.recibos_conceptos VALUES (28130, 22, 17450.39, 1103);
INSERT INTO public.recibos_conceptos VALUES (28131, 23, 34900.78, 1103);
INSERT INTO public.recibos_conceptos VALUES (28132, 32, 1745.04, 1103);
INSERT INTO public.recibos_conceptos VALUES (28133, 24, 68679.19, 1103);
INSERT INTO public.recibos_conceptos VALUES (28134, 25, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28135, 26, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28137, 27, 14308.17, 1103);
INSERT INTO public.recibos_conceptos VALUES (28138, 28, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28140, 31, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28141, 33, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28142, 34, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28143, 35, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28144, 36, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28145, 37, 82987.36, 1103);
INSERT INTO public.recibos_conceptos VALUES (28146, 38, -48086.58, 1103);
INSERT INTO public.recibos_conceptos VALUES (28147, 40, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28148, 9, 600.30, 1103);
INSERT INTO public.recibos_conceptos VALUES (28149, 10, 600.30, 1103);
INSERT INTO public.recibos_conceptos VALUES (28150, 11, 5002.50, 1103);
INSERT INTO public.recibos_conceptos VALUES (28151, 39, 0.00, 1103);
INSERT INTO public.recibos_conceptos VALUES (28152, 1, 60000.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28153, 7, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28154, 12, 6000.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28155, 4, 60000.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28156, 5, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28157, 6, 13200.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28158, 13, 6600.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28161, 15, 85800.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28162, 17, 9438.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28163, 18, 2574.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28164, 19, 2574.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28165, 20, 2145.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28166, 21, 16731.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28167, 22, 69069.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28168, 23, 137091.50, 1104);
INSERT INTO public.recibos_conceptos VALUES (28169, 32, 6854.58, 1104);
INSERT INTO public.recibos_conceptos VALUES (28170, 24, 68679.19, 1104);
INSERT INTO public.recibos_conceptos VALUES (28171, 25, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28172, 26, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28174, 27, 14308.17, 1104);
INSERT INTO public.recibos_conceptos VALUES (28175, 28, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28177, 31, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28178, 33, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28179, 34, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28180, 35, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28181, 36, 0.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28182, 37, 82987.36, 1104);
INSERT INTO public.recibos_conceptos VALUES (28183, 38, 54104.14, 1104);
INSERT INTO public.recibos_conceptos VALUES (28184, 40, 278261.91, 1104);
INSERT INTO public.recibos_conceptos VALUES (28185, 9, 2376.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28186, 10, 2376.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28187, 11, 19800.00, 1104);
INSERT INTO public.recibos_conceptos VALUES (28188, 39, 153258.70, 1104);
INSERT INTO public.recibos_conceptos VALUES (28189, 1, 35033.10, 1105);
INSERT INTO public.recibos_conceptos VALUES (28190, 7, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28191, 12, 3503.31, 1105);
INSERT INTO public.recibos_conceptos VALUES (28192, 4, 35033.10, 1105);
INSERT INTO public.recibos_conceptos VALUES (28193, 5, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28194, 6, 3503.31, 1105);
INSERT INTO public.recibos_conceptos VALUES (28195, 13, 3503.31, 1105);
INSERT INTO public.recibos_conceptos VALUES (28198, 15, 45543.03, 1105);
INSERT INTO public.recibos_conceptos VALUES (28199, 17, 5009.73, 1105);
INSERT INTO public.recibos_conceptos VALUES (28200, 18, 1366.29, 1105);
INSERT INTO public.recibos_conceptos VALUES (28201, 19, 1366.29, 1105);
INSERT INTO public.recibos_conceptos VALUES (28202, 20, 1138.58, 1105);
INSERT INTO public.recibos_conceptos VALUES (28203, 21, 8880.89, 1105);
INSERT INTO public.recibos_conceptos VALUES (28204, 22, 36662.14, 1105);
INSERT INTO public.recibos_conceptos VALUES (28205, 23, 73324.28, 1105);
INSERT INTO public.recibos_conceptos VALUES (28206, 32, 3666.21, 1105);
INSERT INTO public.recibos_conceptos VALUES (28207, 24, 68679.19, 1105);
INSERT INTO public.recibos_conceptos VALUES (28208, 25, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28209, 26, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28211, 27, 14308.17, 1105);
INSERT INTO public.recibos_conceptos VALUES (28212, 28, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28214, 31, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28215, 33, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28216, 34, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28217, 35, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28218, 36, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28219, 37, 82987.36, 1105);
INSERT INTO public.recibos_conceptos VALUES (28220, 38, -9663.08, 1105);
INSERT INTO public.recibos_conceptos VALUES (28221, 40, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28222, 9, 1261.19, 1105);
INSERT INTO public.recibos_conceptos VALUES (28223, 10, 1261.19, 1105);
INSERT INTO public.recibos_conceptos VALUES (28224, 11, 10509.93, 1105);
INSERT INTO public.recibos_conceptos VALUES (28225, 39, 0.00, 1105);
INSERT INTO public.recibos_conceptos VALUES (28226, 1, 46839.10, 1106);
INSERT INTO public.recibos_conceptos VALUES (28227, 7, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28228, 12, 4683.91, 1106);
INSERT INTO public.recibos_conceptos VALUES (28229, 4, 46839.10, 1106);
INSERT INTO public.recibos_conceptos VALUES (28230, 5, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28231, 6, 14051.73, 1106);
INSERT INTO public.recibos_conceptos VALUES (28232, 13, 5464.56, 1106);
INSERT INTO public.recibos_conceptos VALUES (28235, 15, 71039.30, 1106);
INSERT INTO public.recibos_conceptos VALUES (28236, 17, 7814.32, 1106);
INSERT INTO public.recibos_conceptos VALUES (28237, 18, 2131.18, 1106);
INSERT INTO public.recibos_conceptos VALUES (28238, 19, 2131.18, 1106);
INSERT INTO public.recibos_conceptos VALUES (28239, 20, 1775.98, 1106);
INSERT INTO public.recibos_conceptos VALUES (28240, 21, 13852.66, 1106);
INSERT INTO public.recibos_conceptos VALUES (28241, 22, 57186.64, 1106);
INSERT INTO public.recibos_conceptos VALUES (28242, 23, 114373.28, 1106);
INSERT INTO public.recibos_conceptos VALUES (28243, 32, 5718.66, 1106);
INSERT INTO public.recibos_conceptos VALUES (28244, 24, 68679.19, 1106);
INSERT INTO public.recibos_conceptos VALUES (28245, 25, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28246, 26, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28248, 27, 14308.17, 1106);
INSERT INTO public.recibos_conceptos VALUES (28249, 28, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28251, 31, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28252, 33, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28253, 34, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28254, 35, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28255, 36, 0.00, 1106);
INSERT INTO public.recibos_conceptos VALUES (28256, 37, 82987.36, 1106);
INSERT INTO public.recibos_conceptos VALUES (28257, 38, 31385.92, 1106);
INSERT INTO public.recibos_conceptos VALUES (28258, 40, 180085.90, 1106);
INSERT INTO public.recibos_conceptos VALUES (28259, 9, 1967.24, 1106);
INSERT INTO public.recibos_conceptos VALUES (28260, 10, 1967.24, 1106);
INSERT INTO public.recibos_conceptos VALUES (28261, 11, 16393.69, 1106);
INSERT INTO public.recibos_conceptos VALUES (28262, 39, 90042.97, 1106);
INSERT INTO public.recibos_conceptos VALUES (28263, 1, 42666.80, 1107);
INSERT INTO public.recibos_conceptos VALUES (28264, 7, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28265, 12, 4266.68, 1107);
INSERT INTO public.recibos_conceptos VALUES (28266, 4, 42666.80, 1107);
INSERT INTO public.recibos_conceptos VALUES (28267, 5, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28268, 6, 10240.03, 1107);
INSERT INTO public.recibos_conceptos VALUES (28269, 13, 4764.46, 1107);
INSERT INTO public.recibos_conceptos VALUES (28272, 15, 61937.97, 1107);
INSERT INTO public.recibos_conceptos VALUES (28273, 17, 6813.18, 1107);
INSERT INTO public.recibos_conceptos VALUES (28274, 18, 1858.14, 1107);
INSERT INTO public.recibos_conceptos VALUES (28275, 19, 1858.14, 1107);
INSERT INTO public.recibos_conceptos VALUES (28276, 20, 1548.45, 1107);
INSERT INTO public.recibos_conceptos VALUES (28277, 21, 12077.90, 1107);
INSERT INTO public.recibos_conceptos VALUES (28278, 22, 49860.07, 1107);
INSERT INTO public.recibos_conceptos VALUES (28279, 23, 99720.14, 1107);
INSERT INTO public.recibos_conceptos VALUES (28280, 32, 4986.01, 1107);
INSERT INTO public.recibos_conceptos VALUES (28281, 24, 68679.19, 1107);
INSERT INTO public.recibos_conceptos VALUES (28282, 25, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28283, 26, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28285, 27, 14308.17, 1107);
INSERT INTO public.recibos_conceptos VALUES (28286, 28, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28288, 31, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28289, 33, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28290, 34, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28291, 35, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28292, 36, 0.00, 1107);
INSERT INTO public.recibos_conceptos VALUES (28293, 37, 82987.36, 1107);
INSERT INTO public.recibos_conceptos VALUES (28294, 38, 16732.78, 1107);
INSERT INTO public.recibos_conceptos VALUES (28295, 40, 4624.88, 1107);
INSERT INTO public.recibos_conceptos VALUES (28296, 9, 1715.21, 1107);
INSERT INTO public.recibos_conceptos VALUES (28297, 10, 1715.21, 1107);
INSERT INTO public.recibos_conceptos VALUES (28298, 11, 14293.38, 1107);
INSERT INTO public.recibos_conceptos VALUES (28299, 39, 2312.47, 1107);
INSERT INTO public.recibos_conceptos VALUES (28300, 1, 42012.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28301, 7, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28302, 12, 4201.20, 1108);
INSERT INTO public.recibos_conceptos VALUES (28303, 4, 42012.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28305, 6, 31088.88, 1108);
INSERT INTO public.recibos_conceptos VALUES (28306, 13, 6441.84, 1108);
INSERT INTO public.recibos_conceptos VALUES (28309, 15, 83743.92, 1108);
INSERT INTO public.recibos_conceptos VALUES (28310, 17, 9211.83, 1108);
INSERT INTO public.recibos_conceptos VALUES (28311, 18, 2512.32, 1108);
INSERT INTO public.recibos_conceptos VALUES (28312, 19, 2512.32, 1108);
INSERT INTO public.recibos_conceptos VALUES (28313, 20, 2093.60, 1108);
INSERT INTO public.recibos_conceptos VALUES (28314, 21, 16330.06, 1108);
INSERT INTO public.recibos_conceptos VALUES (28315, 22, 67413.86, 1108);
INSERT INTO public.recibos_conceptos VALUES (28316, 23, 134827.72, 1108);
INSERT INTO public.recibos_conceptos VALUES (28317, 32, 6741.39, 1108);
INSERT INTO public.recibos_conceptos VALUES (28318, 24, 68679.19, 1108);
INSERT INTO public.recibos_conceptos VALUES (28319, 25, 13339.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28320, 26, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28322, 27, 14308.17, 1108);
INSERT INTO public.recibos_conceptos VALUES (28323, 28, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28325, 31, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28326, 33, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28327, 34, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28328, 35, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28329, 36, 0.00, 1108);
INSERT INTO public.recibos_conceptos VALUES (28330, 37, 96326.36, 1108);
INSERT INTO public.recibos_conceptos VALUES (28331, 38, 38501.36, 1108);
INSERT INTO public.recibos_conceptos VALUES (28332, 40, 129965.79, 1108);
INSERT INTO public.recibos_conceptos VALUES (28333, 9, 2319.06, 1108);
INSERT INTO public.recibos_conceptos VALUES (28334, 10, 2319.06, 1108);
INSERT INTO public.recibos_conceptos VALUES (28335, 11, 19325.52, 1108);
INSERT INTO public.recibos_conceptos VALUES (28336, 39, 64982.83, 1108);
INSERT INTO public.recibos_conceptos VALUES (28337, 1, 42717.50, 1109);
INSERT INTO public.recibos_conceptos VALUES (28338, 7, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28339, 12, 4271.75, 1109);
INSERT INTO public.recibos_conceptos VALUES (28340, 4, 42717.50, 1109);
INSERT INTO public.recibos_conceptos VALUES (28341, 5, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28342, 6, 7689.15, 1109);
INSERT INTO public.recibos_conceptos VALUES (28343, 13, 4556.53, 1109);
INSERT INTO public.recibos_conceptos VALUES (28346, 15, 59234.93, 1109);
INSERT INTO public.recibos_conceptos VALUES (28347, 17, 6515.84, 1109);
INSERT INTO public.recibos_conceptos VALUES (28348, 18, 1777.05, 1109);
INSERT INTO public.recibos_conceptos VALUES (28349, 19, 1777.05, 1109);
INSERT INTO public.recibos_conceptos VALUES (28350, 20, 1480.87, 1109);
INSERT INTO public.recibos_conceptos VALUES (28351, 21, 11550.81, 1109);
INSERT INTO public.recibos_conceptos VALUES (28352, 22, 47684.12, 1109);
INSERT INTO public.recibos_conceptos VALUES (28353, 23, 95368.24, 1109);
INSERT INTO public.recibos_conceptos VALUES (28354, 32, 4768.41, 1109);
INSERT INTO public.recibos_conceptos VALUES (28355, 24, 68679.19, 1109);
INSERT INTO public.recibos_conceptos VALUES (28356, 25, 13339.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28357, 26, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28359, 27, 14308.17, 1109);
INSERT INTO public.recibos_conceptos VALUES (28360, 28, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28362, 31, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28363, 33, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28364, 34, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28365, 35, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28366, 36, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28367, 37, 96326.36, 1109);
INSERT INTO public.recibos_conceptos VALUES (28368, 38, -958.12, 1109);
INSERT INTO public.recibos_conceptos VALUES (28369, 40, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28370, 9, 1640.35, 1109);
INSERT INTO public.recibos_conceptos VALUES (28371, 10, 1640.35, 1109);
INSERT INTO public.recibos_conceptos VALUES (28372, 11, 13669.60, 1109);
INSERT INTO public.recibos_conceptos VALUES (28373, 39, 0.00, 1109);
INSERT INTO public.recibos_conceptos VALUES (28374, 1, 38158.50, 1110);
INSERT INTO public.recibos_conceptos VALUES (28375, 7, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28376, 12, 3815.85, 1110);
INSERT INTO public.recibos_conceptos VALUES (28377, 4, 38158.50, 1110);
INSERT INTO public.recibos_conceptos VALUES (28378, 5, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28379, 6, 3052.68, 1110);
INSERT INTO public.recibos_conceptos VALUES (28380, 13, 3752.25, 1110);
INSERT INTO public.recibos_conceptos VALUES (28383, 15, 48779.28, 1110);
INSERT INTO public.recibos_conceptos VALUES (28384, 17, 5365.72, 1110);
INSERT INTO public.recibos_conceptos VALUES (28385, 18, 1463.38, 1110);
INSERT INTO public.recibos_conceptos VALUES (28386, 19, 1463.38, 1110);
INSERT INTO public.recibos_conceptos VALUES (28387, 20, 1219.48, 1110);
INSERT INTO public.recibos_conceptos VALUES (28388, 21, 9511.96, 1110);
INSERT INTO public.recibos_conceptos VALUES (28389, 22, 39267.32, 1110);
INSERT INTO public.recibos_conceptos VALUES (28390, 23, 78534.64, 1110);
INSERT INTO public.recibos_conceptos VALUES (28391, 32, 3926.73, 1110);
INSERT INTO public.recibos_conceptos VALUES (28392, 24, 68679.19, 1110);
INSERT INTO public.recibos_conceptos VALUES (28393, 25, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28394, 26, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28396, 27, 14308.17, 1110);
INSERT INTO public.recibos_conceptos VALUES (28397, 28, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28399, 31, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28400, 33, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28401, 34, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28402, 35, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28403, 36, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28404, 37, 82987.36, 1110);
INSERT INTO public.recibos_conceptos VALUES (28405, 38, -4452.72, 1110);
INSERT INTO public.recibos_conceptos VALUES (28406, 40, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28407, 9, 1350.81, 1110);
INSERT INTO public.recibos_conceptos VALUES (28408, 10, 1350.81, 1110);
INSERT INTO public.recibos_conceptos VALUES (28409, 11, 11256.76, 1110);
INSERT INTO public.recibos_conceptos VALUES (28410, 39, 0.00, 1110);
INSERT INTO public.recibos_conceptos VALUES (28411, 1, 15764.70, 1111);
INSERT INTO public.recibos_conceptos VALUES (28412, 7, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28413, 12, 1576.47, 1111);
INSERT INTO public.recibos_conceptos VALUES (28414, 4, 15764.70, 1111);
INSERT INTO public.recibos_conceptos VALUES (28415, 5, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28416, 6, 630.59, 1111);
INSERT INTO public.recibos_conceptos VALUES (28417, 13, 1497.65, 1111);
INSERT INTO public.recibos_conceptos VALUES (28420, 15, 19469.40, 1111);
INSERT INTO public.recibos_conceptos VALUES (28421, 17, 2141.63, 1111);
INSERT INTO public.recibos_conceptos VALUES (28422, 18, 584.08, 1111);
INSERT INTO public.recibos_conceptos VALUES (28423, 19, 584.08, 1111);
INSERT INTO public.recibos_conceptos VALUES (28424, 20, 486.74, 1111);
INSERT INTO public.recibos_conceptos VALUES (28425, 21, 3796.53, 1111);
INSERT INTO public.recibos_conceptos VALUES (28426, 22, 15672.87, 1111);
INSERT INTO public.recibos_conceptos VALUES (28427, 23, 31345.74, 1111);
INSERT INTO public.recibos_conceptos VALUES (28428, 32, 1567.29, 1111);
INSERT INTO public.recibos_conceptos VALUES (28429, 24, 68679.19, 1111);
INSERT INTO public.recibos_conceptos VALUES (28430, 25, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28431, 26, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28433, 27, 14308.17, 1111);
INSERT INTO public.recibos_conceptos VALUES (28434, 28, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28436, 31, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28437, 33, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28438, 34, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28439, 35, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28440, 36, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28441, 37, 82987.36, 1111);
INSERT INTO public.recibos_conceptos VALUES (28442, 38, -51641.62, 1111);
INSERT INTO public.recibos_conceptos VALUES (28443, 40, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28444, 9, 539.15, 1111);
INSERT INTO public.recibos_conceptos VALUES (28445, 10, 539.15, 1111);
INSERT INTO public.recibos_conceptos VALUES (28446, 11, 4492.94, 1111);
INSERT INTO public.recibos_conceptos VALUES (28447, 39, 0.00, 1111);
INSERT INTO public.recibos_conceptos VALUES (28448, 1, 39104.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28449, 7, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28450, 12, 3910.40, 1112);
INSERT INTO public.recibos_conceptos VALUES (28451, 4, 39104.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28452, 5, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28453, 6, 8602.88, 1112);
INSERT INTO public.recibos_conceptos VALUES (28454, 13, 4301.44, 1112);
INSERT INTO public.recibos_conceptos VALUES (28457, 15, 55918.72, 1112);
INSERT INTO public.recibos_conceptos VALUES (28458, 17, 6151.06, 1112);
INSERT INTO public.recibos_conceptos VALUES (28459, 18, 1677.56, 1112);
INSERT INTO public.recibos_conceptos VALUES (28460, 19, 1677.56, 1112);
INSERT INTO public.recibos_conceptos VALUES (28461, 20, 1397.97, 1112);
INSERT INTO public.recibos_conceptos VALUES (28462, 21, 10904.15, 1112);
INSERT INTO public.recibos_conceptos VALUES (28463, 22, 45014.57, 1112);
INSERT INTO public.recibos_conceptos VALUES (28464, 23, 90029.14, 1112);
INSERT INTO public.recibos_conceptos VALUES (28465, 32, 4501.46, 1112);
INSERT INTO public.recibos_conceptos VALUES (28466, 24, 68679.19, 1112);
INSERT INTO public.recibos_conceptos VALUES (28467, 25, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28468, 26, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28470, 27, 14308.17, 1112);
INSERT INTO public.recibos_conceptos VALUES (28471, 28, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28473, 31, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28474, 33, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28475, 34, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28476, 35, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28477, 36, 0.00, 1112);
INSERT INTO public.recibos_conceptos VALUES (28478, 37, 82987.36, 1112);
INSERT INTO public.recibos_conceptos VALUES (28479, 38, 7041.78, 1112);
INSERT INTO public.recibos_conceptos VALUES (28480, 40, 14091.68, 1112);
INSERT INTO public.recibos_conceptos VALUES (28481, 9, 1548.52, 1112);
INSERT INTO public.recibos_conceptos VALUES (28482, 10, 1548.52, 1112);
INSERT INTO public.recibos_conceptos VALUES (28483, 11, 12904.32, 1112);
INSERT INTO public.recibos_conceptos VALUES (28484, 39, 7045.88, 1112);
INSERT INTO public.recibos_conceptos VALUES (28485, 1, 45948.50, 1113);
INSERT INTO public.recibos_conceptos VALUES (28486, 7, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28487, 12, 4594.85, 1113);
INSERT INTO public.recibos_conceptos VALUES (28488, 4, 45948.50, 1113);
INSERT INTO public.recibos_conceptos VALUES (28489, 5, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28490, 6, 29407.04, 1113);
INSERT INTO public.recibos_conceptos VALUES (28491, 13, 6662.53, 1113);
INSERT INTO public.recibos_conceptos VALUES (28494, 15, 86612.92, 1113);
INSERT INTO public.recibos_conceptos VALUES (28495, 17, 9527.42, 1113);
INSERT INTO public.recibos_conceptos VALUES (28496, 18, 2598.39, 1113);
INSERT INTO public.recibos_conceptos VALUES (28497, 19, 2598.39, 1113);
INSERT INTO public.recibos_conceptos VALUES (28498, 20, 2165.32, 1113);
INSERT INTO public.recibos_conceptos VALUES (28499, 21, 16889.52, 1113);
INSERT INTO public.recibos_conceptos VALUES (28500, 22, 69723.40, 1113);
INSERT INTO public.recibos_conceptos VALUES (28501, 23, 139446.80, 1113);
INSERT INTO public.recibos_conceptos VALUES (28502, 32, 6972.34, 1113);
INSERT INTO public.recibos_conceptos VALUES (28503, 24, 68679.19, 1113);
INSERT INTO public.recibos_conceptos VALUES (28504, 25, 13339.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28505, 26, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28507, 27, 14308.17, 1113);
INSERT INTO public.recibos_conceptos VALUES (28508, 28, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28510, 31, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28511, 33, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28512, 34, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28513, 35, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28514, 36, 0.00, 1113);
INSERT INTO public.recibos_conceptos VALUES (28515, 37, 96326.36, 1113);
INSERT INTO public.recibos_conceptos VALUES (28516, 38, 43120.44, 1113);
INSERT INTO public.recibos_conceptos VALUES (28517, 40, 236204.79, 1113);
INSERT INTO public.recibos_conceptos VALUES (28518, 9, 2398.51, 1113);
INSERT INTO public.recibos_conceptos VALUES (28519, 10, 2398.51, 1113);
INSERT INTO public.recibos_conceptos VALUES (28520, 11, 19987.60, 1113);
INSERT INTO public.recibos_conceptos VALUES (28521, 39, 118102.25, 1113);
INSERT INTO public.recibos_conceptos VALUES (28522, 1, 34958.80, 1114);
INSERT INTO public.recibos_conceptos VALUES (28523, 7, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28524, 12, 3495.88, 1114);
INSERT INTO public.recibos_conceptos VALUES (28525, 4, 34958.80, 1114);
INSERT INTO public.recibos_conceptos VALUES (28526, 5, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28527, 6, 3495.88, 1114);
INSERT INTO public.recibos_conceptos VALUES (28528, 13, 3495.88, 1114);
INSERT INTO public.recibos_conceptos VALUES (28531, 15, 45446.44, 1114);
INSERT INTO public.recibos_conceptos VALUES (28532, 17, 4999.11, 1114);
INSERT INTO public.recibos_conceptos VALUES (28533, 18, 1363.39, 1114);
INSERT INTO public.recibos_conceptos VALUES (28534, 19, 1363.39, 1114);
INSERT INTO public.recibos_conceptos VALUES (28535, 20, 1136.16, 1114);
INSERT INTO public.recibos_conceptos VALUES (28536, 21, 8862.06, 1114);
INSERT INTO public.recibos_conceptos VALUES (28537, 22, 36584.38, 1114);
INSERT INTO public.recibos_conceptos VALUES (28538, 23, 73168.76, 1114);
INSERT INTO public.recibos_conceptos VALUES (28539, 32, 3658.44, 1114);
INSERT INTO public.recibos_conceptos VALUES (28540, 24, 68679.19, 1114);
INSERT INTO public.recibos_conceptos VALUES (28541, 25, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28542, 26, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28544, 27, 14308.17, 1114);
INSERT INTO public.recibos_conceptos VALUES (28545, 28, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28547, 31, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28548, 33, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28549, 34, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28550, 35, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28551, 36, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28552, 37, 82987.36, 1114);
INSERT INTO public.recibos_conceptos VALUES (28553, 38, -9818.60, 1114);
INSERT INTO public.recibos_conceptos VALUES (28554, 40, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28555, 9, 1258.52, 1114);
INSERT INTO public.recibos_conceptos VALUES (28556, 10, 1258.52, 1114);
INSERT INTO public.recibos_conceptos VALUES (28557, 11, 10487.64, 1114);
INSERT INTO public.recibos_conceptos VALUES (28558, 39, 0.00, 1114);
INSERT INTO public.recibos_conceptos VALUES (28559, 1, 57061.70, 1115);
INSERT INTO public.recibos_conceptos VALUES (28560, 7, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28561, 12, 5706.17, 1115);
INSERT INTO public.recibos_conceptos VALUES (28562, 4, 57061.70, 1115);
INSERT INTO public.recibos_conceptos VALUES (28563, 5, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28564, 6, 36519.49, 1115);
INSERT INTO public.recibos_conceptos VALUES (28565, 13, 8273.95, 1115);
INSERT INTO public.recibos_conceptos VALUES (28568, 15, 107561.30, 1115);
INSERT INTO public.recibos_conceptos VALUES (28569, 17, 11831.74, 1115);
INSERT INTO public.recibos_conceptos VALUES (28570, 18, 3226.84, 1115);
INSERT INTO public.recibos_conceptos VALUES (28571, 19, 3226.84, 1115);
INSERT INTO public.recibos_conceptos VALUES (28572, 20, 2689.03, 1115);
INSERT INTO public.recibos_conceptos VALUES (28573, 21, 20974.45, 1115);
INSERT INTO public.recibos_conceptos VALUES (28574, 22, 86586.85, 1115);
INSERT INTO public.recibos_conceptos VALUES (28575, 23, 173173.70, 1115);
INSERT INTO public.recibos_conceptos VALUES (28576, 32, 8658.69, 1115);
INSERT INTO public.recibos_conceptos VALUES (28577, 24, 68679.19, 1115);
INSERT INTO public.recibos_conceptos VALUES (28578, 25, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28579, 26, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28581, 27, 14308.17, 1115);
INSERT INTO public.recibos_conceptos VALUES (28582, 28, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28584, 31, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28585, 33, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28586, 34, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28587, 35, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28588, 36, 0.00, 1115);
INSERT INTO public.recibos_conceptos VALUES (28589, 37, 82987.36, 1115);
INSERT INTO public.recibos_conceptos VALUES (28590, 38, 90186.34, 1115);
INSERT INTO public.recibos_conceptos VALUES (28591, 40, 92465.34, 1115);
INSERT INTO public.recibos_conceptos VALUES (28592, 9, 2978.62, 1115);
INSERT INTO public.recibos_conceptos VALUES (28593, 10, 2978.62, 1115);
INSERT INTO public.recibos_conceptos VALUES (28594, 11, 24821.84, 1115);
INSERT INTO public.recibos_conceptos VALUES (28595, 39, 46232.85, 1115);
INSERT INTO public.recibos_conceptos VALUES (28596, 1, 34892.86, 1116);
INSERT INTO public.recibos_conceptos VALUES (28597, 7, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28598, 12, 3489.29, 1116);
INSERT INTO public.recibos_conceptos VALUES (28599, 4, 34892.86, 1116);
INSERT INTO public.recibos_conceptos VALUES (28600, 5, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28601, 6, 697.86, 1116);
INSERT INTO public.recibos_conceptos VALUES (28602, 13, 3256.67, 1116);
INSERT INTO public.recibos_conceptos VALUES (28605, 15, 42336.67, 1116);
INSERT INTO public.recibos_conceptos VALUES (28606, 17, 4657.03, 1116);
INSERT INTO public.recibos_conceptos VALUES (28607, 18, 1270.10, 1116);
INSERT INTO public.recibos_conceptos VALUES (28608, 19, 1270.10, 1116);
INSERT INTO public.recibos_conceptos VALUES (28609, 20, 1058.42, 1116);
INSERT INTO public.recibos_conceptos VALUES (28610, 21, 8255.65, 1116);
INSERT INTO public.recibos_conceptos VALUES (28611, 22, 34081.02, 1116);
INSERT INTO public.recibos_conceptos VALUES (28612, 23, 68162.04, 1116);
INSERT INTO public.recibos_conceptos VALUES (28613, 32, 3408.10, 1116);
INSERT INTO public.recibos_conceptos VALUES (28614, 24, 68679.19, 1116);
INSERT INTO public.recibos_conceptos VALUES (28615, 25, 13339.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28616, 26, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28618, 27, 14308.17, 1116);
INSERT INTO public.recibos_conceptos VALUES (28619, 28, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28621, 31, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28622, 33, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28623, 34, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28624, 35, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28625, 36, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28626, 37, 96326.36, 1116);
INSERT INTO public.recibos_conceptos VALUES (28627, 38, -28164.32, 1116);
INSERT INTO public.recibos_conceptos VALUES (28628, 40, 0.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28629, 9, 1172.40, 1116);
INSERT INTO public.recibos_conceptos VALUES (28630, 10, 1172.40, 1116);
INSERT INTO public.recibos_conceptos VALUES (28631, 11, 9770.00, 1116);
INSERT INTO public.recibos_conceptos VALUES (28632, 39, 0.00, 1116);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 28632, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 1116, true);


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

