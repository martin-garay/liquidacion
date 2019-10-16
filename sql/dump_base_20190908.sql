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
-- Name: fu_numero_letras(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.fu_numero_letras(numero numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	/* Fuente: https://wiki.postgresql.org/wiki/Numeros_a_letras */
     lnEntero INTEGER;
     lcRetorno TEXT;
     lnTerna INTEGER;
     lcMiles TEXT;
     lcCadena TEXT;
     lnUnidades INTEGER;
     lnDecenas INTEGER;
     lnCentenas INTEGER;
     lnFraccion INTEGER;
     lnSw INTEGER;
BEGIN
     lnEntero := FLOOR(numero)::INTEGER;--Obtenemos la parte Entera
     lnFraccion := FLOOR(((numero - lnEntero) * 100))::INTEGER;--Obtenemos la Fraccion del Monto
     lcRetorno := '';
     lnTerna := 1;
     IF lnEntero > 0 THEN
     lnSw := LENGTH(lnEntero);
     WHILE lnTerna <= lnSw LOOP
        -- Recorro terna por terna
        lcCadena = '';
        lnUnidades = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnDecenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnCentenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
    -- Analizo las unidades
       SELECT
         CASE /* UNIDADES */
           WHEN lnUnidades = 1 AND lnTerna = 1 THEN 'UNO ' || lcCadena
           WHEN lnUnidades = 1 AND lnTerna <> 1 THEN 'UN ' || lcCadena
           WHEN lnUnidades = 2 THEN 'DOS ' || lcCadena
           WHEN lnUnidades = 3 THEN 'TRES ' || lcCadena
           WHEN lnUnidades = 4 THEN 'CUATRO ' || lcCadena
           WHEN lnUnidades = 5 THEN 'CINCO ' || lcCadena
           WHEN lnUnidades = 6 THEN 'SEIS ' || lcCadena
           WHEN lnUnidades = 7 THEN 'SIETE ' || lcCadena
           WHEN lnUnidades = 8 THEN 'OCHO ' || lcCadena
           WHEN lnUnidades = 9 THEN 'NUEVE ' || lcCadena
           ELSE lcCadena
          END INTO lcCadena;
          /* UNIDADES */
    -- Analizo las decenas
    SELECT
    CASE /* DECENAS */
      WHEN lnDecenas = 1 THEN
        CASE lnUnidades
          WHEN 0 THEN 'DIEZ '
          WHEN 1 THEN 'ONCE '
          WHEN 2 THEN 'DOCE '
          WHEN 3 THEN 'TRECE '
          WHEN 4 THEN 'CATORCE '
          WHEN 5 THEN 'QUINCE '
          ELSE 'DIECI' || lcCadena
        END
      WHEN lnDecenas = 2 AND lnUnidades = 0 THEN 'VEINTE ' || lcCadena
      WHEN lnDecenas = 2 AND lnUnidades <> 0 THEN 'VEINTI' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades = 0 THEN 'TREINTA ' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades <> 0 THEN 'TREINTA Y ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades = 0 THEN 'CUARENTA ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades <> 0 THEN 'CUARENTA Y ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades = 0 THEN 'CINCUENTA ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades <> 0 THEN 'CINCUENTA Y ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades = 0 THEN 'SESENTA ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades <> 0 THEN 'SESENTA Y ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades = 0 THEN 'SETENTA ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades <> 0 THEN 'SETENTA Y ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades = 0 THEN 'OCHENTA ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades <> 0 THEN 'OCHENTA Y ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades = 0 THEN 'NOVENTA ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades <> 0 THEN 'NOVENTA Y ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena; /* DECENAS */
    -- Analizo las centenas
    SELECT
    CASE /* CENTENAS */
      WHEN lnCentenas = 1 AND lnUnidades = 0 AND lnDecenas = 0 THEN 'CIEN ' || lcCadena
      WHEN lnCentenas = 1 AND NOT(lnUnidades = 0 AND lnDecenas = 0) THEN 'CIENTO ' || lcCadena
      WHEN lnCentenas = 2 THEN 'DOSCIENTOS ' || lcCadena
      WHEN lnCentenas = 3 THEN 'TRESCIENTOS ' || lcCadena
      WHEN lnCentenas = 4 THEN 'CUATROCIENTOS ' || lcCadena
      WHEN lnCentenas = 5 THEN 'QUINIENTOS ' || lcCadena
      WHEN lnCentenas = 6 THEN 'SEISCIENTOS ' || lcCadena
      WHEN lnCentenas = 7 THEN 'SETECIENTOS ' || lcCadena
      WHEN lnCentenas = 8 THEN 'OCHOCIENTOS ' || lcCadena
      WHEN lnCentenas = 9 THEN 'NOVECIENTOS ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena;/* CENTENAS */
    -- Analizo la terna
    SELECT
    CASE /* TERNA */
      WHEN lnTerna = 1 THEN lcCadena
      WHEN lnTerna = 2 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0 THEN lcCadena || ' MILLON '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        NOT (lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0) THEN lcCadena || ' MILLONES '
      WHEN lnTerna = 4 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL MILLONES '
      ELSE ''
    END INTO lcCadena;/* TERNA */
 
    --Retornamos los Valores Obtenidos
    lcRetorno = lcCadena  || lcRetorno;
    lnTerna = lnTerna + 1;
    END LOOP;
  END IF;
  IF lnTerna = 1 THEN
    lcRetorno := 'CERO';
  END IF;
  lcRetorno := RTRIM(lcRetorno) || ' CON ' || LTRIM(lnFraccion) || '/100 NUEVOS SOLES';
RETURN lcRetorno;
END;
$$;


--
-- Name: FUNCTION fu_numero_letras(numero numeric); Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON FUNCTION public.fu_numero_letras(numero numeric) IS 'Funcion para Convertir el Monto Numerico a Letras';


--
-- Name: numero_a_letras(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.numero_a_letras(numero numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
     lnEntero INTEGER;
     lcRetorno TEXT;
     lnTerna INTEGER;
     lcMiles TEXT;
     lcCadena TEXT;
     lnUnidades INTEGER;
     lnDecenas INTEGER;
     lnCentenas INTEGER;
     lnFraccion INTEGER;
     lnSw INTEGER;
BEGIN
     lnEntero := FLOOR(numero)::INTEGER;--Obtenemos la parte Entera
     lnFraccion := FLOOR(((numero - lnEntero) * 100))::INTEGER;--Obtenemos la Fraccion del Monto
     lcRetorno := '';
     lnTerna := 1;
     IF lnEntero > 0 THEN
     lnSw := LENGTH(lnEntero::text);
     WHILE lnTerna <= lnSw LOOP
        -- Recorro terna por terna
        lcCadena = '';
        lnUnidades = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnDecenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnCentenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
    -- Analizo las unidades
       SELECT
         CASE /* UNIDADES */
           WHEN lnUnidades = 1 AND lnTerna = 1 THEN 'UNO ' || lcCadena
           WHEN lnUnidades = 1 AND lnTerna <> 1 THEN 'UN ' || lcCadena
           WHEN lnUnidades = 2 THEN 'DOS ' || lcCadena
           WHEN lnUnidades = 3 THEN 'TRES ' || lcCadena
           WHEN lnUnidades = 4 THEN 'CUATRO ' || lcCadena
           WHEN lnUnidades = 5 THEN 'CINCO ' || lcCadena
           WHEN lnUnidades = 6 THEN 'SEIS ' || lcCadena
           WHEN lnUnidades = 7 THEN 'SIETE ' || lcCadena
           WHEN lnUnidades = 8 THEN 'OCHO ' || lcCadena
           WHEN lnUnidades = 9 THEN 'NUEVE ' || lcCadena
           ELSE lcCadena
          END INTO lcCadena;
          /* UNIDADES */
    -- Analizo las decenas
    SELECT
    CASE /* DECENAS */
      WHEN lnDecenas = 1 THEN
        CASE lnUnidades
          WHEN 0 THEN 'DIEZ '
          WHEN 1 THEN 'ONCE '
          WHEN 2 THEN 'DOCE '
          WHEN 3 THEN 'TRECE '
          WHEN 4 THEN 'CATORCE '
          WHEN 5 THEN 'QUINCE '
          ELSE 'DIECI' || lcCadena
        END
      WHEN lnDecenas = 2 AND lnUnidades = 0 THEN 'VEINTE ' || lcCadena
      WHEN lnDecenas = 2 AND lnUnidades <> 0 THEN 'VEINTI' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades = 0 THEN 'TREINTA ' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades <> 0 THEN 'TREINTA Y ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades = 0 THEN 'CUARENTA ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades <> 0 THEN 'CUARENTA Y ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades = 0 THEN 'CINCUENTA ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades <> 0 THEN 'CINCUENTA Y ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades = 0 THEN 'SESENTA ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades <> 0 THEN 'SESENTA Y ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades = 0 THEN 'SETENTA ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades <> 0 THEN 'SETENTA Y ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades = 0 THEN 'OCHENTA ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades <> 0 THEN 'OCHENTA Y ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades = 0 THEN 'NOVENTA ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades <> 0 THEN 'NOVENTA Y ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena; /* DECENAS */
    -- Analizo las centenas
    SELECT
    CASE /* CENTENAS */
      WHEN lnCentenas = 1 AND lnUnidades = 0 AND lnDecenas = 0 THEN 'CIEN ' || lcCadena
      WHEN lnCentenas = 1 AND NOT(lnUnidades = 0 AND lnDecenas = 0) THEN 'CIENTO ' || lcCadena
      WHEN lnCentenas = 2 THEN 'DOSCIENTOS ' || lcCadena
      WHEN lnCentenas = 3 THEN 'TRESCIENTOS ' || lcCadena
      WHEN lnCentenas = 4 THEN 'CUATROCIENTOS ' || lcCadena
      WHEN lnCentenas = 5 THEN 'QUINIENTOS ' || lcCadena
      WHEN lnCentenas = 6 THEN 'SEISCIENTOS ' || lcCadena
      WHEN lnCentenas = 7 THEN 'SETECIENTOS ' || lcCadena
      WHEN lnCentenas = 8 THEN 'OCHOCIENTOS ' || lcCadena
      WHEN lnCentenas = 9 THEN 'NOVECIENTOS ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena;/* CENTENAS */
    -- Analizo la terna
    SELECT
    CASE /* TERNA */
      WHEN lnTerna = 1 THEN lcCadena
      WHEN lnTerna = 2 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0 THEN lcCadena || ' MILLON '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        NOT (lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0) THEN lcCadena || ' MILLONES '
      WHEN lnTerna = 4 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL MILLONES '
      ELSE ''
    END INTO lcCadena;/* TERNA */
 
    --Retornamos los Valores Obtenidos
    lcRetorno = lcCadena  || lcRetorno;
    lnTerna = lnTerna + 1;
    END LOOP;
  END IF;
  IF lnTerna = 1 THEN
    lcRetorno := 'CERO';
  END IF;

	/* ARMO LOS CENTAVOS */
	lcCadena = '';
        lnUnidades = lnFraccion % 10;
        lnEntero = CAST(lnFraccion/10 AS INTEGER);
        lnDecenas = lnEntero % 10;
	
	-- Analizo las unidades
	SELECT
         CASE /* UNIDADES */
           --WHEN lnUnidades = 1 AND lnTerna = 1 THEN 'UNO ' || lcCadena
           --WHEN lnUnidades = 1 AND lnTerna <> 1 THEN 'UN ' || lcCadena
           WHEN lnUnidades = 1 THEN 'UNO ' || lcCadena
           WHEN lnUnidades = 2 THEN 'DOS ' || lcCadena
           WHEN lnUnidades = 3 THEN 'TRES ' || lcCadena
           WHEN lnUnidades = 4 THEN 'CUATRO ' || lcCadena
           WHEN lnUnidades = 5 THEN 'CINCO ' || lcCadena
           WHEN lnUnidades = 6 THEN 'SEIS ' || lcCadena
           WHEN lnUnidades = 7 THEN 'SIETE ' || lcCadena
           WHEN lnUnidades = 8 THEN 'OCHO ' || lcCadena
           WHEN lnUnidades = 9 THEN 'NUEVE ' || lcCadena
           ELSE lcCadena
          END INTO lcCadena;
          /* UNIDADES */
	-- Analizo las decenas
	SELECT
	CASE /* DECENAS */
	WHEN lnDecenas = 1 THEN
	CASE lnUnidades
	  WHEN 0 THEN 'DIEZ '
	  WHEN 1 THEN 'ONCE '
	  WHEN 2 THEN 'DOCE '
	  WHEN 3 THEN 'TRECE '
	  WHEN 4 THEN 'CATORCE '
	  WHEN 5 THEN 'QUINCE '
	  ELSE 'DIECI' || lcCadena
	END
	WHEN lnDecenas = 2 AND lnUnidades = 0 THEN 'VEINTE ' || lcCadena
	WHEN lnDecenas = 2 AND lnUnidades <> 0 THEN 'VEINTI' || lcCadena
	WHEN lnDecenas = 3 AND lnUnidades = 0 THEN 'TREINTA ' || lcCadena
	WHEN lnDecenas = 3 AND lnUnidades <> 0 THEN 'TREINTA Y ' || lcCadena
	WHEN lnDecenas = 4 AND lnUnidades = 0 THEN 'CUARENTA ' || lcCadena
	WHEN lnDecenas = 4 AND lnUnidades <> 0 THEN 'CUARENTA Y ' || lcCadena
	WHEN lnDecenas = 5 AND lnUnidades = 0 THEN 'CINCUENTA ' || lcCadena
	WHEN lnDecenas = 5 AND lnUnidades <> 0 THEN 'CINCUENTA Y ' || lcCadena
	WHEN lnDecenas = 6 AND lnUnidades = 0 THEN 'SESENTA ' || lcCadena
	WHEN lnDecenas = 6 AND lnUnidades <> 0 THEN 'SESENTA Y ' || lcCadena
	WHEN lnDecenas = 7 AND lnUnidades = 0 THEN 'SETENTA ' || lcCadena
	WHEN lnDecenas = 7 AND lnUnidades <> 0 THEN 'SETENTA Y ' || lcCadena
	WHEN lnDecenas = 8 AND lnUnidades = 0 THEN 'OCHENTA ' || lcCadena
	WHEN lnDecenas = 8 AND lnUnidades <> 0 THEN 'OCHENTA Y ' || lcCadena
	WHEN lnDecenas = 9 AND lnUnidades = 0 THEN 'NOVENTA ' || lcCadena
	WHEN lnDecenas = 9 AND lnUnidades <> 0 THEN 'NOVENTA Y ' || lcCadena
	ELSE lcCadena
	END INTO lcCadena; /* DECENAS */
  
  --lcRetorno := RTRIM(lcRetorno::text) || (CASE WHEN (LTRIM(lnFraccion::text))::int > 0 THEN ' CON '|| LTRIM(lnFraccion::text) ||' CENTAVOS' ELSE '' END)::text;
  lcRetorno := RTRIM(lcRetorno::text) ||' CON '||lcCadena;
RETURN lcRetorno;
END;
$$;


--
-- Name: numero_a_letras_back(numeric); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.numero_a_letras_back(numero numeric) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
     lnEntero INTEGER;
     lcRetorno TEXT;
     lnTerna INTEGER;
     lcMiles TEXT;
     lcCadena TEXT;
     lnUnidades INTEGER;
     lnDecenas INTEGER;
     lnCentenas INTEGER;
     lnFraccion INTEGER;
     lnSw INTEGER;
BEGIN
     lnEntero := FLOOR(numero)::INTEGER;--Obtenemos la parte Entera
     lnFraccion := FLOOR(((numero - lnEntero) * 100))::INTEGER;--Obtenemos la Fraccion del Monto
     lcRetorno := '';
     lnTerna := 1;
     IF lnEntero > 0 THEN
     lnSw := LENGTH(lnEntero::text);
     WHILE lnTerna <= lnSw LOOP
        -- Recorro terna por terna
        lcCadena = '';
        lnUnidades = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnDecenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
        lnCentenas = lnEntero % 10;
        lnEntero = CAST(lnEntero/10 AS INTEGER);
    -- Analizo las unidades
       SELECT
         CASE /* UNIDADES */
           WHEN lnUnidades = 1 AND lnTerna = 1 THEN 'UNO ' || lcCadena
           WHEN lnUnidades = 1 AND lnTerna <> 1 THEN 'UN ' || lcCadena
           WHEN lnUnidades = 2 THEN 'DOS ' || lcCadena
           WHEN lnUnidades = 3 THEN 'TRES ' || lcCadena
           WHEN lnUnidades = 4 THEN 'CUATRO ' || lcCadena
           WHEN lnUnidades = 5 THEN 'CINCO ' || lcCadena
           WHEN lnUnidades = 6 THEN 'SEIS ' || lcCadena
           WHEN lnUnidades = 7 THEN 'SIETE ' || lcCadena
           WHEN lnUnidades = 8 THEN 'OCHO ' || lcCadena
           WHEN lnUnidades = 9 THEN 'NUEVE ' || lcCadena
           ELSE lcCadena
          END INTO lcCadena;
          /* UNIDADES */
    -- Analizo las decenas
    SELECT
    CASE /* DECENAS */
      WHEN lnDecenas = 1 THEN
        CASE lnUnidades
          WHEN 0 THEN 'DIEZ '
          WHEN 1 THEN 'ONCE '
          WHEN 2 THEN 'DOCE '
          WHEN 3 THEN 'TRECE '
          WHEN 4 THEN 'CATORCE '
          WHEN 5 THEN 'QUINCE '
          ELSE 'DIECI' || lcCadena
        END
      WHEN lnDecenas = 2 AND lnUnidades = 0 THEN 'VEINTE ' || lcCadena
      WHEN lnDecenas = 2 AND lnUnidades <> 0 THEN 'VEINTI' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades = 0 THEN 'TREINTA ' || lcCadena
      WHEN lnDecenas = 3 AND lnUnidades <> 0 THEN 'TREINTA Y ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades = 0 THEN 'CUARENTA ' || lcCadena
      WHEN lnDecenas = 4 AND lnUnidades <> 0 THEN 'CUARENTA Y ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades = 0 THEN 'CINCUENTA ' || lcCadena
      WHEN lnDecenas = 5 AND lnUnidades <> 0 THEN 'CINCUENTA Y ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades = 0 THEN 'SESENTA ' || lcCadena
      WHEN lnDecenas = 6 AND lnUnidades <> 0 THEN 'SESENTA Y ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades = 0 THEN 'SETENTA ' || lcCadena
      WHEN lnDecenas = 7 AND lnUnidades <> 0 THEN 'SETENTA Y ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades = 0 THEN 'OCHENTA ' || lcCadena
      WHEN lnDecenas = 8 AND lnUnidades <> 0 THEN 'OCHENTA Y ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades = 0 THEN 'NOVENTA ' || lcCadena
      WHEN lnDecenas = 9 AND lnUnidades <> 0 THEN 'NOVENTA Y ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena; /* DECENAS */
    -- Analizo las centenas
    SELECT
    CASE /* CENTENAS */
      WHEN lnCentenas = 1 AND lnUnidades = 0 AND lnDecenas = 0 THEN 'CIEN ' || lcCadena
      WHEN lnCentenas = 1 AND NOT(lnUnidades = 0 AND lnDecenas = 0) THEN 'CIENTO ' || lcCadena
      WHEN lnCentenas = 2 THEN 'DOSCIENTOS ' || lcCadena
      WHEN lnCentenas = 3 THEN 'TRESCIENTOS ' || lcCadena
      WHEN lnCentenas = 4 THEN 'CUATROCIENTOS ' || lcCadena
      WHEN lnCentenas = 5 THEN 'QUINIENTOS ' || lcCadena
      WHEN lnCentenas = 6 THEN 'SEISCIENTOS ' || lcCadena
      WHEN lnCentenas = 7 THEN 'SETECIENTOS ' || lcCadena
      WHEN lnCentenas = 8 THEN 'OCHOCIENTOS ' || lcCadena
      WHEN lnCentenas = 9 THEN 'NOVECIENTOS ' || lcCadena
      ELSE lcCadena
    END INTO lcCadena;/* CENTENAS */
    -- Analizo la terna
    SELECT
    CASE /* TERNA */
      WHEN lnTerna = 1 THEN lcCadena
      WHEN lnTerna = 2 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0 THEN lcCadena || ' MILLON '
      WHEN lnTerna = 3 AND (lnUnidades + lnDecenas + lnCentenas <> 0) AND
        NOT (lnUnidades = 1 AND lnDecenas = 0 AND lnCentenas = 0) THEN lcCadena || ' MILLONES '
      WHEN lnTerna = 4 AND (lnUnidades + lnDecenas + lnCentenas <> 0) THEN lcCadena || ' MIL MILLONES '
      ELSE ''
    END INTO lcCadena;/* TERNA */
 
    --Retornamos los Valores Obtenidos
    lcRetorno = lcCadena  || lcRetorno;
    lnTerna = lnTerna + 1;
    END LOOP;
  END IF;
  IF lnTerna = 1 THEN
    lcRetorno := 'CERO';
  END IF;
  lcRetorno := RTRIM(lcRetorno::text) || ' PESOS ' || (CASE WHEN (LTRIM(lnFraccion::text))::int > 0 THEN ' CON '|| LTRIM(lnFraccion::text) ||' CENTAVOS' ELSE '' END)::text;
RETURN lcRetorno;
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
	id_tipo_empleador,tipo_empleador,fecha_carga_social,mes_carga_social)
	select id,descripcion,periodo,fecha_desde,fecha_hasta,id_tipo_liquidacion,id_establecimiento,id_banco,fecha_pago,
	periodo_depositado,lugar_pago,fecha_deposito,id_estado,mes,anio,nro_recibo_inicial,banco, estado, tipo_liquidacion,
	establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad,
	id_tipo_empleador,tipo_empleador,fecha_carga_social,mes_carga_social
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
	domicilio, id_nacionalidad, nacionalidad, pais, provincia,id_establecimiento,establecimiento)
	SELECT r.id, r.nro_recibo, r.id_persona, r.total_remunerativos, r.total_no_remunerativos, r.total_deducciones, r.total_neto, r.total_basico, r.id_liquidacion, 
	  p.apellido,p.nombre,p.legajo,p.tipo_documento,p.nro_documento,p.genero,p.id_estado_civil,p.estado_civil,p.fecha_nacimiento,edad(fecha_nacimiento),p.regimen,p.cuil,
	  p.id_categoria,p.categoria,(select string_agg(descripcion,',') from persona_tareas p1 join tareas t ON p1.id_tarea=t.id where p1.id_persona=p.id) as tarea,p.sueldo_basico,
	  p.fecha_ingreso,p.fecha_egreso,p.id_tipo_contrato,p.tipo_contrato,p.id_obra_social,p.obra_social,p.codigo_obra_social,p.id_localidad,p.localidad,p.cp,
	  p.domicilio,p.id_nacionalidad,p.nacionalidad,p.pais,p.provincia,id_establecimiento,establecimiento
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
    tipo_empleador text,
    fecha_carga_social date NOT NULL,
    mes_carga_social character varying(10)
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
    nro_recibo_inicial integer NOT NULL,
    fecha_carga_social date NOT NULL,
    mes_carga_social character varying(10)
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
    horas_extras_50 numeric(10,2),
    dias_vacaciones integer DEFAULT 0,
    id_periodo integer NOT NULL,
    inasistencias integer,
    horas_extras_100 numeric(10,2) DEFAULT 0
);


--
-- Name: COLUMN periodos_detalle.horas_extras_100; Type: COMMENT; Schema: public; Owner: -
--

COMMENT ON COLUMN public.periodos_detalle.horas_extras_100 IS 'Horas extras al 100%';


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
    json_variables character varying
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
    e.tipo_empleador,
    l.fecha_carga_social,
    l.mes_carga_social
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
    pd.horas_extras_50,
    pd.horas_extras_100,
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
    r.descripcion AS regimen,
    a.cant_hijos,
    a.piso,
    a.departamento,
    a.hora_entrada,
    a.hora_salida
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
INSERT INTO public.conceptos VALUES (1, 'Sueldo Básico', '1', 1, 'basico', true, true, true, NULL, NULL, true, false);
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
INSERT INTO public.conceptos VALUES (44, 'Falla de Caja', '51', 1, NULL, true, true, false, NULL, 0.00, true, false);
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
INSERT INTO public.conceptos VALUES (45, 'Bonificación por Función', '52', 1, NULL, true, true, false, NULL, 0.00, true, false);
INSERT INTO public.conceptos VALUES (42, 'Horas Extras 50%', '4', 1, '( c1 / 200 ) * 1.5 * hsextras50', true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (7, 'Horas Extras 100%', '3', 1, '( c1 / 200 ) * 2 *  hsextras100', true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (43, '5% Remuneracion Abril', '50', 1, NULL, true, true, false, NULL, 0.00, true, false);
INSERT INTO public.conceptos VALUES (11, 'Cuota solidaria Utedyc', '511', 2, 'bruto * 0.025', true, true, false, NULL, NULL, false, false);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 45, true);


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

INSERT INTO public.historico_liquidaciones VALUES (103, 'Liquidacion Junio 2019', '2019-06-01', '2019-06-01', '2019-06-30', 1, 1, 1, '2019-06-29', '06 2019', 'Luján', '2019-06-29', 3, 6, 2019, 1, 'Galicia', 'CERRADA', 'Liquidación Mensual Normal', 'Asociación Médica de Luján', 'Mariano Moreno 1460', 'LUJAN', '3450', 'Corrientes', '33539819769', '911200', 1, 'Dec 814/01, art. 2, inc. B', '2019-06-29', 'Junio');


--
-- Data for Name: historico_liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_liquidaciones_conceptos VALUES (2388, 1, 103, NULL, 'Sueldo Básico', '1', 'basico', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2389, 7, 103, NULL, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2390, 42, 103, NULL, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2391, 12, 103, NULL, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2392, 4, 103, NULL, 'Idem Sueldo Basico', '90', 'c1', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2393, 5, 103, NULL, 'Años Reconocimiento', '101', '0', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2394, 6, 103, NULL, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2395, 13, 103, NULL, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2396, 14, 103, 0.00, 'Ganancias - Gratificaciones', '302', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2397, 16, 103, 0.00, 'Ganancias - SAC', '303', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2398, 15, 103, NULL, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2399, 17, 103, NULL, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2400, 18, 103, NULL, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2401, 19, 103, NULL, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2402, 20, 103, NULL, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2403, 21, 103, NULL, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2404, 22, 103, NULL, 'Ganancia Neta Mensual', '321', 'c309-c320', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2405, 23, 103, NULL, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2406, 32, 103, NULL, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2407, 24, 103, NULL, 'Deducción. Especial', '330', 'tabla("especial")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2408, 25, 103, NULL, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2409, 26, 103, NULL, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2410, 29, 103, 0.00, 'Deducciones. Cargas de familia', '333', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2411, 27, 103, NULL, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2412, 28, 103, NULL, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2413, 30, 103, 0.00, 'Deducciones. Servicio doméstico', '336', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2414, 31, 103, NULL, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2415, 33, 103, NULL, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2416, 34, 103, NULL, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2417, 35, 103, NULL, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2418, 36, 103, NULL, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2419, 37, 103, NULL, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2420, 38, 103, NULL, 'Ganancia neta imponible', '360', 'c322 - c350', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2421, 40, 103, NULL, 'Ganancia Escala', '370', 'ganancias(c360)', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2422, 9, 103, NULL, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2423, 10, 103, NULL, 'Obra Social', '502', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2424, 11, 103, NULL, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2425, 39, 103, NULL, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2426, 43, 103, 0.00, '5% Remuneracion Abril', '50', NULL, 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2427, 45, 103, 0.00, 'Bonificación por Función', '52', NULL, 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2428, 44, 103, 0.00, 'Falla de Caja', '51', NULL, 'HABERES');


--
-- Data for Name: historico_recibos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos VALUES (1649, 13, 20, 58522.98, 0.00, 18142.12, 40380.85, NULL, 103, 'Lombardo', 'Norma Elizabeth', 27, 'DNI', '14097779', 'Femenino', 2, 'Casado/a', '1960-11-25', 58, 'Sipa', '27140977794', 2, '2DA.SUPERV', 'sub area ioma', 40000.00, '2009-08-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1650, 14, 21, 45313.22, 0.00, 14047.10, 31266.12, NULL, 103, 'Paccor', 'Maria Soledad', 35, 'DNI', '27033687', 'Femenino', 1, 'Soltero/a', '1979-03-05', 40, 'Capitalización', '27270336871', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2014-11-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1651, 15, 22, 17971.76, 0.00, 5571.24, 12400.51, NULL, 103, 'Paris', 'Alejandra', 39, 'DNI', '30939775', 'Femenino', 1, 'Soltero/a', '1984-05-06', 35, 'Capitalización', '23309397754', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2016-07-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1652, 16, 23, 52790.40, 0.00, 16365.02, 36425.38, NULL, 103, 'Parra', 'Jorgelina', 23, 'DNI', '25048843', 'Femenino', 1, 'Soltero/a', '1976-05-11', 43, 'Sipa', '27250488438', 3, '1RA.ADM', 'Secretaria', 60000.00, '2007-07-02', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1656, 20, 7, 41348.04, 0.00, 12817.89, 28530.15, NULL, 103, 'Zeppa', 'Silvio', 40, 'DNI', '26563056', 'Masculino', 2, 'Casado/a', '1978-05-20', 41, 'Capitalización', '20265630562', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2017-04-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1637, 1, 8, 44055.41, 0.00, 13657.18, 30398.24, NULL, 103, 'Acosta', 'Claudio Daniel', 29, 'DNI', '26823601', 'Masculino', 2, 'Casado/a', '1978-07-18', 41, 'Sipa', '20268236016', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2011-04-06', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, 'Mariano Moreno 1460', 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1638, 2, 9, 52491.28, 0.00, 16272.30, 36218.98, NULL, 103, 'Becaj', 'Ivan Guillermo', 31, 'DNI', '26583833', 'Masculino', 1, 'Soltero/a', '1978-05-01', 41, 'Reparto', '20265838333', 2, '2DA.SUPERV', 'ay.sub area,facturacion,convenios', 40000.00, '2013-06-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1639, 3, 10, 79572.58, 0.00, 24667.50, 54905.08, NULL, 103, 'Cano', 'Silvia Marina', 5, 'DNI', '14490100', 'Femenino', 2, 'Casado/a', '1960-12-22', 58, 'Sipa', '27144901008', 2, '2DA.SUPERV', 'ay.sub area,facturacion', 40000.00, '1988-12-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1640, 4, 11, 30798.63, 0.00, 9547.58, 21251.05, NULL, 103, 'Cespedes Ramirez', 'Teresita', 8, 'DNI', '92727141', 'Femenino', 3, 'Divorciado/a', '1965-05-20', 54, 'Sipa', '27927271414', 5, 'Maestranza', 'maestr.y serv.', 35000.00, '2010-03-01', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1641, 5, 12, 43064.40, 0.00, 13349.96, 29714.43, NULL, 103, 'Dandrilli', 'Gisela Elizabeth', 34, 'DNI', '30939944', 'Femenino', 2, 'Casado/a', '1984-08-04', 35, 'Capitalización', '27309399442', 4, '2DA.ADM', 'ay.sub area,ioma', 50000.00, '2014-02-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1642, 6, 13, 85990.67, 0.00, 26657.11, 59333.56, NULL, 103, 'Delgado', 'Noemi Severa', 7, 'DNI', '12904169', 'Femenino', 2, 'Casado/a', '1956-10-27', 62, 'Sipa', '27129041698', 2, '2DA.SUPERV', 'Encargada,sub area ioma', 40000.00, '1986-07-14', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1643, 7, 14, 20355.00, 0.00, 6310.05, 14044.95, NULL, 103, 'Echenique', 'Cesar Anibal', 37, 'DNI', '27113644', 'Masculino', 1, 'Soltero/a', '1978-12-24', 40, 'Reparto', '20271136448', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2015-06-01', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1644, 8, 15, 79200.00, 0.00, 24552.00, 54648.00, NULL, 103, 'Ferrari', 'Maria Cecilia', 26, 'DNI', '29594863', 'Femenino', 1, 'Soltero/a', '1982-07-25', 37, 'Sipa', '27295948634', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2008-02-20', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1645, 9, 16, 42039.72, 0.00, 13032.31, 29007.41, NULL, 103, 'Ferreyra', 'Rodrigo Raul', 32, 'DNI', '34831908', 'Masculino', 1, 'Soltero/a', '1989-10-10', 29, 'Reparto', '20348319087', 4, '2DA.ADM', 'ay.sub area,fact.ioma', 50000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1653, 17, 24, 83396.53, 0.00, 25852.92, 57543.60, NULL, 103, 'Poletti', 'Norma', 2, 'DNI', '18601061', 'Femenino', 2, 'Casado/a', '1967-11-07', 51, 'Sipa', '27186010618', 2, '2DA.SUPERV', 'Encargada', 40000.00, '1986-09-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1646, 10, 17, 65574.74, 0.00, 20328.17, 45246.57, NULL, 103, 'Frascaroli', 'Micaela Noemi', 19, 'DNI', '29233345', 'Femenino', 1, 'Soltero/a', '1982-02-27', 37, 'Sipa', '27292333450', 2, '2DA.SUPERV', 'Area Contable', 40000.00, '2003-10-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1647, 11, 18, 61973.53, 0.00, 19211.79, 42761.73, NULL, 103, 'Gallesio', 'Betiana Nazareth', 21, 'DNI', '26167199', 'Femenino', 1, 'Soltero/a', '1978-01-04', 41, 'Sipa', '27261671994', 2, '2DA.SUPERV', 'Encargada,sub area ioma', 40000.00, '2006-11-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1648, 12, 19, 78877.53, 0.00, 24452.03, 54425.50, NULL, 103, 'Herrera', 'Claudia Fabiana', 10, 'DNI', '16833436', 'Femenino', 2, 'Casado/a', '1965-04-28', 54, 'Sipa', '27168334368', 3, '1RA.ADM', 'sub area ioma', 60000.00, '1984-08-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1654, 18, 25, 41950.56, 0.00, 13004.67, 28945.89, NULL, 103, 'Riccardo', 'Lautaro', 33, 'DNI', '32378152', 'Masculino', 1, 'Soltero/a', '1986-05-29', 33, 'Reparto', '20323781525', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1655, 19, 26, 99287.36, 0.00, 30779.08, 68508.28, NULL, 103, 'Romero', 'Ana Gladys', 3, 'DNI', '18148598', 'Femenino', 3, 'Divorciado/a', '1966-05-04', 53, 'Sipa', '27181485987', 1, '1RA.SUPERV', 'Responsable,Ad./Jefa de Personal', 50000.00, '1986-11-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');


--
-- Data for Name: historico_recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_acumuladores VALUES (6161, 1, 44055.41, 1637, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6162, 2, 0.00, 1637, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6163, 3, 44055.41, 1637, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6164, 4, 0.00, 1637, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6165, 5, 13657.18, 1637, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6166, 1, 52491.28, 1638, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6167, 2, 0.00, 1638, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6168, 3, 52491.28, 1638, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6169, 4, 0.00, 1638, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6170, 5, 16272.30, 1638, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6171, 1, 79572.58, 1639, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6172, 2, 0.00, 1639, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6173, 3, 79572.58, 1639, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6174, 4, 0.00, 1639, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6175, 5, 24667.50, 1639, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6176, 1, 30798.63, 1640, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6177, 2, 0.00, 1640, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6178, 3, 30798.63, 1640, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6179, 4, 0.00, 1640, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6180, 5, 9547.58, 1640, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6181, 1, 43064.40, 1641, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6182, 2, 0.00, 1641, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6183, 3, 43064.40, 1641, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6184, 4, 0.00, 1641, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6185, 5, 13349.96, 1641, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6186, 1, 85990.67, 1642, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6187, 2, 0.00, 1642, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6188, 3, 85990.67, 1642, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6189, 4, 0.00, 1642, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6190, 5, 26657.11, 1642, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6191, 1, 20355.00, 1643, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6192, 2, 0.00, 1643, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6193, 3, 20355.00, 1643, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6194, 4, 0.00, 1643, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6195, 5, 6310.05, 1643, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6196, 1, 79200.00, 1644, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6197, 2, 0.00, 1644, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6198, 3, 79200.00, 1644, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6199, 4, 0.00, 1644, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6200, 5, 24552.00, 1644, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6201, 1, 42039.72, 1645, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6202, 2, 0.00, 1645, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6203, 3, 42039.72, 1645, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6204, 4, 0.00, 1645, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6205, 5, 13032.31, 1645, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6206, 1, 65574.74, 1646, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6207, 2, 0.00, 1646, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6208, 3, 65574.74, 1646, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6209, 4, 0.00, 1646, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6210, 5, 20328.17, 1646, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6211, 1, 61973.53, 1647, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6212, 2, 0.00, 1647, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6213, 3, 61973.53, 1647, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6214, 4, 0.00, 1647, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6215, 5, 19211.79, 1647, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6216, 1, 78877.53, 1648, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6217, 2, 0.00, 1648, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6218, 3, 78877.53, 1648, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6219, 4, 0.00, 1648, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6220, 5, 24452.03, 1648, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6221, 1, 58522.98, 1649, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6222, 2, 0.00, 1649, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6223, 3, 58522.98, 1649, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6224, 4, 0.00, 1649, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6225, 5, 18142.12, 1649, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6226, 1, 45313.22, 1650, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6227, 2, 0.00, 1650, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6228, 3, 45313.22, 1650, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6229, 4, 0.00, 1650, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6230, 5, 14047.10, 1650, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6231, 1, 17971.76, 1651, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6232, 2, 0.00, 1651, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6233, 3, 17971.76, 1651, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6234, 4, 0.00, 1651, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6235, 5, 5571.24, 1651, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6236, 1, 52790.40, 1652, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6237, 2, 0.00, 1652, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6238, 3, 52790.40, 1652, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6239, 4, 0.00, 1652, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6240, 5, 16365.02, 1652, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6241, 1, 83396.53, 1653, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6242, 2, 0.00, 1653, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6243, 3, 83396.53, 1653, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6244, 4, 0.00, 1653, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6245, 5, 25852.92, 1653, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6246, 1, 41950.56, 1654, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6247, 2, 0.00, 1654, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6248, 3, 41950.56, 1654, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6249, 4, 0.00, 1654, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6250, 5, 13004.67, 1654, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6251, 1, 99287.36, 1655, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6252, 2, 0.00, 1655, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6253, 3, 99287.36, 1655, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6254, 4, 0.00, 1655, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6255, 5, 30779.08, 1655, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6256, 1, 41348.04, 1656, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6257, 2, 0.00, 1656, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6258, 3, 41348.04, 1656, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6259, 4, 0.00, 1656, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (6260, 5, 12817.89, 1656, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');


--
-- Data for Name: historico_recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_conceptos VALUES (47921, 14, 0.00, 1637, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47922, 16, 0.00, 1637, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47935, 29, 0.00, 1637, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47938, 30, 0.00, 1637, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47952, 45, 0.00, 1637, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47962, 14, 0.00, 1638, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47963, 16, 0.00, 1638, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47976, 29, 0.00, 1638, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47979, 30, 0.00, 1638, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48003, 14, 0.00, 1639, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48004, 16, 0.00, 1639, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48017, 29, 0.00, 1639, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48020, 30, 0.00, 1639, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48044, 14, 0.00, 1640, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48045, 16, 0.00, 1640, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48058, 29, 0.00, 1640, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48061, 30, 0.00, 1640, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48085, 14, 0.00, 1641, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48086, 16, 0.00, 1641, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47992, 43, 2257.00, 1638, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47993, 45, 4216.80, 1638, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47913, 1, 34351.20, 1637, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47914, 7, 0.00, 1637, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47915, 42, 772.90, 1637, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47916, 12, 3435.12, 1637, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47917, 4, 34351.20, 1637, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47918, 5, 0.00, 1637, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47919, 6, 5496.19, 1637, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48099, 29, 0.00, 1641, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48102, 30, 0.00, 1641, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48126, 14, 0.00, 1642, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48127, 16, 0.00, 1642, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48140, 29, 0.00, 1642, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48143, 30, 0.00, 1642, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48167, 14, 0.00, 1643, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48168, 16, 0.00, 1643, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48181, 29, 0.00, 1643, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48184, 30, 0.00, 1643, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48208, 14, 0.00, 1644, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48209, 16, 0.00, 1644, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48222, 29, 0.00, 1644, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48225, 30, 0.00, 1644, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48249, 14, 0.00, 1645, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48250, 16, 0.00, 1645, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48263, 29, 0.00, 1645, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48266, 30, 0.00, 1645, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48098, 26, 0.00, 1641, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48100, 27, 42924.50, 1641, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48101, 28, 0.00, 1641, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48103, 31, 0.00, 1641, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48104, 33, 0.00, 1641, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48105, 34, 0.00, 1641, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48106, 35, 0.00, 1641, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48107, 36, 0.00, 1641, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48108, 37, 288979.06, 1641, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48109, 38, -251423.32, 1641, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48110, 40, 0.00, 1641, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48111, 9, 1291.93, 1641, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48112, 10, 1291.93, 1641, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48290, 14, 0.00, 1646, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48291, 16, 0.00, 1646, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48304, 29, 0.00, 1646, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48307, 30, 0.00, 1646, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48331, 14, 0.00, 1647, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48332, 16, 0.00, 1647, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48345, 29, 0.00, 1647, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48348, 30, 0.00, 1647, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48369, 5, 3.00, 1648, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48372, 14, 0.00, 1648, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48373, 16, 0.00, 1648, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48386, 29, 0.00, 1648, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48389, 30, 0.00, 1648, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48413, 14, 0.00, 1649, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48414, 16, 0.00, 1649, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48427, 29, 0.00, 1649, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48430, 30, 0.00, 1649, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48454, 14, 0.00, 1650, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48455, 16, 0.00, 1650, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48283, 7, 0.00, 1646, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48284, 42, 0.00, 1646, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48285, 12, 4683.91, 1646, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48286, 4, 46839.10, 1646, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48287, 5, 0.00, 1646, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48288, 6, 14051.73, 1646, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48289, 13, 5464.56, 1646, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48292, 15, 71039.30, 1646, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48293, 17, 7814.32, 1646, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48294, 18, 2131.18, 1646, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48468, 29, 0.00, 1650, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48471, 30, 0.00, 1650, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48495, 14, 0.00, 1651, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48496, 16, 0.00, 1651, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48509, 29, 0.00, 1651, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48512, 30, 0.00, 1651, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48536, 14, 0.00, 1652, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48537, 16, 0.00, 1652, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48550, 29, 0.00, 1652, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48553, 30, 0.00, 1652, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48577, 14, 0.00, 1653, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48578, 16, 0.00, 1653, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48591, 29, 0.00, 1653, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48594, 30, 0.00, 1653, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48618, 14, 0.00, 1654, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48619, 16, 0.00, 1654, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48632, 29, 0.00, 1654, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48635, 30, 0.00, 1654, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48469, 27, 42924.50, 1650, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48470, 28, 0.00, 1650, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48472, 31, 0.00, 1650, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48473, 33, 0.00, 1650, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48474, 34, 0.00, 1650, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48475, 35, 0.00, 1650, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48476, 36, 0.00, 1650, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48477, 37, 248962.07, 1650, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48478, 38, -209445.17, 1650, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48479, 40, 0.00, 1650, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48480, 9, 1359.40, 1650, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48481, 10, 1359.40, 1650, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48482, 11, 11328.30, 1650, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48659, 14, 0.00, 1655, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48660, 16, 0.00, 1655, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48673, 29, 0.00, 1655, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48676, 30, 0.00, 1655, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48700, 14, 0.00, 1656, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48701, 16, 0.00, 1656, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48714, 29, 0.00, 1656, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48717, 30, 0.00, 1656, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48033, 43, 3615.23, 1639, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48034, 45, 7114.91, 1639, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48074, 43, 1294.00, 1640, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48115, 43, 1918.37, 1641, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48117, 44, 3219.73, 1641, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48156, 43, 3825.35, 1642, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48157, 45, 4102.65, 1642, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48158, 44, 3219.73, 1642, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48197, 43, 2491.76, 1643, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48238, 43, 1475.72, 1644, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48279, 43, 1772.88, 1645, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48320, 43, 3077.41, 1646, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48321, 45, 4554.36, 1646, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48322, 44, 3219.73, 1646, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48361, 43, 2550.86, 1647, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48362, 45, 5903.89, 1647, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48402, 43, 3066.64, 1648, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48403, 45, 1417.38, 1648, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48404, 44, 3219.79, 1648, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48443, 43, 2536.36, 1649, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48444, 45, 5589.81, 1649, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48484, 43, 1900.17, 1650, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48525, 43, 759.05, 1651, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48566, 43, 2305.45, 1652, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48568, 44, 3219.00, 1652, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48607, 43, 4395.26, 1653, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48608, 45, 9601.68, 1653, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48648, 43, 1769.12, 1654, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48689, 43, 4969.00, 1655, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48690, 45, 16956.60, 1655, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48691, 44, 3219.73, 1655, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48730, 43, 2270.71, 1656, '5% Remuneracion Abril', '50', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47920, 13, 3671.28, 1637, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47923, 15, 47726.70, 1637, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47924, 17, 5249.94, 1637, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47925, 18, 1431.80, 1637, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47926, 19, 1431.80, 1637, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47927, 20, 1193.17, 1637, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47928, 21, 9306.71, 1637, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47929, 22, 38419.99, 1637, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47930, 23, 38419.99, 1637, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47931, 32, 1921.00, 1637, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47932, 24, 206037.57, 1637, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47933, 25, 40016.99, 1637, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47934, 26, 0.00, 1637, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47936, 27, 42924.50, 1637, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47937, 28, 0.00, 1637, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47939, 31, 0.00, 1637, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47940, 33, 0.00, 1637, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47941, 34, 0.00, 1637, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47942, 35, 0.00, 1637, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47943, 36, 0.00, 1637, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47944, 37, 288979.06, 1637, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47945, 38, -250559.07, 1637, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47946, 40, 0.00, 1637, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47947, 9, 1321.66, 1637, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47948, 10, 1321.66, 1637, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47949, 11, 11013.85, 1637, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47950, 39, 0.00, 1637, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47954, 1, 41008.81, 1638, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47955, 7, 0.00, 1638, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47956, 42, 2460.53, 1638, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47957, 12, 4100.88, 1638, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47958, 4, 41008.81, 1638, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47959, 5, 0.00, 1638, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47960, 6, 4921.06, 1638, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (47961, 13, 4374.27, 1638, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47964, 15, 56865.55, 1638, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47965, 17, 6255.21, 1638, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47966, 18, 1705.97, 1638, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47967, 19, 1705.97, 1638, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47968, 20, 1421.64, 1638, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47969, 21, 11088.78, 1638, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47970, 22, 45776.77, 1638, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47971, 23, 45776.77, 1638, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47972, 32, 2288.84, 1638, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47973, 24, 206037.57, 1638, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47974, 25, 0.00, 1638, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47975, 26, 0.00, 1638, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47977, 27, 42924.50, 1638, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47978, 28, 0.00, 1638, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47980, 31, 0.00, 1638, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47981, 33, 0.00, 1638, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47982, 34, 0.00, 1638, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47983, 35, 0.00, 1638, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47984, 36, 0.00, 1638, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47985, 37, 248962.07, 1638, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47986, 38, -203185.30, 1638, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47987, 40, 0.00, 1638, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47988, 9, 1574.74, 1638, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47989, 10, 1574.74, 1638, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47990, 11, 13122.82, 1638, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48653, 42, 0.00, 1655, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48654, 12, 5706.17, 1655, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48655, 4, 57061.70, 1655, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48656, 5, 0.00, 1655, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48657, 6, 36519.49, 1655, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (47991, 39, 0.00, 1638, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47995, 1, 46807.40, 1639, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47996, 7, 0.00, 1639, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47997, 42, 0.00, 1639, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47998, 12, 4680.74, 1639, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (47999, 4, 46807.40, 1639, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48000, 5, 0.00, 1639, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48001, 6, 28084.44, 1639, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48002, 13, 6631.05, 1639, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48005, 15, 86203.63, 1639, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48006, 17, 9482.40, 1639, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48007, 18, 2586.11, 1639, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48008, 19, 2586.11, 1639, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48009, 20, 2155.09, 1639, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48010, 21, 16809.71, 1639, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48011, 22, 69393.92, 1639, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48012, 23, 69393.92, 1639, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48013, 32, 3469.70, 1639, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48014, 24, 206037.57, 1639, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48015, 25, 40016.99, 1639, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48016, 26, 0.00, 1639, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48018, 27, 42924.50, 1639, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48019, 28, 0.00, 1639, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48084, 13, 3588.70, 1641, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48021, 31, 0.00, 1639, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48022, 33, 0.00, 1639, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48023, 34, 0.00, 1639, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48024, 35, 0.00, 1639, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48025, 36, 0.00, 1639, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48026, 37, 288979.06, 1639, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48027, 38, -219585.14, 1639, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48028, 40, 0.00, 1639, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48029, 9, 2387.18, 1639, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48030, 10, 2387.18, 1639, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48031, 11, 19893.15, 1639, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48032, 39, 0.00, 1639, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48036, 1, 24061.43, 1640, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48037, 7, 0.00, 1640, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48038, 42, 0.00, 1640, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48039, 12, 2406.14, 1640, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48040, 4, 24061.43, 1640, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48041, 5, 0.00, 1640, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48042, 6, 4331.06, 1640, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48043, 13, 2566.55, 1640, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48046, 15, 33365.18, 1640, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48047, 17, 3670.17, 1640, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48048, 18, 1000.96, 1640, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48049, 19, 1000.96, 1640, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48050, 20, 834.13, 1640, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48051, 21, 6506.21, 1640, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48052, 22, 26858.97, 1640, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48053, 23, 26858.97, 1640, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48054, 32, 1342.95, 1640, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48055, 24, 206037.57, 1640, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48056, 25, 0.00, 1640, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48057, 26, 0.00, 1640, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48059, 27, 42924.50, 1640, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48060, 28, 0.00, 1640, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48062, 31, 0.00, 1640, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48063, 33, 0.00, 1640, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48064, 34, 0.00, 1640, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48065, 35, 0.00, 1640, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48066, 36, 0.00, 1640, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48067, 37, 248962.07, 1640, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48068, 38, -222103.10, 1640, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48069, 40, 0.00, 1640, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48070, 9, 923.96, 1640, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48071, 10, 923.96, 1640, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48072, 11, 7699.66, 1640, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48073, 39, 0.00, 1640, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48077, 1, 35226.50, 1641, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48078, 7, 0.00, 1641, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48079, 42, 792.60, 1641, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48080, 12, 3522.65, 1641, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48081, 4, 35226.50, 1641, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48082, 5, 0.00, 1641, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48083, 6, 3522.65, 1641, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48087, 15, 46653.10, 1641, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48088, 17, 5131.84, 1641, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48089, 18, 1399.59, 1641, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48090, 19, 1399.59, 1641, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48091, 20, 1166.33, 1641, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48092, 21, 9097.35, 1641, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48093, 22, 37555.74, 1641, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48094, 23, 37555.74, 1641, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48095, 32, 1877.79, 1641, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48096, 24, 206037.57, 1641, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48097, 25, 40016.99, 1641, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48113, 11, 10766.10, 1641, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48114, 39, 0.00, 1641, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48118, 1, 48582.30, 1642, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48119, 7, 0.00, 1642, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48120, 42, 1457.47, 1642, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48121, 12, 4858.23, 1642, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48122, 4, 48582.30, 1642, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48123, 5, 0.00, 1642, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48124, 6, 31092.67, 1642, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48125, 13, 7165.89, 1642, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48128, 15, 93156.56, 1642, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48129, 17, 10247.22, 1642, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48130, 18, 2794.70, 1642, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48131, 19, 2794.70, 1642, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48132, 20, 2328.91, 1642, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48133, 21, 18165.53, 1642, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48134, 22, 74991.03, 1642, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48135, 23, 74991.03, 1642, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48136, 32, 3749.55, 1642, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48137, 24, 206037.57, 1642, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48138, 25, 40016.99, 1642, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48139, 26, 0.00, 1642, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48141, 27, 42924.50, 1642, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48142, 28, 0.00, 1642, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48144, 31, 0.00, 1642, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48145, 33, 0.00, 1642, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48146, 34, 0.00, 1642, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48147, 35, 0.00, 1642, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48148, 36, 0.00, 1642, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48149, 37, 288979.06, 1642, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48150, 38, -213988.03, 1642, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48151, 40, 0.00, 1642, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48152, 9, 2579.72, 1642, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48153, 10, 2579.72, 1642, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48154, 11, 21497.67, 1642, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48155, 39, 0.00, 1642, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48159, 1, 17250.00, 1643, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48160, 7, 0.00, 1643, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48161, 42, 0.00, 1643, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48162, 12, 1725.00, 1643, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48163, 4, 17250.00, 1643, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48164, 5, 0.00, 1643, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48165, 6, 1380.00, 1643, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48166, 13, 1696.25, 1643, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48169, 15, 22051.25, 1643, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48170, 17, 2425.64, 1643, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48171, 18, 661.54, 1643, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48172, 19, 661.54, 1643, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48173, 20, 551.28, 1643, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48174, 21, 4299.99, 1643, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48175, 22, 17751.26, 1643, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48176, 23, 17751.26, 1643, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48177, 32, 887.56, 1643, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48178, 24, 206037.57, 1643, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48179, 25, 0.00, 1643, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48180, 26, 0.00, 1643, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48182, 27, 42924.50, 1643, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48183, 28, 0.00, 1643, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48185, 31, 0.00, 1643, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48186, 33, 0.00, 1643, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48187, 34, 0.00, 1643, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48188, 35, 0.00, 1643, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48189, 36, 0.00, 1643, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48190, 37, 248962.07, 1643, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48191, 38, -231210.81, 1643, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48192, 40, 0.00, 1643, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48193, 9, 610.65, 1643, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48194, 10, 610.65, 1643, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48195, 11, 5088.75, 1643, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48196, 39, 0.00, 1643, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48200, 1, 60000.00, 1644, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48201, 7, 0.00, 1644, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48202, 42, 0.00, 1644, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48203, 12, 6000.00, 1644, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48204, 4, 60000.00, 1644, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48205, 5, 0.00, 1644, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48206, 6, 13200.00, 1644, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48207, 13, 6600.00, 1644, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48210, 15, 85800.00, 1644, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48211, 17, 9438.00, 1644, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48212, 18, 2574.00, 1644, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48213, 19, 2574.00, 1644, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48214, 20, 2145.00, 1644, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48215, 21, 16731.00, 1644, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48216, 22, 69069.00, 1644, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48217, 23, 69069.00, 1644, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48218, 32, 3453.45, 1644, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48219, 24, 206037.57, 1644, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48220, 25, 0.00, 1644, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48221, 26, 0.00, 1644, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48223, 27, 42924.50, 1644, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48224, 28, 0.00, 1644, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48226, 31, 0.00, 1644, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48227, 33, 0.00, 1644, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48228, 34, 0.00, 1644, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48229, 35, 0.00, 1644, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48230, 36, 0.00, 1644, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48231, 37, 248962.07, 1644, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48232, 38, -179893.07, 1644, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48233, 40, 0.00, 1644, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48234, 9, 2376.00, 1644, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48235, 10, 2376.00, 1644, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48236, 11, 19800.00, 1644, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48237, 39, 0.00, 1644, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48241, 1, 35033.10, 1645, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48242, 7, 0.00, 1645, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48243, 42, 0.00, 1645, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48244, 12, 3503.31, 1645, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48245, 4, 35033.10, 1645, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48246, 5, 0.00, 1645, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48247, 6, 3503.31, 1645, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48248, 13, 3503.31, 1645, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48251, 15, 45543.03, 1645, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48252, 17, 5009.73, 1645, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48253, 18, 1366.29, 1645, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48254, 19, 1366.29, 1645, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48255, 20, 1138.58, 1645, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48256, 21, 8880.89, 1645, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48257, 22, 36662.14, 1645, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48258, 23, 36662.14, 1645, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48259, 32, 1833.11, 1645, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48260, 24, 206037.57, 1645, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48261, 25, 0.00, 1645, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48262, 26, 0.00, 1645, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48264, 27, 42924.50, 1645, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48265, 28, 0.00, 1645, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48267, 31, 0.00, 1645, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48268, 33, 0.00, 1645, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48269, 34, 0.00, 1645, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48270, 35, 0.00, 1645, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48271, 36, 0.00, 1645, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48272, 37, 248962.07, 1645, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48273, 38, -212299.93, 1645, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48274, 40, 0.00, 1645, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48275, 9, 1261.19, 1645, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48276, 10, 1261.19, 1645, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48277, 11, 10509.93, 1645, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48278, 39, 0.00, 1645, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48282, 1, 46839.10, 1646, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48295, 19, 2131.18, 1646, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48296, 20, 1775.98, 1646, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48297, 21, 13852.66, 1646, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48298, 22, 57186.64, 1646, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48299, 23, 57186.64, 1646, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48300, 32, 2859.33, 1646, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48301, 24, 206037.57, 1646, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48302, 25, 0.00, 1646, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48303, 26, 0.00, 1646, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48305, 27, 42924.50, 1646, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48306, 28, 0.00, 1646, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48308, 31, 0.00, 1646, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48309, 33, 0.00, 1646, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48310, 34, 0.00, 1646, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48379, 21, 16662.88, 1648, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48311, 35, 0.00, 1646, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48312, 36, 0.00, 1646, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48313, 37, 248962.07, 1646, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48314, 38, -191775.43, 1646, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48315, 40, 0.00, 1646, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48316, 9, 1967.24, 1646, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48317, 10, 1967.24, 1646, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48318, 11, 16393.69, 1646, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48319, 39, 0.00, 1646, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48323, 1, 42666.80, 1647, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48324, 7, 0.00, 1647, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48325, 42, 4800.02, 1647, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48326, 12, 4266.68, 1647, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48327, 4, 42666.80, 1647, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48328, 5, 0.00, 1647, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48329, 6, 10240.03, 1647, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48330, 13, 5164.46, 1647, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48333, 15, 67137.99, 1647, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48334, 17, 7385.18, 1647, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48335, 18, 2014.14, 1647, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48336, 19, 2014.14, 1647, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48337, 20, 1678.45, 1647, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48338, 21, 13091.91, 1647, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48339, 22, 54046.08, 1647, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48340, 23, 54046.08, 1647, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48341, 32, 2702.30, 1647, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48342, 24, 206037.57, 1647, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48343, 25, 0.00, 1647, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48344, 26, 0.00, 1647, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48346, 27, 42924.50, 1647, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48347, 28, 0.00, 1647, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48349, 31, 0.00, 1647, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48350, 33, 0.00, 1647, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48351, 34, 0.00, 1647, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48352, 35, 0.00, 1647, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48353, 36, 0.00, 1647, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48354, 37, 248962.07, 1647, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48355, 38, -194915.99, 1647, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48356, 40, 0.00, 1647, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48357, 9, 1859.21, 1647, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48358, 10, 1859.21, 1647, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48359, 11, 15493.38, 1647, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48360, 39, 0.00, 1647, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48364, 1, 42012.00, 1648, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48365, 7, 0.00, 1648, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48366, 42, 1575.45, 1648, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48367, 12, 4201.20, 1648, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48368, 4, 42012.00, 1648, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48370, 6, 31088.88, 1648, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48371, 13, 6573.13, 1648, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48374, 15, 85450.66, 1648, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48375, 17, 9399.57, 1648, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48376, 18, 2563.52, 1648, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48377, 19, 2563.52, 1648, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48378, 20, 2136.27, 1648, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48380, 22, 68787.78, 1648, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48381, 23, 68787.78, 1648, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48382, 32, 3439.39, 1648, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48383, 24, 206037.57, 1648, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48384, 25, 40016.99, 1648, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48385, 26, 0.00, 1648, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48387, 27, 42924.50, 1648, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48388, 28, 0.00, 1648, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48390, 31, 0.00, 1648, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48391, 33, 0.00, 1648, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48392, 34, 0.00, 1648, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48393, 35, 0.00, 1648, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48394, 36, 0.00, 1648, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48395, 37, 288979.06, 1648, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48396, 38, -220191.28, 1648, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48397, 40, 0.00, 1648, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48398, 9, 2366.33, 1648, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48399, 10, 2366.33, 1648, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48400, 11, 19719.38, 1648, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48401, 39, 0.00, 1648, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48405, 1, 42717.50, 1649, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48406, 7, 0.00, 1649, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48407, 42, 3844.58, 1649, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48408, 12, 4271.75, 1649, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48409, 4, 42717.50, 1649, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48410, 5, 0.00, 1649, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48411, 6, 7689.15, 1649, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48412, 13, 4876.91, 1649, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48415, 15, 63399.89, 1649, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48416, 17, 6973.99, 1649, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48417, 18, 1902.00, 1649, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48418, 19, 1902.00, 1649, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48419, 20, 1585.00, 1649, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48420, 21, 12362.98, 1649, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48421, 22, 51036.91, 1649, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48422, 23, 51036.91, 1649, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48423, 32, 2551.85, 1649, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48424, 24, 206037.57, 1649, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48425, 25, 40016.99, 1649, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48426, 26, 0.00, 1649, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48428, 27, 42924.50, 1649, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48429, 28, 0.00, 1649, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48431, 31, 0.00, 1649, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48432, 33, 0.00, 1649, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48433, 34, 0.00, 1649, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48434, 35, 0.00, 1649, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48435, 36, 0.00, 1649, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48436, 37, 288979.06, 1649, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48437, 38, -237942.15, 1649, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48438, 40, 0.00, 1649, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48439, 9, 1755.69, 1649, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48440, 10, 1755.69, 1649, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48528, 1, 39104.00, 1652, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48441, 11, 14630.74, 1649, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48442, 39, 0.00, 1649, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48446, 1, 38158.50, 1650, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48447, 7, 0.00, 1650, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48448, 42, 286.19, 1650, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48449, 12, 3815.85, 1650, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48450, 4, 38158.50, 1650, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48451, 5, 0.00, 1650, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48452, 6, 3052.68, 1650, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48453, 13, 3776.10, 1650, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48456, 15, 49089.32, 1650, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48457, 17, 5399.83, 1650, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48458, 18, 1472.68, 1650, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48459, 19, 1472.68, 1650, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48460, 20, 1227.23, 1650, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48461, 21, 9572.42, 1650, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48462, 22, 39516.90, 1650, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48463, 23, 39516.90, 1650, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48464, 32, 1975.85, 1650, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48465, 24, 206037.57, 1650, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48466, 25, 0.00, 1650, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48467, 26, 0.00, 1650, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48483, 39, 0.00, 1650, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48487, 1, 15764.70, 1651, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48488, 7, 0.00, 1651, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48489, 42, 0.00, 1651, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48490, 12, 1576.47, 1651, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48491, 4, 15764.70, 1651, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48492, 5, 0.00, 1651, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48493, 6, 630.59, 1651, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48494, 13, 1497.65, 1651, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48497, 15, 19469.40, 1651, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48498, 17, 2141.63, 1651, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48499, 18, 584.08, 1651, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48500, 19, 584.08, 1651, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48501, 20, 486.74, 1651, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48502, 21, 3796.53, 1651, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48503, 22, 15672.87, 1651, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48504, 23, 15672.87, 1651, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48505, 32, 783.64, 1651, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48506, 24, 206037.57, 1651, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48507, 25, 0.00, 1651, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48508, 26, 0.00, 1651, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48510, 27, 42924.50, 1651, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48511, 28, 0.00, 1651, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48513, 31, 0.00, 1651, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48514, 33, 0.00, 1651, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48515, 34, 0.00, 1651, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48516, 35, 0.00, 1651, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48517, 36, 0.00, 1651, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48518, 37, 248962.07, 1651, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48519, 38, -233289.20, 1651, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48520, 40, 0.00, 1651, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48521, 9, 539.15, 1651, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48522, 10, 539.15, 1651, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48523, 11, 4492.94, 1651, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48524, 39, 0.00, 1651, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48529, 7, 0.00, 1652, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48530, 42, 1173.12, 1652, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48531, 12, 3910.40, 1652, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48532, 4, 39104.00, 1652, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48533, 5, 0.00, 1652, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48534, 6, 8602.88, 1652, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48535, 13, 4399.20, 1652, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48538, 15, 57189.60, 1652, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48539, 17, 6290.86, 1652, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48540, 18, 1715.69, 1652, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48541, 19, 1715.69, 1652, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48542, 20, 1429.74, 1652, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48543, 21, 11151.97, 1652, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48544, 22, 46037.63, 1652, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48545, 23, 46037.63, 1652, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48546, 32, 2301.88, 1652, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48547, 24, 206037.57, 1652, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48548, 25, 0.00, 1652, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48549, 26, 0.00, 1652, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48551, 27, 42924.50, 1652, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48552, 28, 0.00, 1652, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48554, 31, 0.00, 1652, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48555, 33, 0.00, 1652, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48556, 34, 0.00, 1652, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48557, 35, 0.00, 1652, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48558, 36, 0.00, 1652, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48559, 37, 248962.07, 1652, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48560, 38, -202924.44, 1652, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48561, 40, 0.00, 1652, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48562, 9, 1583.71, 1652, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48563, 10, 1583.71, 1652, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48564, 11, 13197.60, 1652, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48565, 39, 0.00, 1652, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48569, 1, 45948.50, 1653, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48570, 7, 0.00, 1653, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48571, 42, 3446.14, 1653, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48572, 12, 4594.85, 1653, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48573, 4, 45948.50, 1653, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48574, 5, 0.00, 1653, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48575, 6, 29407.04, 1653, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48576, 13, 6949.71, 1653, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48579, 15, 90346.24, 1653, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48580, 17, 9938.09, 1653, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48581, 18, 2710.39, 1653, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48582, 19, 2710.39, 1653, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48583, 20, 2258.66, 1653, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48584, 21, 17617.52, 1653, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48585, 22, 72728.72, 1653, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48586, 23, 72728.72, 1653, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48587, 32, 3636.44, 1653, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48588, 24, 206037.57, 1653, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48589, 25, 40016.99, 1653, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48590, 26, 0.00, 1653, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48592, 27, 42924.50, 1653, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48593, 28, 0.00, 1653, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48665, 20, 2689.03, 1655, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48595, 31, 0.00, 1653, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48596, 33, 0.00, 1653, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48597, 34, 0.00, 1653, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48598, 35, 0.00, 1653, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48599, 36, 0.00, 1653, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48600, 37, 288979.06, 1653, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48601, 38, -216250.34, 1653, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48602, 40, 0.00, 1653, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48603, 9, 2501.90, 1653, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48604, 10, 2501.90, 1653, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48605, 11, 20849.13, 1653, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48606, 39, 0.00, 1653, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48610, 1, 34958.80, 1654, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48611, 7, 0.00, 1654, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48612, 42, 0.00, 1654, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48613, 12, 3495.88, 1654, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48614, 4, 34958.80, 1654, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48615, 5, 0.00, 1654, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48616, 6, 3495.88, 1654, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48617, 13, 3495.88, 1654, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48620, 15, 45446.44, 1654, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48621, 17, 4999.11, 1654, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48622, 18, 1363.39, 1654, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48623, 19, 1363.39, 1654, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48624, 20, 1136.16, 1654, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48625, 21, 8862.06, 1654, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48626, 22, 36584.38, 1654, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48627, 23, 36584.38, 1654, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48628, 32, 1829.22, 1654, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48629, 24, 206037.57, 1654, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48630, 25, 0.00, 1654, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48631, 26, 0.00, 1654, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48633, 27, 42924.50, 1654, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48634, 28, 0.00, 1654, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48636, 31, 0.00, 1654, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48637, 33, 0.00, 1654, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48638, 34, 0.00, 1654, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48639, 35, 0.00, 1654, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48640, 36, 0.00, 1654, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48641, 37, 248962.07, 1654, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48642, 38, -212377.69, 1654, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48643, 40, 0.00, 1654, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48644, 9, 1258.52, 1654, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48645, 10, 1258.52, 1654, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48646, 11, 10487.64, 1654, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48647, 39, 0.00, 1654, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48651, 1, 57061.70, 1655, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48652, 7, 0.00, 1655, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48658, 13, 8273.95, 1655, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48661, 15, 107561.30, 1655, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48662, 17, 11831.74, 1655, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48663, 18, 3226.84, 1655, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48664, 19, 3226.84, 1655, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48666, 21, 20974.45, 1655, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48667, 22, 86586.85, 1655, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48668, 23, 86586.85, 1655, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48669, 32, 4329.34, 1655, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48670, 24, 206037.57, 1655, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48671, 25, 0.00, 1655, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48672, 26, 0.00, 1655, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48674, 27, 42924.50, 1655, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48675, 28, 0.00, 1655, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48677, 31, 0.00, 1655, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48678, 33, 0.00, 1655, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48679, 34, 0.00, 1655, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48680, 35, 0.00, 1655, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48681, 36, 0.00, 1655, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48682, 37, 248962.07, 1655, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48683, 38, -162375.22, 1655, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48684, 40, 0.00, 1655, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48685, 9, 2978.62, 1655, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48686, 10, 2978.62, 1655, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48687, 11, 24821.84, 1655, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48688, 39, 0.00, 1655, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48692, 1, 34892.86, 1656, 'Sueldo Básico', '1', 'basico', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48693, 7, 0.00, 1656, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48694, 42, 1570.18, 1656, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48695, 12, 3489.29, 1656, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48696, 4, 34892.86, 1656, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48697, 5, 0.00, 1656, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48698, 6, 1395.71, 1656, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (48699, 13, 3445.67, 1656, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48702, 15, 44793.71, 1656, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48703, 17, 4927.31, 1656, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48704, 18, 1343.81, 1656, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48705, 19, 1343.81, 1656, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48706, 20, 1119.84, 1656, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48707, 21, 8734.77, 1656, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48708, 22, 36058.94, 1656, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48709, 23, 36058.94, 1656, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48710, 32, 1802.95, 1656, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48711, 24, 206037.57, 1656, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48712, 25, 40016.99, 1656, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48713, 26, 0.00, 1656, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48715, 27, 42924.50, 1656, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48716, 28, 0.00, 1656, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48718, 31, 0.00, 1656, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48719, 33, 0.00, 1656, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48720, 34, 0.00, 1656, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48721, 35, 0.00, 1656, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48722, 36, 0.00, 1656, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48723, 37, 288979.06, 1656, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48724, 38, -252920.12, 1656, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48725, 40, 0.00, 1656, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48726, 9, 1240.44, 1656, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48727, 10, 1240.44, 1656, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48728, 11, 10337.01, 1656, 'Cuota solidaria Utedyc', '511', 'bruto * 0.25', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (48729, 39, 0.00, 1656, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', false, false, false, NULL, false, false);


--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (103, 'Liquidacion Junio 2019', '2019-06-01', '2019-06-01', '2019-06-30', 1, 1, 1, '2019-06-29', '06 2019', 'Luján', '2019-06-29', 3, 6, 2019, 1, '2019-06-29', 'Junio');


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (2388, 1, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2389, 7, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2390, 42, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2391, 12, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2392, 4, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2393, 5, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2394, 6, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2395, 13, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2396, 14, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2397, 16, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2398, 15, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2399, 17, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2400, 18, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2401, 19, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2402, 20, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2403, 21, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2404, 22, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2405, 23, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2406, 32, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2407, 24, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2408, 25, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2409, 26, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2410, 29, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2411, 27, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2412, 28, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2413, 30, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2414, 31, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2415, 33, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2416, 34, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2417, 35, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2418, 36, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2419, 37, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2420, 38, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2421, 40, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2422, 9, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2423, 10, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2424, 11, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2425, 39, 103, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2426, 43, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2427, 45, 103, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2428, 44, 103, 0.00);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 2428, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 103, true);


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

INSERT INTO public.periodos VALUES (3, 'Datos del periodo enero 2019', 2019, 1, '2019-01-01', '2019-01-01', '2019-01-31', 'Estos datos son usados cuando se liquide Enero 2019');
INSERT INTO public.periodos VALUES (4, 'Planilla de Junio', 2019, 6, '2019-06-01', '2019-06-01', '2019-06-30', NULL);


--
-- Data for Name: periodos_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.periodos_detalle VALUES (5, 10, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (6, 13, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (7, 11, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (8, 19, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (9, 17, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (10, 18, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (11, 23, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (12, 15, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (13, 20, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (14, 8, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (15, 9, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (16, 16, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (17, 25, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (18, 12, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (19, 21, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (20, 14, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (21, 22, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (22, 7, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (3, 24, 23.00, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (4, 26, 99.00, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (23, 24, NULL, NULL, 10.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (24, 26, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (25, 10, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (26, 13, NULL, NULL, 4.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (27, 11, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (28, 19, NULL, NULL, 5.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (29, 17, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (30, 18, NULL, NULL, 15.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (31, 23, NULL, NULL, 4.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (32, 15, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (33, 20, NULL, NULL, 12.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (34, 8, NULL, NULL, 3.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (35, 9, NULL, NULL, 8.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (36, 16, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (37, 25, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (38, 12, NULL, NULL, 3.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (39, 21, NULL, NULL, 1.00, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (40, 14, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (41, 22, NULL, NULL, NULL, 0, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (42, 7, NULL, NULL, 6.00, 0, 4, NULL, 0.00);


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_detalle_id_seq', 42, true);


--
-- Name: periodos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_id_seq', 4, true);


--
-- Data for Name: persona_tareas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.persona_tareas VALUES (2, 2, 1);
INSERT INTO public.persona_tareas VALUES (4, 8, 1);
INSERT INTO public.persona_tareas VALUES (5, 8, 2);
INSERT INTO public.persona_tareas VALUES (6, 7, 1);
INSERT INTO public.persona_tareas VALUES (7, 7, 2);
INSERT INTO public.persona_tareas VALUES (8, 9, 1);
INSERT INTO public.persona_tareas VALUES (9, 9, 2);
INSERT INTO public.persona_tareas VALUES (10, 9, 3);
INSERT INTO public.persona_tareas VALUES (11, 10, 1);
INSERT INTO public.persona_tareas VALUES (12, 10, 2);
INSERT INTO public.persona_tareas VALUES (13, 11, 4);
INSERT INTO public.persona_tareas VALUES (14, 12, 1);
INSERT INTO public.persona_tareas VALUES (15, 12, 5);
INSERT INTO public.persona_tareas VALUES (16, 13, 6);
INSERT INTO public.persona_tareas VALUES (17, 13, 7);
INSERT INTO public.persona_tareas VALUES (18, 14, 1);
INSERT INTO public.persona_tareas VALUES (19, 14, 2);
INSERT INTO public.persona_tareas VALUES (20, 15, 1);
INSERT INTO public.persona_tareas VALUES (21, 15, 2);
INSERT INTO public.persona_tareas VALUES (22, 16, 1);
INSERT INTO public.persona_tareas VALUES (23, 16, 8);
INSERT INTO public.persona_tareas VALUES (24, 17, 9);
INSERT INTO public.persona_tareas VALUES (26, 18, 7);
INSERT INTO public.persona_tareas VALUES (27, 18, 6);
INSERT INTO public.persona_tareas VALUES (3, 19, 7);
INSERT INTO public.persona_tareas VALUES (28, 20, 7);
INSERT INTO public.persona_tareas VALUES (29, 21, 1);
INSERT INTO public.persona_tareas VALUES (30, 21, 2);
INSERT INTO public.persona_tareas VALUES (31, 22, 1);
INSERT INTO public.persona_tareas VALUES (32, 22, 2);
INSERT INTO public.persona_tareas VALUES (33, 23, 10);
INSERT INTO public.persona_tareas VALUES (34, 24, 6);
INSERT INTO public.persona_tareas VALUES (35, 25, 1);
INSERT INTO public.persona_tareas VALUES (36, 25, 2);
INSERT INTO public.persona_tareas VALUES (37, 26, 11);
INSERT INTO public.persona_tareas VALUES (38, 26, 12);


--
-- Name: persona_tareas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.persona_tareas_id_seq', 38, true);


--
-- Data for Name: personas; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.personas VALUES (2, 'Martin', 'Garay', '1989-05-11', 1, '34555008', 1, 1, false, 4611, 1, 1, 1, 1, 'martingaray_12@gmail.com', '2019-07-01', '2019-08-15', '08:00:00', '15:00:00', 1, 'San Vicente 1351', '1 ', 'D         ', '01122777025', '01122777025', 1, '23345550089', 7.00, 10000.00, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (20, 'Norma Elizabeth', 'Lombardo', '1960-11-25', 1, '14097779', 2, 1, true, 27, 2, 2, 1, 1, NULL, '2009-08-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27140977794', 7.00, 42717.50, 0, 8.00, 2);
INSERT INTO public.personas VALUES (21, 'Maria Soledad', 'Paccor', '1979-03-05', 1, '27033687', 2, 1, true, 35, 1, 3, 1, 1, NULL, '2014-11-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27270336871', 7.00, 38158.50, 0, 8.00, 3);
INSERT INTO public.personas VALUES (22, 'Alejandra', 'Paris', '1984-05-06', 1, '30939775', 2, 1, true, 39, 1, 3, 1, 1, NULL, '2016-07-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '23309397754', 7.00, 15764.70, 0, 8.00, 3);
INSERT INTO public.personas VALUES (23, 'Jorgelina', 'Parra', '1976-05-11', 1, '25048843', 2, 1, true, 23, 1, 3, 1, 1, NULL, '2007-07-02', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27250488438', 7.00, 39104.00, 0, 8.00, 2);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265630562', 7.00, 34892.86, 0, 8.00, 3);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, 'Mariano Moreno 1460', NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 34351.20, 0, 8.00, 2);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265838333', 7.00, 41008.81, 0, 8.00, 1);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27144901008', 7.00, 46807.40, 0, 8.00, 2);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27927271414', 7.00, 24061.43, 0, 4.00, 2);
INSERT INTO public.personas VALUES (12, 'Gisela Elizabeth', 'Dandrilli', '1984-08-04', 1, '30939944', 2, 1, true, 34, 2, 4, 1, 1, NULL, '2014-02-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27309399442', 7.00, 35226.50, 0, 8.00, 3);
INSERT INTO public.personas VALUES (13, 'Noemi Severa', 'Delgado', '1956-10-27', 1, '12904169', 2, 1, true, 7, 2, 2, 1, 1, NULL, '1986-07-14', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27129041698', 7.00, 48582.30, 0, 8.00, 2);
INSERT INTO public.personas VALUES (14, 'Cesar Anibal', 'Echenique', '1978-12-24', 1, '27113644', 1, 1, true, 37, 1, 3, 2, 1, NULL, '2015-06-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20271136448', 7.00, 17250.00, 0, 4.00, 1);
INSERT INTO public.personas VALUES (15, 'Maria Cecilia', 'Ferrari', '1982-07-25', 1, '29594863', 2, 1, true, 26, 1, 3, 2, 1, NULL, '2008-02-20', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27295948634', 7.00, NULL, 0, 4.00, 2);
INSERT INTO public.personas VALUES (16, 'Rodrigo Raul', 'Ferreyra', '1989-10-10', 1, '34831908', 1, 1, true, 32, 1, 4, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20348319087', 7.00, 35033.10, 0, 8.00, 1);
INSERT INTO public.personas VALUES (24, 'Norma', 'Poletti', '1967-11-07', 1, '18601061', 2, 1, true, 2, 2, 2, 1, 1, NULL, '1986-09-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27186010618', 7.00, 45948.50, 0, 8.00, 2);
INSERT INTO public.personas VALUES (17, 'Micaela Noemi', 'Frascaroli', '1982-02-27', 1, '29233345', 2, 1, true, 19, 1, 2, 1, 1, NULL, '2003-10-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27292333450', 7.00, 46839.10, 0, 8.00, 2);
INSERT INTO public.personas VALUES (18, 'Betiana Nazareth', 'Gallesio', '1978-01-04', 1, '26167199', 2, 1, true, 21, 1, 2, 1, 1, NULL, '2006-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27261671994', 7.00, 42666.80, 0, 8.00, 2);
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1984-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 42012.00, 0, 8.00, 2);
INSERT INTO public.personas VALUES (25, 'Lautaro', 'Riccardo', '1986-05-29', 1, '32378152', 1, 1, true, 33, 1, 3, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20323781525', 7.00, 34958.80, 0, 8.00, 1);
INSERT INTO public.personas VALUES (26, 'Ana Gladys', 'Romero', '1966-05-04', 1, '18148598', 2, 1, true, 3, 3, 1, 1, 1, NULL, '1986-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27181485987', 7.00, 57061.70, 0, 8.00, 2);


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

INSERT INTO public.recibos VALUES (1637, 1, 8, 44055.41, 0.00, 13657.18, 30398.24, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1638, 2, 9, 52491.28, 0.00, 16272.30, 36218.98, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1639, 3, 10, 79572.58, 0.00, 24667.50, 54905.08, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1640, 4, 11, 30798.63, 0.00, 9547.58, 21251.05, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1641, 5, 12, 43064.40, 0.00, 13349.96, 29714.43, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1642, 6, 13, 85990.67, 0.00, 26657.11, 59333.56, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1643, 7, 14, 20355.00, 0.00, 6310.05, 14044.95, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1644, 8, 15, 79200.00, 0.00, 24552.00, 54648.00, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1645, 9, 16, 42039.72, 0.00, 13032.31, 29007.41, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1646, 10, 17, 65574.74, 0.00, 20328.17, 45246.57, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1647, 11, 18, 61973.53, 0.00, 19211.79, 42761.73, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1648, 12, 19, 78877.53, 0.00, 24452.03, 54425.50, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1649, 13, 20, 58522.98, 0.00, 18142.12, 40380.85, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1650, 14, 21, 45313.22, 0.00, 14047.10, 31266.12, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1651, 15, 22, 17971.76, 0.00, 5571.24, 12400.51, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1652, 16, 23, 52790.40, 0.00, 16365.02, 36425.38, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1653, 17, 24, 83396.53, 0.00, 25852.92, 57543.60, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1654, 18, 25, 41950.56, 0.00, 13004.67, 28945.89, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1655, 19, 26, 99287.36, 0.00, 30779.08, 68508.28, NULL, 103, NULL);
INSERT INTO public.recibos VALUES (1656, 20, 7, 41348.04, 0.00, 12817.89, 28530.15, NULL, 103, NULL);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (6161, 1, 44055.41, 1637);
INSERT INTO public.recibos_acumuladores VALUES (6162, 2, 0.00, 1637);
INSERT INTO public.recibos_acumuladores VALUES (6163, 3, 44055.41, 1637);
INSERT INTO public.recibos_acumuladores VALUES (6164, 4, 0.00, 1637);
INSERT INTO public.recibos_acumuladores VALUES (6165, 5, 13657.18, 1637);
INSERT INTO public.recibos_acumuladores VALUES (6166, 1, 52491.28, 1638);
INSERT INTO public.recibos_acumuladores VALUES (6167, 2, 0.00, 1638);
INSERT INTO public.recibos_acumuladores VALUES (6168, 3, 52491.28, 1638);
INSERT INTO public.recibos_acumuladores VALUES (6169, 4, 0.00, 1638);
INSERT INTO public.recibos_acumuladores VALUES (6170, 5, 16272.30, 1638);
INSERT INTO public.recibos_acumuladores VALUES (6171, 1, 79572.58, 1639);
INSERT INTO public.recibos_acumuladores VALUES (6172, 2, 0.00, 1639);
INSERT INTO public.recibos_acumuladores VALUES (6173, 3, 79572.58, 1639);
INSERT INTO public.recibos_acumuladores VALUES (6174, 4, 0.00, 1639);
INSERT INTO public.recibos_acumuladores VALUES (6175, 5, 24667.50, 1639);
INSERT INTO public.recibos_acumuladores VALUES (6176, 1, 30798.63, 1640);
INSERT INTO public.recibos_acumuladores VALUES (6177, 2, 0.00, 1640);
INSERT INTO public.recibos_acumuladores VALUES (6178, 3, 30798.63, 1640);
INSERT INTO public.recibos_acumuladores VALUES (6179, 4, 0.00, 1640);
INSERT INTO public.recibos_acumuladores VALUES (6180, 5, 9547.58, 1640);
INSERT INTO public.recibos_acumuladores VALUES (6181, 1, 43064.40, 1641);
INSERT INTO public.recibos_acumuladores VALUES (6182, 2, 0.00, 1641);
INSERT INTO public.recibos_acumuladores VALUES (6183, 3, 43064.40, 1641);
INSERT INTO public.recibos_acumuladores VALUES (6184, 4, 0.00, 1641);
INSERT INTO public.recibos_acumuladores VALUES (6185, 5, 13349.96, 1641);
INSERT INTO public.recibos_acumuladores VALUES (6186, 1, 85990.67, 1642);
INSERT INTO public.recibos_acumuladores VALUES (6187, 2, 0.00, 1642);
INSERT INTO public.recibos_acumuladores VALUES (6188, 3, 85990.67, 1642);
INSERT INTO public.recibos_acumuladores VALUES (6189, 4, 0.00, 1642);
INSERT INTO public.recibos_acumuladores VALUES (6190, 5, 26657.11, 1642);
INSERT INTO public.recibos_acumuladores VALUES (6191, 1, 20355.00, 1643);
INSERT INTO public.recibos_acumuladores VALUES (6192, 2, 0.00, 1643);
INSERT INTO public.recibos_acumuladores VALUES (6193, 3, 20355.00, 1643);
INSERT INTO public.recibos_acumuladores VALUES (6194, 4, 0.00, 1643);
INSERT INTO public.recibos_acumuladores VALUES (6195, 5, 6310.05, 1643);
INSERT INTO public.recibos_acumuladores VALUES (6196, 1, 79200.00, 1644);
INSERT INTO public.recibos_acumuladores VALUES (6197, 2, 0.00, 1644);
INSERT INTO public.recibos_acumuladores VALUES (6198, 3, 79200.00, 1644);
INSERT INTO public.recibos_acumuladores VALUES (6199, 4, 0.00, 1644);
INSERT INTO public.recibos_acumuladores VALUES (6200, 5, 24552.00, 1644);
INSERT INTO public.recibos_acumuladores VALUES (6201, 1, 42039.72, 1645);
INSERT INTO public.recibos_acumuladores VALUES (6202, 2, 0.00, 1645);
INSERT INTO public.recibos_acumuladores VALUES (6203, 3, 42039.72, 1645);
INSERT INTO public.recibos_acumuladores VALUES (6204, 4, 0.00, 1645);
INSERT INTO public.recibos_acumuladores VALUES (6205, 5, 13032.31, 1645);
INSERT INTO public.recibos_acumuladores VALUES (6206, 1, 65574.74, 1646);
INSERT INTO public.recibos_acumuladores VALUES (6207, 2, 0.00, 1646);
INSERT INTO public.recibos_acumuladores VALUES (6208, 3, 65574.74, 1646);
INSERT INTO public.recibos_acumuladores VALUES (6209, 4, 0.00, 1646);
INSERT INTO public.recibos_acumuladores VALUES (6210, 5, 20328.17, 1646);
INSERT INTO public.recibos_acumuladores VALUES (6211, 1, 61973.53, 1647);
INSERT INTO public.recibos_acumuladores VALUES (6212, 2, 0.00, 1647);
INSERT INTO public.recibos_acumuladores VALUES (6213, 3, 61973.53, 1647);
INSERT INTO public.recibos_acumuladores VALUES (6214, 4, 0.00, 1647);
INSERT INTO public.recibos_acumuladores VALUES (6215, 5, 19211.79, 1647);
INSERT INTO public.recibos_acumuladores VALUES (6216, 1, 78877.53, 1648);
INSERT INTO public.recibos_acumuladores VALUES (6217, 2, 0.00, 1648);
INSERT INTO public.recibos_acumuladores VALUES (6218, 3, 78877.53, 1648);
INSERT INTO public.recibos_acumuladores VALUES (6219, 4, 0.00, 1648);
INSERT INTO public.recibos_acumuladores VALUES (6220, 5, 24452.03, 1648);
INSERT INTO public.recibos_acumuladores VALUES (6221, 1, 58522.98, 1649);
INSERT INTO public.recibos_acumuladores VALUES (6222, 2, 0.00, 1649);
INSERT INTO public.recibos_acumuladores VALUES (6223, 3, 58522.98, 1649);
INSERT INTO public.recibos_acumuladores VALUES (6224, 4, 0.00, 1649);
INSERT INTO public.recibos_acumuladores VALUES (6225, 5, 18142.12, 1649);
INSERT INTO public.recibos_acumuladores VALUES (6226, 1, 45313.22, 1650);
INSERT INTO public.recibos_acumuladores VALUES (6227, 2, 0.00, 1650);
INSERT INTO public.recibos_acumuladores VALUES (6228, 3, 45313.22, 1650);
INSERT INTO public.recibos_acumuladores VALUES (6229, 4, 0.00, 1650);
INSERT INTO public.recibos_acumuladores VALUES (6230, 5, 14047.10, 1650);
INSERT INTO public.recibos_acumuladores VALUES (6231, 1, 17971.76, 1651);
INSERT INTO public.recibos_acumuladores VALUES (6232, 2, 0.00, 1651);
INSERT INTO public.recibos_acumuladores VALUES (6233, 3, 17971.76, 1651);
INSERT INTO public.recibos_acumuladores VALUES (6234, 4, 0.00, 1651);
INSERT INTO public.recibos_acumuladores VALUES (6235, 5, 5571.24, 1651);
INSERT INTO public.recibos_acumuladores VALUES (6236, 1, 52790.40, 1652);
INSERT INTO public.recibos_acumuladores VALUES (6237, 2, 0.00, 1652);
INSERT INTO public.recibos_acumuladores VALUES (6238, 3, 52790.40, 1652);
INSERT INTO public.recibos_acumuladores VALUES (6239, 4, 0.00, 1652);
INSERT INTO public.recibos_acumuladores VALUES (6240, 5, 16365.02, 1652);
INSERT INTO public.recibos_acumuladores VALUES (6241, 1, 83396.53, 1653);
INSERT INTO public.recibos_acumuladores VALUES (6242, 2, 0.00, 1653);
INSERT INTO public.recibos_acumuladores VALUES (6243, 3, 83396.53, 1653);
INSERT INTO public.recibos_acumuladores VALUES (6244, 4, 0.00, 1653);
INSERT INTO public.recibos_acumuladores VALUES (6245, 5, 25852.92, 1653);
INSERT INTO public.recibos_acumuladores VALUES (6246, 1, 41950.56, 1654);
INSERT INTO public.recibos_acumuladores VALUES (6247, 2, 0.00, 1654);
INSERT INTO public.recibos_acumuladores VALUES (6248, 3, 41950.56, 1654);
INSERT INTO public.recibos_acumuladores VALUES (6249, 4, 0.00, 1654);
INSERT INTO public.recibos_acumuladores VALUES (6250, 5, 13004.67, 1654);
INSERT INTO public.recibos_acumuladores VALUES (6251, 1, 99287.36, 1655);
INSERT INTO public.recibos_acumuladores VALUES (6252, 2, 0.00, 1655);
INSERT INTO public.recibos_acumuladores VALUES (6253, 3, 99287.36, 1655);
INSERT INTO public.recibos_acumuladores VALUES (6254, 4, 0.00, 1655);
INSERT INTO public.recibos_acumuladores VALUES (6255, 5, 30779.08, 1655);
INSERT INTO public.recibos_acumuladores VALUES (6256, 1, 41348.04, 1656);
INSERT INTO public.recibos_acumuladores VALUES (6257, 2, 0.00, 1656);
INSERT INTO public.recibos_acumuladores VALUES (6258, 3, 41348.04, 1656);
INSERT INTO public.recibos_acumuladores VALUES (6259, 4, 0.00, 1656);
INSERT INTO public.recibos_acumuladores VALUES (6260, 5, 12817.89, 1656);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 6260, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (47921, 14, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47922, 16, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47935, 29, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47938, 30, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47952, 45, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47962, 14, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47963, 16, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47976, 29, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47979, 30, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (48003, 14, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48004, 16, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48017, 29, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48020, 30, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48044, 14, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48045, 16, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48058, 29, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48061, 30, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48085, 14, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48086, 16, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (47992, 43, 2257.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47993, 45, 4216.80, 1638);
INSERT INTO public.recibos_conceptos VALUES (47913, 1, 34351.20, 1637);
INSERT INTO public.recibos_conceptos VALUES (47914, 7, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47915, 42, 772.90, 1637);
INSERT INTO public.recibos_conceptos VALUES (47916, 12, 3435.12, 1637);
INSERT INTO public.recibos_conceptos VALUES (47917, 4, 34351.20, 1637);
INSERT INTO public.recibos_conceptos VALUES (47918, 5, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47919, 6, 5496.19, 1637);
INSERT INTO public.recibos_conceptos VALUES (48099, 29, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48102, 30, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48126, 14, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48127, 16, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48140, 29, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48143, 30, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48167, 14, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48168, 16, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48181, 29, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48184, 30, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48208, 14, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48209, 16, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48222, 29, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48225, 30, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48249, 14, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48250, 16, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48263, 29, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48266, 30, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48098, 26, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48100, 27, 42924.50, 1641);
INSERT INTO public.recibos_conceptos VALUES (48101, 28, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48103, 31, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48104, 33, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48105, 34, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48106, 35, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48107, 36, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48108, 37, 288979.06, 1641);
INSERT INTO public.recibos_conceptos VALUES (48109, 38, -251423.32, 1641);
INSERT INTO public.recibos_conceptos VALUES (48110, 40, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48111, 9, 1291.93, 1641);
INSERT INTO public.recibos_conceptos VALUES (48112, 10, 1291.93, 1641);
INSERT INTO public.recibos_conceptos VALUES (48290, 14, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48291, 16, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48304, 29, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48307, 30, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48331, 14, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48332, 16, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48345, 29, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48348, 30, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48369, 5, 3.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48372, 14, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48373, 16, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48386, 29, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48389, 30, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48413, 14, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48414, 16, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48427, 29, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48430, 30, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48454, 14, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48455, 16, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48283, 7, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48284, 42, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48285, 12, 4683.91, 1646);
INSERT INTO public.recibos_conceptos VALUES (48286, 4, 46839.10, 1646);
INSERT INTO public.recibos_conceptos VALUES (48287, 5, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48288, 6, 14051.73, 1646);
INSERT INTO public.recibos_conceptos VALUES (48289, 13, 5464.56, 1646);
INSERT INTO public.recibos_conceptos VALUES (48292, 15, 71039.30, 1646);
INSERT INTO public.recibos_conceptos VALUES (48293, 17, 7814.32, 1646);
INSERT INTO public.recibos_conceptos VALUES (48294, 18, 2131.18, 1646);
INSERT INTO public.recibos_conceptos VALUES (48468, 29, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48471, 30, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48495, 14, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48496, 16, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48509, 29, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48512, 30, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48536, 14, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48537, 16, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48550, 29, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48553, 30, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48577, 14, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48578, 16, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48591, 29, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48594, 30, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48618, 14, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48619, 16, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48632, 29, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48635, 30, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48469, 27, 42924.50, 1650);
INSERT INTO public.recibos_conceptos VALUES (48470, 28, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48472, 31, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48473, 33, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48474, 34, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48475, 35, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48476, 36, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48477, 37, 248962.07, 1650);
INSERT INTO public.recibos_conceptos VALUES (48478, 38, -209445.17, 1650);
INSERT INTO public.recibos_conceptos VALUES (48479, 40, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48480, 9, 1359.40, 1650);
INSERT INTO public.recibos_conceptos VALUES (48481, 10, 1359.40, 1650);
INSERT INTO public.recibos_conceptos VALUES (48482, 11, 11328.30, 1650);
INSERT INTO public.recibos_conceptos VALUES (48659, 14, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48660, 16, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48673, 29, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48676, 30, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48700, 14, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48701, 16, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48714, 29, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48717, 30, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48033, 43, 3615.23, 1639);
INSERT INTO public.recibos_conceptos VALUES (48034, 45, 7114.91, 1639);
INSERT INTO public.recibos_conceptos VALUES (48074, 43, 1294.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48115, 43, 1918.37, 1641);
INSERT INTO public.recibos_conceptos VALUES (48117, 44, 3219.73, 1641);
INSERT INTO public.recibos_conceptos VALUES (48156, 43, 3825.35, 1642);
INSERT INTO public.recibos_conceptos VALUES (48157, 45, 4102.65, 1642);
INSERT INTO public.recibos_conceptos VALUES (48158, 44, 3219.73, 1642);
INSERT INTO public.recibos_conceptos VALUES (48197, 43, 2491.76, 1643);
INSERT INTO public.recibos_conceptos VALUES (48238, 43, 1475.72, 1644);
INSERT INTO public.recibos_conceptos VALUES (48279, 43, 1772.88, 1645);
INSERT INTO public.recibos_conceptos VALUES (48320, 43, 3077.41, 1646);
INSERT INTO public.recibos_conceptos VALUES (48321, 45, 4554.36, 1646);
INSERT INTO public.recibos_conceptos VALUES (48322, 44, 3219.73, 1646);
INSERT INTO public.recibos_conceptos VALUES (48361, 43, 2550.86, 1647);
INSERT INTO public.recibos_conceptos VALUES (48362, 45, 5903.89, 1647);
INSERT INTO public.recibos_conceptos VALUES (48402, 43, 3066.64, 1648);
INSERT INTO public.recibos_conceptos VALUES (48403, 45, 1417.38, 1648);
INSERT INTO public.recibos_conceptos VALUES (48404, 44, 3219.79, 1648);
INSERT INTO public.recibos_conceptos VALUES (48443, 43, 2536.36, 1649);
INSERT INTO public.recibos_conceptos VALUES (48444, 45, 5589.81, 1649);
INSERT INTO public.recibos_conceptos VALUES (48484, 43, 1900.17, 1650);
INSERT INTO public.recibos_conceptos VALUES (48525, 43, 759.05, 1651);
INSERT INTO public.recibos_conceptos VALUES (48566, 43, 2305.45, 1652);
INSERT INTO public.recibos_conceptos VALUES (48568, 44, 3219.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48607, 43, 4395.26, 1653);
INSERT INTO public.recibos_conceptos VALUES (48608, 45, 9601.68, 1653);
INSERT INTO public.recibos_conceptos VALUES (48648, 43, 1769.12, 1654);
INSERT INTO public.recibos_conceptos VALUES (48689, 43, 4969.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48690, 45, 16956.60, 1655);
INSERT INTO public.recibos_conceptos VALUES (48691, 44, 3219.73, 1655);
INSERT INTO public.recibos_conceptos VALUES (48730, 43, 2270.71, 1656);
INSERT INTO public.recibos_conceptos VALUES (47920, 13, 3671.28, 1637);
INSERT INTO public.recibos_conceptos VALUES (47923, 15, 47726.70, 1637);
INSERT INTO public.recibos_conceptos VALUES (47924, 17, 5249.94, 1637);
INSERT INTO public.recibos_conceptos VALUES (47925, 18, 1431.80, 1637);
INSERT INTO public.recibos_conceptos VALUES (47926, 19, 1431.80, 1637);
INSERT INTO public.recibos_conceptos VALUES (47927, 20, 1193.17, 1637);
INSERT INTO public.recibos_conceptos VALUES (47928, 21, 9306.71, 1637);
INSERT INTO public.recibos_conceptos VALUES (47929, 22, 38419.99, 1637);
INSERT INTO public.recibos_conceptos VALUES (47930, 23, 38419.99, 1637);
INSERT INTO public.recibos_conceptos VALUES (47931, 32, 1921.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47932, 24, 206037.57, 1637);
INSERT INTO public.recibos_conceptos VALUES (47933, 25, 40016.99, 1637);
INSERT INTO public.recibos_conceptos VALUES (47934, 26, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47936, 27, 42924.50, 1637);
INSERT INTO public.recibos_conceptos VALUES (47937, 28, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47939, 31, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47940, 33, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47941, 34, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47942, 35, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47943, 36, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47944, 37, 288979.06, 1637);
INSERT INTO public.recibos_conceptos VALUES (47945, 38, -250559.07, 1637);
INSERT INTO public.recibos_conceptos VALUES (47946, 40, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47947, 9, 1321.66, 1637);
INSERT INTO public.recibos_conceptos VALUES (47948, 10, 1321.66, 1637);
INSERT INTO public.recibos_conceptos VALUES (47949, 11, 11013.85, 1637);
INSERT INTO public.recibos_conceptos VALUES (47950, 39, 0.00, 1637);
INSERT INTO public.recibos_conceptos VALUES (47954, 1, 41008.81, 1638);
INSERT INTO public.recibos_conceptos VALUES (47955, 7, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47956, 42, 2460.53, 1638);
INSERT INTO public.recibos_conceptos VALUES (47957, 12, 4100.88, 1638);
INSERT INTO public.recibos_conceptos VALUES (47958, 4, 41008.81, 1638);
INSERT INTO public.recibos_conceptos VALUES (47959, 5, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47960, 6, 4921.06, 1638);
INSERT INTO public.recibos_conceptos VALUES (47961, 13, 4374.27, 1638);
INSERT INTO public.recibos_conceptos VALUES (47964, 15, 56865.55, 1638);
INSERT INTO public.recibos_conceptos VALUES (47965, 17, 6255.21, 1638);
INSERT INTO public.recibos_conceptos VALUES (47966, 18, 1705.97, 1638);
INSERT INTO public.recibos_conceptos VALUES (47967, 19, 1705.97, 1638);
INSERT INTO public.recibos_conceptos VALUES (47968, 20, 1421.64, 1638);
INSERT INTO public.recibos_conceptos VALUES (47969, 21, 11088.78, 1638);
INSERT INTO public.recibos_conceptos VALUES (47970, 22, 45776.77, 1638);
INSERT INTO public.recibos_conceptos VALUES (47971, 23, 45776.77, 1638);
INSERT INTO public.recibos_conceptos VALUES (47972, 32, 2288.84, 1638);
INSERT INTO public.recibos_conceptos VALUES (47973, 24, 206037.57, 1638);
INSERT INTO public.recibos_conceptos VALUES (47974, 25, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47975, 26, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47977, 27, 42924.50, 1638);
INSERT INTO public.recibos_conceptos VALUES (47978, 28, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47980, 31, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47981, 33, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47982, 34, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47983, 35, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47984, 36, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47985, 37, 248962.07, 1638);
INSERT INTO public.recibos_conceptos VALUES (47986, 38, -203185.30, 1638);
INSERT INTO public.recibos_conceptos VALUES (47987, 40, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47988, 9, 1574.74, 1638);
INSERT INTO public.recibos_conceptos VALUES (47989, 10, 1574.74, 1638);
INSERT INTO public.recibos_conceptos VALUES (47990, 11, 13122.82, 1638);
INSERT INTO public.recibos_conceptos VALUES (48653, 42, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48654, 12, 5706.17, 1655);
INSERT INTO public.recibos_conceptos VALUES (48655, 4, 57061.70, 1655);
INSERT INTO public.recibos_conceptos VALUES (48656, 5, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48657, 6, 36519.49, 1655);
INSERT INTO public.recibos_conceptos VALUES (47991, 39, 0.00, 1638);
INSERT INTO public.recibos_conceptos VALUES (47995, 1, 46807.40, 1639);
INSERT INTO public.recibos_conceptos VALUES (47996, 7, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (47997, 42, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (47998, 12, 4680.74, 1639);
INSERT INTO public.recibos_conceptos VALUES (47999, 4, 46807.40, 1639);
INSERT INTO public.recibos_conceptos VALUES (48000, 5, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48001, 6, 28084.44, 1639);
INSERT INTO public.recibos_conceptos VALUES (48002, 13, 6631.05, 1639);
INSERT INTO public.recibos_conceptos VALUES (48005, 15, 86203.63, 1639);
INSERT INTO public.recibos_conceptos VALUES (48006, 17, 9482.40, 1639);
INSERT INTO public.recibos_conceptos VALUES (48007, 18, 2586.11, 1639);
INSERT INTO public.recibos_conceptos VALUES (48008, 19, 2586.11, 1639);
INSERT INTO public.recibos_conceptos VALUES (48009, 20, 2155.09, 1639);
INSERT INTO public.recibos_conceptos VALUES (48010, 21, 16809.71, 1639);
INSERT INTO public.recibos_conceptos VALUES (48011, 22, 69393.92, 1639);
INSERT INTO public.recibos_conceptos VALUES (48012, 23, 69393.92, 1639);
INSERT INTO public.recibos_conceptos VALUES (48013, 32, 3469.70, 1639);
INSERT INTO public.recibos_conceptos VALUES (48014, 24, 206037.57, 1639);
INSERT INTO public.recibos_conceptos VALUES (48015, 25, 40016.99, 1639);
INSERT INTO public.recibos_conceptos VALUES (48016, 26, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48018, 27, 42924.50, 1639);
INSERT INTO public.recibos_conceptos VALUES (48019, 28, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48021, 31, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48022, 33, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48023, 34, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48024, 35, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48025, 36, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48026, 37, 288979.06, 1639);
INSERT INTO public.recibos_conceptos VALUES (48027, 38, -219585.14, 1639);
INSERT INTO public.recibos_conceptos VALUES (48028, 40, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48029, 9, 2387.18, 1639);
INSERT INTO public.recibos_conceptos VALUES (48030, 10, 2387.18, 1639);
INSERT INTO public.recibos_conceptos VALUES (48031, 11, 19893.15, 1639);
INSERT INTO public.recibos_conceptos VALUES (48032, 39, 0.00, 1639);
INSERT INTO public.recibos_conceptos VALUES (48036, 1, 24061.43, 1640);
INSERT INTO public.recibos_conceptos VALUES (48037, 7, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48038, 42, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48039, 12, 2406.14, 1640);
INSERT INTO public.recibos_conceptos VALUES (48040, 4, 24061.43, 1640);
INSERT INTO public.recibos_conceptos VALUES (48041, 5, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48042, 6, 4331.06, 1640);
INSERT INTO public.recibos_conceptos VALUES (48043, 13, 2566.55, 1640);
INSERT INTO public.recibos_conceptos VALUES (48046, 15, 33365.18, 1640);
INSERT INTO public.recibos_conceptos VALUES (48047, 17, 3670.17, 1640);
INSERT INTO public.recibos_conceptos VALUES (48048, 18, 1000.96, 1640);
INSERT INTO public.recibos_conceptos VALUES (48049, 19, 1000.96, 1640);
INSERT INTO public.recibos_conceptos VALUES (48050, 20, 834.13, 1640);
INSERT INTO public.recibos_conceptos VALUES (48051, 21, 6506.21, 1640);
INSERT INTO public.recibos_conceptos VALUES (48052, 22, 26858.97, 1640);
INSERT INTO public.recibos_conceptos VALUES (48053, 23, 26858.97, 1640);
INSERT INTO public.recibos_conceptos VALUES (48054, 32, 1342.95, 1640);
INSERT INTO public.recibos_conceptos VALUES (48055, 24, 206037.57, 1640);
INSERT INTO public.recibos_conceptos VALUES (48056, 25, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48057, 26, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48059, 27, 42924.50, 1640);
INSERT INTO public.recibos_conceptos VALUES (48060, 28, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48062, 31, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48063, 33, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48064, 34, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48065, 35, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48066, 36, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48067, 37, 248962.07, 1640);
INSERT INTO public.recibos_conceptos VALUES (48068, 38, -222103.10, 1640);
INSERT INTO public.recibos_conceptos VALUES (48069, 40, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48070, 9, 923.96, 1640);
INSERT INTO public.recibos_conceptos VALUES (48071, 10, 923.96, 1640);
INSERT INTO public.recibos_conceptos VALUES (48072, 11, 7699.66, 1640);
INSERT INTO public.recibos_conceptos VALUES (48073, 39, 0.00, 1640);
INSERT INTO public.recibos_conceptos VALUES (48077, 1, 35226.50, 1641);
INSERT INTO public.recibos_conceptos VALUES (48078, 7, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48079, 42, 792.60, 1641);
INSERT INTO public.recibos_conceptos VALUES (48080, 12, 3522.65, 1641);
INSERT INTO public.recibos_conceptos VALUES (48081, 4, 35226.50, 1641);
INSERT INTO public.recibos_conceptos VALUES (48082, 5, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48083, 6, 3522.65, 1641);
INSERT INTO public.recibos_conceptos VALUES (48084, 13, 3588.70, 1641);
INSERT INTO public.recibos_conceptos VALUES (48087, 15, 46653.10, 1641);
INSERT INTO public.recibos_conceptos VALUES (48088, 17, 5131.84, 1641);
INSERT INTO public.recibos_conceptos VALUES (48089, 18, 1399.59, 1641);
INSERT INTO public.recibos_conceptos VALUES (48090, 19, 1399.59, 1641);
INSERT INTO public.recibos_conceptos VALUES (48091, 20, 1166.33, 1641);
INSERT INTO public.recibos_conceptos VALUES (48092, 21, 9097.35, 1641);
INSERT INTO public.recibos_conceptos VALUES (48093, 22, 37555.74, 1641);
INSERT INTO public.recibos_conceptos VALUES (48094, 23, 37555.74, 1641);
INSERT INTO public.recibos_conceptos VALUES (48095, 32, 1877.79, 1641);
INSERT INTO public.recibos_conceptos VALUES (48096, 24, 206037.57, 1641);
INSERT INTO public.recibos_conceptos VALUES (48097, 25, 40016.99, 1641);
INSERT INTO public.recibos_conceptos VALUES (48113, 11, 10766.10, 1641);
INSERT INTO public.recibos_conceptos VALUES (48114, 39, 0.00, 1641);
INSERT INTO public.recibos_conceptos VALUES (48118, 1, 48582.30, 1642);
INSERT INTO public.recibos_conceptos VALUES (48119, 7, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48120, 42, 1457.47, 1642);
INSERT INTO public.recibos_conceptos VALUES (48121, 12, 4858.23, 1642);
INSERT INTO public.recibos_conceptos VALUES (48122, 4, 48582.30, 1642);
INSERT INTO public.recibos_conceptos VALUES (48123, 5, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48124, 6, 31092.67, 1642);
INSERT INTO public.recibos_conceptos VALUES (48125, 13, 7165.89, 1642);
INSERT INTO public.recibos_conceptos VALUES (48128, 15, 93156.56, 1642);
INSERT INTO public.recibos_conceptos VALUES (48129, 17, 10247.22, 1642);
INSERT INTO public.recibos_conceptos VALUES (48130, 18, 2794.70, 1642);
INSERT INTO public.recibos_conceptos VALUES (48131, 19, 2794.70, 1642);
INSERT INTO public.recibos_conceptos VALUES (48132, 20, 2328.91, 1642);
INSERT INTO public.recibos_conceptos VALUES (48133, 21, 18165.53, 1642);
INSERT INTO public.recibos_conceptos VALUES (48134, 22, 74991.03, 1642);
INSERT INTO public.recibos_conceptos VALUES (48135, 23, 74991.03, 1642);
INSERT INTO public.recibos_conceptos VALUES (48136, 32, 3749.55, 1642);
INSERT INTO public.recibos_conceptos VALUES (48137, 24, 206037.57, 1642);
INSERT INTO public.recibos_conceptos VALUES (48138, 25, 40016.99, 1642);
INSERT INTO public.recibos_conceptos VALUES (48139, 26, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48141, 27, 42924.50, 1642);
INSERT INTO public.recibos_conceptos VALUES (48142, 28, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48144, 31, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48145, 33, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48146, 34, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48147, 35, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48148, 36, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48149, 37, 288979.06, 1642);
INSERT INTO public.recibos_conceptos VALUES (48150, 38, -213988.03, 1642);
INSERT INTO public.recibos_conceptos VALUES (48151, 40, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48152, 9, 2579.72, 1642);
INSERT INTO public.recibos_conceptos VALUES (48153, 10, 2579.72, 1642);
INSERT INTO public.recibos_conceptos VALUES (48154, 11, 21497.67, 1642);
INSERT INTO public.recibos_conceptos VALUES (48155, 39, 0.00, 1642);
INSERT INTO public.recibos_conceptos VALUES (48159, 1, 17250.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48160, 7, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48161, 42, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48162, 12, 1725.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48163, 4, 17250.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48164, 5, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48165, 6, 1380.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48166, 13, 1696.25, 1643);
INSERT INTO public.recibos_conceptos VALUES (48169, 15, 22051.25, 1643);
INSERT INTO public.recibos_conceptos VALUES (48170, 17, 2425.64, 1643);
INSERT INTO public.recibos_conceptos VALUES (48171, 18, 661.54, 1643);
INSERT INTO public.recibos_conceptos VALUES (48172, 19, 661.54, 1643);
INSERT INTO public.recibos_conceptos VALUES (48173, 20, 551.28, 1643);
INSERT INTO public.recibos_conceptos VALUES (48174, 21, 4299.99, 1643);
INSERT INTO public.recibos_conceptos VALUES (48175, 22, 17751.26, 1643);
INSERT INTO public.recibos_conceptos VALUES (48176, 23, 17751.26, 1643);
INSERT INTO public.recibos_conceptos VALUES (48177, 32, 887.56, 1643);
INSERT INTO public.recibos_conceptos VALUES (48178, 24, 206037.57, 1643);
INSERT INTO public.recibos_conceptos VALUES (48179, 25, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48180, 26, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48182, 27, 42924.50, 1643);
INSERT INTO public.recibos_conceptos VALUES (48183, 28, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48185, 31, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48186, 33, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48187, 34, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48188, 35, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48189, 36, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48190, 37, 248962.07, 1643);
INSERT INTO public.recibos_conceptos VALUES (48191, 38, -231210.81, 1643);
INSERT INTO public.recibos_conceptos VALUES (48192, 40, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48193, 9, 610.65, 1643);
INSERT INTO public.recibos_conceptos VALUES (48194, 10, 610.65, 1643);
INSERT INTO public.recibos_conceptos VALUES (48195, 11, 5088.75, 1643);
INSERT INTO public.recibos_conceptos VALUES (48196, 39, 0.00, 1643);
INSERT INTO public.recibos_conceptos VALUES (48200, 1, 60000.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48201, 7, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48202, 42, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48203, 12, 6000.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48204, 4, 60000.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48205, 5, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48206, 6, 13200.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48207, 13, 6600.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48210, 15, 85800.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48211, 17, 9438.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48212, 18, 2574.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48213, 19, 2574.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48214, 20, 2145.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48215, 21, 16731.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48216, 22, 69069.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48217, 23, 69069.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48218, 32, 3453.45, 1644);
INSERT INTO public.recibos_conceptos VALUES (48219, 24, 206037.57, 1644);
INSERT INTO public.recibos_conceptos VALUES (48220, 25, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48221, 26, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48223, 27, 42924.50, 1644);
INSERT INTO public.recibos_conceptos VALUES (48224, 28, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48226, 31, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48227, 33, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48228, 34, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48229, 35, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48230, 36, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48231, 37, 248962.07, 1644);
INSERT INTO public.recibos_conceptos VALUES (48232, 38, -179893.07, 1644);
INSERT INTO public.recibos_conceptos VALUES (48233, 40, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48234, 9, 2376.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48235, 10, 2376.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48236, 11, 19800.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48237, 39, 0.00, 1644);
INSERT INTO public.recibos_conceptos VALUES (48241, 1, 35033.10, 1645);
INSERT INTO public.recibos_conceptos VALUES (48242, 7, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48243, 42, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48244, 12, 3503.31, 1645);
INSERT INTO public.recibos_conceptos VALUES (48245, 4, 35033.10, 1645);
INSERT INTO public.recibos_conceptos VALUES (48246, 5, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48247, 6, 3503.31, 1645);
INSERT INTO public.recibos_conceptos VALUES (48248, 13, 3503.31, 1645);
INSERT INTO public.recibos_conceptos VALUES (48251, 15, 45543.03, 1645);
INSERT INTO public.recibos_conceptos VALUES (48252, 17, 5009.73, 1645);
INSERT INTO public.recibos_conceptos VALUES (48253, 18, 1366.29, 1645);
INSERT INTO public.recibos_conceptos VALUES (48254, 19, 1366.29, 1645);
INSERT INTO public.recibos_conceptos VALUES (48255, 20, 1138.58, 1645);
INSERT INTO public.recibos_conceptos VALUES (48256, 21, 8880.89, 1645);
INSERT INTO public.recibos_conceptos VALUES (48257, 22, 36662.14, 1645);
INSERT INTO public.recibos_conceptos VALUES (48258, 23, 36662.14, 1645);
INSERT INTO public.recibos_conceptos VALUES (48259, 32, 1833.11, 1645);
INSERT INTO public.recibos_conceptos VALUES (48260, 24, 206037.57, 1645);
INSERT INTO public.recibos_conceptos VALUES (48261, 25, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48262, 26, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48264, 27, 42924.50, 1645);
INSERT INTO public.recibos_conceptos VALUES (48265, 28, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48267, 31, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48268, 33, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48269, 34, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48270, 35, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48271, 36, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48272, 37, 248962.07, 1645);
INSERT INTO public.recibos_conceptos VALUES (48273, 38, -212299.93, 1645);
INSERT INTO public.recibos_conceptos VALUES (48274, 40, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48275, 9, 1261.19, 1645);
INSERT INTO public.recibos_conceptos VALUES (48276, 10, 1261.19, 1645);
INSERT INTO public.recibos_conceptos VALUES (48277, 11, 10509.93, 1645);
INSERT INTO public.recibos_conceptos VALUES (48278, 39, 0.00, 1645);
INSERT INTO public.recibos_conceptos VALUES (48282, 1, 46839.10, 1646);
INSERT INTO public.recibos_conceptos VALUES (48295, 19, 2131.18, 1646);
INSERT INTO public.recibos_conceptos VALUES (48296, 20, 1775.98, 1646);
INSERT INTO public.recibos_conceptos VALUES (48297, 21, 13852.66, 1646);
INSERT INTO public.recibos_conceptos VALUES (48298, 22, 57186.64, 1646);
INSERT INTO public.recibos_conceptos VALUES (48299, 23, 57186.64, 1646);
INSERT INTO public.recibos_conceptos VALUES (48300, 32, 2859.33, 1646);
INSERT INTO public.recibos_conceptos VALUES (48301, 24, 206037.57, 1646);
INSERT INTO public.recibos_conceptos VALUES (48302, 25, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48303, 26, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48305, 27, 42924.50, 1646);
INSERT INTO public.recibos_conceptos VALUES (48306, 28, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48308, 31, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48309, 33, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48310, 34, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48311, 35, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48312, 36, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48313, 37, 248962.07, 1646);
INSERT INTO public.recibos_conceptos VALUES (48314, 38, -191775.43, 1646);
INSERT INTO public.recibos_conceptos VALUES (48315, 40, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48316, 9, 1967.24, 1646);
INSERT INTO public.recibos_conceptos VALUES (48317, 10, 1967.24, 1646);
INSERT INTO public.recibos_conceptos VALUES (48318, 11, 16393.69, 1646);
INSERT INTO public.recibos_conceptos VALUES (48319, 39, 0.00, 1646);
INSERT INTO public.recibos_conceptos VALUES (48323, 1, 42666.80, 1647);
INSERT INTO public.recibos_conceptos VALUES (48324, 7, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48325, 42, 4800.02, 1647);
INSERT INTO public.recibos_conceptos VALUES (48326, 12, 4266.68, 1647);
INSERT INTO public.recibos_conceptos VALUES (48327, 4, 42666.80, 1647);
INSERT INTO public.recibos_conceptos VALUES (48328, 5, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48329, 6, 10240.03, 1647);
INSERT INTO public.recibos_conceptos VALUES (48330, 13, 5164.46, 1647);
INSERT INTO public.recibos_conceptos VALUES (48333, 15, 67137.99, 1647);
INSERT INTO public.recibos_conceptos VALUES (48334, 17, 7385.18, 1647);
INSERT INTO public.recibos_conceptos VALUES (48335, 18, 2014.14, 1647);
INSERT INTO public.recibos_conceptos VALUES (48336, 19, 2014.14, 1647);
INSERT INTO public.recibos_conceptos VALUES (48337, 20, 1678.45, 1647);
INSERT INTO public.recibos_conceptos VALUES (48338, 21, 13091.91, 1647);
INSERT INTO public.recibos_conceptos VALUES (48339, 22, 54046.08, 1647);
INSERT INTO public.recibos_conceptos VALUES (48340, 23, 54046.08, 1647);
INSERT INTO public.recibos_conceptos VALUES (48341, 32, 2702.30, 1647);
INSERT INTO public.recibos_conceptos VALUES (48342, 24, 206037.57, 1647);
INSERT INTO public.recibos_conceptos VALUES (48343, 25, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48344, 26, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48346, 27, 42924.50, 1647);
INSERT INTO public.recibos_conceptos VALUES (48347, 28, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48349, 31, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48350, 33, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48351, 34, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48352, 35, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48353, 36, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48354, 37, 248962.07, 1647);
INSERT INTO public.recibos_conceptos VALUES (48355, 38, -194915.99, 1647);
INSERT INTO public.recibos_conceptos VALUES (48356, 40, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48357, 9, 1859.21, 1647);
INSERT INTO public.recibos_conceptos VALUES (48358, 10, 1859.21, 1647);
INSERT INTO public.recibos_conceptos VALUES (48359, 11, 15493.38, 1647);
INSERT INTO public.recibos_conceptos VALUES (48360, 39, 0.00, 1647);
INSERT INTO public.recibos_conceptos VALUES (48364, 1, 42012.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48365, 7, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48366, 42, 1575.45, 1648);
INSERT INTO public.recibos_conceptos VALUES (48367, 12, 4201.20, 1648);
INSERT INTO public.recibos_conceptos VALUES (48368, 4, 42012.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48370, 6, 31088.88, 1648);
INSERT INTO public.recibos_conceptos VALUES (48371, 13, 6573.13, 1648);
INSERT INTO public.recibos_conceptos VALUES (48374, 15, 85450.66, 1648);
INSERT INTO public.recibos_conceptos VALUES (48375, 17, 9399.57, 1648);
INSERT INTO public.recibos_conceptos VALUES (48376, 18, 2563.52, 1648);
INSERT INTO public.recibos_conceptos VALUES (48377, 19, 2563.52, 1648);
INSERT INTO public.recibos_conceptos VALUES (48378, 20, 2136.27, 1648);
INSERT INTO public.recibos_conceptos VALUES (48379, 21, 16662.88, 1648);
INSERT INTO public.recibos_conceptos VALUES (48380, 22, 68787.78, 1648);
INSERT INTO public.recibos_conceptos VALUES (48381, 23, 68787.78, 1648);
INSERT INTO public.recibos_conceptos VALUES (48382, 32, 3439.39, 1648);
INSERT INTO public.recibos_conceptos VALUES (48383, 24, 206037.57, 1648);
INSERT INTO public.recibos_conceptos VALUES (48384, 25, 40016.99, 1648);
INSERT INTO public.recibos_conceptos VALUES (48385, 26, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48387, 27, 42924.50, 1648);
INSERT INTO public.recibos_conceptos VALUES (48388, 28, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48390, 31, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48391, 33, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48392, 34, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48393, 35, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48394, 36, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48395, 37, 288979.06, 1648);
INSERT INTO public.recibos_conceptos VALUES (48396, 38, -220191.28, 1648);
INSERT INTO public.recibos_conceptos VALUES (48397, 40, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48398, 9, 2366.33, 1648);
INSERT INTO public.recibos_conceptos VALUES (48399, 10, 2366.33, 1648);
INSERT INTO public.recibos_conceptos VALUES (48400, 11, 19719.38, 1648);
INSERT INTO public.recibos_conceptos VALUES (48401, 39, 0.00, 1648);
INSERT INTO public.recibos_conceptos VALUES (48405, 1, 42717.50, 1649);
INSERT INTO public.recibos_conceptos VALUES (48406, 7, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48407, 42, 3844.58, 1649);
INSERT INTO public.recibos_conceptos VALUES (48408, 12, 4271.75, 1649);
INSERT INTO public.recibos_conceptos VALUES (48409, 4, 42717.50, 1649);
INSERT INTO public.recibos_conceptos VALUES (48410, 5, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48411, 6, 7689.15, 1649);
INSERT INTO public.recibos_conceptos VALUES (48412, 13, 4876.91, 1649);
INSERT INTO public.recibos_conceptos VALUES (48415, 15, 63399.89, 1649);
INSERT INTO public.recibos_conceptos VALUES (48416, 17, 6973.99, 1649);
INSERT INTO public.recibos_conceptos VALUES (48417, 18, 1902.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48418, 19, 1902.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48419, 20, 1585.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48420, 21, 12362.98, 1649);
INSERT INTO public.recibos_conceptos VALUES (48421, 22, 51036.91, 1649);
INSERT INTO public.recibos_conceptos VALUES (48422, 23, 51036.91, 1649);
INSERT INTO public.recibos_conceptos VALUES (48423, 32, 2551.85, 1649);
INSERT INTO public.recibos_conceptos VALUES (48424, 24, 206037.57, 1649);
INSERT INTO public.recibos_conceptos VALUES (48425, 25, 40016.99, 1649);
INSERT INTO public.recibos_conceptos VALUES (48426, 26, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48428, 27, 42924.50, 1649);
INSERT INTO public.recibos_conceptos VALUES (48429, 28, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48431, 31, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48432, 33, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48433, 34, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48434, 35, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48435, 36, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48436, 37, 288979.06, 1649);
INSERT INTO public.recibos_conceptos VALUES (48437, 38, -237942.15, 1649);
INSERT INTO public.recibos_conceptos VALUES (48438, 40, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48439, 9, 1755.69, 1649);
INSERT INTO public.recibos_conceptos VALUES (48440, 10, 1755.69, 1649);
INSERT INTO public.recibos_conceptos VALUES (48441, 11, 14630.74, 1649);
INSERT INTO public.recibos_conceptos VALUES (48442, 39, 0.00, 1649);
INSERT INTO public.recibos_conceptos VALUES (48446, 1, 38158.50, 1650);
INSERT INTO public.recibos_conceptos VALUES (48447, 7, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48448, 42, 286.19, 1650);
INSERT INTO public.recibos_conceptos VALUES (48449, 12, 3815.85, 1650);
INSERT INTO public.recibos_conceptos VALUES (48450, 4, 38158.50, 1650);
INSERT INTO public.recibos_conceptos VALUES (48451, 5, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48452, 6, 3052.68, 1650);
INSERT INTO public.recibos_conceptos VALUES (48453, 13, 3776.10, 1650);
INSERT INTO public.recibos_conceptos VALUES (48456, 15, 49089.32, 1650);
INSERT INTO public.recibos_conceptos VALUES (48457, 17, 5399.83, 1650);
INSERT INTO public.recibos_conceptos VALUES (48458, 18, 1472.68, 1650);
INSERT INTO public.recibos_conceptos VALUES (48459, 19, 1472.68, 1650);
INSERT INTO public.recibos_conceptos VALUES (48460, 20, 1227.23, 1650);
INSERT INTO public.recibos_conceptos VALUES (48461, 21, 9572.42, 1650);
INSERT INTO public.recibos_conceptos VALUES (48462, 22, 39516.90, 1650);
INSERT INTO public.recibos_conceptos VALUES (48463, 23, 39516.90, 1650);
INSERT INTO public.recibos_conceptos VALUES (48464, 32, 1975.85, 1650);
INSERT INTO public.recibos_conceptos VALUES (48465, 24, 206037.57, 1650);
INSERT INTO public.recibos_conceptos VALUES (48466, 25, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48467, 26, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48483, 39, 0.00, 1650);
INSERT INTO public.recibos_conceptos VALUES (48487, 1, 15764.70, 1651);
INSERT INTO public.recibos_conceptos VALUES (48488, 7, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48489, 42, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48490, 12, 1576.47, 1651);
INSERT INTO public.recibos_conceptos VALUES (48491, 4, 15764.70, 1651);
INSERT INTO public.recibos_conceptos VALUES (48492, 5, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48493, 6, 630.59, 1651);
INSERT INTO public.recibos_conceptos VALUES (48494, 13, 1497.65, 1651);
INSERT INTO public.recibos_conceptos VALUES (48497, 15, 19469.40, 1651);
INSERT INTO public.recibos_conceptos VALUES (48498, 17, 2141.63, 1651);
INSERT INTO public.recibos_conceptos VALUES (48499, 18, 584.08, 1651);
INSERT INTO public.recibos_conceptos VALUES (48500, 19, 584.08, 1651);
INSERT INTO public.recibos_conceptos VALUES (48501, 20, 486.74, 1651);
INSERT INTO public.recibos_conceptos VALUES (48502, 21, 3796.53, 1651);
INSERT INTO public.recibos_conceptos VALUES (48503, 22, 15672.87, 1651);
INSERT INTO public.recibos_conceptos VALUES (48504, 23, 15672.87, 1651);
INSERT INTO public.recibos_conceptos VALUES (48505, 32, 783.64, 1651);
INSERT INTO public.recibos_conceptos VALUES (48506, 24, 206037.57, 1651);
INSERT INTO public.recibos_conceptos VALUES (48507, 25, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48508, 26, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48510, 27, 42924.50, 1651);
INSERT INTO public.recibos_conceptos VALUES (48511, 28, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48513, 31, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48514, 33, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48515, 34, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48516, 35, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48517, 36, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48518, 37, 248962.07, 1651);
INSERT INTO public.recibos_conceptos VALUES (48519, 38, -233289.20, 1651);
INSERT INTO public.recibos_conceptos VALUES (48520, 40, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48521, 9, 539.15, 1651);
INSERT INTO public.recibos_conceptos VALUES (48522, 10, 539.15, 1651);
INSERT INTO public.recibos_conceptos VALUES (48523, 11, 4492.94, 1651);
INSERT INTO public.recibos_conceptos VALUES (48524, 39, 0.00, 1651);
INSERT INTO public.recibos_conceptos VALUES (48528, 1, 39104.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48529, 7, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48530, 42, 1173.12, 1652);
INSERT INTO public.recibos_conceptos VALUES (48531, 12, 3910.40, 1652);
INSERT INTO public.recibos_conceptos VALUES (48532, 4, 39104.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48533, 5, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48534, 6, 8602.88, 1652);
INSERT INTO public.recibos_conceptos VALUES (48535, 13, 4399.20, 1652);
INSERT INTO public.recibos_conceptos VALUES (48538, 15, 57189.60, 1652);
INSERT INTO public.recibos_conceptos VALUES (48539, 17, 6290.86, 1652);
INSERT INTO public.recibos_conceptos VALUES (48540, 18, 1715.69, 1652);
INSERT INTO public.recibos_conceptos VALUES (48541, 19, 1715.69, 1652);
INSERT INTO public.recibos_conceptos VALUES (48542, 20, 1429.74, 1652);
INSERT INTO public.recibos_conceptos VALUES (48543, 21, 11151.97, 1652);
INSERT INTO public.recibos_conceptos VALUES (48544, 22, 46037.63, 1652);
INSERT INTO public.recibos_conceptos VALUES (48545, 23, 46037.63, 1652);
INSERT INTO public.recibos_conceptos VALUES (48546, 32, 2301.88, 1652);
INSERT INTO public.recibos_conceptos VALUES (48547, 24, 206037.57, 1652);
INSERT INTO public.recibos_conceptos VALUES (48548, 25, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48549, 26, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48551, 27, 42924.50, 1652);
INSERT INTO public.recibos_conceptos VALUES (48552, 28, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48554, 31, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48555, 33, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48556, 34, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48557, 35, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48558, 36, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48559, 37, 248962.07, 1652);
INSERT INTO public.recibos_conceptos VALUES (48560, 38, -202924.44, 1652);
INSERT INTO public.recibos_conceptos VALUES (48561, 40, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48562, 9, 1583.71, 1652);
INSERT INTO public.recibos_conceptos VALUES (48563, 10, 1583.71, 1652);
INSERT INTO public.recibos_conceptos VALUES (48564, 11, 13197.60, 1652);
INSERT INTO public.recibos_conceptos VALUES (48565, 39, 0.00, 1652);
INSERT INTO public.recibos_conceptos VALUES (48569, 1, 45948.50, 1653);
INSERT INTO public.recibos_conceptos VALUES (48570, 7, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48571, 42, 3446.14, 1653);
INSERT INTO public.recibos_conceptos VALUES (48572, 12, 4594.85, 1653);
INSERT INTO public.recibos_conceptos VALUES (48573, 4, 45948.50, 1653);
INSERT INTO public.recibos_conceptos VALUES (48574, 5, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48575, 6, 29407.04, 1653);
INSERT INTO public.recibos_conceptos VALUES (48576, 13, 6949.71, 1653);
INSERT INTO public.recibos_conceptos VALUES (48579, 15, 90346.24, 1653);
INSERT INTO public.recibos_conceptos VALUES (48580, 17, 9938.09, 1653);
INSERT INTO public.recibos_conceptos VALUES (48581, 18, 2710.39, 1653);
INSERT INTO public.recibos_conceptos VALUES (48582, 19, 2710.39, 1653);
INSERT INTO public.recibos_conceptos VALUES (48583, 20, 2258.66, 1653);
INSERT INTO public.recibos_conceptos VALUES (48584, 21, 17617.52, 1653);
INSERT INTO public.recibos_conceptos VALUES (48585, 22, 72728.72, 1653);
INSERT INTO public.recibos_conceptos VALUES (48586, 23, 72728.72, 1653);
INSERT INTO public.recibos_conceptos VALUES (48587, 32, 3636.44, 1653);
INSERT INTO public.recibos_conceptos VALUES (48588, 24, 206037.57, 1653);
INSERT INTO public.recibos_conceptos VALUES (48589, 25, 40016.99, 1653);
INSERT INTO public.recibos_conceptos VALUES (48590, 26, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48592, 27, 42924.50, 1653);
INSERT INTO public.recibos_conceptos VALUES (48593, 28, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48595, 31, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48596, 33, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48597, 34, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48598, 35, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48599, 36, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48600, 37, 288979.06, 1653);
INSERT INTO public.recibos_conceptos VALUES (48601, 38, -216250.34, 1653);
INSERT INTO public.recibos_conceptos VALUES (48602, 40, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48603, 9, 2501.90, 1653);
INSERT INTO public.recibos_conceptos VALUES (48604, 10, 2501.90, 1653);
INSERT INTO public.recibos_conceptos VALUES (48605, 11, 20849.13, 1653);
INSERT INTO public.recibos_conceptos VALUES (48606, 39, 0.00, 1653);
INSERT INTO public.recibos_conceptos VALUES (48610, 1, 34958.80, 1654);
INSERT INTO public.recibos_conceptos VALUES (48611, 7, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48612, 42, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48613, 12, 3495.88, 1654);
INSERT INTO public.recibos_conceptos VALUES (48614, 4, 34958.80, 1654);
INSERT INTO public.recibos_conceptos VALUES (48615, 5, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48616, 6, 3495.88, 1654);
INSERT INTO public.recibos_conceptos VALUES (48617, 13, 3495.88, 1654);
INSERT INTO public.recibos_conceptos VALUES (48620, 15, 45446.44, 1654);
INSERT INTO public.recibos_conceptos VALUES (48621, 17, 4999.11, 1654);
INSERT INTO public.recibos_conceptos VALUES (48622, 18, 1363.39, 1654);
INSERT INTO public.recibos_conceptos VALUES (48623, 19, 1363.39, 1654);
INSERT INTO public.recibos_conceptos VALUES (48624, 20, 1136.16, 1654);
INSERT INTO public.recibos_conceptos VALUES (48625, 21, 8862.06, 1654);
INSERT INTO public.recibos_conceptos VALUES (48626, 22, 36584.38, 1654);
INSERT INTO public.recibos_conceptos VALUES (48627, 23, 36584.38, 1654);
INSERT INTO public.recibos_conceptos VALUES (48628, 32, 1829.22, 1654);
INSERT INTO public.recibos_conceptos VALUES (48629, 24, 206037.57, 1654);
INSERT INTO public.recibos_conceptos VALUES (48630, 25, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48631, 26, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48633, 27, 42924.50, 1654);
INSERT INTO public.recibos_conceptos VALUES (48634, 28, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48636, 31, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48637, 33, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48638, 34, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48639, 35, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48640, 36, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48641, 37, 248962.07, 1654);
INSERT INTO public.recibos_conceptos VALUES (48642, 38, -212377.69, 1654);
INSERT INTO public.recibos_conceptos VALUES (48643, 40, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48644, 9, 1258.52, 1654);
INSERT INTO public.recibos_conceptos VALUES (48645, 10, 1258.52, 1654);
INSERT INTO public.recibos_conceptos VALUES (48646, 11, 10487.64, 1654);
INSERT INTO public.recibos_conceptos VALUES (48647, 39, 0.00, 1654);
INSERT INTO public.recibos_conceptos VALUES (48651, 1, 57061.70, 1655);
INSERT INTO public.recibos_conceptos VALUES (48652, 7, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48658, 13, 8273.95, 1655);
INSERT INTO public.recibos_conceptos VALUES (48661, 15, 107561.30, 1655);
INSERT INTO public.recibos_conceptos VALUES (48662, 17, 11831.74, 1655);
INSERT INTO public.recibos_conceptos VALUES (48663, 18, 3226.84, 1655);
INSERT INTO public.recibos_conceptos VALUES (48664, 19, 3226.84, 1655);
INSERT INTO public.recibos_conceptos VALUES (48665, 20, 2689.03, 1655);
INSERT INTO public.recibos_conceptos VALUES (48666, 21, 20974.45, 1655);
INSERT INTO public.recibos_conceptos VALUES (48667, 22, 86586.85, 1655);
INSERT INTO public.recibos_conceptos VALUES (48668, 23, 86586.85, 1655);
INSERT INTO public.recibos_conceptos VALUES (48669, 32, 4329.34, 1655);
INSERT INTO public.recibos_conceptos VALUES (48670, 24, 206037.57, 1655);
INSERT INTO public.recibos_conceptos VALUES (48671, 25, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48672, 26, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48674, 27, 42924.50, 1655);
INSERT INTO public.recibos_conceptos VALUES (48675, 28, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48677, 31, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48678, 33, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48679, 34, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48680, 35, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48681, 36, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48682, 37, 248962.07, 1655);
INSERT INTO public.recibos_conceptos VALUES (48683, 38, -162375.22, 1655);
INSERT INTO public.recibos_conceptos VALUES (48684, 40, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48685, 9, 2978.62, 1655);
INSERT INTO public.recibos_conceptos VALUES (48686, 10, 2978.62, 1655);
INSERT INTO public.recibos_conceptos VALUES (48687, 11, 24821.84, 1655);
INSERT INTO public.recibos_conceptos VALUES (48688, 39, 0.00, 1655);
INSERT INTO public.recibos_conceptos VALUES (48692, 1, 34892.86, 1656);
INSERT INTO public.recibos_conceptos VALUES (48693, 7, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48694, 42, 1570.18, 1656);
INSERT INTO public.recibos_conceptos VALUES (48695, 12, 3489.29, 1656);
INSERT INTO public.recibos_conceptos VALUES (48696, 4, 34892.86, 1656);
INSERT INTO public.recibos_conceptos VALUES (48697, 5, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48698, 6, 1395.71, 1656);
INSERT INTO public.recibos_conceptos VALUES (48699, 13, 3445.67, 1656);
INSERT INTO public.recibos_conceptos VALUES (48702, 15, 44793.71, 1656);
INSERT INTO public.recibos_conceptos VALUES (48703, 17, 4927.31, 1656);
INSERT INTO public.recibos_conceptos VALUES (48704, 18, 1343.81, 1656);
INSERT INTO public.recibos_conceptos VALUES (48705, 19, 1343.81, 1656);
INSERT INTO public.recibos_conceptos VALUES (48706, 20, 1119.84, 1656);
INSERT INTO public.recibos_conceptos VALUES (48707, 21, 8734.77, 1656);
INSERT INTO public.recibos_conceptos VALUES (48708, 22, 36058.94, 1656);
INSERT INTO public.recibos_conceptos VALUES (48709, 23, 36058.94, 1656);
INSERT INTO public.recibos_conceptos VALUES (48710, 32, 1802.95, 1656);
INSERT INTO public.recibos_conceptos VALUES (48711, 24, 206037.57, 1656);
INSERT INTO public.recibos_conceptos VALUES (48712, 25, 40016.99, 1656);
INSERT INTO public.recibos_conceptos VALUES (48713, 26, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48715, 27, 42924.50, 1656);
INSERT INTO public.recibos_conceptos VALUES (48716, 28, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48718, 31, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48719, 33, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48720, 34, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48721, 35, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48722, 36, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48723, 37, 288979.06, 1656);
INSERT INTO public.recibos_conceptos VALUES (48724, 38, -252920.12, 1656);
INSERT INTO public.recibos_conceptos VALUES (48725, 40, 0.00, 1656);
INSERT INTO public.recibos_conceptos VALUES (48726, 9, 1240.44, 1656);
INSERT INTO public.recibos_conceptos VALUES (48727, 10, 1240.44, 1656);
INSERT INTO public.recibos_conceptos VALUES (48728, 11, 10337.01, 1656);
INSERT INTO public.recibos_conceptos VALUES (48729, 39, 0.00, 1656);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 48732, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 1656, true);


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
INSERT INTO public.tabla_ganancias_detalle VALUES (24, 3, 0.00, 0.00, 0.00, 0.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (25, 3, 0.00, 0.00, 0.00, 0.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (26, 4, 0.00, 0.00, 0.00, 0.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (27, 4, 0.00, 0.00, 0.00, 0.00, 0.00, 2);


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_detalle_id_seq', 27, true);


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
INSERT INTO public.tabla_personas VALUES (5, 2019, 9, '2019-09-01', 1000.00, 26, 11);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 5, true);


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
INSERT INTO public.tipo_liquidacion_conceptos VALUES (120, 42, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (121, 42, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (122, 42, 4);


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 122, true);


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
INSERT INTO sistema.reservadas VALUES (8, 'hsextras50', 'Horas Extras al 50%', 'Trae de la planilla del periodo las horas extras al 50%', 'SELECT horas_extras_50 as resultado 
FROM v_periodos_detalle 
WHERE periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION})
AND id_persona={ID_PERSONA};', NULL, 2, 4, '0');
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
INSERT INTO sistema.reservadas VALUES (27, 'hsextras100', 'Horas Extras al 100%', 'Trae de la planilla del periodo las horas extras al 100%', 'SELECT horas_extras_100 as resultado 
FROM v_periodos_detalle 
WHERE periodo=(SELECT periodo FROM liquidaciones WHERE id={ID_LIQUIDACION})
AND id_persona={ID_PERSONA};', NULL, 2, 4, '0');


--
-- Name: reservadas_id_seq; Type: SEQUENCE SET; Schema: sistema; Owner: -
--

SELECT pg_catalog.setval('sistema.reservadas_id_seq', 27, true);


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
    ADD CONSTRAINT fk_recibos_acumuladores__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id) ON DELETE CASCADE;


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
    ADD CONSTRAINT fk_recibos_conceptos__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id) ON DELETE CASCADE;


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

