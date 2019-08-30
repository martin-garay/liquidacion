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
		JOIN liquidaciones l ON l.id=r.id_liquidacion;
		
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
    anio integer
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
    horas_mes numeric(10,2)
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
    l.id_pais
   FROM (public.establecimientos e
     JOIN public.v_localidades l ON ((e.id_localidad = l.id)));


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
    l.anio
   FROM ((((public.liquidaciones l
     JOIN public.estados_liquidacion el ON ((el.id = l.id_estado)))
     JOIN public.tipos_liquidaciones tl ON ((tl.id = l.id_tipo_liquidacion)))
     JOIN public.establecimientos e ON ((e.id = l.id_establecimiento)))
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
    a.fecha_egreso
   FROM (((((((((public.personas a
     LEFT JOIN public.estados_civiles ec ON ((ec.id = a.id_estado_civil)))
     LEFT JOIN public.categorias c ON ((c.id = a.id_categoria)))
     LEFT JOIN public.establecimientos es ON ((es.id = a.id_establecimiento)))
     LEFT JOIN public.obras_sociales os ON ((os.id = a.id_obra_social)))
     LEFT JOIN public.v_localidades loc ON ((loc.id = a.id_localidad)))
     LEFT JOIN public.nacionalidades n ON ((n.id = a.id_nacionalidad)))
     LEFT JOIN public.tipos_documentos td ON ((td.id = a.id_tipo_documento)))
     LEFT JOIN public.generos g ON ((g.id = a.id_genero)))
     LEFT JOIN public.tipos_contratos tc ON ((tc.id = a.id_tipo_contrato)));


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
    r.id_liquidacion
   FROM ((public.recibos_conceptos rc
     JOIN public.recibos r ON ((r.id = rc.id_recibo)))
     JOIN public.conceptos c ON ((c.id = rc.id_concepto)));


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
INSERT INTO public.conceptos VALUES (13, 'Ganancias - SAC Devengado', '301', 4, 'bruto/12', false, false, false, 'Se usa solo para calculos', NULL, false, false);
INSERT INTO public.conceptos VALUES (14, 'Ganancias - Gratificaciones', '302', 4, '0', false, false, false, 'Concepto que se para calcular el total de la remuneracion bruta', 0.00, false, false);
INSERT INTO public.conceptos VALUES (16, 'Ganancias - SAC', '303', 4, '0', false, false, false, NULL, 0.00, false, false);
INSERT INTO public.conceptos VALUES (15, 'Ganancias - tot_rem_bruta', '309', 4, 'bruto +  c301 + c302 + c303', false, false, false, 'Suma el bruto + el SAC devengado + Gratificaciones + SAC??', NULL, false, false);
INSERT INTO public.conceptos VALUES (29, 'Deducciones. Cargas de familia', '333', 4, '0', false, false, false, 'Hay que ver si se usa', 0.00, false, false);
INSERT INTO public.conceptos VALUES (30, 'Deducciones. Servicio doméstico', '336', 4, '0', false, false, false, 'Ver si se usa', 0.00, false, false);
INSERT INTO public.conceptos VALUES (23, 'Ganancia Neta Acumulada', '322', 4, NULL, false, false, false, NULL, 0.00, false, false);
INSERT INTO public.conceptos VALUES (24, 'Deducción. Especial', '330', 4, 'tabla("especiales")', false, false, false, 'Busca el valor en la tabla de deducciones especiales en el periodo de la liquidación', NULL, false, false);
INSERT INTO public.conceptos VALUES (25, 'Deduccion. Conyuge', '331', 4, 'si( casado , tabla("conyuge") , 0 )', false, false, false, 'SI es casado busca el valor en la tabla de conyuge en el periodo de la liquidacion SINO devuelve 0', NULL, false, false);
INSERT INTO public.conceptos VALUES (26, 'Deducciones. Hijos', '332', 4, 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', false, false, false, NULL, NULL, false, false);
INSERT INTO public.conceptos VALUES (27, 'Deducciones. Ganancia no imponible', '334', 4, 'tabla("ganancia")', false, false, false, 'Trae el valor de la tabla de ganancia no imponibles para el periodo de la liquidacion', NULL, false, false);
INSERT INTO public.conceptos VALUES (28, 'Deducciones. Intereses créditos hipotecarios', '335', 4, 'informado("hipoteca")', false, false, false, 'Trae el valor informado por el empleado', NULL, false, false);
INSERT INTO public.conceptos VALUES (32, 'Prepaga (5% del sueldo neto)', '323', 4, 'ganancia_neta_acumulada*0.05', false, false, false, 'Calculo auxiliar', NULL, false, false);
INSERT INTO public.conceptos VALUES (31, 'Prepaga', '337', 4, 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', false, false, false, NULL, NULL, false, false);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 32, true);


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

INSERT INTO public.establecimientos VALUES (1, 'Asociación Médica de Luján', 'Mariano Moreno 1460', 1, NULL, NULL, NULL);


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
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (31, 'Liquidacion Octubre', '2019-10-01', '2019-08-01', '2019-08-31', 1, 1, 1, '2019-08-31', 'Octubre', 'Lujan', '2019-08-31', 2, 10, 2019);
INSERT INTO public.liquidaciones VALUES (32, 'Liquidacion Octubre', '2019-01-01', '2019-08-01', '2019-08-31', 1, 1, 1, '2019-08-31', 'Octubre', 'Lujan', '2019-08-23', 2, 1, 2019);
INSERT INTO public.liquidaciones VALUES (33, 'Liquidacion Febrero', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-01-31', 'Enero', 'Lujan', '2019-08-31', 2, 1, 2019);


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (93, 1, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (94, 12, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (95, 5, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (96, 6, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (97, 7, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (98, 9, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (99, 10, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (100, 11, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (101, 4, 31, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (102, 1, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (103, 12, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (104, 5, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (105, 6, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (106, 7, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (107, 9, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (108, 10, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (109, 11, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (110, 4, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (111, 13, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (112, 15, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (113, 17, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (114, 18, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (115, 19, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (116, 20, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (117, 21, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (118, 22, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (120, 14, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (121, 16, 32, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (122, 1, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (123, 12, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (124, 5, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (125, 6, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (126, 7, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (127, 9, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (128, 10, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (129, 11, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (130, 4, 33, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (131, 24, 33, NULL);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 131, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 33, true);


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


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.persona_tareas_id_seq', 3, true);


--
-- Data for Name: personas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.personas VALUES (2, 'Martin', 'Garay', '1989-05-11', 1, '34555008', 1, 1, false, 4611, 1, 1, 1, 1, 'martingaray_12@gmail.com', '2019-07-01', '2019-08-15', '08:00:00', '15:00:00', 1, 'San Vicente 1351', '1 ', 'D         ', '01122777025', '01122777025', 1, '23345550089', 7.00, 10000.00, 0, 8.00);
INSERT INTO public.personas VALUES (12, 'Gisela Elizabeth', 'Dandrilli', '1984-08-04', 1, '30939944', 2, 1, true, 34, 2, 4, 1, 1, NULL, '2014-02-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27309399442', 7.00, 35226.50, 0, 8.00);
INSERT INTO public.personas VALUES (13, 'Noemi Severa', 'Delgado', '1956-10-27', 1, '12904169', 2, 1, true, 7, 2, 2, 1, 1, NULL, '1986-07-14', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27129041698', 7.00, 48582.30, 0, 8.00);
INSERT INTO public.personas VALUES (16, 'Rodrigo Raul', 'Ferreyra', '1989-10-10', 1, '34831908', 1, 1, true, 32, 1, 4, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20348319087', 7.00, 35033.10, 0, 8.00);
INSERT INTO public.personas VALUES (17, 'Micaela Noemi', 'Frascaroli', '1982-02-27', 1, '29233345', 2, 1, true, 19, 1, 2, 1, 1, NULL, '2003-10-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27292333450', 7.00, 46839.10, 0, 8.00);
INSERT INTO public.personas VALUES (18, 'Betiana Nazareth', 'Gallesio', '1978-01-04', 1, '26167199', 2, 1, true, 21, 1, 2, 1, 1, NULL, '2006-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27261671994', 7.00, 42666.80, 0, 8.00);
INSERT INTO public.personas VALUES (20, 'Norma Elizabeth', 'Lombardo', '1960-11-25', 1, '14097779', 2, 1, true, 27, 2, 2, 1, 1, NULL, '2009-08-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27140977794', 7.00, 42717.50, 0, 8.00);
INSERT INTO public.personas VALUES (21, 'Maria Soledad', 'Paccor', '1979-03-05', 1, '27033687', 2, 1, true, 35, 1, 3, 1, 1, NULL, '2014-11-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27270336871', 7.00, 38158.50, 0, 8.00);
INSERT INTO public.personas VALUES (22, 'Alejandra', 'Paris', '1984-05-06', 1, '30939775', 2, 1, true, 39, 1, 3, 1, 1, NULL, '2016-07-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '23309397754', 7.00, 15764.70, 0, 8.00);
INSERT INTO public.personas VALUES (23, 'Jorgelina', 'Parra', '1976-05-11', 1, '25048843', 2, 1, true, 23, 1, 3, 1, 1, NULL, '2007-07-02', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27250488438', 7.00, 39104.00, 0, 8.00);
INSERT INTO public.personas VALUES (25, 'Lautaro', 'Riccardo', '1986-05-29', 1, '32378152', 1, 1, true, 33, 1, 3, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20323781525', 7.00, 34958.80, 0, 8.00);
INSERT INTO public.personas VALUES (26, 'Ana Gladys', 'Romero', '1966-05-04', 1, '18148598', 2, 1, true, 3, 3, 1, 1, 1, NULL, '1986-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27181485987', 7.00, 57061.70, 0, 8.00);
INSERT INTO public.personas VALUES (24, 'Norma', 'Poletti', '1967-11-07', 1, '18601061', 2, 1, true, 2, 2, 2, 1, 1, NULL, '1986-09-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27186010618', 7.00, 45948.50, 0, 8.00);
INSERT INTO public.personas VALUES (15, 'Maria Cecilia', 'Ferrari', '1982-07-25', 1, '29594863', 2, 1, true, 26, 1, 3, 2, 1, NULL, '2008-02-20', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27295948634', 7.00, NULL, 0, 4.00);
INSERT INTO public.personas VALUES (14, 'Cesar Anibal', 'Echenique', '1978-12-24', 1, '27113644', 1, 1, true, 37, 1, 3, 2, 1, NULL, '2015-06-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20271136448', 7.00, 17250.00, 0, 4.00);
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1984-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 42012.00, 0, 8.00);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20268236016', 7.00, 34351.20, 0, 8.00);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265630562', 7.00, 34892.86, 0, 8.00);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265838333', 7.00, 41008.81, 0, 8.00);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27144901008', 7.00, 46807.40, 0, 8.00);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27927271414', 7.00, 24061.43, 0, 4.00);


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

INSERT INTO public.recibos VALUES (297, NULL, 8, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (298, NULL, 9, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (299, NULL, 10, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (300, NULL, 11, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (301, NULL, 12, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (302, NULL, 13, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (303, NULL, 14, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (304, NULL, 15, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (305, NULL, 16, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (306, NULL, 17, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (307, NULL, 18, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (308, NULL, 19, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (309, NULL, 20, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (310, NULL, 21, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (311, NULL, 22, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (312, NULL, 23, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (313, NULL, 24, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (314, NULL, 25, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (315, NULL, 26, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (316, NULL, 7, NULL, NULL, NULL, NULL, NULL, 31);
INSERT INTO public.recibos VALUES (317, NULL, 8, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (318, NULL, 9, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (319, NULL, 10, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (320, NULL, 11, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (321, NULL, 12, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (322, NULL, 13, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (323, NULL, 14, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (324, NULL, 15, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (325, NULL, 16, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (326, NULL, 17, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (327, NULL, 18, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (328, NULL, 19, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (329, NULL, 20, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (330, NULL, 21, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (331, NULL, 22, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (332, NULL, 23, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (333, NULL, 24, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (334, NULL, 25, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (335, NULL, 26, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (336, NULL, 7, NULL, NULL, NULL, NULL, NULL, 32);
INSERT INTO public.recibos VALUES (337, NULL, 8, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (338, NULL, 9, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (339, NULL, 10, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (340, NULL, 11, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (341, NULL, 12, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (342, NULL, 13, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (343, NULL, 14, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (344, NULL, 15, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (345, NULL, 16, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (346, NULL, 17, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (347, NULL, 18, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (348, NULL, 19, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (349, NULL, 20, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (350, NULL, 21, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (351, NULL, 22, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (352, NULL, 23, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (353, NULL, 24, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (354, NULL, 25, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (355, NULL, 26, NULL, NULL, NULL, NULL, NULL, 33);
INSERT INTO public.recibos VALUES (356, NULL, 7, NULL, NULL, NULL, NULL, NULL, 33);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (121, 1, 43282.51, 297);
INSERT INTO public.recibos_acumuladores VALUES (122, 2, 34351.20, 297);
INSERT INTO public.recibos_acumuladores VALUES (123, 1, 50030.75, 298);
INSERT INTO public.recibos_acumuladores VALUES (124, 2, 41008.81, 298);
INSERT INTO public.recibos_acumuladores VALUES (125, 1, 79572.58, 299);
INSERT INTO public.recibos_acumuladores VALUES (126, 2, 46807.40, 299);
INSERT INTO public.recibos_acumuladores VALUES (127, 1, 30798.63, 300);
INSERT INTO public.recibos_acumuladores VALUES (128, 2, 24061.43, 300);
INSERT INTO public.recibos_acumuladores VALUES (129, 1, 42271.80, 301);
INSERT INTO public.recibos_acumuladores VALUES (130, 2, 35226.50, 301);
INSERT INTO public.recibos_acumuladores VALUES (131, 1, 85504.85, 302);
INSERT INTO public.recibos_acumuladores VALUES (132, 2, 48582.30, 302);
INSERT INTO public.recibos_acumuladores VALUES (133, 1, 20355.00, 303);
INSERT INTO public.recibos_acumuladores VALUES (134, 2, 17250.00, 303);
INSERT INTO public.recibos_acumuladores VALUES (135, 1, 79200.00, 304);
INSERT INTO public.recibos_acumuladores VALUES (136, 2, 60000.00, 304);
INSERT INTO public.recibos_acumuladores VALUES (137, 1, 42039.72, 305);
INSERT INTO public.recibos_acumuladores VALUES (138, 2, 35033.10, 305);
INSERT INTO public.recibos_acumuladores VALUES (139, 1, 65574.74, 306);
INSERT INTO public.recibos_acumuladores VALUES (140, 2, 46839.10, 306);
INSERT INTO public.recibos_acumuladores VALUES (141, 1, 57173.51, 307);
INSERT INTO public.recibos_acumuladores VALUES (142, 2, 42666.80, 307);
INSERT INTO public.recibos_acumuladores VALUES (143, 1, 78142.32, 308);
INSERT INTO public.recibos_acumuladores VALUES (144, 2, 42012.00, 308);
INSERT INTO public.recibos_acumuladores VALUES (145, 1, 55532.75, 309);
INSERT INTO public.recibos_acumuladores VALUES (146, 2, 42717.50, 309);
INSERT INTO public.recibos_acumuladores VALUES (147, 1, 45027.03, 310);
INSERT INTO public.recibos_acumuladores VALUES (148, 2, 38158.50, 310);
INSERT INTO public.recibos_acumuladores VALUES (149, 1, 18287.05, 311);
INSERT INTO public.recibos_acumuladores VALUES (150, 2, 15764.70, 311);
INSERT INTO public.recibos_acumuladores VALUES (151, 1, 52399.36, 312);
INSERT INTO public.recibos_acumuladores VALUES (152, 2, 39104.00, 312);
INSERT INTO public.recibos_acumuladores VALUES (153, 1, 79950.39, 313);
INSERT INTO public.recibos_acumuladores VALUES (154, 2, 45948.50, 313);
INSERT INTO public.recibos_acumuladores VALUES (155, 1, 41950.56, 314);
INSERT INTO public.recibos_acumuladores VALUES (156, 2, 34958.80, 314);
INSERT INTO public.recibos_acumuladores VALUES (157, 1, 99287.36, 315);
INSERT INTO public.recibos_acumuladores VALUES (158, 2, 57061.70, 315);
INSERT INTO public.recibos_acumuladores VALUES (159, 1, 39777.86, 316);
INSERT INTO public.recibos_acumuladores VALUES (160, 2, 34892.86, 316);
INSERT INTO public.recibos_acumuladores VALUES (161, 1, 43282.51, 317);
INSERT INTO public.recibos_acumuladores VALUES (162, 2, 0.00, 317);
INSERT INTO public.recibos_acumuladores VALUES (163, 3, 43282.51, 317);
INSERT INTO public.recibos_acumuladores VALUES (164, 4, 0.00, 317);
INSERT INTO public.recibos_acumuladores VALUES (165, 5, 13417.58, 317);
INSERT INTO public.recibos_acumuladores VALUES (166, 1, 50030.75, 318);
INSERT INTO public.recibos_acumuladores VALUES (167, 2, 0.00, 318);
INSERT INTO public.recibos_acumuladores VALUES (168, 3, 50030.75, 318);
INSERT INTO public.recibos_acumuladores VALUES (169, 4, 0.00, 318);
INSERT INTO public.recibos_acumuladores VALUES (170, 5, 15509.53, 318);
INSERT INTO public.recibos_acumuladores VALUES (171, 1, 79572.58, 319);
INSERT INTO public.recibos_acumuladores VALUES (172, 2, 0.00, 319);
INSERT INTO public.recibos_acumuladores VALUES (173, 3, 79572.58, 319);
INSERT INTO public.recibos_acumuladores VALUES (174, 4, 0.00, 319);
INSERT INTO public.recibos_acumuladores VALUES (175, 5, 24667.50, 319);
INSERT INTO public.recibos_acumuladores VALUES (176, 1, 30798.63, 320);
INSERT INTO public.recibos_acumuladores VALUES (177, 2, 0.00, 320);
INSERT INTO public.recibos_acumuladores VALUES (178, 3, 30798.63, 320);
INSERT INTO public.recibos_acumuladores VALUES (179, 4, 0.00, 320);
INSERT INTO public.recibos_acumuladores VALUES (180, 5, 9547.58, 320);
INSERT INTO public.recibos_acumuladores VALUES (181, 1, 42271.80, 321);
INSERT INTO public.recibos_acumuladores VALUES (182, 2, 0.00, 321);
INSERT INTO public.recibos_acumuladores VALUES (183, 3, 42271.80, 321);
INSERT INTO public.recibos_acumuladores VALUES (184, 4, 0.00, 321);
INSERT INTO public.recibos_acumuladores VALUES (185, 5, 13104.26, 321);
INSERT INTO public.recibos_acumuladores VALUES (186, 1, 85504.85, 322);
INSERT INTO public.recibos_acumuladores VALUES (187, 2, 0.00, 322);
INSERT INTO public.recibos_acumuladores VALUES (188, 3, 85504.85, 322);
INSERT INTO public.recibos_acumuladores VALUES (189, 4, 0.00, 322);
INSERT INTO public.recibos_acumuladores VALUES (190, 5, 26506.50, 322);
INSERT INTO public.recibos_acumuladores VALUES (191, 1, 20355.00, 323);
INSERT INTO public.recibos_acumuladores VALUES (192, 2, 0.00, 323);
INSERT INTO public.recibos_acumuladores VALUES (193, 3, 20355.00, 323);
INSERT INTO public.recibos_acumuladores VALUES (194, 4, 0.00, 323);
INSERT INTO public.recibos_acumuladores VALUES (195, 5, 6310.05, 323);
INSERT INTO public.recibos_acumuladores VALUES (196, 1, 79200.00, 324);
INSERT INTO public.recibos_acumuladores VALUES (197, 2, 0.00, 324);
INSERT INTO public.recibos_acumuladores VALUES (198, 3, 79200.00, 324);
INSERT INTO public.recibos_acumuladores VALUES (199, 4, 0.00, 324);
INSERT INTO public.recibos_acumuladores VALUES (200, 5, 24552.00, 324);
INSERT INTO public.recibos_acumuladores VALUES (201, 1, 42039.72, 325);
INSERT INTO public.recibos_acumuladores VALUES (202, 2, 0.00, 325);
INSERT INTO public.recibos_acumuladores VALUES (203, 3, 42039.72, 325);
INSERT INTO public.recibos_acumuladores VALUES (204, 4, 0.00, 325);
INSERT INTO public.recibos_acumuladores VALUES (205, 5, 13032.31, 325);
INSERT INTO public.recibos_acumuladores VALUES (206, 1, 65574.74, 326);
INSERT INTO public.recibos_acumuladores VALUES (207, 2, 0.00, 326);
INSERT INTO public.recibos_acumuladores VALUES (208, 3, 65574.74, 326);
INSERT INTO public.recibos_acumuladores VALUES (209, 4, 0.00, 326);
INSERT INTO public.recibos_acumuladores VALUES (210, 5, 20328.17, 326);
INSERT INTO public.recibos_acumuladores VALUES (211, 1, 57173.51, 327);
INSERT INTO public.recibos_acumuladores VALUES (212, 2, 0.00, 327);
INSERT INTO public.recibos_acumuladores VALUES (213, 3, 57173.51, 327);
INSERT INTO public.recibos_acumuladores VALUES (214, 4, 0.00, 327);
INSERT INTO public.recibos_acumuladores VALUES (215, 5, 17723.79, 327);
INSERT INTO public.recibos_acumuladores VALUES (216, 1, 78142.32, 328);
INSERT INTO public.recibos_acumuladores VALUES (217, 2, 0.00, 328);
INSERT INTO public.recibos_acumuladores VALUES (218, 3, 78142.32, 328);
INSERT INTO public.recibos_acumuladores VALUES (219, 4, 0.00, 328);
INSERT INTO public.recibos_acumuladores VALUES (220, 5, 24224.12, 328);
INSERT INTO public.recibos_acumuladores VALUES (221, 1, 55532.75, 329);
INSERT INTO public.recibos_acumuladores VALUES (222, 2, 0.00, 329);
INSERT INTO public.recibos_acumuladores VALUES (223, 3, 55532.75, 329);
INSERT INTO public.recibos_acumuladores VALUES (224, 4, 0.00, 329);
INSERT INTO public.recibos_acumuladores VALUES (225, 5, 17215.15, 329);
INSERT INTO public.recibos_acumuladores VALUES (226, 1, 45027.03, 330);
INSERT INTO public.recibos_acumuladores VALUES (227, 2, 0.00, 330);
INSERT INTO public.recibos_acumuladores VALUES (228, 3, 45027.03, 330);
INSERT INTO public.recibos_acumuladores VALUES (229, 4, 0.00, 330);
INSERT INTO public.recibos_acumuladores VALUES (230, 5, 13958.38, 330);
INSERT INTO public.recibos_acumuladores VALUES (231, 1, 18287.05, 331);
INSERT INTO public.recibos_acumuladores VALUES (232, 2, 0.00, 331);
INSERT INTO public.recibos_acumuladores VALUES (233, 3, 18287.05, 331);
INSERT INTO public.recibos_acumuladores VALUES (234, 4, 0.00, 331);
INSERT INTO public.recibos_acumuladores VALUES (235, 5, 5668.99, 331);
INSERT INTO public.recibos_acumuladores VALUES (236, 1, 52399.36, 332);
INSERT INTO public.recibos_acumuladores VALUES (237, 2, 0.00, 332);
INSERT INTO public.recibos_acumuladores VALUES (238, 3, 52399.36, 332);
INSERT INTO public.recibos_acumuladores VALUES (239, 4, 0.00, 332);
INSERT INTO public.recibos_acumuladores VALUES (240, 5, 16243.80, 332);
INSERT INTO public.recibos_acumuladores VALUES (241, 1, 79950.39, 333);
INSERT INTO public.recibos_acumuladores VALUES (242, 2, 0.00, 333);
INSERT INTO public.recibos_acumuladores VALUES (243, 3, 79950.39, 333);
INSERT INTO public.recibos_acumuladores VALUES (244, 4, 0.00, 333);
INSERT INTO public.recibos_acumuladores VALUES (245, 5, 24784.62, 333);
INSERT INTO public.recibos_acumuladores VALUES (246, 1, 41950.56, 334);
INSERT INTO public.recibos_acumuladores VALUES (247, 2, 0.00, 334);
INSERT INTO public.recibos_acumuladores VALUES (248, 3, 41950.56, 334);
INSERT INTO public.recibos_acumuladores VALUES (249, 4, 0.00, 334);
INSERT INTO public.recibos_acumuladores VALUES (250, 5, 13004.67, 334);
INSERT INTO public.recibos_acumuladores VALUES (251, 1, 99287.36, 335);
INSERT INTO public.recibos_acumuladores VALUES (252, 2, 0.00, 335);
INSERT INTO public.recibos_acumuladores VALUES (253, 3, 99287.36, 335);
INSERT INTO public.recibos_acumuladores VALUES (254, 4, 0.00, 335);
INSERT INTO public.recibos_acumuladores VALUES (255, 5, 30779.08, 335);
INSERT INTO public.recibos_acumuladores VALUES (256, 1, 39777.86, 336);
INSERT INTO public.recibos_acumuladores VALUES (257, 2, 0.00, 336);
INSERT INTO public.recibos_acumuladores VALUES (258, 3, 39777.86, 336);
INSERT INTO public.recibos_acumuladores VALUES (259, 4, 0.00, 336);
INSERT INTO public.recibos_acumuladores VALUES (260, 5, 12331.14, 336);
INSERT INTO public.recibos_acumuladores VALUES (261, 1, 42595.49, 337);
INSERT INTO public.recibos_acumuladores VALUES (262, 2, 0.00, 337);
INSERT INTO public.recibos_acumuladores VALUES (263, 3, 42595.49, 337);
INSERT INTO public.recibos_acumuladores VALUES (264, 4, 0.00, 337);
INSERT INTO public.recibos_acumuladores VALUES (265, 5, 13204.60, 337);
INSERT INTO public.recibos_acumuladores VALUES (266, 1, 49210.57, 338);
INSERT INTO public.recibos_acumuladores VALUES (267, 2, 0.00, 338);
INSERT INTO public.recibos_acumuladores VALUES (268, 3, 49210.57, 338);
INSERT INTO public.recibos_acumuladores VALUES (269, 4, 0.00, 338);
INSERT INTO public.recibos_acumuladores VALUES (270, 5, 15255.28, 338);
INSERT INTO public.recibos_acumuladores VALUES (271, 1, 79572.58, 339);
INSERT INTO public.recibos_acumuladores VALUES (272, 2, 0.00, 339);
INSERT INTO public.recibos_acumuladores VALUES (273, 3, 79572.58, 339);
INSERT INTO public.recibos_acumuladores VALUES (274, 4, 0.00, 339);
INSERT INTO public.recibos_acumuladores VALUES (275, 5, 24667.50, 339);
INSERT INTO public.recibos_acumuladores VALUES (276, 1, 30317.40, 340);
INSERT INTO public.recibos_acumuladores VALUES (277, 2, 0.00, 340);
INSERT INTO public.recibos_acumuladores VALUES (278, 3, 30317.40, 340);
INSERT INTO public.recibos_acumuladores VALUES (279, 4, 0.00, 340);
INSERT INTO public.recibos_acumuladores VALUES (280, 5, 9398.39, 340);
INSERT INTO public.recibos_acumuladores VALUES (281, 1, 41567.27, 341);
INSERT INTO public.recibos_acumuladores VALUES (282, 2, 0.00, 341);
INSERT INTO public.recibos_acumuladores VALUES (283, 3, 41567.27, 341);
INSERT INTO public.recibos_acumuladores VALUES (284, 4, 0.00, 341);
INSERT INTO public.recibos_acumuladores VALUES (285, 5, 12885.85, 341);
INSERT INTO public.recibos_acumuladores VALUES (286, 1, 84533.20, 342);
INSERT INTO public.recibos_acumuladores VALUES (287, 2, 0.00, 342);
INSERT INTO public.recibos_acumuladores VALUES (288, 3, 84533.20, 342);
INSERT INTO public.recibos_acumuladores VALUES (289, 4, 0.00, 342);
INSERT INTO public.recibos_acumuladores VALUES (290, 5, 26205.29, 342);
INSERT INTO public.recibos_acumuladores VALUES (291, 1, 20010.00, 343);
INSERT INTO public.recibos_acumuladores VALUES (292, 2, 0.00, 343);
INSERT INTO public.recibos_acumuladores VALUES (293, 3, 20010.00, 343);
INSERT INTO public.recibos_acumuladores VALUES (294, 4, 0.00, 343);
INSERT INTO public.recibos_acumuladores VALUES (295, 5, 6203.10, 343);
INSERT INTO public.recibos_acumuladores VALUES (296, 1, 78000.00, 344);
INSERT INTO public.recibos_acumuladores VALUES (297, 2, 0.00, 344);
INSERT INTO public.recibos_acumuladores VALUES (298, 3, 78000.00, 344);
INSERT INTO public.recibos_acumuladores VALUES (299, 4, 0.00, 344);
INSERT INTO public.recibos_acumuladores VALUES (300, 5, 24180.00, 344);
INSERT INTO public.recibos_acumuladores VALUES (301, 1, 42039.72, 345);
INSERT INTO public.recibos_acumuladores VALUES (302, 2, 0.00, 345);
INSERT INTO public.recibos_acumuladores VALUES (303, 3, 42039.72, 345);
INSERT INTO public.recibos_acumuladores VALUES (304, 4, 0.00, 345);
INSERT INTO public.recibos_acumuladores VALUES (305, 5, 13032.31, 345);
INSERT INTO public.recibos_acumuladores VALUES (306, 1, 65574.74, 346);
INSERT INTO public.recibos_acumuladores VALUES (307, 2, 0.00, 346);
INSERT INTO public.recibos_acumuladores VALUES (308, 3, 65574.74, 346);
INSERT INTO public.recibos_acumuladores VALUES (309, 4, 0.00, 346);
INSERT INTO public.recibos_acumuladores VALUES (310, 5, 20328.17, 346);
INSERT INTO public.recibos_acumuladores VALUES (311, 1, 57173.51, 347);
INSERT INTO public.recibos_acumuladores VALUES (312, 2, 0.00, 347);
INSERT INTO public.recibos_acumuladores VALUES (313, 3, 57173.51, 347);
INSERT INTO public.recibos_acumuladores VALUES (314, 4, 0.00, 347);
INSERT INTO public.recibos_acumuladores VALUES (315, 5, 17723.79, 347);
INSERT INTO public.recibos_acumuladores VALUES (316, 1, 77302.08, 348);
INSERT INTO public.recibos_acumuladores VALUES (317, 2, 0.00, 348);
INSERT INTO public.recibos_acumuladores VALUES (318, 3, 77302.08, 348);
INSERT INTO public.recibos_acumuladores VALUES (319, 4, 0.00, 348);
INSERT INTO public.recibos_acumuladores VALUES (320, 5, 23963.64, 348);
INSERT INTO public.recibos_acumuladores VALUES (321, 1, 54678.40, 349);
INSERT INTO public.recibos_acumuladores VALUES (322, 2, 0.00, 349);
INSERT INTO public.recibos_acumuladores VALUES (323, 3, 54678.40, 349);
INSERT INTO public.recibos_acumuladores VALUES (324, 4, 0.00, 349);
INSERT INTO public.recibos_acumuladores VALUES (325, 5, 16950.30, 349);
INSERT INTO public.recibos_acumuladores VALUES (326, 1, 45027.03, 350);
INSERT INTO public.recibos_acumuladores VALUES (327, 2, 0.00, 350);
INSERT INTO public.recibos_acumuladores VALUES (328, 3, 45027.03, 350);
INSERT INTO public.recibos_acumuladores VALUES (329, 4, 0.00, 350);
INSERT INTO public.recibos_acumuladores VALUES (330, 5, 13958.38, 350);
INSERT INTO public.recibos_acumuladores VALUES (331, 1, 17971.76, 351);
INSERT INTO public.recibos_acumuladores VALUES (332, 2, 0.00, 351);
INSERT INTO public.recibos_acumuladores VALUES (333, 3, 17971.76, 351);
INSERT INTO public.recibos_acumuladores VALUES (334, 4, 0.00, 351);
INSERT INTO public.recibos_acumuladores VALUES (335, 5, 5571.24, 351);
INSERT INTO public.recibos_acumuladores VALUES (336, 1, 51617.28, 352);
INSERT INTO public.recibos_acumuladores VALUES (337, 2, 0.00, 352);
INSERT INTO public.recibos_acumuladores VALUES (338, 3, 51617.28, 352);
INSERT INTO public.recibos_acumuladores VALUES (339, 4, 0.00, 352);
INSERT INTO public.recibos_acumuladores VALUES (340, 5, 16001.36, 352);
INSERT INTO public.recibos_acumuladores VALUES (341, 1, 79950.39, 353);
INSERT INTO public.recibos_acumuladores VALUES (342, 2, 0.00, 353);
INSERT INTO public.recibos_acumuladores VALUES (343, 3, 79950.39, 353);
INSERT INTO public.recibos_acumuladores VALUES (344, 4, 0.00, 353);
INSERT INTO public.recibos_acumuladores VALUES (345, 5, 24784.62, 353);
INSERT INTO public.recibos_acumuladores VALUES (346, 1, 41950.56, 354);
INSERT INTO public.recibos_acumuladores VALUES (347, 2, 0.00, 354);
INSERT INTO public.recibos_acumuladores VALUES (348, 3, 41950.56, 354);
INSERT INTO public.recibos_acumuladores VALUES (349, 4, 0.00, 354);
INSERT INTO public.recibos_acumuladores VALUES (350, 5, 13004.67, 354);
INSERT INTO public.recibos_acumuladores VALUES (351, 1, 99287.36, 355);
INSERT INTO public.recibos_acumuladores VALUES (352, 2, 0.00, 355);
INSERT INTO public.recibos_acumuladores VALUES (353, 3, 99287.36, 355);
INSERT INTO public.recibos_acumuladores VALUES (354, 4, 0.00, 355);
INSERT INTO public.recibos_acumuladores VALUES (355, 5, 30779.08, 355);
INSERT INTO public.recibos_acumuladores VALUES (356, 1, 39080.00, 356);
INSERT INTO public.recibos_acumuladores VALUES (357, 2, 0.00, 356);
INSERT INTO public.recibos_acumuladores VALUES (358, 3, 39080.00, 356);
INSERT INTO public.recibos_acumuladores VALUES (359, 4, 0.00, 356);
INSERT INTO public.recibos_acumuladores VALUES (360, 5, 12114.80, 356);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 360, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (1770, 5, 3.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1669, 1, 34351.20, 297);
INSERT INTO public.recibos_conceptos VALUES (1670, 12, 3435.12, 297);
INSERT INTO public.recibos_conceptos VALUES (1671, 5, 0.00, 297);
INSERT INTO public.recibos_conceptos VALUES (1672, 6, 5496.19, 297);
INSERT INTO public.recibos_conceptos VALUES (1673, 7, 0.00, 297);
INSERT INTO public.recibos_conceptos VALUES (1674, 9, 0.00, 297);
INSERT INTO public.recibos_conceptos VALUES (1675, 10, 0.00, 297);
INSERT INTO public.recibos_conceptos VALUES (1676, 11, 0.00, 297);
INSERT INTO public.recibos_conceptos VALUES (1677, 4, 34351.20, 297);
INSERT INTO public.recibos_conceptos VALUES (1678, 1, 41008.81, 298);
INSERT INTO public.recibos_conceptos VALUES (1679, 12, 4100.88, 298);
INSERT INTO public.recibos_conceptos VALUES (1680, 5, 0.00, 298);
INSERT INTO public.recibos_conceptos VALUES (1681, 6, 4921.06, 298);
INSERT INTO public.recibos_conceptos VALUES (1682, 7, 0.00, 298);
INSERT INTO public.recibos_conceptos VALUES (1683, 9, 0.00, 298);
INSERT INTO public.recibos_conceptos VALUES (1684, 10, 0.00, 298);
INSERT INTO public.recibos_conceptos VALUES (1685, 11, 0.00, 298);
INSERT INTO public.recibos_conceptos VALUES (1686, 4, 41008.81, 298);
INSERT INTO public.recibos_conceptos VALUES (1687, 1, 46807.40, 299);
INSERT INTO public.recibos_conceptos VALUES (1688, 12, 4680.74, 299);
INSERT INTO public.recibos_conceptos VALUES (1689, 5, 0.00, 299);
INSERT INTO public.recibos_conceptos VALUES (1690, 6, 28084.44, 299);
INSERT INTO public.recibos_conceptos VALUES (1691, 7, 0.00, 299);
INSERT INTO public.recibos_conceptos VALUES (1692, 9, 0.00, 299);
INSERT INTO public.recibos_conceptos VALUES (1693, 10, 0.00, 299);
INSERT INTO public.recibos_conceptos VALUES (1694, 11, 0.00, 299);
INSERT INTO public.recibos_conceptos VALUES (1695, 4, 46807.40, 299);
INSERT INTO public.recibos_conceptos VALUES (1696, 1, 24061.43, 300);
INSERT INTO public.recibos_conceptos VALUES (1697, 12, 2406.14, 300);
INSERT INTO public.recibos_conceptos VALUES (1698, 5, 0.00, 300);
INSERT INTO public.recibos_conceptos VALUES (1699, 6, 4331.06, 300);
INSERT INTO public.recibos_conceptos VALUES (1700, 7, 0.00, 300);
INSERT INTO public.recibos_conceptos VALUES (1701, 9, 0.00, 300);
INSERT INTO public.recibos_conceptos VALUES (1702, 10, 0.00, 300);
INSERT INTO public.recibos_conceptos VALUES (1703, 11, 0.00, 300);
INSERT INTO public.recibos_conceptos VALUES (1704, 4, 24061.43, 300);
INSERT INTO public.recibos_conceptos VALUES (1705, 1, 35226.50, 301);
INSERT INTO public.recibos_conceptos VALUES (1706, 12, 3522.65, 301);
INSERT INTO public.recibos_conceptos VALUES (1707, 5, 0.00, 301);
INSERT INTO public.recibos_conceptos VALUES (1708, 6, 3522.65, 301);
INSERT INTO public.recibos_conceptos VALUES (1709, 7, 0.00, 301);
INSERT INTO public.recibos_conceptos VALUES (1710, 9, 0.00, 301);
INSERT INTO public.recibos_conceptos VALUES (1711, 10, 0.00, 301);
INSERT INTO public.recibos_conceptos VALUES (1712, 11, 0.00, 301);
INSERT INTO public.recibos_conceptos VALUES (1713, 4, 35226.50, 301);
INSERT INTO public.recibos_conceptos VALUES (1714, 1, 48582.30, 302);
INSERT INTO public.recibos_conceptos VALUES (1715, 12, 4858.23, 302);
INSERT INTO public.recibos_conceptos VALUES (1716, 5, 0.00, 302);
INSERT INTO public.recibos_conceptos VALUES (1717, 6, 32064.32, 302);
INSERT INTO public.recibos_conceptos VALUES (1718, 7, 0.00, 302);
INSERT INTO public.recibos_conceptos VALUES (1719, 9, 0.00, 302);
INSERT INTO public.recibos_conceptos VALUES (1720, 10, 0.00, 302);
INSERT INTO public.recibos_conceptos VALUES (1721, 11, 0.00, 302);
INSERT INTO public.recibos_conceptos VALUES (1722, 4, 48582.30, 302);
INSERT INTO public.recibos_conceptos VALUES (1723, 1, 17250.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1724, 12, 1725.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1725, 5, 0.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1726, 6, 1380.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1727, 7, 0.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1728, 9, 0.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1729, 10, 0.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1730, 11, 0.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1731, 4, 17250.00, 303);
INSERT INTO public.recibos_conceptos VALUES (1732, 1, 60000.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1733, 12, 6000.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1734, 5, 0.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1735, 6, 13200.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1736, 7, 0.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1737, 9, 0.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1738, 10, 0.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1739, 11, 0.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1740, 4, 60000.00, 304);
INSERT INTO public.recibos_conceptos VALUES (1741, 1, 35033.10, 305);
INSERT INTO public.recibos_conceptos VALUES (1742, 12, 3503.31, 305);
INSERT INTO public.recibos_conceptos VALUES (1743, 5, 0.00, 305);
INSERT INTO public.recibos_conceptos VALUES (1744, 6, 3503.31, 305);
INSERT INTO public.recibos_conceptos VALUES (1745, 7, 0.00, 305);
INSERT INTO public.recibos_conceptos VALUES (1746, 9, 0.00, 305);
INSERT INTO public.recibos_conceptos VALUES (1747, 10, 0.00, 305);
INSERT INTO public.recibos_conceptos VALUES (1748, 11, 0.00, 305);
INSERT INTO public.recibos_conceptos VALUES (1749, 4, 35033.10, 305);
INSERT INTO public.recibos_conceptos VALUES (1750, 1, 46839.10, 306);
INSERT INTO public.recibos_conceptos VALUES (1751, 12, 4683.91, 306);
INSERT INTO public.recibos_conceptos VALUES (1752, 5, 0.00, 306);
INSERT INTO public.recibos_conceptos VALUES (1753, 6, 14051.73, 306);
INSERT INTO public.recibos_conceptos VALUES (1754, 7, 0.00, 306);
INSERT INTO public.recibos_conceptos VALUES (1755, 9, 0.00, 306);
INSERT INTO public.recibos_conceptos VALUES (1756, 10, 0.00, 306);
INSERT INTO public.recibos_conceptos VALUES (1757, 11, 0.00, 306);
INSERT INTO public.recibos_conceptos VALUES (1758, 4, 46839.10, 306);
INSERT INTO public.recibos_conceptos VALUES (1759, 1, 42666.80, 307);
INSERT INTO public.recibos_conceptos VALUES (1760, 12, 4266.68, 307);
INSERT INTO public.recibos_conceptos VALUES (1761, 5, 0.00, 307);
INSERT INTO public.recibos_conceptos VALUES (1762, 6, 10240.03, 307);
INSERT INTO public.recibos_conceptos VALUES (1763, 7, 0.00, 307);
INSERT INTO public.recibos_conceptos VALUES (1764, 9, 0.00, 307);
INSERT INTO public.recibos_conceptos VALUES (1765, 10, 0.00, 307);
INSERT INTO public.recibos_conceptos VALUES (1766, 11, 0.00, 307);
INSERT INTO public.recibos_conceptos VALUES (1767, 4, 42666.80, 307);
INSERT INTO public.recibos_conceptos VALUES (1768, 1, 42012.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1769, 12, 4201.20, 308);
INSERT INTO public.recibos_conceptos VALUES (1771, 6, 31929.12, 308);
INSERT INTO public.recibos_conceptos VALUES (1772, 7, 0.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1773, 9, 0.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1774, 10, 0.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1775, 11, 0.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1776, 4, 42012.00, 308);
INSERT INTO public.recibos_conceptos VALUES (1777, 1, 42717.50, 309);
INSERT INTO public.recibos_conceptos VALUES (1778, 12, 4271.75, 309);
INSERT INTO public.recibos_conceptos VALUES (1779, 5, 0.00, 309);
INSERT INTO public.recibos_conceptos VALUES (1780, 6, 8543.50, 309);
INSERT INTO public.recibos_conceptos VALUES (1781, 7, 0.00, 309);
INSERT INTO public.recibos_conceptos VALUES (1782, 9, 0.00, 309);
INSERT INTO public.recibos_conceptos VALUES (1783, 10, 0.00, 309);
INSERT INTO public.recibos_conceptos VALUES (1784, 11, 0.00, 309);
INSERT INTO public.recibos_conceptos VALUES (1785, 4, 42717.50, 309);
INSERT INTO public.recibos_conceptos VALUES (1786, 1, 38158.50, 310);
INSERT INTO public.recibos_conceptos VALUES (1787, 12, 3815.85, 310);
INSERT INTO public.recibos_conceptos VALUES (1788, 5, 0.00, 310);
INSERT INTO public.recibos_conceptos VALUES (1789, 6, 3052.68, 310);
INSERT INTO public.recibos_conceptos VALUES (1790, 7, 0.00, 310);
INSERT INTO public.recibos_conceptos VALUES (1791, 9, 0.00, 310);
INSERT INTO public.recibos_conceptos VALUES (1792, 10, 0.00, 310);
INSERT INTO public.recibos_conceptos VALUES (1793, 11, 0.00, 310);
INSERT INTO public.recibos_conceptos VALUES (1794, 4, 38158.50, 310);
INSERT INTO public.recibos_conceptos VALUES (1795, 1, 15764.70, 311);
INSERT INTO public.recibos_conceptos VALUES (1796, 12, 1576.47, 311);
INSERT INTO public.recibos_conceptos VALUES (1797, 5, 0.00, 311);
INSERT INTO public.recibos_conceptos VALUES (1798, 6, 945.88, 311);
INSERT INTO public.recibos_conceptos VALUES (1799, 7, 0.00, 311);
INSERT INTO public.recibos_conceptos VALUES (1800, 9, 0.00, 311);
INSERT INTO public.recibos_conceptos VALUES (1801, 10, 0.00, 311);
INSERT INTO public.recibos_conceptos VALUES (1802, 11, 0.00, 311);
INSERT INTO public.recibos_conceptos VALUES (1803, 4, 15764.70, 311);
INSERT INTO public.recibos_conceptos VALUES (1804, 1, 39104.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1805, 12, 3910.40, 312);
INSERT INTO public.recibos_conceptos VALUES (1806, 5, 0.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1807, 6, 9384.96, 312);
INSERT INTO public.recibos_conceptos VALUES (1808, 7, 0.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1809, 9, 0.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1810, 10, 0.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1811, 11, 0.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1812, 4, 39104.00, 312);
INSERT INTO public.recibos_conceptos VALUES (1813, 1, 45948.50, 313);
INSERT INTO public.recibos_conceptos VALUES (1814, 12, 4594.85, 313);
INSERT INTO public.recibos_conceptos VALUES (1815, 5, 0.00, 313);
INSERT INTO public.recibos_conceptos VALUES (1816, 6, 29407.04, 313);
INSERT INTO public.recibos_conceptos VALUES (1817, 7, 0.00, 313);
INSERT INTO public.recibos_conceptos VALUES (1818, 9, 0.00, 313);
INSERT INTO public.recibos_conceptos VALUES (1819, 10, 0.00, 313);
INSERT INTO public.recibos_conceptos VALUES (1820, 11, 0.00, 313);
INSERT INTO public.recibos_conceptos VALUES (1821, 4, 45948.50, 313);
INSERT INTO public.recibos_conceptos VALUES (1822, 1, 34958.80, 314);
INSERT INTO public.recibos_conceptos VALUES (1823, 12, 3495.88, 314);
INSERT INTO public.recibos_conceptos VALUES (1824, 5, 0.00, 314);
INSERT INTO public.recibos_conceptos VALUES (1825, 6, 3495.88, 314);
INSERT INTO public.recibos_conceptos VALUES (1826, 7, 0.00, 314);
INSERT INTO public.recibos_conceptos VALUES (1827, 9, 0.00, 314);
INSERT INTO public.recibos_conceptos VALUES (1828, 10, 0.00, 314);
INSERT INTO public.recibos_conceptos VALUES (1829, 11, 0.00, 314);
INSERT INTO public.recibos_conceptos VALUES (1830, 4, 34958.80, 314);
INSERT INTO public.recibos_conceptos VALUES (1831, 1, 57061.70, 315);
INSERT INTO public.recibos_conceptos VALUES (1832, 12, 5706.17, 315);
INSERT INTO public.recibos_conceptos VALUES (1833, 5, 0.00, 315);
INSERT INTO public.recibos_conceptos VALUES (1834, 6, 36519.49, 315);
INSERT INTO public.recibos_conceptos VALUES (1835, 7, 0.00, 315);
INSERT INTO public.recibos_conceptos VALUES (1836, 9, 0.00, 315);
INSERT INTO public.recibos_conceptos VALUES (1837, 10, 0.00, 315);
INSERT INTO public.recibos_conceptos VALUES (1838, 11, 0.00, 315);
INSERT INTO public.recibos_conceptos VALUES (1839, 4, 57061.70, 315);
INSERT INTO public.recibos_conceptos VALUES (1840, 1, 34892.86, 316);
INSERT INTO public.recibos_conceptos VALUES (1841, 12, 3489.29, 316);
INSERT INTO public.recibos_conceptos VALUES (1842, 5, 0.00, 316);
INSERT INTO public.recibos_conceptos VALUES (1843, 6, 1395.71, 316);
INSERT INTO public.recibos_conceptos VALUES (1844, 7, 0.00, 316);
INSERT INTO public.recibos_conceptos VALUES (1845, 9, 0.00, 316);
INSERT INTO public.recibos_conceptos VALUES (1846, 10, 0.00, 316);
INSERT INTO public.recibos_conceptos VALUES (1847, 11, 0.00, 316);
INSERT INTO public.recibos_conceptos VALUES (1848, 4, 34892.86, 316);
INSERT INTO public.recibos_conceptos VALUES (2269, 1, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2270, 1, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2271, 1, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2272, 1, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2273, 1, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2274, 1, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2275, 1, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2276, 1, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2277, 1, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2278, 1, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2279, 1, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2280, 1, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2281, 1, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2282, 1, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2283, 1, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2284, 1, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2285, 1, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2286, 1, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2287, 1, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2288, 1, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2289, 1, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2290, 1, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2291, 1, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2292, 1, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2293, 1, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2294, 1, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2295, 1, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2296, 1, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2297, 1, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2298, 1, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2299, 1, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2300, 1, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2301, 1, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2302, 1, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2303, 1, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2304, 1, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2305, 1, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2306, 1, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2307, 1, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2308, 1, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2309, 12, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2310, 12, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2311, 12, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2312, 12, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2313, 12, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2314, 12, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2315, 12, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2316, 12, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2317, 12, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2318, 12, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2319, 12, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2320, 12, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2321, 12, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2322, 12, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2323, 12, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2324, 12, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2325, 12, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2326, 12, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2327, 12, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2328, 12, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2329, 12, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2330, 12, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2331, 12, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2332, 12, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2333, 12, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2334, 12, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2335, 12, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2336, 12, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2337, 12, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2338, 12, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2339, 12, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2340, 12, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2341, 12, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2342, 12, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2343, 12, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2344, 12, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2345, 12, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2346, 12, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2347, 12, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2348, 12, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2349, 5, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2350, 5, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2351, 5, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2352, 5, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2353, 5, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2354, 5, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2355, 5, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2356, 5, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2357, 5, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2358, 5, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2359, 5, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2360, 5, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2361, 5, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2362, 5, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2363, 5, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2364, 5, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2365, 5, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2366, 5, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2367, 5, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2368, 5, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2369, 5, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2370, 5, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2371, 5, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2372, 5, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2373, 5, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2374, 5, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2375, 5, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2376, 5, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2377, 5, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2378, 5, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2379, 5, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2380, 5, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2381, 5, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2382, 5, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2383, 5, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2384, 5, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2385, 5, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2386, 5, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2387, 5, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2388, 5, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2389, 6, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2390, 6, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2391, 6, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2392, 6, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2393, 6, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2394, 6, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2395, 6, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2396, 6, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2397, 6, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2398, 6, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2399, 6, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2400, 6, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2401, 6, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2402, 6, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2403, 6, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2404, 6, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2405, 6, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2406, 6, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2407, 6, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2408, 6, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2409, 6, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2410, 6, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2411, 6, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2412, 6, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2413, 6, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2414, 6, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2415, 6, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2416, 6, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2417, 6, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2418, 6, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2419, 6, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2420, 6, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2421, 6, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2422, 6, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2423, 6, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2424, 6, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2425, 6, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2426, 6, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2427, 6, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2428, 6, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2429, 7, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2430, 7, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2431, 7, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2432, 7, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2433, 7, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2434, 7, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2435, 7, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2436, 7, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2437, 7, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2438, 7, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2439, 7, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2440, 7, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2441, 7, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2442, 7, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2443, 7, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2444, 7, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2445, 7, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2446, 7, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2447, 7, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2448, 7, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2449, 7, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2450, 7, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2451, 7, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2452, 7, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2453, 7, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2454, 7, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2455, 7, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2456, 7, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2457, 7, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2038, 5, 3.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2458, 7, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2459, 7, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2460, 7, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2461, 7, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2462, 7, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2463, 7, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2464, 7, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2465, 7, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2466, 7, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2467, 7, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2468, 7, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2469, 9, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2470, 9, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2471, 9, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2472, 9, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2473, 9, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2474, 9, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2475, 9, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2476, 9, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2477, 9, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2478, 9, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2479, 9, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2480, 9, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2481, 9, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2482, 9, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2483, 9, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2484, 9, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2485, 9, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2486, 9, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2487, 9, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2488, 9, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2489, 9, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2490, 9, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2491, 9, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2492, 9, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2493, 9, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2494, 9, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2495, 9, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2496, 9, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2497, 9, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2498, 9, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2499, 9, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2500, 9, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2501, 9, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2502, 9, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2503, 9, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2504, 9, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2505, 9, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2506, 9, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2507, 9, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2508, 9, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2509, 10, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2510, 10, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2511, 10, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2512, 10, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2513, 10, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2514, 10, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2515, 10, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2516, 10, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2517, 10, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2518, 10, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2519, 10, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2520, 10, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2521, 10, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2522, 10, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2523, 10, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2524, 10, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2525, 10, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2526, 10, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2527, 10, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2528, 10, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2529, 10, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2530, 10, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2531, 10, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2532, 10, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2533, 10, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2534, 10, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2535, 10, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2536, 10, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2537, 10, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2538, 10, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2539, 10, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2540, 10, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2541, 10, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2542, 10, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2543, 10, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2544, 10, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2545, 10, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2546, 10, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2547, 10, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2548, 10, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2549, 11, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2550, 11, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2551, 11, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2552, 11, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2553, 11, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2554, 11, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2555, 11, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2556, 11, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2557, 11, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2558, 11, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2559, 11, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2560, 11, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2561, 11, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2562, 11, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2563, 11, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2564, 11, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2565, 11, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2566, 11, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2567, 11, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2568, 11, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2569, 11, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2570, 11, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2571, 11, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2572, 11, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2573, 11, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2574, 11, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2575, 11, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2576, 11, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2577, 11, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2578, 11, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2579, 11, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2580, 11, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2581, 11, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2582, 11, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2583, 11, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2584, 11, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2585, 11, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2586, 11, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2587, 11, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2588, 11, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2589, 4, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2590, 4, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2591, 4, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2592, 4, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2593, 4, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2594, 4, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2595, 4, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2596, 4, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2597, 4, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2598, 4, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2599, 4, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2600, 4, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2601, 4, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2602, 4, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2603, 4, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2604, 4, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2605, 4, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2606, 4, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2607, 4, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2189, 14, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2190, 14, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2191, 14, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2192, 14, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2193, 14, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2194, 14, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2195, 14, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2196, 14, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2197, 14, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2198, 14, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2199, 14, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2200, 14, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2201, 14, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2202, 14, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2203, 14, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2204, 14, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2205, 14, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2206, 14, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2207, 14, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2208, 14, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2608, 4, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2609, 4, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2610, 4, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2611, 4, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2612, 4, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2613, 4, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2614, 4, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2615, 4, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2616, 4, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2617, 4, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2618, 4, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2619, 4, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2620, 4, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2621, 4, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2622, 4, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2623, 4, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2624, 4, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2625, 4, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2626, 4, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2627, 4, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2229, 16, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2230, 16, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2231, 16, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2232, 16, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2233, 16, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2234, 16, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2235, 16, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2236, 16, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2237, 16, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2238, 16, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2239, 16, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2240, 16, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2241, 16, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2242, 16, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2243, 16, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2244, 16, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2245, 16, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2246, 16, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2247, 16, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2248, 16, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2628, 4, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (1849, 1, 34351.20, 317);
INSERT INTO public.recibos_conceptos VALUES (1850, 12, 3435.12, 317);
INSERT INTO public.recibos_conceptos VALUES (1851, 5, 0.00, 317);
INSERT INTO public.recibos_conceptos VALUES (1852, 6, 5496.19, 317);
INSERT INTO public.recibos_conceptos VALUES (1853, 7, 0.00, 317);
INSERT INTO public.recibos_conceptos VALUES (1854, 9, 1298.48, 317);
INSERT INTO public.recibos_conceptos VALUES (1855, 10, 1298.48, 317);
INSERT INTO public.recibos_conceptos VALUES (1856, 11, 10820.63, 317);
INSERT INTO public.recibos_conceptos VALUES (1857, 4, 34351.20, 317);
INSERT INTO public.recibos_conceptos VALUES (1858, 13, 3606.88, 317);
INSERT INTO public.recibos_conceptos VALUES (1859, 15, 46889.39, 317);
INSERT INTO public.recibos_conceptos VALUES (1860, 17, 5157.83, 317);
INSERT INTO public.recibos_conceptos VALUES (1861, 18, 1406.68, 317);
INSERT INTO public.recibos_conceptos VALUES (1862, 19, 1406.68, 317);
INSERT INTO public.recibos_conceptos VALUES (1863, 20, 1172.23, 317);
INSERT INTO public.recibos_conceptos VALUES (1864, 21, 9143.43, 317);
INSERT INTO public.recibos_conceptos VALUES (1865, 22, 37745.96, 317);
INSERT INTO public.recibos_conceptos VALUES (1866, 1, 41008.81, 318);
INSERT INTO public.recibos_conceptos VALUES (1867, 12, 4100.88, 318);
INSERT INTO public.recibos_conceptos VALUES (1868, 5, 0.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1869, 6, 4921.06, 318);
INSERT INTO public.recibos_conceptos VALUES (1870, 7, 0.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1871, 9, 1500.92, 318);
INSERT INTO public.recibos_conceptos VALUES (1872, 10, 1500.92, 318);
INSERT INTO public.recibos_conceptos VALUES (1873, 11, 12507.69, 318);
INSERT INTO public.recibos_conceptos VALUES (1874, 4, 41008.81, 318);
INSERT INTO public.recibos_conceptos VALUES (1875, 13, 4169.23, 318);
INSERT INTO public.recibos_conceptos VALUES (1876, 15, 54199.98, 318);
INSERT INTO public.recibos_conceptos VALUES (1877, 17, 5962.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1878, 18, 1626.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1879, 19, 1626.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1880, 20, 1355.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1881, 21, 10569.00, 318);
INSERT INTO public.recibos_conceptos VALUES (1882, 22, 43630.98, 318);
INSERT INTO public.recibos_conceptos VALUES (1883, 1, 46807.40, 319);
INSERT INTO public.recibos_conceptos VALUES (1884, 12, 4680.74, 319);
INSERT INTO public.recibos_conceptos VALUES (1885, 5, 0.00, 319);
INSERT INTO public.recibos_conceptos VALUES (1886, 6, 28084.44, 319);
INSERT INTO public.recibos_conceptos VALUES (1887, 7, 0.00, 319);
INSERT INTO public.recibos_conceptos VALUES (1888, 9, 2387.18, 319);
INSERT INTO public.recibos_conceptos VALUES (1889, 10, 2387.18, 319);
INSERT INTO public.recibos_conceptos VALUES (1890, 11, 19893.15, 319);
INSERT INTO public.recibos_conceptos VALUES (1891, 4, 46807.40, 319);
INSERT INTO public.recibos_conceptos VALUES (1892, 13, 6631.05, 319);
INSERT INTO public.recibos_conceptos VALUES (1893, 15, 86203.63, 319);
INSERT INTO public.recibos_conceptos VALUES (1894, 17, 9482.40, 319);
INSERT INTO public.recibos_conceptos VALUES (1895, 18, 2586.11, 319);
INSERT INTO public.recibos_conceptos VALUES (1896, 19, 2586.11, 319);
INSERT INTO public.recibos_conceptos VALUES (1897, 20, 2155.09, 319);
INSERT INTO public.recibos_conceptos VALUES (1898, 21, 16809.71, 319);
INSERT INTO public.recibos_conceptos VALUES (1899, 22, 69393.92, 319);
INSERT INTO public.recibos_conceptos VALUES (1900, 1, 24061.43, 320);
INSERT INTO public.recibos_conceptos VALUES (1901, 12, 2406.14, 320);
INSERT INTO public.recibos_conceptos VALUES (1902, 5, 0.00, 320);
INSERT INTO public.recibos_conceptos VALUES (1903, 6, 4331.06, 320);
INSERT INTO public.recibos_conceptos VALUES (1904, 7, 0.00, 320);
INSERT INTO public.recibos_conceptos VALUES (1905, 9, 923.96, 320);
INSERT INTO public.recibos_conceptos VALUES (1906, 10, 923.96, 320);
INSERT INTO public.recibos_conceptos VALUES (1907, 11, 7699.66, 320);
INSERT INTO public.recibos_conceptos VALUES (1908, 4, 24061.43, 320);
INSERT INTO public.recibos_conceptos VALUES (1909, 13, 2566.55, 320);
INSERT INTO public.recibos_conceptos VALUES (1910, 15, 33365.18, 320);
INSERT INTO public.recibos_conceptos VALUES (1911, 17, 3670.17, 320);
INSERT INTO public.recibos_conceptos VALUES (1912, 18, 1000.96, 320);
INSERT INTO public.recibos_conceptos VALUES (1913, 19, 1000.96, 320);
INSERT INTO public.recibos_conceptos VALUES (1914, 20, 834.13, 320);
INSERT INTO public.recibos_conceptos VALUES (1915, 21, 6506.21, 320);
INSERT INTO public.recibos_conceptos VALUES (1916, 22, 26858.97, 320);
INSERT INTO public.recibos_conceptos VALUES (1917, 1, 35226.50, 321);
INSERT INTO public.recibos_conceptos VALUES (1918, 12, 3522.65, 321);
INSERT INTO public.recibos_conceptos VALUES (1919, 5, 0.00, 321);
INSERT INTO public.recibos_conceptos VALUES (1920, 6, 3522.65, 321);
INSERT INTO public.recibos_conceptos VALUES (1921, 7, 0.00, 321);
INSERT INTO public.recibos_conceptos VALUES (1922, 9, 1268.15, 321);
INSERT INTO public.recibos_conceptos VALUES (1923, 10, 1268.15, 321);
INSERT INTO public.recibos_conceptos VALUES (1924, 11, 10567.95, 321);
INSERT INTO public.recibos_conceptos VALUES (1925, 4, 35226.50, 321);
INSERT INTO public.recibos_conceptos VALUES (1926, 13, 3522.65, 321);
INSERT INTO public.recibos_conceptos VALUES (1927, 15, 45794.45, 321);
INSERT INTO public.recibos_conceptos VALUES (1928, 17, 5037.39, 321);
INSERT INTO public.recibos_conceptos VALUES (1929, 18, 1373.83, 321);
INSERT INTO public.recibos_conceptos VALUES (1930, 19, 1373.83, 321);
INSERT INTO public.recibos_conceptos VALUES (1931, 20, 1144.86, 321);
INSERT INTO public.recibos_conceptos VALUES (1932, 21, 8929.92, 321);
INSERT INTO public.recibos_conceptos VALUES (1933, 22, 36864.53, 321);
INSERT INTO public.recibos_conceptos VALUES (1934, 1, 48582.30, 322);
INSERT INTO public.recibos_conceptos VALUES (1935, 12, 4858.23, 322);
INSERT INTO public.recibos_conceptos VALUES (1936, 5, 0.00, 322);
INSERT INTO public.recibos_conceptos VALUES (1937, 6, 32064.32, 322);
INSERT INTO public.recibos_conceptos VALUES (1938, 7, 0.00, 322);
INSERT INTO public.recibos_conceptos VALUES (1939, 9, 2565.15, 322);
INSERT INTO public.recibos_conceptos VALUES (1940, 10, 2565.15, 322);
INSERT INTO public.recibos_conceptos VALUES (1941, 11, 21376.21, 322);
INSERT INTO public.recibos_conceptos VALUES (1942, 4, 48582.30, 322);
INSERT INTO public.recibos_conceptos VALUES (1943, 13, 7125.40, 322);
INSERT INTO public.recibos_conceptos VALUES (1944, 15, 92630.25, 322);
INSERT INTO public.recibos_conceptos VALUES (1945, 17, 10189.33, 322);
INSERT INTO public.recibos_conceptos VALUES (1946, 18, 2778.91, 322);
INSERT INTO public.recibos_conceptos VALUES (1947, 19, 2778.91, 322);
INSERT INTO public.recibos_conceptos VALUES (1948, 20, 2315.76, 322);
INSERT INTO public.recibos_conceptos VALUES (1949, 21, 18062.90, 322);
INSERT INTO public.recibos_conceptos VALUES (1950, 22, 74567.35, 322);
INSERT INTO public.recibos_conceptos VALUES (1951, 1, 17250.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1952, 12, 1725.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1953, 5, 0.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1954, 6, 1380.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1955, 7, 0.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1956, 9, 610.65, 323);
INSERT INTO public.recibos_conceptos VALUES (1957, 10, 610.65, 323);
INSERT INTO public.recibos_conceptos VALUES (1958, 11, 5088.75, 323);
INSERT INTO public.recibos_conceptos VALUES (1959, 4, 17250.00, 323);
INSERT INTO public.recibos_conceptos VALUES (1960, 13, 1696.25, 323);
INSERT INTO public.recibos_conceptos VALUES (1961, 15, 22051.25, 323);
INSERT INTO public.recibos_conceptos VALUES (1962, 17, 2425.64, 323);
INSERT INTO public.recibos_conceptos VALUES (1963, 18, 661.54, 323);
INSERT INTO public.recibos_conceptos VALUES (1964, 19, 661.54, 323);
INSERT INTO public.recibos_conceptos VALUES (1965, 20, 551.28, 323);
INSERT INTO public.recibos_conceptos VALUES (1966, 21, 4299.99, 323);
INSERT INTO public.recibos_conceptos VALUES (1967, 22, 17751.26, 323);
INSERT INTO public.recibos_conceptos VALUES (1968, 1, 60000.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1969, 12, 6000.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1970, 5, 0.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1971, 6, 13200.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1972, 7, 0.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1973, 9, 2376.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1974, 10, 2376.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1975, 11, 19800.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1976, 4, 60000.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1977, 13, 6600.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1978, 15, 85800.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1979, 17, 9438.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1980, 18, 2574.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1981, 19, 2574.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1982, 20, 2145.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1983, 21, 16731.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1984, 22, 69069.00, 324);
INSERT INTO public.recibos_conceptos VALUES (1985, 1, 35033.10, 325);
INSERT INTO public.recibos_conceptos VALUES (1986, 12, 3503.31, 325);
INSERT INTO public.recibos_conceptos VALUES (1987, 5, 0.00, 325);
INSERT INTO public.recibos_conceptos VALUES (1988, 6, 3503.31, 325);
INSERT INTO public.recibos_conceptos VALUES (1989, 7, 0.00, 325);
INSERT INTO public.recibos_conceptos VALUES (1990, 9, 1261.19, 325);
INSERT INTO public.recibos_conceptos VALUES (1991, 10, 1261.19, 325);
INSERT INTO public.recibos_conceptos VALUES (1992, 11, 10509.93, 325);
INSERT INTO public.recibos_conceptos VALUES (1993, 4, 35033.10, 325);
INSERT INTO public.recibos_conceptos VALUES (1994, 13, 3503.31, 325);
INSERT INTO public.recibos_conceptos VALUES (1995, 15, 45543.03, 325);
INSERT INTO public.recibos_conceptos VALUES (1996, 17, 5009.73, 325);
INSERT INTO public.recibos_conceptos VALUES (1997, 18, 1366.29, 325);
INSERT INTO public.recibos_conceptos VALUES (1998, 19, 1366.29, 325);
INSERT INTO public.recibos_conceptos VALUES (1999, 20, 1138.58, 325);
INSERT INTO public.recibos_conceptos VALUES (2000, 21, 8880.89, 325);
INSERT INTO public.recibos_conceptos VALUES (2001, 22, 36662.14, 325);
INSERT INTO public.recibos_conceptos VALUES (2002, 1, 46839.10, 326);
INSERT INTO public.recibos_conceptos VALUES (2003, 12, 4683.91, 326);
INSERT INTO public.recibos_conceptos VALUES (2004, 5, 0.00, 326);
INSERT INTO public.recibos_conceptos VALUES (2005, 6, 14051.73, 326);
INSERT INTO public.recibos_conceptos VALUES (2006, 7, 0.00, 326);
INSERT INTO public.recibos_conceptos VALUES (2007, 9, 1967.24, 326);
INSERT INTO public.recibos_conceptos VALUES (2008, 10, 1967.24, 326);
INSERT INTO public.recibos_conceptos VALUES (2009, 11, 16393.69, 326);
INSERT INTO public.recibos_conceptos VALUES (2010, 4, 46839.10, 326);
INSERT INTO public.recibos_conceptos VALUES (2011, 13, 5464.56, 326);
INSERT INTO public.recibos_conceptos VALUES (2012, 15, 71039.30, 326);
INSERT INTO public.recibos_conceptos VALUES (2013, 17, 7814.32, 326);
INSERT INTO public.recibos_conceptos VALUES (2014, 18, 2131.18, 326);
INSERT INTO public.recibos_conceptos VALUES (2015, 19, 2131.18, 326);
INSERT INTO public.recibos_conceptos VALUES (2016, 20, 1775.98, 326);
INSERT INTO public.recibos_conceptos VALUES (2017, 21, 13852.66, 326);
INSERT INTO public.recibos_conceptos VALUES (2018, 22, 57186.64, 326);
INSERT INTO public.recibos_conceptos VALUES (2019, 1, 42666.80, 327);
INSERT INTO public.recibos_conceptos VALUES (2020, 12, 4266.68, 327);
INSERT INTO public.recibos_conceptos VALUES (2021, 5, 0.00, 327);
INSERT INTO public.recibos_conceptos VALUES (2022, 6, 10240.03, 327);
INSERT INTO public.recibos_conceptos VALUES (2023, 7, 0.00, 327);
INSERT INTO public.recibos_conceptos VALUES (2024, 9, 1715.21, 327);
INSERT INTO public.recibos_conceptos VALUES (2025, 10, 1715.21, 327);
INSERT INTO public.recibos_conceptos VALUES (2026, 11, 14293.38, 327);
INSERT INTO public.recibos_conceptos VALUES (2027, 4, 42666.80, 327);
INSERT INTO public.recibos_conceptos VALUES (2028, 13, 4764.46, 327);
INSERT INTO public.recibos_conceptos VALUES (2029, 15, 61937.97, 327);
INSERT INTO public.recibos_conceptos VALUES (2030, 17, 6813.18, 327);
INSERT INTO public.recibos_conceptos VALUES (2031, 18, 1858.14, 327);
INSERT INTO public.recibos_conceptos VALUES (2032, 19, 1858.14, 327);
INSERT INTO public.recibos_conceptos VALUES (2033, 20, 1548.45, 327);
INSERT INTO public.recibos_conceptos VALUES (2034, 21, 12077.90, 327);
INSERT INTO public.recibos_conceptos VALUES (2035, 22, 49860.07, 327);
INSERT INTO public.recibos_conceptos VALUES (2036, 1, 42012.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2037, 12, 4201.20, 328);
INSERT INTO public.recibos_conceptos VALUES (2039, 6, 31929.12, 328);
INSERT INTO public.recibos_conceptos VALUES (2040, 7, 0.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2041, 9, 2344.27, 328);
INSERT INTO public.recibos_conceptos VALUES (2042, 10, 2344.27, 328);
INSERT INTO public.recibos_conceptos VALUES (2043, 11, 19535.58, 328);
INSERT INTO public.recibos_conceptos VALUES (2044, 4, 42012.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2045, 13, 6511.86, 328);
INSERT INTO public.recibos_conceptos VALUES (2046, 15, 84654.18, 328);
INSERT INTO public.recibos_conceptos VALUES (2047, 17, 9311.96, 328);
INSERT INTO public.recibos_conceptos VALUES (2048, 18, 2539.63, 328);
INSERT INTO public.recibos_conceptos VALUES (2049, 19, 2539.63, 328);
INSERT INTO public.recibos_conceptos VALUES (2050, 20, 2116.35, 328);
INSERT INTO public.recibos_conceptos VALUES (2051, 21, 16507.57, 328);
INSERT INTO public.recibos_conceptos VALUES (2052, 22, 68146.61, 328);
INSERT INTO public.recibos_conceptos VALUES (2053, 1, 42717.50, 329);
INSERT INTO public.recibos_conceptos VALUES (2054, 12, 4271.75, 329);
INSERT INTO public.recibos_conceptos VALUES (2055, 5, 0.00, 329);
INSERT INTO public.recibos_conceptos VALUES (2056, 6, 8543.50, 329);
INSERT INTO public.recibos_conceptos VALUES (2057, 7, 0.00, 329);
INSERT INTO public.recibos_conceptos VALUES (2058, 9, 1665.98, 329);
INSERT INTO public.recibos_conceptos VALUES (2059, 10, 1665.98, 329);
INSERT INTO public.recibos_conceptos VALUES (2060, 11, 13883.19, 329);
INSERT INTO public.recibos_conceptos VALUES (2061, 4, 42717.50, 329);
INSERT INTO public.recibos_conceptos VALUES (2062, 13, 4627.73, 329);
INSERT INTO public.recibos_conceptos VALUES (2063, 15, 60160.48, 329);
INSERT INTO public.recibos_conceptos VALUES (2064, 17, 6617.65, 329);
INSERT INTO public.recibos_conceptos VALUES (2065, 18, 1804.81, 329);
INSERT INTO public.recibos_conceptos VALUES (2066, 19, 1804.81, 329);
INSERT INTO public.recibos_conceptos VALUES (2067, 20, 1504.01, 329);
INSERT INTO public.recibos_conceptos VALUES (2068, 21, 11731.29, 329);
INSERT INTO public.recibos_conceptos VALUES (2069, 22, 48429.19, 329);
INSERT INTO public.recibos_conceptos VALUES (2070, 1, 38158.50, 330);
INSERT INTO public.recibos_conceptos VALUES (2071, 12, 3815.85, 330);
INSERT INTO public.recibos_conceptos VALUES (2072, 5, 0.00, 330);
INSERT INTO public.recibos_conceptos VALUES (2073, 6, 3052.68, 330);
INSERT INTO public.recibos_conceptos VALUES (2074, 7, 0.00, 330);
INSERT INTO public.recibos_conceptos VALUES (2075, 9, 1350.81, 330);
INSERT INTO public.recibos_conceptos VALUES (2076, 10, 1350.81, 330);
INSERT INTO public.recibos_conceptos VALUES (2077, 11, 11256.76, 330);
INSERT INTO public.recibos_conceptos VALUES (2078, 4, 38158.50, 330);
INSERT INTO public.recibos_conceptos VALUES (2079, 13, 3752.25, 330);
INSERT INTO public.recibos_conceptos VALUES (2080, 15, 48779.28, 330);
INSERT INTO public.recibos_conceptos VALUES (2081, 17, 5365.72, 330);
INSERT INTO public.recibos_conceptos VALUES (2082, 18, 1463.38, 330);
INSERT INTO public.recibos_conceptos VALUES (2083, 19, 1463.38, 330);
INSERT INTO public.recibos_conceptos VALUES (2084, 20, 1219.48, 330);
INSERT INTO public.recibos_conceptos VALUES (2085, 21, 9511.96, 330);
INSERT INTO public.recibos_conceptos VALUES (2086, 22, 39267.32, 330);
INSERT INTO public.recibos_conceptos VALUES (2087, 1, 15764.70, 331);
INSERT INTO public.recibos_conceptos VALUES (2088, 12, 1576.47, 331);
INSERT INTO public.recibos_conceptos VALUES (2089, 5, 0.00, 331);
INSERT INTO public.recibos_conceptos VALUES (2090, 6, 945.88, 331);
INSERT INTO public.recibos_conceptos VALUES (2091, 7, 0.00, 331);
INSERT INTO public.recibos_conceptos VALUES (2092, 9, 548.61, 331);
INSERT INTO public.recibos_conceptos VALUES (2093, 10, 548.61, 331);
INSERT INTO public.recibos_conceptos VALUES (2094, 11, 4571.76, 331);
INSERT INTO public.recibos_conceptos VALUES (2095, 4, 15764.70, 331);
INSERT INTO public.recibos_conceptos VALUES (2096, 13, 1523.92, 331);
INSERT INTO public.recibos_conceptos VALUES (2097, 15, 19810.97, 331);
INSERT INTO public.recibos_conceptos VALUES (2098, 17, 2179.21, 331);
INSERT INTO public.recibos_conceptos VALUES (2099, 18, 594.33, 331);
INSERT INTO public.recibos_conceptos VALUES (2100, 19, 594.33, 331);
INSERT INTO public.recibos_conceptos VALUES (2101, 20, 495.27, 331);
INSERT INTO public.recibos_conceptos VALUES (2102, 21, 3863.14, 331);
INSERT INTO public.recibos_conceptos VALUES (2103, 22, 15947.83, 331);
INSERT INTO public.recibos_conceptos VALUES (2104, 1, 39104.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2105, 12, 3910.40, 332);
INSERT INTO public.recibos_conceptos VALUES (2106, 5, 0.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2107, 6, 9384.96, 332);
INSERT INTO public.recibos_conceptos VALUES (2108, 7, 0.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2109, 9, 1571.98, 332);
INSERT INTO public.recibos_conceptos VALUES (2110, 10, 1571.98, 332);
INSERT INTO public.recibos_conceptos VALUES (2111, 11, 13099.84, 332);
INSERT INTO public.recibos_conceptos VALUES (2112, 4, 39104.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2113, 13, 4366.61, 332);
INSERT INTO public.recibos_conceptos VALUES (2114, 15, 56765.97, 332);
INSERT INTO public.recibos_conceptos VALUES (2115, 17, 6244.26, 332);
INSERT INTO public.recibos_conceptos VALUES (2116, 18, 1702.98, 332);
INSERT INTO public.recibos_conceptos VALUES (2117, 19, 1702.98, 332);
INSERT INTO public.recibos_conceptos VALUES (2118, 20, 1419.15, 332);
INSERT INTO public.recibos_conceptos VALUES (2119, 21, 11069.36, 332);
INSERT INTO public.recibos_conceptos VALUES (2120, 22, 45696.61, 332);
INSERT INTO public.recibos_conceptos VALUES (2121, 1, 45948.50, 333);
INSERT INTO public.recibos_conceptos VALUES (2122, 12, 4594.85, 333);
INSERT INTO public.recibos_conceptos VALUES (2123, 5, 0.00, 333);
INSERT INTO public.recibos_conceptos VALUES (2124, 6, 29407.04, 333);
INSERT INTO public.recibos_conceptos VALUES (2125, 7, 0.00, 333);
INSERT INTO public.recibos_conceptos VALUES (2126, 9, 2398.51, 333);
INSERT INTO public.recibos_conceptos VALUES (2127, 10, 2398.51, 333);
INSERT INTO public.recibos_conceptos VALUES (2128, 11, 19987.60, 333);
INSERT INTO public.recibos_conceptos VALUES (2129, 4, 45948.50, 333);
INSERT INTO public.recibos_conceptos VALUES (2130, 13, 6662.53, 333);
INSERT INTO public.recibos_conceptos VALUES (2131, 15, 86612.92, 333);
INSERT INTO public.recibos_conceptos VALUES (2132, 17, 9527.42, 333);
INSERT INTO public.recibos_conceptos VALUES (2133, 18, 2598.39, 333);
INSERT INTO public.recibos_conceptos VALUES (2134, 19, 2598.39, 333);
INSERT INTO public.recibos_conceptos VALUES (2135, 20, 2165.32, 333);
INSERT INTO public.recibos_conceptos VALUES (2136, 21, 16889.52, 333);
INSERT INTO public.recibos_conceptos VALUES (2137, 22, 69723.40, 333);
INSERT INTO public.recibos_conceptos VALUES (2138, 1, 34958.80, 334);
INSERT INTO public.recibos_conceptos VALUES (2139, 12, 3495.88, 334);
INSERT INTO public.recibos_conceptos VALUES (2140, 5, 0.00, 334);
INSERT INTO public.recibos_conceptos VALUES (2141, 6, 3495.88, 334);
INSERT INTO public.recibos_conceptos VALUES (2142, 7, 0.00, 334);
INSERT INTO public.recibos_conceptos VALUES (2143, 9, 1258.52, 334);
INSERT INTO public.recibos_conceptos VALUES (2144, 10, 1258.52, 334);
INSERT INTO public.recibos_conceptos VALUES (2145, 11, 10487.64, 334);
INSERT INTO public.recibos_conceptos VALUES (2146, 4, 34958.80, 334);
INSERT INTO public.recibos_conceptos VALUES (2147, 13, 3495.88, 334);
INSERT INTO public.recibos_conceptos VALUES (2148, 15, 45446.44, 334);
INSERT INTO public.recibos_conceptos VALUES (2149, 17, 4999.11, 334);
INSERT INTO public.recibos_conceptos VALUES (2150, 18, 1363.39, 334);
INSERT INTO public.recibos_conceptos VALUES (2151, 19, 1363.39, 334);
INSERT INTO public.recibos_conceptos VALUES (2152, 20, 1136.16, 334);
INSERT INTO public.recibos_conceptos VALUES (2153, 21, 8862.06, 334);
INSERT INTO public.recibos_conceptos VALUES (2154, 22, 36584.38, 334);
INSERT INTO public.recibos_conceptos VALUES (2155, 1, 57061.70, 335);
INSERT INTO public.recibos_conceptos VALUES (2156, 12, 5706.17, 335);
INSERT INTO public.recibos_conceptos VALUES (2157, 5, 0.00, 335);
INSERT INTO public.recibos_conceptos VALUES (2158, 6, 36519.49, 335);
INSERT INTO public.recibos_conceptos VALUES (2159, 7, 0.00, 335);
INSERT INTO public.recibos_conceptos VALUES (2160, 9, 2978.62, 335);
INSERT INTO public.recibos_conceptos VALUES (2161, 10, 2978.62, 335);
INSERT INTO public.recibos_conceptos VALUES (2162, 11, 24821.84, 335);
INSERT INTO public.recibos_conceptos VALUES (2163, 4, 57061.70, 335);
INSERT INTO public.recibos_conceptos VALUES (2164, 13, 8273.95, 335);
INSERT INTO public.recibos_conceptos VALUES (2165, 15, 107561.30, 335);
INSERT INTO public.recibos_conceptos VALUES (2166, 17, 11831.74, 335);
INSERT INTO public.recibos_conceptos VALUES (2167, 18, 3226.84, 335);
INSERT INTO public.recibos_conceptos VALUES (2168, 19, 3226.84, 335);
INSERT INTO public.recibos_conceptos VALUES (2169, 20, 2689.03, 335);
INSERT INTO public.recibos_conceptos VALUES (2170, 21, 20974.45, 335);
INSERT INTO public.recibos_conceptos VALUES (2171, 22, 86586.85, 335);
INSERT INTO public.recibos_conceptos VALUES (2172, 1, 34892.86, 336);
INSERT INTO public.recibos_conceptos VALUES (2173, 12, 3489.29, 336);
INSERT INTO public.recibos_conceptos VALUES (2174, 5, 0.00, 336);
INSERT INTO public.recibos_conceptos VALUES (2175, 6, 1395.71, 336);
INSERT INTO public.recibos_conceptos VALUES (2176, 7, 0.00, 336);
INSERT INTO public.recibos_conceptos VALUES (2177, 9, 1193.34, 336);
INSERT INTO public.recibos_conceptos VALUES (2178, 10, 1193.34, 336);
INSERT INTO public.recibos_conceptos VALUES (2179, 11, 9944.47, 336);
INSERT INTO public.recibos_conceptos VALUES (2180, 4, 34892.86, 336);
INSERT INTO public.recibos_conceptos VALUES (2181, 13, 3314.82, 336);
INSERT INTO public.recibos_conceptos VALUES (2182, 15, 43092.68, 336);
INSERT INTO public.recibos_conceptos VALUES (2183, 17, 4740.20, 336);
INSERT INTO public.recibos_conceptos VALUES (2184, 18, 1292.78, 336);
INSERT INTO public.recibos_conceptos VALUES (2185, 19, 1292.78, 336);
INSERT INTO public.recibos_conceptos VALUES (2186, 20, 1077.32, 336);
INSERT INTO public.recibos_conceptos VALUES (2187, 21, 8403.07, 336);
INSERT INTO public.recibos_conceptos VALUES (2188, 22, 34689.61, 336);
INSERT INTO public.recibos_conceptos VALUES (2209, 14, 0.00, 317);
INSERT INTO public.recibos_conceptos VALUES (2210, 14, 0.00, 318);
INSERT INTO public.recibos_conceptos VALUES (2211, 14, 0.00, 319);
INSERT INTO public.recibos_conceptos VALUES (2212, 14, 0.00, 320);
INSERT INTO public.recibos_conceptos VALUES (2213, 14, 0.00, 321);
INSERT INTO public.recibos_conceptos VALUES (2214, 14, 0.00, 322);
INSERT INTO public.recibos_conceptos VALUES (2215, 14, 0.00, 323);
INSERT INTO public.recibos_conceptos VALUES (2216, 14, 0.00, 324);
INSERT INTO public.recibos_conceptos VALUES (2217, 14, 0.00, 325);
INSERT INTO public.recibos_conceptos VALUES (2218, 14, 0.00, 326);
INSERT INTO public.recibos_conceptos VALUES (2219, 14, 0.00, 327);
INSERT INTO public.recibos_conceptos VALUES (2220, 14, 0.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2221, 14, 0.00, 329);
INSERT INTO public.recibos_conceptos VALUES (2222, 14, 0.00, 330);
INSERT INTO public.recibos_conceptos VALUES (2223, 14, 0.00, 331);
INSERT INTO public.recibos_conceptos VALUES (2224, 14, 0.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2225, 14, 0.00, 333);
INSERT INTO public.recibos_conceptos VALUES (2226, 14, 0.00, 334);
INSERT INTO public.recibos_conceptos VALUES (2227, 14, 0.00, 335);
INSERT INTO public.recibos_conceptos VALUES (2228, 14, 0.00, 336);
INSERT INTO public.recibos_conceptos VALUES (2249, 16, 0.00, 317);
INSERT INTO public.recibos_conceptos VALUES (2250, 16, 0.00, 318);
INSERT INTO public.recibos_conceptos VALUES (2251, 16, 0.00, 319);
INSERT INTO public.recibos_conceptos VALUES (2252, 16, 0.00, 320);
INSERT INTO public.recibos_conceptos VALUES (2253, 16, 0.00, 321);
INSERT INTO public.recibos_conceptos VALUES (2254, 16, 0.00, 322);
INSERT INTO public.recibos_conceptos VALUES (2255, 16, 0.00, 323);
INSERT INTO public.recibos_conceptos VALUES (2256, 16, 0.00, 324);
INSERT INTO public.recibos_conceptos VALUES (2257, 16, 0.00, 325);
INSERT INTO public.recibos_conceptos VALUES (2258, 16, 0.00, 326);
INSERT INTO public.recibos_conceptos VALUES (2259, 16, 0.00, 327);
INSERT INTO public.recibos_conceptos VALUES (2260, 16, 0.00, 328);
INSERT INTO public.recibos_conceptos VALUES (2261, 16, 0.00, 329);
INSERT INTO public.recibos_conceptos VALUES (2262, 16, 0.00, 330);
INSERT INTO public.recibos_conceptos VALUES (2263, 16, 0.00, 331);
INSERT INTO public.recibos_conceptos VALUES (2264, 16, 0.00, 332);
INSERT INTO public.recibos_conceptos VALUES (2265, 16, 0.00, 333);
INSERT INTO public.recibos_conceptos VALUES (2266, 16, 0.00, 334);
INSERT INTO public.recibos_conceptos VALUES (2267, 16, 0.00, 335);
INSERT INTO public.recibos_conceptos VALUES (2268, 16, 0.00, 336);
INSERT INTO public.recibos_conceptos VALUES (2730, 5, 3.00, 348);
INSERT INTO public.recibos_conceptos VALUES (2809, 24, NULL, 297);
INSERT INTO public.recibos_conceptos VALUES (2810, 24, NULL, 298);
INSERT INTO public.recibos_conceptos VALUES (2811, 24, NULL, 299);
INSERT INTO public.recibos_conceptos VALUES (2812, 24, NULL, 300);
INSERT INTO public.recibos_conceptos VALUES (2813, 24, NULL, 301);
INSERT INTO public.recibos_conceptos VALUES (2814, 24, NULL, 302);
INSERT INTO public.recibos_conceptos VALUES (2815, 24, NULL, 303);
INSERT INTO public.recibos_conceptos VALUES (2816, 24, NULL, 304);
INSERT INTO public.recibos_conceptos VALUES (2817, 24, NULL, 305);
INSERT INTO public.recibos_conceptos VALUES (2818, 24, NULL, 306);
INSERT INTO public.recibos_conceptos VALUES (2819, 24, NULL, 307);
INSERT INTO public.recibos_conceptos VALUES (2820, 24, NULL, 308);
INSERT INTO public.recibos_conceptos VALUES (2821, 24, NULL, 309);
INSERT INTO public.recibos_conceptos VALUES (2822, 24, NULL, 310);
INSERT INTO public.recibos_conceptos VALUES (2823, 24, NULL, 311);
INSERT INTO public.recibos_conceptos VALUES (2824, 24, NULL, 312);
INSERT INTO public.recibos_conceptos VALUES (2825, 24, NULL, 313);
INSERT INTO public.recibos_conceptos VALUES (2826, 24, NULL, 314);
INSERT INTO public.recibos_conceptos VALUES (2827, 24, NULL, 315);
INSERT INTO public.recibos_conceptos VALUES (2828, 24, NULL, 316);
INSERT INTO public.recibos_conceptos VALUES (2829, 24, NULL, 317);
INSERT INTO public.recibos_conceptos VALUES (2830, 24, NULL, 318);
INSERT INTO public.recibos_conceptos VALUES (2831, 24, NULL, 319);
INSERT INTO public.recibos_conceptos VALUES (2832, 24, NULL, 320);
INSERT INTO public.recibos_conceptos VALUES (2833, 24, NULL, 321);
INSERT INTO public.recibos_conceptos VALUES (2834, 24, NULL, 322);
INSERT INTO public.recibos_conceptos VALUES (2835, 24, NULL, 323);
INSERT INTO public.recibos_conceptos VALUES (2836, 24, NULL, 324);
INSERT INTO public.recibos_conceptos VALUES (2837, 24, NULL, 325);
INSERT INTO public.recibos_conceptos VALUES (2838, 24, NULL, 326);
INSERT INTO public.recibos_conceptos VALUES (2839, 24, NULL, 327);
INSERT INTO public.recibos_conceptos VALUES (2840, 24, NULL, 328);
INSERT INTO public.recibos_conceptos VALUES (2841, 24, NULL, 329);
INSERT INTO public.recibos_conceptos VALUES (2842, 24, NULL, 330);
INSERT INTO public.recibos_conceptos VALUES (2843, 24, NULL, 331);
INSERT INTO public.recibos_conceptos VALUES (2844, 24, NULL, 332);
INSERT INTO public.recibos_conceptos VALUES (2845, 24, NULL, 333);
INSERT INTO public.recibos_conceptos VALUES (2846, 24, NULL, 334);
INSERT INTO public.recibos_conceptos VALUES (2847, 24, NULL, 335);
INSERT INTO public.recibos_conceptos VALUES (2848, 24, NULL, 336);
INSERT INTO public.recibos_conceptos VALUES (2629, 1, 34351.20, 337);
INSERT INTO public.recibos_conceptos VALUES (2630, 12, 3435.12, 337);
INSERT INTO public.recibos_conceptos VALUES (2631, 5, 0.00, 337);
INSERT INTO public.recibos_conceptos VALUES (2632, 6, 4809.17, 337);
INSERT INTO public.recibos_conceptos VALUES (2633, 7, 0.00, 337);
INSERT INTO public.recibos_conceptos VALUES (2634, 9, 1277.86, 337);
INSERT INTO public.recibos_conceptos VALUES (2635, 10, 1277.86, 337);
INSERT INTO public.recibos_conceptos VALUES (2636, 11, 10648.87, 337);
INSERT INTO public.recibos_conceptos VALUES (2637, 4, 34351.20, 337);
INSERT INTO public.recibos_conceptos VALUES (2638, 1, 41008.81, 338);
INSERT INTO public.recibos_conceptos VALUES (2639, 12, 4100.88, 338);
INSERT INTO public.recibos_conceptos VALUES (2640, 5, 0.00, 338);
INSERT INTO public.recibos_conceptos VALUES (2641, 6, 4100.88, 338);
INSERT INTO public.recibos_conceptos VALUES (2642, 7, 0.00, 338);
INSERT INTO public.recibos_conceptos VALUES (2643, 9, 1476.32, 338);
INSERT INTO public.recibos_conceptos VALUES (2644, 10, 1476.32, 338);
INSERT INTO public.recibos_conceptos VALUES (2645, 11, 12302.64, 338);
INSERT INTO public.recibos_conceptos VALUES (2646, 4, 41008.81, 338);
INSERT INTO public.recibos_conceptos VALUES (2647, 1, 46807.40, 339);
INSERT INTO public.recibos_conceptos VALUES (2648, 12, 4680.74, 339);
INSERT INTO public.recibos_conceptos VALUES (2649, 5, 0.00, 339);
INSERT INTO public.recibos_conceptos VALUES (2650, 6, 28084.44, 339);
INSERT INTO public.recibos_conceptos VALUES (2651, 7, 0.00, 339);
INSERT INTO public.recibos_conceptos VALUES (2652, 9, 2387.18, 339);
INSERT INTO public.recibos_conceptos VALUES (2653, 10, 2387.18, 339);
INSERT INTO public.recibos_conceptos VALUES (2654, 11, 19893.15, 339);
INSERT INTO public.recibos_conceptos VALUES (2655, 4, 46807.40, 339);
INSERT INTO public.recibos_conceptos VALUES (2656, 1, 24061.43, 340);
INSERT INTO public.recibos_conceptos VALUES (2657, 12, 2406.14, 340);
INSERT INTO public.recibos_conceptos VALUES (2658, 5, 0.00, 340);
INSERT INTO public.recibos_conceptos VALUES (2659, 6, 3849.83, 340);
INSERT INTO public.recibos_conceptos VALUES (2660, 7, 0.00, 340);
INSERT INTO public.recibos_conceptos VALUES (2661, 9, 909.52, 340);
INSERT INTO public.recibos_conceptos VALUES (2662, 10, 909.52, 340);
INSERT INTO public.recibos_conceptos VALUES (2663, 11, 7579.35, 340);
INSERT INTO public.recibos_conceptos VALUES (2664, 4, 24061.43, 340);
INSERT INTO public.recibos_conceptos VALUES (2665, 1, 35226.50, 341);
INSERT INTO public.recibos_conceptos VALUES (2666, 12, 3522.65, 341);
INSERT INTO public.recibos_conceptos VALUES (2667, 5, 0.00, 341);
INSERT INTO public.recibos_conceptos VALUES (2668, 6, 2818.12, 341);
INSERT INTO public.recibos_conceptos VALUES (2669, 7, 0.00, 341);
INSERT INTO public.recibos_conceptos VALUES (2670, 9, 1247.02, 341);
INSERT INTO public.recibos_conceptos VALUES (2671, 10, 1247.02, 341);
INSERT INTO public.recibos_conceptos VALUES (2672, 11, 10391.82, 341);
INSERT INTO public.recibos_conceptos VALUES (2673, 4, 35226.50, 341);
INSERT INTO public.recibos_conceptos VALUES (2674, 1, 48582.30, 342);
INSERT INTO public.recibos_conceptos VALUES (2675, 12, 4858.23, 342);
INSERT INTO public.recibos_conceptos VALUES (2676, 5, 0.00, 342);
INSERT INTO public.recibos_conceptos VALUES (2677, 6, 31092.67, 342);
INSERT INTO public.recibos_conceptos VALUES (2678, 7, 0.00, 342);
INSERT INTO public.recibos_conceptos VALUES (2679, 9, 2536.00, 342);
INSERT INTO public.recibos_conceptos VALUES (2680, 10, 2536.00, 342);
INSERT INTO public.recibos_conceptos VALUES (2681, 11, 21133.30, 342);
INSERT INTO public.recibos_conceptos VALUES (2682, 4, 48582.30, 342);
INSERT INTO public.recibos_conceptos VALUES (2683, 1, 17250.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2684, 12, 1725.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2685, 5, 0.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2686, 6, 1035.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2687, 7, 0.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2688, 9, 600.30, 343);
INSERT INTO public.recibos_conceptos VALUES (2689, 10, 600.30, 343);
INSERT INTO public.recibos_conceptos VALUES (2690, 11, 5002.50, 343);
INSERT INTO public.recibos_conceptos VALUES (2691, 4, 17250.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2692, 1, 60000.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2693, 12, 6000.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2694, 5, 0.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2695, 6, 12000.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2696, 7, 0.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2697, 9, 2340.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2698, 10, 2340.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2699, 11, 19500.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2700, 4, 60000.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2701, 1, 35033.10, 345);
INSERT INTO public.recibos_conceptos VALUES (2702, 12, 3503.31, 345);
INSERT INTO public.recibos_conceptos VALUES (2703, 5, 0.00, 345);
INSERT INTO public.recibos_conceptos VALUES (2704, 6, 3503.31, 345);
INSERT INTO public.recibos_conceptos VALUES (2705, 7, 0.00, 345);
INSERT INTO public.recibos_conceptos VALUES (2706, 9, 1261.19, 345);
INSERT INTO public.recibos_conceptos VALUES (2707, 10, 1261.19, 345);
INSERT INTO public.recibos_conceptos VALUES (2708, 11, 10509.93, 345);
INSERT INTO public.recibos_conceptos VALUES (2709, 4, 35033.10, 345);
INSERT INTO public.recibos_conceptos VALUES (2710, 1, 46839.10, 346);
INSERT INTO public.recibos_conceptos VALUES (2711, 12, 4683.91, 346);
INSERT INTO public.recibos_conceptos VALUES (2712, 5, 0.00, 346);
INSERT INTO public.recibos_conceptos VALUES (2713, 6, 14051.73, 346);
INSERT INTO public.recibos_conceptos VALUES (2714, 7, 0.00, 346);
INSERT INTO public.recibos_conceptos VALUES (2715, 9, 1967.24, 346);
INSERT INTO public.recibos_conceptos VALUES (2716, 10, 1967.24, 346);
INSERT INTO public.recibos_conceptos VALUES (2717, 11, 16393.69, 346);
INSERT INTO public.recibos_conceptos VALUES (2718, 4, 46839.10, 346);
INSERT INTO public.recibos_conceptos VALUES (2719, 1, 42666.80, 347);
INSERT INTO public.recibos_conceptos VALUES (2720, 12, 4266.68, 347);
INSERT INTO public.recibos_conceptos VALUES (2721, 5, 0.00, 347);
INSERT INTO public.recibos_conceptos VALUES (2722, 6, 10240.03, 347);
INSERT INTO public.recibos_conceptos VALUES (2723, 7, 0.00, 347);
INSERT INTO public.recibos_conceptos VALUES (2724, 9, 1715.21, 347);
INSERT INTO public.recibos_conceptos VALUES (2725, 10, 1715.21, 347);
INSERT INTO public.recibos_conceptos VALUES (2726, 11, 14293.38, 347);
INSERT INTO public.recibos_conceptos VALUES (2727, 4, 42666.80, 347);
INSERT INTO public.recibos_conceptos VALUES (2728, 1, 42012.00, 348);
INSERT INTO public.recibos_conceptos VALUES (2729, 12, 4201.20, 348);
INSERT INTO public.recibos_conceptos VALUES (2731, 6, 31088.88, 348);
INSERT INTO public.recibos_conceptos VALUES (2732, 7, 0.00, 348);
INSERT INTO public.recibos_conceptos VALUES (2733, 9, 2319.06, 348);
INSERT INTO public.recibos_conceptos VALUES (2734, 10, 2319.06, 348);
INSERT INTO public.recibos_conceptos VALUES (2735, 11, 19325.52, 348);
INSERT INTO public.recibos_conceptos VALUES (2736, 4, 42012.00, 348);
INSERT INTO public.recibos_conceptos VALUES (2737, 1, 42717.50, 349);
INSERT INTO public.recibos_conceptos VALUES (2738, 12, 4271.75, 349);
INSERT INTO public.recibos_conceptos VALUES (2739, 5, 0.00, 349);
INSERT INTO public.recibos_conceptos VALUES (2740, 6, 7689.15, 349);
INSERT INTO public.recibos_conceptos VALUES (2741, 7, 0.00, 349);
INSERT INTO public.recibos_conceptos VALUES (2742, 9, 1640.35, 349);
INSERT INTO public.recibos_conceptos VALUES (2743, 10, 1640.35, 349);
INSERT INTO public.recibos_conceptos VALUES (2744, 11, 13669.60, 349);
INSERT INTO public.recibos_conceptos VALUES (2745, 4, 42717.50, 349);
INSERT INTO public.recibos_conceptos VALUES (2746, 1, 38158.50, 350);
INSERT INTO public.recibos_conceptos VALUES (2747, 12, 3815.85, 350);
INSERT INTO public.recibos_conceptos VALUES (2748, 5, 0.00, 350);
INSERT INTO public.recibos_conceptos VALUES (2749, 6, 3052.68, 350);
INSERT INTO public.recibos_conceptos VALUES (2750, 7, 0.00, 350);
INSERT INTO public.recibos_conceptos VALUES (2751, 9, 1350.81, 350);
INSERT INTO public.recibos_conceptos VALUES (2752, 10, 1350.81, 350);
INSERT INTO public.recibos_conceptos VALUES (2753, 11, 11256.76, 350);
INSERT INTO public.recibos_conceptos VALUES (2754, 4, 38158.50, 350);
INSERT INTO public.recibos_conceptos VALUES (2755, 1, 15764.70, 351);
INSERT INTO public.recibos_conceptos VALUES (2756, 12, 1576.47, 351);
INSERT INTO public.recibos_conceptos VALUES (2757, 5, 0.00, 351);
INSERT INTO public.recibos_conceptos VALUES (2758, 6, 630.59, 351);
INSERT INTO public.recibos_conceptos VALUES (2759, 7, 0.00, 351);
INSERT INTO public.recibos_conceptos VALUES (2760, 9, 539.15, 351);
INSERT INTO public.recibos_conceptos VALUES (2761, 10, 539.15, 351);
INSERT INTO public.recibos_conceptos VALUES (2762, 11, 4492.94, 351);
INSERT INTO public.recibos_conceptos VALUES (2763, 4, 15764.70, 351);
INSERT INTO public.recibos_conceptos VALUES (2764, 1, 39104.00, 352);
INSERT INTO public.recibos_conceptos VALUES (2765, 12, 3910.40, 352);
INSERT INTO public.recibos_conceptos VALUES (2766, 5, 0.00, 352);
INSERT INTO public.recibos_conceptos VALUES (2767, 6, 8602.88, 352);
INSERT INTO public.recibos_conceptos VALUES (2768, 7, 0.00, 352);
INSERT INTO public.recibos_conceptos VALUES (2769, 9, 1548.52, 352);
INSERT INTO public.recibos_conceptos VALUES (2770, 10, 1548.52, 352);
INSERT INTO public.recibos_conceptos VALUES (2771, 11, 12904.32, 352);
INSERT INTO public.recibos_conceptos VALUES (2772, 4, 39104.00, 352);
INSERT INTO public.recibos_conceptos VALUES (2773, 1, 45948.50, 353);
INSERT INTO public.recibos_conceptos VALUES (2774, 12, 4594.85, 353);
INSERT INTO public.recibos_conceptos VALUES (2775, 5, 0.00, 353);
INSERT INTO public.recibos_conceptos VALUES (2776, 6, 29407.04, 353);
INSERT INTO public.recibos_conceptos VALUES (2777, 7, 0.00, 353);
INSERT INTO public.recibos_conceptos VALUES (2778, 9, 2398.51, 353);
INSERT INTO public.recibos_conceptos VALUES (2779, 10, 2398.51, 353);
INSERT INTO public.recibos_conceptos VALUES (2780, 11, 19987.60, 353);
INSERT INTO public.recibos_conceptos VALUES (2781, 4, 45948.50, 353);
INSERT INTO public.recibos_conceptos VALUES (2782, 1, 34958.80, 354);
INSERT INTO public.recibos_conceptos VALUES (2783, 12, 3495.88, 354);
INSERT INTO public.recibos_conceptos VALUES (2784, 5, 0.00, 354);
INSERT INTO public.recibos_conceptos VALUES (2785, 6, 3495.88, 354);
INSERT INTO public.recibos_conceptos VALUES (2786, 7, 0.00, 354);
INSERT INTO public.recibos_conceptos VALUES (2787, 9, 1258.52, 354);
INSERT INTO public.recibos_conceptos VALUES (2788, 10, 1258.52, 354);
INSERT INTO public.recibos_conceptos VALUES (2789, 11, 10487.64, 354);
INSERT INTO public.recibos_conceptos VALUES (2790, 4, 34958.80, 354);
INSERT INTO public.recibos_conceptos VALUES (2791, 1, 57061.70, 355);
INSERT INTO public.recibos_conceptos VALUES (2792, 12, 5706.17, 355);
INSERT INTO public.recibos_conceptos VALUES (2793, 5, 0.00, 355);
INSERT INTO public.recibos_conceptos VALUES (2794, 6, 36519.49, 355);
INSERT INTO public.recibos_conceptos VALUES (2795, 7, 0.00, 355);
INSERT INTO public.recibos_conceptos VALUES (2796, 9, 2978.62, 355);
INSERT INTO public.recibos_conceptos VALUES (2797, 10, 2978.62, 355);
INSERT INTO public.recibos_conceptos VALUES (2798, 11, 24821.84, 355);
INSERT INTO public.recibos_conceptos VALUES (2799, 4, 57061.70, 355);
INSERT INTO public.recibos_conceptos VALUES (2800, 1, 34892.86, 356);
INSERT INTO public.recibos_conceptos VALUES (2801, 12, 3489.29, 356);
INSERT INTO public.recibos_conceptos VALUES (2802, 5, 0.00, 356);
INSERT INTO public.recibos_conceptos VALUES (2803, 6, 697.86, 356);
INSERT INTO public.recibos_conceptos VALUES (2804, 7, 0.00, 356);
INSERT INTO public.recibos_conceptos VALUES (2805, 9, 1172.40, 356);
INSERT INTO public.recibos_conceptos VALUES (2806, 10, 1172.40, 356);
INSERT INTO public.recibos_conceptos VALUES (2807, 11, 9770.00, 356);
INSERT INTO public.recibos_conceptos VALUES (2808, 4, 34892.86, 356);
INSERT INTO public.recibos_conceptos VALUES (2849, 24, 5000.00, 337);
INSERT INTO public.recibos_conceptos VALUES (2850, 24, 5000.00, 338);
INSERT INTO public.recibos_conceptos VALUES (2851, 24, 5000.00, 339);
INSERT INTO public.recibos_conceptos VALUES (2852, 24, 5000.00, 340);
INSERT INTO public.recibos_conceptos VALUES (2853, 24, 5000.00, 341);
INSERT INTO public.recibos_conceptos VALUES (2854, 24, 5000.00, 342);
INSERT INTO public.recibos_conceptos VALUES (2855, 24, 5000.00, 343);
INSERT INTO public.recibos_conceptos VALUES (2856, 24, 5000.00, 344);
INSERT INTO public.recibos_conceptos VALUES (2857, 24, 5000.00, 345);
INSERT INTO public.recibos_conceptos VALUES (2858, 24, 5000.00, 346);
INSERT INTO public.recibos_conceptos VALUES (2859, 24, 5000.00, 347);
INSERT INTO public.recibos_conceptos VALUES (2860, 24, 5000.00, 348);
INSERT INTO public.recibos_conceptos VALUES (2861, 24, 5000.00, 349);
INSERT INTO public.recibos_conceptos VALUES (2862, 24, 5000.00, 350);
INSERT INTO public.recibos_conceptos VALUES (2863, 24, 5000.00, 351);
INSERT INTO public.recibos_conceptos VALUES (2864, 24, 5000.00, 352);
INSERT INTO public.recibos_conceptos VALUES (2865, 24, 5000.00, 353);
INSERT INTO public.recibos_conceptos VALUES (2866, 24, 5000.00, 354);
INSERT INTO public.recibos_conceptos VALUES (2867, 24, 5000.00, 355);
INSERT INTO public.recibos_conceptos VALUES (2868, 24, 5000.00, 356);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 2868, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 356, true);


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

INSERT INTO public.tabla VALUES (1, 'especiales', 'Deducciones Especiales');
INSERT INTO public.tabla VALUES (2, 'conyuge', 'Deducciones Cónyuge');
INSERT INTO public.tabla VALUES (3, 'hijo', 'Deducciones Hijo');
INSERT INTO public.tabla VALUES (4, 'familia', 'Cargas de familia');
INSERT INTO public.tabla VALUES (5, 'ganancia', 'Ganancia no imponible');
INSERT INTO public.tabla VALUES (6, 'hipoteca', 'Intereses créditos hipotecarios');
INSERT INTO public.tabla VALUES (7, 'segurovida', 'Seguro de Vida');
INSERT INTO public.tabla VALUES (8, 'prepaga', 'Prepaga');


--
-- Data for Name: tabla_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_detalle VALUES (4, 2019, 4, '2019-04-01', 137358.38, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (5, 2019, 5, '2019-05-01', 171697.98, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (6, 2019, 6, '2019-06-01', 206037.57, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (7, 2019, 7, '2019-07-01', 240377.17, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (8, 2019, 8, '2019-08-01', 274716.76, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (9, 2019, 9, '2019-09-01', 309056.36, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (10, 2019, 10, '2019-10-01', 343395.95, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (11, 2019, 11, '2019-11-01', 377735.55, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (12, 2019, 12, '2019-12-01', 412075.14, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (1, 2019, 1, '2019-01-01', 34339.60, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (2, 2019, 2, '2019-02-01', 68679.19, 0.00, 1);
INSERT INTO public.tabla_detalle VALUES (3, 2019, 3, '2019-03-01', 103018.79, 0.00, 1);
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


--
-- Name: tabla_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_detalle_id_seq', 84, true);


--
-- Data for Name: tabla_ganancias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_ganancias VALUES (1, 2019, 'Tabla Ganancias 2019');


--
-- Data for Name: tabla_ganancias_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_ganancias_detalle VALUES (1, 1, 0.00, 5000.00, 100.00, 100.00, 0.00, 1);
INSERT INTO public.tabla_ganancias_detalle VALUES (2, 2, 100.00, 100.00, 100.00, 100.00, 11.00, 1);
INSERT INTO public.tabla_ganancias_detalle VALUES (3, 3, 100.00, 100.00, 100.00, 100.00, 10.00, 1);
INSERT INTO public.tabla_ganancias_detalle VALUES (4, 1, 100.00, 100.00, 100.00, 100.00, 100.00, 1);
INSERT INTO public.tabla_ganancias_detalle VALUES (5, 1, 20.00, 50.00, 100.00, 10.00, 110.00, 1);


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_detalle_id_seq', 5, true);


--
-- Name: tabla_ganancias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_id_seq', 1, true);


--
-- Name: tabla_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_id_seq', 8, true);


--
-- Data for Name: tabla_personas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_personas VALUES (1, 2019, 12, '2019-12-01', 5000.00, 8, 1);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 1, true);


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


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 13, true);


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



--
-- Name: tipos_empleadores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_empleadores_id_seq', 1, false);


--
-- Data for Name: tipos_liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_liquidaciones VALUES (1, 'Liquidación Mensual Normal', true);
INSERT INTO public.tipos_liquidaciones VALUES (2, 'Vacaciones', true);
INSERT INTO public.tipos_liquidaciones VALUES (3, '1er Semestre SAC', true);
INSERT INTO public.tipos_liquidaciones VALUES (4, '2do Semestre SAC', true);
INSERT INTO public.tipos_liquidaciones VALUES (5, 'Despido Con Causa', true);
INSERT INTO public.tipos_liquidaciones VALUES (6, 'Despido sin Causa', true);


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


--
-- Name: reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.reservadas_id_seq', 17, true);


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
-- Name: pk_recibos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos PRIMARY KEY (id);


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
-- Name: uk_recibos_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladores UNIQUE (id_recibo, id_acumulador);


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

