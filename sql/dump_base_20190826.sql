--
-- PostgreSQL database dump
--

-- Dumped from database version 11.4 (Ubuntu 11.4-1.pgdg18.04+1)
-- Dumped by pg_dump version 11.4 (Ubuntu 11.4-1.pgdg18.04+1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
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
SET idle_in_transaction_session_timeout = 0;
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
    AS integer
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
    AS integer
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
    AS integer
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
    p.legajo
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
-- Name: acumuladores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores ALTER COLUMN id SET DEFAULT nextval('public.acumuladores_id_seq'::regclass);


--
-- Name: bancos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bancos ALTER COLUMN id SET DEFAULT nextval('public.bancos_id_seq'::regclass);


--
-- Name: categorias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);


--
-- Name: conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos ALTER COLUMN id SET DEFAULT nextval('public.conceptos_id_seq'::regclass);


--
-- Name: datos_actuales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales ALTER COLUMN id SET DEFAULT nextval('public.datos_actuales_id_seq'::regclass);


--
-- Name: datos_laborales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales ALTER COLUMN id SET DEFAULT nextval('public.datos_laborales_id_seq'::regclass);


--
-- Name: datos_salud id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud ALTER COLUMN id SET DEFAULT nextval('public.datos_salud_id_seq'::regclass);


--
-- Name: establecimientos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos ALTER COLUMN id SET DEFAULT nextval('public.establecimientos_id_seq'::regclass);


--
-- Name: estados_civiles id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_civiles ALTER COLUMN id SET DEFAULT nextval('public.estados_civiles_id_seq'::regclass);


--
-- Name: estados_liquidacion id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion ALTER COLUMN id SET DEFAULT nextval('public.estados_liquidacion_id_seq'::regclass);


--
-- Name: feriados id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feriados ALTER COLUMN id SET DEFAULT nextval('public.feriados_id_seq'::regclass);


--
-- Name: fichajes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes ALTER COLUMN id SET DEFAULT nextval('public.fichajes_id_seq'::regclass);


--
-- Name: generos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generos ALTER COLUMN id SET DEFAULT nextval('public.generos_id_seq'::regclass);


--
-- Name: liquidaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_id_seq'::regclass);


--
-- Name: liquidaciones_conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_conceptos_id_seq'::regclass);


--
-- Name: localidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades ALTER COLUMN id SET DEFAULT nextval('public.localidades_id_seq'::regclass);


--
-- Name: nacionalidades id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nacionalidades ALTER COLUMN id SET DEFAULT nextval('public.nacionalidades_id_seq'::regclass);


--
-- Name: obras_sociales id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obras_sociales ALTER COLUMN id SET DEFAULT nextval('public.obras_sociales_id_seq'::regclass);


--
-- Name: paises id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paises ALTER COLUMN id SET DEFAULT nextval('public.paises_id_seq'::regclass);


--
-- Name: periodos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos ALTER COLUMN id SET DEFAULT nextval('public.periodos_id_seq'::regclass);


--
-- Name: periodos_detalle id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle ALTER COLUMN id SET DEFAULT nextval('public.periodos_detalle_id_seq'::regclass);


--
-- Name: persona_tareas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas ALTER COLUMN id SET DEFAULT nextval('public.persona_tareas_id_seq'::regclass);


--
-- Name: personas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas ALTER COLUMN id SET DEFAULT nextval('public.personas_id_seq'::regclass);


--
-- Name: personas_conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos ALTER COLUMN id SET DEFAULT nextval('public.personas_conceptos_id_seq'::regclass);


--
-- Name: personas_jornadas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas ALTER COLUMN id SET DEFAULT nextval('public.personas_jornadas_id_seq'::regclass);


--
-- Name: provincias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias ALTER COLUMN id SET DEFAULT nextval('public.provincias_id_seq'::regclass);


--
-- Name: recibos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos ALTER COLUMN id SET DEFAULT nextval('public.recibos_id_seq'::regclass);


--
-- Name: recibos_acumuladores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores ALTER COLUMN id SET DEFAULT nextval('public.recibos_acumuladores_id_seq'::regclass);


--
-- Name: recibos_conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.recibos_conceptos_id_seq'::regclass);


--
-- Name: regimenes id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regimenes ALTER COLUMN id SET DEFAULT nextval('public.regimenes_id_seq'::regclass);


--
-- Name: tabla id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla ALTER COLUMN id SET DEFAULT nextval('public.tabla_id_seq'::regclass);


--
-- Name: tabla_detalle id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_detalle_id_seq'::regclass);


--
-- Name: tabla_ganancias id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_id_seq'::regclass);


--
-- Name: tabla_ganancias_detalle id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_detalle_id_seq'::regclass);


--
-- Name: tabla_personas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas ALTER COLUMN id SET DEFAULT nextval('public.tabla_personas_id_seq'::regclass);


--
-- Name: tareas id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas ALTER COLUMN id SET DEFAULT nextval('public.tareas_id_seq'::regclass);


--
-- Name: tipo_liquidacion_conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipo_liquidacion_conceptos_id_seq'::regclass);


--
-- Name: tipos_conceptos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipos_conceptos_id_seq'::regclass);


--
-- Name: tipos_contratos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_contratos ALTER COLUMN id SET DEFAULT nextval('public.tipos_contratos_id_seq'::regclass);


--
-- Name: tipos_documentos id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documentos ALTER COLUMN id SET DEFAULT nextval('public.tipos_documentos_id_seq'::regclass);


--
-- Name: tipos_empleadores id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_empleadores ALTER COLUMN id SET DEFAULT nextval('public.tipos_empleadores_id_seq'::regclass);


--
-- Name: tipos_liquidaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.tipos_liquidaciones_id_seq'::regclass);


--
-- Name: vacaciones id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones ALTER COLUMN id SET DEFAULT nextval('public.vacaciones_id_seq'::regclass);


--
-- Name: reservadas id; Type: DEFAULT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas ALTER COLUMN id SET DEFAULT nextval('sistema.reservadas_id_seq'::regclass);


--
-- Name: tipos_datos id; Type: DEFAULT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_datos ALTER COLUMN id SET DEFAULT nextval('sistema.tipos_datos_id_seq'::regclass);


--
-- Name: tipos_reservadas id; Type: DEFAULT; Schema: sistema; Owner: -
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
-- Data for Name: bancos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.bancos VALUES (1, 'Galicia');


--
-- Data for Name: categorias; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.categorias VALUES (1, '1RA.SUPERV', 50000.00, NULL, '1');
INSERT INTO public.categorias VALUES (2, '2DA.SUPERV', 40000.00, NULL, '2');
INSERT INTO public.categorias VALUES (3, '1RA.ADM', 60000.00, NULL, '3');
INSERT INTO public.categorias VALUES (4, '2DA.ADM', 50000.00, NULL, '4');
INSERT INTO public.categorias VALUES (5, 'Maestranza', 35000.00, NULL, '5');


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
INSERT INTO public.conceptos VALUES (23, 'Ganancia Neta Acumulada', '322', 4, NULL, false, false, false, NULL, NULL, false, false);


--
-- Data for Name: conceptos_personas; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: datos_actuales; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: datos_laborales; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: datos_salud; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: establecimientos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.establecimientos VALUES (1, 'Asociación Médica de Luján', 'Mariano Moreno 1460', 1, NULL, NULL, NULL);


--
-- Data for Name: estados_civiles; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.estados_civiles VALUES (1, 'Soltero/a');
INSERT INTO public.estados_civiles VALUES (2, 'Casado/a');
INSERT INTO public.estados_civiles VALUES (3, 'Divorciado/a');


--
-- Data for Name: estados_liquidacion; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.estados_liquidacion VALUES (1, 'PENDIENTE LIQUIDACION');
INSERT INTO public.estados_liquidacion VALUES (2, 'LIQUIDADA');


--
-- Data for Name: feriados; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: fichajes; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: generos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.generos VALUES (1, 'Masculino');
INSERT INTO public.generos VALUES (2, 'Femenino');


--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (31, 'Liquidacion Octubre', '2019-10-01', '2019-08-01', '2019-08-31', 1, 1, 1, '2019-08-31', 'Octubre', 'Lujan', '2019-08-31', 2, 10, 2019);


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


--
-- Data for Name: localidades; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.localidades VALUES (1, 'LUJAN', 3450, 7);


--
-- Data for Name: nacionalidades; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.nacionalidades VALUES (1, 'Argentino');


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
-- Data for Name: paises; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.paises VALUES (1, 'Argentina', 'Argentino');


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
-- Data for Name: persona_tareas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.persona_tareas VALUES (2, 2, 1);
INSERT INTO public.persona_tareas VALUES (3, 19, 1);


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
-- Data for Name: personas_jornadas; Type: TABLE DATA; Schema: public; Owner: -
--



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


--
-- Data for Name: regimenes; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.regimenes VALUES (1, 'Reparto');
INSERT INTO public.regimenes VALUES (2, 'Sipa');
INSERT INTO public.regimenes VALUES (3, 'Capitalización');


--
-- Data for Name: tabla; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla VALUES (3, 'deduccion_especial', 'Deducciones Especiales');


--
-- Data for Name: tabla_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tabla_detalle VALUES (2, 2019, 1, '2019-01-01', 34339.60, 0.00, 3);
INSERT INTO public.tabla_detalle VALUES (3, 2019, 2, '2019-02-01', 50000.00, 0.00, 3);


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
-- Data for Name: tabla_personas; Type: TABLE DATA; Schema: public; Owner: -
--



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
-- Data for Name: tipos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_conceptos VALUES (3, 'ASIGNACIONES F.', NULL, NULL);
INSERT INTO public.tipos_conceptos VALUES (1, 'HABERES', 1, 299);
INSERT INTO public.tipos_conceptos VALUES (4, 'CALCULO GANANCIAS', 300, 399);
INSERT INTO public.tipos_conceptos VALUES (2, 'DEDUCCIONES', 500, 599);


--
-- Data for Name: tipos_contratos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_contratos VALUES (1, 'a tiempo comp.', NULL);
INSERT INTO public.tipos_contratos VALUES (2, 'a tiempo parcial', NULL);


--
-- Data for Name: tipos_documentos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.tipos_documentos VALUES (1, 'DNI');
INSERT INTO public.tipos_documentos VALUES (2, 'CI');
INSERT INTO public.tipos_documentos VALUES (3, 'LE');
INSERT INTO public.tipos_documentos VALUES (4, 'LC');


--
-- Data for Name: tipos_empleadores; Type: TABLE DATA; Schema: public; Owner: -
--



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
-- Data for Name: vacaciones; Type: TABLE DATA; Schema: public; Owner: -
--



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


--
-- Data for Name: tipos_datos; Type: TABLE DATA; Schema: sistema; Owner: -
--

INSERT INTO sistema.tipos_datos VALUES (1, 'INTEGER');
INSERT INTO sistema.tipos_datos VALUES (2, 'BOOLEAN');
INSERT INTO sistema.tipos_datos VALUES (3, 'TEXT');
INSERT INTO sistema.tipos_datos VALUES (4, 'NUMERIC');


--
-- Data for Name: tipos_reservadas; Type: TABLE DATA; Schema: sistema; Owner: -
--

INSERT INTO sistema.tipos_reservadas VALUES (1, 'LIQUIDACION');
INSERT INTO sistema.tipos_reservadas VALUES (2, 'PERSONA');


--
-- Name: acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.acumuladores_id_seq', 5, true);


--
-- Name: bancos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.bancos_id_seq', 1, true);


--
-- Name: categorias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.categorias_id_seq', 5, false);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 23, true);


--
-- Name: datos_actuales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_actuales_id_seq', 1, true);


--
-- Name: datos_laborales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_laborales_id_seq', 1, true);


--
-- Name: datos_salud_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.datos_salud_id_seq', 1, true);


--
-- Name: establecimientos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.establecimientos_id_seq', 1, false);


--
-- Name: estados_civiles_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estados_civiles_id_seq', 1, false);


--
-- Name: estados_liquidacion_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.estados_liquidacion_id_seq', 1, false);


--
-- Name: feriados_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.feriados_id_seq', 1, false);


--
-- Name: fichajes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.fichajes_id_seq', 1, false);


--
-- Name: generos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.generos_id_seq', 1, false);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 101, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 31, true);


--
-- Name: localidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.localidades_id_seq', 1, true);


--
-- Name: nacionalidades_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.nacionalidades_id_seq', 1, false);


--
-- Name: obras_sociales_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.obras_sociales_id_seq', 1, false);


--
-- Name: paises_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.paises_id_seq', 1, true);


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_detalle_id_seq', 22, true);


--
-- Name: periodos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_id_seq', 3, true);


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.persona_tareas_id_seq', 3, true);


--
-- Name: personas_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_conceptos_id_seq', 1, true);


--
-- Name: personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_id_seq', 26, true);


--
-- Name: personas_jornadas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.personas_jornadas_id_seq', 1, false);


--
-- Name: provincias_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.provincias_id_seq', 24, true);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 160, true);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 1848, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 316, true);


--
-- Name: regimenes_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.regimenes_id_seq', 1, false);


--
-- Name: tabla_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_detalle_id_seq', 3, true);


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

SELECT pg_catalog.setval('public.tabla_id_seq', 3, true);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 1, false);


--
-- Name: tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tareas_id_seq', 1, false);


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 13, true);


--
-- Name: tipos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_conceptos_id_seq', 4, true);


--
-- Name: tipos_contratos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_contratos_id_seq', 1, false);


--
-- Name: tipos_documentos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_documentos_id_seq', 1, false);


--
-- Name: tipos_empleadores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_empleadores_id_seq', 1, false);


--
-- Name: tipos_liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipos_liquidaciones_id_seq', 6, true);


--
-- Name: vacaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.vacaciones_id_seq', 1, false);


--
-- Name: reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.reservadas_id_seq', 15, true);


--
-- Name: tipos_datos_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.tipos_datos_id_seq', 1, false);


--
-- Name: tipos_reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.tipos_reservadas_id_seq', 1, false);


--
-- Name: persona_tareas persona_tareas_id_persona_id_tarea_unique; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT persona_tareas_id_persona_id_tarea_unique UNIQUE (id_persona, id_tarea);


--
-- Name: acumuladores pk_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT pk_acumuladores PRIMARY KEY (id);


--
-- Name: bancos pk_bancos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.bancos
    ADD CONSTRAINT pk_bancos PRIMARY KEY (id);


--
-- Name: categorias pk_categorias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT pk_categorias PRIMARY KEY (id);


--
-- Name: conceptos pk_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT pk_conceptos PRIMARY KEY (id);


--
-- Name: conceptos_personas pk_conceptos_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT pk_conceptos_personas PRIMARY KEY (id);


--
-- Name: datos_actuales pk_datos_actuales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT pk_datos_actuales PRIMARY KEY (id);


--
-- Name: datos_laborales pk_datos_laborales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT pk_datos_laborales PRIMARY KEY (id);


--
-- Name: datos_salud pk_datos_salud; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT pk_datos_salud PRIMARY KEY (id);


--
-- Name: establecimientos pk_establecimientos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT pk_establecimientos PRIMARY KEY (id);


--
-- Name: estados_civiles pk_estados_civiles; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_civiles
    ADD CONSTRAINT pk_estados_civiles PRIMARY KEY (id);


--
-- Name: estados_liquidacion pk_estados_liquidacion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT pk_estados_liquidacion PRIMARY KEY (id);


--
-- Name: feriados pk_feriados; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.feriados
    ADD CONSTRAINT pk_feriados PRIMARY KEY (id);


--
-- Name: fichajes pk_fichajes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT pk_fichajes PRIMARY KEY (id);


--
-- Name: generos pk_generos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.generos
    ADD CONSTRAINT pk_generos PRIMARY KEY (id);


--
-- Name: tipos_liquidaciones pk_liquidaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_liquidaciones
    ADD CONSTRAINT pk_liquidaciones PRIMARY KEY (id);


--
-- Name: liquidaciones pk_liquidaciones2; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT pk_liquidaciones2 PRIMARY KEY (id);


--
-- Name: liquidaciones_conceptos pk_liquidaciones_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT pk_liquidaciones_conceptos PRIMARY KEY (id);


--
-- Name: localidades pk_localidad; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT pk_localidad PRIMARY KEY (id);


--
-- Name: nacionalidades pk_nacionalidades; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.nacionalidades
    ADD CONSTRAINT pk_nacionalidades PRIMARY KEY (id);


--
-- Name: obras_sociales pk_obras_sociales; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.obras_sociales
    ADD CONSTRAINT pk_obras_sociales PRIMARY KEY (id);


--
-- Name: paises pk_paises; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (id);


--
-- Name: periodos_detalle pk_periodo_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT pk_periodo_detalle PRIMARY KEY (id);


--
-- Name: periodos pk_periodos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT pk_periodos PRIMARY KEY (id);


--
-- Name: persona_tareas pk_persona_tareas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT pk_persona_tareas PRIMARY KEY (id);


--
-- Name: personas pk_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT pk_personas PRIMARY KEY (id);


--
-- Name: personas_conceptos pk_personas_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT pk_personas_conceptos PRIMARY KEY (id);


--
-- Name: personas_jornadas pk_personas_jornadas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT pk_personas_jornadas PRIMARY KEY (id);


--
-- Name: provincias pk_provincias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT pk_provincias PRIMARY KEY (id);


--
-- Name: recibos pk_recibos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT pk_recibos PRIMARY KEY (id);


--
-- Name: recibos_acumuladores pk_recibos_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT pk_recibos_acumuladores PRIMARY KEY (id);


--
-- Name: recibos_conceptos pk_recibos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos PRIMARY KEY (id);


--
-- Name: regimenes pk_regimenes; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.regimenes
    ADD CONSTRAINT pk_regimenes PRIMARY KEY (id);


--
-- Name: tabla pk_tabla; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla
    ADD CONSTRAINT pk_tabla PRIMARY KEY (id);


--
-- Name: tabla_detalle pk_tabla_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT pk_tabla_detalle PRIMARY KEY (id);


--
-- Name: tabla_ganancias pk_tabla_ganancias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id);


--
-- Name: tabla_ganancias_detalle pk_tabla_ganancias_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT pk_tabla_ganancias_detalle PRIMARY KEY (id);


--
-- Name: tabla_personas pk_tabla_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT pk_tabla_personas PRIMARY KEY (id);


--
-- Name: tabla_vacaciones pk_tabla_vacaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_vacaciones
    ADD CONSTRAINT pk_tabla_vacaciones PRIMARY KEY (id);


--
-- Name: tabla_vacaciones_dias pk_tabla_vacaciones_dias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_vacaciones_dias
    ADD CONSTRAINT pk_tabla_vacaciones_dias PRIMARY KEY (id);


--
-- Name: tareas pk_tareas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT pk_tareas PRIMARY KEY (id);


--
-- Name: tipo_liquidacion_conceptos pk_tipo_liquidacion_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT pk_tipo_liquidacion_conceptos PRIMARY KEY (id);


--
-- Name: tipos_conceptos pk_tipos_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_conceptos
    ADD CONSTRAINT pk_tipos_conceptos PRIMARY KEY (id);


--
-- Name: tipos_documentos pk_tipos_documentos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_documentos
    ADD CONSTRAINT pk_tipos_documentos PRIMARY KEY (id);


--
-- Name: tipos_empleadores pk_tipos_empleadores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_empleadores
    ADD CONSTRAINT pk_tipos_empleadores PRIMARY KEY (id);


--
-- Name: vacaciones pk_vacaciones; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT pk_vacaciones PRIMARY KEY (id);


--
-- Name: tipos_contratos tipos_contratos_pkey; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipos_contratos
    ADD CONSTRAINT tipos_contratos_pkey PRIMARY KEY (id);


--
-- Name: conceptos uk_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT uk_conceptos UNIQUE (codigo);


--
-- Name: conceptos_personas uk_conceptos_personas; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT uk_conceptos_personas UNIQUE (id_concepto, id_persona);


--
-- Name: estados_liquidacion uk_estados_liquidacion; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT uk_estados_liquidacion UNIQUE (descripcion);


--
-- Name: periodos uk_periodos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT uk_periodos UNIQUE (periodo);


--
-- Name: personas_conceptos uk_personas_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT uk_personas_conceptos UNIQUE (id_persona, id_concepto);


--
-- Name: personas uk_personas_dni; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT uk_personas_dni UNIQUE (id_tipo_documento, nro_documento);


--
-- Name: recibos_acumuladores uk_recibos_acumuladores; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladores UNIQUE (id_recibo, id_acumulador);


--
-- Name: tabla_ganancias uk_tabla_ganancias; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT uk_tabla_ganancias UNIQUE (anio);


--
-- Name: tipo_liquidacion_conceptos uk_tipo_liquidacion_conceptos; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT uk_tipo_liquidacion_conceptos UNIQUE (id_concepto, id_tipo_liquidacion);


--
-- Name: reservadas pk_reservadas; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT pk_reservadas PRIMARY KEY (id);


--
-- Name: tipos_datos pk_tipos_datos; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_datos
    ADD CONSTRAINT pk_tipos_datos PRIMARY KEY (id);


--
-- Name: tipos_reservadas pk_tipos_reservadas; Type: CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.tipos_reservadas
    ADD CONSTRAINT pk_tipos_reservadas PRIMARY KEY (id);


--
-- Name: recibos trg_ai_recibos; Type: TRIGGER; Schema: public; Owner: -
--

CREATE TRIGGER trg_ai_recibos AFTER INSERT ON public.recibos FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_ai_recibos();


--
-- Name: conceptos conceptos_id_tipo_concepto_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT conceptos_id_tipo_concepto_foreign FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);


--
-- Name: establecimientos establecimientos_id_localidad_foreign; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT establecimientos_id_localidad_foreign FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);


--
-- Name: acumuladores fk_acumuladores__tipo_concepto; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT fk_acumuladores__tipo_concepto FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);


--
-- Name: conceptos_personas fk_conceptos_personas__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: conceptos_personas fk_conceptos_personas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: datos_actuales fk_datos_actuales__estado_civil; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__estado_civil FOREIGN KEY (id_estado_civil) REFERENCES public.estados_civiles(id);


--
-- Name: datos_actuales fk_datos_actuales__peresona; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__peresona FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: datos_actuales fk_datos_actuales_localidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales_localidades FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);


--
-- Name: datos_laborales fk_datos_laborales__categorias; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__categorias FOREIGN KEY (id_categoria) REFERENCES public.categorias(id);


--
-- Name: datos_laborales fk_datos_laborales__establecimiento; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__establecimiento FOREIGN KEY (id_establecimiento) REFERENCES public.establecimientos(id);


--
-- Name: datos_laborales fk_datos_laborales__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: datos_laborales fk_datos_laborales__tipos_contratos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__tipos_contratos FOREIGN KEY (id_tipo_contrato) REFERENCES public.tipos_contratos(id);


--
-- Name: datos_salud fk_datos_salud__obra_social; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__obra_social FOREIGN KEY (id_obra_social) REFERENCES public.obras_sociales(id);


--
-- Name: datos_salud fk_datos_salud__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: establecimientos fk_establecimientos__tipo_empleador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT fk_establecimientos__tipo_empleador FOREIGN KEY (id_tipo_empleador) REFERENCES public.tipos_empleadores(id);


--
-- Name: fichajes fk_fichajes__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT fk_fichajes__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: liquidaciones fk_liquidacion__estado; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidacion__estado FOREIGN KEY (id_estado) REFERENCES public.estados_liquidacion(id);


--
-- Name: liquidaciones fk_liquidaciones__bancos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__bancos FOREIGN KEY (id_banco) REFERENCES public.bancos(id);


--
-- Name: liquidaciones fk_liquidaciones__tipos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__tipos FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);


--
-- Name: liquidaciones_conceptos fk_liquidaciones_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: liquidaciones_conceptos fk_liquidaciones_conceptos__liquidaciones; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);


--
-- Name: localidades fk_localidad_provincia; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT fk_localidad_provincia FOREIGN KEY (id_provincia) REFERENCES public.provincias(id);


--
-- Name: periodos_detalle fk_periodo_detalle__periodo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__periodo FOREIGN KEY (id_periodo) REFERENCES public.periodos(id);


--
-- Name: periodos_detalle fk_periodo_detalle__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: personas fk_persona__nacionalidades; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_persona__nacionalidades FOREIGN KEY (id_nacionalidad) REFERENCES public.nacionalidades(id);


--
-- Name: personas fk_personas__generos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_personas__generos FOREIGN KEY (id_genero) REFERENCES public.generos(id);


--
-- Name: personas_conceptos fk_personas_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: personas_conceptos fk_personas_conceptos__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: personas_jornadas fk_personas_jornadas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT fk_personas_jornadas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: persona_tareas fk_personas_tareas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT fk_personas_tareas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: provincias fk_provincias_pais; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT fk_provincias_pais FOREIGN KEY (id_pais) REFERENCES public.paises(id);


--
-- Name: recibos fk_recibos__liquidaciones; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);


--
-- Name: recibos fk_recibos__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: recibos_acumuladores fk_recibos_acumuladores__acumulador; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__acumulador FOREIGN KEY (id_acumulador) REFERENCES public.acumuladores(id);


--
-- Name: recibos_acumuladores fk_recibos_acumuladores__recibo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id);


--
-- Name: recibos_conceptos fk_recibos_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: recibos_conceptos fk_recibos_conceptos__recibo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id);


--
-- Name: tabla_detalle fk_tabla_detalle__tabla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT fk_tabla_detalle__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);


--
-- Name: tabla_ganancias_detalle fk_tabla_ganancias_detalle__cabecera; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT fk_tabla_ganancias_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES public.tabla_ganancias(id);


--
-- Name: tabla_personas fk_tabla_personas__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: tabla_personas fk_tabla_personas__tabla; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);


--
-- Name: tipo_liquidacion_conceptos fk_tipo_liquidacion_conceptos__conceptos; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);


--
-- Name: tipo_liquidacion_conceptos fk_tipo_liquidacion_conceptos__tipo; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__tipo FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);


--
-- Name: vacaciones fk_vacaciones__personas; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT fk_vacaciones__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);


--
-- Name: reservadas fk_reservadas__tipos_datos; Type: FK CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_reservadas__tipos_datos FOREIGN KEY (id_tipo_dato) REFERENCES sistema.tipos_datos(id);


--
-- Name: reservadas fk_tipos_reservadas__reservadas; Type: FK CONSTRAINT; Schema: sistema; Owner: -
--

ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_tipos_reservadas__reservadas FOREIGN KEY (id_tipo_reservada) REFERENCES sistema.tipos_reservadas(id);


--
-- PostgreSQL database dump complete
--

