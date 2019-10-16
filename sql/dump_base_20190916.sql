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
-- Name: back_sueldo_basico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.back_sueldo_basico (
    id integer,
    basico numeric(10,2)
);


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
-- Data for Name: back_sueldo_basico; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.back_sueldo_basico VALUES (2, 10000.00);
INSERT INTO public.back_sueldo_basico VALUES (20, 42717.50);
INSERT INTO public.back_sueldo_basico VALUES (21, 38158.50);
INSERT INTO public.back_sueldo_basico VALUES (22, 15764.70);
INSERT INTO public.back_sueldo_basico VALUES (23, 39104.00);
INSERT INTO public.back_sueldo_basico VALUES (7, 34892.86);
INSERT INTO public.back_sueldo_basico VALUES (8, 34351.20);
INSERT INTO public.back_sueldo_basico VALUES (9, 41008.81);
INSERT INTO public.back_sueldo_basico VALUES (10, 46807.40);
INSERT INTO public.back_sueldo_basico VALUES (11, 24061.43);
INSERT INTO public.back_sueldo_basico VALUES (12, 35226.50);
INSERT INTO public.back_sueldo_basico VALUES (13, 48582.30);
INSERT INTO public.back_sueldo_basico VALUES (14, 17250.00);
INSERT INTO public.back_sueldo_basico VALUES (15, NULL);
INSERT INTO public.back_sueldo_basico VALUES (16, 35033.10);
INSERT INTO public.back_sueldo_basico VALUES (24, 45948.50);
INSERT INTO public.back_sueldo_basico VALUES (17, 46839.10);
INSERT INTO public.back_sueldo_basico VALUES (18, 42666.80);
INSERT INTO public.back_sueldo_basico VALUES (19, 42012.00);
INSERT INTO public.back_sueldo_basico VALUES (25, 34958.80);
INSERT INTO public.back_sueldo_basico VALUES (26, 57061.70);


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
INSERT INTO public.conceptos VALUES (1, 'Sueldo Básico', '1', 1, 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ diasmes * (diasmes-diasvacac) ))', true, true, true, 'Si se toma vacaciones calculo el proporcional a los dias trabajados.
En el caso de que se tome todos los dias del mes devueve el basico.', NULL, true, false);
INSERT INTO public.conceptos VALUES (46, 'Vacaciones', '200', 1, 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', true, true, false, 'Plus Vacacional.
En bruto tengo el proporcional y tengo que calcular el total del sueldo bruto sin el proporcional a los dias trabajados (basico/diasmes*diastrab).', NULL, true, false);
INSERT INTO public.conceptos VALUES (48, 'A cuenta de futuros aumentos', '30', 1, NULL, true, true, false, 'Es un valor agregado por el operador', NULL, true, false);
INSERT INTO public.conceptos VALUES (47, 'Bruto Sin Proporcional', '199', 1, 'si( igual(diasvacac,0) , bruto , bruto/ si( igual(diasmes,diasvacac),diasmes, diasmes-diasvacac)*diasmes )', false, false, false, 'Si hay vacaciones se calcula un proporcional. Este concepto muestra el total sin tener en cuenta el proporcional. VER c1', NULL, false, false);
INSERT INTO public.conceptos VALUES (49, 'Asig. Decreto 1043/2018', '60', 1, NULL, true, true, false, 'Valor ingresado por el operador', NULL, false, true);
INSERT INTO public.conceptos VALUES (50, 'Vacaciones', '201', 1, NULL, true, true, false, 'El valor de este concepto es ingresado por el usuario', NULL, false, false);
INSERT INTO public.conceptos VALUES (51, 'Adicional 51860', '5', 1, NULL, true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (39, 'IMPUESTO A LAS GANANCIAS', '515', 2, 'c370 - ganancia_acumulada', true, true, false, 'c370: Valor Final del calculo de ganancia mensual - el acumulado del año hasta el periodo de la liquidacion', NULL, false, false);


--
-- Name: conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.conceptos_id_seq', 51, true);


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



--
-- Data for Name: historico_liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: historico_recibos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: historico_recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: historico_recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (111, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 1, 1, 2019, 1, '2019-01-29', 'Enero');


--
-- Data for Name: liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones_conceptos VALUES (2708, 1, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2709, 7, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2710, 42, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2711, 12, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2712, 4, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2713, 5, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2714, 6, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2715, 47, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2716, 46, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2717, 13, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2718, 14, 111, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2719, 16, 111, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2720, 15, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2721, 17, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2722, 18, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2723, 19, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2724, 20, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2725, 21, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2726, 22, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2727, 23, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2728, 32, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2729, 24, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2730, 25, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2731, 26, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2732, 29, 111, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2733, 27, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2734, 28, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2735, 30, 111, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2736, 31, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2737, 33, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2738, 34, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2739, 35, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2740, 36, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2741, 37, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2742, 38, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2743, 40, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2744, 9, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2745, 10, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2746, 11, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2747, 39, 111, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2748, 48, 111, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2749, 49, 111, 0.00);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 2749, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 111, true);


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

INSERT INTO public.periodos VALUES (4, 'Planilla de Junio', 2019, 6, '2019-06-01', '2019-06-01', '2019-06-30', NULL);
INSERT INTO public.periodos VALUES (5, 'Planilla de Julio', 2019, 7, '2019-07-01', '2019-07-01', '2019-07-31', NULL);
INSERT INTO public.periodos VALUES (3, 'Datos del periodo enero 2019', 2019, 1, '2019-01-01', '2019-01-01', '2019-01-31', 'Estos datos son usados cuando se liquide Enero 2019');


--
-- Data for Name: periodos_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.periodos_detalle VALUES (6, 13, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (7, 11, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (8, 19, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (9, 17, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (12, 15, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (13, 20, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (18, 12, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (20, 14, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (23, 24, NULL, NULL, 10.00, 0, 4, NULL, 0.00);
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
INSERT INTO public.periodos_detalle VALUES (24, 26, NULL, NULL, NULL, 30, 4, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (43, 24, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (44, 26, NULL, NULL, NULL, 18, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (45, 10, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (46, 13, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (47, 11, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (48, 19, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (49, 17, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (50, 18, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (51, 23, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (52, 15, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (53, 20, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (54, 8, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (55, 9, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (56, 16, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (57, 25, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (58, 12, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (59, 21, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (60, 14, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (61, 22, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (62, 7, NULL, NULL, NULL, 0, 5, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (10, 18, NULL, NULL, NULL, 0, 3, NULL, 23.00);
INSERT INTO public.periodos_detalle VALUES (11, 23, NULL, NULL, NULL, 0, 3, NULL, 5.13);
INSERT INTO public.periodos_detalle VALUES (16, 16, NULL, NULL, NULL, 0, 3, NULL, 19.37);
INSERT INTO public.periodos_detalle VALUES (17, 25, NULL, NULL, NULL, 0, 3, NULL, 2.41);
INSERT INTO public.periodos_detalle VALUES (19, 21, NULL, NULL, NULL, 0, 3, NULL, 4.40);
INSERT INTO public.periodos_detalle VALUES (21, 22, NULL, NULL, NULL, 0, 3, NULL, 13.07);
INSERT INTO public.periodos_detalle VALUES (4, 26, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (14, 8, NULL, NULL, NULL, 0, 3, NULL, 13.84);
INSERT INTO public.periodos_detalle VALUES (15, 9, NULL, NULL, NULL, 0, 3, NULL, 1.13);
INSERT INTO public.periodos_detalle VALUES (22, 7, NULL, NULL, NULL, 0, 3, NULL, 4.00);
INSERT INTO public.periodos_detalle VALUES (5, 10, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (3, 24, NULL, NULL, NULL, 0, 3, NULL, 0.00);


--
-- Name: periodos_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_detalle_id_seq', 62, true);


--
-- Name: periodos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.periodos_id_seq', 5, true);


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

INSERT INTO public.personas VALUES (13, 'Noemi Severa', 'Delgado', '1956-10-27', 1, '12904169', 2, 1, true, 7, 1, 2, 1, 1, NULL, '1986-07-14', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27129041698', 7.00, 38150.89, 0, 8.00, 2);
INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265838333', 7.00, 32721.43, 0, 8.00, 1);
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1994-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 33068.34, 0, 8.00, 2);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27144901008', 7.00, 36809.25, 0, 8.00, 2);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27927271414', 7.00, 19136.11, 0, 4.00, 2);
INSERT INTO public.personas VALUES (12, 'Gisela Elizabeth', 'Dandrilli', '1984-08-04', 1, '30939944', 2, 1, true, 34, 2, 4, 1, 1, NULL, '2014-02-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27309399442', 7.00, 28051.97, 0, 8.00, 3);
INSERT INTO public.personas VALUES (14, 'Cesar Anibal', 'Echenique', '1978-12-24', 1, '27113644', 1, 1, true, 37, 1, 3, 2, 1, NULL, '2015-06-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20271136448', 7.00, 13537.16, 0, 4.00, 1);
INSERT INTO public.personas VALUES (15, 'Maria Cecilia', 'Ferrari', '1982-07-25', 1, '29594863', 2, 1, true, 26, 1, 3, 2, 1, NULL, '2008-02-20', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27295948634', 7.00, 20037.91, 0, 4.00, 2);
INSERT INTO public.personas VALUES (2, 'Martin', 'Garay', '1989-05-11', 1, '34555008', 1, 1, false, 4611, 1, 1, 1, 1, 'martingaray_12@gmail.com', '2019-07-01', '2019-08-15', '08:00:00', '15:00:00', 1, 'San Vicente 1351', '1 ', 'D         ', '01122777025', '01122777025', 1, '23345550089', 7.00, 35983.30, 0, 8.00, NULL);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265630562', 7.00, 27909.93, 0, 8.00, 3);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, 'Mariano Moreno 1460', NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 28027.12, 0, 8.00, 2);
INSERT INTO public.personas VALUES (16, 'Rodrigo Raul', 'Ferreyra', '1989-10-10', 1, '34831908', 1, 1, true, 32, 1, 4, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20348319087', 7.00, 27965.08, 0, 8.00, 1);
INSERT INTO public.personas VALUES (17, 'Micaela Noemi', 'Frascaroli', '1982-02-27', 1, '29233345', 2, 1, true, 19, 1, 2, 1, 1, NULL, '2003-10-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27292333450', 7.00, 37038.13, 0, 8.00, 2);
INSERT INTO public.personas VALUES (18, 'Betiana Nazareth', 'Gallesio', '1978-01-04', 1, '26167199', 2, 1, true, 21, 1, 2, 1, 1, NULL, '2006-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27261671994', 7.00, 32407.03, 0, 8.00, 2);
INSERT INTO public.personas VALUES (20, 'Norma Elizabeth', 'Lombardo', '1960-11-25', 1, '14097779', 2, 1, true, 27, 2, 2, 1, 1, NULL, '2009-08-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27140977794', 7.00, 33913.59, 0, 8.00, 2);
INSERT INTO public.personas VALUES (21, 'Maria Soledad', 'Paccor', '1979-03-05', 1, '27033687', 2, 1, true, 35, 1, 3, 1, 1, NULL, '2014-11-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27270336871', 7.00, 29170.23, 0, 8.00, 3);
INSERT INTO public.personas VALUES (22, 'Alejandra', 'Paris', '1984-05-06', 1, '30939775', 2, 1, true, 39, 1, 3, 1, 1, NULL, '2016-07-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '23309397754', 7.00, 29084.74, 0, 8.00, 3);
INSERT INTO public.personas VALUES (23, 'Jorgelina', 'Parra', '1976-05-11', 1, '25048843', 2, 1, true, 23, 1, 3, 1, 1, NULL, '2007-07-02', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27250488438', 7.00, 31052.42, 0, 8.00, 2);
INSERT INTO public.personas VALUES (24, 'Norma', 'Poletti', '1967-11-07', 1, '18601061', 2, 1, true, 2, 2, 2, 1, 1, NULL, '1986-09-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27186010618', 7.00, 35983.30, 0, 8.00, 2);
INSERT INTO public.personas VALUES (25, 'Lautaro', 'Riccardo', '1986-05-29', 1, '32378152', 1, 1, true, 33, 1, 3, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20323781525', 7.00, 27905.80, 0, 8.00, 1);
INSERT INTO public.personas VALUES (26, 'Ana Gladys', 'Romero', '1966-05-04', 1, '18148598', 2, 1, true, 3, 3, 1, 1, 1, NULL, '1986-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27181485987', 7.00, 44516.50, 0, 8.00, 2);


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

INSERT INTO public.recibos VALUES (1797, NULL, 8, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1798, NULL, 9, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1799, NULL, 10, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1800, NULL, 11, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1801, NULL, 12, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1802, NULL, 13, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1803, NULL, 14, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1804, NULL, 15, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1805, NULL, 16, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1806, NULL, 17, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1807, NULL, 18, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1808, NULL, 19, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1809, NULL, 20, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1810, NULL, 21, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1811, NULL, 22, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1812, NULL, 23, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1813, NULL, 24, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1814, NULL, 25, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1815, NULL, 26, NULL, NULL, NULL, NULL, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1816, NULL, 7, NULL, NULL, NULL, NULL, NULL, 111, NULL);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--



--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 6860, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (54315, 1, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54316, 7, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54317, 42, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54318, 12, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54319, 4, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54320, 5, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54321, 6, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54322, 47, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54323, 46, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54324, 13, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54325, 14, 0.00, 1797);
INSERT INTO public.recibos_conceptos VALUES (54326, 16, 0.00, 1797);
INSERT INTO public.recibos_conceptos VALUES (54327, 15, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54328, 17, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54329, 18, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54330, 19, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54331, 20, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54332, 21, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54333, 22, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54334, 23, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54335, 32, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54336, 24, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54337, 25, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54338, 26, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54339, 29, 0.00, 1797);
INSERT INTO public.recibos_conceptos VALUES (54340, 27, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54341, 28, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54342, 30, 0.00, 1797);
INSERT INTO public.recibos_conceptos VALUES (54343, 31, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54344, 33, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54345, 34, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54346, 35, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54347, 36, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54348, 37, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54349, 38, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54350, 40, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54351, 9, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54352, 10, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54353, 11, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54354, 39, NULL, 1797);
INSERT INTO public.recibos_conceptos VALUES (54357, 1, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54358, 7, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54359, 42, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54360, 12, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54361, 4, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54362, 5, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54363, 6, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54364, 47, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54365, 46, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54366, 13, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54367, 14, 0.00, 1798);
INSERT INTO public.recibos_conceptos VALUES (54368, 16, 0.00, 1798);
INSERT INTO public.recibos_conceptos VALUES (54369, 15, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54370, 17, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54371, 18, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54372, 19, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54373, 20, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54374, 21, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54375, 22, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54376, 23, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54377, 32, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54378, 24, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54379, 25, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54380, 26, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54381, 29, 0.00, 1798);
INSERT INTO public.recibos_conceptos VALUES (54382, 27, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54383, 28, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54384, 30, 0.00, 1798);
INSERT INTO public.recibos_conceptos VALUES (54385, 31, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54386, 33, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54387, 34, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54388, 35, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54389, 36, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54390, 37, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54391, 38, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54392, 40, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54393, 9, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54394, 10, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54395, 11, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54396, 39, NULL, 1798);
INSERT INTO public.recibos_conceptos VALUES (54399, 1, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54400, 7, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54401, 42, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54402, 12, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54403, 4, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54404, 5, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54405, 6, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54406, 47, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54407, 46, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54408, 13, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54409, 14, 0.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54410, 16, 0.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54411, 15, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54412, 17, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54413, 18, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54414, 19, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54415, 20, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54416, 21, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54417, 22, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54418, 23, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54419, 32, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54420, 24, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54421, 25, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54422, 26, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54423, 29, 0.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54424, 27, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54425, 28, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54426, 30, 0.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54427, 31, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54428, 33, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54429, 34, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54430, 35, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54431, 36, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54432, 37, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54433, 38, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54434, 40, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54435, 9, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54436, 10, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54437, 11, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54438, 39, NULL, 1799);
INSERT INTO public.recibos_conceptos VALUES (54439, 48, 0.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54441, 1, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54442, 7, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54443, 42, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54444, 12, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54445, 4, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54446, 5, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54447, 6, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54448, 47, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54449, 46, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54450, 13, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54451, 14, 0.00, 1800);
INSERT INTO public.recibos_conceptos VALUES (54452, 16, 0.00, 1800);
INSERT INTO public.recibos_conceptos VALUES (54453, 15, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54454, 17, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54455, 18, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54456, 19, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54457, 20, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54458, 21, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54459, 22, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54460, 23, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54461, 32, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54462, 24, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54463, 25, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54464, 26, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54465, 29, 0.00, 1800);
INSERT INTO public.recibos_conceptos VALUES (54466, 27, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54467, 28, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54468, 30, 0.00, 1800);
INSERT INTO public.recibos_conceptos VALUES (54469, 31, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54470, 33, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54471, 34, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54472, 35, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54473, 36, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54474, 37, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54475, 38, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54476, 40, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54477, 9, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54478, 10, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54479, 11, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54480, 39, NULL, 1800);
INSERT INTO public.recibos_conceptos VALUES (54483, 1, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54484, 7, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54485, 42, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54486, 12, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54487, 4, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54488, 5, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54489, 6, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54490, 47, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54491, 46, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54492, 13, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54493, 14, 0.00, 1801);
INSERT INTO public.recibos_conceptos VALUES (54494, 16, 0.00, 1801);
INSERT INTO public.recibos_conceptos VALUES (54495, 15, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54496, 17, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54497, 18, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54498, 19, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54499, 20, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54500, 21, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54501, 22, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54502, 23, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54503, 32, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54504, 24, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54505, 25, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54506, 26, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54507, 29, 0.00, 1801);
INSERT INTO public.recibos_conceptos VALUES (54508, 27, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54509, 28, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54510, 30, 0.00, 1801);
INSERT INTO public.recibos_conceptos VALUES (54511, 31, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54512, 33, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54513, 34, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54514, 35, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54515, 36, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54516, 37, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54517, 38, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54518, 40, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54519, 9, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54520, 10, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54521, 11, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54522, 39, NULL, 1801);
INSERT INTO public.recibos_conceptos VALUES (54525, 1, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54526, 7, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54527, 42, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54528, 12, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54529, 4, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54530, 5, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54531, 6, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54532, 47, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54533, 46, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54534, 13, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54535, 14, 0.00, 1802);
INSERT INTO public.recibos_conceptos VALUES (54536, 16, 0.00, 1802);
INSERT INTO public.recibos_conceptos VALUES (54537, 15, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54538, 17, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54539, 18, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54540, 19, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54541, 20, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54542, 21, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54543, 22, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54544, 23, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54545, 32, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54546, 24, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54547, 25, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54548, 26, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54549, 29, 0.00, 1802);
INSERT INTO public.recibos_conceptos VALUES (54550, 27, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54551, 28, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54552, 30, 0.00, 1802);
INSERT INTO public.recibos_conceptos VALUES (54553, 31, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54554, 33, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54555, 34, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54556, 35, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54557, 36, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54558, 37, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54559, 38, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54560, 40, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54561, 9, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54562, 10, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54563, 11, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54564, 39, NULL, 1802);
INSERT INTO public.recibos_conceptos VALUES (54567, 1, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54568, 7, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54569, 42, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54570, 12, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54571, 4, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54572, 5, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54573, 6, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54574, 47, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54575, 46, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54576, 13, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54577, 14, 0.00, 1803);
INSERT INTO public.recibos_conceptos VALUES (54578, 16, 0.00, 1803);
INSERT INTO public.recibos_conceptos VALUES (54579, 15, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54580, 17, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54581, 18, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54582, 19, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54583, 20, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54584, 21, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54585, 22, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54586, 23, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54587, 32, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54588, 24, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54589, 25, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54590, 26, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54591, 29, 0.00, 1803);
INSERT INTO public.recibos_conceptos VALUES (54592, 27, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54593, 28, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54594, 30, 0.00, 1803);
INSERT INTO public.recibos_conceptos VALUES (54595, 31, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54596, 33, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54597, 34, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54598, 35, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54599, 36, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54600, 37, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54601, 38, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54602, 40, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54603, 9, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54604, 10, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54605, 11, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54606, 39, NULL, 1803);
INSERT INTO public.recibos_conceptos VALUES (54609, 1, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54610, 7, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54611, 42, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54612, 12, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54613, 4, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54614, 5, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54615, 6, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54616, 47, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54617, 46, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54618, 13, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54619, 14, 0.00, 1804);
INSERT INTO public.recibos_conceptos VALUES (54620, 16, 0.00, 1804);
INSERT INTO public.recibos_conceptos VALUES (54621, 15, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54622, 17, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54623, 18, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54624, 19, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54625, 20, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54626, 21, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54627, 22, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54628, 23, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54629, 32, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54630, 24, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54631, 25, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54632, 26, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54633, 29, 0.00, 1804);
INSERT INTO public.recibos_conceptos VALUES (54634, 27, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54635, 28, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54636, 30, 0.00, 1804);
INSERT INTO public.recibos_conceptos VALUES (54637, 31, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54638, 33, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54639, 34, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54640, 35, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54641, 36, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54642, 37, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54643, 38, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54644, 40, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54645, 9, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54646, 10, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54647, 11, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54648, 39, NULL, 1804);
INSERT INTO public.recibos_conceptos VALUES (54651, 1, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54652, 7, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54653, 42, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54654, 12, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54655, 4, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54656, 5, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54657, 6, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54658, 47, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54659, 46, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54660, 13, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54661, 14, 0.00, 1805);
INSERT INTO public.recibos_conceptos VALUES (54662, 16, 0.00, 1805);
INSERT INTO public.recibos_conceptos VALUES (54663, 15, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54664, 17, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54665, 18, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54666, 19, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54667, 20, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54668, 21, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54669, 22, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54670, 23, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54671, 32, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54672, 24, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54673, 25, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54674, 26, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54675, 29, 0.00, 1805);
INSERT INTO public.recibos_conceptos VALUES (54676, 27, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54677, 28, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54678, 30, 0.00, 1805);
INSERT INTO public.recibos_conceptos VALUES (54679, 31, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54680, 33, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54681, 34, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54682, 35, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54683, 36, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54684, 37, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54650, 49, -1400.00, 1804);
INSERT INTO public.recibos_conceptos VALUES (54685, 38, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54686, 40, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54687, 9, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54688, 10, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54689, 11, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54690, 39, NULL, 1805);
INSERT INTO public.recibos_conceptos VALUES (54693, 1, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54694, 7, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54695, 42, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54696, 12, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54697, 4, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54698, 5, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54699, 6, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54700, 47, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54701, 46, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54702, 13, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54703, 14, 0.00, 1806);
INSERT INTO public.recibos_conceptos VALUES (54704, 16, 0.00, 1806);
INSERT INTO public.recibos_conceptos VALUES (54705, 15, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54706, 17, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54707, 18, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54708, 19, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54709, 20, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54710, 21, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54711, 22, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54712, 23, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54713, 32, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54714, 24, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54715, 25, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54716, 26, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54717, 29, 0.00, 1806);
INSERT INTO public.recibos_conceptos VALUES (54718, 27, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54719, 28, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54720, 30, 0.00, 1806);
INSERT INTO public.recibos_conceptos VALUES (54721, 31, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54722, 33, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54723, 34, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54724, 35, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54725, 36, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54726, 37, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54727, 38, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54728, 40, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54729, 9, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54730, 10, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54731, 11, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54732, 39, NULL, 1806);
INSERT INTO public.recibos_conceptos VALUES (54735, 1, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54736, 7, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54737, 42, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54738, 12, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54739, 4, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54740, 5, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54741, 6, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54742, 47, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54743, 46, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54744, 13, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54745, 14, 0.00, 1807);
INSERT INTO public.recibos_conceptos VALUES (54746, 16, 0.00, 1807);
INSERT INTO public.recibos_conceptos VALUES (54747, 15, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54748, 17, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54749, 18, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54750, 19, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54751, 20, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54752, 21, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54753, 22, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54754, 23, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54755, 32, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54756, 24, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54757, 25, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54758, 26, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54759, 29, 0.00, 1807);
INSERT INTO public.recibos_conceptos VALUES (54760, 27, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54761, 28, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54762, 30, 0.00, 1807);
INSERT INTO public.recibos_conceptos VALUES (54763, 31, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54764, 33, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54765, 34, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54766, 35, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54767, 36, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54768, 37, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54769, 38, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54770, 40, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54771, 9, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54772, 10, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54773, 11, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54774, 39, NULL, 1807);
INSERT INTO public.recibos_conceptos VALUES (54777, 1, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54778, 7, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54779, 42, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54780, 12, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54781, 4, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54782, 5, 3.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54783, 6, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54784, 47, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54785, 46, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54786, 13, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54787, 14, 0.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54788, 16, 0.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54789, 15, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54790, 17, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54791, 18, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54792, 19, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54793, 20, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54794, 21, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54795, 22, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54796, 23, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54797, 32, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54798, 24, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54799, 25, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54800, 26, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54801, 29, 0.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54802, 27, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54803, 28, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54804, 30, 0.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54805, 31, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54806, 33, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54807, 34, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54808, 35, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54809, 36, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54810, 37, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54811, 38, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54812, 40, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54813, 9, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54814, 10, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54815, 11, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54816, 39, NULL, 1808);
INSERT INTO public.recibos_conceptos VALUES (54819, 1, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54820, 7, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54821, 42, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54822, 12, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54823, 4, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54824, 5, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54825, 6, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54826, 47, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54827, 46, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54828, 13, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54829, 14, 0.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (54830, 16, 0.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (54831, 15, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54832, 17, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54833, 18, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54834, 19, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54835, 20, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54836, 21, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54837, 22, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54838, 23, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54839, 32, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54840, 24, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54841, 25, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54842, 26, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54843, 29, 0.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (54844, 27, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54845, 28, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54846, 30, 0.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (54847, 31, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54848, 33, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54849, 34, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54850, 35, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54851, 36, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54852, 37, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54853, 38, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54854, 40, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54855, 9, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54856, 10, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54857, 11, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54858, 39, NULL, 1809);
INSERT INTO public.recibos_conceptos VALUES (54861, 1, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54862, 7, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54863, 42, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54864, 12, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54865, 4, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54866, 5, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54867, 6, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54868, 47, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54869, 46, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54870, 13, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54871, 14, 0.00, 1810);
INSERT INTO public.recibos_conceptos VALUES (54872, 16, 0.00, 1810);
INSERT INTO public.recibos_conceptos VALUES (54873, 15, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54874, 17, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54875, 18, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54876, 19, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54877, 20, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54878, 21, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54879, 22, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54880, 23, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54881, 32, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54882, 24, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54883, 25, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54884, 26, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54885, 29, 0.00, 1810);
INSERT INTO public.recibos_conceptos VALUES (54886, 27, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54887, 28, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54888, 30, 0.00, 1810);
INSERT INTO public.recibos_conceptos VALUES (54889, 31, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54890, 33, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54891, 34, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54892, 35, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54893, 36, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54894, 37, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54895, 38, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54896, 40, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54897, 9, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54898, 10, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54899, 11, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54900, 39, NULL, 1810);
INSERT INTO public.recibos_conceptos VALUES (54903, 1, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54904, 7, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54905, 42, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54906, 12, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54907, 4, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54908, 5, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54909, 6, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54910, 47, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54911, 46, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54912, 13, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54913, 14, 0.00, 1811);
INSERT INTO public.recibos_conceptos VALUES (54914, 16, 0.00, 1811);
INSERT INTO public.recibos_conceptos VALUES (54915, 15, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54916, 17, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54917, 18, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54918, 19, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54919, 20, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54920, 21, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54921, 22, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54922, 23, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54923, 32, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54924, 24, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54925, 25, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54926, 26, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54927, 29, 0.00, 1811);
INSERT INTO public.recibos_conceptos VALUES (54928, 27, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54929, 28, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54930, 30, 0.00, 1811);
INSERT INTO public.recibos_conceptos VALUES (54931, 31, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54932, 33, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54933, 34, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54934, 35, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54935, 36, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54936, 37, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54937, 38, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54938, 40, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54939, 9, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54940, 10, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54941, 11, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54942, 39, NULL, 1811);
INSERT INTO public.recibos_conceptos VALUES (54945, 1, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54946, 7, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54947, 42, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54948, 12, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54949, 4, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54950, 5, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54951, 6, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54952, 47, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54953, 46, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54954, 13, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54955, 14, 0.00, 1812);
INSERT INTO public.recibos_conceptos VALUES (54956, 16, 0.00, 1812);
INSERT INTO public.recibos_conceptos VALUES (54957, 15, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54958, 17, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54959, 18, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54960, 19, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54961, 20, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54962, 21, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54963, 22, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54964, 23, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54965, 32, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54966, 24, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54967, 25, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54968, 26, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54969, 29, 0.00, 1812);
INSERT INTO public.recibos_conceptos VALUES (54970, 27, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54971, 28, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54972, 30, 0.00, 1812);
INSERT INTO public.recibos_conceptos VALUES (54973, 31, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54974, 33, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54975, 34, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54976, 35, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54977, 36, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54978, 37, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54979, 38, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54980, 40, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54981, 9, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54982, 10, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54983, 11, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54984, 39, NULL, 1812);
INSERT INTO public.recibos_conceptos VALUES (54987, 1, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54988, 7, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54989, 42, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54990, 12, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54991, 4, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54992, 5, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54993, 6, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54994, 47, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54995, 46, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54996, 13, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (54997, 14, 0.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (54998, 16, 0.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (54999, 15, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55000, 17, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55001, 18, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55002, 19, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55003, 20, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55004, 21, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55005, 22, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55006, 23, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55007, 32, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55008, 24, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55009, 25, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55010, 26, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55011, 29, 0.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (55012, 27, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55013, 28, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55014, 30, 0.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (55015, 31, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55016, 33, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55017, 34, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55018, 35, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55019, 36, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55020, 37, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55021, 38, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55022, 40, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55023, 9, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55024, 10, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55025, 11, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55026, 39, NULL, 1813);
INSERT INTO public.recibos_conceptos VALUES (55027, 48, 0.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (55029, 1, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55030, 7, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55031, 42, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55032, 12, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55033, 4, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55034, 5, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55035, 6, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55036, 47, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55037, 46, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55038, 13, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55039, 14, 0.00, 1814);
INSERT INTO public.recibos_conceptos VALUES (55040, 16, 0.00, 1814);
INSERT INTO public.recibos_conceptos VALUES (55041, 15, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55042, 17, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55043, 18, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55044, 19, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55045, 20, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55046, 21, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55047, 22, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55048, 23, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55049, 32, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55050, 24, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55051, 25, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55052, 26, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55053, 29, 0.00, 1814);
INSERT INTO public.recibos_conceptos VALUES (55054, 27, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55055, 28, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55056, 30, 0.00, 1814);
INSERT INTO public.recibos_conceptos VALUES (55057, 31, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55058, 33, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55059, 34, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55060, 35, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55061, 36, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55062, 37, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55063, 38, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55064, 40, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55065, 9, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55066, 10, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55067, 11, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55068, 39, NULL, 1814);
INSERT INTO public.recibos_conceptos VALUES (55071, 1, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55072, 7, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55073, 42, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55074, 12, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55075, 4, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55076, 5, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55077, 6, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55078, 47, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55079, 46, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55080, 13, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55081, 14, 0.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55082, 16, 0.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55083, 15, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55084, 17, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55085, 18, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55086, 19, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55087, 20, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55088, 21, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55089, 22, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55090, 23, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55091, 32, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55092, 24, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55093, 25, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55094, 26, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55095, 29, 0.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55096, 27, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55097, 28, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55098, 30, 0.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55099, 31, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55100, 33, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55101, 34, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55102, 35, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55103, 36, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55104, 37, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55105, 38, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55106, 40, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55107, 9, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55108, 10, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55109, 11, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55110, 39, NULL, 1815);
INSERT INTO public.recibos_conceptos VALUES (55113, 1, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55114, 7, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55115, 42, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55116, 12, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55117, 4, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55118, 5, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55119, 6, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55120, 47, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55121, 46, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55122, 13, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55123, 14, 0.00, 1816);
INSERT INTO public.recibos_conceptos VALUES (55124, 16, 0.00, 1816);
INSERT INTO public.recibos_conceptos VALUES (55125, 15, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55126, 17, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55127, 18, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55128, 19, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55129, 20, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55130, 21, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55131, 22, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55132, 23, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55133, 32, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55134, 24, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55135, 25, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55136, 26, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55137, 29, 0.00, 1816);
INSERT INTO public.recibos_conceptos VALUES (55138, 27, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55139, 28, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55140, 30, 0.00, 1816);
INSERT INTO public.recibos_conceptos VALUES (55141, 31, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55142, 33, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55143, 34, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55144, 35, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55145, 36, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55146, 37, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55147, 38, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55148, 40, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55149, 9, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55150, 10, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55151, 11, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55152, 39, NULL, 1816);
INSERT INTO public.recibos_conceptos VALUES (55155, 45, 3376.41, 1802);
INSERT INTO public.recibos_conceptos VALUES (54355, 48, 1108.96, 1797);
INSERT INTO public.recibos_conceptos VALUES (54356, 49, -2500.00, 1797);
INSERT INTO public.recibos_conceptos VALUES (54397, 48, 333.14, 1798);
INSERT INTO public.recibos_conceptos VALUES (54398, 49, -2500.00, 1798);
INSERT INTO public.recibos_conceptos VALUES (54440, 49, -2500.00, 1799);
INSERT INTO public.recibos_conceptos VALUES (54481, 48, 809.33, 1800);
INSERT INTO public.recibos_conceptos VALUES (54482, 49, -1700.00, 1800);
INSERT INTO public.recibos_conceptos VALUES (54523, 48, 1140.80, 1801);
INSERT INTO public.recibos_conceptos VALUES (54524, 49, -2500.00, 1801);
INSERT INTO public.recibos_conceptos VALUES (54565, 48, 2225.40, 1802);
INSERT INTO public.recibos_conceptos VALUES (54566, 49, -2500.00, 1802);
INSERT INTO public.recibos_conceptos VALUES (54607, 48, 347.72, 1803);
INSERT INTO public.recibos_conceptos VALUES (54608, 49, -1125.00, 1803);
INSERT INTO public.recibos_conceptos VALUES (54649, 48, 948.83, 1804);
INSERT INTO public.recibos_conceptos VALUES (55153, 48, 979.66, 1816);
INSERT INTO public.recibos_conceptos VALUES (55154, 49, -2500.00, 1816);
INSERT INTO public.recibos_conceptos VALUES (55156, 51, 1483.33, 1804);
INSERT INTO public.recibos_conceptos VALUES (55157, 45, 3748.16, 1806);
INSERT INTO public.recibos_conceptos VALUES (55158, 45, 4858.79, 1807);
INSERT INTO public.recibos_conceptos VALUES (55159, 45, 1166.48, 1808);
INSERT INTO public.recibos_conceptos VALUES (55160, 44, 2649.80, 1808);
INSERT INTO public.recibos_conceptos VALUES (55161, 45, 4600.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (55162, 45, 1236.63, 1810);
INSERT INTO public.recibos_conceptos VALUES (55163, 44, 2649.80, 1812);
INSERT INTO public.recibos_conceptos VALUES (55164, 45, 13955.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55165, 44, 2649.80, 1815);
INSERT INTO public.recibos_conceptos VALUES (54691, 48, 1052.98, 1805);
INSERT INTO public.recibos_conceptos VALUES (54692, 49, -2500.00, 1805);
INSERT INTO public.recibos_conceptos VALUES (54733, 48, 1834.35, 1806);
INSERT INTO public.recibos_conceptos VALUES (54734, 49, -2500.00, 1806);
INSERT INTO public.recibos_conceptos VALUES (54775, 48, 1575.87, 1807);
INSERT INTO public.recibos_conceptos VALUES (54776, 49, -2500.00, 1807);
INSERT INTO public.recibos_conceptos VALUES (54817, 48, 1830.95, 1808);
INSERT INTO public.recibos_conceptos VALUES (54818, 49, -2500.00, 1808);
INSERT INTO public.recibos_conceptos VALUES (54859, 48, 1509.30, 1809);
INSERT INTO public.recibos_conceptos VALUES (54860, 49, -2500.00, 1809);
INSERT INTO public.recibos_conceptos VALUES (54901, 48, 1121.28, 1810);
INSERT INTO public.recibos_conceptos VALUES (54902, 49, -2500.00, 1810);
INSERT INTO public.recibos_conceptos VALUES (54943, 48, 1039.45, 1811);
INSERT INTO public.recibos_conceptos VALUES (54944, 49, -2500.00, 1811);
INSERT INTO public.recibos_conceptos VALUES (54985, 48, 1372.70, 1812);
INSERT INTO public.recibos_conceptos VALUES (54986, 49, -2500.00, 1812);
INSERT INTO public.recibos_conceptos VALUES (55028, 49, -2500.00, 1813);
INSERT INTO public.recibos_conceptos VALUES (55069, 48, 280.19, 1814);
INSERT INTO public.recibos_conceptos VALUES (55070, 49, -2500.00, 1814);
INSERT INTO public.recibos_conceptos VALUES (55111, 48, 2970.05, 1815);
INSERT INTO public.recibos_conceptos VALUES (55112, 49, -2500.00, 1815);
INSERT INTO public.recibos_conceptos VALUES (55166, 45, 873.04, 1798);
INSERT INTO public.recibos_conceptos VALUES (55167, 44, 2649.80, 1801);
INSERT INTO public.recibos_conceptos VALUES (55168, 44, 2649.80, 1802);
INSERT INTO public.recibos_conceptos VALUES (55169, 44, 2649.80, 1806);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 55169, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 1816, true);


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
INSERT INTO public.tabla_personas VALUES (13, 2019, 1, '2019-01-01', 6688.15, 13, 8);
INSERT INTO public.tabla_personas VALUES (14, 2019, 1, '2019-01-01', 5838.00, 17, 8);
INSERT INTO public.tabla_personas VALUES (15, 2019, 1, '2019-01-01', 6577.76, 18, 8);
INSERT INTO public.tabla_personas VALUES (18, 2019, 1, '2019-01-01', 1044.52, 10, 8);
INSERT INTO public.tabla_personas VALUES (19, 2019, 1, '2019-01-01', 7406.84, 24, 8);
INSERT INTO public.tabla_personas VALUES (20, 2019, 1, '2019-01-01', 851.84, 24, 7);
INSERT INTO public.tabla_personas VALUES (21, 2019, 1, '2019-01-01', 5838.00, 26, 8);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 21, true);


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
INSERT INTO public.tipo_liquidacion_conceptos VALUES (123, 47, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (124, 46, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (125, 47, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (127, 46, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (128, 47, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (129, 46, 4);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (130, 8, 1);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (131, 8, 3);
INSERT INTO public.tipo_liquidacion_conceptos VALUES (132, 8, 4);


--
-- Name: tipo_liquidacion_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 132, true);


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
    ADD CONSTRAINT uk_tabla_personas UNIQUE (id_tabla, id_persona, anio, mes);


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

