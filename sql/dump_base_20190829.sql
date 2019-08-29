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
INSERT INTO public.conceptos VALUES (13, 'Ganancias - SAC Devengado', '301', 4, 'bruto/12', false, false, false, 'Se usa solo para calculos', NULL, false, false);
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
INSERT INTO public.conceptos VALUES (40, 'Ganancia Escala', '370', 4, 'ganancias(c360)', false, false, false, 'Realiza el calculo final de ganancia Mensual.
Le pasa a la funcion ganancia() el valor de la "Ganancia neta imponible"(c360).', NULL, false, false);
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

SELECT pg_catalog.setval('public.conceptos_id_seq', 40, true);


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

INSERT INTO public.liquidaciones VALUES (57, 'Liquidacion Enero 2019', '2019-01-01', '2019-08-01', '2019-01-31', 1, 1, 1, '2019-02-01', 'Enero', 'Lujan', '2019-02-01', 2, 1, 2019);


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (719, 1, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (720, 7, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (721, 12, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (722, 4, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (723, 5, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (724, 6, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (725, 13, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (726, 14, 57, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (727, 16, 57, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (728, 15, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (729, 17, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (730, 18, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (731, 19, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (732, 20, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (733, 21, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (734, 22, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (735, 23, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (736, 32, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (737, 24, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (738, 25, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (739, 26, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (740, 29, 57, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (741, 27, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (742, 28, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (743, 30, 57, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (744, 31, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (745, 33, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (746, 34, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (747, 35, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (748, 36, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (749, 37, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (750, 38, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (751, 40, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (752, 9, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (753, 10, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (754, 11, 57, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (755, 39, 57, NULL);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 755, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 57, true);


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
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265630562', 7.00, 34892.86, 0, 8.00);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '20265838333', 7.00, 41008.81, 0, 8.00);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27144901008', 7.00, 46807.40, 0, 8.00);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, NULL, '27927271414', 7.00, 24061.43, 0, 4.00);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 34351.20, 0, 8.00);


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

INSERT INTO public.recibos VALUES (737, 737, 8, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (738, 738, 9, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (739, 739, 10, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (740, 740, 11, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (741, 741, 12, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (742, 742, 13, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (743, 743, 14, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (744, 744, 15, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (745, 745, 16, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (746, 746, 17, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (747, 747, 18, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (748, 748, 19, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (749, 749, 20, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (750, 750, 21, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (751, 751, 22, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (752, 752, 23, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (753, 753, 24, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (754, 754, 25, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (755, 755, 26, NULL, NULL, NULL, NULL, NULL, 57);
INSERT INTO public.recibos VALUES (756, 756, 7, NULL, NULL, NULL, NULL, NULL, 57);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (2261, 1, 39080.00, 756);
INSERT INTO public.recibos_acumuladores VALUES (2262, 2, 0.00, 756);
INSERT INTO public.recibos_acumuladores VALUES (2263, 3, 39080.00, 756);
INSERT INTO public.recibos_acumuladores VALUES (2264, 4, 0.00, 756);
INSERT INTO public.recibos_acumuladores VALUES (2265, 5, 12114.80, 756);
INSERT INTO public.recibos_acumuladores VALUES (2266, 1, 42595.49, 737);
INSERT INTO public.recibos_acumuladores VALUES (2267, 2, 0.00, 737);
INSERT INTO public.recibos_acumuladores VALUES (2268, 3, 42595.49, 737);
INSERT INTO public.recibos_acumuladores VALUES (2269, 4, 0.00, 737);
INSERT INTO public.recibos_acumuladores VALUES (2270, 5, 13204.60, 737);
INSERT INTO public.recibos_acumuladores VALUES (2271, 1, 49210.57, 738);
INSERT INTO public.recibos_acumuladores VALUES (2272, 2, 0.00, 738);
INSERT INTO public.recibos_acumuladores VALUES (2273, 3, 49210.57, 738);
INSERT INTO public.recibos_acumuladores VALUES (2274, 4, 0.00, 738);
INSERT INTO public.recibos_acumuladores VALUES (2275, 5, 15255.28, 738);
INSERT INTO public.recibos_acumuladores VALUES (2276, 1, 79572.58, 739);
INSERT INTO public.recibos_acumuladores VALUES (2277, 2, 0.00, 739);
INSERT INTO public.recibos_acumuladores VALUES (2278, 3, 79572.58, 739);
INSERT INTO public.recibos_acumuladores VALUES (2279, 4, 0.00, 739);
INSERT INTO public.recibos_acumuladores VALUES (2280, 5, 24667.50, 739);
INSERT INTO public.recibos_acumuladores VALUES (2281, 1, 30317.40, 740);
INSERT INTO public.recibos_acumuladores VALUES (2282, 2, 0.00, 740);
INSERT INTO public.recibos_acumuladores VALUES (2283, 3, 30317.40, 740);
INSERT INTO public.recibos_acumuladores VALUES (2284, 4, 0.00, 740);
INSERT INTO public.recibos_acumuladores VALUES (2285, 5, 9398.39, 740);
INSERT INTO public.recibos_acumuladores VALUES (2286, 1, 41567.27, 741);
INSERT INTO public.recibos_acumuladores VALUES (2287, 2, 0.00, 741);
INSERT INTO public.recibos_acumuladores VALUES (2288, 3, 41567.27, 741);
INSERT INTO public.recibos_acumuladores VALUES (2289, 4, 0.00, 741);
INSERT INTO public.recibos_acumuladores VALUES (2290, 5, 12885.85, 741);
INSERT INTO public.recibos_acumuladores VALUES (2291, 1, 84533.20, 742);
INSERT INTO public.recibos_acumuladores VALUES (2292, 2, 0.00, 742);
INSERT INTO public.recibos_acumuladores VALUES (2293, 3, 84533.20, 742);
INSERT INTO public.recibos_acumuladores VALUES (2294, 4, 0.00, 742);
INSERT INTO public.recibos_acumuladores VALUES (2295, 5, 26205.29, 742);
INSERT INTO public.recibos_acumuladores VALUES (2296, 1, 20010.00, 743);
INSERT INTO public.recibos_acumuladores VALUES (2297, 2, 0.00, 743);
INSERT INTO public.recibos_acumuladores VALUES (2298, 3, 20010.00, 743);
INSERT INTO public.recibos_acumuladores VALUES (2299, 4, 0.00, 743);
INSERT INTO public.recibos_acumuladores VALUES (2300, 5, 6203.10, 743);
INSERT INTO public.recibos_acumuladores VALUES (2301, 1, 78000.00, 744);
INSERT INTO public.recibos_acumuladores VALUES (2302, 2, 0.00, 744);
INSERT INTO public.recibos_acumuladores VALUES (2303, 3, 78000.00, 744);
INSERT INTO public.recibos_acumuladores VALUES (2304, 4, 0.00, 744);
INSERT INTO public.recibos_acumuladores VALUES (2305, 5, 24180.00, 744);
INSERT INTO public.recibos_acumuladores VALUES (2306, 1, 42039.72, 745);
INSERT INTO public.recibos_acumuladores VALUES (2307, 2, 0.00, 745);
INSERT INTO public.recibos_acumuladores VALUES (2308, 3, 42039.72, 745);
INSERT INTO public.recibos_acumuladores VALUES (2309, 4, 0.00, 745);
INSERT INTO public.recibos_acumuladores VALUES (2310, 5, 13032.31, 745);
INSERT INTO public.recibos_acumuladores VALUES (2311, 1, 65574.74, 746);
INSERT INTO public.recibos_acumuladores VALUES (2312, 2, 0.00, 746);
INSERT INTO public.recibos_acumuladores VALUES (2313, 3, 65574.74, 746);
INSERT INTO public.recibos_acumuladores VALUES (2314, 4, 0.00, 746);
INSERT INTO public.recibos_acumuladores VALUES (2315, 5, 20328.17, 746);
INSERT INTO public.recibos_acumuladores VALUES (2316, 1, 57173.51, 747);
INSERT INTO public.recibos_acumuladores VALUES (2317, 2, 0.00, 747);
INSERT INTO public.recibos_acumuladores VALUES (2318, 3, 57173.51, 747);
INSERT INTO public.recibos_acumuladores VALUES (2319, 4, 0.00, 747);
INSERT INTO public.recibos_acumuladores VALUES (2320, 5, 17723.79, 747);
INSERT INTO public.recibos_acumuladores VALUES (2321, 1, 77302.08, 748);
INSERT INTO public.recibos_acumuladores VALUES (2322, 2, 0.00, 748);
INSERT INTO public.recibos_acumuladores VALUES (2323, 3, 77302.08, 748);
INSERT INTO public.recibos_acumuladores VALUES (2324, 4, 0.00, 748);
INSERT INTO public.recibos_acumuladores VALUES (2325, 5, 23963.64, 748);
INSERT INTO public.recibos_acumuladores VALUES (2326, 1, 54678.40, 749);
INSERT INTO public.recibos_acumuladores VALUES (2327, 2, 0.00, 749);
INSERT INTO public.recibos_acumuladores VALUES (2328, 3, 54678.40, 749);
INSERT INTO public.recibos_acumuladores VALUES (2329, 4, 0.00, 749);
INSERT INTO public.recibos_acumuladores VALUES (2330, 5, 16950.30, 749);
INSERT INTO public.recibos_acumuladores VALUES (2331, 1, 45027.03, 750);
INSERT INTO public.recibos_acumuladores VALUES (2332, 2, 0.00, 750);
INSERT INTO public.recibos_acumuladores VALUES (2333, 3, 45027.03, 750);
INSERT INTO public.recibos_acumuladores VALUES (2334, 4, 0.00, 750);
INSERT INTO public.recibos_acumuladores VALUES (2335, 5, 13958.38, 750);
INSERT INTO public.recibos_acumuladores VALUES (2336, 1, 17971.76, 751);
INSERT INTO public.recibos_acumuladores VALUES (2337, 2, 0.00, 751);
INSERT INTO public.recibos_acumuladores VALUES (2338, 3, 17971.76, 751);
INSERT INTO public.recibos_acumuladores VALUES (2339, 4, 0.00, 751);
INSERT INTO public.recibos_acumuladores VALUES (2340, 5, 5571.24, 751);
INSERT INTO public.recibos_acumuladores VALUES (2341, 1, 51617.28, 752);
INSERT INTO public.recibos_acumuladores VALUES (2342, 2, 0.00, 752);
INSERT INTO public.recibos_acumuladores VALUES (2343, 3, 51617.28, 752);
INSERT INTO public.recibos_acumuladores VALUES (2344, 4, 0.00, 752);
INSERT INTO public.recibos_acumuladores VALUES (2345, 5, 16001.36, 752);
INSERT INTO public.recibos_acumuladores VALUES (2346, 1, 79950.39, 753);
INSERT INTO public.recibos_acumuladores VALUES (2347, 2, 0.00, 753);
INSERT INTO public.recibos_acumuladores VALUES (2348, 3, 79950.39, 753);
INSERT INTO public.recibos_acumuladores VALUES (2349, 4, 0.00, 753);
INSERT INTO public.recibos_acumuladores VALUES (2350, 5, 24784.62, 753);
INSERT INTO public.recibos_acumuladores VALUES (2351, 1, 41950.56, 754);
INSERT INTO public.recibos_acumuladores VALUES (2352, 2, 0.00, 754);
INSERT INTO public.recibos_acumuladores VALUES (2353, 3, 41950.56, 754);
INSERT INTO public.recibos_acumuladores VALUES (2354, 4, 0.00, 754);
INSERT INTO public.recibos_acumuladores VALUES (2355, 5, 13004.67, 754);
INSERT INTO public.recibos_acumuladores VALUES (2356, 1, 99287.36, 755);
INSERT INTO public.recibos_acumuladores VALUES (2357, 2, 0.00, 755);
INSERT INTO public.recibos_acumuladores VALUES (2358, 3, 99287.36, 755);
INSERT INTO public.recibos_acumuladores VALUES (2359, 4, 0.00, 755);
INSERT INTO public.recibos_acumuladores VALUES (2360, 5, 30779.08, 755);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 2360, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (14540, 14, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14541, 16, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14554, 29, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14557, 30, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14577, 14, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14578, 16, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14591, 29, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14594, 30, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14614, 14, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14615, 16, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14628, 29, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14631, 30, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14651, 14, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14652, 16, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14665, 29, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14668, 30, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14688, 14, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14689, 16, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14702, 29, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14705, 30, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14725, 14, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14726, 16, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14739, 29, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14742, 30, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14762, 14, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14763, 16, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14776, 29, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14779, 30, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14799, 14, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14800, 16, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14813, 29, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14816, 30, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14836, 14, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14837, 16, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14850, 29, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14853, 30, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14873, 14, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14874, 16, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14887, 29, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14890, 30, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14910, 14, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14911, 16, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14924, 29, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14927, 30, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14944, 5, 3.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14947, 14, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14948, 16, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14961, 29, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14964, 30, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14984, 14, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (14985, 16, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (14998, 29, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15001, 30, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15021, 14, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15022, 16, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15035, 29, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15038, 30, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15058, 14, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15059, 16, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15072, 29, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15075, 30, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15095, 14, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15096, 16, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15109, 29, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15112, 30, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15132, 14, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15133, 16, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15146, 29, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15149, 30, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15169, 14, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15170, 16, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15183, 29, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15186, 30, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15206, 14, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15207, 16, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15220, 29, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15223, 30, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15243, 14, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15244, 16, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15257, 29, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15260, 30, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (14533, 1, 34351.20, 737);
INSERT INTO public.recibos_conceptos VALUES (14534, 7, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14535, 12, 3435.12, 737);
INSERT INTO public.recibos_conceptos VALUES (14536, 4, 34351.20, 737);
INSERT INTO public.recibos_conceptos VALUES (14537, 5, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14538, 6, 4809.17, 737);
INSERT INTO public.recibos_conceptos VALUES (14539, 13, 3549.62, 737);
INSERT INTO public.recibos_conceptos VALUES (14542, 15, 46145.11, 737);
INSERT INTO public.recibos_conceptos VALUES (14543, 17, 5075.96, 737);
INSERT INTO public.recibos_conceptos VALUES (14544, 18, 1384.35, 737);
INSERT INTO public.recibos_conceptos VALUES (14545, 19, 1384.35, 737);
INSERT INTO public.recibos_conceptos VALUES (14546, 20, 1153.63, 737);
INSERT INTO public.recibos_conceptos VALUES (14547, 21, 8998.30, 737);
INSERT INTO public.recibos_conceptos VALUES (14548, 22, 37146.82, 737);
INSERT INTO public.recibos_conceptos VALUES (14549, 23, 37146.82, 737);
INSERT INTO public.recibos_conceptos VALUES (14550, 32, 1857.34, 737);
INSERT INTO public.recibos_conceptos VALUES (14551, 24, 34339.60, 737);
INSERT INTO public.recibos_conceptos VALUES (14552, 25, 6669.50, 737);
INSERT INTO public.recibos_conceptos VALUES (14553, 26, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14555, 27, 7154.08, 737);
INSERT INTO public.recibos_conceptos VALUES (14556, 28, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14558, 31, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14559, 33, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14560, 34, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14561, 35, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14562, 36, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14563, 37, 48163.18, 737);
INSERT INTO public.recibos_conceptos VALUES (14564, 38, -11016.36, 737);
INSERT INTO public.recibos_conceptos VALUES (14565, 40, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14566, 9, 1277.86, 737);
INSERT INTO public.recibos_conceptos VALUES (14567, 10, 1277.86, 737);
INSERT INTO public.recibos_conceptos VALUES (14568, 11, 10648.87, 737);
INSERT INTO public.recibos_conceptos VALUES (14569, 39, 0.00, 737);
INSERT INTO public.recibos_conceptos VALUES (14570, 1, 41008.81, 738);
INSERT INTO public.recibos_conceptos VALUES (14571, 7, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14572, 12, 4100.88, 738);
INSERT INTO public.recibos_conceptos VALUES (14573, 4, 41008.81, 738);
INSERT INTO public.recibos_conceptos VALUES (14574, 5, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14575, 6, 4100.88, 738);
INSERT INTO public.recibos_conceptos VALUES (14576, 13, 4100.88, 738);
INSERT INTO public.recibos_conceptos VALUES (14579, 15, 53311.45, 738);
INSERT INTO public.recibos_conceptos VALUES (14580, 17, 5864.26, 738);
INSERT INTO public.recibos_conceptos VALUES (14581, 18, 1599.34, 738);
INSERT INTO public.recibos_conceptos VALUES (14582, 19, 1599.34, 738);
INSERT INTO public.recibos_conceptos VALUES (14583, 20, 1332.79, 738);
INSERT INTO public.recibos_conceptos VALUES (14584, 21, 10395.73, 738);
INSERT INTO public.recibos_conceptos VALUES (14585, 22, 42915.72, 738);
INSERT INTO public.recibos_conceptos VALUES (14586, 23, 42915.72, 738);
INSERT INTO public.recibos_conceptos VALUES (14587, 32, 2145.79, 738);
INSERT INTO public.recibos_conceptos VALUES (14588, 24, 34339.60, 738);
INSERT INTO public.recibos_conceptos VALUES (14589, 25, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14590, 26, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14592, 27, 7154.08, 738);
INSERT INTO public.recibos_conceptos VALUES (14593, 28, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14595, 31, 2145.79, 738);
INSERT INTO public.recibos_conceptos VALUES (14596, 33, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14597, 34, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14598, 35, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14599, 36, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14600, 37, 43639.47, 738);
INSERT INTO public.recibos_conceptos VALUES (14601, 38, -723.75, 738);
INSERT INTO public.recibos_conceptos VALUES (14602, 40, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14603, 9, 1476.32, 738);
INSERT INTO public.recibos_conceptos VALUES (14604, 10, 1476.32, 738);
INSERT INTO public.recibos_conceptos VALUES (14605, 11, 12302.64, 738);
INSERT INTO public.recibos_conceptos VALUES (14606, 39, 0.00, 738);
INSERT INTO public.recibos_conceptos VALUES (14607, 1, 46807.40, 739);
INSERT INTO public.recibos_conceptos VALUES (14608, 7, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14609, 12, 4680.74, 739);
INSERT INTO public.recibos_conceptos VALUES (14610, 4, 46807.40, 739);
INSERT INTO public.recibos_conceptos VALUES (14611, 5, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14612, 6, 28084.44, 739);
INSERT INTO public.recibos_conceptos VALUES (14613, 13, 6631.05, 739);
INSERT INTO public.recibos_conceptos VALUES (14616, 15, 86203.63, 739);
INSERT INTO public.recibos_conceptos VALUES (14617, 17, 9482.40, 739);
INSERT INTO public.recibos_conceptos VALUES (14618, 18, 2586.11, 739);
INSERT INTO public.recibos_conceptos VALUES (14619, 19, 2586.11, 739);
INSERT INTO public.recibos_conceptos VALUES (14620, 20, 2155.09, 739);
INSERT INTO public.recibos_conceptos VALUES (14621, 21, 16809.71, 739);
INSERT INTO public.recibos_conceptos VALUES (14622, 22, 69393.92, 739);
INSERT INTO public.recibos_conceptos VALUES (14623, 23, 69393.92, 739);
INSERT INTO public.recibos_conceptos VALUES (14624, 32, 3469.70, 739);
INSERT INTO public.recibos_conceptos VALUES (14625, 24, 34339.60, 739);
INSERT INTO public.recibos_conceptos VALUES (14626, 25, 6669.50, 739);
INSERT INTO public.recibos_conceptos VALUES (14627, 26, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14629, 27, 7154.08, 739);
INSERT INTO public.recibos_conceptos VALUES (14630, 28, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14632, 31, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14633, 33, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14634, 34, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14635, 35, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14636, 36, 0.00, 739);
INSERT INTO public.recibos_conceptos VALUES (14637, 37, 48163.18, 739);
INSERT INTO public.recibos_conceptos VALUES (14638, 38, 21230.74, 739);
INSERT INTO public.recibos_conceptos VALUES (14639, 40, 110524.46, 739);
INSERT INTO public.recibos_conceptos VALUES (14640, 9, 2387.18, 739);
INSERT INTO public.recibos_conceptos VALUES (14641, 10, 2387.18, 739);
INSERT INTO public.recibos_conceptos VALUES (14642, 11, 19893.15, 739);
INSERT INTO public.recibos_conceptos VALUES (14643, 39, 110524.46, 739);
INSERT INTO public.recibos_conceptos VALUES (14644, 1, 24061.43, 740);
INSERT INTO public.recibos_conceptos VALUES (14645, 7, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14646, 12, 2406.14, 740);
INSERT INTO public.recibos_conceptos VALUES (14647, 4, 24061.43, 740);
INSERT INTO public.recibos_conceptos VALUES (14648, 5, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14649, 6, 3849.83, 740);
INSERT INTO public.recibos_conceptos VALUES (14650, 13, 2526.45, 740);
INSERT INTO public.recibos_conceptos VALUES (14653, 15, 32843.85, 740);
INSERT INTO public.recibos_conceptos VALUES (14654, 17, 3612.82, 740);
INSERT INTO public.recibos_conceptos VALUES (14655, 18, 985.32, 740);
INSERT INTO public.recibos_conceptos VALUES (14656, 19, 985.32, 740);
INSERT INTO public.recibos_conceptos VALUES (14657, 20, 821.10, 740);
INSERT INTO public.recibos_conceptos VALUES (14658, 21, 6404.55, 740);
INSERT INTO public.recibos_conceptos VALUES (14659, 22, 26439.30, 740);
INSERT INTO public.recibos_conceptos VALUES (14660, 23, 26439.30, 740);
INSERT INTO public.recibos_conceptos VALUES (14661, 32, 1321.97, 740);
INSERT INTO public.recibos_conceptos VALUES (14662, 24, 34339.60, 740);
INSERT INTO public.recibos_conceptos VALUES (14663, 25, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14664, 26, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14666, 27, 7154.08, 740);
INSERT INTO public.recibos_conceptos VALUES (14667, 28, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14669, 31, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14670, 33, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14671, 34, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14672, 35, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14673, 36, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14674, 37, 41493.68, 740);
INSERT INTO public.recibos_conceptos VALUES (14675, 38, -15054.38, 740);
INSERT INTO public.recibos_conceptos VALUES (14676, 40, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14677, 9, 909.52, 740);
INSERT INTO public.recibos_conceptos VALUES (14678, 10, 909.52, 740);
INSERT INTO public.recibos_conceptos VALUES (14679, 11, 7579.35, 740);
INSERT INTO public.recibos_conceptos VALUES (14680, 39, 0.00, 740);
INSERT INTO public.recibos_conceptos VALUES (14681, 1, 35226.50, 741);
INSERT INTO public.recibos_conceptos VALUES (14682, 7, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14683, 12, 3522.65, 741);
INSERT INTO public.recibos_conceptos VALUES (14684, 4, 35226.50, 741);
INSERT INTO public.recibos_conceptos VALUES (14685, 5, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14686, 6, 2818.12, 741);
INSERT INTO public.recibos_conceptos VALUES (14687, 13, 3463.94, 741);
INSERT INTO public.recibos_conceptos VALUES (14690, 15, 45031.21, 741);
INSERT INTO public.recibos_conceptos VALUES (14691, 17, 4953.43, 741);
INSERT INTO public.recibos_conceptos VALUES (14692, 18, 1350.94, 741);
INSERT INTO public.recibos_conceptos VALUES (14693, 19, 1350.94, 741);
INSERT INTO public.recibos_conceptos VALUES (14694, 20, 1125.78, 741);
INSERT INTO public.recibos_conceptos VALUES (14695, 21, 8781.09, 741);
INSERT INTO public.recibos_conceptos VALUES (14696, 22, 36250.12, 741);
INSERT INTO public.recibos_conceptos VALUES (14697, 23, 36250.12, 741);
INSERT INTO public.recibos_conceptos VALUES (14698, 32, 1812.51, 741);
INSERT INTO public.recibos_conceptos VALUES (14699, 24, 34339.60, 741);
INSERT INTO public.recibos_conceptos VALUES (14700, 25, 6669.50, 741);
INSERT INTO public.recibos_conceptos VALUES (14701, 26, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14703, 27, 7154.08, 741);
INSERT INTO public.recibos_conceptos VALUES (14704, 28, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14706, 31, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14707, 33, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14708, 34, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14709, 35, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14710, 36, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14711, 37, 48163.18, 741);
INSERT INTO public.recibos_conceptos VALUES (14712, 38, -11913.06, 741);
INSERT INTO public.recibos_conceptos VALUES (14713, 40, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14714, 9, 1247.02, 741);
INSERT INTO public.recibos_conceptos VALUES (14715, 10, 1247.02, 741);
INSERT INTO public.recibos_conceptos VALUES (14716, 11, 10391.82, 741);
INSERT INTO public.recibos_conceptos VALUES (14717, 39, 0.00, 741);
INSERT INTO public.recibos_conceptos VALUES (14718, 1, 48582.30, 742);
INSERT INTO public.recibos_conceptos VALUES (14719, 7, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14720, 12, 4858.23, 742);
INSERT INTO public.recibos_conceptos VALUES (14721, 4, 48582.30, 742);
INSERT INTO public.recibos_conceptos VALUES (14722, 5, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14723, 6, 31092.67, 742);
INSERT INTO public.recibos_conceptos VALUES (14724, 13, 7044.43, 742);
INSERT INTO public.recibos_conceptos VALUES (14727, 15, 91577.64, 742);
INSERT INTO public.recibos_conceptos VALUES (14728, 17, 10073.54, 742);
INSERT INTO public.recibos_conceptos VALUES (14729, 18, 2747.33, 742);
INSERT INTO public.recibos_conceptos VALUES (14730, 19, 2747.33, 742);
INSERT INTO public.recibos_conceptos VALUES (14731, 20, 2289.44, 742);
INSERT INTO public.recibos_conceptos VALUES (14732, 21, 17857.64, 742);
INSERT INTO public.recibos_conceptos VALUES (14733, 22, 73720.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14734, 23, 73720.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14735, 32, 3686.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14736, 24, 34339.60, 742);
INSERT INTO public.recibos_conceptos VALUES (14737, 25, 6669.50, 742);
INSERT INTO public.recibos_conceptos VALUES (14738, 26, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14740, 27, 7154.08, 742);
INSERT INTO public.recibos_conceptos VALUES (14741, 28, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14743, 31, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14744, 33, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14745, 34, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14746, 35, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14747, 36, 0.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14748, 37, 48163.18, 742);
INSERT INTO public.recibos_conceptos VALUES (14749, 38, 25556.82, 742);
INSERT INTO public.recibos_conceptos VALUES (14750, 40, 98759.12, 742);
INSERT INTO public.recibos_conceptos VALUES (14751, 9, 2536.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14752, 10, 2536.00, 742);
INSERT INTO public.recibos_conceptos VALUES (14753, 11, 21133.30, 742);
INSERT INTO public.recibos_conceptos VALUES (14754, 39, 98759.12, 742);
INSERT INTO public.recibos_conceptos VALUES (14755, 1, 17250.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14756, 7, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14757, 12, 1725.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14758, 4, 17250.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14759, 5, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14760, 6, 1035.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14761, 13, 1667.50, 743);
INSERT INTO public.recibos_conceptos VALUES (14764, 15, 21677.50, 743);
INSERT INTO public.recibos_conceptos VALUES (14765, 17, 2384.53, 743);
INSERT INTO public.recibos_conceptos VALUES (14766, 18, 650.33, 743);
INSERT INTO public.recibos_conceptos VALUES (14767, 19, 650.33, 743);
INSERT INTO public.recibos_conceptos VALUES (14768, 20, 541.94, 743);
INSERT INTO public.recibos_conceptos VALUES (14769, 21, 4227.11, 743);
INSERT INTO public.recibos_conceptos VALUES (14770, 22, 17450.39, 743);
INSERT INTO public.recibos_conceptos VALUES (14771, 23, 17450.39, 743);
INSERT INTO public.recibos_conceptos VALUES (14772, 32, 872.52, 743);
INSERT INTO public.recibos_conceptos VALUES (14773, 24, 34339.60, 743);
INSERT INTO public.recibos_conceptos VALUES (14774, 25, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14775, 26, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14777, 27, 7154.08, 743);
INSERT INTO public.recibos_conceptos VALUES (14778, 28, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14780, 31, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14781, 33, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14782, 34, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14783, 35, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14784, 36, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14785, 37, 41493.68, 743);
INSERT INTO public.recibos_conceptos VALUES (14786, 38, -24043.29, 743);
INSERT INTO public.recibos_conceptos VALUES (14787, 40, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14788, 9, 600.30, 743);
INSERT INTO public.recibos_conceptos VALUES (14789, 10, 600.30, 743);
INSERT INTO public.recibos_conceptos VALUES (14790, 11, 5002.50, 743);
INSERT INTO public.recibos_conceptos VALUES (14791, 39, 0.00, 743);
INSERT INTO public.recibos_conceptos VALUES (14792, 1, 60000.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14793, 7, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14794, 12, 6000.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14795, 4, 60000.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14796, 5, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14797, 6, 12000.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14798, 13, 6500.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14801, 15, 84500.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14802, 17, 9295.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14803, 18, 2535.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14804, 19, 2535.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14805, 20, 2112.50, 744);
INSERT INTO public.recibos_conceptos VALUES (14806, 21, 16477.50, 744);
INSERT INTO public.recibos_conceptos VALUES (14807, 22, 68022.50, 744);
INSERT INTO public.recibos_conceptos VALUES (14808, 23, 68022.50, 744);
INSERT INTO public.recibos_conceptos VALUES (14809, 32, 3401.13, 744);
INSERT INTO public.recibos_conceptos VALUES (14810, 24, 34339.60, 744);
INSERT INTO public.recibos_conceptos VALUES (14811, 25, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14812, 26, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14814, 27, 7154.08, 744);
INSERT INTO public.recibos_conceptos VALUES (14815, 28, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14817, 31, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14818, 33, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14819, 34, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14820, 35, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14821, 36, 0.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14822, 37, 41493.68, 744);
INSERT INTO public.recibos_conceptos VALUES (14823, 38, 26528.82, 744);
INSERT INTO public.recibos_conceptos VALUES (14824, 40, 125003.21, 744);
INSERT INTO public.recibos_conceptos VALUES (14825, 9, 2340.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14826, 10, 2340.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14827, 11, 19500.00, 744);
INSERT INTO public.recibos_conceptos VALUES (14828, 39, 125003.21, 744);
INSERT INTO public.recibos_conceptos VALUES (14829, 1, 35033.10, 745);
INSERT INTO public.recibos_conceptos VALUES (14830, 7, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14831, 12, 3503.31, 745);
INSERT INTO public.recibos_conceptos VALUES (14832, 4, 35033.10, 745);
INSERT INTO public.recibos_conceptos VALUES (14833, 5, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14834, 6, 3503.31, 745);
INSERT INTO public.recibos_conceptos VALUES (14835, 13, 3503.31, 745);
INSERT INTO public.recibos_conceptos VALUES (14838, 15, 45543.03, 745);
INSERT INTO public.recibos_conceptos VALUES (14839, 17, 5009.73, 745);
INSERT INTO public.recibos_conceptos VALUES (14840, 18, 1366.29, 745);
INSERT INTO public.recibos_conceptos VALUES (14841, 19, 1366.29, 745);
INSERT INTO public.recibos_conceptos VALUES (14842, 20, 1138.58, 745);
INSERT INTO public.recibos_conceptos VALUES (14843, 21, 8880.89, 745);
INSERT INTO public.recibos_conceptos VALUES (14844, 22, 36662.14, 745);
INSERT INTO public.recibos_conceptos VALUES (14845, 23, 36662.14, 745);
INSERT INTO public.recibos_conceptos VALUES (14846, 32, 1833.11, 745);
INSERT INTO public.recibos_conceptos VALUES (14847, 24, 34339.60, 745);
INSERT INTO public.recibos_conceptos VALUES (14848, 25, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14849, 26, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14851, 27, 7154.08, 745);
INSERT INTO public.recibos_conceptos VALUES (14852, 28, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14854, 31, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14855, 33, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14856, 34, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14857, 35, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14858, 36, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14859, 37, 41493.68, 745);
INSERT INTO public.recibos_conceptos VALUES (14860, 38, -4831.54, 745);
INSERT INTO public.recibos_conceptos VALUES (14861, 40, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14862, 9, 1261.19, 745);
INSERT INTO public.recibos_conceptos VALUES (14863, 10, 1261.19, 745);
INSERT INTO public.recibos_conceptos VALUES (14864, 11, 10509.93, 745);
INSERT INTO public.recibos_conceptos VALUES (14865, 39, 0.00, 745);
INSERT INTO public.recibos_conceptos VALUES (14866, 1, 46839.10, 746);
INSERT INTO public.recibos_conceptos VALUES (14867, 7, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14868, 12, 4683.91, 746);
INSERT INTO public.recibos_conceptos VALUES (14869, 4, 46839.10, 746);
INSERT INTO public.recibos_conceptos VALUES (14870, 5, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14871, 6, 14051.73, 746);
INSERT INTO public.recibos_conceptos VALUES (14872, 13, 5464.56, 746);
INSERT INTO public.recibos_conceptos VALUES (14875, 15, 71039.30, 746);
INSERT INTO public.recibos_conceptos VALUES (14876, 17, 7814.32, 746);
INSERT INTO public.recibos_conceptos VALUES (14877, 18, 2131.18, 746);
INSERT INTO public.recibos_conceptos VALUES (14878, 19, 2131.18, 746);
INSERT INTO public.recibos_conceptos VALUES (14879, 20, 1775.98, 746);
INSERT INTO public.recibos_conceptos VALUES (14880, 21, 13852.66, 746);
INSERT INTO public.recibos_conceptos VALUES (14881, 22, 57186.64, 746);
INSERT INTO public.recibos_conceptos VALUES (14882, 23, 57186.64, 746);
INSERT INTO public.recibos_conceptos VALUES (14883, 32, 2859.33, 746);
INSERT INTO public.recibos_conceptos VALUES (14884, 24, 34339.60, 746);
INSERT INTO public.recibos_conceptos VALUES (14885, 25, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14886, 26, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14888, 27, 7154.08, 746);
INSERT INTO public.recibos_conceptos VALUES (14889, 28, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14891, 31, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14892, 33, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14893, 34, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14894, 35, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14895, 36, 0.00, 746);
INSERT INTO public.recibos_conceptos VALUES (14896, 37, 41493.68, 746);
INSERT INTO public.recibos_conceptos VALUES (14897, 38, 15692.96, 746);
INSERT INTO public.recibos_conceptos VALUES (14898, 40, 90042.93, 746);
INSERT INTO public.recibos_conceptos VALUES (14899, 9, 1967.24, 746);
INSERT INTO public.recibos_conceptos VALUES (14900, 10, 1967.24, 746);
INSERT INTO public.recibos_conceptos VALUES (14901, 11, 16393.69, 746);
INSERT INTO public.recibos_conceptos VALUES (14902, 39, 90042.93, 746);
INSERT INTO public.recibos_conceptos VALUES (14903, 1, 42666.80, 747);
INSERT INTO public.recibos_conceptos VALUES (14904, 7, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14905, 12, 4266.68, 747);
INSERT INTO public.recibos_conceptos VALUES (14906, 4, 42666.80, 747);
INSERT INTO public.recibos_conceptos VALUES (14907, 5, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14908, 6, 10240.03, 747);
INSERT INTO public.recibos_conceptos VALUES (14909, 13, 4764.46, 747);
INSERT INTO public.recibos_conceptos VALUES (14912, 15, 61937.97, 747);
INSERT INTO public.recibos_conceptos VALUES (14913, 17, 6813.18, 747);
INSERT INTO public.recibos_conceptos VALUES (14914, 18, 1858.14, 747);
INSERT INTO public.recibos_conceptos VALUES (14915, 19, 1858.14, 747);
INSERT INTO public.recibos_conceptos VALUES (14916, 20, 1548.45, 747);
INSERT INTO public.recibos_conceptos VALUES (14917, 21, 12077.90, 747);
INSERT INTO public.recibos_conceptos VALUES (14918, 22, 49860.07, 747);
INSERT INTO public.recibos_conceptos VALUES (14919, 23, 49860.07, 747);
INSERT INTO public.recibos_conceptos VALUES (14920, 32, 2493.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14921, 24, 34339.60, 747);
INSERT INTO public.recibos_conceptos VALUES (14922, 25, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14923, 26, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14925, 27, 7154.08, 747);
INSERT INTO public.recibos_conceptos VALUES (14926, 28, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14928, 31, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14929, 33, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14930, 34, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14931, 35, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14932, 36, 0.00, 747);
INSERT INTO public.recibos_conceptos VALUES (14933, 37, 41493.68, 747);
INSERT INTO public.recibos_conceptos VALUES (14934, 38, 8366.39, 747);
INSERT INTO public.recibos_conceptos VALUES (14935, 40, 2312.41, 747);
INSERT INTO public.recibos_conceptos VALUES (14936, 9, 1715.21, 747);
INSERT INTO public.recibos_conceptos VALUES (14937, 10, 1715.21, 747);
INSERT INTO public.recibos_conceptos VALUES (14938, 11, 14293.38, 747);
INSERT INTO public.recibos_conceptos VALUES (14939, 39, 2312.41, 747);
INSERT INTO public.recibos_conceptos VALUES (14940, 1, 42012.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14941, 7, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14942, 12, 4201.20, 748);
INSERT INTO public.recibos_conceptos VALUES (14943, 4, 42012.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14945, 6, 31088.88, 748);
INSERT INTO public.recibos_conceptos VALUES (14946, 13, 6441.84, 748);
INSERT INTO public.recibos_conceptos VALUES (14949, 15, 83743.92, 748);
INSERT INTO public.recibos_conceptos VALUES (14950, 17, 9211.83, 748);
INSERT INTO public.recibos_conceptos VALUES (14951, 18, 2512.32, 748);
INSERT INTO public.recibos_conceptos VALUES (14952, 19, 2512.32, 748);
INSERT INTO public.recibos_conceptos VALUES (14953, 20, 2093.60, 748);
INSERT INTO public.recibos_conceptos VALUES (14954, 21, 16330.06, 748);
INSERT INTO public.recibos_conceptos VALUES (14955, 22, 67413.86, 748);
INSERT INTO public.recibos_conceptos VALUES (14956, 23, 67413.86, 748);
INSERT INTO public.recibos_conceptos VALUES (14957, 32, 3370.69, 748);
INSERT INTO public.recibos_conceptos VALUES (14958, 24, 34339.60, 748);
INSERT INTO public.recibos_conceptos VALUES (14959, 25, 6669.50, 748);
INSERT INTO public.recibos_conceptos VALUES (14960, 26, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14962, 27, 7154.08, 748);
INSERT INTO public.recibos_conceptos VALUES (14963, 28, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14965, 31, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14966, 33, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14967, 34, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14968, 35, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14969, 36, 0.00, 748);
INSERT INTO public.recibos_conceptos VALUES (14970, 37, 48163.18, 748);
INSERT INTO public.recibos_conceptos VALUES (14971, 38, 19250.68, 748);
INSERT INTO public.recibos_conceptos VALUES (14972, 40, 64982.96, 748);
INSERT INTO public.recibos_conceptos VALUES (14973, 9, 2319.06, 748);
INSERT INTO public.recibos_conceptos VALUES (14974, 10, 2319.06, 748);
INSERT INTO public.recibos_conceptos VALUES (14975, 11, 19325.52, 748);
INSERT INTO public.recibos_conceptos VALUES (14976, 39, 64982.96, 748);
INSERT INTO public.recibos_conceptos VALUES (14977, 1, 42717.50, 749);
INSERT INTO public.recibos_conceptos VALUES (14978, 7, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (14979, 12, 4271.75, 749);
INSERT INTO public.recibos_conceptos VALUES (14980, 4, 42717.50, 749);
INSERT INTO public.recibos_conceptos VALUES (14981, 5, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (14982, 6, 7689.15, 749);
INSERT INTO public.recibos_conceptos VALUES (14983, 13, 4556.53, 749);
INSERT INTO public.recibos_conceptos VALUES (14986, 15, 59234.93, 749);
INSERT INTO public.recibos_conceptos VALUES (14987, 17, 6515.84, 749);
INSERT INTO public.recibos_conceptos VALUES (14988, 18, 1777.05, 749);
INSERT INTO public.recibos_conceptos VALUES (14989, 19, 1777.05, 749);
INSERT INTO public.recibos_conceptos VALUES (14990, 20, 1480.87, 749);
INSERT INTO public.recibos_conceptos VALUES (14991, 21, 11550.81, 749);
INSERT INTO public.recibos_conceptos VALUES (14992, 22, 47684.12, 749);
INSERT INTO public.recibos_conceptos VALUES (14993, 23, 47684.12, 749);
INSERT INTO public.recibos_conceptos VALUES (14994, 32, 2384.21, 749);
INSERT INTO public.recibos_conceptos VALUES (14995, 24, 34339.60, 749);
INSERT INTO public.recibos_conceptos VALUES (14996, 25, 6669.50, 749);
INSERT INTO public.recibos_conceptos VALUES (14997, 26, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (14999, 27, 7154.08, 749);
INSERT INTO public.recibos_conceptos VALUES (15000, 28, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15002, 31, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15003, 33, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15004, 34, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15005, 35, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15006, 36, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15007, 37, 48163.18, 749);
INSERT INTO public.recibos_conceptos VALUES (15008, 38, -479.06, 749);
INSERT INTO public.recibos_conceptos VALUES (15009, 40, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15010, 9, 1640.35, 749);
INSERT INTO public.recibos_conceptos VALUES (15011, 10, 1640.35, 749);
INSERT INTO public.recibos_conceptos VALUES (15012, 11, 13669.60, 749);
INSERT INTO public.recibos_conceptos VALUES (15013, 39, 0.00, 749);
INSERT INTO public.recibos_conceptos VALUES (15014, 1, 38158.50, 750);
INSERT INTO public.recibos_conceptos VALUES (15015, 7, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15016, 12, 3815.85, 750);
INSERT INTO public.recibos_conceptos VALUES (15017, 4, 38158.50, 750);
INSERT INTO public.recibos_conceptos VALUES (15018, 5, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15019, 6, 3052.68, 750);
INSERT INTO public.recibos_conceptos VALUES (15020, 13, 3752.25, 750);
INSERT INTO public.recibos_conceptos VALUES (15023, 15, 48779.28, 750);
INSERT INTO public.recibos_conceptos VALUES (15024, 17, 5365.72, 750);
INSERT INTO public.recibos_conceptos VALUES (15025, 18, 1463.38, 750);
INSERT INTO public.recibos_conceptos VALUES (15026, 19, 1463.38, 750);
INSERT INTO public.recibos_conceptos VALUES (15027, 20, 1219.48, 750);
INSERT INTO public.recibos_conceptos VALUES (15028, 21, 9511.96, 750);
INSERT INTO public.recibos_conceptos VALUES (15029, 22, 39267.32, 750);
INSERT INTO public.recibos_conceptos VALUES (15030, 23, 39267.32, 750);
INSERT INTO public.recibos_conceptos VALUES (15031, 32, 1963.37, 750);
INSERT INTO public.recibos_conceptos VALUES (15032, 24, 34339.60, 750);
INSERT INTO public.recibos_conceptos VALUES (15033, 25, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15034, 26, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15036, 27, 7154.08, 750);
INSERT INTO public.recibos_conceptos VALUES (15037, 28, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15039, 31, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15040, 33, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15041, 34, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15042, 35, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15043, 36, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15044, 37, 41493.68, 750);
INSERT INTO public.recibos_conceptos VALUES (15045, 38, -2226.36, 750);
INSERT INTO public.recibos_conceptos VALUES (15046, 40, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15047, 9, 1350.81, 750);
INSERT INTO public.recibos_conceptos VALUES (15048, 10, 1350.81, 750);
INSERT INTO public.recibos_conceptos VALUES (15049, 11, 11256.76, 750);
INSERT INTO public.recibos_conceptos VALUES (15050, 39, 0.00, 750);
INSERT INTO public.recibos_conceptos VALUES (15051, 1, 15764.70, 751);
INSERT INTO public.recibos_conceptos VALUES (15052, 7, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15053, 12, 1576.47, 751);
INSERT INTO public.recibos_conceptos VALUES (15054, 4, 15764.70, 751);
INSERT INTO public.recibos_conceptos VALUES (15055, 5, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15056, 6, 630.59, 751);
INSERT INTO public.recibos_conceptos VALUES (15057, 13, 1497.65, 751);
INSERT INTO public.recibos_conceptos VALUES (15060, 15, 19469.40, 751);
INSERT INTO public.recibos_conceptos VALUES (15061, 17, 2141.63, 751);
INSERT INTO public.recibos_conceptos VALUES (15062, 18, 584.08, 751);
INSERT INTO public.recibos_conceptos VALUES (15063, 19, 584.08, 751);
INSERT INTO public.recibos_conceptos VALUES (15064, 20, 486.74, 751);
INSERT INTO public.recibos_conceptos VALUES (15065, 21, 3796.53, 751);
INSERT INTO public.recibos_conceptos VALUES (15066, 22, 15672.87, 751);
INSERT INTO public.recibos_conceptos VALUES (15067, 23, 15672.87, 751);
INSERT INTO public.recibos_conceptos VALUES (15068, 32, 783.64, 751);
INSERT INTO public.recibos_conceptos VALUES (15069, 24, 34339.60, 751);
INSERT INTO public.recibos_conceptos VALUES (15070, 25, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15071, 26, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15073, 27, 7154.08, 751);
INSERT INTO public.recibos_conceptos VALUES (15074, 28, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15076, 31, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15077, 33, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15078, 34, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15079, 35, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15080, 36, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15081, 37, 41493.68, 751);
INSERT INTO public.recibos_conceptos VALUES (15082, 38, -25820.81, 751);
INSERT INTO public.recibos_conceptos VALUES (15083, 40, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15084, 9, 539.15, 751);
INSERT INTO public.recibos_conceptos VALUES (15085, 10, 539.15, 751);
INSERT INTO public.recibos_conceptos VALUES (15086, 11, 4492.94, 751);
INSERT INTO public.recibos_conceptos VALUES (15087, 39, 0.00, 751);
INSERT INTO public.recibos_conceptos VALUES (15088, 1, 39104.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15089, 7, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15090, 12, 3910.40, 752);
INSERT INTO public.recibos_conceptos VALUES (15091, 4, 39104.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15092, 5, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15093, 6, 8602.88, 752);
INSERT INTO public.recibos_conceptos VALUES (15094, 13, 4301.44, 752);
INSERT INTO public.recibos_conceptos VALUES (15097, 15, 55918.72, 752);
INSERT INTO public.recibos_conceptos VALUES (15098, 17, 6151.06, 752);
INSERT INTO public.recibos_conceptos VALUES (15099, 18, 1677.56, 752);
INSERT INTO public.recibos_conceptos VALUES (15100, 19, 1677.56, 752);
INSERT INTO public.recibos_conceptos VALUES (15101, 20, 1397.97, 752);
INSERT INTO public.recibos_conceptos VALUES (15102, 21, 10904.15, 752);
INSERT INTO public.recibos_conceptos VALUES (15103, 22, 45014.57, 752);
INSERT INTO public.recibos_conceptos VALUES (15104, 23, 45014.57, 752);
INSERT INTO public.recibos_conceptos VALUES (15105, 32, 2250.73, 752);
INSERT INTO public.recibos_conceptos VALUES (15106, 24, 34339.60, 752);
INSERT INTO public.recibos_conceptos VALUES (15107, 25, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15108, 26, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15110, 27, 7154.08, 752);
INSERT INTO public.recibos_conceptos VALUES (15111, 28, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15113, 31, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15114, 33, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15115, 34, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15116, 35, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15117, 36, 0.00, 752);
INSERT INTO public.recibos_conceptos VALUES (15118, 37, 41493.68, 752);
INSERT INTO public.recibos_conceptos VALUES (15119, 38, 3520.89, 752);
INSERT INTO public.recibos_conceptos VALUES (15120, 40, 7045.80, 752);
INSERT INTO public.recibos_conceptos VALUES (15121, 9, 1548.52, 752);
INSERT INTO public.recibos_conceptos VALUES (15122, 10, 1548.52, 752);
INSERT INTO public.recibos_conceptos VALUES (15123, 11, 12904.32, 752);
INSERT INTO public.recibos_conceptos VALUES (15124, 39, 7045.80, 752);
INSERT INTO public.recibos_conceptos VALUES (15125, 1, 45948.50, 753);
INSERT INTO public.recibos_conceptos VALUES (15126, 7, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15127, 12, 4594.85, 753);
INSERT INTO public.recibos_conceptos VALUES (15128, 4, 45948.50, 753);
INSERT INTO public.recibos_conceptos VALUES (15129, 5, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15130, 6, 29407.04, 753);
INSERT INTO public.recibos_conceptos VALUES (15131, 13, 6662.53, 753);
INSERT INTO public.recibos_conceptos VALUES (15134, 15, 86612.92, 753);
INSERT INTO public.recibos_conceptos VALUES (15135, 17, 9527.42, 753);
INSERT INTO public.recibos_conceptos VALUES (15136, 18, 2598.39, 753);
INSERT INTO public.recibos_conceptos VALUES (15137, 19, 2598.39, 753);
INSERT INTO public.recibos_conceptos VALUES (15138, 20, 2165.32, 753);
INSERT INTO public.recibos_conceptos VALUES (15139, 21, 16889.52, 753);
INSERT INTO public.recibos_conceptos VALUES (15140, 22, 69723.40, 753);
INSERT INTO public.recibos_conceptos VALUES (15141, 23, 69723.40, 753);
INSERT INTO public.recibos_conceptos VALUES (15142, 32, 3486.17, 753);
INSERT INTO public.recibos_conceptos VALUES (15143, 24, 34339.60, 753);
INSERT INTO public.recibos_conceptos VALUES (15144, 25, 6669.50, 753);
INSERT INTO public.recibos_conceptos VALUES (15145, 26, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15147, 27, 7154.08, 753);
INSERT INTO public.recibos_conceptos VALUES (15148, 28, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15150, 31, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15151, 33, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15152, 34, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15153, 35, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15154, 36, 0.00, 753);
INSERT INTO public.recibos_conceptos VALUES (15155, 37, 48163.18, 753);
INSERT INTO public.recibos_conceptos VALUES (15156, 38, 21560.22, 753);
INSERT INTO public.recibos_conceptos VALUES (15157, 40, 118102.54, 753);
INSERT INTO public.recibos_conceptos VALUES (15158, 9, 2398.51, 753);
INSERT INTO public.recibos_conceptos VALUES (15159, 10, 2398.51, 753);
INSERT INTO public.recibos_conceptos VALUES (15160, 11, 19987.60, 753);
INSERT INTO public.recibos_conceptos VALUES (15161, 39, 118102.54, 753);
INSERT INTO public.recibos_conceptos VALUES (15162, 1, 34958.80, 754);
INSERT INTO public.recibos_conceptos VALUES (15163, 7, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15164, 12, 3495.88, 754);
INSERT INTO public.recibos_conceptos VALUES (15165, 4, 34958.80, 754);
INSERT INTO public.recibos_conceptos VALUES (15166, 5, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15167, 6, 3495.88, 754);
INSERT INTO public.recibos_conceptos VALUES (15168, 13, 3495.88, 754);
INSERT INTO public.recibos_conceptos VALUES (15171, 15, 45446.44, 754);
INSERT INTO public.recibos_conceptos VALUES (15172, 17, 4999.11, 754);
INSERT INTO public.recibos_conceptos VALUES (15173, 18, 1363.39, 754);
INSERT INTO public.recibos_conceptos VALUES (15174, 19, 1363.39, 754);
INSERT INTO public.recibos_conceptos VALUES (15175, 20, 1136.16, 754);
INSERT INTO public.recibos_conceptos VALUES (15176, 21, 8862.06, 754);
INSERT INTO public.recibos_conceptos VALUES (15177, 22, 36584.38, 754);
INSERT INTO public.recibos_conceptos VALUES (15178, 23, 36584.38, 754);
INSERT INTO public.recibos_conceptos VALUES (15179, 32, 1829.22, 754);
INSERT INTO public.recibos_conceptos VALUES (15180, 24, 34339.60, 754);
INSERT INTO public.recibos_conceptos VALUES (15181, 25, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15182, 26, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15184, 27, 7154.08, 754);
INSERT INTO public.recibos_conceptos VALUES (15185, 28, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15187, 31, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15188, 33, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15189, 34, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15190, 35, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15191, 36, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15192, 37, 41493.68, 754);
INSERT INTO public.recibos_conceptos VALUES (15193, 38, -4909.30, 754);
INSERT INTO public.recibos_conceptos VALUES (15194, 40, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15195, 9, 1258.52, 754);
INSERT INTO public.recibos_conceptos VALUES (15196, 10, 1258.52, 754);
INSERT INTO public.recibos_conceptos VALUES (15197, 11, 10487.64, 754);
INSERT INTO public.recibos_conceptos VALUES (15198, 39, 0.00, 754);
INSERT INTO public.recibos_conceptos VALUES (15199, 1, 57061.70, 755);
INSERT INTO public.recibos_conceptos VALUES (15200, 7, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15201, 12, 5706.17, 755);
INSERT INTO public.recibos_conceptos VALUES (15202, 4, 57061.70, 755);
INSERT INTO public.recibos_conceptos VALUES (15203, 5, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15204, 6, 36519.49, 755);
INSERT INTO public.recibos_conceptos VALUES (15205, 13, 8273.95, 755);
INSERT INTO public.recibos_conceptos VALUES (15208, 15, 107561.30, 755);
INSERT INTO public.recibos_conceptos VALUES (15209, 17, 11831.74, 755);
INSERT INTO public.recibos_conceptos VALUES (15210, 18, 3226.84, 755);
INSERT INTO public.recibos_conceptos VALUES (15211, 19, 3226.84, 755);
INSERT INTO public.recibos_conceptos VALUES (15212, 20, 2689.03, 755);
INSERT INTO public.recibos_conceptos VALUES (15213, 21, 20974.45, 755);
INSERT INTO public.recibos_conceptos VALUES (15214, 22, 86586.85, 755);
INSERT INTO public.recibos_conceptos VALUES (15215, 23, 86586.85, 755);
INSERT INTO public.recibos_conceptos VALUES (15216, 32, 4329.34, 755);
INSERT INTO public.recibos_conceptos VALUES (15217, 24, 34339.60, 755);
INSERT INTO public.recibos_conceptos VALUES (15218, 25, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15219, 26, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15221, 27, 7154.08, 755);
INSERT INTO public.recibos_conceptos VALUES (15222, 28, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15224, 31, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15225, 33, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15226, 34, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15227, 35, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15228, 36, 0.00, 755);
INSERT INTO public.recibos_conceptos VALUES (15229, 37, 41493.68, 755);
INSERT INTO public.recibos_conceptos VALUES (15230, 38, 45093.17, 755);
INSERT INTO public.recibos_conceptos VALUES (15231, 40, 46232.49, 755);
INSERT INTO public.recibos_conceptos VALUES (15232, 9, 2978.62, 755);
INSERT INTO public.recibos_conceptos VALUES (15233, 10, 2978.62, 755);
INSERT INTO public.recibos_conceptos VALUES (15234, 11, 24821.84, 755);
INSERT INTO public.recibos_conceptos VALUES (15235, 39, 46232.49, 755);
INSERT INTO public.recibos_conceptos VALUES (15236, 1, 34892.86, 756);
INSERT INTO public.recibos_conceptos VALUES (15237, 7, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15238, 12, 3489.29, 756);
INSERT INTO public.recibos_conceptos VALUES (15239, 4, 34892.86, 756);
INSERT INTO public.recibos_conceptos VALUES (15240, 5, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15241, 6, 697.86, 756);
INSERT INTO public.recibos_conceptos VALUES (15242, 13, 3256.67, 756);
INSERT INTO public.recibos_conceptos VALUES (15245, 15, 42336.67, 756);
INSERT INTO public.recibos_conceptos VALUES (15246, 17, 4657.03, 756);
INSERT INTO public.recibos_conceptos VALUES (15247, 18, 1270.10, 756);
INSERT INTO public.recibos_conceptos VALUES (15248, 19, 1270.10, 756);
INSERT INTO public.recibos_conceptos VALUES (15249, 20, 1058.42, 756);
INSERT INTO public.recibos_conceptos VALUES (15250, 21, 8255.65, 756);
INSERT INTO public.recibos_conceptos VALUES (15251, 22, 34081.02, 756);
INSERT INTO public.recibos_conceptos VALUES (15252, 23, 34081.02, 756);
INSERT INTO public.recibos_conceptos VALUES (15253, 32, 1704.05, 756);
INSERT INTO public.recibos_conceptos VALUES (15254, 24, 34339.60, 756);
INSERT INTO public.recibos_conceptos VALUES (15255, 25, 6669.50, 756);
INSERT INTO public.recibos_conceptos VALUES (15256, 26, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15258, 27, 7154.08, 756);
INSERT INTO public.recibos_conceptos VALUES (15259, 28, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15261, 31, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15262, 33, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15263, 34, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15264, 35, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15265, 36, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15266, 37, 48163.18, 756);
INSERT INTO public.recibos_conceptos VALUES (15267, 38, -14082.16, 756);
INSERT INTO public.recibos_conceptos VALUES (15268, 40, 0.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15269, 9, 1172.40, 756);
INSERT INTO public.recibos_conceptos VALUES (15270, 10, 1172.40, 756);
INSERT INTO public.recibos_conceptos VALUES (15271, 11, 9770.00, 756);
INSERT INTO public.recibos_conceptos VALUES (15272, 39, 0.00, 756);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 15272, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 756, true);


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


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 43, true);


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


--
-- Name: reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.reservadas_id_seq', 19, true);


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
-- Name: uk_recibos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT uk_recibos_conceptos UNIQUE (id_concepto, id_recibo);


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

