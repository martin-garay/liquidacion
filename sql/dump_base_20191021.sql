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
-- Name: sp_volver_a_estado_inicial(integer); Type: FUNCTION; Schema: public; Owner: -
--

CREATE FUNCTION public.sp_volver_a_estado_inicial(_id_liquidacion integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
declare 
	_id_estado integer;
begin 
	select id_estado into _id_estado from liquidaciones where id=_id_liquidacion;
	IF _id_estado=2 THEN

		update liquidaciones set id_estado=1 where id=_id_liquidacion;

		update recibos set total_remunerativos=null,total_no_remunerativos=null,total_deducciones=null,total_neto=null,json_variables=null
		where id_liquidacion=_id_liquidacion;

		update recibos_conceptos set importe=null where id_recibo in (select id from recibos where id_liquidacion=_id_liquidacion);

		delete from recibos_acumuladores where id_recibo in (select id from recibos where id_liquidacion=_id_liquidacion);
	
	END IF;
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
-- Name: historico_sueldo_basico; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_sueldo_basico (
    id integer NOT NULL,
    mes integer NOT NULL,
    anio integer NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    descripcion character varying(255)
);


--
-- Name: historico_sueldo_basico_detalle; Type: TABLE; Schema: public; Owner: -
--

CREATE TABLE public.historico_sueldo_basico_detalle (
    id integer NOT NULL,
    id_persona integer NOT NULL,
    basico numeric(10,2) NOT NULL,
    id_cabecera integer NOT NULL
);


--
-- Name: historico_sueldo_basico_detalle_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historico_sueldo_basico_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historico_sueldo_basico_detalle_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historico_sueldo_basico_detalle_id_seq OWNED BY public.historico_sueldo_basico_detalle.id;


--
-- Name: historico_sueldo_basico_id_seq; Type: SEQUENCE; Schema: public; Owner: -
--

CREATE SEQUENCE public.historico_sueldo_basico_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: historico_sueldo_basico_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: -
--

ALTER SEQUENCE public.historico_sueldo_basico_id_seq OWNED BY public.historico_sueldo_basico.id;


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
    id_recibo integer NOT NULL,
    importe_fijo numeric(10,2)
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
    a.hora_salida,
    a.basico
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

ALTER TABLE ONLY public.historico_sueldo_basico ALTER COLUMN id SET DEFAULT nextval('public.historico_sueldo_basico_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_sueldo_basico_detalle ALTER COLUMN id SET DEFAULT nextval('public.historico_sueldo_basico_detalle_id_seq'::regclass);


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
INSERT INTO public.conceptos VALUES (46, 'Vacaciones', '200', 1, 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', true, true, false, 'Plus Vacacional.
En bruto tengo el proporcional y tengo que calcular el total del sueldo bruto sin el proporcional a los dias trabajados (basico/diasmes*diastrab).', NULL, true, false);
INSERT INTO public.conceptos VALUES (48, 'A cuenta de futuros aumentos', '30', 1, NULL, true, true, false, 'Es un valor agregado por el operador', NULL, true, false);
INSERT INTO public.conceptos VALUES (49, 'Asig. Decreto 1043/2018', '60', 1, NULL, true, true, false, 'Valor ingresado por el operador', NULL, false, true);
INSERT INTO public.conceptos VALUES (50, 'Vacaciones', '201', 1, NULL, true, true, false, 'El valor de este concepto es ingresado por el usuario', NULL, false, false);
INSERT INTO public.conceptos VALUES (51, 'Adicional 51860', '5', 1, NULL, true, true, false, NULL, NULL, true, false);
INSERT INTO public.conceptos VALUES (39, 'IMPUESTO A LAS GANANCIAS', '515', 2, 'c370 - ganancia_acumulada', true, true, false, 'c370: Valor Final del calculo de ganancia mensual - el acumulado del año hasta el periodo de la liquidacion', NULL, false, false);
INSERT INTO public.conceptos VALUES (47, 'Bruto Sin Proporcional', '199', 1, 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', false, false, false, 'Si hay vacaciones se calcula un proporcional. Este concepto muestra el total sin tener en cuenta el proporcional. VER c1', NULL, false, false);
INSERT INTO public.conceptos VALUES (1, 'Sueldo Básico', '1', 1, 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', true, true, true, 'Si se toma vacaciones calculo el proporcional a los dias trabajados.
En el caso de que se tome todos los dias del mes devueve el basico.', NULL, true, false);


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

INSERT INTO public.historico_liquidaciones VALUES (111, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 3, 1, 2019, 1, 'Galicia', 'CERRADA', 'Liquidación Mensual Normal', 'Asociación Médica de Luján', 'Mariano Moreno 1460', 'LUJAN', '3450', 'Corrientes', '33539819769', '911200', 1, 'Dec 814/01, art. 2, inc. B', '2019-01-29', 'Enero');


--
-- Data for Name: historico_liquidaciones_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_liquidaciones_conceptos VALUES (2712, 4, 111, NULL, 'Idem Sueldo Basico', '90', 'c1', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2744, 9, 111, NULL, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2745, 10, 111, NULL, 'Obra Social', '502', 'bruto * 0.03', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2711, 12, 111, NULL, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2713, 5, 111, NULL, 'Años Reconocimiento', '101', '0', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2714, 6, 111, NULL, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2726, 22, 111, NULL, 'Ganancia Neta Mensual', '321', 'c309-c320', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2721, 17, 111, NULL, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2722, 18, 111, NULL, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2723, 19, 111, NULL, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2724, 20, 111, NULL, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2725, 21, 111, NULL, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2718, 14, 111, 0.00, 'Ganancias - Gratificaciones', '302', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2719, 16, 111, 0.00, 'Ganancias - SAC', '303', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2720, 15, 111, NULL, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2736, 31, 111, NULL, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2741, 37, 111, NULL, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2732, 29, 111, 0.00, 'Deducciones. Cargas de familia', '333', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2735, 30, 111, 0.00, 'Deducciones. Servicio doméstico', '336', '0', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2727, 23, 111, NULL, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2728, 32, 111, NULL, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2742, 38, 111, NULL, 'Ganancia neta imponible', '360', 'c322 - c350', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2730, 25, 111, NULL, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2731, 26, 111, NULL, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2733, 27, 111, NULL, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2734, 28, 111, NULL, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2717, 13, 111, NULL, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2743, 40, 111, NULL, 'Ganancia Escala', '370', 'ganancias(c360)', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2729, 24, 111, NULL, 'Deducción. Especial', '330', 'tabla("especial")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2738, 34, 111, NULL, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2737, 33, 111, NULL, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2739, 35, 111, NULL, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2740, 36, 111, NULL, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 'CALCULO GANANCIAS');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2710, 42, 111, NULL, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2709, 7, 111, NULL, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2746, 11, 111, NULL, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2716, 46, 111, NULL, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2748, 48, 111, 0.00, 'A cuenta de futuros aumentos', '30', NULL, 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2749, 49, 111, 0.00, 'Asig. Decreto 1043/2018', '60', NULL, 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2747, 39, 111, NULL, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 'DEDUCCIONES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2715, 47, 111, NULL, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 'HABERES');
INSERT INTO public.historico_liquidaciones_conceptos VALUES (2708, 1, 111, NULL, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 'HABERES');


--
-- Data for Name: historico_recibos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos VALUES (1810, 6, 21, 38062.27, -2500.00, 7422.14, 28140.13, NULL, 111, 'Paccor', 'Maria Soledad', 35, 'DNI', '27033687', 'Femenino', 1, 'Soltero/a', '1979-03-05', 40, 'Capitalización', '27270336871', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2014-11-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1811, 7, 22, 37997.43, -2500.00, 7409.50, 28087.93, NULL, 111, 'Paris', 'Alejandra', 39, 'DNI', '30939775', 'Femenino', 1, 'Soltero/a', '1984-05-06', 35, 'Capitalización', '23309397754', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2016-07-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1812, 8, 23, 46604.68, -2500.00, 9087.91, 35016.77, NULL, 111, 'Parra', 'Jorgelina', 23, 'DNI', '25048843', 'Femenino', 1, 'Soltero/a', '1976-05-11', 43, 'Sipa', '27250488438', 3, '1RA.ADM', 'Secretaria', 60000.00, '2007-07-02', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1813, 9, 24, 62610.94, -2500.00, 12356.12, 47754.82, NULL, 111, 'Poletti', 'Norma', 2, 'DNI', '18601061', 'Femenino', 2, 'Casado/a', '1967-11-07', 51, 'Sipa', '27186010618', 2, '2DA.SUPERV', 'Encargada', 40000.00, '1986-09-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1814, 10, 25, 34439.68, -2500.00, 6715.74, 25223.94, NULL, 111, 'Riccardo', 'Lautaro', 33, 'DNI', '32378152', 'Masculino', 1, 'Soltero/a', '1986-05-29', 33, 'Reparto', '20323781525', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1815, 11, 26, 97033.56, -2500.00, 27152.38, 67381.18, NULL, 111, 'Romero', 'Ana Gladys', 3, 'DNI', '18148598', 'Femenino', 3, 'Divorciado/a', '1966-05-04', 53, 'Sipa', '27181485987', 1, '1RA.SUPERV', 'Responsable,Ad./Jefa de Personal', 50000.00, '1986-11-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1816, 12, 7, 33355.18, -2500.00, 6337.46, 24517.72, NULL, 111, 'Zeppa', 'Silvio', 40, 'DNI', '26563056', 'Masculino', 2, 'Casado/a', '1978-05-20', 41, 'Capitalización', '20265630562', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2017-04-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1797, 13, 8, 39741.54, -2500.00, 7749.60, 29491.94, NULL, 111, 'Acosta', 'Claudio Daniel', 29, 'DNI', '26823601', 'Masculino', 2, 'Casado/a', '1978-07-18', 41, 'Sipa', '20268236016', 4, '2DA.ADM', 'ay.sub area,facturacion', 50000.00, '2011-04-06', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, 'Mariano Moreno 1460', 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1798, 14, 9, 51.98, -2500.00, 10.14, -2458.16, NULL, 111, 'Becaj', 'Ivan Guillermo', 31, 'DNI', '26583833', 'Masculino', 1, 'Soltero/a', '1978-05-01', 41, 'Reparto', '20265838333', 2, '2DA.SUPERV', 'ay.sub area,facturacion,convenios', 40000.00, '2013-06-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1799, 15, 10, 62575.73, -2500.00, 12574.86, 47500.87, NULL, 111, 'Cano', 'Silvia Marina', 5, 'DNI', '14490100', 'Femenino', 2, 'Casado/a', '1960-12-22', 58, 'Sipa', '27144901008', 2, '2DA.SUPERV', 'ay.sub area,facturacion', 40000.00, '1988-12-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1800, 16, 11, 24920.83, -1700.00, 4859.56, 18361.27, NULL, 111, 'Cespedes Ramirez', 'Teresita', 8, 'DNI', '92727141', 'Femenino', 3, 'Divorciado/a', '1965-05-20', 54, 'Sipa', '27927271414', 5, 'Maestranza', 'maestr.y serv.', 35000.00, '2010-03-01', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1801, 17, 12, 36891.92, -2500.00, 7193.93, 27198.00, NULL, 111, 'Dandrilli', 'Gisela Elizabeth', 34, 'DNI', '30939944', 'Femenino', 2, 'Casado/a', '1984-08-04', 35, 'Capitalización', '27309399442', 4, '2DA.ADM', 'ay.sub area,ioma', 50000.00, '2014-02-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1802, 18, 13, 74634.16, -2500.00, 17607.21, 54526.95, NULL, 111, 'Delgado', 'Noemi Severa', 7, 'DNI', '12904169', 'Femenino', 1, 'Soltero/a', '1956-10-27', 62, 'Sipa', '27129041698', 2, '2DA.SUPERV', 'Encargada,sub area ioma', 40000.00, '1986-07-14', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1803, 19, 14, 16050.83, -1125.00, 3129.91, 11795.91, NULL, 111, 'Echenique', 'Cesar Anibal', 37, 'DNI', '27113644', 'Masculino', 1, 'Soltero/a', '1978-12-24', 40, 'Reparto', '20271136448', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2015-06-01', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1804, 20, 15, 28481.44, -1400.00, 5553.88, 21527.56, NULL, 111, 'Ferrari', 'Maria Cecilia', 26, 'DNI', '29594863', 'Femenino', 1, 'Soltero/a', '1982-07-25', 37, 'Sipa', '27295948634', 3, '1RA.ADM', 'ay.sub area,facturacion', 60000.00, '2008-02-20', NULL, 2, 'a tiempo parcial', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1805, 1, 16, 40027.91, -2500.00, 7805.44, 29722.47, NULL, 111, 'Ferreyra', 'Rodrigo Raul', 32, 'DNI', '34831908', 'Masculino', 1, 'Soltero/a', '1989-10-10', 30, 'Reparto', '20348319087', 4, '2DA.ADM', 'ay.sub area,fact.ioma', 50000.00, '2013-10-07', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1806, 2, 17, 63020.79, -2500.00, 13373.58, 47147.21, NULL, 111, 'Frascaroli', 'Micaela Noemi', 19, 'DNI', '29233345', 'Femenino', 1, 'Soltero/a', '1982-02-27', 37, 'Sipa', '27292333450', 2, '2DA.SUPERV', 'Area Contable', 40000.00, '2003-10-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1807, 3, 18, 57313.70, -2500.00, 11619.58, 43194.12, NULL, 111, 'Gallesio', 'Betiana Nazareth', 21, 'DNI', '26167199', 'Femenino', 1, 'Soltero/a', '1978-01-04', 41, 'Sipa', '27261671994', 2, '2DA.SUPERV', 'Encargada,sub area ioma', 40000.00, '2006-11-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1808, 4, 19, 59879.31, -2500.00, 11931.43, 45447.88, NULL, 111, 'Herrera', 'Claudia Fabiana', 10, 'DNI', '16833436', 'Femenino', 2, 'Casado/a', '1965-04-28', 54, 'Sipa', '27168334368', 3, '1RA.ADM', 'sub area ioma', 60000.00, '1994-08-01', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');
INSERT INTO public.historico_recibos VALUES (1809, 5, 20, 49518.70, -2500.00, 9656.15, 37362.55, NULL, 111, 'Lombardo', 'Norma Elizabeth', 27, 'DNI', '14097779', 'Femenino', 2, 'Casado/a', '1960-11-25', 58, 'Sipa', '27140977794', 2, '2DA.SUPERV', 'sub area ioma', 40000.00, '2009-08-03', NULL, 1, 'a tiempo comp.', 1, 'swiss medical', '406', 1, 'LUJAN', 3450, NULL, 1, 'Argentino', 'Argentina', 'Corrientes', 1, 'Asociación Médica de Luján');


--
-- Data for Name: historico_recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_acumuladores VALUES (8061, 1, 40027.91, 1805, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8062, 2, -2500.00, 1805, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8063, 3, 40027.91, 1805, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8064, 4, -2500.00, 1805, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8065, 5, 7805.44, 1805, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8066, 1, 63020.79, 1806, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8067, 2, -2500.00, 1806, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8068, 3, 63020.79, 1806, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8069, 4, -2500.00, 1806, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8070, 5, 13373.58, 1806, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8071, 1, 57313.70, 1807, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8072, 2, -2500.00, 1807, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8073, 3, 57313.70, 1807, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8074, 4, -2500.00, 1807, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8075, 5, 11619.58, 1807, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8076, 1, 59879.31, 1808, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8077, 2, -2500.00, 1808, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8078, 3, 59879.31, 1808, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8079, 4, -2500.00, 1808, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8080, 5, 11931.43, 1808, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8081, 1, 49518.70, 1809, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8082, 2, -2500.00, 1809, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8083, 3, 49518.70, 1809, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8084, 4, -2500.00, 1809, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8085, 5, 9656.15, 1809, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8086, 1, 38062.27, 1810, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8087, 2, -2500.00, 1810, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8088, 3, 38062.27, 1810, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8089, 4, -2500.00, 1810, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8090, 5, 7422.14, 1810, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8091, 1, 37997.43, 1811, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8092, 2, -2500.00, 1811, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8093, 3, 37997.43, 1811, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8094, 4, -2500.00, 1811, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8095, 5, 7409.50, 1811, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8096, 1, 46604.68, 1812, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8097, 2, -2500.00, 1812, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8098, 3, 46604.68, 1812, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8099, 4, -2500.00, 1812, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8100, 5, 9087.91, 1812, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8101, 1, 62610.94, 1813, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8102, 2, -2500.00, 1813, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8103, 3, 62610.94, 1813, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8104, 4, -2500.00, 1813, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8105, 5, 12356.12, 1813, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8106, 1, 34439.68, 1814, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8107, 2, -2500.00, 1814, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8108, 3, 34439.68, 1814, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8109, 4, -2500.00, 1814, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8110, 5, 6715.74, 1814, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8111, 1, 97033.56, 1815, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8112, 2, -2500.00, 1815, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8113, 3, 97033.56, 1815, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8114, 4, -2500.00, 1815, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8115, 5, 27152.38, 1815, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8116, 1, 33355.18, 1816, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8117, 2, -2500.00, 1816, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8118, 3, 33355.18, 1816, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8119, 4, -2500.00, 1816, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8120, 5, 6337.46, 1816, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8121, 1, 39741.54, 1797, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8122, 2, -2500.00, 1797, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8123, 3, 39741.54, 1797, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8124, 4, -2500.00, 1797, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8125, 5, 7749.60, 1797, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8126, 1, 51.98, 1798, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8127, 2, -2500.00, 1798, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8128, 3, 51.98, 1798, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8129, 4, -2500.00, 1798, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8130, 5, 10.14, 1798, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8131, 1, 62575.73, 1799, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8132, 2, -2500.00, 1799, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8133, 3, 62575.73, 1799, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8134, 4, -2500.00, 1799, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8135, 5, 12574.86, 1799, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8136, 1, 24920.83, 1800, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8137, 2, -1700.00, 1800, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8138, 3, 24920.83, 1800, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8139, 4, -1700.00, 1800, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8140, 5, 4859.56, 1800, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8141, 1, 36891.92, 1801, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8142, 2, -2500.00, 1801, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8143, 3, 36891.92, 1801, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8144, 4, -2500.00, 1801, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8145, 5, 7193.93, 1801, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8146, 1, 74634.16, 1802, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8147, 2, -2500.00, 1802, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8148, 3, 74634.16, 1802, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8149, 4, -2500.00, 1802, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8150, 5, 17607.21, 1802, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8151, 1, 16050.83, 1803, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8152, 2, -1125.00, 1803, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8153, 3, 16050.83, 1803, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8154, 4, -1125.00, 1803, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8155, 5, 3129.91, 1803, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8156, 1, 28481.44, 1804, 'total_remunerativos', 'Acumula los Haberes Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8157, 2, -1400.00, 1804, 'total_no_remunerativos', 'Acumula los Haberes No Remunerativos', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8158, 3, 28481.44, 1804, 'bruto', 'Sueldo Bruto', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8159, 4, -1400.00, 1804, 'total_haberes', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 1, 'HABERES');
INSERT INTO public.historico_recibos_acumuladores VALUES (8160, 5, 5553.88, 1804, 'total_deducciones', 'Solo los que se muestran en el reciboNo puedo hacer este calculo. corregir', 2, 'DEDUCCIONES');


--
-- Data for Name: historico_recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_recibos_conceptos VALUES (54319, 4, 28027.12, 1797, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54361, 4, 8725.71, 1798, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54403, 4, 36809.25, 1799, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54445, 4, 19136.11, 1800, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54487, 4, 28051.97, 1801, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54529, 4, 38150.89, 1802, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54571, 4, 13537.16, 1803, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54613, 4, 20037.91, 1804, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54655, 4, 27965.08, 1805, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54697, 4, 39134.63, 1806, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54739, 4, 32407.03, 1807, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54781, 4, 33068.34, 1808, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54823, 4, 33913.59, 1809, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54865, 4, 29170.23, 1810, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54907, 4, 29084.74, 1811, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54949, 4, 31052.42, 1812, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54991, 4, 35983.30, 1813, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55033, 4, 27905.80, 1814, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55075, 4, 44516.50, 1815, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55117, 4, 27909.93, 1816, 'Idem Sueldo Basico', '90', 'c1', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57626, 8, 4371.57, 1797, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57627, 8, 5.72, 1798, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57628, 8, 6883.33, 1799, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57629, 8, 2741.29, 1800, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57630, 8, 4058.11, 1801, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57631, 8, 8209.76, 1802, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57632, 8, 1765.59, 1803, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57633, 8, 3132.96, 1804, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57634, 8, 4403.07, 1805, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57635, 8, 6932.29, 1806, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57636, 8, 6304.51, 1807, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57637, 8, 6586.72, 1808, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57638, 8, 5447.06, 1809, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57639, 8, 4186.85, 1810, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57640, 8, 4179.72, 1811, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57641, 8, 5126.52, 1812, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57642, 8, 6887.20, 1813, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57643, 8, 3788.36, 1814, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57644, 8, 10673.69, 1815, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (57645, 8, 3669.07, 1816, 'Jubilacion', '500', 'bruto * 0.11', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54351, 9, 1192.25, 1797, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54393, 9, 1.56, 1798, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54435, 9, 1877.27, 1799, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54477, 9, 747.62, 1800, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54519, 9, 1106.76, 1801, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54561, 9, 2239.02, 1802, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54603, 9, 481.52, 1803, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54645, 9, 854.44, 1804, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54687, 9, 1200.84, 1805, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54729, 9, 1890.62, 1806, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54771, 9, 1719.41, 1807, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54813, 9, 1796.38, 1808, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54855, 9, 1485.56, 1809, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54897, 9, 1141.87, 1810, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54939, 9, 1139.92, 1811, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54981, 9, 1398.14, 1812, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55023, 9, 1878.33, 1813, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55065, 9, 1033.19, 1814, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55107, 9, 2911.01, 1815, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55149, 9, 1000.66, 1816, 'INNSJP-LEY 1903', '501', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54352, 10, 1192.25, 1797, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54394, 10, 1.56, 1798, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54436, 10, 1877.27, 1799, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54478, 10, 747.62, 1800, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54520, 10, 1106.76, 1801, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54562, 10, 2239.02, 1802, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54604, 10, 481.52, 1803, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54646, 10, 854.44, 1804, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54688, 10, 1200.84, 1805, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54730, 10, 1890.62, 1806, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54772, 10, 1719.41, 1807, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54814, 10, 1796.38, 1808, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54856, 10, 1485.56, 1809, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54898, 10, 1141.87, 1810, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54940, 10, 1139.92, 1811, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54982, 10, 1398.14, 1812, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55024, 10, 1878.33, 1813, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55066, 10, 1033.19, 1814, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55108, 10, 2911.01, 1815, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55150, 10, 1000.66, 1816, 'Obra Social', '502', 'bruto * 0.03', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54318, 12, 2802.71, 1797, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54360, 12, 3272.14, 1798, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54402, 12, 3680.93, 1799, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54444, 12, 1913.61, 1800, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54486, 12, 2805.20, 1801, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54528, 12, 3815.09, 1802, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54570, 12, 1353.72, 1803, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54612, 12, 2003.79, 1804, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54654, 12, 2796.51, 1805, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54696, 12, 3913.46, 1806, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54738, 12, 3240.70, 1807, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54780, 12, 3306.83, 1808, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54822, 12, 3391.36, 1809, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54864, 12, 2917.02, 1810, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54906, 12, 2908.47, 1811, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54948, 12, 3105.24, 1812, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54990, 12, 3598.33, 1813, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55032, 12, 2790.58, 1814, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55074, 12, 4451.65, 1815, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55116, 12, 2790.99, 1816, 'Presentismo', '10', 'si( igual(inasistencias, 0) , ( basico*0.1 ) , 0 )', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54320, 5, 0.00, 1797, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54362, 5, 0.00, 1798, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54404, 5, 0.00, 1799, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54446, 5, 0.00, 1800, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54488, 5, 0.00, 1801, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54530, 5, 0.00, 1802, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54572, 5, 0.00, 1803, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54614, 5, 0.00, 1804, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54656, 5, 0.00, 1805, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54698, 5, 0.00, 1806, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54740, 5, 0.00, 1807, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54782, 5, 3.00, 1808, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54824, 5, 0.00, 1809, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54866, 5, 0.00, 1810, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54908, 5, 0.00, 1811, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54950, 5, 0.00, 1812, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54992, 5, 0.00, 1813, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55034, 5, 0.00, 1814, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55076, 5, 0.00, 1815, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55118, 5, 0.00, 1816, 'Años Reconocimiento', '101', '0', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54321, 6, 3923.80, 1797, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54363, 6, 872.57, 1798, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54405, 6, 22085.55, 1799, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54447, 6, 3061.78, 1800, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54489, 6, 2244.16, 1801, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54531, 6, 24416.57, 1802, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54573, 6, 812.23, 1803, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54615, 6, 4007.58, 1804, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54657, 6, 2796.51, 1805, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54699, 6, 11740.39, 1806, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54741, 6, 7777.69, 1807, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54783, 6, 17856.90, 1808, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54825, 6, 6104.45, 1809, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54867, 6, 2333.62, 1810, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54909, 6, 1163.39, 1811, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54951, 6, 6831.53, 1812, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54993, 6, 23029.31, 1813, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55035, 6, 2790.58, 1814, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55077, 6, 28490.56, 1815, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55119, 6, 558.20, 1816, 'Antiguedad', '102', 'c90 * ( antiguedad + c101 ) * 0.02', 1, 'HABERES', true, false, true, NULL, true, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54333, 22, 34657.94, 1797, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54375, 22, 45.33, 1798, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54417, 22, 54571.25, 1799, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54459, 22, 21733.04, 1800, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54501, 22, 32172.83, 1801, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54543, 22, 65087.21, 1802, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54585, 22, 13997.66, 1803, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54627, 22, 24838.19, 1804, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54669, 22, 34907.67, 1805, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54711, 22, 54959.38, 1806, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54753, 22, 49982.32, 1807, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54795, 22, 52219.75, 1808, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54837, 22, 43184.43, 1809, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54879, 22, 33193.47, 1810, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54921, 22, 33136.92, 1811, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54963, 22, 40643.17, 1812, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55005, 22, 54601.96, 1813, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55047, 22, 30034.27, 1814, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55089, 22, 84621.35, 1815, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55131, 22, 29088.50, 1816, 'Ganancia Neta Mensual', '321', 'c309-c320', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54328, 17, 4735.87, 1797, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54370, 17, 6.19, 1798, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54412, 17, 7456.94, 1799, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54454, 17, 2969.73, 1800, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54496, 17, 4396.29, 1801, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54538, 17, 8893.90, 1802, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54580, 17, 1912.72, 1803, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54622, 17, 3394.04, 1804, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54664, 17, 4769.99, 1805, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54706, 17, 7509.98, 1806, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54748, 17, 6829.88, 1807, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54790, 17, 7135.62, 1808, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54832, 17, 5900.98, 1809, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54874, 17, 4535.75, 1810, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54916, 17, 4528.03, 1811, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54958, 17, 5553.72, 1812, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55000, 17, 7461.14, 1813, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55042, 17, 4104.06, 1814, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55084, 17, 11563.17, 1815, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55126, 17, 3974.83, 1816, 'Retenciones - Jubilación', '310', 'c309 * 0.11', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54329, 18, 1291.60, 1797, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54371, 18, 1.69, 1798, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54413, 18, 2033.71, 1799, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54455, 18, 809.93, 1800, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54497, 18, 1198.99, 1801, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54539, 18, 2425.61, 1802, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54581, 18, 521.65, 1803, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54623, 18, 925.65, 1804, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54665, 18, 1300.91, 1805, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54707, 18, 2048.18, 1806, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54749, 18, 1862.70, 1807, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54791, 18, 1946.08, 1808, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54833, 18, 1609.36, 1809, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54875, 18, 1237.02, 1810, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54917, 18, 1234.92, 1811, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54959, 18, 1514.65, 1812, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55001, 18, 2034.86, 1813, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55043, 18, 1119.29, 1814, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55085, 18, 3153.59, 1815, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55127, 18, 1084.04, 1816, 'Retenciones - Obra Social', '311', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54330, 19, 1291.60, 1797, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54372, 19, 1.69, 1798, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54414, 19, 2033.71, 1799, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54456, 19, 809.93, 1800, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54498, 19, 1198.99, 1801, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54540, 19, 2425.61, 1802, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54582, 19, 521.65, 1803, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54624, 19, 925.65, 1804, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54666, 19, 1300.91, 1805, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54708, 19, 2048.18, 1806, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54750, 19, 1862.70, 1807, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54792, 19, 1946.08, 1808, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54834, 19, 1609.36, 1809, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54876, 19, 1237.02, 1810, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54918, 19, 1234.92, 1811, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54960, 19, 1514.65, 1812, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55002, 19, 2034.86, 1813, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55044, 19, 1119.29, 1814, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55086, 19, 3153.59, 1815, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55128, 19, 1084.04, 1816, 'Retenciones - INNSJP', '312', 'c309 * 0.03', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54331, 20, 1076.33, 1797, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54373, 20, 1.41, 1798, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54415, 20, 1694.76, 1799, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54457, 20, 674.94, 1800, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54499, 20, 999.16, 1801, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54541, 20, 2021.34, 1802, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54583, 20, 434.71, 1803, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54625, 20, 771.37, 1804, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54667, 20, 1084.09, 1805, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54709, 20, 1706.81, 1806, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54751, 20, 1552.25, 1807, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54793, 20, 1621.73, 1808, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54835, 20, 1341.13, 1809, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54877, 20, 1030.85, 1810, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54919, 20, 1029.10, 1811, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54961, 20, 1262.21, 1812, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55003, 20, 1695.71, 1813, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55045, 20, 932.74, 1814, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55087, 20, 2627.99, 1815, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55129, 20, 903.37, 1816, 'Retenciones - Cuota Solidaridad', '313', 'c309 * 0.025', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54332, 21, 8395.40, 1797, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54374, 21, 10.98, 1798, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54416, 21, 13219.12, 1799, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54458, 21, 5264.53, 1800, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54500, 21, 7793.42, 1801, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54542, 21, 15766.47, 1802, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54584, 21, 3390.74, 1803, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54626, 21, 6016.70, 1804, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54668, 21, 8455.90, 1805, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54710, 21, 13313.14, 1806, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54752, 21, 12107.52, 1807, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54794, 21, 12649.50, 1808, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54836, 21, 10460.82, 1809, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54878, 21, 8040.65, 1810, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54920, 21, 8026.96, 1811, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54962, 21, 9845.24, 1812, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55004, 21, 13226.56, 1813, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55046, 21, 7275.38, 1814, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55088, 21, 20498.34, 1815, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54377, 32, 2.27, 1798, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55130, 21, 7046.28, 1816, 'Retenciones - Total Retenciones', '320', 'c310 + c311 + c312 + c313', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54325, 14, 0.00, 1797, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54367, 14, 0.00, 1798, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54409, 14, 0.00, 1799, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54451, 14, 0.00, 1800, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54493, 14, 0.00, 1801, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54535, 14, 0.00, 1802, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54577, 14, 0.00, 1803, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54619, 14, 0.00, 1804, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54661, 14, 0.00, 1805, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54703, 14, 0.00, 1806, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54745, 14, 0.00, 1807, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54787, 14, 0.00, 1808, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54829, 14, 0.00, 1809, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54871, 14, 0.00, 1810, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54913, 14, 0.00, 1811, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54955, 14, 0.00, 1812, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54997, 14, 0.00, 1813, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55039, 14, 0.00, 1814, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55081, 14, 0.00, 1815, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55123, 14, 0.00, 1816, 'Ganancias - Gratificaciones', '302', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54326, 16, 0.00, 1797, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54368, 16, 0.00, 1798, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54410, 16, 0.00, 1799, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54452, 16, 0.00, 1800, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54494, 16, 0.00, 1801, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54536, 16, 0.00, 1802, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54578, 16, 0.00, 1803, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54620, 16, 0.00, 1804, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54662, 16, 0.00, 1805, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54704, 16, 0.00, 1806, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54746, 16, 0.00, 1807, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54788, 16, 0.00, 1808, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54830, 16, 0.00, 1809, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54872, 16, 0.00, 1810, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54914, 16, 0.00, 1811, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54956, 16, 0.00, 1812, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54998, 16, 0.00, 1813, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55040, 16, 0.00, 1814, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55082, 16, 0.00, 1815, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55124, 16, 0.00, 1816, 'Ganancias - SAC', '303', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54327, 15, 43053.34, 1797, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54369, 15, 56.31, 1798, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54411, 15, 67790.37, 1799, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54453, 15, 26997.56, 1800, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54495, 15, 39966.25, 1801, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54537, 15, 80853.67, 1802, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54579, 15, 17388.39, 1803, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54621, 15, 30854.90, 1804, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54663, 15, 43363.57, 1805, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54705, 15, 68272.52, 1806, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54747, 15, 62089.84, 1807, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54789, 15, 64869.25, 1808, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54831, 15, 53645.25, 1809, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54873, 15, 41234.13, 1810, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54915, 15, 41163.88, 1811, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54957, 15, 50488.41, 1812, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54999, 15, 67828.52, 1813, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55041, 15, 37309.65, 1814, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55083, 15, 105119.69, 1815, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55125, 15, 36134.78, 1816, 'Ganancias - tot_rem_bruta', '309', 'bruto +  c301 + c302 + c303', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55167, 44, 2649.80, 1801, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55168, 44, 2649.80, 1802, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55169, 44, 2649.80, 1806, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55160, 44, 2649.80, 1808, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55163, 44, 2649.80, 1812, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55165, 44, 2649.80, 1815, 'Falla de Caja', '51', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54419, 32, 2728.56, 1799, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54343, 31, 0.00, 1797, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54385, 31, 2.27, 1798, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54427, 31, 1044.52, 1799, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54469, 31, 0.00, 1800, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54511, 31, 0.00, 1801, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54553, 31, 3254.36, 1802, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54595, 31, 0.00, 1803, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54637, 31, 0.00, 1804, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54679, 31, 0.00, 1805, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54721, 31, 2747.97, 1806, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54763, 31, 2499.12, 1807, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54805, 31, 0.00, 1808, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54847, 31, 0.00, 1809, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54889, 31, 0.00, 1810, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54931, 31, 0.00, 1811, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54973, 31, 0.00, 1812, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55015, 31, 2730.10, 1813, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55057, 31, 0.00, 1814, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55099, 31, 4231.07, 1815, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55141, 31, 0.00, 1816, 'Deducciones. Prepaga', '337', 'si( igual(informado("prepaga"),0) , 0, si( menor_igual( informado("prepaga"), c323 ) , informado("prepaga"),c323))', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54348, 37, 48163.18, 1797, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54390, 37, 41495.95, 1798, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54432, 37, 49207.70, 1799, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54474, 37, 41493.68, 1800, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54516, 37, 48163.18, 1801, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54558, 37, 44748.04, 1802, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54600, 37, 41493.68, 1803, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54642, 37, 41493.68, 1804, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54684, 37, 41493.68, 1805, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54726, 37, 44241.65, 1806, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54768, 37, 43992.80, 1807, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54810, 37, 48163.18, 1808, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54852, 37, 48163.18, 1809, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54894, 37, 41493.68, 1810, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54936, 37, 41493.68, 1811, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54978, 37, 41493.68, 1812, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55020, 37, 51745.12, 1813, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55062, 37, 41493.68, 1814, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54461, 32, 1086.65, 1800, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55104, 37, 45724.75, 1815, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55146, 37, 48163.18, 1816, 'Total Deducciones', '350', 'c330 +  c331 +  c332 + c333 + c334 + c335 + c336 + c337 + c338 + c339 + c340 + c341', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54339, 29, 0.00, 1797, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54381, 29, 0.00, 1798, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54423, 29, 0.00, 1799, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54465, 29, 0.00, 1800, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54507, 29, 0.00, 1801, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54549, 29, 0.00, 1802, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54591, 29, 0.00, 1803, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54633, 29, 0.00, 1804, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54675, 29, 0.00, 1805, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54717, 29, 0.00, 1806, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54759, 29, 0.00, 1807, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54801, 29, 0.00, 1808, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54843, 29, 0.00, 1809, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54885, 29, 0.00, 1810, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54927, 29, 0.00, 1811, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54969, 29, 0.00, 1812, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55011, 29, 0.00, 1813, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55053, 29, 0.00, 1814, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55095, 29, 0.00, 1815, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55137, 29, 0.00, 1816, 'Deducciones. Cargas de familia', '333', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54342, 30, 0.00, 1797, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54384, 30, 0.00, 1798, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54426, 30, 0.00, 1799, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54468, 30, 0.00, 1800, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54510, 30, 0.00, 1801, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54552, 30, 0.00, 1802, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54594, 30, 0.00, 1803, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54636, 30, 0.00, 1804, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54678, 30, 0.00, 1805, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54720, 30, 0.00, 1806, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54762, 30, 0.00, 1807, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54804, 30, 0.00, 1808, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54846, 30, 0.00, 1809, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54888, 30, 0.00, 1810, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54930, 30, 0.00, 1811, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54972, 30, 0.00, 1812, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55014, 30, 0.00, 1813, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55056, 30, 0.00, 1814, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55098, 30, 0.00, 1815, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55140, 30, 0.00, 1816, 'Deducciones. Servicio doméstico', '336', '0', 4, 'CALCULO GANANCIAS', false, false, false, 0.00, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54334, 23, 34657.94, 1797, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54376, 23, 45.33, 1798, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54418, 23, 54571.25, 1799, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54460, 23, 21733.04, 1800, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54502, 23, 32172.83, 1801, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54544, 23, 65087.21, 1802, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54586, 23, 13997.66, 1803, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54628, 23, 24838.19, 1804, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54670, 23, 34907.67, 1805, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54712, 23, 54959.38, 1806, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54754, 23, 49982.32, 1807, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54796, 23, 52219.75, 1808, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54838, 23, 43184.43, 1809, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54880, 23, 33193.47, 1810, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54922, 23, 33136.92, 1811, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54964, 23, 40643.17, 1812, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55006, 23, 54601.96, 1813, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55048, 23, 30034.27, 1814, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55090, 23, 84621.35, 1815, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55132, 23, 29088.50, 1816, 'Ganancia Neta Acumulada', '322', 'c321 + ganancia_neta_acumulada', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54335, 32, 1732.90, 1797, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54503, 32, 1608.64, 1801, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54545, 32, 3254.36, 1802, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54587, 32, 699.88, 1803, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54629, 32, 1241.91, 1804, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54671, 32, 1745.38, 1805, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54713, 32, 2747.97, 1806, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54755, 32, 2499.12, 1807, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54797, 32, 2610.99, 1808, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54839, 32, 2159.22, 1809, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54881, 32, 1659.67, 1810, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54923, 32, 1656.85, 1811, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54965, 32, 2032.16, 1812, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55007, 32, 2730.10, 1813, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55049, 32, 1501.71, 1814, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55091, 32, 4231.07, 1815, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55133, 32, 1454.42, 1816, 'Prepaga (5% del sueldo neto)', '323', 'c322 * 0.05', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54349, 38, -13505.24, 1797, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54391, 38, -41450.62, 1798, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54433, 38, 5363.55, 1799, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54475, 38, -19760.64, 1800, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54517, 38, -15990.35, 1801, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54559, 38, 20339.17, 1802, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54601, 38, -27496.02, 1803, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54643, 38, -16655.49, 1804, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54685, 38, -6586.01, 1805, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54727, 38, 10717.73, 1806, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54769, 38, 5989.52, 1807, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54811, 38, 4056.57, 1808, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54853, 38, -4978.75, 1809, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54895, 38, -8300.21, 1810, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54937, 38, -8356.76, 1811, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54979, 38, -850.51, 1812, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55021, 38, 2856.84, 1813, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55063, 38, -11459.41, 1814, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55105, 38, 38896.60, 1815, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55147, 38, -19074.68, 1816, 'Ganancia neta imponible', '360', 'c322 - c350', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54337, 25, 6669.50, 1797, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54379, 25, 0.00, 1798, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54421, 25, 6669.50, 1799, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54463, 25, 0.00, 1800, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54505, 25, 6669.50, 1801, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54547, 25, 0.00, 1802, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54589, 25, 0.00, 1803, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54631, 25, 0.00, 1804, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54673, 25, 0.00, 1805, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54715, 25, 0.00, 1806, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54757, 25, 0.00, 1807, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54799, 25, 6669.50, 1808, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54841, 25, 6669.50, 1809, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54883, 25, 0.00, 1810, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54925, 25, 0.00, 1811, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54967, 25, 0.00, 1812, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55009, 25, 6669.50, 1813, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55051, 25, 0.00, 1814, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55093, 25, 0.00, 1815, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55135, 25, 6669.50, 1816, 'Deduccion. Conyuge', '331', 'si( casado , tabla("conyuge") , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54338, 26, 0.00, 1797, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54380, 26, 0.00, 1798, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54422, 26, 0.00, 1799, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54464, 26, 0.00, 1800, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54506, 26, 0.00, 1801, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54548, 26, 0.00, 1802, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54590, 26, 0.00, 1803, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54632, 26, 0.00, 1804, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54674, 26, 0.00, 1805, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54716, 26, 0.00, 1806, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54758, 26, 0.00, 1807, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54800, 26, 0.00, 1808, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54842, 26, 0.00, 1809, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54884, 26, 0.00, 1810, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54926, 26, 0.00, 1811, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54968, 26, 0.00, 1812, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55010, 26, 0.00, 1813, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55052, 26, 0.00, 1814, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55094, 26, 0.00, 1815, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55136, 26, 0.00, 1816, 'Deducciones. Hijos', '332', 'si( mayor(hijos,0) , tabla("hijo") * hijos , 0 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54340, 27, 7154.08, 1797, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54382, 27, 7154.08, 1798, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54424, 27, 7154.08, 1799, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54466, 27, 7154.08, 1800, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54508, 27, 7154.08, 1801, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54550, 27, 7154.08, 1802, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54592, 27, 7154.08, 1803, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54634, 27, 7154.08, 1804, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54676, 27, 7154.08, 1805, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54718, 27, 7154.08, 1806, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54760, 27, 7154.08, 1807, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54802, 27, 7154.08, 1808, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54844, 27, 7154.08, 1809, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54886, 27, 7154.08, 1810, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54928, 27, 7154.08, 1811, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54970, 27, 7154.08, 1812, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55012, 27, 7154.08, 1813, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55054, 27, 7154.08, 1814, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55096, 27, 7154.08, 1815, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55138, 27, 7154.08, 1816, 'Deducciones. Ganancia no imponible', '334', 'tabla("ganancia")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54341, 28, 0.00, 1797, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54383, 28, 0.00, 1798, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54425, 28, 0.00, 1799, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54467, 28, 0.00, 1800, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54509, 28, 0.00, 1801, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54551, 28, 0.00, 1802, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54593, 28, 0.00, 1803, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54635, 28, 0.00, 1804, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54677, 28, 0.00, 1805, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54719, 28, 0.00, 1806, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54761, 28, 0.00, 1807, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54803, 28, 0.00, 1808, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54845, 28, 0.00, 1809, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54887, 28, 0.00, 1810, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54929, 28, 0.00, 1811, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54971, 28, 0.00, 1812, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55013, 28, 0.00, 1813, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55055, 28, 0.00, 1814, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55097, 28, 0.00, 1815, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55139, 28, 0.00, 1816, 'Deducciones. Intereses créditos hipotecarios', '335', 'informado("hipoteca")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54324, 13, 3311.80, 1797, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54366, 13, 4.33, 1798, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54408, 13, 5214.64, 1799, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54450, 13, 2076.74, 1800, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54492, 13, 3074.33, 1801, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54534, 13, 6219.51, 1802, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54576, 13, 1337.57, 1803, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54618, 13, 2373.45, 1804, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54660, 13, 3335.66, 1805, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54702, 13, 5251.73, 1806, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54744, 13, 4776.14, 1807, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54786, 13, 4989.94, 1808, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54828, 13, 4126.56, 1809, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54870, 13, 3171.86, 1810, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54912, 13, 3166.45, 1811, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54954, 13, 3883.72, 1812, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54996, 13, 5217.58, 1813, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55038, 13, 2869.97, 1814, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55080, 13, 8086.13, 1815, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55122, 13, 2779.60, 1816, 'Ganancias - SAC Devengado', '301', 'si(  calculasac  , (maxsueldo/2) - sumsac , bruto/12 )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54350, 40, 0.00, 1797, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54392, 40, 0.00, 1798, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54434, 40, 372.59, 1799, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54476, 40, 0.00, 1800, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54518, 40, 0.00, 1801, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54560, 40, 3053.55, 1802, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54602, 40, 0.00, 1803, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54644, 40, 0.00, 1804, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54686, 40, 0.00, 1805, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54728, 40, 1084.53, 1806, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54770, 40, 443.41, 1807, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54812, 40, 254.96, 1808, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54854, 40, 0.00, 1809, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54896, 40, 0.00, 1810, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54938, 40, 0.00, 1811, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54980, 40, 0.00, 1812, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55022, 40, 146.99, 1813, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55064, 40, 0.00, 1814, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55106, 40, 8230.84, 1815, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55148, 40, 0.00, 1816, 'Ganancia Escala', '370', 'ganancias(c360)', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54336, 24, 34339.60, 1797, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54378, 24, 34339.60, 1798, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54420, 24, 34339.60, 1799, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54462, 24, 34339.60, 1800, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54504, 24, 34339.60, 1801, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54546, 24, 34339.60, 1802, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54588, 24, 34339.60, 1803, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54630, 24, 34339.60, 1804, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54672, 24, 34339.60, 1805, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54714, 24, 34339.60, 1806, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54756, 24, 34339.60, 1807, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54798, 24, 34339.60, 1808, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54840, 24, 34339.60, 1809, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54882, 24, 34339.60, 1810, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54924, 24, 34339.60, 1811, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54966, 24, 34339.60, 1812, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55008, 24, 34339.60, 1813, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55050, 24, 34339.60, 1814, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55092, 24, 34339.60, 1815, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55134, 24, 34339.60, 1816, 'Deducción. Especial', '330', 'tabla("especial")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54345, 34, 0.00, 1797, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54387, 34, 0.00, 1798, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54429, 34, 0.00, 1799, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54471, 34, 0.00, 1800, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54513, 34, 0.00, 1801, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54555, 34, 0.00, 1802, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54597, 34, 0.00, 1803, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54639, 34, 0.00, 1804, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54681, 34, 0.00, 1805, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54723, 34, 0.00, 1806, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54765, 34, 0.00, 1807, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54807, 34, 0.00, 1808, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54849, 34, 0.00, 1809, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54891, 34, 0.00, 1810, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54933, 34, 0.00, 1811, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54975, 34, 0.00, 1812, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55017, 34, 851.84, 1813, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55059, 34, 0.00, 1814, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55101, 34, 0.00, 1815, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55143, 34, 0.00, 1816, 'Deducciones. Seguro de Vida', '339', 'si(  igual( informado("segurovida"), 0) , 0 , si(  menor_igual(informado("segurovida"),tope("segurovida"))  , informado("segurovida") , tope("segurovida")  )  )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54344, 33, 0.00, 1797, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54386, 33, 0.00, 1798, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54428, 33, 0.00, 1799, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54470, 33, 0.00, 1800, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54512, 33, 0.00, 1801, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54554, 33, 0.00, 1802, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54596, 33, 0.00, 1803, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54638, 33, 0.00, 1804, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54680, 33, 0.00, 1805, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54722, 33, 0.00, 1806, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54764, 33, 0.00, 1807, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54806, 33, 0.00, 1808, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54848, 33, 0.00, 1809, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54890, 33, 0.00, 1810, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54932, 33, 0.00, 1811, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54974, 33, 0.00, 1812, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55016, 33, 0.00, 1813, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55058, 33, 0.00, 1814, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55100, 33, 0.00, 1815, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55142, 33, 0.00, 1816, 'Deducciones. Gastos Médicos', '338', 'informado("medico")', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54346, 35, 0.00, 1797, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54388, 35, 0.00, 1798, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54430, 35, 0.00, 1799, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54472, 35, 0.00, 1800, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54514, 35, 0.00, 1801, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54556, 35, 0.00, 1802, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54598, 35, 0.00, 1803, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54640, 35, 0.00, 1804, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54682, 35, 0.00, 1805, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54724, 35, 0.00, 1806, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54766, 35, 0.00, 1807, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54808, 35, 0.00, 1808, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54850, 35, 0.00, 1809, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54892, 35, 0.00, 1810, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54934, 35, 0.00, 1811, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54976, 35, 0.00, 1812, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55018, 35, 0.00, 1813, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55060, 35, 0.00, 1814, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55102, 35, 0.00, 1815, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55144, 35, 0.00, 1816, 'Deducciones. Donaciones', '340', 'si( igual( informado("donacion"), 0) , 0 , si( menor_igual(informado("donacion"),tope("donacion")) , informado("donacion") , tope("donacion") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54347, 36, 0.00, 1797, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54389, 36, 0.00, 1798, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54431, 36, 0.00, 1799, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54473, 36, 0.00, 1800, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54515, 36, 0.00, 1801, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54557, 36, 0.00, 1802, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54599, 36, 0.00, 1803, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54778, 7, 0.00, 1808, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54641, 36, 0.00, 1804, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54683, 36, 0.00, 1805, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54725, 36, 0.00, 1806, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54767, 36, 0.00, 1807, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54809, 36, 0.00, 1808, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54851, 36, 0.00, 1809, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54893, 36, 0.00, 1810, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54935, 36, 0.00, 1811, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54977, 36, 0.00, 1812, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55019, 36, 0.00, 1813, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55061, 36, 0.00, 1814, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55103, 36, 0.00, 1815, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55145, 36, 0.00, 1816, 'Deducciones. Alquileres', '341', 'si( igual( informado("alquiler"), 0) , 0 , si( menor_igual(informado("alquiler"),tope("alquiler")) , informado("alquiler") , tope("alquiler") ) )', 4, 'CALCULO GANANCIAS', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55166, 45, 873.04, 1798, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55155, 45, 3376.41, 1802, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55157, 45, 3748.16, 1806, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55158, 45, 4858.79, 1807, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55159, 45, 1166.48, 1808, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55161, 45, 4600.00, 1809, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55162, 45, 1236.63, 1810, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55164, 45, 13955.00, 1815, 'Bonificación por Función', '52', NULL, 1, 'HABERES', true, false, true, 0.00, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54317, 42, 0.00, 1797, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54359, 42, 0.00, 1798, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54401, 42, 0.00, 1799, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54443, 42, 0.00, 1800, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54485, 42, 0.00, 1801, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54527, 42, 0.00, 1802, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54569, 42, 0.00, 1803, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54611, 42, 0.00, 1804, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54653, 42, 0.00, 1805, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54695, 42, 0.00, 1806, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54737, 42, 0.00, 1807, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54779, 42, 0.00, 1808, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54821, 42, 0.00, 1809, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54863, 42, 0.00, 1810, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54905, 42, 0.00, 1811, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54947, 42, 0.00, 1812, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54989, 42, 0.00, 1813, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55031, 42, 0.00, 1814, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55073, 42, 0.00, 1815, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55115, 42, 0.00, 1816, 'Horas Extras 50%', '4', '( c1 / 200 ) * 1.5 * hsextras50', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54316, 7, 3878.95, 1797, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54358, 7, 98.60, 1798, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54400, 7, 0.00, 1799, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54442, 7, 0.00, 1800, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54484, 7, 0.00, 1801, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54526, 7, 0.00, 1802, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54568, 7, 0.00, 1803, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54610, 7, 0.00, 1804, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54652, 7, 5416.84, 1805, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54694, 7, 0.00, 1806, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54736, 7, 7453.62, 1807, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54820, 7, 0.00, 1809, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54862, 7, 1283.49, 1810, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54904, 7, 3801.38, 1811, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54946, 7, 1592.99, 1812, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54988, 7, 0.00, 1813, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55030, 7, 672.53, 1814, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55072, 7, 0.00, 1815, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55114, 7, 1116.40, 1816, 'Horas Extras 100%', '3', '( c1 / 200 ) * 2 *  hsextras100', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54353, 11, 993.54, 1797, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54395, 11, 1.30, 1798, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54437, 11, 1564.39, 1799, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54479, 11, 623.02, 1800, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54521, 11, 922.30, 1801, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54563, 11, 1865.85, 1802, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54605, 11, 401.27, 1803, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54647, 11, 712.04, 1804, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54689, 11, 1000.70, 1805, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54731, 11, 1575.52, 1806, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54773, 11, 1432.84, 1807, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54815, 11, 1496.98, 1808, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54857, 11, 1237.97, 1809, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54899, 11, 951.56, 1810, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54941, 11, 949.94, 1811, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54983, 11, 1165.12, 1812, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55025, 11, 1565.27, 1813, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55067, 11, 860.99, 1814, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55109, 11, 2425.84, 1815, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55151, 11, 667.08, 1816, 'Cuota solidaria Utedyc', '511', 'bruto * 0.025', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54323, 46, 0.00, 1797, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54365, 46, -14123.23, 1798, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54407, 46, 0.00, 1799, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54449, 46, 0.00, 1800, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54491, 46, 0.00, 1801, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54533, 46, 0.00, 1802, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54575, 46, 0.00, 1803, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54617, 46, 0.00, 1804, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54659, 46, 0.00, 1805, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54701, 46, 0.00, 1806, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54743, 46, 0.00, 1807, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54785, 46, 0.00, 1808, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54827, 46, 0.00, 1809, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54869, 46, 0.00, 1810, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54911, 46, 0.00, 1811, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54953, 46, 0.00, 1812, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54995, 46, 0.00, 1813, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55037, 46, 0.00, 1814, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55079, 46, 0.00, 1815, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55121, 46, 0.00, 1816, 'Vacaciones', '200', 'si(igual(diasvacac,0) ,0, (c199/25*diasvacac)-bruto)', 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54355, 48, 1108.96, 1797, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54397, 48, 333.14, 1798, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54439, 48, 0.00, 1799, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54481, 48, 809.33, 1800, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54523, 48, 1140.80, 1801, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54565, 48, 2225.40, 1802, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54607, 48, 347.72, 1803, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54649, 48, 948.83, 1804, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54691, 48, 1052.98, 1805, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54733, 48, 1834.35, 1806, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54775, 48, 1575.87, 1807, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54817, 48, 1830.95, 1808, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54859, 48, 1509.30, 1809, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54901, 48, 1121.28, 1810, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54943, 48, 1039.45, 1811, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54985, 48, 1372.70, 1812, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55027, 48, 0.00, 1813, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55069, 48, 280.19, 1814, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55111, 48, 2970.05, 1815, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55153, 48, 979.66, 1816, 'A cuenta de futuros aumentos', '30', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54356, 49, -2500.00, 1797, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54398, 49, -2500.00, 1798, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54440, 49, -2500.00, 1799, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54482, 49, -1700.00, 1800, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54524, 49, -2500.00, 1801, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54566, 49, -2500.00, 1802, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54608, 49, -1125.00, 1803, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54650, 49, -1400.00, 1804, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54692, 49, -2500.00, 1805, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54734, 49, -2500.00, 1806, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54776, 49, -2500.00, 1807, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54818, 49, -2500.00, 1808, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54860, 49, -2500.00, 1809, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54902, 49, -2500.00, 1810, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54944, 49, -2500.00, 1811, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (54986, 49, -2500.00, 1812, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55028, 49, -2500.00, 1813, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55070, 49, -2500.00, 1814, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55112, 49, -2500.00, 1815, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55154, 49, -2500.00, 1816, 'Asig. Decreto 1043/2018', '60', NULL, 1, 'HABERES', true, false, true, NULL, false, true);
INSERT INTO public.historico_recibos_conceptos VALUES (55156, 51, 1483.33, 1804, 'Adicional 51860', '5', NULL, 1, 'HABERES', true, false, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54354, 39, 0.00, 1797, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54396, 39, 0.00, 1798, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54438, 39, 372.59, 1799, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54480, 39, 0.00, 1800, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54522, 39, 0.00, 1801, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54564, 39, 3053.55, 1802, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54606, 39, 0.00, 1803, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54648, 39, 0.00, 1804, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54690, 39, 0.00, 1805, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54732, 39, 1084.53, 1806, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54774, 39, 443.41, 1807, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54816, 39, 254.96, 1808, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54858, 39, 0.00, 1809, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54900, 39, 0.00, 1810, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54942, 39, 0.00, 1811, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54984, 39, 0.00, 1812, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55026, 39, 146.99, 1813, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55068, 39, 0.00, 1814, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55110, 39, 8230.84, 1815, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55152, 39, 0.00, 1816, 'IMPUESTO A LAS GANANCIAS', '515', 'c370 - ganancia_acumulada', 2, 'DEDUCCIONES', true, false, true, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54322, 47, 39741.54, 1797, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54364, 47, 59.06, 1798, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54406, 47, 62575.73, 1799, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54448, 47, 24920.83, 1800, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54490, 47, 36891.92, 1801, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54532, 47, 74634.16, 1802, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54574, 47, 16050.83, 1803, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54616, 47, 28481.44, 1804, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54658, 47, 40027.91, 1805, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54700, 47, 63020.79, 1806, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54742, 47, 57313.70, 1807, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54784, 47, 59879.31, 1808, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54826, 47, 49518.70, 1809, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54868, 47, 38062.27, 1810, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54910, 47, 37997.43, 1811, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54952, 47, 46604.68, 1812, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54994, 47, 62610.94, 1813, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55036, 47, 34439.68, 1814, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55078, 47, 97033.56, 1815, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55120, 47, 33355.18, 1816, 'Bruto Sin Proporcional', '199', 'si( igual(diasvacac,0) , bruto , bruto/ ( (30-diasvacac)*30) )', 1, 'HABERES', false, false, false, NULL, false, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54315, 1, 28027.12, 1797, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54357, 1, 8725.71, 1798, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54399, 1, 36809.25, 1799, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54441, 1, 19136.11, 1800, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54483, 1, 28051.97, 1801, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54525, 1, 38150.89, 1802, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54567, 1, 13537.16, 1803, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54609, 1, 20037.91, 1804, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54651, 1, 27965.08, 1805, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54693, 1, 39134.63, 1806, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54735, 1, 32407.03, 1807, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54777, 1, 33068.34, 1808, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54819, 1, 33913.59, 1809, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54861, 1, 29170.23, 1810, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54903, 1, 29084.74, 1811, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54945, 1, 31052.42, 1812, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (54987, 1, 35983.30, 1813, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55029, 1, 27905.80, 1814, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55071, 1, 44516.50, 1815, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);
INSERT INTO public.historico_recibos_conceptos VALUES (55113, 1, 27909.93, 1816, 'Sueldo Básico', '1', 'si(  igual(diasvacac,0)  , basico , si( igual(diasmes,diasvacac), basico, basico/ 30 * (30-diasvacac) ))', 1, 'HABERES', true, true, true, NULL, true, false);


--
-- Data for Name: historico_sueldo_basico; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_sueldo_basico VALUES (17, 1, 2019, '2019-10-05 11:43:27.26574', 'BACK ENERO 2019');
INSERT INTO public.historico_sueldo_basico VALUES (18, 2, 2019, '2019-10-05 11:53:35.701614', 'BASICOS FEBREO 2019');
INSERT INTO public.historico_sueldo_basico VALUES (19, 3, 2019, '2019-10-05 11:56:43.35022', 'BASICOS MARZO 2019');
INSERT INTO public.historico_sueldo_basico VALUES (20, 1, 2019, '2019-10-05 11:43:27.26574', 'RESTAURACION DE SUELDOS BASICOS');


--
-- Data for Name: historico_sueldo_basico_detalle; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.historico_sueldo_basico_detalle VALUES (118, 13, 38150.89, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (119, 9, 32721.43, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (120, 19, 33068.34, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (121, 10, 36809.25, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (122, 11, 19136.11, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (123, 12, 28051.97, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (124, 17, 39134.63, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (125, 2, 35983.30, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (126, 14, 13537.16, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (127, 15, 20037.91, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (128, 7, 27909.93, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (129, 8, 28027.12, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (130, 16, 27965.08, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (131, 18, 32407.03, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (132, 20, 33913.59, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (133, 21, 29170.23, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (134, 22, 29084.74, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (135, 23, 31052.42, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (136, 24, 35983.30, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (137, 25, 27905.80, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (138, 26, 44516.50, 17);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (139, 20, 35833.23, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (140, 21, 30821.38, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (141, 22, 30731.05, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (142, 23, 32810.10, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (143, 24, 38020.09, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (144, 17, 39134.63, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (145, 25, 29485.37, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (146, 26, 47036.30, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (147, 2, 35983.30, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (148, 13, 40310.37, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (149, 9, 34573.59, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (150, 10, 38892.80, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (151, 11, 20219.29, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (152, 12, 29639.82, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (153, 14, 14303.41, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (154, 15, 21172.13, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (155, 7, 29489.74, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (156, 8, 29613.56, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (157, 16, 29548.01, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (158, 19, 34940.13, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (159, 18, 34241.39, 18);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (160, 20, 35833.23, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (161, 21, 30821.38, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (162, 22, 30731.05, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (163, 23, 32810.10, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (164, 24, 38020.09, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (165, 17, 39134.63, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (166, 25, 29485.37, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (167, 26, 47036.30, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (168, 2, 35983.30, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (169, 13, 40310.37, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (170, 9, 34573.59, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (171, 10, 38892.80, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (172, 11, 20219.29, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (173, 12, 29639.82, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (174, 14, 14303.41, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (175, 15, 21172.13, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (176, 7, 29489.74, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (177, 8, 29613.56, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (178, 16, 29548.01, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (179, 19, 34940.13, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (180, 18, 34241.39, 19);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (181, 9, 32721.43, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (182, 17, 39134.63, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (183, 20, 33913.59, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (184, 2, 35983.30, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (185, 21, 29170.23, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (186, 22, 29084.74, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (187, 23, 31052.42, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (188, 24, 35983.30, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (189, 25, 27905.80, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (190, 26, 44516.50, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (191, 13, 38150.89, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (192, 10, 36809.25, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (193, 11, 19136.11, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (194, 12, 28051.97, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (195, 14, 13537.16, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (196, 15, 20037.91, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (197, 7, 27909.93, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (198, 8, 28027.12, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (199, 16, 27965.08, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (200, 19, 33068.34, 20);
INSERT INTO public.historico_sueldo_basico_detalle VALUES (201, 18, 32407.03, 20);


--
-- Name: historico_sueldo_basico_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historico_sueldo_basico_detalle_id_seq', 201, true);


--
-- Name: historico_sueldo_basico_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.historico_sueldo_basico_id_seq', 20, true);


--
-- Data for Name: liquidaciones; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.liquidaciones VALUES (112, 'Liquidacion Febrero 2019', '2019-02-01', '2019-02-01', '2019-02-28', 1, 1, 1, '2019-02-01', '02 2019', 'Luján', '2019-02-01', 1, 2, 2019, 21, '2019-01-29', 'Enero');
INSERT INTO public.liquidaciones VALUES (113, 'Liquidacion Marzo 2019', '2019-03-01', '2019-03-01', '2019-03-31', 1, 1, 1, '2019-02-01', '03 2019', 'Luján', '2019-02-01', 1, 3, 2019, 41, '2019-09-04', 'Septiembre');
INSERT INTO public.liquidaciones VALUES (114, 'Liquidacion Abril 2019', '2019-04-01', '2019-04-01', '2019-04-30', 1, 1, 1, '2019-04-30', '04 2019', 'Luján', '2019-04-30', 1, 4, 2019, 61, '2019-10-18', 'Octubre');
INSERT INTO public.liquidaciones VALUES (111, 'Liquidacion Enero 2019', '2019-01-01', '2019-01-01', '2019-01-31', 1, 1, 1, '2019-02-01', '01 2019', 'Luján', '2019-02-01', 3, 1, 2019, 1, '2019-01-29', 'Enero');


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
INSERT INTO public.liquidaciones_conceptos VALUES (2750, 1, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2751, 7, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2752, 42, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2753, 12, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2754, 4, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2755, 5, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2756, 6, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2757, 47, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2758, 46, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2759, 13, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2760, 14, 112, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2761, 16, 112, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2762, 15, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2763, 17, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2764, 18, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2765, 19, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2766, 20, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2767, 21, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2768, 22, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2769, 23, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2770, 32, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2771, 24, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2772, 25, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2773, 26, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2774, 29, 112, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2775, 27, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2776, 28, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2777, 30, 112, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2778, 31, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2779, 33, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2780, 34, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2781, 35, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2782, 36, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2783, 37, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2784, 38, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2785, 40, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2786, 8, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2787, 9, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2788, 10, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2789, 11, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2790, 39, 112, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2791, 1, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2792, 7, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2793, 42, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2794, 12, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2795, 4, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2796, 5, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2797, 6, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2798, 47, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2799, 46, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2800, 13, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2801, 14, 113, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2802, 16, 113, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2803, 15, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2804, 17, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2805, 18, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2806, 19, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2807, 20, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2808, 21, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2809, 22, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2810, 23, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2811, 32, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2812, 24, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2813, 25, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2814, 26, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2815, 29, 113, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2816, 27, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2817, 28, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2818, 30, 113, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2819, 31, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2820, 33, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2821, 34, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2822, 35, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2823, 36, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2824, 37, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2825, 38, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2826, 40, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2827, 8, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2828, 9, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2829, 10, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2830, 11, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2831, 39, 113, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2832, 1, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2833, 42, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2834, 12, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2835, 4, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2836, 5, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2837, 6, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2838, 47, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2839, 46, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2840, 13, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2841, 14, 114, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2842, 16, 114, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2843, 15, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2844, 17, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2845, 18, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2846, 19, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2847, 20, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2848, 21, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2849, 22, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2850, 23, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2851, 32, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2852, 24, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2853, 25, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2854, 26, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2855, 29, 114, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2856, 27, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2857, 28, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2858, 30, 114, 0.00);
INSERT INTO public.liquidaciones_conceptos VALUES (2859, 31, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2860, 33, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2861, 34, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2862, 35, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2863, 36, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2864, 37, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2865, 38, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2866, 40, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2867, 8, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2868, 9, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2869, 10, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2870, 11, 114, NULL);
INSERT INTO public.liquidaciones_conceptos VALUES (2871, 39, 114, NULL);


--
-- Name: liquidaciones_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 2871, true);


--
-- Name: liquidaciones_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.liquidaciones_id_seq', 114, true);


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
INSERT INTO public.periodos_detalle VALUES (22, 7, NULL, NULL, NULL, 0, 3, NULL, 4.00);
INSERT INTO public.periodos_detalle VALUES (5, 10, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (3, 24, NULL, NULL, NULL, 0, 3, NULL, 0.00);
INSERT INTO public.periodos_detalle VALUES (15, 9, NULL, NULL, NULL, 22, 3, NULL, 1.13);


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

INSERT INTO public.personas VALUES (9, 'Ivan Guillermo', 'Becaj', '1978-05-01', 1, '26583833', 1, 1, true, 31, 1, 2, 1, 1, NULL, '2013-06-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265838333', 7.00, 32721.43, 0, 8.00, 1);
INSERT INTO public.personas VALUES (17, 'Micaela Noemi', 'Frascaroli', '1982-02-27', 1, '29233345', 2, 1, true, 19, 1, 2, 1, 1, NULL, '2003-10-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27292333450', 7.00, 39134.63, 0, 8.00, 2);
INSERT INTO public.personas VALUES (20, 'Norma Elizabeth', 'Lombardo', '1960-11-25', 1, '14097779', 2, 1, true, 27, 2, 2, 1, 1, NULL, '2009-08-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27140977794', 7.00, 33913.59, 0, 8.00, 2);
INSERT INTO public.personas VALUES (2, 'Martin', 'Garay', '1989-05-11', 1, '34555008', 1, 1, false, 4611, 1, 1, 1, 1, 'martingaray_12@gmail.com', '2019-07-01', '2019-08-15', '08:00:00', '15:00:00', 1, 'San Vicente 1351', '1 ', 'D         ', '01122777025', '01122777025', 1, '23345550089', 7.00, 35983.30, 0, 8.00, 1);
INSERT INTO public.personas VALUES (21, 'Maria Soledad', 'Paccor', '1979-03-05', 1, '27033687', 2, 1, true, 35, 1, 3, 1, 1, NULL, '2014-11-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27270336871', 7.00, 29170.23, 0, 8.00, 3);
INSERT INTO public.personas VALUES (22, 'Alejandra', 'Paris', '1984-05-06', 1, '30939775', 2, 1, true, 39, 1, 3, 1, 1, NULL, '2016-07-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '23309397754', 7.00, 29084.74, 0, 8.00, 3);
INSERT INTO public.personas VALUES (23, 'Jorgelina', 'Parra', '1976-05-11', 1, '25048843', 2, 1, true, 23, 1, 3, 1, 1, NULL, '2007-07-02', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27250488438', 7.00, 31052.42, 0, 8.00, 2);
INSERT INTO public.personas VALUES (24, 'Norma', 'Poletti', '1967-11-07', 1, '18601061', 2, 1, true, 2, 2, 2, 1, 1, NULL, '1986-09-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27186010618', 7.00, 35983.30, 0, 8.00, 2);
INSERT INTO public.personas VALUES (25, 'Lautaro', 'Riccardo', '1986-05-29', 1, '32378152', 1, 1, true, 33, 1, 3, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20323781525', 7.00, 27905.80, 0, 8.00, 1);
INSERT INTO public.personas VALUES (26, 'Ana Gladys', 'Romero', '1966-05-04', 1, '18148598', 2, 1, true, 3, 3, 1, 1, 1, NULL, '1986-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27181485987', 7.00, 44516.50, 0, 8.00, 2);
INSERT INTO public.personas VALUES (13, 'Noemi Severa', 'Delgado', '1956-10-27', 1, '12904169', 2, 1, true, 7, 1, 2, 1, 1, NULL, '1986-07-14', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27129041698', 7.00, 38150.89, 0, 8.00, 2);
INSERT INTO public.personas VALUES (10, 'Silvia Marina', 'Cano', '1960-12-22', 1, '14490100', 2, 1, true, 5, 2, 2, 1, 1, NULL, '1988-12-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27144901008', 7.00, 36809.25, 0, 8.00, 2);
INSERT INTO public.personas VALUES (11, 'Teresita', 'Cespedes Ramirez', '1965-05-20', 1, '92727141', 2, 1, true, 8, 3, 5, 2, 1, NULL, '2010-03-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27927271414', 7.00, 19136.11, 0, 4.00, 2);
INSERT INTO public.personas VALUES (12, 'Gisela Elizabeth', 'Dandrilli', '1984-08-04', 1, '30939944', 2, 1, true, 34, 2, 4, 1, 1, NULL, '2014-02-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27309399442', 7.00, 28051.97, 0, 8.00, 3);
INSERT INTO public.personas VALUES (14, 'Cesar Anibal', 'Echenique', '1978-12-24', 1, '27113644', 1, 1, true, 37, 1, 3, 2, 1, NULL, '2015-06-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20271136448', 7.00, 13537.16, 0, 4.00, 1);
INSERT INTO public.personas VALUES (15, 'Maria Cecilia', 'Ferrari', '1982-07-25', 1, '29594863', 2, 1, true, 26, 1, 3, 2, 1, NULL, '2008-02-20', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27295948634', 7.00, 20037.91, 0, 4.00, 2);
INSERT INTO public.personas VALUES (7, 'Silvio', 'Zeppa', '1978-05-20', 1, '26563056', 1, 1, true, 40, 2, 4, 1, 1, NULL, '2017-04-03', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20265630562', 7.00, 27909.93, 0, 8.00, 3);
INSERT INTO public.personas VALUES (8, 'Claudio Daniel', 'Acosta', '1978-07-18', 1, '26823601', 1, 1, true, 29, 2, 4, 1, 1, NULL, '2011-04-06', NULL, '07:00:00', '16:00:00', 1, 'Mariano Moreno 1460', NULL, NULL, NULL, NULL, 1, '20268236016', 9.00, 28027.12, 0, 8.00, 2);
INSERT INTO public.personas VALUES (16, 'Rodrigo Raul', 'Ferreyra', '1989-10-10', 1, '34831908', 1, 1, true, 32, 1, 4, 1, 1, NULL, '2013-10-07', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '20348319087', 7.00, 27965.08, 0, 8.00, 1);
INSERT INTO public.personas VALUES (19, 'Claudia Fabiana', 'Herrera', '1965-04-28', 1, '16833436', 2, 1, true, 10, 2, 3, 1, 1, NULL, '1994-08-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27168334368', 7.00, 33068.34, 0, 8.00, 2);
INSERT INTO public.personas VALUES (18, 'Betiana Nazareth', 'Gallesio', '1978-01-04', 1, '26167199', 2, 1, true, 21, 1, 2, 1, 1, NULL, '2006-11-01', NULL, '08:00:00', '15:00:00', 1, NULL, NULL, NULL, NULL, NULL, 1, '27261671994', 7.00, 32407.03, 0, 8.00, 2);


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

INSERT INTO public.recibos VALUES (1817, 21, 8, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1818, 22, 9, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1819, 23, 10, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1820, 24, 11, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1821, 25, 12, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1822, 26, 13, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1823, 27, 14, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1824, 28, 15, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1825, 29, 16, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1826, 30, 17, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1827, 31, 18, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1828, 32, 19, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1829, 33, 20, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1830, 34, 21, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1831, 35, 22, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1832, 36, 23, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1833, 37, 24, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1834, 38, 25, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1835, 39, 26, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1836, 40, 7, NULL, NULL, NULL, NULL, NULL, 112, NULL);
INSERT INTO public.recibos VALUES (1839, 42, 10, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1840, 43, 11, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1841, 44, 12, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1842, 45, 13, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1843, 46, 14, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1844, 47, 15, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1845, 48, 16, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1846, 49, 17, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1847, 50, 18, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1848, 51, 19, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1849, 52, 20, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1850, 53, 21, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1851, 54, 22, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1852, 55, 23, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1853, 56, 24, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1854, 57, 25, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1855, 58, 26, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1856, 59, 7, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1837, 60, 8, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1838, 41, 9, NULL, NULL, NULL, NULL, NULL, 113, NULL);
INSERT INTO public.recibos VALUES (1857, NULL, 8, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1858, NULL, 9, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1859, NULL, 10, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1860, NULL, 11, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1861, NULL, 12, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1862, NULL, 13, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1863, NULL, 14, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1864, NULL, 15, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1865, NULL, 16, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1866, NULL, 17, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1867, NULL, 18, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1868, NULL, 19, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1869, NULL, 20, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1870, NULL, 21, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1871, NULL, 22, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1872, NULL, 23, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1873, NULL, 24, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1874, NULL, 25, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1875, NULL, 26, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1876, NULL, 7, NULL, NULL, NULL, NULL, NULL, 114, NULL);
INSERT INTO public.recibos VALUES (1810, 6, 21, 38062.27, -2500.00, 7422.14, 28140.13, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1811, 7, 22, 37997.43, -2500.00, 7409.50, 28087.93, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1812, 8, 23, 46604.68, -2500.00, 9087.91, 35016.77, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1813, 9, 24, 62610.94, -2500.00, 12356.12, 47754.82, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1814, 10, 25, 34439.68, -2500.00, 6715.74, 25223.94, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1815, 11, 26, 97033.56, -2500.00, 27152.38, 67381.18, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1816, 12, 7, 33355.18, -2500.00, 6337.46, 24517.72, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1797, 13, 8, 39741.54, -2500.00, 7749.60, 29491.94, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1798, 14, 9, 51.98, -2500.00, 10.14, -2458.16, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1799, 15, 10, 62575.73, -2500.00, 12574.86, 47500.87, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1800, 16, 11, 24920.83, -1700.00, 4859.56, 18361.27, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1801, 17, 12, 36891.92, -2500.00, 7193.93, 27198.00, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1802, 18, 13, 74634.16, -2500.00, 17607.21, 54526.95, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1803, 19, 14, 16050.83, -1125.00, 3129.91, 11795.91, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1804, 20, 15, 28481.44, -1400.00, 5553.88, 21527.56, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1805, 1, 16, 40027.91, -2500.00, 7805.44, 29722.47, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1806, 2, 17, 63020.79, -2500.00, 13373.58, 47147.21, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1807, 3, 18, 57313.70, -2500.00, 11619.58, 43194.12, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1808, 4, 19, 59879.31, -2500.00, 11931.43, 45447.88, NULL, 111, NULL);
INSERT INTO public.recibos VALUES (1809, 5, 20, 49518.70, -2500.00, 9656.15, 37362.55, NULL, 111, NULL);


--
-- Data for Name: recibos_acumuladores; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_acumuladores VALUES (8061, 1, 40027.91, 1805);
INSERT INTO public.recibos_acumuladores VALUES (8062, 2, -2500.00, 1805);
INSERT INTO public.recibos_acumuladores VALUES (8063, 3, 40027.91, 1805);
INSERT INTO public.recibos_acumuladores VALUES (8064, 4, -2500.00, 1805);
INSERT INTO public.recibos_acumuladores VALUES (8065, 5, 7805.44, 1805);
INSERT INTO public.recibos_acumuladores VALUES (8066, 1, 63020.79, 1806);
INSERT INTO public.recibos_acumuladores VALUES (8067, 2, -2500.00, 1806);
INSERT INTO public.recibos_acumuladores VALUES (8068, 3, 63020.79, 1806);
INSERT INTO public.recibos_acumuladores VALUES (8069, 4, -2500.00, 1806);
INSERT INTO public.recibos_acumuladores VALUES (8070, 5, 13373.58, 1806);
INSERT INTO public.recibos_acumuladores VALUES (8071, 1, 57313.70, 1807);
INSERT INTO public.recibos_acumuladores VALUES (8072, 2, -2500.00, 1807);
INSERT INTO public.recibos_acumuladores VALUES (8073, 3, 57313.70, 1807);
INSERT INTO public.recibos_acumuladores VALUES (8074, 4, -2500.00, 1807);
INSERT INTO public.recibos_acumuladores VALUES (8075, 5, 11619.58, 1807);
INSERT INTO public.recibos_acumuladores VALUES (8076, 1, 59879.31, 1808);
INSERT INTO public.recibos_acumuladores VALUES (8077, 2, -2500.00, 1808);
INSERT INTO public.recibos_acumuladores VALUES (8078, 3, 59879.31, 1808);
INSERT INTO public.recibos_acumuladores VALUES (8079, 4, -2500.00, 1808);
INSERT INTO public.recibos_acumuladores VALUES (8080, 5, 11931.43, 1808);
INSERT INTO public.recibos_acumuladores VALUES (8081, 1, 49518.70, 1809);
INSERT INTO public.recibos_acumuladores VALUES (8082, 2, -2500.00, 1809);
INSERT INTO public.recibos_acumuladores VALUES (8083, 3, 49518.70, 1809);
INSERT INTO public.recibos_acumuladores VALUES (8084, 4, -2500.00, 1809);
INSERT INTO public.recibos_acumuladores VALUES (8085, 5, 9656.15, 1809);
INSERT INTO public.recibos_acumuladores VALUES (8086, 1, 38062.27, 1810);
INSERT INTO public.recibos_acumuladores VALUES (8087, 2, -2500.00, 1810);
INSERT INTO public.recibos_acumuladores VALUES (8088, 3, 38062.27, 1810);
INSERT INTO public.recibos_acumuladores VALUES (8089, 4, -2500.00, 1810);
INSERT INTO public.recibos_acumuladores VALUES (8090, 5, 7422.14, 1810);
INSERT INTO public.recibos_acumuladores VALUES (8091, 1, 37997.43, 1811);
INSERT INTO public.recibos_acumuladores VALUES (8092, 2, -2500.00, 1811);
INSERT INTO public.recibos_acumuladores VALUES (8093, 3, 37997.43, 1811);
INSERT INTO public.recibos_acumuladores VALUES (8094, 4, -2500.00, 1811);
INSERT INTO public.recibos_acumuladores VALUES (8095, 5, 7409.50, 1811);
INSERT INTO public.recibos_acumuladores VALUES (8096, 1, 46604.68, 1812);
INSERT INTO public.recibos_acumuladores VALUES (8097, 2, -2500.00, 1812);
INSERT INTO public.recibos_acumuladores VALUES (8098, 3, 46604.68, 1812);
INSERT INTO public.recibos_acumuladores VALUES (8099, 4, -2500.00, 1812);
INSERT INTO public.recibos_acumuladores VALUES (8100, 5, 9087.91, 1812);
INSERT INTO public.recibos_acumuladores VALUES (8101, 1, 62610.94, 1813);
INSERT INTO public.recibos_acumuladores VALUES (8102, 2, -2500.00, 1813);
INSERT INTO public.recibos_acumuladores VALUES (8103, 3, 62610.94, 1813);
INSERT INTO public.recibos_acumuladores VALUES (8104, 4, -2500.00, 1813);
INSERT INTO public.recibos_acumuladores VALUES (8105, 5, 12356.12, 1813);
INSERT INTO public.recibos_acumuladores VALUES (8106, 1, 34439.68, 1814);
INSERT INTO public.recibos_acumuladores VALUES (8107, 2, -2500.00, 1814);
INSERT INTO public.recibos_acumuladores VALUES (8108, 3, 34439.68, 1814);
INSERT INTO public.recibos_acumuladores VALUES (8109, 4, -2500.00, 1814);
INSERT INTO public.recibos_acumuladores VALUES (8110, 5, 6715.74, 1814);
INSERT INTO public.recibos_acumuladores VALUES (8111, 1, 97033.56, 1815);
INSERT INTO public.recibos_acumuladores VALUES (8112, 2, -2500.00, 1815);
INSERT INTO public.recibos_acumuladores VALUES (8113, 3, 97033.56, 1815);
INSERT INTO public.recibos_acumuladores VALUES (8114, 4, -2500.00, 1815);
INSERT INTO public.recibos_acumuladores VALUES (8115, 5, 27152.38, 1815);
INSERT INTO public.recibos_acumuladores VALUES (8116, 1, 33355.18, 1816);
INSERT INTO public.recibos_acumuladores VALUES (8117, 2, -2500.00, 1816);
INSERT INTO public.recibos_acumuladores VALUES (8118, 3, 33355.18, 1816);
INSERT INTO public.recibos_acumuladores VALUES (8119, 4, -2500.00, 1816);
INSERT INTO public.recibos_acumuladores VALUES (8120, 5, 6337.46, 1816);
INSERT INTO public.recibos_acumuladores VALUES (8121, 1, 39741.54, 1797);
INSERT INTO public.recibos_acumuladores VALUES (8122, 2, -2500.00, 1797);
INSERT INTO public.recibos_acumuladores VALUES (8123, 3, 39741.54, 1797);
INSERT INTO public.recibos_acumuladores VALUES (8124, 4, -2500.00, 1797);
INSERT INTO public.recibos_acumuladores VALUES (8125, 5, 7749.60, 1797);
INSERT INTO public.recibos_acumuladores VALUES (8126, 1, 51.98, 1798);
INSERT INTO public.recibos_acumuladores VALUES (8127, 2, -2500.00, 1798);
INSERT INTO public.recibos_acumuladores VALUES (8128, 3, 51.98, 1798);
INSERT INTO public.recibos_acumuladores VALUES (8129, 4, -2500.00, 1798);
INSERT INTO public.recibos_acumuladores VALUES (8130, 5, 10.14, 1798);
INSERT INTO public.recibos_acumuladores VALUES (8131, 1, 62575.73, 1799);
INSERT INTO public.recibos_acumuladores VALUES (8132, 2, -2500.00, 1799);
INSERT INTO public.recibos_acumuladores VALUES (8133, 3, 62575.73, 1799);
INSERT INTO public.recibos_acumuladores VALUES (8134, 4, -2500.00, 1799);
INSERT INTO public.recibos_acumuladores VALUES (8135, 5, 12574.86, 1799);
INSERT INTO public.recibos_acumuladores VALUES (8136, 1, 24920.83, 1800);
INSERT INTO public.recibos_acumuladores VALUES (8137, 2, -1700.00, 1800);
INSERT INTO public.recibos_acumuladores VALUES (8138, 3, 24920.83, 1800);
INSERT INTO public.recibos_acumuladores VALUES (8139, 4, -1700.00, 1800);
INSERT INTO public.recibos_acumuladores VALUES (8140, 5, 4859.56, 1800);
INSERT INTO public.recibos_acumuladores VALUES (8141, 1, 36891.92, 1801);
INSERT INTO public.recibos_acumuladores VALUES (8142, 2, -2500.00, 1801);
INSERT INTO public.recibos_acumuladores VALUES (8143, 3, 36891.92, 1801);
INSERT INTO public.recibos_acumuladores VALUES (8144, 4, -2500.00, 1801);
INSERT INTO public.recibos_acumuladores VALUES (8145, 5, 7193.93, 1801);
INSERT INTO public.recibos_acumuladores VALUES (8146, 1, 74634.16, 1802);
INSERT INTO public.recibos_acumuladores VALUES (8147, 2, -2500.00, 1802);
INSERT INTO public.recibos_acumuladores VALUES (8148, 3, 74634.16, 1802);
INSERT INTO public.recibos_acumuladores VALUES (8149, 4, -2500.00, 1802);
INSERT INTO public.recibos_acumuladores VALUES (8150, 5, 17607.21, 1802);
INSERT INTO public.recibos_acumuladores VALUES (8151, 1, 16050.83, 1803);
INSERT INTO public.recibos_acumuladores VALUES (8152, 2, -1125.00, 1803);
INSERT INTO public.recibos_acumuladores VALUES (8153, 3, 16050.83, 1803);
INSERT INTO public.recibos_acumuladores VALUES (8154, 4, -1125.00, 1803);
INSERT INTO public.recibos_acumuladores VALUES (8155, 5, 3129.91, 1803);
INSERT INTO public.recibos_acumuladores VALUES (8156, 1, 28481.44, 1804);
INSERT INTO public.recibos_acumuladores VALUES (8157, 2, -1400.00, 1804);
INSERT INTO public.recibos_acumuladores VALUES (8158, 3, 28481.44, 1804);
INSERT INTO public.recibos_acumuladores VALUES (8159, 4, -1400.00, 1804);
INSERT INTO public.recibos_acumuladores VALUES (8160, 5, 5553.88, 1804);


--
-- Name: recibos_acumuladores_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 8160, true);


--
-- Data for Name: recibos_conceptos; Type: TABLE DATA; Schema: public; Owner: -
--

INSERT INTO public.recibos_conceptos VALUES (54529, 4, 38150.89, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (56774, 42, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56775, 12, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56776, 4, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56777, 5, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56778, 6, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56779, 47, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56780, 46, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56003, 14, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56781, 13, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56784, 15, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56004, 16, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56785, 17, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56786, 18, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56062, 31, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56063, 33, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56064, 34, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56065, 35, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56066, 36, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56017, 29, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56067, 37, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56068, 38, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56069, 40, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56020, 30, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56070, 8, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56071, 9, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56072, 10, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56073, 11, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56074, 39, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56075, 1, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56076, 7, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56077, 42, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56078, 12, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56079, 4, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56080, 5, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56081, 6, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56082, 47, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56083, 46, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56084, 13, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56087, 15, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56088, 17, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56089, 18, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56090, 19, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56091, 20, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56092, 21, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56093, 22, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56094, 23, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56044, 14, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56045, 16, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56058, 29, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56061, 30, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56085, 14, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56086, 16, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56099, 29, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56102, 30, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56126, 14, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56127, 16, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56140, 29, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56143, 30, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56167, 14, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56168, 16, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56181, 29, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56184, 30, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56208, 14, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56209, 16, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56095, 32, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56096, 24, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56097, 25, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56098, 26, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56100, 27, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56101, 28, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56103, 31, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56104, 33, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56105, 34, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56106, 35, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56107, 36, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56108, 37, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56109, 38, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56110, 40, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56111, 8, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56112, 9, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56113, 10, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56114, 11, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56115, 39, NULL, 1839, NULL);
INSERT INTO public.recibos_conceptos VALUES (56116, 1, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56117, 7, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56118, 42, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56119, 12, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56120, 4, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56121, 5, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56122, 6, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56123, 47, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56124, 46, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56125, 13, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56128, 15, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56129, 17, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56130, 18, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56131, 19, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56132, 20, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56133, 21, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56134, 22, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56135, 23, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56136, 32, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56137, 24, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56138, 25, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56139, 26, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56141, 27, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56142, 28, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56144, 31, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56145, 33, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56146, 34, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56147, 35, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56148, 36, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56149, 37, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56150, 38, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56151, 40, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56152, 8, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56153, 9, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56154, 10, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56155, 11, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56156, 39, NULL, 1840, NULL);
INSERT INTO public.recibos_conceptos VALUES (56157, 1, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56158, 7, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56159, 42, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56160, 12, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56161, 4, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56162, 5, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56163, 6, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56164, 47, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56165, 46, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56166, 13, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56169, 15, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56170, 17, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56171, 18, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56172, 19, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56173, 20, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56174, 21, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56175, 22, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56176, 23, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56177, 32, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56178, 24, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56179, 25, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56180, 26, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56182, 27, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56183, 28, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56185, 31, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56186, 33, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56187, 34, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56188, 35, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56189, 36, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56190, 37, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56191, 38, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56192, 40, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56193, 8, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56194, 9, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56195, 10, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56196, 11, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56197, 39, NULL, 1841, NULL);
INSERT INTO public.recibos_conceptos VALUES (56198, 1, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56199, 7, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56200, 42, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56201, 12, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56202, 4, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56203, 5, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56204, 6, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56205, 47, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56206, 46, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56207, 13, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56210, 15, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56211, 17, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56212, 18, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56213, 19, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56214, 20, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56215, 21, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56216, 22, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56217, 23, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56218, 32, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56219, 24, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56220, 25, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56221, 26, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56223, 27, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56224, 28, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56226, 31, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56227, 33, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56228, 34, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56229, 35, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56230, 36, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56231, 37, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56232, 38, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56233, 40, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56234, 8, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56235, 9, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56236, 10, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56237, 11, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56238, 39, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56239, 1, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56222, 29, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56225, 30, NULL, 1842, NULL);
INSERT INTO public.recibos_conceptos VALUES (56249, 14, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56250, 16, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56263, 29, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56266, 30, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56290, 14, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56291, 16, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56304, 29, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56307, 30, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56331, 14, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56332, 16, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56345, 29, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56348, 30, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56372, 14, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56373, 16, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56240, 7, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56241, 42, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56242, 12, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56243, 4, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56245, 6, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56246, 47, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56247, 46, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56248, 13, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56251, 15, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56252, 17, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56253, 18, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56254, 19, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56255, 20, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56256, 21, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56257, 22, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56258, 23, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56259, 32, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56260, 24, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56261, 25, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56262, 26, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56264, 27, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56265, 28, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56267, 31, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56268, 33, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56269, 34, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56270, 35, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56271, 36, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56272, 37, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56273, 38, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56274, 40, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56275, 8, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56276, 9, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56277, 10, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56278, 11, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56279, 39, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (56280, 1, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56281, 7, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56282, 42, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56283, 12, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56284, 4, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56285, 5, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56286, 6, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56287, 47, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56288, 46, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56289, 13, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56292, 15, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56293, 17, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56294, 18, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56295, 19, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56296, 20, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56297, 21, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56298, 22, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56299, 23, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56300, 32, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56301, 24, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56302, 25, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56303, 26, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56305, 27, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56306, 28, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56308, 31, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56309, 33, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56310, 34, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56311, 35, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56312, 36, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56313, 37, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56314, 38, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56315, 40, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56316, 8, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56317, 9, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56318, 10, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56319, 11, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56320, 39, NULL, 1844, NULL);
INSERT INTO public.recibos_conceptos VALUES (56321, 1, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56322, 7, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56323, 42, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56324, 12, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56325, 4, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56326, 5, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56327, 6, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56328, 47, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56329, 46, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56330, 13, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56333, 15, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56334, 17, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56335, 18, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56336, 19, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56337, 20, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56338, 21, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56339, 22, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56340, 23, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56341, 32, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56342, 24, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56343, 25, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56344, 26, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56346, 27, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56347, 28, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56349, 31, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56350, 33, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56351, 34, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56352, 35, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56353, 36, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56354, 37, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56355, 38, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56356, 40, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56357, 8, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56358, 9, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56359, 10, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56360, 11, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56361, 39, NULL, 1845, NULL);
INSERT INTO public.recibos_conceptos VALUES (56362, 1, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56363, 7, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56364, 42, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56365, 12, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56366, 4, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56367, 5, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56368, 6, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56369, 47, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56370, 46, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56371, 13, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56374, 15, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56375, 17, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56376, 18, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56377, 19, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56378, 20, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56379, 21, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56380, 22, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56381, 23, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56382, 32, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56383, 24, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56384, 25, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56385, 26, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56387, 27, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56388, 28, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56390, 31, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56391, 33, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (57642, 8, 6887.20, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (57643, 8, 3788.36, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (57644, 8, 10673.69, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (57645, 8, 3669.07, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (54568, 7, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (56386, 29, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56389, 30, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56413, 14, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56414, 16, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56427, 29, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56430, 30, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56454, 14, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56455, 16, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56468, 29, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56471, 30, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56495, 14, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56496, 16, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56509, 29, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56512, 30, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56536, 14, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56537, 16, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56392, 34, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56393, 35, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56394, 36, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56395, 37, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56396, 38, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56397, 40, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56398, 8, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56399, 9, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56400, 10, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56401, 11, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56402, 39, NULL, 1846, NULL);
INSERT INTO public.recibos_conceptos VALUES (56403, 1, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56404, 7, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56405, 42, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56406, 12, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56407, 4, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56408, 5, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56409, 6, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56410, 47, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56411, 46, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56412, 13, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56415, 15, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56416, 17, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56417, 18, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56418, 19, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56419, 20, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56420, 21, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56421, 22, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56422, 23, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56423, 32, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56424, 24, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56425, 25, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56426, 26, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56428, 27, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56429, 28, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56431, 31, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56432, 33, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56433, 34, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56434, 35, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56435, 36, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56436, 37, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56437, 38, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56438, 40, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56439, 8, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56440, 9, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56441, 10, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56442, 11, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56443, 39, NULL, 1847, NULL);
INSERT INTO public.recibos_conceptos VALUES (56444, 1, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56445, 7, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56446, 42, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56447, 12, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56448, 4, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56449, 5, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56450, 6, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56451, 47, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56452, 46, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56453, 13, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56456, 15, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56457, 17, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56458, 18, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56459, 19, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56460, 20, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56461, 21, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56462, 22, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56463, 23, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56464, 32, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56465, 24, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56466, 25, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56467, 26, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56469, 27, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56470, 28, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56472, 31, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56473, 33, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56474, 34, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56475, 35, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56476, 36, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56477, 37, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56478, 38, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56479, 40, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56480, 8, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56481, 9, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56482, 10, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56483, 11, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56484, 39, NULL, 1848, NULL);
INSERT INTO public.recibos_conceptos VALUES (56485, 1, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56486, 7, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56487, 42, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56488, 12, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56489, 4, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56490, 5, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56491, 6, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56492, 47, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56493, 46, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56494, 13, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56497, 15, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56498, 17, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56499, 18, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56500, 19, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56501, 20, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56502, 21, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56503, 22, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56504, 23, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56505, 32, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56506, 24, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56507, 25, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56508, 26, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56510, 27, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56511, 28, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56513, 31, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56514, 33, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56515, 34, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56516, 35, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56517, 36, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56518, 37, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56519, 38, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56520, 40, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56521, 8, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56522, 9, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56523, 10, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56524, 11, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56525, 39, NULL, 1849, NULL);
INSERT INTO public.recibos_conceptos VALUES (56526, 1, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56527, 7, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56528, 42, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56529, 12, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56530, 4, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56531, 5, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56532, 6, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56533, 47, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56534, 46, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56535, 13, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56538, 15, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56539, 17, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56540, 18, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (55151, 11, 667.08, 1816, 667.08);
INSERT INTO public.recibos_conceptos VALUES (54530, 5, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54531, 6, 24416.57, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54532, 47, 74634.16, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54533, 46, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54534, 13, 6219.51, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54535, 14, 0.00, 1802, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54536, 16, 0.00, 1802, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54537, 15, 80853.67, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54538, 17, 8893.90, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54539, 18, 2425.61, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54540, 19, 2425.61, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54541, 20, 2021.34, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54542, 21, 15766.47, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54543, 22, 65087.21, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (56550, 29, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56553, 30, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56577, 14, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56578, 16, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56591, 29, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56594, 30, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56618, 14, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56619, 16, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56632, 29, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56635, 30, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56659, 14, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56660, 16, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56673, 29, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56676, 30, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56541, 19, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56542, 20, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56543, 21, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56544, 22, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56545, 23, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56546, 32, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56547, 24, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56548, 25, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56549, 26, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56551, 27, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56552, 28, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56554, 31, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56555, 33, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56556, 34, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56557, 35, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56558, 36, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56559, 37, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56560, 38, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56561, 40, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56562, 8, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56563, 9, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56564, 10, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56565, 11, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56566, 39, NULL, 1850, NULL);
INSERT INTO public.recibos_conceptos VALUES (56567, 1, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56568, 7, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56569, 42, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56570, 12, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56571, 4, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56572, 5, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56573, 6, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56574, 47, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56575, 46, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56576, 13, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56579, 15, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56580, 17, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56581, 18, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56582, 19, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56583, 20, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56584, 21, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56585, 22, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56586, 23, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56587, 32, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56588, 24, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56589, 25, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56590, 26, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56592, 27, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56593, 28, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56595, 31, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56596, 33, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56597, 34, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56598, 35, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56599, 36, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56600, 37, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56601, 38, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56602, 40, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56603, 8, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56604, 9, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56605, 10, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56606, 11, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56607, 39, NULL, 1851, NULL);
INSERT INTO public.recibos_conceptos VALUES (56608, 1, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56609, 7, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56610, 42, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56647, 11, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56648, 39, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56649, 1, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56650, 7, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56742, 16, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56651, 42, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56652, 12, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56653, 4, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56654, 5, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56655, 6, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56656, 47, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56657, 46, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56658, 13, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56661, 15, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56662, 17, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56663, 18, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56664, 19, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56665, 20, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56666, 21, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56667, 22, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56668, 23, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56669, 32, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56670, 24, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56671, 25, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56672, 26, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56674, 27, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56675, 28, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56677, 31, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56678, 33, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56679, 34, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56680, 35, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56681, 36, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56682, 37, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56683, 38, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56684, 40, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56685, 8, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56686, 9, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56687, 10, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56688, 11, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56689, 39, NULL, 1853, NULL);
INSERT INTO public.recibos_conceptos VALUES (56690, 1, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56691, 7, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56692, 42, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (54544, 23, 65087.21, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54545, 32, 3254.36, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54546, 24, 34339.60, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54547, 25, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54548, 26, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54549, 29, 0.00, 1802, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54550, 27, 7154.08, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54551, 28, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54552, 30, 0.00, 1802, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54553, 31, 3254.36, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54554, 33, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54555, 34, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54556, 35, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54557, 36, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (57626, 8, 4371.57, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (57627, 8, 5.72, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (57628, 8, 6883.33, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (57629, 8, 2741.29, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (57630, 8, 4058.11, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (57631, 8, 8209.76, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (57632, 8, 1765.59, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (57633, 8, 3132.96, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (57634, 8, 4403.07, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (57635, 8, 6932.29, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (57636, 8, 6304.51, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (57637, 8, 6586.72, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (57638, 8, 5447.06, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (57639, 8, 4186.85, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (57640, 8, 4179.72, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (56693, 12, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (57641, 8, 5126.52, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54497, 18, 1198.99, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54498, 19, 1198.99, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54569, 42, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54570, 12, 1353.72, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54571, 4, 13537.16, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54558, 37, 44748.04, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54572, 5, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54573, 6, 812.23, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54575, 46, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54576, 13, 1337.57, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54577, 14, 0.00, 1803, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54578, 16, 0.00, 1803, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54579, 15, 17388.39, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54580, 17, 1912.72, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54582, 19, 521.65, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54581, 18, 521.65, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54583, 20, 434.71, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54584, 21, 3390.74, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54585, 22, 13997.66, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54586, 23, 13997.66, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54587, 32, 699.88, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54588, 24, 34339.60, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54589, 25, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54590, 26, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54591, 29, 0.00, 1803, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54592, 27, 7154.08, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54593, 28, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54594, 30, 0.00, 1803, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54595, 31, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54596, 33, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54597, 34, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54598, 35, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54599, 36, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54600, 37, 41493.68, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54601, 38, -27496.02, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54602, 40, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54603, 9, 481.52, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54604, 10, 481.52, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54605, 11, 401.27, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54606, 39, 0.00, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (54609, 1, 20037.91, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54636, 30, 0.00, 1804, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54610, 7, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54611, 42, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54612, 12, 2003.79, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54613, 4, 20037.91, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54614, 5, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54615, 6, 4007.58, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54616, 47, 28481.44, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54617, 46, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54618, 13, 2373.45, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54619, 14, 0.00, 1804, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54620, 16, 0.00, 1804, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54621, 15, 30854.90, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54622, 17, 3394.04, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54623, 18, 925.65, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54624, 19, 925.65, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54625, 20, 771.37, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54626, 21, 6016.70, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (56700, 14, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56694, 4, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (54627, 22, 24838.19, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54628, 23, 24838.19, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54629, 32, 1241.91, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54630, 24, 34339.60, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54500, 21, 7793.42, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54631, 25, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54632, 26, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54633, 29, 0.00, 1804, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54634, 27, 7154.08, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54635, 28, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54637, 31, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54638, 33, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54639, 34, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54640, 35, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54641, 36, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54642, 37, 41493.68, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54643, 38, -16655.49, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54644, 40, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54645, 9, 854.44, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54646, 10, 854.44, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54647, 11, 712.04, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54648, 39, 0.00, 1804, NULL);
INSERT INTO public.recibos_conceptos VALUES (54651, 1, 27965.08, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54652, 7, 5416.84, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54653, 42, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54654, 12, 2796.51, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54655, 4, 27965.08, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54656, 5, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54657, 6, 2796.51, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54658, 47, 40027.91, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54659, 46, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54660, 13, 3335.66, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54661, 14, 0.00, 1805, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54662, 16, 0.00, 1805, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54663, 15, 43363.57, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54664, 17, 4769.99, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54665, 18, 1300.91, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54666, 19, 1300.91, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54686, 40, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54687, 9, 1200.84, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54688, 10, 1200.84, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54689, 11, 1000.70, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54690, 39, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54693, 1, 39134.63, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54694, 7, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54695, 42, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54667, 20, 1084.09, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54668, 21, 8455.90, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54669, 22, 34907.67, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54670, 23, 34907.67, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54671, 32, 1745.38, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54672, 24, 34339.60, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54673, 25, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54674, 26, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54675, 29, 0.00, 1805, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54676, 27, 7154.08, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54677, 28, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54678, 30, 0.00, 1805, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54679, 31, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54680, 33, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54681, 34, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54682, 35, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54683, 36, 0.00, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54684, 37, 41493.68, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54650, 49, -1400.00, 1804, -1400.00);
INSERT INTO public.recibos_conceptos VALUES (54696, 12, 3913.46, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54697, 4, 39134.63, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54698, 5, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54699, 6, 11740.39, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54700, 47, 63020.79, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54701, 46, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54702, 13, 5251.73, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54703, 14, 0.00, 1806, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54704, 16, 0.00, 1806, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54705, 15, 68272.52, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54706, 17, 7509.98, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54707, 18, 2048.18, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54708, 19, 2048.18, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54709, 20, 1706.81, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54710, 21, 13313.14, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54711, 22, 54959.38, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54712, 23, 54959.38, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54713, 32, 2747.97, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54714, 24, 34339.60, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54715, 25, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54716, 26, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54717, 29, 0.00, 1806, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54718, 27, 7154.08, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (56695, 5, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56696, 6, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56697, 47, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56016, 26, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56018, 27, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56698, 46, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56699, 13, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56702, 15, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56703, 17, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56704, 18, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56705, 19, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56706, 20, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56707, 21, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56708, 22, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56709, 23, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56710, 32, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56711, 24, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56712, 25, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56701, 16, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56713, 26, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (54719, 28, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54720, 30, 0.00, 1806, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54721, 31, 2747.97, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54722, 33, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54723, 34, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54724, 35, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54725, 36, 0.00, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54726, 37, 44241.65, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54727, 38, 10717.73, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54728, 40, 1084.53, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54729, 9, 1890.62, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54730, 10, 1890.62, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54731, 11, 1575.52, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54732, 39, 1084.53, 1806, NULL);
INSERT INTO public.recibos_conceptos VALUES (54735, 1, 32407.03, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54736, 7, 7453.62, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54737, 42, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54738, 12, 3240.70, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54739, 4, 32407.03, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54740, 5, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54741, 6, 7777.69, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54742, 47, 57313.70, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54743, 46, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54744, 13, 4776.14, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54745, 14, 0.00, 1807, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54746, 16, 0.00, 1807, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54747, 15, 62089.84, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54748, 17, 6829.88, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54749, 18, 1862.70, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54750, 19, 1862.70, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54751, 20, 1552.25, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54752, 21, 12107.52, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54753, 22, 49982.32, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54754, 23, 49982.32, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54755, 32, 2499.12, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54756, 24, 34339.60, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54757, 25, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54758, 26, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54759, 29, 0.00, 1807, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54760, 27, 7154.08, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54761, 28, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54762, 30, 0.00, 1807, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54763, 31, 2499.12, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54764, 33, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54765, 34, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54766, 35, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54767, 36, 0.00, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54768, 37, 43992.80, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54769, 38, 5989.52, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54770, 40, 443.41, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54771, 9, 1719.41, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54772, 10, 1719.41, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54773, 11, 1432.84, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54774, 39, 443.41, 1807, NULL);
INSERT INTO public.recibos_conceptos VALUES (54777, 1, 33068.34, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54778, 7, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54779, 42, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54780, 12, 3306.83, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54781, 4, 33068.34, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54782, 5, 3.00, 1808, 3.00);
INSERT INTO public.recibos_conceptos VALUES (54783, 6, 17856.90, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54784, 47, 59879.31, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54785, 46, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54786, 13, 4989.94, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54787, 14, 0.00, 1808, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54788, 16, 0.00, 1808, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54789, 15, 64869.25, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54790, 17, 7135.62, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54791, 18, 1946.08, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54685, 38, -6586.01, 1805, NULL);
INSERT INTO public.recibos_conceptos VALUES (54792, 19, 1946.08, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54793, 20, 1621.73, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54794, 21, 12649.50, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54795, 22, 52219.75, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54796, 23, 52219.75, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54797, 32, 2610.99, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54798, 24, 34339.60, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54799, 25, 6669.50, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54800, 26, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54801, 29, 0.00, 1808, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54802, 27, 7154.08, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54803, 28, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54804, 30, 0.00, 1808, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54805, 31, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54806, 33, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54807, 34, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54808, 35, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54809, 36, 0.00, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54810, 37, 48163.18, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54811, 38, 4056.57, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54812, 40, 254.96, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54813, 9, 1796.38, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54814, 10, 1796.38, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54815, 11, 1496.98, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54816, 39, 254.96, 1808, NULL);
INSERT INTO public.recibos_conceptos VALUES (54819, 1, 33913.59, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54820, 7, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54821, 42, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54822, 12, 3391.36, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54823, 4, 33913.59, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54824, 5, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54825, 6, 6104.45, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54826, 47, 49518.70, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54870, 13, 3171.86, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54871, 14, 0.00, 1810, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54872, 16, 0.00, 1810, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54873, 15, 41234.13, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54874, 17, 4535.75, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54875, 18, 1237.02, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54876, 19, 1237.02, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54827, 46, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54828, 13, 4126.56, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54829, 14, 0.00, 1809, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54830, 16, 0.00, 1809, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54831, 15, 53645.25, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54832, 17, 5900.98, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54833, 18, 1609.36, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54834, 19, 1609.36, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54835, 20, 1341.13, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54836, 21, 10460.82, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54837, 22, 43184.43, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54838, 23, 43184.43, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54839, 32, 2159.22, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54840, 24, 34339.60, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54841, 25, 6669.50, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54842, 26, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54843, 29, 0.00, 1809, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54844, 27, 7154.08, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54845, 28, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54846, 30, 0.00, 1809, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54847, 31, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54848, 33, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54849, 34, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54850, 35, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54851, 36, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54852, 37, 48163.18, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54853, 38, -4978.75, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54854, 40, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54855, 9, 1485.56, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54856, 10, 1485.56, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54857, 11, 1237.97, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54858, 39, 0.00, 1809, NULL);
INSERT INTO public.recibos_conceptos VALUES (54861, 1, 29170.23, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54862, 7, 1283.49, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54863, 42, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54864, 12, 2917.02, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54865, 4, 29170.23, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54866, 5, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54867, 6, 2333.62, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54868, 47, 38062.27, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54869, 46, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54877, 20, 1030.85, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54878, 21, 8040.65, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54879, 22, 33193.47, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54880, 23, 33193.47, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54881, 32, 1659.67, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54882, 24, 34339.60, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54883, 25, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54884, 26, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54885, 29, 0.00, 1810, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54886, 27, 7154.08, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54887, 28, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54888, 30, 0.00, 1810, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54889, 31, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54890, 33, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54891, 34, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54892, 35, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54893, 36, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54894, 37, 41493.68, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54895, 38, -8300.21, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54896, 40, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54897, 9, 1141.87, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54898, 10, 1141.87, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54899, 11, 951.56, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54900, 39, 0.00, 1810, NULL);
INSERT INTO public.recibos_conceptos VALUES (54903, 1, 29084.74, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54904, 7, 3801.38, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54905, 42, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54906, 12, 2908.47, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54907, 4, 29084.74, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54908, 5, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54909, 6, 1163.39, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54910, 47, 37997.43, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54911, 46, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54912, 13, 3166.45, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54913, 14, 0.00, 1811, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54914, 16, 0.00, 1811, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54915, 15, 41163.88, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54916, 17, 4528.03, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54917, 18, 1234.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54918, 19, 1234.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54919, 20, 1029.10, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54920, 21, 8026.96, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54921, 22, 33136.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54922, 23, 33136.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54923, 32, 1656.85, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54924, 24, 34339.60, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54925, 25, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54926, 26, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54927, 29, 0.00, 1811, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54928, 27, 7154.08, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54929, 28, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54930, 30, 0.00, 1811, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54931, 31, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54932, 33, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54933, 34, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54934, 35, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54935, 36, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54936, 37, 41493.68, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54937, 38, -8356.76, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54938, 40, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54939, 9, 1139.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54940, 10, 1139.92, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54941, 11, 949.94, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54942, 39, 0.00, 1811, NULL);
INSERT INTO public.recibos_conceptos VALUES (54945, 1, 31052.42, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54946, 7, 1592.99, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54947, 42, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54948, 12, 3105.24, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54949, 4, 31052.42, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54950, 5, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54951, 6, 6831.53, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54952, 47, 46604.68, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54953, 46, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54954, 13, 3883.72, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54955, 14, 0.00, 1812, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54956, 16, 0.00, 1812, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54957, 15, 50488.41, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54958, 17, 5553.72, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54959, 18, 1514.65, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54960, 19, 1514.65, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54961, 20, 1262.21, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54962, 21, 9845.24, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54963, 22, 40643.17, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54964, 23, 40643.17, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54965, 32, 2032.16, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54966, 24, 34339.60, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54967, 25, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54968, 26, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54969, 29, 0.00, 1812, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54970, 27, 7154.08, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54971, 28, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54972, 30, 0.00, 1812, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54973, 31, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54974, 33, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54975, 34, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54976, 35, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54977, 36, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54978, 37, 41493.68, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54979, 38, -850.51, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54980, 40, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54981, 9, 1398.14, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54982, 10, 1398.14, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54983, 11, 1165.12, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54984, 39, 0.00, 1812, NULL);
INSERT INTO public.recibos_conceptos VALUES (54987, 1, 35983.30, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54988, 7, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54989, 42, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54990, 12, 3598.33, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54323, 46, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54324, 13, 3311.80, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54325, 14, 0.00, 1797, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54326, 16, 0.00, 1797, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54327, 15, 43053.34, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54328, 17, 4735.87, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54329, 18, 1291.60, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54330, 19, 1291.60, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54331, 20, 1076.33, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54332, 21, 8395.40, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54333, 22, 34657.94, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54334, 23, 34657.94, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54335, 32, 1732.90, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54336, 24, 34339.60, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54337, 25, 6669.50, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54338, 26, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54339, 29, 0.00, 1797, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54340, 27, 7154.08, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54341, 28, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54342, 30, 0.00, 1797, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54343, 31, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54344, 33, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54345, 34, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (55055, 28, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55056, 30, 0.00, 1814, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55057, 31, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55058, 33, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55059, 34, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (54991, 4, 35983.30, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54992, 5, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54993, 6, 23029.31, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54994, 47, 62610.94, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54995, 46, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54996, 13, 5217.58, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54997, 14, 0.00, 1813, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54998, 16, 0.00, 1813, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54999, 15, 67828.52, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55000, 17, 7461.14, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55001, 18, 2034.86, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55002, 19, 2034.86, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55003, 20, 1695.71, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55004, 21, 13226.56, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55005, 22, 54601.96, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55006, 23, 54601.96, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55007, 32, 2730.10, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55008, 24, 34339.60, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55009, 25, 6669.50, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55010, 26, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55011, 29, 0.00, 1813, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55012, 27, 7154.08, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55013, 28, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55014, 30, 0.00, 1813, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55016, 33, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55017, 34, 851.84, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55018, 35, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55019, 36, 0.00, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55020, 37, 51745.12, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55021, 38, 2856.84, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55022, 40, 146.99, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55023, 9, 1878.33, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55024, 10, 1878.33, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55025, 11, 1565.27, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55026, 39, 146.99, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (55027, 48, 0.00, 1813, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55029, 1, 27905.80, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55030, 7, 672.53, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55031, 42, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55032, 12, 2790.58, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55033, 4, 27905.80, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55034, 5, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55035, 6, 2790.58, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55036, 47, 34439.68, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55037, 46, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55038, 13, 2869.97, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55039, 14, 0.00, 1814, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55040, 16, 0.00, 1814, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55041, 15, 37309.65, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55042, 17, 4104.06, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55043, 18, 1119.29, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55044, 19, 1119.29, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55045, 20, 932.74, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55046, 21, 7275.38, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55047, 22, 30034.27, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55048, 23, 30034.27, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55049, 32, 1501.71, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55050, 24, 34339.60, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55051, 25, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55052, 26, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55054, 27, 7154.08, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55060, 35, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55061, 36, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55063, 38, -11459.41, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55064, 40, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55065, 9, 1033.19, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55066, 10, 1033.19, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55067, 11, 860.99, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55068, 39, 0.00, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (55071, 1, 44516.50, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55072, 7, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55073, 42, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55074, 12, 4451.65, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55075, 4, 44516.50, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55076, 5, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55077, 6, 28490.56, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55078, 47, 97033.56, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55079, 46, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55080, 13, 8086.13, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55081, 14, 0.00, 1815, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55082, 16, 0.00, 1815, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55083, 15, 105119.69, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55084, 17, 11563.17, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55085, 18, 3153.59, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55086, 19, 3153.59, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55087, 20, 2627.99, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55088, 21, 20498.34, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (54322, 47, 39741.54, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (55089, 22, 84621.35, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55090, 23, 84621.35, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55091, 32, 4231.07, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55092, 24, 34339.60, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55093, 25, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55094, 26, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55095, 29, 0.00, 1815, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55096, 27, 7154.08, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55097, 28, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55098, 30, 0.00, 1815, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55099, 31, 4231.07, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55100, 33, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55101, 34, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55102, 35, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55103, 36, 0.00, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55104, 37, 45724.75, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55105, 38, 38896.60, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55106, 40, 8230.84, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55107, 9, 2911.01, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55108, 10, 2911.01, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55109, 11, 2425.84, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55110, 39, 8230.84, 1815, NULL);
INSERT INTO public.recibos_conceptos VALUES (55113, 1, 27909.93, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55114, 7, 1116.40, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55115, 42, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55116, 12, 2790.99, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55117, 4, 27909.93, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55118, 5, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55119, 6, 558.20, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55120, 47, 33355.18, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55121, 46, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55122, 13, 2779.60, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55123, 14, 0.00, 1816, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55124, 16, 0.00, 1816, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55125, 15, 36134.78, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55126, 17, 3974.83, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55127, 18, 1084.04, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55128, 19, 1084.04, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55129, 20, 903.37, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55130, 21, 7046.28, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55131, 22, 29088.50, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55132, 23, 29088.50, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55133, 32, 1454.42, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55134, 24, 34339.60, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55135, 25, 6669.50, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55136, 26, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55137, 29, 0.00, 1816, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55138, 27, 7154.08, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55139, 28, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55140, 30, 0.00, 1816, 0.00);
INSERT INTO public.recibos_conceptos VALUES (55141, 31, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55142, 33, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55143, 34, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55144, 35, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55145, 36, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55146, 37, 48163.18, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55147, 38, -19074.68, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55148, 40, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55149, 9, 1000.66, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55150, 10, 1000.66, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55152, 39, 0.00, 1816, NULL);
INSERT INTO public.recibos_conceptos VALUES (55155, 45, 3376.41, 1802, 3376.41);
INSERT INTO public.recibos_conceptos VALUES (54355, 48, 1108.96, 1797, 1108.96);
INSERT INTO public.recibos_conceptos VALUES (54356, 49, -2500.00, 1797, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54397, 48, 333.14, 1798, 333.14);
INSERT INTO public.recibos_conceptos VALUES (54398, 49, -2500.00, 1798, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54440, 49, -2500.00, 1799, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54481, 48, 809.33, 1800, 809.33);
INSERT INTO public.recibos_conceptos VALUES (54482, 49, -1700.00, 1800, -1700.00);
INSERT INTO public.recibos_conceptos VALUES (54523, 48, 1140.80, 1801, 1140.80);
INSERT INTO public.recibos_conceptos VALUES (54524, 49, -2500.00, 1801, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54565, 48, 2225.40, 1802, 2225.40);
INSERT INTO public.recibos_conceptos VALUES (54566, 49, -2500.00, 1802, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (56714, 29, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56717, 30, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56741, 14, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56715, 27, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56716, 28, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56718, 31, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56719, 33, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56720, 34, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56721, 35, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56722, 36, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56723, 37, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56724, 38, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56725, 40, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56726, 8, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56727, 9, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56728, 10, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56787, 19, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56788, 20, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56789, 21, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56790, 22, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56791, 23, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56792, 32, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56793, 24, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56794, 25, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56795, 26, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56797, 27, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56798, 28, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56800, 31, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56801, 33, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56802, 34, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56803, 35, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56804, 36, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56805, 37, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56806, 38, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56807, 40, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56808, 8, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56809, 9, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56810, 10, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56811, 11, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56812, 39, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56813, 45, NULL, 1846, 3960.32);
INSERT INTO public.recibos_conceptos VALUES (56814, 48, NULL, 1846, 1834.35);
INSERT INTO public.recibos_conceptos VALUES (54607, 48, 347.72, 1803, 347.72);
INSERT INTO public.recibos_conceptos VALUES (54608, 49, -1125.00, 1803, -1125.00);
INSERT INTO public.recibos_conceptos VALUES (54649, 48, 948.83, 1804, 948.83);
INSERT INTO public.recibos_conceptos VALUES (55153, 48, 979.66, 1816, 979.66);
INSERT INTO public.recibos_conceptos VALUES (55154, 49, -2500.00, 1816, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (56815, 44, NULL, 1846, 2799.77);
INSERT INTO public.recibos_conceptos VALUES (54559, 38, 20339.17, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (55156, 51, 1483.33, 1804, 1483.33);
INSERT INTO public.recibos_conceptos VALUES (55157, 45, 3748.16, 1806, 3748.16);
INSERT INTO public.recibos_conceptos VALUES (55158, 45, 4858.79, 1807, 4858.79);
INSERT INTO public.recibos_conceptos VALUES (55159, 45, 1166.48, 1808, 1166.48);
INSERT INTO public.recibos_conceptos VALUES (55160, 44, 2649.80, 1808, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (55161, 45, 4600.00, 1809, 4600.00);
INSERT INTO public.recibos_conceptos VALUES (55162, 45, 1236.63, 1810, 1236.63);
INSERT INTO public.recibos_conceptos VALUES (55163, 44, 2649.80, 1812, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (55164, 45, 13955.00, 1815, 13955.00);
INSERT INTO public.recibos_conceptos VALUES (55165, 44, 2649.80, 1815, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (54691, 48, 1052.98, 1805, 1052.98);
INSERT INTO public.recibos_conceptos VALUES (54692, 49, -2500.00, 1805, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54733, 48, 1834.35, 1806, 1834.35);
INSERT INTO public.recibos_conceptos VALUES (54734, 49, -2500.00, 1806, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54775, 48, 1575.87, 1807, 1575.87);
INSERT INTO public.recibos_conceptos VALUES (54776, 49, -2500.00, 1807, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54817, 48, 1830.95, 1808, 1830.95);
INSERT INTO public.recibos_conceptos VALUES (54818, 49, -2500.00, 1808, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54859, 48, 1509.30, 1809, 1509.30);
INSERT INTO public.recibos_conceptos VALUES (56755, 29, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56758, 30, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56782, 14, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56783, 16, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56796, 29, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56799, 30, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (55993, 1, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55994, 7, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55995, 42, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55996, 12, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55997, 4, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55998, 5, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55999, 6, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56000, 47, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56001, 46, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56002, 13, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56005, 15, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56006, 17, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56007, 18, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56008, 19, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56009, 20, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56010, 21, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56011, 22, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56012, 23, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56013, 32, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56014, 24, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56015, 25, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (55373, 11, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55374, 39, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55375, 1, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55376, 7, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55377, 42, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55378, 12, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55379, 4, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55192, 25, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55193, 26, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55380, 5, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55381, 6, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55382, 47, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55383, 46, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55384, 13, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55387, 15, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55388, 17, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55389, 18, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55390, 19, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55391, 20, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55392, 21, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55195, 27, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55196, 28, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55393, 22, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (56019, 28, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56021, 31, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56022, 33, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56023, 34, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56024, 35, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56025, 36, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56026, 37, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56027, 38, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56028, 40, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56029, 8, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56030, 9, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56031, 10, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56032, 11, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56033, 39, NULL, 1837, NULL);
INSERT INTO public.recibos_conceptos VALUES (56034, 1, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56035, 7, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56036, 42, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56037, 12, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56038, 4, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56039, 5, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56040, 6, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56041, 47, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56042, 46, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56043, 13, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56046, 15, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56047, 17, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56048, 18, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56049, 19, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56050, 20, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56051, 21, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56052, 22, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56053, 23, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56054, 32, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56055, 24, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56056, 25, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56057, 26, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56059, 27, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56060, 28, NULL, 1838, NULL);
INSERT INTO public.recibos_conceptos VALUES (56729, 11, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56730, 39, NULL, 1854, NULL);
INSERT INTO public.recibos_conceptos VALUES (56731, 1, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56732, 7, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56733, 42, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56734, 12, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56735, 4, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56736, 5, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56737, 6, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56738, 47, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56739, 46, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56740, 13, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56743, 15, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56744, 17, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56745, 18, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56746, 19, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56747, 20, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56748, 21, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56749, 22, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56750, 23, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56751, 32, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56752, 24, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56753, 25, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56754, 26, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56756, 27, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56757, 28, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56759, 31, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56760, 33, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56761, 34, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56762, 35, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56763, 36, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56764, 37, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56765, 38, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56766, 40, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56767, 8, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56768, 9, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56769, 10, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56770, 11, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56771, 39, NULL, 1855, NULL);
INSERT INTO public.recibos_conceptos VALUES (56772, 1, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (56773, 7, NULL, 1856, NULL);
INSERT INTO public.recibos_conceptos VALUES (55394, 23, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55395, 32, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55198, 31, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55199, 33, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55396, 24, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55397, 25, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55398, 26, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55400, 27, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55401, 28, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55403, 31, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55404, 33, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55405, 34, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55406, 35, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55407, 36, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55408, 37, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55409, 38, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55410, 40, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55426, 14, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55427, 16, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55440, 29, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55443, 30, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55467, 14, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55468, 16, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55481, 29, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55484, 30, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55508, 14, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55509, 16, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55200, 34, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55180, 14, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55181, 16, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55201, 35, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55202, 36, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55203, 37, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55204, 38, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55205, 40, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55206, 8, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55207, 9, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55212, 7, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55213, 42, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55214, 12, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55215, 4, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55194, 29, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55522, 29, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55525, 30, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55549, 14, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55550, 16, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55563, 29, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55566, 30, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55590, 14, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55591, 16, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55411, 8, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55412, 9, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55413, 10, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55414, 11, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55415, 39, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55416, 1, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55417, 7, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55418, 42, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55419, 12, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55420, 4, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55421, 5, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55422, 6, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55423, 47, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55424, 46, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55425, 13, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55428, 15, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55429, 17, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55430, 18, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55431, 19, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55432, 20, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55433, 21, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55434, 22, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55435, 23, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55436, 32, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55437, 24, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55438, 25, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55439, 26, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55210, 39, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55441, 27, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55442, 28, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55444, 31, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55445, 33, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55446, 34, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55447, 35, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55448, 36, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55449, 37, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55450, 38, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55451, 40, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55452, 8, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55453, 9, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55454, 10, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55455, 11, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55456, 39, NULL, 1823, NULL);
INSERT INTO public.recibos_conceptos VALUES (55457, 1, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55458, 7, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55459, 42, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55460, 12, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55461, 4, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55462, 5, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55463, 6, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55464, 47, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55465, 46, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55466, 13, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55469, 15, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55470, 17, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55471, 18, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55472, 19, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55473, 20, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55474, 21, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55475, 22, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55476, 23, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55477, 32, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55478, 24, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55479, 25, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55480, 26, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55482, 27, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55483, 28, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55485, 31, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55486, 33, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55487, 34, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55488, 35, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55489, 36, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55490, 37, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55491, 38, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55492, 40, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55493, 8, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55494, 9, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55495, 10, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55496, 11, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55497, 39, NULL, 1824, NULL);
INSERT INTO public.recibos_conceptos VALUES (55498, 1, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55499, 7, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55500, 42, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55501, 12, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55502, 4, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55503, 5, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55504, 6, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55505, 47, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55506, 46, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55507, 13, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55510, 15, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55511, 17, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55512, 18, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55513, 19, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55514, 20, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55515, 21, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55516, 22, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55517, 23, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55518, 32, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55519, 24, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55520, 25, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55521, 26, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55523, 27, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55524, 28, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55526, 31, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55527, 33, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55528, 34, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55529, 35, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55530, 36, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55531, 37, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55532, 38, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55533, 40, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55534, 8, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55535, 9, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55536, 10, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55537, 11, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55538, 39, NULL, 1825, NULL);
INSERT INTO public.recibos_conceptos VALUES (55539, 1, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55540, 7, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55541, 42, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55542, 12, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55543, 4, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55544, 5, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55545, 6, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55546, 47, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55547, 46, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55548, 13, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55551, 15, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55552, 17, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55553, 18, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55554, 19, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55555, 20, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55556, 21, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55557, 22, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55558, 23, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55559, 32, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55560, 24, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55561, 25, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55562, 26, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55564, 27, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55565, 28, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55567, 31, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55568, 33, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55569, 34, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55197, 30, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55216, 5, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55217, 6, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55218, 47, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55221, 14, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55222, 16, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55219, 46, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55220, 13, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55223, 15, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55224, 17, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55225, 18, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55226, 19, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55227, 20, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55228, 21, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55229, 22, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55570, 35, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55571, 36, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55572, 37, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55573, 38, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55574, 40, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55575, 8, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55604, 29, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55607, 30, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55631, 14, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55632, 16, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55645, 29, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55648, 30, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55672, 14, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55673, 16, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55686, 29, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55689, 30, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55713, 14, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55714, 16, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55727, 29, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55730, 30, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55754, 14, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55755, 16, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55768, 29, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55771, 30, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55576, 9, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55577, 10, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55578, 11, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55579, 39, NULL, 1826, NULL);
INSERT INTO public.recibos_conceptos VALUES (55580, 1, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55581, 7, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55582, 42, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55583, 12, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55584, 4, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55585, 5, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55586, 6, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55587, 47, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55588, 46, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55589, 13, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55592, 15, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55593, 17, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55594, 18, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55595, 19, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55596, 20, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55597, 21, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55598, 22, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55599, 23, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55600, 32, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55601, 24, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55602, 25, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55603, 26, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55605, 27, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55606, 28, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55608, 31, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55609, 33, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55610, 34, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55611, 35, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55612, 36, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55613, 37, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55284, 36, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55614, 38, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55615, 40, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55616, 8, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55617, 9, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55618, 10, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55619, 11, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55620, 39, NULL, 1827, NULL);
INSERT INTO public.recibos_conceptos VALUES (55621, 1, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55622, 7, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55623, 42, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55624, 12, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55625, 4, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55626, 5, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55627, 6, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55628, 47, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55629, 46, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55630, 13, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55633, 15, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55634, 17, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55635, 18, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55636, 19, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55637, 20, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55638, 21, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55639, 22, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55640, 23, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55641, 32, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55642, 24, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55643, 25, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55644, 26, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55646, 27, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55647, 28, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55649, 31, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55650, 33, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55651, 34, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55652, 35, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55653, 36, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55654, 37, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55655, 38, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55656, 40, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55657, 8, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55658, 9, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55659, 10, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55660, 11, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55661, 39, NULL, 1828, NULL);
INSERT INTO public.recibos_conceptos VALUES (55662, 1, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55663, 7, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55664, 42, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55665, 12, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55666, 4, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55667, 5, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55668, 6, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55669, 47, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55670, 46, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55671, 13, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55674, 15, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55675, 17, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55676, 18, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55677, 19, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55678, 20, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55679, 21, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55680, 22, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55681, 23, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55682, 32, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55683, 24, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55684, 25, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55685, 26, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55687, 27, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55688, 28, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55690, 31, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55691, 33, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55692, 34, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55693, 35, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55694, 36, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55695, 37, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55696, 38, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55697, 40, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55698, 8, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55699, 9, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55700, 10, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55701, 11, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55702, 39, NULL, 1829, NULL);
INSERT INTO public.recibos_conceptos VALUES (55703, 1, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55704, 7, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55705, 42, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55706, 12, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55707, 4, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55708, 5, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55709, 6, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55710, 47, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55711, 46, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55712, 13, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55715, 15, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55716, 17, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55717, 18, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55230, 23, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55231, 32, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55232, 24, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55233, 25, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55234, 26, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55236, 27, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55237, 28, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55239, 31, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55240, 33, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55241, 34, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55242, 35, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55243, 36, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55244, 37, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55245, 38, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55235, 29, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55718, 19, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55719, 20, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55720, 21, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55721, 22, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55722, 23, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55723, 32, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55724, 24, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55725, 25, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55726, 26, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55728, 27, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55729, 28, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55731, 31, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55732, 33, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55733, 34, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55734, 35, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55735, 36, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55736, 37, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55737, 38, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55738, 40, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55739, 8, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55740, 9, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55795, 14, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55796, 16, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55809, 29, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55812, 30, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55836, 14, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55837, 16, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55850, 29, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55853, 30, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55877, 14, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55878, 16, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55891, 29, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55894, 30, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55918, 14, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55919, 16, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55932, 29, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55935, 30, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55959, 14, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55960, 16, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55741, 10, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55742, 11, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55743, 39, NULL, 1830, NULL);
INSERT INTO public.recibos_conceptos VALUES (55744, 1, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55745, 7, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55746, 42, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55747, 12, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55748, 4, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55749, 5, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55750, 6, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55751, 47, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55752, 46, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55753, 13, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55756, 15, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55757, 17, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55758, 18, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55759, 19, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55760, 20, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55761, 21, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55762, 22, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55763, 23, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (56244, 5, NULL, 1843, NULL);
INSERT INTO public.recibos_conceptos VALUES (55764, 32, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55765, 24, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55766, 25, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55767, 26, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55769, 27, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55770, 28, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55772, 31, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55797, 15, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55798, 17, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55799, 18, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55800, 19, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55801, 20, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55802, 21, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55803, 22, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55804, 23, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55805, 32, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55806, 24, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55807, 25, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55808, 26, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55810, 27, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55811, 28, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55813, 31, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55814, 33, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55815, 34, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55816, 35, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55817, 36, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55818, 37, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55819, 38, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55820, 40, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55821, 8, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55822, 9, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55823, 10, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55824, 11, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55825, 39, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55826, 1, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55827, 7, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55828, 42, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55829, 12, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55830, 4, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55831, 5, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55832, 6, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55833, 47, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55834, 46, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55835, 13, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55838, 15, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55839, 17, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55840, 18, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55841, 19, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55842, 20, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55843, 21, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55844, 22, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55845, 23, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55846, 32, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55847, 24, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55848, 25, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55849, 26, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55851, 27, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55852, 28, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55854, 31, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55855, 33, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55856, 34, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55857, 35, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55858, 36, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55859, 37, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55860, 38, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55861, 40, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55862, 8, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55863, 9, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55864, 10, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55865, 11, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55866, 39, NULL, 1833, NULL);
INSERT INTO public.recibos_conceptos VALUES (55867, 1, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55868, 7, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55869, 42, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55870, 12, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55871, 4, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55872, 5, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55873, 6, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55874, 47, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55875, 46, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55876, 13, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55879, 15, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55880, 17, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55881, 18, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55882, 19, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55883, 20, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55884, 21, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55885, 22, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55886, 23, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55887, 32, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55888, 24, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55889, 25, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55238, 30, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55262, 14, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55263, 16, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55276, 29, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55279, 30, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55303, 14, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55304, 16, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55317, 29, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55320, 30, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55344, 14, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55345, 16, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55358, 29, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55361, 30, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55385, 14, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55386, 16, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55399, 29, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55402, 30, NULL, 1822, NULL);
INSERT INTO public.recibos_conceptos VALUES (55890, 26, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55892, 27, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55893, 28, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55895, 31, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55896, 33, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55897, 34, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55898, 35, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55899, 36, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55900, 37, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55901, 38, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55902, 40, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55903, 8, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55904, 9, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55905, 10, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55973, 29, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55976, 30, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55170, 1, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55171, 7, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55172, 42, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55173, 12, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55174, 4, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55175, 5, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55176, 6, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55177, 47, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55178, 46, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55179, 13, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55182, 15, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55183, 17, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55184, 18, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55185, 19, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55186, 20, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55187, 21, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55188, 22, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55189, 23, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55190, 32, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55191, 24, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55208, 10, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55209, 11, NULL, 1817, NULL);
INSERT INTO public.recibos_conceptos VALUES (55211, 1, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55985, 8, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55986, 9, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55987, 10, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55906, 11, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55907, 39, NULL, 1834, NULL);
INSERT INTO public.recibos_conceptos VALUES (55908, 1, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55909, 7, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55910, 42, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55911, 12, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55912, 4, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55913, 5, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55914, 6, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55915, 47, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55916, 46, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55917, 13, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55920, 15, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55921, 17, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55922, 18, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55923, 19, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55924, 20, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55925, 21, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55926, 22, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55927, 23, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55928, 32, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55929, 24, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55930, 25, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55931, 26, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55933, 27, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55934, 28, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55936, 31, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55937, 33, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55938, 34, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55939, 35, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55940, 36, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55941, 37, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55942, 38, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55943, 40, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55944, 8, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55945, 9, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55946, 10, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55947, 11, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55948, 39, NULL, 1835, NULL);
INSERT INTO public.recibos_conceptos VALUES (55949, 1, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55950, 7, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55951, 42, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55952, 12, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55953, 4, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55954, 5, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55955, 6, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55956, 47, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55957, 46, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55958, 13, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55961, 15, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55962, 17, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55963, 18, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55964, 19, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55965, 20, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55966, 21, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55967, 22, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55968, 23, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55969, 32, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55970, 24, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55971, 25, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55972, 26, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55974, 27, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55975, 28, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55977, 31, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55978, 33, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55979, 34, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55980, 35, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55981, 36, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55982, 37, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55983, 38, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55984, 40, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55988, 11, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55989, 39, NULL, 1836, NULL);
INSERT INTO public.recibos_conceptos VALUES (55990, 45, NULL, 1826, 3960.32);
INSERT INTO public.recibos_conceptos VALUES (55991, 48, NULL, 1826, 1834.35);
INSERT INTO public.recibos_conceptos VALUES (55992, 44, NULL, 1826, 2799.77);
INSERT INTO public.recibos_conceptos VALUES (55246, 40, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55247, 8, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55248, 9, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55249, 10, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55250, 11, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55251, 39, NULL, 1818, NULL);
INSERT INTO public.recibos_conceptos VALUES (55252, 1, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55253, 7, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55254, 42, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55255, 12, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55256, 4, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55257, 5, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55258, 6, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55259, 47, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55260, 46, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55261, 13, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55264, 15, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55265, 17, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55266, 18, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55267, 19, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55268, 20, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55269, 21, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55285, 37, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55286, 38, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55287, 40, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55773, 33, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55774, 34, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55775, 35, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55776, 36, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55777, 37, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55778, 38, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55779, 40, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55780, 8, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55781, 9, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55782, 10, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55783, 11, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55784, 39, NULL, 1831, NULL);
INSERT INTO public.recibos_conceptos VALUES (55785, 1, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55786, 7, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55787, 42, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55788, 12, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55789, 4, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55790, 5, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55791, 6, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55792, 47, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55793, 46, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55794, 13, NULL, 1832, NULL);
INSERT INTO public.recibos_conceptos VALUES (55364, 34, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55365, 35, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55366, 36, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55367, 37, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55368, 38, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55369, 40, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55370, 8, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55371, 9, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55372, 10, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55270, 22, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55271, 23, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55272, 32, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55273, 24, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55274, 25, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55275, 26, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55277, 27, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55278, 28, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55280, 31, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55281, 33, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55282, 34, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55283, 35, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55288, 8, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55289, 9, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55290, 10, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55291, 11, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55292, 39, NULL, 1819, NULL);
INSERT INTO public.recibos_conceptos VALUES (55293, 1, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55294, 7, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55295, 42, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55296, 12, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55297, 4, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55298, 5, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55299, 6, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55300, 47, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55301, 46, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (56611, 12, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56612, 4, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56613, 5, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56614, 6, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56615, 47, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56616, 46, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56617, 13, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56620, 15, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56621, 17, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56622, 18, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56623, 19, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56624, 20, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56625, 21, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56626, 22, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56627, 23, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56628, 32, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56629, 24, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56630, 25, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56631, 26, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56633, 27, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56634, 28, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56636, 31, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56637, 33, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56638, 34, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56639, 35, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56640, 36, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56641, 37, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56642, 38, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56643, 40, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56644, 8, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56645, 9, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (56646, 10, NULL, 1852, NULL);
INSERT INTO public.recibos_conceptos VALUES (55302, 13, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55305, 15, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55306, 17, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55307, 18, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55308, 19, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55309, 20, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55310, 21, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55311, 22, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55312, 23, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55313, 32, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55314, 24, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55315, 25, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55316, 26, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55318, 27, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55319, 28, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55321, 31, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55322, 33, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55323, 34, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55324, 35, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55325, 36, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55326, 37, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55327, 38, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55328, 40, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55329, 8, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55330, 9, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55331, 10, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55332, 11, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55333, 39, NULL, 1820, NULL);
INSERT INTO public.recibos_conceptos VALUES (55334, 1, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55335, 7, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55336, 42, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55337, 12, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55338, 4, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55339, 5, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55340, 6, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55341, 47, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55342, 46, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55343, 13, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55346, 15, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55347, 17, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55348, 18, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55349, 19, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55350, 20, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55351, 21, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55352, 22, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55353, 23, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55354, 32, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55355, 24, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55356, 25, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55357, 26, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55359, 27, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55360, 28, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55362, 31, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (55363, 33, NULL, 1821, NULL);
INSERT INTO public.recibos_conceptos VALUES (54560, 40, 3053.55, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54561, 9, 2239.02, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54562, 10, 2239.02, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54563, 11, 1865.85, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54860, 49, -2500.00, 1809, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54901, 48, 1121.28, 1810, 1121.28);
INSERT INTO public.recibos_conceptos VALUES (54902, 49, -2500.00, 1810, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54943, 48, 1039.45, 1811, 1039.45);
INSERT INTO public.recibos_conceptos VALUES (54944, 49, -2500.00, 1811, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (54985, 48, 1372.70, 1812, 1372.70);
INSERT INTO public.recibos_conceptos VALUES (54370, 17, 6.19, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54371, 18, 1.69, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54372, 19, 1.69, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54373, 20, 1.41, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54426, 30, 0.00, 1799, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54374, 21, 10.98, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54375, 22, 45.33, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54376, 23, 45.33, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54479, 11, 623.02, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54480, 39, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54483, 1, 28051.97, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54484, 7, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54485, 42, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54486, 12, 2805.20, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54346, 35, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54487, 4, 28051.97, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54488, 5, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54489, 6, 2244.16, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54490, 47, 36891.92, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54491, 46, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54492, 13, 3074.33, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54493, 14, 0.00, 1801, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54494, 16, 0.00, 1801, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54495, 15, 39966.25, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54496, 17, 4396.29, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54428, 33, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54429, 34, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54430, 35, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54431, 36, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54432, 37, 49207.70, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54433, 38, 5363.55, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54434, 40, 372.59, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54435, 9, 1877.27, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54436, 10, 1877.27, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54437, 11, 1564.39, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54438, 39, 372.59, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54439, 48, 0.00, 1799, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54441, 1, 19136.11, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54442, 7, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54443, 42, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54444, 12, 1913.61, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54445, 4, 19136.11, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54446, 5, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54447, 6, 3061.78, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54504, 24, 34339.60, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54505, 25, 6669.50, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54508, 27, 7154.08, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54509, 28, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54510, 30, 0.00, 1801, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54511, 31, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54512, 33, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54513, 34, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54514, 35, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54515, 36, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54516, 37, 48163.18, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54517, 38, -15990.35, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54518, 40, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54519, 9, 1106.76, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54520, 10, 1106.76, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54521, 11, 922.30, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54522, 39, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54525, 1, 38150.89, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54526, 7, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54421, 25, 6669.50, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54422, 26, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54467, 28, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54468, 30, 0.00, 1800, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54469, 31, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54470, 33, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54471, 34, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54472, 35, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54473, 36, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54474, 37, 41493.68, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54475, 38, -19760.64, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54476, 40, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54527, 42, 0.00, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54528, 12, 3815.09, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (55015, 31, 2730.10, 1813, NULL);
INSERT INTO public.recibos_conceptos VALUES (54377, 32, 2.27, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54378, 24, 34339.60, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54379, 25, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54380, 26, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54383, 28, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54384, 30, 0.00, 1798, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54385, 31, 2.27, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54386, 33, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54387, 34, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54388, 35, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54389, 36, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54390, 37, 41495.95, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54391, 38, -41450.62, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54392, 40, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54564, 39, 3053.55, 1802, NULL);
INSERT INTO public.recibos_conceptos VALUES (54567, 1, 13537.16, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (56826, 1, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56827, 42, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56828, 12, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56829, 4, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56830, 5, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56831, 6, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56832, 47, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56833, 46, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56834, 13, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56835, 14, 0.00, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56836, 16, 0.00, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56837, 15, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56838, 17, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56839, 18, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56840, 19, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56841, 20, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56842, 21, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56843, 22, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56844, 23, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56845, 32, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56846, 24, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56847, 25, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56848, 26, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56849, 29, 0.00, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56850, 27, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56851, 28, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56852, 30, 0.00, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56853, 31, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56854, 33, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56855, 34, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56856, 35, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56857, 36, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56858, 37, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56859, 38, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56860, 40, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56861, 8, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56862, 9, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56863, 10, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56864, 11, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56865, 39, NULL, 1857, NULL);
INSERT INTO public.recibos_conceptos VALUES (56866, 1, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56867, 42, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56868, 12, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56869, 4, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56870, 5, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56871, 6, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56872, 47, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56873, 46, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56874, 13, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56875, 14, 0.00, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56876, 16, 0.00, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56877, 15, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56878, 17, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56879, 18, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56880, 19, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56881, 20, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56882, 21, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56883, 22, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56884, 23, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56885, 32, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56886, 24, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56887, 25, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56888, 26, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56889, 29, 0.00, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56890, 27, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56891, 28, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56892, 30, 0.00, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56893, 31, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56894, 33, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56895, 34, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56896, 35, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56897, 36, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56898, 37, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56899, 38, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56900, 40, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56901, 8, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56902, 9, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56903, 10, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56904, 11, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56905, 39, NULL, 1858, NULL);
INSERT INTO public.recibos_conceptos VALUES (56906, 1, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56907, 42, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56908, 12, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56909, 4, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56910, 5, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56911, 6, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56912, 47, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56913, 46, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56914, 13, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56915, 14, 0.00, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56916, 16, 0.00, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56917, 15, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56918, 17, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56919, 18, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56920, 19, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56921, 20, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56922, 21, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56923, 22, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56924, 23, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56925, 32, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56926, 24, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56927, 25, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56928, 26, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56929, 29, 0.00, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56930, 27, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56931, 28, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56932, 30, 0.00, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56933, 31, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56934, 33, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56935, 34, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56936, 35, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56937, 36, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56938, 37, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56939, 38, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56940, 40, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56941, 8, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56942, 9, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56943, 10, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56944, 11, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56945, 39, NULL, 1859, NULL);
INSERT INTO public.recibos_conceptos VALUES (56946, 1, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56947, 42, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56948, 12, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56949, 4, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56950, 5, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56951, 6, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56952, 47, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56953, 46, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56954, 13, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56955, 14, 0.00, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56956, 16, 0.00, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56957, 15, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56958, 17, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56959, 18, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56960, 19, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56961, 20, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56962, 21, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56963, 22, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56964, 23, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56965, 32, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56966, 24, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56967, 25, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56968, 26, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56969, 29, 0.00, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56970, 27, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56971, 28, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56972, 30, 0.00, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56973, 31, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56974, 33, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56975, 34, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56976, 35, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56977, 36, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56978, 37, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56979, 38, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56980, 40, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56981, 8, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56982, 9, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56983, 10, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56984, 11, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56985, 39, NULL, 1860, NULL);
INSERT INTO public.recibos_conceptos VALUES (56986, 1, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56987, 42, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56988, 12, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56989, 4, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56990, 5, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56991, 6, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56992, 47, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56993, 46, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56994, 13, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56995, 14, 0.00, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56996, 16, 0.00, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56997, 15, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56998, 17, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (56999, 18, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57000, 19, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57001, 20, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57002, 21, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57003, 22, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57004, 23, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57005, 32, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57006, 24, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57007, 25, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57008, 26, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57009, 29, 0.00, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57010, 27, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57011, 28, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57012, 30, 0.00, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57013, 31, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57014, 33, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57015, 34, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57016, 35, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57017, 36, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57018, 37, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57019, 38, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57020, 40, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57021, 8, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57022, 9, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57023, 10, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57024, 11, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57025, 39, NULL, 1861, NULL);
INSERT INTO public.recibos_conceptos VALUES (57026, 1, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57027, 42, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57028, 12, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57029, 4, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57030, 5, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57031, 6, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57032, 47, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57033, 46, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57034, 13, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57035, 14, 0.00, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57036, 16, 0.00, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57037, 15, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57038, 17, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57039, 18, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57040, 19, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57041, 20, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57042, 21, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57043, 22, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57044, 23, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57045, 32, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57046, 24, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57047, 25, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57048, 26, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57049, 29, 0.00, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57050, 27, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57051, 28, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57052, 30, 0.00, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57053, 31, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57054, 33, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57055, 34, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57056, 35, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57057, 36, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57058, 37, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57059, 38, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57060, 40, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57061, 8, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57062, 9, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57063, 10, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57064, 11, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57065, 39, NULL, 1862, NULL);
INSERT INTO public.recibos_conceptos VALUES (57066, 1, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57067, 42, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57068, 12, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57069, 4, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57070, 5, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57071, 6, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57072, 47, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57073, 46, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57074, 13, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57075, 14, 0.00, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57076, 16, 0.00, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57077, 15, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57078, 17, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57079, 18, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57080, 19, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57081, 20, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57082, 21, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57083, 22, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57084, 23, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57085, 32, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57086, 24, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57087, 25, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57088, 26, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57089, 29, 0.00, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57090, 27, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57091, 28, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57092, 30, 0.00, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57093, 31, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57094, 33, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57095, 34, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57096, 35, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57097, 36, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57098, 37, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57099, 38, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57100, 40, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57101, 8, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57102, 9, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57103, 10, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57104, 11, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57105, 39, NULL, 1863, NULL);
INSERT INTO public.recibos_conceptos VALUES (57106, 1, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57107, 42, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57108, 12, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57109, 4, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57110, 5, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57111, 6, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57112, 47, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57113, 46, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57114, 13, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57115, 14, 0.00, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57116, 16, 0.00, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57117, 15, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57118, 17, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57119, 18, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57120, 19, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57121, 20, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57122, 21, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57123, 22, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57124, 23, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57125, 32, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57126, 24, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57127, 25, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57128, 26, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57129, 29, 0.00, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57130, 27, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57131, 28, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57132, 30, 0.00, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57133, 31, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57134, 33, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57135, 34, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57136, 35, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57137, 36, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57138, 37, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57139, 38, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57140, 40, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57141, 8, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57142, 9, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57143, 10, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57144, 11, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57145, 39, NULL, 1864, NULL);
INSERT INTO public.recibos_conceptos VALUES (57146, 1, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57147, 42, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57148, 12, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57149, 4, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57150, 5, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57151, 6, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57152, 47, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57153, 46, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57154, 13, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57155, 14, 0.00, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57156, 16, 0.00, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57157, 15, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57158, 17, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57159, 18, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57160, 19, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57161, 20, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57162, 21, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57163, 22, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57164, 23, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57165, 32, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57166, 24, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57167, 25, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57168, 26, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57169, 29, 0.00, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57170, 27, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57171, 28, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57172, 30, 0.00, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57173, 31, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57174, 33, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57175, 34, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57176, 35, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57177, 36, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57178, 37, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57179, 38, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57180, 40, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57181, 8, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57182, 9, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57183, 10, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57184, 11, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57185, 39, NULL, 1865, NULL);
INSERT INTO public.recibos_conceptos VALUES (57186, 1, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57187, 42, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57188, 12, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57189, 4, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57190, 5, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57191, 6, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57192, 47, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57193, 46, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57194, 13, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57195, 14, 0.00, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57196, 16, 0.00, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57197, 15, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57198, 17, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57199, 18, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57200, 19, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57201, 20, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57202, 21, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57203, 22, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57204, 23, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57205, 32, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57206, 24, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57207, 25, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57208, 26, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57209, 29, 0.00, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57210, 27, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57211, 28, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57212, 30, 0.00, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57213, 31, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57214, 33, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57215, 34, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57216, 35, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57217, 36, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57218, 37, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57219, 38, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57220, 40, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57221, 8, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57222, 9, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57223, 10, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57224, 11, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57225, 39, NULL, 1866, NULL);
INSERT INTO public.recibos_conceptos VALUES (57226, 1, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57227, 42, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57228, 12, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57229, 4, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57230, 5, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57231, 6, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57232, 47, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57233, 46, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57234, 13, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57235, 14, 0.00, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57236, 16, 0.00, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57237, 15, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57238, 17, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57239, 18, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57240, 19, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57241, 20, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57242, 21, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57243, 22, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57244, 23, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57245, 32, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57246, 24, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57247, 25, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57248, 26, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57249, 29, 0.00, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57250, 27, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57251, 28, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57252, 30, 0.00, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57253, 31, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57254, 33, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57255, 34, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57256, 35, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57257, 36, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57258, 37, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57259, 38, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57260, 40, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57261, 8, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57262, 9, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57263, 10, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57264, 11, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57265, 39, NULL, 1867, NULL);
INSERT INTO public.recibos_conceptos VALUES (57266, 1, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57267, 42, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57268, 12, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57269, 4, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57270, 5, 3.00, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57271, 6, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57272, 47, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57273, 46, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57274, 13, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57275, 14, 0.00, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57276, 16, 0.00, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57277, 15, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57278, 17, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57279, 18, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57280, 19, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57281, 20, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57282, 21, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57283, 22, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57284, 23, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57285, 32, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57286, 24, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57287, 25, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57288, 26, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57289, 29, 0.00, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57290, 27, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57291, 28, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57292, 30, 0.00, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57293, 31, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57294, 33, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57295, 34, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57296, 35, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57297, 36, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57298, 37, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57299, 38, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57300, 40, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57301, 8, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57302, 9, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57303, 10, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57304, 11, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57305, 39, NULL, 1868, NULL);
INSERT INTO public.recibos_conceptos VALUES (57306, 1, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57307, 42, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57308, 12, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57309, 4, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57310, 5, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57311, 6, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57312, 47, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57313, 46, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57314, 13, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57315, 14, 0.00, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57316, 16, 0.00, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57317, 15, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57318, 17, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57319, 18, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57320, 19, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57321, 20, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57322, 21, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57323, 22, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57324, 23, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57325, 32, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57326, 24, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57327, 25, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57328, 26, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57329, 29, 0.00, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57330, 27, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57331, 28, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57332, 30, 0.00, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57333, 31, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57334, 33, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57335, 34, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57336, 35, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57337, 36, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57338, 37, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57339, 38, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57340, 40, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57341, 8, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57342, 9, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57343, 10, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57344, 11, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57345, 39, NULL, 1869, NULL);
INSERT INTO public.recibos_conceptos VALUES (57346, 1, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57347, 42, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57348, 12, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57349, 4, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57350, 5, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57351, 6, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57352, 47, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57353, 46, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57354, 13, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57355, 14, 0.00, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57356, 16, 0.00, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57357, 15, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57358, 17, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57359, 18, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57360, 19, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57361, 20, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57362, 21, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57363, 22, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57364, 23, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57365, 32, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57366, 24, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57367, 25, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57368, 26, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57369, 29, 0.00, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57370, 27, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57371, 28, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57372, 30, 0.00, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57373, 31, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57374, 33, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57375, 34, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57376, 35, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57377, 36, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57378, 37, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57379, 38, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57380, 40, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57381, 8, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57382, 9, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57383, 10, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57384, 11, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57385, 39, NULL, 1870, NULL);
INSERT INTO public.recibos_conceptos VALUES (57386, 1, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57387, 42, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57388, 12, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57389, 4, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57390, 5, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57391, 6, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57392, 47, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57393, 46, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57394, 13, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57395, 14, 0.00, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57396, 16, 0.00, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57397, 15, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57398, 17, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57399, 18, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57400, 19, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57401, 20, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57402, 21, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57403, 22, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57404, 23, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57405, 32, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57406, 24, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57407, 25, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57408, 26, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57409, 29, 0.00, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57410, 27, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57411, 28, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57412, 30, 0.00, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57413, 31, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57414, 33, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57415, 34, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57416, 35, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57417, 36, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57418, 37, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57419, 38, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57420, 40, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57421, 8, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57422, 9, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57423, 10, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57424, 11, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57425, 39, NULL, 1871, NULL);
INSERT INTO public.recibos_conceptos VALUES (57426, 1, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57427, 42, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57428, 12, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57429, 4, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57430, 5, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57431, 6, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57432, 47, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57433, 46, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57434, 13, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57435, 14, 0.00, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57436, 16, 0.00, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57437, 15, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57438, 17, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57439, 18, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57440, 19, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57441, 20, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57442, 21, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57443, 22, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57444, 23, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57445, 32, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57446, 24, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57447, 25, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57448, 26, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57449, 29, 0.00, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57450, 27, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57451, 28, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57452, 30, 0.00, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57453, 31, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57454, 33, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57455, 34, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57456, 35, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57457, 36, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57458, 37, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57459, 38, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57460, 40, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57461, 8, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57462, 9, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57463, 10, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57464, 11, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57465, 39, NULL, 1872, NULL);
INSERT INTO public.recibos_conceptos VALUES (57466, 1, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57467, 42, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57468, 12, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57469, 4, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57470, 5, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57471, 6, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57472, 47, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57473, 46, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57474, 13, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57475, 14, 0.00, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57476, 16, 0.00, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57477, 15, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57478, 17, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57479, 18, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57480, 19, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57481, 20, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57482, 21, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57483, 22, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57484, 23, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57485, 32, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57486, 24, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57487, 25, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57488, 26, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57489, 29, 0.00, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57490, 27, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57491, 28, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57492, 30, 0.00, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57493, 31, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57494, 33, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57495, 34, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57496, 35, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57497, 36, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57498, 37, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57499, 38, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57500, 40, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57501, 8, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57502, 9, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57503, 10, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57504, 11, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57505, 39, NULL, 1873, NULL);
INSERT INTO public.recibos_conceptos VALUES (57506, 1, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57507, 42, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57508, 12, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57509, 4, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57510, 5, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57511, 6, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57512, 47, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57513, 46, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57514, 13, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57515, 14, 0.00, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57516, 16, 0.00, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57517, 15, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57518, 17, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57519, 18, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57520, 19, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57521, 20, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57522, 21, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57523, 22, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57524, 23, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57525, 32, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57526, 24, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57527, 25, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57528, 26, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57529, 29, 0.00, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57530, 27, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57531, 28, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57532, 30, 0.00, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57533, 31, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57534, 33, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57535, 34, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57536, 35, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57537, 36, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57538, 37, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57539, 38, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57540, 40, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57541, 8, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57542, 9, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57543, 10, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57544, 11, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57545, 39, NULL, 1874, NULL);
INSERT INTO public.recibos_conceptos VALUES (57546, 1, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57547, 42, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57548, 12, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57549, 4, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57550, 5, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57551, 6, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57552, 47, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57553, 46, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57554, 13, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57555, 14, 0.00, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57556, 16, 0.00, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57557, 15, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57558, 17, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57559, 18, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57560, 19, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57561, 20, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57562, 21, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57563, 22, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57564, 23, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57565, 32, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57566, 24, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57567, 25, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57568, 26, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57569, 29, 0.00, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57570, 27, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57571, 28, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57572, 30, 0.00, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57573, 31, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57574, 33, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57575, 34, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57576, 35, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57577, 36, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57578, 37, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57579, 38, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57580, 40, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57581, 8, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57582, 9, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57583, 10, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57584, 11, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57585, 39, NULL, 1875, NULL);
INSERT INTO public.recibos_conceptos VALUES (57586, 1, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57587, 42, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57588, 12, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57589, 4, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57590, 5, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57591, 6, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57592, 47, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57593, 46, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57594, 13, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57595, 14, 0.00, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57596, 16, 0.00, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57597, 15, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57598, 17, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57599, 18, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57600, 19, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57601, 20, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57602, 21, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57603, 22, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57604, 23, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57605, 32, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57606, 24, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57607, 25, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57608, 26, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57609, 29, 0.00, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57610, 27, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57611, 28, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57612, 30, 0.00, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57613, 31, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57614, 33, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57615, 34, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57616, 35, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57617, 36, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57618, 37, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57619, 38, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57620, 40, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57621, 8, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57622, 9, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57623, 10, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57624, 11, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (57625, 39, NULL, 1876, NULL);
INSERT INTO public.recibos_conceptos VALUES (55053, 29, 0.00, 1814, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54448, 47, 24920.83, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54449, 46, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54450, 13, 2076.74, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54451, 14, 0.00, 1800, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54452, 16, 0.00, 1800, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54453, 15, 26997.56, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54454, 17, 2969.73, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54455, 18, 809.93, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54456, 19, 809.93, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54457, 20, 674.94, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54458, 21, 5264.53, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54459, 22, 21733.04, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54460, 23, 21733.04, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54461, 32, 1086.65, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54462, 24, 34339.60, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54463, 25, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54464, 26, 0.00, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54465, 29, 0.00, 1800, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54466, 27, 7154.08, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54574, 47, 16050.83, 1803, NULL);
INSERT INTO public.recibos_conceptos VALUES (55062, 37, 41493.68, 1814, NULL);
INSERT INTO public.recibos_conceptos VALUES (54399, 1, 36809.25, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54401, 42, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54402, 12, 3680.93, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54403, 4, 36809.25, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54404, 5, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54405, 6, 22085.55, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54406, 47, 62575.73, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54407, 46, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54408, 13, 5214.64, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54409, 14, 0.00, 1799, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54410, 16, 0.00, 1799, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54411, 15, 67790.37, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54412, 17, 7456.94, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54413, 18, 2033.71, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54414, 19, 2033.71, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54415, 20, 1694.76, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54416, 21, 13219.12, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54315, 1, 28027.12, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54316, 7, 3878.95, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54317, 42, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54318, 12, 2802.71, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54319, 4, 28027.12, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54320, 5, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54321, 6, 3923.80, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54417, 22, 54571.25, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54418, 23, 54571.25, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54419, 32, 2728.56, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54420, 24, 34339.60, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54499, 20, 999.16, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54506, 26, 0.00, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54507, 29, 0.00, 1801, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54501, 22, 32172.83, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54502, 23, 32172.83, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54503, 32, 1608.64, 1801, NULL);
INSERT INTO public.recibos_conceptos VALUES (54393, 9, 1.56, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54394, 10, 1.56, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54395, 11, 1.30, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54396, 39, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54423, 29, 0.00, 1799, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54424, 27, 7154.08, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54425, 28, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54427, 31, 1044.52, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54364, 47, 59.06, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54365, 46, -14123.23, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54366, 13, 4.33, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54381, 29, 0.00, 1798, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54382, 27, 7154.08, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54400, 7, 0.00, 1799, NULL);
INSERT INTO public.recibos_conceptos VALUES (54477, 9, 747.62, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54478, 10, 747.62, 1800, NULL);
INSERT INTO public.recibos_conceptos VALUES (54986, 49, -2500.00, 1812, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (55028, 49, -2500.00, 1813, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (55069, 48, 280.19, 1814, 280.19);
INSERT INTO public.recibos_conceptos VALUES (55070, 49, -2500.00, 1814, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (55111, 48, 2970.05, 1815, 2970.05);
INSERT INTO public.recibos_conceptos VALUES (55112, 49, -2500.00, 1815, -2500.00);
INSERT INTO public.recibos_conceptos VALUES (55166, 45, 873.04, 1798, 873.04);
INSERT INTO public.recibos_conceptos VALUES (55167, 44, 2649.80, 1801, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (55168, 44, 2649.80, 1802, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (55169, 44, 2649.80, 1806, 2649.80);
INSERT INTO public.recibos_conceptos VALUES (54347, 36, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54348, 37, 48163.18, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54349, 38, -13505.24, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54350, 40, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54351, 9, 1192.25, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54352, 10, 1192.25, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54353, 11, 993.54, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54354, 39, 0.00, 1797, NULL);
INSERT INTO public.recibos_conceptos VALUES (54357, 1, 8725.71, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54358, 7, 98.60, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54359, 42, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54360, 12, 3272.14, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54361, 4, 8725.71, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54362, 5, 0.00, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54363, 6, 872.57, 1798, NULL);
INSERT INTO public.recibos_conceptos VALUES (54367, 14, 0.00, 1798, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54368, 16, 0.00, 1798, 0.00);
INSERT INTO public.recibos_conceptos VALUES (54369, 15, 56.31, 1798, NULL);


--
-- Name: recibos_conceptos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 57645, true);


--
-- Name: recibos_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.recibos_id_seq', 1876, true);


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
INSERT INTO public.tabla_ganancias_detalle VALUES (28, 3, 16519.90, 25779.85, 1156.39, 12.00, 16519.90, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (29, 3, 24779.85, 33039.81, 2147.59, 15.00, 24779.85, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (30, 3, 33039.81, 49559.71, 3386.58, 19.00, 33039.81, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (31, 3, 49559.71, 66079.61, 6525.36, 23.00, 49559.71, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (24, 3, 8259.95, 16519.90, 413.00, 9.00, 8259.95, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (25, 3, 0.00, 8259.95, 0.00, 5.00, 0.00, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (32, 3, 66079.61, 99119.42, 10324.94, 27.00, 66079.61, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (33, 3, 99119.42, 132159.23, 19245.69, 31.00, 99119.42, 2);
INSERT INTO public.tabla_ganancias_detalle VALUES (34, 3, 132159.23, 999999.00, 29488.03, 35.00, 132159.23, 2);


--
-- Name: tabla_ganancias_detalle_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_ganancias_detalle_id_seq', 34, true);


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
INSERT INTO public.tabla_personas VALUES (22, 2019, 2, '2019-02-01', 5838.00, 17, 8);
INSERT INTO public.tabla_personas VALUES (24, 2019, 3, '2019-03-01', 6129.00, 17, 8);


--
-- Name: tabla_personas_id_seq; Type: SEQUENCE SET; Schema: public; Owner: -
--

SELECT pg_catalog.setval('public.tabla_personas_id_seq', 24, true);


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
-- Name: pk_historico_sueldo_basico; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_sueldo_basico
    ADD CONSTRAINT pk_historico_sueldo_basico PRIMARY KEY (id);


--
-- Name: pk_historico_sueldo_basico_detalle; Type: CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_sueldo_basico_detalle
    ADD CONSTRAINT pk_historico_sueldo_basico_detalle PRIMARY KEY (id);


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
-- Name: fk_historico_sueldo_basico_detalle__cabecera; Type: FK CONSTRAINT; Schema: public; Owner: -
--

ALTER TABLE ONLY public.historico_sueldo_basico_detalle
    ADD CONSTRAINT fk_historico_sueldo_basico_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES public.historico_sueldo_basico(id);


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

