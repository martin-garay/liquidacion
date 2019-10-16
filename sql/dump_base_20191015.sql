PGDMP         /            	    w         
   asociacion    9.5.19    9.5.19 �   �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    579533 
   asociacion    DATABASE     |   CREATE DATABASE asociacion WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_AR.UTF-8' LC_CTYPE = 'es_AR.UTF-8';
    DROP DATABASE asociacion;
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
             postgres    false            �           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                  postgres    false    6                        2615    561161    sistema    SCHEMA        CREATE SCHEMA sistema;
    DROP SCHEMA sistema;
             postgres    false                        3079    12435    plpgsql 	   EXTENSION     ?   CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;
    DROP EXTENSION plpgsql;
                  false            �           0    0    EXTENSION plpgsql    COMMENT     @   COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';
                       false    1            .           1255    561162    antiguedad(integer, date)    FUNCTION       CREATE FUNCTION public.antiguedad(id_persona integer, _fecha date DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	resultado integer;
BEGIN
    SELECT edad(fecha_ingreso, _fecha) INTO resultado FROM personas WHERE id=id_persona;
    return resultado;
END;
$$;
 B   DROP FUNCTION public.antiguedad(id_persona integer, _fecha date);
       public       postgres    false    1    6            /           1255    561163    antiguedad_dias(integer, date)    FUNCTION     L  CREATE FUNCTION public.antiguedad_dias(_id_persona integer, _fecha date DEFAULT now()) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
	resultado integer;
BEGIN    
    SELECT (EXTRACT(epoch from age(fecha_ingreso, _fecha)) / 86400)::int INTO resultado FROM personas WHERE id=_id_persona;
    return abs(resultado);
END;
$$;
 H   DROP FUNCTION public.antiguedad_dias(_id_persona integer, _fecha date);
       public       postgres    false    6    1            <           1255    561164    dias_mes(date)    FUNCTION       CREATE FUNCTION public.dias_mes(fecha date) RETURNS integer
    LANGUAGE plpgsql
    AS $$
DECLARE
    cant_dias integer;
BEGIN
	SELECT DATE_PART('days', DATE_TRUNC('month', fecha) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL ) into cant_dias;
	return cant_dias;
END;
$$;
 +   DROP FUNCTION public.dias_mes(fecha date);
       public       postgres    false    6    1            =           1255    561165    edad(date, date)    FUNCTION     �  CREATE FUNCTION public.edad(date, date DEFAULT NULL::date) RETURNS integer
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
 '   DROP FUNCTION public.edad(date, date);
       public       postgres    false    6    1            >           1255    561166     fecha_hasta_liquidacion(integer)    FUNCTION       CREATE FUNCTION public.fecha_hasta_liquidacion(id_liquidacion integer) RETURNS date
    LANGUAGE plpgsql
    AS $$
DECLARE 
	_fecha_hasta date;
BEGIN
	SELECT fecha_hasta INTO _fecha_hasta FROM liquidaciones WHERE id=id_liquidacion;
	return _fecha_hasta;
END;
$$;
 F   DROP FUNCTION public.fecha_hasta_liquidacion(id_liquidacion integer);
       public       postgres    false    6    1            C           1255    571335    fu_numero_letras(numeric)    FUNCTION     �  CREATE FUNCTION public.fu_numero_letras(numero numeric) RETURNS text
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
 7   DROP FUNCTION public.fu_numero_letras(numero numeric);
       public       postgres    false    6    1            �           0    0 )   FUNCTION fu_numero_letras(numero numeric)    COMMENT     t   COMMENT ON FUNCTION public.fu_numero_letras(numero numeric) IS 'Funcion para Convertir el Monto Numerico a Letras';
            public       postgres    false    323            F           1255    571336    numero_a_letras(numeric)    FUNCTION     m  CREATE FUNCTION public.numero_a_letras(numero numeric) RETURNS text
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
 6   DROP FUNCTION public.numero_a_letras(numero numeric);
       public       postgres    false    6    1            D           1255    571332    numero_a_letras_back(numeric)    FUNCTION     �  CREATE FUNCTION public.numero_a_letras_back(numero numeric) RETURNS text
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
 ;   DROP FUNCTION public.numero_a_letras_back(numero numeric);
       public       postgres    false    1    6            E           1255    570801 (   sp_grabar_historico_liquidacion(integer)    FUNCTION       CREATE FUNCTION public.sp_grabar_historico_liquidacion(_id_liquidacion integer) RETURNS void
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
 O   DROP FUNCTION public.sp_grabar_historico_liquidacion(_id_liquidacion integer);
       public       postgres    false    6    1            A           1255    562005 #   sp_trg_ai_liquidaciones_conceptos()    FUNCTION     �  CREATE FUNCTION public.sp_trg_ai_liquidaciones_conceptos() RETURNS trigger
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
 :   DROP FUNCTION public.sp_trg_ai_liquidaciones_conceptos();
       public       postgres    false    6    1            ?           1255    561167    sp_trg_ai_recibos()    FUNCTION     ~  CREATE FUNCTION public.sp_trg_ai_recibos() RETURNS trigger
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
 *   DROP FUNCTION public.sp_trg_ai_recibos();
       public       postgres    false    6    1            B           1255    570561    sp_trg_au_liquidaciones()    FUNCTION     �  CREATE FUNCTION public.sp_trg_au_liquidaciones() RETURNS trigger
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
 0   DROP FUNCTION public.sp_trg_au_liquidaciones();
       public       postgres    false    1    6            G           1255    587725 #   sp_volver_a_estado_inicial(integer)    FUNCTION     �  CREATE FUNCTION public.sp_volver_a_estado_inicial(_id_liquidacion integer) RETURNS void
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
 J   DROP FUNCTION public.sp_volver_a_estado_inicial(_id_liquidacion integer);
       public       postgres    false    6    1            @           1255    561168    total_vacaciones(integer, date)    FUNCTION     �  CREATE FUNCTION public.total_vacaciones(_id_persona integer, _fecha date DEFAULT now()) RETURNS integer
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
 I   DROP FUNCTION public.total_vacaciones(_id_persona integer, _fecha date);
       public       postgres    false    1    6            �            1259    561169    acumuladores    TABLE       CREATE TABLE public.acumuladores (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    descripcion text NOT NULL,
    id_tipo_concepto integer NOT NULL,
    remunerativo boolean DEFAULT false NOT NULL,
    valor_inicial numeric(10,2) DEFAULT 0 NOT NULL
);
     DROP TABLE public.acumuladores;
       public         postgres    false    6            �            1259    561177    acumuladores_id_seq    SEQUENCE     |   CREATE SEQUENCE public.acumuladores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE public.acumuladores_id_seq;
       public       postgres    false    6    182            �           0    0    acumuladores_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE public.acumuladores_id_seq OWNED BY public.acumuladores.id;
            public       postgres    false    183            )           1259    571665    back_sueldo_basico    TABLE     U   CREATE TABLE public.back_sueldo_basico (
    id integer,
    basico numeric(10,2)
);
 &   DROP TABLE public.back_sueldo_basico;
       public         postgres    false    6            �            1259    561179    bancos    TABLE     W   CREATE TABLE public.bancos (
    id integer NOT NULL,
    descripcion text NOT NULL
);
    DROP TABLE public.bancos;
       public         postgres    false    6            �            1259    561185    bancos_id_seq    SEQUENCE     v   CREATE SEQUENCE public.bancos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.bancos_id_seq;
       public       postgres    false    6    184            �           0    0    bancos_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.bancos_id_seq OWNED BY public.bancos.id;
            public       postgres    false    185            �            1259    561187 
   categorias    TABLE     �   CREATE TABLE public.categorias (
    id integer NOT NULL,
    descripcion text NOT NULL,
    sueldo_basico numeric(10,2),
    valor_hora numeric(10,2),
    codigo text NOT NULL
);
    DROP TABLE public.categorias;
       public         postgres    false    6            �            1259    561193    categorias_id_seq    SEQUENCE     z   CREATE SEQUENCE public.categorias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.categorias_id_seq;
       public       postgres    false    6    186            �           0    0    categorias_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.categorias_id_seq OWNED BY public.categorias.id;
            public       postgres    false    187            �            1259    561195 	   conceptos    TABLE     �  CREATE TABLE public.conceptos (
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
    DROP TABLE public.conceptos;
       public         postgres    false    6            �            1259    561206    conceptos_id_seq    SEQUENCE     y   CREATE SEQUENCE public.conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.conceptos_id_seq;
       public       postgres    false    6    188            �           0    0    conceptos_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.conceptos_id_seq OWNED BY public.conceptos.id;
            public       postgres    false    189            �            1259    561208    conceptos_personas    TABLE     �   CREATE TABLE public.conceptos_personas (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_persona integer NOT NULL,
    valor_fijo numeric(10,2)
);
 &   DROP TABLE public.conceptos_personas;
       public         postgres    false    6            �            1259    561211    datos_actuales    TABLE     ;  CREATE TABLE public.datos_actuales (
    id integer NOT NULL,
    domicilio text NOT NULL,
    id_localidad integer,
    telefono_particular character varying(30),
    telefono_celular character varying(30),
    email character varying(100),
    id_estado_civil integer NOT NULL,
    id_persona integer NOT NULL
);
 "   DROP TABLE public.datos_actuales;
       public         postgres    false    6            �            1259    561217    datos_actuales_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.datos_actuales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.datos_actuales_id_seq;
       public       postgres    false    191    6            �           0    0    datos_actuales_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.datos_actuales_id_seq OWNED BY public.datos_actuales.id;
            public       postgres    false    192            �            1259    561219    datos_laborales    TABLE     �  CREATE TABLE public.datos_laborales (
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
 #   DROP TABLE public.datos_laborales;
       public         postgres    false    6            �            1259    561222    datos_laborales_id_seq    SEQUENCE        CREATE SEQUENCE public.datos_laborales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.datos_laborales_id_seq;
       public       postgres    false    6    193            �           0    0    datos_laborales_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.datos_laborales_id_seq OWNED BY public.datos_laborales.id;
            public       postgres    false    194            �            1259    561224    datos_salud    TABLE     �   CREATE TABLE public.datos_salud (
    id integer NOT NULL,
    id_obra_social integer,
    observaciones_medicas character varying(255),
    id_persona integer NOT NULL
);
    DROP TABLE public.datos_salud;
       public         postgres    false    6            �            1259    561227    datos_salud_id_seq    SEQUENCE     {   CREATE SEQUENCE public.datos_salud_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.datos_salud_id_seq;
       public       postgres    false    195    6            �           0    0    datos_salud_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.datos_salud_id_seq OWNED BY public.datos_salud.id;
            public       postgres    false    196            �            1259    561229    establecimientos    TABLE     �   CREATE TABLE public.establecimientos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    direccion text NOT NULL,
    id_localidad integer NOT NULL,
    cuit text,
    actividad text,
    id_tipo_empleador integer
);
 $   DROP TABLE public.establecimientos;
       public         postgres    false    6            �            1259    561235    establecimientos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.establecimientos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.establecimientos_id_seq;
       public       postgres    false    197    6            �           0    0    establecimientos_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.establecimientos_id_seq OWNED BY public.establecimientos.id;
            public       postgres    false    198            �            1259    561237    estados_civiles    TABLE     `   CREATE TABLE public.estados_civiles (
    id integer NOT NULL,
    descripcion text NOT NULL
);
 #   DROP TABLE public.estados_civiles;
       public         postgres    false    6            �            1259    561243    estados_civiles_id_seq    SEQUENCE        CREATE SEQUENCE public.estados_civiles_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.estados_civiles_id_seq;
       public       postgres    false    6    199            �           0    0    estados_civiles_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.estados_civiles_id_seq OWNED BY public.estados_civiles.id;
            public       postgres    false    200            �            1259    561245    estados_liquidacion    TABLE     l   CREATE TABLE public.estados_liquidacion (
    id integer NOT NULL,
    descripcion character varying(60)
);
 '   DROP TABLE public.estados_liquidacion;
       public         postgres    false    6            �            1259    561248    estados_liquidacion_id_seq    SEQUENCE     �   CREATE SEQUENCE public.estados_liquidacion_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.estados_liquidacion_id_seq;
       public       postgres    false    6    201            �           0    0    estados_liquidacion_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.estados_liquidacion_id_seq OWNED BY public.estados_liquidacion.id;
            public       postgres    false    202            �            1259    561250    feriados    TABLE     �   CREATE TABLE public.feriados (
    id integer NOT NULL,
    fecha date NOT NULL,
    descripcion text NOT NULL,
    hora_desde time without time zone,
    hora_hasta time without time zone
);
    DROP TABLE public.feriados;
       public         postgres    false    6            �            1259    561256    feriados_id_seq    SEQUENCE     x   CREATE SEQUENCE public.feriados_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.feriados_id_seq;
       public       postgres    false    6    203            �           0    0    feriados_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.feriados_id_seq OWNED BY public.feriados.id;
            public       postgres    false    204            �            1259    561258    fichajes    TABLE       CREATE TABLE public.fichajes (
    id integer NOT NULL,
    fecha date NOT NULL,
    hora_entrada timestamp without time zone,
    hora_salida timestamp without time zone,
    horas_trabajadas numeric(10,2),
    horas_extras numeric(10,2),
    id_persona integer NOT NULL
);
    DROP TABLE public.fichajes;
       public         postgres    false    6            �            1259    561261    fichajes_id_seq    SEQUENCE     x   CREATE SEQUENCE public.fichajes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.fichajes_id_seq;
       public       postgres    false    205    6            �           0    0    fichajes_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.fichajes_id_seq OWNED BY public.fichajes.id;
            public       postgres    false    206            �            1259    561263    generos    TABLE     X   CREATE TABLE public.generos (
    id integer NOT NULL,
    descripcion text NOT NULL
);
    DROP TABLE public.generos;
       public         postgres    false    6            �            1259    561269    generos_id_seq    SEQUENCE     w   CREATE SEQUENCE public.generos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.generos_id_seq;
       public       postgres    false    207    6            �           0    0    generos_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.generos_id_seq OWNED BY public.generos.id;
            public       postgres    false    208            #           1259    570723    historico_liquidaciones    TABLE     �  CREATE TABLE public.historico_liquidaciones (
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
 +   DROP TABLE public.historico_liquidaciones;
       public         postgres    false    6            $           1259    570738 !   historico_liquidaciones_conceptos    TABLE       CREATE TABLE public.historico_liquidaciones_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_liquidacion integer NOT NULL,
    valor_fijo numeric(10,2),
    concepto text,
    codigo text,
    formula text,
    tipo_concepto text
);
 5   DROP TABLE public.historico_liquidaciones_conceptos;
       public         postgres    false    6            %           1259    570802    historico_recibos    TABLE     X  CREATE TABLE public.historico_recibos (
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
 %   DROP TABLE public.historico_recibos;
       public         postgres    false    6            &           1259    570817    historico_recibos_acumuladores    TABLE       CREATE TABLE public.historico_recibos_acumuladores (
    id integer NOT NULL,
    id_acumulador integer NOT NULL,
    importe numeric(10,2) NOT NULL,
    id_recibo integer NOT NULL,
    nombre text,
    descripcion text,
    id_tipo_concepto integer,
    tipo_concepto text
);
 2   DROP TABLE public.historico_recibos_acumuladores;
       public         postgres    false    6            '           1259    570832    historico_recibos_conceptos    TABLE     �  CREATE TABLE public.historico_recibos_conceptos (
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
 /   DROP TABLE public.historico_recibos_conceptos;
       public         postgres    false    6            +           1259    595919    historico_sueldo_basico    TABLE     �   CREATE TABLE public.historico_sueldo_basico (
    id integer NOT NULL,
    mes integer NOT NULL,
    anio integer NOT NULL,
    fecha timestamp without time zone DEFAULT now() NOT NULL,
    descripcion character varying(255)
);
 +   DROP TABLE public.historico_sueldo_basico;
       public         postgres    false    6            -           1259    595928    historico_sueldo_basico_detalle    TABLE     �   CREATE TABLE public.historico_sueldo_basico_detalle (
    id integer NOT NULL,
    id_persona integer NOT NULL,
    basico numeric(10,2) NOT NULL,
    id_cabecera integer NOT NULL
);
 3   DROP TABLE public.historico_sueldo_basico_detalle;
       public         postgres    false    6            ,           1259    595926 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE public.historico_sueldo_basico_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 =   DROP SEQUENCE public.historico_sueldo_basico_detalle_id_seq;
       public       postgres    false    301    6            �           0    0 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE public.historico_sueldo_basico_detalle_id_seq OWNED BY public.historico_sueldo_basico_detalle.id;
            public       postgres    false    300            *           1259    595917    historico_sueldo_basico_id_seq    SEQUENCE     �   CREATE SEQUENCE public.historico_sueldo_basico_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.historico_sueldo_basico_id_seq;
       public       postgres    false    299    6            �           0    0    historico_sueldo_basico_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.historico_sueldo_basico_id_seq OWNED BY public.historico_sueldo_basico.id;
            public       postgres    false    298            �            1259    561271    liquidaciones    TABLE     c  CREATE TABLE public.liquidaciones (
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
 !   DROP TABLE public.liquidaciones;
       public         postgres    false    6            �            1259    561279    liquidaciones_conceptos    TABLE     �   CREATE TABLE public.liquidaciones_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_liquidacion integer NOT NULL,
    valor_fijo numeric(10,2)
);
 +   DROP TABLE public.liquidaciones_conceptos;
       public         postgres    false    6            �            1259    561282    liquidaciones_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.liquidaciones_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.liquidaciones_conceptos_id_seq;
       public       postgres    false    6    210            �           0    0    liquidaciones_conceptos_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.liquidaciones_conceptos_id_seq OWNED BY public.liquidaciones_conceptos.id;
            public       postgres    false    211            �            1259    561284    liquidaciones_id_seq    SEQUENCE     }   CREATE SEQUENCE public.liquidaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.liquidaciones_id_seq;
       public       postgres    false    209    6            �           0    0    liquidaciones_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.liquidaciones_id_seq OWNED BY public.liquidaciones.id;
            public       postgres    false    212            �            1259    561286    localidades    TABLE     �   CREATE TABLE public.localidades (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    cp integer NOT NULL,
    id_provincia integer NOT NULL
);
    DROP TABLE public.localidades;
       public         postgres    false    6            �            1259    561289    localidades_id_seq    SEQUENCE     {   CREATE SEQUENCE public.localidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE public.localidades_id_seq;
       public       postgres    false    213    6            �           0    0    localidades_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE public.localidades_id_seq OWNED BY public.localidades.id;
            public       postgres    false    214            �            1259    561291    nacionalidades    TABLE     _   CREATE TABLE public.nacionalidades (
    id integer NOT NULL,
    descripcion text NOT NULL
);
 "   DROP TABLE public.nacionalidades;
       public         postgres    false    6            �            1259    561297    nacionalidades_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.nacionalidades_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.nacionalidades_id_seq;
       public       postgres    false    215    6            �           0    0    nacionalidades_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.nacionalidades_id_seq OWNED BY public.nacionalidades.id;
            public       postgres    false    216            �            1259    561299    obras_sociales    TABLE     y   CREATE TABLE public.obras_sociales (
    id integer NOT NULL,
    codigo text NOT NULL,
    descripcion text NOT NULL
);
 "   DROP TABLE public.obras_sociales;
       public         postgres    false    6            �            1259    561305    obras_sociales_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.obras_sociales_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.obras_sociales_id_seq;
       public       postgres    false    217    6            �           0    0    obras_sociales_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.obras_sociales_id_seq OWNED BY public.obras_sociales.id;
            public       postgres    false    218            �            1259    561307    paises    TABLE     �   CREATE TABLE public.paises (
    id integer NOT NULL,
    nombre character varying(60) NOT NULL,
    nacionalidad character varying(60) NOT NULL
);
    DROP TABLE public.paises;
       public         postgres    false    6            �            1259    561310    paises_id_seq    SEQUENCE     v   CREATE SEQUENCE public.paises_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.paises_id_seq;
       public       postgres    false    6    219            �           0    0    paises_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.paises_id_seq OWNED BY public.paises.id;
            public       postgres    false    220            �            1259    561312    periodos    TABLE     �   CREATE TABLE public.periodos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date NOT NULL,
    observaciones text
);
    DROP TABLE public.periodos;
       public         postgres    false    6            �            1259    561318    periodos_detalle    TABLE     [  CREATE TABLE public.periodos_detalle (
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
 $   DROP TABLE public.periodos_detalle;
       public         postgres    false    6            �           0    0 (   COLUMN periodos_detalle.horas_extras_100    COMMENT     V   COMMENT ON COLUMN public.periodos_detalle.horas_extras_100 IS 'Horas extras al 100%';
            public       postgres    false    222            �            1259    561322    periodos_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE public.periodos_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.periodos_detalle_id_seq;
       public       postgres    false    6    222            �           0    0    periodos_detalle_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.periodos_detalle_id_seq OWNED BY public.periodos_detalle.id;
            public       postgres    false    223            �            1259    561324    periodos_id_seq    SEQUENCE     x   CREATE SEQUENCE public.periodos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.periodos_id_seq;
       public       postgres    false    6    221            �           0    0    periodos_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.periodos_id_seq OWNED BY public.periodos.id;
            public       postgres    false    224            �            1259    561326    persona_tareas    TABLE     �   CREATE TABLE public.persona_tareas (
    id integer NOT NULL,
    id_persona integer NOT NULL,
    id_tarea integer NOT NULL
);
 "   DROP TABLE public.persona_tareas;
       public         postgres    false    6            �            1259    561329    persona_tareas_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.persona_tareas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.persona_tareas_id_seq;
       public       postgres    false    6    225            �           0    0    persona_tareas_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.persona_tareas_id_seq OWNED BY public.persona_tareas.id;
            public       postgres    false    226            �            1259    561331    personas    TABLE     �  CREATE TABLE public.personas (
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
    DROP TABLE public.personas;
       public         postgres    false    6            �            1259    561339    personas_conceptos    TABLE     �   CREATE TABLE public.personas_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    valor_fijo numeric(10,2),
    id_persona integer NOT NULL
);
 &   DROP TABLE public.personas_conceptos;
       public         postgres    false    6            �            1259    561342    personas_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.personas_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE public.personas_conceptos_id_seq;
       public       postgres    false    6    228            �           0    0    personas_conceptos_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE public.personas_conceptos_id_seq OWNED BY public.personas_conceptos.id;
            public       postgres    false    229            �            1259    561344    personas_id_seq    SEQUENCE     x   CREATE SEQUENCE public.personas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 &   DROP SEQUENCE public.personas_id_seq;
       public       postgres    false    227    6            �           0    0    personas_id_seq    SEQUENCE OWNED BY     C   ALTER SEQUENCE public.personas_id_seq OWNED BY public.personas.id;
            public       postgres    false    230            �            1259    561346    personas_jornadas    TABLE     �   CREATE TABLE public.personas_jornadas (
    id integer NOT NULL,
    hora_desde time without time zone NOT NULL,
    hora_hasta time without time zone NOT NULL,
    id_persona integer NOT NULL
);
 %   DROP TABLE public.personas_jornadas;
       public         postgres    false    6            �            1259    561349    personas_jornadas_id_seq    SEQUENCE     �   CREATE SEQUENCE public.personas_jornadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.personas_jornadas_id_seq;
       public       postgres    false    6    231            �           0    0    personas_jornadas_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.personas_jornadas_id_seq OWNED BY public.personas_jornadas.id;
            public       postgres    false    232            �            1259    561351 
   provincias    TABLE     �   CREATE TABLE public.provincias (
    id integer NOT NULL,
    nombre character varying NOT NULL,
    id_pais integer NOT NULL
);
    DROP TABLE public.provincias;
       public         postgres    false    6            �            1259    561357    provincias_id_seq    SEQUENCE     z   CREATE SEQUENCE public.provincias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.provincias_id_seq;
       public       postgres    false    233    6            �           0    0    provincias_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.provincias_id_seq OWNED BY public.provincias.id;
            public       postgres    false    234            �            1259    561359    recibos    TABLE     q  CREATE TABLE public.recibos (
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
    DROP TABLE public.recibos;
       public         postgres    false    6            �            1259    561362    recibos_acumuladores    TABLE     �   CREATE TABLE public.recibos_acumuladores (
    id integer NOT NULL,
    id_acumulador integer NOT NULL,
    importe numeric(10,2) NOT NULL,
    id_recibo integer NOT NULL
);
 (   DROP TABLE public.recibos_acumuladores;
       public         postgres    false    6            �            1259    561365    recibos_acumuladores_id_seq    SEQUENCE     �   CREATE SEQUENCE public.recibos_acumuladores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE public.recibos_acumuladores_id_seq;
       public       postgres    false    6    236            �           0    0    recibos_acumuladores_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE public.recibos_acumuladores_id_seq OWNED BY public.recibos_acumuladores.id;
            public       postgres    false    237            �            1259    561367    recibos_conceptos    TABLE     �   CREATE TABLE public.recibos_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    importe numeric(10,2),
    id_recibo integer NOT NULL,
    importe_fijo numeric(10,2)
);
 %   DROP TABLE public.recibos_conceptos;
       public         postgres    false    6            �            1259    561370    recibos_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.recibos_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.recibos_conceptos_id_seq;
       public       postgres    false    238    6            �           0    0    recibos_conceptos_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.recibos_conceptos_id_seq OWNED BY public.recibos_conceptos.id;
            public       postgres    false    239            �            1259    561372    recibos_id_seq    SEQUENCE     w   CREATE SEQUENCE public.recibos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 %   DROP SEQUENCE public.recibos_id_seq;
       public       postgres    false    235    6            �           0    0    recibos_id_seq    SEQUENCE OWNED BY     A   ALTER SEQUENCE public.recibos_id_seq OWNED BY public.recibos.id;
            public       postgres    false    240            �            1259    561374 	   regimenes    TABLE     Z   CREATE TABLE public.regimenes (
    id integer NOT NULL,
    descripcion text NOT NULL
);
    DROP TABLE public.regimenes;
       public         postgres    false    6            �            1259    561380    regimenes_id_seq    SEQUENCE     y   CREATE SEQUENCE public.regimenes_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE public.regimenes_id_seq;
       public       postgres    false    241    6            �           0    0    regimenes_id_seq    SEQUENCE OWNED BY     E   ALTER SEQUENCE public.regimenes_id_seq OWNED BY public.regimenes.id;
            public       postgres    false    242                       1259    561956    tabla    TABLE     �   CREATE TABLE public.tabla (
    id integer NOT NULL,
    clave character varying(60) NOT NULL,
    descripcion text NOT NULL
);
    DROP TABLE public.tabla;
       public         postgres    false    6                       1259    561967    tabla_detalle    TABLE     �   CREATE TABLE public.tabla_detalle (
    id integer NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    valor numeric(10,2) NOT NULL,
    tope numeric(10,2) NOT NULL,
    id_tabla integer NOT NULL
);
 !   DROP TABLE public.tabla_detalle;
       public         postgres    false    6                       1259    561965    tabla_detalle_id_seq    SEQUENCE     }   CREATE SEQUENCE public.tabla_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.tabla_detalle_id_seq;
       public       postgres    false    284    6            �           0    0    tabla_detalle_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.tabla_detalle_id_seq OWNED BY public.tabla_detalle.id;
            public       postgres    false    283            �            1259    561391    tabla_ganancias    TABLE     {   CREATE TABLE public.tabla_ganancias (
    id integer NOT NULL,
    anio integer NOT NULL,
    descripcion text NOT NULL
);
 #   DROP TABLE public.tabla_ganancias;
       public         postgres    false    6            �            1259    561397    tabla_ganancias_detalle    TABLE     .  CREATE TABLE public.tabla_ganancias_detalle (
    id integer NOT NULL,
    mes integer NOT NULL,
    desde numeric(10,2) NOT NULL,
    hasta numeric(10,2),
    fijo numeric(10,2) NOT NULL,
    porcentaje numeric(10,2) NOT NULL,
    excedente numeric(10,2) NOT NULL,
    id_cabecera integer NOT NULL
);
 +   DROP TABLE public.tabla_ganancias_detalle;
       public         postgres    false    6            �            1259    561400    tabla_ganancias_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tabla_ganancias_detalle_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.tabla_ganancias_detalle_id_seq;
       public       postgres    false    244    6            �           0    0    tabla_ganancias_detalle_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.tabla_ganancias_detalle_id_seq OWNED BY public.tabla_ganancias_detalle.id;
            public       postgres    false    245            �            1259    561402    tabla_ganancias_id_seq    SEQUENCE        CREATE SEQUENCE public.tabla_ganancias_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.tabla_ganancias_id_seq;
       public       postgres    false    243    6            �           0    0    tabla_ganancias_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.tabla_ganancias_id_seq OWNED BY public.tabla_ganancias.id;
            public       postgres    false    246                       1259    561954    tabla_id_seq    SEQUENCE     u   CREATE SEQUENCE public.tabla_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 #   DROP SEQUENCE public.tabla_id_seq;
       public       postgres    false    6    282            �           0    0    tabla_id_seq    SEQUENCE OWNED BY     =   ALTER SEQUENCE public.tabla_id_seq OWNED BY public.tabla.id;
            public       postgres    false    281                       1259    561980    tabla_personas    TABLE     �   CREATE TABLE public.tabla_personas (
    id integer NOT NULL,
    anio integer NOT NULL,
    mes integer NOT NULL,
    periodo date NOT NULL,
    valor numeric(10,2) NOT NULL,
    id_persona integer NOT NULL,
    id_tabla integer NOT NULL
);
 "   DROP TABLE public.tabla_personas;
       public         postgres    false    6                       1259    561978    tabla_personas_id_seq    SEQUENCE     ~   CREATE SEQUENCE public.tabla_personas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE public.tabla_personas_id_seq;
       public       postgres    false    6    286            �           0    0    tabla_personas_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE public.tabla_personas_id_seq OWNED BY public.tabla_personas.id;
            public       postgres    false    285            �            1259    561407    tabla_vacaciones    TABLE     �   CREATE TABLE public.tabla_vacaciones (
    id integer NOT NULL,
    desde numeric(10,2) NOT NULL,
    hasta numeric(10,2) NOT NULL,
    dias integer NOT NULL
);
 $   DROP TABLE public.tabla_vacaciones;
       public         postgres    false    6            �            1259    561410    tabla_vacaciones_dias    TABLE     �   CREATE TABLE public.tabla_vacaciones_dias (
    id integer NOT NULL,
    desde integer NOT NULL,
    hasta integer NOT NULL,
    dias integer NOT NULL,
    descripcion text
);
 )   DROP TABLE public.tabla_vacaciones_dias;
       public         postgres    false    6            �            1259    561416    tareas    TABLE     W   CREATE TABLE public.tareas (
    id integer NOT NULL,
    descripcion text NOT NULL
);
    DROP TABLE public.tareas;
       public         postgres    false    6            �            1259    561422    tareas_id_seq    SEQUENCE     v   CREATE SEQUENCE public.tareas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 $   DROP SEQUENCE public.tareas_id_seq;
       public       postgres    false    6    249            �           0    0    tareas_id_seq    SEQUENCE OWNED BY     ?   ALTER SEQUENCE public.tareas_id_seq OWNED BY public.tareas.id;
            public       postgres    false    250            �            1259    561424    tipo_liquidacion_conceptos    TABLE     �   CREATE TABLE public.tipo_liquidacion_conceptos (
    id integer NOT NULL,
    id_concepto integer NOT NULL,
    id_tipo_liquidacion integer NOT NULL
);
 .   DROP TABLE public.tipo_liquidacion_conceptos;
       public         postgres    false    6            �            1259    561427 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tipo_liquidacion_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 8   DROP SEQUENCE public.tipo_liquidacion_conceptos_id_seq;
       public       postgres    false    251    6            �           0    0 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE OWNED BY     g   ALTER SEQUENCE public.tipo_liquidacion_conceptos_id_seq OWNED BY public.tipo_liquidacion_conceptos.id;
            public       postgres    false    252            �            1259    561429    tipos_conceptos    TABLE     �   CREATE TABLE public.tipos_conceptos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    desde integer,
    hasta integer
);
 #   DROP TABLE public.tipos_conceptos;
       public         postgres    false    6            �            1259    561435    tipos_conceptos_id_seq    SEQUENCE        CREATE SEQUENCE public.tipos_conceptos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.tipos_conceptos_id_seq;
       public       postgres    false    253    6            �           0    0    tipos_conceptos_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.tipos_conceptos_id_seq OWNED BY public.tipos_conceptos.id;
            public       postgres    false    254            �            1259    561437    tipos_contratos    TABLE     }   CREATE TABLE public.tipos_contratos (
    id integer NOT NULL,
    descripcion text NOT NULL,
    horas_mes numeric(10,2)
);
 #   DROP TABLE public.tipos_contratos;
       public         postgres    false    6                        1259    561443    tipos_contratos_id_seq    SEQUENCE        CREATE SEQUENCE public.tipos_contratos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.tipos_contratos_id_seq;
       public       postgres    false    6    255            �           0    0    tipos_contratos_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.tipos_contratos_id_seq OWNED BY public.tipos_contratos.id;
            public       postgres    false    256                       1259    561445    tipos_documentos    TABLE     a   CREATE TABLE public.tipos_documentos (
    id integer NOT NULL,
    descripcion text NOT NULL
);
 $   DROP TABLE public.tipos_documentos;
       public         postgres    false    6                       1259    561451    tipos_documentos_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tipos_documentos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE public.tipos_documentos_id_seq;
       public       postgres    false    257    6            �           0    0    tipos_documentos_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE public.tipos_documentos_id_seq OWNED BY public.tipos_documentos.id;
            public       postgres    false    258                       1259    561453    tipos_empleadores    TABLE     b   CREATE TABLE public.tipos_empleadores (
    id integer NOT NULL,
    descripcion text NOT NULL
);
 %   DROP TABLE public.tipos_empleadores;
       public         postgres    false    6                       1259    561459    tipos_empleadores_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tipos_empleadores_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.tipos_empleadores_id_seq;
       public       postgres    false    259    6            �           0    0    tipos_empleadores_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.tipos_empleadores_id_seq OWNED BY public.tipos_empleadores.id;
            public       postgres    false    260                       1259    561461    tipos_liquidaciones    TABLE     �   CREATE TABLE public.tipos_liquidaciones (
    id integer NOT NULL,
    descripcion text NOT NULL,
    activo boolean DEFAULT true NOT NULL
);
 '   DROP TABLE public.tipos_liquidaciones;
       public         postgres    false    6                       1259    561468    tipos_liquidaciones_id_seq    SEQUENCE     �   CREATE SEQUENCE public.tipos_liquidaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE public.tipos_liquidaciones_id_seq;
       public       postgres    false    261    6            �           0    0    tipos_liquidaciones_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE public.tipos_liquidaciones_id_seq OWNED BY public.tipos_liquidaciones.id;
            public       postgres    false    262                       1259    561470    v_acumuladores    VIEW     %  CREATE VIEW public.v_acumuladores AS
 SELECT a.id,
    a.nombre,
    a.descripcion,
    a.id_tipo_concepto,
    a.remunerativo,
    a.valor_inicial,
    tc.descripcion AS tipo_concepto
   FROM (public.acumuladores a
     LEFT JOIN public.tipos_conceptos tc ON ((a.id_tipo_concepto = tc.id)));
 !   DROP VIEW public.v_acumuladores;
       public       postgres    false    253    253    182    182    182    182    182    182    6                       1259    561474    v_conceptos    VIEW     �  CREATE VIEW public.v_conceptos AS
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
    DROP VIEW public.v_conceptos;
       public       postgres    false    188    188    188    188    253    188    188    253    188    188    188    188    188    188    6            	           1259    561479    v_localidades    VIEW     /  CREATE VIEW public.v_localidades AS
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
     DROP VIEW public.v_localidades;
       public       postgres    false    233    219    233    233    219    213    213    213    213    6            
           1259    561483    v_establecimientos    VIEW     �  CREATE VIEW public.v_establecimientos AS
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
 %   DROP VIEW public.v_establecimientos;
       public       postgres    false    265    265    265    197    197    197    197    197    197    197    259    259    265    265    265    6                       1259    561487    v_liquidaciones    VIEW     �  CREATE VIEW public.v_liquidaciones AS
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
 "   DROP VIEW public.v_liquidaciones;
       public       postgres    false    184    209    209    209    261    261    209    209    184    266    266    266    266    201    209    266    266    266    266    209    209    209    266    266    201    209    209    209    209    209    209    209    209    209    6            (           1259    571346    v_periodos_detalle    VIEW     �  CREATE VIEW public.v_periodos_detalle AS
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
 %   DROP VIEW public.v_periodos_detalle;
       public       postgres    false    222    221    221    221    221    221    221    221    222    222    222    222    222    222    222    222    6                       1259    561496 
   v_personas    VIEW     *  CREATE VIEW public.v_personas AS
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
    DROP VIEW public.v_personas;
       public       postgres    false    186    186    186    186    197    197    199    199    207    207    215    215    217    217    217    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    227    241    241    255    255    257    257    265    265    265    265    265    6                       1259    561501 	   v_recibos    VIEW     �  CREATE VIEW public.v_recibos AS
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
    DROP VIEW public.v_recibos;
       public       postgres    false    209    268    268    268    268    268    235    235    235    268    235    209    235    235    235    235    235    209    268    268    268    268    6                       1259    561506    v_recibos_conceptos    VIEW     �  CREATE VIEW public.v_recibos_conceptos AS
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
 &   DROP VIEW public.v_recibos_conceptos;
       public       postgres    false    209    235    209    209    209    188    188    188    188    188    188    188    209    235    238    238    238    238    235    235    6            "           1259    562322    v_recibos_conceptos_detallado    VIEW     j  CREATE VIEW public.v_recibos_conceptos_detallado AS
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
 0   DROP VIEW public.v_recibos_conceptos_detallado;
       public       postgres    false    270    270    270    270    270    270    270    270    270    270    270    270    270    270    270    270    270    270    268    268    268    268    268    268    268    268    268    268    268    268    268    268    268    268    253    253    6                       1259    561996    v_tabla_detalle    VIEW       CREATE VIEW public.v_tabla_detalle AS
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
 "   DROP VIEW public.v_tabla_detalle;
       public       postgres    false    284    284    284    284    282    282    282    284    284    284    6            !           1259    562246    v_tabla_ganancias_detalle    VIEW     x  CREATE VIEW public.v_tabla_ganancias_detalle AS
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
 ,   DROP VIEW public.v_tabla_ganancias_detalle;
       public       postgres    false    244    244    244    244    244    244    244    244    243    243    243    6                        1259    562000    v_tabla_personas    VIEW     T  CREATE VIEW public.v_tabla_personas AS
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
 #   DROP VIEW public.v_tabla_personas;
       public       postgres    false    286    227    227    227    227    227    227    282    282    282    286    286    286    286    286    286    6                       1259    561520    v_tipo_liquidacion_conceptos    VIEW     J  CREATE VIEW public.v_tipo_liquidacion_conceptos AS
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
 /   DROP VIEW public.v_tipo_liquidacion_conceptos;
       public       postgres    false    261    261    253    253    251    251    188    188    188    188    188    251    6                       1259    561525 
   vacaciones    TABLE     �   CREATE TABLE public.vacaciones (
    id integer NOT NULL,
    fecha_desde date NOT NULL,
    fecha_hasta date NOT NULL,
    observaciones text,
    id_persona integer NOT NULL
);
    DROP TABLE public.vacaciones;
       public         postgres    false    6                       1259    561531    vacaciones_id_seq    SEQUENCE     z   CREATE SEQUENCE public.vacaciones_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE public.vacaciones_id_seq;
       public       postgres    false    6    272            �           0    0    vacaciones_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE public.vacaciones_id_seq OWNED BY public.vacaciones.id;
            public       postgres    false    273                       1259    561533 
   reservadas    TABLE       CREATE TABLE sistema.reservadas (
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
    DROP TABLE sistema.reservadas;
       sistema         postgres    false    8                       1259    561539    reservadas_id_seq    SEQUENCE     {   CREATE SEQUENCE sistema.reservadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE sistema.reservadas_id_seq;
       sistema       postgres    false    8    274            �           0    0    reservadas_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE sistema.reservadas_id_seq OWNED BY sistema.reservadas.id;
            sistema       postgres    false    275                       1259    561541    tipos_datos    TABLE     ]   CREATE TABLE sistema.tipos_datos (
    id integer NOT NULL,
    descripcion text NOT NULL
);
     DROP TABLE sistema.tipos_datos;
       sistema         postgres    false    8                       1259    561547    tipos_datos_id_seq    SEQUENCE     |   CREATE SEQUENCE sistema.tipos_datos_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE sistema.tipos_datos_id_seq;
       sistema       postgres    false    8    276            �           0    0    tipos_datos_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE sistema.tipos_datos_id_seq OWNED BY sistema.tipos_datos.id;
            sistema       postgres    false    277                       1259    561549    tipos_reservadas    TABLE     b   CREATE TABLE sistema.tipos_reservadas (
    id integer NOT NULL,
    descripcion text NOT NULL
);
 %   DROP TABLE sistema.tipos_reservadas;
       sistema         postgres    false    8                       1259    561555    tipos_reservadas_id_seq    SEQUENCE     �   CREATE SEQUENCE sistema.tipos_reservadas_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE sistema.tipos_reservadas_id_seq;
       sistema       postgres    false    278    8            �           0    0    tipos_reservadas_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE sistema.tipos_reservadas_id_seq OWNED BY sistema.tipos_reservadas.id;
            sistema       postgres    false    279                       1259    561557    v_reservadas    VIEW     �  CREATE VIEW sistema.v_reservadas AS
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
     DROP VIEW sistema.v_reservadas;
       sistema       postgres    false    274    278    278    276    276    274    274    274    274    274    274    274    274    8            �	           2604    561561    id    DEFAULT     r   ALTER TABLE ONLY public.acumuladores ALTER COLUMN id SET DEFAULT nextval('public.acumuladores_id_seq'::regclass);
 >   ALTER TABLE public.acumuladores ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    183    182            �	           2604    561562    id    DEFAULT     f   ALTER TABLE ONLY public.bancos ALTER COLUMN id SET DEFAULT nextval('public.bancos_id_seq'::regclass);
 8   ALTER TABLE public.bancos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    185    184            �	           2604    561563    id    DEFAULT     n   ALTER TABLE ONLY public.categorias ALTER COLUMN id SET DEFAULT nextval('public.categorias_id_seq'::regclass);
 <   ALTER TABLE public.categorias ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    187    186            �	           2604    561564    id    DEFAULT     l   ALTER TABLE ONLY public.conceptos ALTER COLUMN id SET DEFAULT nextval('public.conceptos_id_seq'::regclass);
 ;   ALTER TABLE public.conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    189    188            �	           2604    561565    id    DEFAULT     v   ALTER TABLE ONLY public.datos_actuales ALTER COLUMN id SET DEFAULT nextval('public.datos_actuales_id_seq'::regclass);
 @   ALTER TABLE public.datos_actuales ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    192    191            �	           2604    561566    id    DEFAULT     x   ALTER TABLE ONLY public.datos_laborales ALTER COLUMN id SET DEFAULT nextval('public.datos_laborales_id_seq'::regclass);
 A   ALTER TABLE public.datos_laborales ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    194    193            �	           2604    561567    id    DEFAULT     p   ALTER TABLE ONLY public.datos_salud ALTER COLUMN id SET DEFAULT nextval('public.datos_salud_id_seq'::regclass);
 =   ALTER TABLE public.datos_salud ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    196    195            �	           2604    561568    id    DEFAULT     z   ALTER TABLE ONLY public.establecimientos ALTER COLUMN id SET DEFAULT nextval('public.establecimientos_id_seq'::regclass);
 B   ALTER TABLE public.establecimientos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    198    197            �	           2604    561569    id    DEFAULT     x   ALTER TABLE ONLY public.estados_civiles ALTER COLUMN id SET DEFAULT nextval('public.estados_civiles_id_seq'::regclass);
 A   ALTER TABLE public.estados_civiles ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    200    199            �	           2604    561570    id    DEFAULT     �   ALTER TABLE ONLY public.estados_liquidacion ALTER COLUMN id SET DEFAULT nextval('public.estados_liquidacion_id_seq'::regclass);
 E   ALTER TABLE public.estados_liquidacion ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    202    201            �	           2604    561571    id    DEFAULT     j   ALTER TABLE ONLY public.feriados ALTER COLUMN id SET DEFAULT nextval('public.feriados_id_seq'::regclass);
 :   ALTER TABLE public.feriados ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    204    203            �	           2604    561572    id    DEFAULT     j   ALTER TABLE ONLY public.fichajes ALTER COLUMN id SET DEFAULT nextval('public.fichajes_id_seq'::regclass);
 :   ALTER TABLE public.fichajes ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    206    205            �	           2604    561573    id    DEFAULT     h   ALTER TABLE ONLY public.generos ALTER COLUMN id SET DEFAULT nextval('public.generos_id_seq'::regclass);
 9   ALTER TABLE public.generos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    208    207            �	           2604    595922    id    DEFAULT     �   ALTER TABLE ONLY public.historico_sueldo_basico ALTER COLUMN id SET DEFAULT nextval('public.historico_sueldo_basico_id_seq'::regclass);
 I   ALTER TABLE public.historico_sueldo_basico ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    299    298    299            �	           2604    595931    id    DEFAULT     �   ALTER TABLE ONLY public.historico_sueldo_basico_detalle ALTER COLUMN id SET DEFAULT nextval('public.historico_sueldo_basico_detalle_id_seq'::regclass);
 Q   ALTER TABLE public.historico_sueldo_basico_detalle ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    301    300    301            �	           2604    561574    id    DEFAULT     t   ALTER TABLE ONLY public.liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_id_seq'::regclass);
 ?   ALTER TABLE public.liquidaciones ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    212    209            �	           2604    561575    id    DEFAULT     �   ALTER TABLE ONLY public.liquidaciones_conceptos ALTER COLUMN id SET DEFAULT nextval('public.liquidaciones_conceptos_id_seq'::regclass);
 I   ALTER TABLE public.liquidaciones_conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    211    210            �	           2604    561576    id    DEFAULT     p   ALTER TABLE ONLY public.localidades ALTER COLUMN id SET DEFAULT nextval('public.localidades_id_seq'::regclass);
 =   ALTER TABLE public.localidades ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    214    213            �	           2604    561577    id    DEFAULT     v   ALTER TABLE ONLY public.nacionalidades ALTER COLUMN id SET DEFAULT nextval('public.nacionalidades_id_seq'::regclass);
 @   ALTER TABLE public.nacionalidades ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    216    215            �	           2604    561578    id    DEFAULT     v   ALTER TABLE ONLY public.obras_sociales ALTER COLUMN id SET DEFAULT nextval('public.obras_sociales_id_seq'::regclass);
 @   ALTER TABLE public.obras_sociales ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    218    217            �	           2604    561579    id    DEFAULT     f   ALTER TABLE ONLY public.paises ALTER COLUMN id SET DEFAULT nextval('public.paises_id_seq'::regclass);
 8   ALTER TABLE public.paises ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    220    219            �	           2604    561580    id    DEFAULT     j   ALTER TABLE ONLY public.periodos ALTER COLUMN id SET DEFAULT nextval('public.periodos_id_seq'::regclass);
 :   ALTER TABLE public.periodos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    224    221            �	           2604    561581    id    DEFAULT     z   ALTER TABLE ONLY public.periodos_detalle ALTER COLUMN id SET DEFAULT nextval('public.periodos_detalle_id_seq'::regclass);
 B   ALTER TABLE public.periodos_detalle ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    223    222            �	           2604    561582    id    DEFAULT     v   ALTER TABLE ONLY public.persona_tareas ALTER COLUMN id SET DEFAULT nextval('public.persona_tareas_id_seq'::regclass);
 @   ALTER TABLE public.persona_tareas ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    226    225            �	           2604    561583    id    DEFAULT     j   ALTER TABLE ONLY public.personas ALTER COLUMN id SET DEFAULT nextval('public.personas_id_seq'::regclass);
 :   ALTER TABLE public.personas ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    230    227            �	           2604    561584    id    DEFAULT     ~   ALTER TABLE ONLY public.personas_conceptos ALTER COLUMN id SET DEFAULT nextval('public.personas_conceptos_id_seq'::regclass);
 D   ALTER TABLE public.personas_conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    229    228            �	           2604    561585    id    DEFAULT     |   ALTER TABLE ONLY public.personas_jornadas ALTER COLUMN id SET DEFAULT nextval('public.personas_jornadas_id_seq'::regclass);
 C   ALTER TABLE public.personas_jornadas ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    232    231            �	           2604    561586    id    DEFAULT     n   ALTER TABLE ONLY public.provincias ALTER COLUMN id SET DEFAULT nextval('public.provincias_id_seq'::regclass);
 <   ALTER TABLE public.provincias ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    234    233            �	           2604    561587    id    DEFAULT     h   ALTER TABLE ONLY public.recibos ALTER COLUMN id SET DEFAULT nextval('public.recibos_id_seq'::regclass);
 9   ALTER TABLE public.recibos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    240    235            �	           2604    561588    id    DEFAULT     �   ALTER TABLE ONLY public.recibos_acumuladores ALTER COLUMN id SET DEFAULT nextval('public.recibos_acumuladores_id_seq'::regclass);
 F   ALTER TABLE public.recibos_acumuladores ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    237    236            �	           2604    561589    id    DEFAULT     |   ALTER TABLE ONLY public.recibos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.recibos_conceptos_id_seq'::regclass);
 C   ALTER TABLE public.recibos_conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    239    238            �	           2604    561590    id    DEFAULT     l   ALTER TABLE ONLY public.regimenes ALTER COLUMN id SET DEFAULT nextval('public.regimenes_id_seq'::regclass);
 ;   ALTER TABLE public.regimenes ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    242    241            �	           2604    561959    id    DEFAULT     d   ALTER TABLE ONLY public.tabla ALTER COLUMN id SET DEFAULT nextval('public.tabla_id_seq'::regclass);
 7   ALTER TABLE public.tabla ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    281    282    282            �	           2604    561970    id    DEFAULT     t   ALTER TABLE ONLY public.tabla_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_detalle_id_seq'::regclass);
 ?   ALTER TABLE public.tabla_detalle ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    283    284    284            �	           2604    561591    id    DEFAULT     x   ALTER TABLE ONLY public.tabla_ganancias ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_id_seq'::regclass);
 A   ALTER TABLE public.tabla_ganancias ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    246    243            �	           2604    561592    id    DEFAULT     �   ALTER TABLE ONLY public.tabla_ganancias_detalle ALTER COLUMN id SET DEFAULT nextval('public.tabla_ganancias_detalle_id_seq'::regclass);
 I   ALTER TABLE public.tabla_ganancias_detalle ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    245    244            �	           2604    561983    id    DEFAULT     v   ALTER TABLE ONLY public.tabla_personas ALTER COLUMN id SET DEFAULT nextval('public.tabla_personas_id_seq'::regclass);
 @   ALTER TABLE public.tabla_personas ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    285    286    286            �	           2604    561593    id    DEFAULT     f   ALTER TABLE ONLY public.tareas ALTER COLUMN id SET DEFAULT nextval('public.tareas_id_seq'::regclass);
 8   ALTER TABLE public.tareas ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    250    249            �	           2604    561594    id    DEFAULT     �   ALTER TABLE ONLY public.tipo_liquidacion_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipo_liquidacion_conceptos_id_seq'::regclass);
 L   ALTER TABLE public.tipo_liquidacion_conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    252    251            �	           2604    561595    id    DEFAULT     x   ALTER TABLE ONLY public.tipos_conceptos ALTER COLUMN id SET DEFAULT nextval('public.tipos_conceptos_id_seq'::regclass);
 A   ALTER TABLE public.tipos_conceptos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    254    253            �	           2604    561596    id    DEFAULT     x   ALTER TABLE ONLY public.tipos_contratos ALTER COLUMN id SET DEFAULT nextval('public.tipos_contratos_id_seq'::regclass);
 A   ALTER TABLE public.tipos_contratos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    256    255            �	           2604    561597    id    DEFAULT     z   ALTER TABLE ONLY public.tipos_documentos ALTER COLUMN id SET DEFAULT nextval('public.tipos_documentos_id_seq'::regclass);
 B   ALTER TABLE public.tipos_documentos ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    258    257            �	           2604    561598    id    DEFAULT     |   ALTER TABLE ONLY public.tipos_empleadores ALTER COLUMN id SET DEFAULT nextval('public.tipos_empleadores_id_seq'::regclass);
 C   ALTER TABLE public.tipos_empleadores ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    260    259            �	           2604    561599    id    DEFAULT     �   ALTER TABLE ONLY public.tipos_liquidaciones ALTER COLUMN id SET DEFAULT nextval('public.tipos_liquidaciones_id_seq'::regclass);
 E   ALTER TABLE public.tipos_liquidaciones ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    262    261            �	           2604    561600    id    DEFAULT     n   ALTER TABLE ONLY public.vacaciones ALTER COLUMN id SET DEFAULT nextval('public.vacaciones_id_seq'::regclass);
 <   ALTER TABLE public.vacaciones ALTER COLUMN id DROP DEFAULT;
       public       postgres    false    273    272            �	           2604    561601    id    DEFAULT     p   ALTER TABLE ONLY sistema.reservadas ALTER COLUMN id SET DEFAULT nextval('sistema.reservadas_id_seq'::regclass);
 =   ALTER TABLE sistema.reservadas ALTER COLUMN id DROP DEFAULT;
       sistema       postgres    false    275    274            �	           2604    561602    id    DEFAULT     r   ALTER TABLE ONLY sistema.tipos_datos ALTER COLUMN id SET DEFAULT nextval('sistema.tipos_datos_id_seq'::regclass);
 >   ALTER TABLE sistema.tipos_datos ALTER COLUMN id DROP DEFAULT;
       sistema       postgres    false    277    276            �	           2604    561603    id    DEFAULT     |   ALTER TABLE ONLY sistema.tipos_reservadas ALTER COLUMN id SET DEFAULT nextval('sistema.tipos_reservadas_id_seq'::regclass);
 C   ALTER TABLE sistema.tipos_reservadas ALTER COLUMN id DROP DEFAULT;
       sistema       postgres    false    279    278            F          0    561169    acumuladores 
   TABLE DATA                     public       postgres    false    182   ��      �           0    0    acumuladores_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('public.acumuladores_id_seq', 5, true);
            public       postgres    false    183            �          0    571665    back_sueldo_basico 
   TABLE DATA                     public       postgres    false    297   ��      H          0    561179    bancos 
   TABLE DATA                     public       postgres    false    184   ��      �           0    0    bancos_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.bancos_id_seq', 1, true);
            public       postgres    false    185            J          0    561187 
   categorias 
   TABLE DATA                     public       postgres    false    186   ��      �           0    0    categorias_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.categorias_id_seq', 5, false);
            public       postgres    false    187            L          0    561195 	   conceptos 
   TABLE DATA                     public       postgres    false    188   ��      �           0    0    conceptos_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.conceptos_id_seq', 51, true);
            public       postgres    false    189            N          0    561208    conceptos_personas 
   TABLE DATA                     public       postgres    false    190   W�      O          0    561211    datos_actuales 
   TABLE DATA                     public       postgres    false    191   q�      �           0    0    datos_actuales_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.datos_actuales_id_seq', 1, true);
            public       postgres    false    192            Q          0    561219    datos_laborales 
   TABLE DATA                     public       postgres    false    193   ��      �           0    0    datos_laborales_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.datos_laborales_id_seq', 1, true);
            public       postgres    false    194            S          0    561224    datos_salud 
   TABLE DATA                     public       postgres    false    195   ��      �           0    0    datos_salud_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.datos_salud_id_seq', 1, true);
            public       postgres    false    196            U          0    561229    establecimientos 
   TABLE DATA                     public       postgres    false    197   ��      �           0    0    establecimientos_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.establecimientos_id_seq', 1, false);
            public       postgres    false    198            W          0    561237    estados_civiles 
   TABLE DATA                     public       postgres    false    199   V�      �           0    0    estados_civiles_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.estados_civiles_id_seq', 1, false);
            public       postgres    false    200            Y          0    561245    estados_liquidacion 
   TABLE DATA                     public       postgres    false    201   ��      �           0    0    estados_liquidacion_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('public.estados_liquidacion_id_seq', 1, false);
            public       postgres    false    202            [          0    561250    feriados 
   TABLE DATA                     public       postgres    false    203   A�      �           0    0    feriados_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.feriados_id_seq', 1, false);
            public       postgres    false    204            ]          0    561258    fichajes 
   TABLE DATA                     public       postgres    false    205   [�      �           0    0    fichajes_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.fichajes_id_seq', 1, false);
            public       postgres    false    206            _          0    561263    generos 
   TABLE DATA                     public       postgres    false    207   u�      �           0    0    generos_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.generos_id_seq', 1, false);
            public       postgres    false    208            �          0    570723    historico_liquidaciones 
   TABLE DATA                     public       postgres    false    291   ��      �          0    570738 !   historico_liquidaciones_conceptos 
   TABLE DATA                     public       postgres    false    292   ��      �          0    570802    historico_recibos 
   TABLE DATA                     public       postgres    false    293   �      �          0    570817    historico_recibos_acumuladores 
   TABLE DATA                     public       postgres    false    294   �      �          0    570832    historico_recibos_conceptos 
   TABLE DATA                     public       postgres    false    295   8�      �          0    595919    historico_sueldo_basico 
   TABLE DATA                     public       postgres    false    299   R�      �          0    595928    historico_sueldo_basico_detalle 
   TABLE DATA                     public       postgres    false    301   (�      �           0    0 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE SET     V   SELECT pg_catalog.setval('public.historico_sueldo_basico_detalle_id_seq', 201, true);
            public       postgres    false    300            �           0    0    historico_sueldo_basico_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.historico_sueldo_basico_id_seq', 20, true);
            public       postgres    false    298            a          0    561271    liquidaciones 
   TABLE DATA                     public       postgres    false    209    �      b          0    561279    liquidaciones_conceptos 
   TABLE DATA                     public       postgres    false    210   ��      �           0    0    liquidaciones_conceptos_id_seq    SEQUENCE SET     O   SELECT pg_catalog.setval('public.liquidaciones_conceptos_id_seq', 2831, true);
            public       postgres    false    211            �           0    0    liquidaciones_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.liquidaciones_id_seq', 113, true);
            public       postgres    false    212            e          0    561286    localidades 
   TABLE DATA                     public       postgres    false    213   ��      �           0    0    localidades_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.localidades_id_seq', 1, true);
            public       postgres    false    214            g          0    561291    nacionalidades 
   TABLE DATA                     public       postgres    false    215   �      �           0    0    nacionalidades_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.nacionalidades_id_seq', 1, false);
            public       postgres    false    216            i          0    561299    obras_sociales 
   TABLE DATA                     public       postgres    false    217   \�      �           0    0    obras_sociales_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.obras_sociales_id_seq', 1, false);
            public       postgres    false    218            k          0    561307    paises 
   TABLE DATA                     public       postgres    false    219   :�      �           0    0    paises_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.paises_id_seq', 1, true);
            public       postgres    false    220            m          0    561312    periodos 
   TABLE DATA                     public       postgres    false    221   ��      n          0    561318    periodos_detalle 
   TABLE DATA                     public       postgres    false    222   W�      �           0    0    periodos_detalle_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.periodos_detalle_id_seq', 62, true);
            public       postgres    false    223            �           0    0    periodos_id_seq    SEQUENCE SET     =   SELECT pg_catalog.setval('public.periodos_id_seq', 5, true);
            public       postgres    false    224            q          0    561326    persona_tareas 
   TABLE DATA                     public       postgres    false    225   ,�                  0    0    persona_tareas_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.persona_tareas_id_seq', 38, true);
            public       postgres    false    226            s          0    561331    personas 
   TABLE DATA                     public       postgres    false    227   ?�      t          0    561339    personas_conceptos 
   TABLE DATA                     public       postgres    false    228   ��                 0    0    personas_conceptos_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.personas_conceptos_id_seq', 1, true);
            public       postgres    false    229                       0    0    personas_id_seq    SEQUENCE SET     >   SELECT pg_catalog.setval('public.personas_id_seq', 26, true);
            public       postgres    false    230            w          0    561346    personas_jornadas 
   TABLE DATA                     public       postgres    false    231   ��                 0    0    personas_jornadas_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.personas_jornadas_id_seq', 1, false);
            public       postgres    false    232            y          0    561351 
   provincias 
   TABLE DATA                     public       postgres    false    233   ��                 0    0    provincias_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.provincias_id_seq', 24, true);
            public       postgres    false    234            {          0    561359    recibos 
   TABLE DATA                     public       postgres    false    235   M�      |          0    561362    recibos_acumuladores 
   TABLE DATA                     public       postgres    false    236   H�                 0    0    recibos_acumuladores_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.recibos_acumuladores_id_seq', 7460, true);
            public       postgres    false    237            ~          0    561367    recibos_conceptos 
   TABLE DATA                     public       postgres    false    238   b�                 0    0    recibos_conceptos_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('public.recibos_conceptos_id_seq', 56815, true);
            public       postgres    false    239                       0    0    recibos_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.recibos_id_seq', 1856, true);
            public       postgres    false    240            �          0    561374 	   regimenes 
   TABLE DATA                     public       postgres    false    241   �                 0    0    regimenes_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('public.regimenes_id_seq', 1, false);
            public       postgres    false    242            �          0    561956    tabla 
   TABLE DATA                     public       postgres    false    282         �          0    561967    tabla_detalle 
   TABLE DATA                     public       postgres    false    284   ?      	           0    0    tabla_detalle_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.tabla_detalle_id_seq', 120, true);
            public       postgres    false    283            �          0    561391    tabla_ganancias 
   TABLE DATA                     public       postgres    false    243   �      �          0    561397    tabla_ganancias_detalle 
   TABLE DATA                     public       postgres    false    244          
           0    0    tabla_ganancias_detalle_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.tabla_ganancias_detalle_id_seq', 34, true);
            public       postgres    false    245                       0    0    tabla_ganancias_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.tabla_ganancias_id_seq', 2, true);
            public       postgres    false    246                       0    0    tabla_id_seq    SEQUENCE SET     ;   SELECT pg_catalog.setval('public.tabla_id_seq', 11, true);
            public       postgres    false    281            �          0    561980    tabla_personas 
   TABLE DATA                     public       postgres    false    286   c"                 0    0    tabla_personas_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.tabla_personas_id_seq', 24, true);
            public       postgres    false    285            �          0    561407    tabla_vacaciones 
   TABLE DATA                     public       postgres    false    247   r#      �          0    561410    tabla_vacaciones_dias 
   TABLE DATA                     public       postgres    false    248   �#      �          0    561416    tareas 
   TABLE DATA                     public       postgres    false    249   �$                 0    0    tareas_id_seq    SEQUENCE SET     <   SELECT pg_catalog.setval('public.tareas_id_seq', 1, false);
            public       postgres    false    250            �          0    561424    tipo_liquidacion_conceptos 
   TABLE DATA                     public       postgres    false    251   �%                 0    0 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('public.tipo_liquidacion_conceptos_id_seq', 132, true);
            public       postgres    false    252            �          0    561429    tipos_conceptos 
   TABLE DATA                     public       postgres    false    253   A(                 0    0    tipos_conceptos_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('public.tipos_conceptos_id_seq', 4, true);
            public       postgres    false    254            �          0    561437    tipos_contratos 
   TABLE DATA                     public       postgres    false    255   �(                 0    0    tipos_contratos_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.tipos_contratos_id_seq', 1, false);
            public       postgres    false    256            �          0    561445    tipos_documentos 
   TABLE DATA                     public       postgres    false    257   Y)                 0    0    tipos_documentos_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.tipos_documentos_id_seq', 1, false);
            public       postgres    false    258            �          0    561453    tipos_empleadores 
   TABLE DATA                     public       postgres    false    259   �)                 0    0    tipos_empleadores_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('public.tipos_empleadores_id_seq', 1, true);
            public       postgres    false    260            �          0    561461    tipos_liquidaciones 
   TABLE DATA                     public       postgres    false    261   (*                 0    0    tipos_liquidaciones_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('public.tipos_liquidaciones_id_seq', 6, true);
            public       postgres    false    262            �          0    561525 
   vacaciones 
   TABLE DATA                     public       postgres    false    272   �*                 0    0    vacaciones_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('public.vacaciones_id_seq', 1, false);
            public       postgres    false    273            �          0    561533 
   reservadas 
   TABLE DATA                     sistema       postgres    false    274   �*                 0    0    reservadas_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('sistema.reservadas_id_seq', 27, true);
            sistema       postgres    false    275            �          0    561541    tipos_datos 
   TABLE DATA                     sistema       postgres    false    276   �3                 0    0    tipos_datos_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('sistema.tipos_datos_id_seq', 1, false);
            sistema       postgres    false    277            �          0    561549    tipos_reservadas 
   TABLE DATA                     sistema       postgres    false    278   4                 0    0    tipos_reservadas_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('sistema.tipos_reservadas_id_seq', 1, false);
            sistema       postgres    false    279            /
           2606    561605 )   persona_tareas_id_persona_id_tarea_unique 
   CONSTRAINT     �   ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT persona_tareas_id_persona_id_tarea_unique UNIQUE (id_persona, id_tarea);
 b   ALTER TABLE ONLY public.persona_tareas DROP CONSTRAINT persona_tareas_id_persona_id_tarea_unique;
       public         postgres    false    225    225    225            �	           2606    561607    pk_acumuladores 
   CONSTRAINT     Z   ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT pk_acumuladores PRIMARY KEY (id);
 F   ALTER TABLE ONLY public.acumuladores DROP CONSTRAINT pk_acumuladores;
       public         postgres    false    182    182            �	           2606    561609 	   pk_bancos 
   CONSTRAINT     N   ALTER TABLE ONLY public.bancos
    ADD CONSTRAINT pk_bancos PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.bancos DROP CONSTRAINT pk_bancos;
       public         postgres    false    184    184            �	           2606    561611    pk_categorias 
   CONSTRAINT     V   ALTER TABLE ONLY public.categorias
    ADD CONSTRAINT pk_categorias PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.categorias DROP CONSTRAINT pk_categorias;
       public         postgres    false    186    186            �	           2606    561613    pk_conceptos 
   CONSTRAINT     T   ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT pk_conceptos PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.conceptos DROP CONSTRAINT pk_conceptos;
       public         postgres    false    188    188            
           2606    561615    pk_conceptos_personas 
   CONSTRAINT     f   ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT pk_conceptos_personas PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.conceptos_personas DROP CONSTRAINT pk_conceptos_personas;
       public         postgres    false    190    190            
           2606    561617    pk_datos_actuales 
   CONSTRAINT     ^   ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT pk_datos_actuales PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.datos_actuales DROP CONSTRAINT pk_datos_actuales;
       public         postgres    false    191    191            	
           2606    561619    pk_datos_laborales 
   CONSTRAINT     `   ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT pk_datos_laborales PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.datos_laborales DROP CONSTRAINT pk_datos_laborales;
       public         postgres    false    193    193            
           2606    561621    pk_datos_salud 
   CONSTRAINT     X   ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT pk_datos_salud PRIMARY KEY (id);
 D   ALTER TABLE ONLY public.datos_salud DROP CONSTRAINT pk_datos_salud;
       public         postgres    false    195    195            
           2606    561623    pk_establecimientos 
   CONSTRAINT     b   ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT pk_establecimientos PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.establecimientos DROP CONSTRAINT pk_establecimientos;
       public         postgres    false    197    197            
           2606    561625    pk_estados_civiles 
   CONSTRAINT     `   ALTER TABLE ONLY public.estados_civiles
    ADD CONSTRAINT pk_estados_civiles PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.estados_civiles DROP CONSTRAINT pk_estados_civiles;
       public         postgres    false    199    199            
           2606    561628    pk_estados_liquidacion 
   CONSTRAINT     h   ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT pk_estados_liquidacion PRIMARY KEY (id);
 T   ALTER TABLE ONLY public.estados_liquidacion DROP CONSTRAINT pk_estados_liquidacion;
       public         postgres    false    201    201            
           2606    561630    pk_feriados 
   CONSTRAINT     R   ALTER TABLE ONLY public.feriados
    ADD CONSTRAINT pk_feriados PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.feriados DROP CONSTRAINT pk_feriados;
       public         postgres    false    203    203            
           2606    561632    pk_fichajes 
   CONSTRAINT     R   ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT pk_fichajes PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.fichajes DROP CONSTRAINT pk_fichajes;
       public         postgres    false    205    205            
           2606    561634 
   pk_generos 
   CONSTRAINT     P   ALTER TABLE ONLY public.generos
    ADD CONSTRAINT pk_generos PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.generos DROP CONSTRAINT pk_generos;
       public         postgres    false    207    207            �
           2606    595925    pk_historico_sueldo_basico 
   CONSTRAINT     p   ALTER TABLE ONLY public.historico_sueldo_basico
    ADD CONSTRAINT pk_historico_sueldo_basico PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.historico_sueldo_basico DROP CONSTRAINT pk_historico_sueldo_basico;
       public         postgres    false    299    299            �
           2606    595933 "   pk_historico_sueldo_basico_detalle 
   CONSTRAINT     �   ALTER TABLE ONLY public.historico_sueldo_basico_detalle
    ADD CONSTRAINT pk_historico_sueldo_basico_detalle PRIMARY KEY (id);
 l   ALTER TABLE ONLY public.historico_sueldo_basico_detalle DROP CONSTRAINT pk_historico_sueldo_basico_detalle;
       public         postgres    false    301    301            e
           2606    561636    pk_liquidaciones 
   CONSTRAINT     b   ALTER TABLE ONLY public.tipos_liquidaciones
    ADD CONSTRAINT pk_liquidaciones PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.tipos_liquidaciones DROP CONSTRAINT pk_liquidaciones;
       public         postgres    false    261    261            
           2606    561638    pk_liquidaciones2 
   CONSTRAINT     ]   ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT pk_liquidaciones2 PRIMARY KEY (id);
 I   ALTER TABLE ONLY public.liquidaciones DROP CONSTRAINT pk_liquidaciones2;
       public         postgres    false    209    209            
           2606    561640    pk_liquidaciones_conceptos 
   CONSTRAINT     p   ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT pk_liquidaciones_conceptos PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.liquidaciones_conceptos DROP CONSTRAINT pk_liquidaciones_conceptos;
       public         postgres    false    210    210            }
           2606    570745 $   pk_liquidaciones_conceptos_historico 
   CONSTRAINT     �   ALTER TABLE ONLY public.historico_liquidaciones_conceptos
    ADD CONSTRAINT pk_liquidaciones_conceptos_historico PRIMARY KEY (id);
 p   ALTER TABLE ONLY public.historico_liquidaciones_conceptos DROP CONSTRAINT pk_liquidaciones_conceptos_historico;
       public         postgres    false    292    292            {
           2606    570732    pk_liquidaciones_historico 
   CONSTRAINT     p   ALTER TABLE ONLY public.historico_liquidaciones
    ADD CONSTRAINT pk_liquidaciones_historico PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.historico_liquidaciones DROP CONSTRAINT pk_liquidaciones_historico;
       public         postgres    false    291    291            !
           2606    561642    pk_localidad 
   CONSTRAINT     V   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT pk_localidad PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.localidades DROP CONSTRAINT pk_localidad;
       public         postgres    false    213    213            #
           2606    561644    pk_nacionalidades 
   CONSTRAINT     ^   ALTER TABLE ONLY public.nacionalidades
    ADD CONSTRAINT pk_nacionalidades PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.nacionalidades DROP CONSTRAINT pk_nacionalidades;
       public         postgres    false    215    215            %
           2606    561646    pk_obras_sociales 
   CONSTRAINT     ^   ALTER TABLE ONLY public.obras_sociales
    ADD CONSTRAINT pk_obras_sociales PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.obras_sociales DROP CONSTRAINT pk_obras_sociales;
       public         postgres    false    217    217            '
           2606    561648 	   pk_paises 
   CONSTRAINT     N   ALTER TABLE ONLY public.paises
    ADD CONSTRAINT pk_paises PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.paises DROP CONSTRAINT pk_paises;
       public         postgres    false    219    219            -
           2606    561650    pk_periodo_detalle 
   CONSTRAINT     a   ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT pk_periodo_detalle PRIMARY KEY (id);
 M   ALTER TABLE ONLY public.periodos_detalle DROP CONSTRAINT pk_periodo_detalle;
       public         postgres    false    222    222            )
           2606    561652    pk_periodos 
   CONSTRAINT     R   ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT pk_periodos PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.periodos DROP CONSTRAINT pk_periodos;
       public         postgres    false    221    221            1
           2606    561654    pk_persona_tareas 
   CONSTRAINT     ^   ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT pk_persona_tareas PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.persona_tareas DROP CONSTRAINT pk_persona_tareas;
       public         postgres    false    225    225            3
           2606    561656    pk_personas 
   CONSTRAINT     R   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT pk_personas PRIMARY KEY (id);
 >   ALTER TABLE ONLY public.personas DROP CONSTRAINT pk_personas;
       public         postgres    false    227    227            7
           2606    561658    pk_personas_conceptos 
   CONSTRAINT     f   ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT pk_personas_conceptos PRIMARY KEY (id);
 R   ALTER TABLE ONLY public.personas_conceptos DROP CONSTRAINT pk_personas_conceptos;
       public         postgres    false    228    228            ;
           2606    561660    pk_personas_jornadas 
   CONSTRAINT     d   ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT pk_personas_jornadas PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.personas_jornadas DROP CONSTRAINT pk_personas_jornadas;
       public         postgres    false    231    231            =
           2606    561662    pk_provincias 
   CONSTRAINT     V   ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT pk_provincias PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.provincias DROP CONSTRAINT pk_provincias;
       public         postgres    false    233    233            ?
           2606    561664 
   pk_recibos 
   CONSTRAINT     P   ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT pk_recibos PRIMARY KEY (id);
 <   ALTER TABLE ONLY public.recibos DROP CONSTRAINT pk_recibos;
       public         postgres    false    235    235            C
           2606    561666    pk_recibos_acumuladores 
   CONSTRAINT     j   ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT pk_recibos_acumuladores PRIMARY KEY (id);
 V   ALTER TABLE ONLY public.recibos_acumuladores DROP CONSTRAINT pk_recibos_acumuladores;
       public         postgres    false    236    236            �
           2606    570824 !   pk_recibos_acumuladores_historico 
   CONSTRAINT     ~   ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT pk_recibos_acumuladores_historico PRIMARY KEY (id);
 j   ALTER TABLE ONLY public.historico_recibos_acumuladores DROP CONSTRAINT pk_recibos_acumuladores_historico;
       public         postgres    false    294    294            G
           2606    561668    pk_recibos_conceptos 
   CONSTRAINT     d   ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.recibos_conceptos DROP CONSTRAINT pk_recibos_conceptos;
       public         postgres    false    238    238            �
           2606    570839    pk_recibos_conceptos_historico 
   CONSTRAINT     x   ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT pk_recibos_conceptos_historico PRIMARY KEY (id);
 d   ALTER TABLE ONLY public.historico_recibos_conceptos DROP CONSTRAINT pk_recibos_conceptos_historico;
       public         postgres    false    295    295            
           2606    570809    pk_recibos_historico 
   CONSTRAINT     d   ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT pk_recibos_historico PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.historico_recibos DROP CONSTRAINT pk_recibos_historico;
       public         postgres    false    293    293            K
           2606    561670    pk_regimenes 
   CONSTRAINT     T   ALTER TABLE ONLY public.regimenes
    ADD CONSTRAINT pk_regimenes PRIMARY KEY (id);
 @   ALTER TABLE ONLY public.regimenes DROP CONSTRAINT pk_regimenes;
       public         postgres    false    241    241            o
           2606    561964    pk_tabla 
   CONSTRAINT     L   ALTER TABLE ONLY public.tabla
    ADD CONSTRAINT pk_tabla PRIMARY KEY (id);
 8   ALTER TABLE ONLY public.tabla DROP CONSTRAINT pk_tabla;
       public         postgres    false    282    282            s
           2606    561972    pk_tabla_detalle 
   CONSTRAINT     \   ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT pk_tabla_detalle PRIMARY KEY (id);
 H   ALTER TABLE ONLY public.tabla_detalle DROP CONSTRAINT pk_tabla_detalle;
       public         postgres    false    284    284            M
           2606    561676    pk_tabla_ganancias 
   CONSTRAINT     `   ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.tabla_ganancias DROP CONSTRAINT pk_tabla_ganancias;
       public         postgres    false    243    243            Q
           2606    561678    pk_tabla_ganancias_detalle 
   CONSTRAINT     p   ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT pk_tabla_ganancias_detalle PRIMARY KEY (id);
 \   ALTER TABLE ONLY public.tabla_ganancias_detalle DROP CONSTRAINT pk_tabla_ganancias_detalle;
       public         postgres    false    244    244            w
           2606    561985    pk_tabla_personas 
   CONSTRAINT     ^   ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT pk_tabla_personas PRIMARY KEY (id);
 J   ALTER TABLE ONLY public.tabla_personas DROP CONSTRAINT pk_tabla_personas;
       public         postgres    false    286    286            S
           2606    561682    pk_tabla_vacaciones 
   CONSTRAINT     b   ALTER TABLE ONLY public.tabla_vacaciones
    ADD CONSTRAINT pk_tabla_vacaciones PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.tabla_vacaciones DROP CONSTRAINT pk_tabla_vacaciones;
       public         postgres    false    247    247            U
           2606    561684    pk_tabla_vacaciones_dias 
   CONSTRAINT     l   ALTER TABLE ONLY public.tabla_vacaciones_dias
    ADD CONSTRAINT pk_tabla_vacaciones_dias PRIMARY KEY (id);
 X   ALTER TABLE ONLY public.tabla_vacaciones_dias DROP CONSTRAINT pk_tabla_vacaciones_dias;
       public         postgres    false    248    248            W
           2606    561686 	   pk_tareas 
   CONSTRAINT     N   ALTER TABLE ONLY public.tareas
    ADD CONSTRAINT pk_tareas PRIMARY KEY (id);
 :   ALTER TABLE ONLY public.tareas DROP CONSTRAINT pk_tareas;
       public         postgres    false    249    249            Y
           2606    561688    pk_tipo_liquidacion_conceptos 
   CONSTRAINT     v   ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT pk_tipo_liquidacion_conceptos PRIMARY KEY (id);
 b   ALTER TABLE ONLY public.tipo_liquidacion_conceptos DROP CONSTRAINT pk_tipo_liquidacion_conceptos;
       public         postgres    false    251    251            ]
           2606    561690    pk_tipos_conceptos 
   CONSTRAINT     `   ALTER TABLE ONLY public.tipos_conceptos
    ADD CONSTRAINT pk_tipos_conceptos PRIMARY KEY (id);
 L   ALTER TABLE ONLY public.tipos_conceptos DROP CONSTRAINT pk_tipos_conceptos;
       public         postgres    false    253    253            a
           2606    561692    pk_tipos_documentos 
   CONSTRAINT     b   ALTER TABLE ONLY public.tipos_documentos
    ADD CONSTRAINT pk_tipos_documentos PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.tipos_documentos DROP CONSTRAINT pk_tipos_documentos;
       public         postgres    false    257    257            c
           2606    561694    pk_tipos_empleadores 
   CONSTRAINT     d   ALTER TABLE ONLY public.tipos_empleadores
    ADD CONSTRAINT pk_tipos_empleadores PRIMARY KEY (id);
 P   ALTER TABLE ONLY public.tipos_empleadores DROP CONSTRAINT pk_tipos_empleadores;
       public         postgres    false    259    259            g
           2606    561696    pk_vacaciones 
   CONSTRAINT     V   ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT pk_vacaciones PRIMARY KEY (id);
 B   ALTER TABLE ONLY public.vacaciones DROP CONSTRAINT pk_vacaciones;
       public         postgres    false    272    272            _
           2606    561698    tipos_contratos_pkey 
   CONSTRAINT     b   ALTER TABLE ONLY public.tipos_contratos
    ADD CONSTRAINT tipos_contratos_pkey PRIMARY KEY (id);
 N   ALTER TABLE ONLY public.tipos_contratos DROP CONSTRAINT tipos_contratos_pkey;
       public         postgres    false    255    255            
           2606    561700    uk_conceptos 
   CONSTRAINT     S   ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT uk_conceptos UNIQUE (codigo);
 @   ALTER TABLE ONLY public.conceptos DROP CONSTRAINT uk_conceptos;
       public         postgres    false    188    188            
           2606    561702    uk_conceptos_personas 
   CONSTRAINT     v   ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT uk_conceptos_personas UNIQUE (id_concepto, id_persona);
 R   ALTER TABLE ONLY public.conceptos_personas DROP CONSTRAINT uk_conceptos_personas;
       public         postgres    false    190    190    190            
           2606    561704    uk_estados_liquidacion 
   CONSTRAINT     l   ALTER TABLE ONLY public.estados_liquidacion
    ADD CONSTRAINT uk_estados_liquidacion UNIQUE (descripcion);
 T   ALTER TABLE ONLY public.estados_liquidacion DROP CONSTRAINT uk_estados_liquidacion;
       public         postgres    false    201    201            
           2606    562032    uk_liquidaciones_conceptos 
   CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT uk_liquidaciones_conceptos UNIQUE (id_concepto, id_liquidacion);
 \   ALTER TABLE ONLY public.liquidaciones_conceptos DROP CONSTRAINT uk_liquidaciones_conceptos;
       public         postgres    false    210    210    210            +
           2606    561706    uk_periodos 
   CONSTRAINT     R   ALTER TABLE ONLY public.periodos
    ADD CONSTRAINT uk_periodos UNIQUE (periodo);
 >   ALTER TABLE ONLY public.periodos DROP CONSTRAINT uk_periodos;
       public         postgres    false    221    221            9
           2606    561708    uk_personas_conceptos 
   CONSTRAINT     v   ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT uk_personas_conceptos UNIQUE (id_persona, id_concepto);
 R   ALTER TABLE ONLY public.personas_conceptos DROP CONSTRAINT uk_personas_conceptos;
       public         postgres    false    228    228    228            5
           2606    561710    uk_personas_dni 
   CONSTRAINT     o   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT uk_personas_dni UNIQUE (id_tipo_documento, nro_documento);
 B   ALTER TABLE ONLY public.personas DROP CONSTRAINT uk_personas_dni;
       public         postgres    false    227    227    227            A
           2606    562034 
   uk_recibos 
   CONSTRAINT     c   ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT uk_recibos UNIQUE (id_liquidacion, id_persona);
 <   ALTER TABLE ONLY public.recibos DROP CONSTRAINT uk_recibos;
       public         postgres    false    235    235    235            E
           2606    561712    uk_recibos_acumuladores 
   CONSTRAINT     {   ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladores UNIQUE (id_recibo, id_acumulador);
 V   ALTER TABLE ONLY public.recibos_acumuladores DROP CONSTRAINT uk_recibos_acumuladores;
       public         postgres    false    236    236    236            �
           2606    570826    uk_recibos_acumuladoresh 
   CONSTRAINT     �   ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT uk_recibos_acumuladoresh UNIQUE (id_recibo, id_acumulador);
 a   ALTER TABLE ONLY public.historico_recibos_acumuladores DROP CONSTRAINT uk_recibos_acumuladoresh;
       public         postgres    false    294    294    294            I
           2606    562036    uk_recibos_conceptos 
   CONSTRAINT     s   ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT uk_recibos_conceptos UNIQUE (id_concepto, id_recibo);
 P   ALTER TABLE ONLY public.recibos_conceptos DROP CONSTRAINT uk_recibos_conceptos;
       public         postgres    false    238    238    238            �
           2606    570841    uk_recibos_conceptosh 
   CONSTRAINT     ~   ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT uk_recibos_conceptosh UNIQUE (id_concepto, id_recibo);
 [   ALTER TABLE ONLY public.historico_recibos_conceptos DROP CONSTRAINT uk_recibos_conceptosh;
       public         postgres    false    295    295    295            �
           2606    570811    uk_recibosh 
   CONSTRAINT     n   ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT uk_recibosh UNIQUE (id_liquidacion, id_persona);
 G   ALTER TABLE ONLY public.historico_recibos DROP CONSTRAINT uk_recibosh;
       public         postgres    false    293    293    293            q
           2606    562013    uk_tabla 
   CONSTRAINT     J   ALTER TABLE ONLY public.tabla
    ADD CONSTRAINT uk_tabla UNIQUE (clave);
 8   ALTER TABLE ONLY public.tabla DROP CONSTRAINT uk_tabla;
       public         postgres    false    282    282            u
           2606    562011    uk_tabla_detalle 
   CONSTRAINT     h   ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT uk_tabla_detalle UNIQUE (id_tabla, anio, mes);
 H   ALTER TABLE ONLY public.tabla_detalle DROP CONSTRAINT uk_tabla_detalle;
       public         postgres    false    284    284    284    284            O
           2606    561714    uk_tabla_ganancias 
   CONSTRAINT     ]   ALTER TABLE ONLY public.tabla_ganancias
    ADD CONSTRAINT uk_tabla_ganancias UNIQUE (anio);
 L   ALTER TABLE ONLY public.tabla_ganancias DROP CONSTRAINT uk_tabla_ganancias;
       public         postgres    false    243    243            y
           2606    571719    uk_tabla_personas 
   CONSTRAINT     v   ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT uk_tabla_personas UNIQUE (id_tabla, id_persona, anio, mes);
 J   ALTER TABLE ONLY public.tabla_personas DROP CONSTRAINT uk_tabla_personas;
       public         postgres    false    286    286    286    286    286            [
           2606    561716    uk_tipo_liquidacion_conceptos 
   CONSTRAINT     �   ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT uk_tipo_liquidacion_conceptos UNIQUE (id_concepto, id_tipo_liquidacion);
 b   ALTER TABLE ONLY public.tipo_liquidacion_conceptos DROP CONSTRAINT uk_tipo_liquidacion_conceptos;
       public         postgres    false    251    251    251            i
           2606    561718    pk_reservadas 
   CONSTRAINT     W   ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT pk_reservadas PRIMARY KEY (id);
 C   ALTER TABLE ONLY sistema.reservadas DROP CONSTRAINT pk_reservadas;
       sistema         postgres    false    274    274            k
           2606    561720    pk_tipos_datos 
   CONSTRAINT     Y   ALTER TABLE ONLY sistema.tipos_datos
    ADD CONSTRAINT pk_tipos_datos PRIMARY KEY (id);
 E   ALTER TABLE ONLY sistema.tipos_datos DROP CONSTRAINT pk_tipos_datos;
       sistema         postgres    false    276    276            m
           2606    561722    pk_tipos_reservadas 
   CONSTRAINT     c   ALTER TABLE ONLY sistema.tipos_reservadas
    ADD CONSTRAINT pk_tipos_reservadas PRIMARY KEY (id);
 O   ALTER TABLE ONLY sistema.tipos_reservadas DROP CONSTRAINT pk_tipos_reservadas;
       sistema         postgres    false    278    278            �
           2620    562006    trg_ai_liquidaciones_conceptos    TRIGGER     �   CREATE TRIGGER trg_ai_liquidaciones_conceptos AFTER INSERT ON public.liquidaciones_conceptos FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_ai_liquidaciones_conceptos();
 O   DROP TRIGGER trg_ai_liquidaciones_conceptos ON public.liquidaciones_conceptos;
       public       postgres    false    321    210            �
           2620    561723    trg_ai_recibos    TRIGGER     x   CREATE TRIGGER trg_ai_recibos AFTER INSERT ON public.recibos FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_ai_recibos();
 /   DROP TRIGGER trg_ai_recibos ON public.recibos;
       public       postgres    false    319    235            �
           2620    570563    trg_au_liquidaciones    TRIGGER     �   CREATE TRIGGER trg_au_liquidaciones AFTER UPDATE ON public.liquidaciones FOR EACH ROW EXECUTE PROCEDURE public.sp_trg_au_liquidaciones();
 ;   DROP TRIGGER trg_au_liquidaciones ON public.liquidaciones;
       public       postgres    false    209    322            �
           2606    561724 "   conceptos_id_tipo_concepto_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.conceptos
    ADD CONSTRAINT conceptos_id_tipo_concepto_foreign FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);
 V   ALTER TABLE ONLY public.conceptos DROP CONSTRAINT conceptos_id_tipo_concepto_foreign;
       public       postgres    false    253    188    2653            �
           2606    561729 %   establecimientos_id_localidad_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT establecimientos_id_localidad_foreign FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);
 `   ALTER TABLE ONLY public.establecimientos DROP CONSTRAINT establecimientos_id_localidad_foreign;
       public       postgres    false    197    2593    213            �
           2606    561734    fk_acumuladores__tipo_concepto    FK CONSTRAINT     �   ALTER TABLE ONLY public.acumuladores
    ADD CONSTRAINT fk_acumuladores__tipo_concepto FOREIGN KEY (id_tipo_concepto) REFERENCES public.tipos_conceptos(id);
 U   ALTER TABLE ONLY public.acumuladores DROP CONSTRAINT fk_acumuladores__tipo_concepto;
       public       postgres    false    182    253    2653            �
           2606    561739     fk_conceptos_personas__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);
 ]   ALTER TABLE ONLY public.conceptos_personas DROP CONSTRAINT fk_conceptos_personas__conceptos;
       public       postgres    false    2559    190    188            �
           2606    561744    fk_conceptos_personas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.conceptos_personas
    ADD CONSTRAINT fk_conceptos_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 \   ALTER TABLE ONLY public.conceptos_personas DROP CONSTRAINT fk_conceptos_personas__personas;
       public       postgres    false    2611    227    190            �
           2606    561749    fk_datos_actuales__estado_civil    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__estado_civil FOREIGN KEY (id_estado_civil) REFERENCES public.estados_civiles(id);
 X   ALTER TABLE ONLY public.datos_actuales DROP CONSTRAINT fk_datos_actuales__estado_civil;
       public       postgres    false    2575    191    199            �
           2606    561754    fk_datos_actuales__peresona    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales__peresona FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 T   ALTER TABLE ONLY public.datos_actuales DROP CONSTRAINT fk_datos_actuales__peresona;
       public       postgres    false    2611    227    191            �
           2606    561759    fk_datos_actuales_localidades    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_actuales
    ADD CONSTRAINT fk_datos_actuales_localidades FOREIGN KEY (id_localidad) REFERENCES public.localidades(id);
 V   ALTER TABLE ONLY public.datos_actuales DROP CONSTRAINT fk_datos_actuales_localidades;
       public       postgres    false    191    213    2593            �
           2606    561764    fk_datos_laborales__categorias    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__categorias FOREIGN KEY (id_categoria) REFERENCES public.categorias(id);
 X   ALTER TABLE ONLY public.datos_laborales DROP CONSTRAINT fk_datos_laborales__categorias;
       public       postgres    false    186    193    2557            �
           2606    561769 #   fk_datos_laborales__establecimiento    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__establecimiento FOREIGN KEY (id_establecimiento) REFERENCES public.establecimientos(id);
 ]   ALTER TABLE ONLY public.datos_laborales DROP CONSTRAINT fk_datos_laborales__establecimiento;
       public       postgres    false    193    197    2573            �
           2606    561774    fk_datos_laborales__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 V   ALTER TABLE ONLY public.datos_laborales DROP CONSTRAINT fk_datos_laborales__personas;
       public       postgres    false    2611    193    227            �
           2606    561779 #   fk_datos_laborales__tipos_contratos    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_laborales
    ADD CONSTRAINT fk_datos_laborales__tipos_contratos FOREIGN KEY (id_tipo_contrato) REFERENCES public.tipos_contratos(id);
 ]   ALTER TABLE ONLY public.datos_laborales DROP CONSTRAINT fk_datos_laborales__tipos_contratos;
       public       postgres    false    255    2655    193            �
           2606    561784    fk_datos_salud__obra_social    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__obra_social FOREIGN KEY (id_obra_social) REFERENCES public.obras_sociales(id);
 Q   ALTER TABLE ONLY public.datos_salud DROP CONSTRAINT fk_datos_salud__obra_social;
       public       postgres    false    2597    217    195            �
           2606    561789    fk_datos_salud__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.datos_salud
    ADD CONSTRAINT fk_datos_salud__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 N   ALTER TABLE ONLY public.datos_salud DROP CONSTRAINT fk_datos_salud__personas;
       public       postgres    false    2611    227    195            �
           2606    561794 #   fk_establecimientos__tipo_empleador    FK CONSTRAINT     �   ALTER TABLE ONLY public.establecimientos
    ADD CONSTRAINT fk_establecimientos__tipo_empleador FOREIGN KEY (id_tipo_empleador) REFERENCES public.tipos_empleadores(id);
 ^   ALTER TABLE ONLY public.establecimientos DROP CONSTRAINT fk_establecimientos__tipo_empleador;
       public       postgres    false    259    197    2659            �
           2606    561799    fk_fichajes__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.fichajes
    ADD CONSTRAINT fk_fichajes__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 H   ALTER TABLE ONLY public.fichajes DROP CONSTRAINT fk_fichajes__personas;
       public       postgres    false    2611    205    227            �
           2606    595934 ,   fk_historico_sueldo_basico_detalle__cabecera    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_sueldo_basico_detalle
    ADD CONSTRAINT fk_historico_sueldo_basico_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES public.historico_sueldo_basico(id);
 v   ALTER TABLE ONLY public.historico_sueldo_basico_detalle DROP CONSTRAINT fk_historico_sueldo_basico_detalle__cabecera;
       public       postgres    false    2699    299    301            �
           2606    561804    fk_liquidacion__estado    FK CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidacion__estado FOREIGN KEY (id_estado) REFERENCES public.estados_liquidacion(id);
 N   ALTER TABLE ONLY public.liquidaciones DROP CONSTRAINT fk_liquidacion__estado;
       public       postgres    false    2577    201    209            �
           2606    561809    fk_liquidaciones__bancos    FK CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__bancos FOREIGN KEY (id_banco) REFERENCES public.bancos(id);
 P   ALTER TABLE ONLY public.liquidaciones DROP CONSTRAINT fk_liquidaciones__bancos;
       public       postgres    false    2555    184    209            �
           2606    561814    fk_liquidaciones__tipos    FK CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones
    ADD CONSTRAINT fk_liquidaciones__tipos FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);
 O   ALTER TABLE ONLY public.liquidaciones DROP CONSTRAINT fk_liquidaciones__tipos;
       public       postgres    false    2661    209    261            �
           2606    561819 %   fk_liquidaciones_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);
 g   ALTER TABLE ONLY public.liquidaciones_conceptos DROP CONSTRAINT fk_liquidaciones_conceptos__conceptos;
       public       postgres    false    188    2559    210            �
           2606    561824 )   fk_liquidaciones_conceptos__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY public.liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);
 k   ALTER TABLE ONLY public.liquidaciones_conceptos DROP CONSTRAINT fk_liquidaciones_conceptos__liquidaciones;
       public       postgres    false    210    2587    209            �
           2606    570746 ,   fk_liquidaciones_conceptos_h__liquidacionesh    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_liquidaciones_conceptos
    ADD CONSTRAINT fk_liquidaciones_conceptos_h__liquidacionesh FOREIGN KEY (id_liquidacion) REFERENCES public.historico_liquidaciones(id);
 x   ALTER TABLE ONLY public.historico_liquidaciones_conceptos DROP CONSTRAINT fk_liquidaciones_conceptos_h__liquidacionesh;
       public       postgres    false    291    2683    292            �
           2606    570733 )   fk_liquidaciones_historico__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_liquidaciones
    ADD CONSTRAINT fk_liquidaciones_historico__liquidaciones FOREIGN KEY (id) REFERENCES public.liquidaciones(id);
 k   ALTER TABLE ONLY public.historico_liquidaciones DROP CONSTRAINT fk_liquidaciones_historico__liquidaciones;
       public       postgres    false    291    209    2587            �
           2606    561829    fk_localidad_provincia    FK CONSTRAINT     �   ALTER TABLE ONLY public.localidades
    ADD CONSTRAINT fk_localidad_provincia FOREIGN KEY (id_provincia) REFERENCES public.provincias(id);
 L   ALTER TABLE ONLY public.localidades DROP CONSTRAINT fk_localidad_provincia;
       public       postgres    false    233    213    2621            �
           2606    561834    fk_periodo_detalle__periodo    FK CONSTRAINT     �   ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__periodo FOREIGN KEY (id_periodo) REFERENCES public.periodos(id);
 V   ALTER TABLE ONLY public.periodos_detalle DROP CONSTRAINT fk_periodo_detalle__periodo;
       public       postgres    false    2601    222    221            �
           2606    561839    fk_periodo_detalle__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.periodos_detalle
    ADD CONSTRAINT fk_periodo_detalle__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 W   ALTER TABLE ONLY public.periodos_detalle DROP CONSTRAINT fk_periodo_detalle__personas;
       public       postgres    false    227    222    2611            �
           2606    561844    fk_persona__nacionalidades    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_persona__nacionalidades FOREIGN KEY (id_nacionalidad) REFERENCES public.nacionalidades(id);
 M   ALTER TABLE ONLY public.personas DROP CONSTRAINT fk_persona__nacionalidades;
       public       postgres    false    227    2595    215            �
           2606    561849    fk_personas__generos    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas
    ADD CONSTRAINT fk_personas__generos FOREIGN KEY (id_genero) REFERENCES public.generos(id);
 G   ALTER TABLE ONLY public.personas DROP CONSTRAINT fk_personas__generos;
       public       postgres    false    2585    207    227            �
           2606    561854     fk_personas_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);
 ]   ALTER TABLE ONLY public.personas_conceptos DROP CONSTRAINT fk_personas_conceptos__conceptos;
       public       postgres    false    228    188    2559            �
           2606    561859    fk_personas_conceptos__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas_conceptos
    ADD CONSTRAINT fk_personas_conceptos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 \   ALTER TABLE ONLY public.personas_conceptos DROP CONSTRAINT fk_personas_conceptos__personas;
       public       postgres    false    2611    228    227            �
           2606    561864    fk_personas_jornadas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.personas_jornadas
    ADD CONSTRAINT fk_personas_jornadas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 Z   ALTER TABLE ONLY public.personas_jornadas DROP CONSTRAINT fk_personas_jornadas__personas;
       public       postgres    false    227    2611    231            �
           2606    561869    fk_personas_tareas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.persona_tareas
    ADD CONSTRAINT fk_personas_tareas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 U   ALTER TABLE ONLY public.persona_tareas DROP CONSTRAINT fk_personas_tareas__personas;
       public       postgres    false    225    227    2611            �
           2606    561874    fk_provincias_pais    FK CONSTRAINT     }   ALTER TABLE ONLY public.provincias
    ADD CONSTRAINT fk_provincias_pais FOREIGN KEY (id_pais) REFERENCES public.paises(id);
 G   ALTER TABLE ONLY public.provincias DROP CONSTRAINT fk_provincias_pais;
       public       postgres    false    233    2599    219            �
           2606    561879    fk_recibos__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__liquidaciones FOREIGN KEY (id_liquidacion) REFERENCES public.liquidaciones(id);
 K   ALTER TABLE ONLY public.recibos DROP CONSTRAINT fk_recibos__liquidaciones;
       public       postgres    false    2587    235    209            �
           2606    561884    fk_recibos__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos
    ADD CONSTRAINT fk_recibos__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 F   ALTER TABLE ONLY public.recibos DROP CONSTRAINT fk_recibos__personas;
       public       postgres    false    227    2611    235            �
           2606    561889 #   fk_recibos_acumuladores__acumulador    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__acumulador FOREIGN KEY (id_acumulador) REFERENCES public.acumuladores(id);
 b   ALTER TABLE ONLY public.recibos_acumuladores DROP CONSTRAINT fk_recibos_acumuladores__acumulador;
       public       postgres    false    2553    236    182            �
           2606    571433    fk_recibos_acumuladores__recibo    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladores__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id) ON DELETE CASCADE;
 ^   ALTER TABLE ONLY public.recibos_acumuladores DROP CONSTRAINT fk_recibos_acumuladores__recibo;
       public       postgres    false    236    235    2623            �
           2606    570827 !   fk_recibos_acumuladoresh__reciboh    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_recibos_acumuladores
    ADD CONSTRAINT fk_recibos_acumuladoresh__reciboh FOREIGN KEY (id_recibo) REFERENCES public.historico_recibos(id);
 j   ALTER TABLE ONLY public.historico_recibos_acumuladores DROP CONSTRAINT fk_recibos_acumuladoresh__reciboh;
       public       postgres    false    293    2687    294            �
           2606    561899    fk_recibos_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);
 [   ALTER TABLE ONLY public.recibos_conceptos DROP CONSTRAINT fk_recibos_conceptos__conceptos;
       public       postgres    false    238    2559    188            �
           2606    571438    fk_recibos_conceptos__recibo    FK CONSTRAINT     �   ALTER TABLE ONLY public.recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__recibo FOREIGN KEY (id_recibo) REFERENCES public.recibos(id) ON DELETE CASCADE;
 X   ALTER TABLE ONLY public.recibos_conceptos DROP CONSTRAINT fk_recibos_conceptos__recibo;
       public       postgres    false    2623    238    235            �
           2606    570842    fk_recibos_conceptos__reciboh    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_recibos_conceptos
    ADD CONSTRAINT fk_recibos_conceptos__reciboh FOREIGN KEY (id_recibo) REFERENCES public.historico_recibos(id);
 c   ALTER TABLE ONLY public.historico_recibos_conceptos DROP CONSTRAINT fk_recibos_conceptos__reciboh;
       public       postgres    false    2687    293    295            �
           2606    570812 $   fk_recibos_historico__liquidacionesh    FK CONSTRAINT     �   ALTER TABLE ONLY public.historico_recibos
    ADD CONSTRAINT fk_recibos_historico__liquidacionesh FOREIGN KEY (id_liquidacion) REFERENCES public.historico_liquidaciones(id);
 `   ALTER TABLE ONLY public.historico_recibos DROP CONSTRAINT fk_recibos_historico__liquidacionesh;
       public       postgres    false    293    291    2683            �
           2606    561973    fk_tabla_detalle__tabla    FK CONSTRAINT     �   ALTER TABLE ONLY public.tabla_detalle
    ADD CONSTRAINT fk_tabla_detalle__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);
 O   ALTER TABLE ONLY public.tabla_detalle DROP CONSTRAINT fk_tabla_detalle__tabla;
       public       postgres    false    2671    282    284            �
           2606    561914 $   fk_tabla_ganancias_detalle__cabecera    FK CONSTRAINT     �   ALTER TABLE ONLY public.tabla_ganancias_detalle
    ADD CONSTRAINT fk_tabla_ganancias_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES public.tabla_ganancias(id);
 f   ALTER TABLE ONLY public.tabla_ganancias_detalle DROP CONSTRAINT fk_tabla_ganancias_detalle__cabecera;
       public       postgres    false    244    2637    243            �
           2606    561986    fk_tabla_personas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 T   ALTER TABLE ONLY public.tabla_personas DROP CONSTRAINT fk_tabla_personas__personas;
       public       postgres    false    2611    286    227            �
           2606    561991    fk_tabla_personas__tabla    FK CONSTRAINT     �   ALTER TABLE ONLY public.tabla_personas
    ADD CONSTRAINT fk_tabla_personas__tabla FOREIGN KEY (id_tabla) REFERENCES public.tabla(id);
 Q   ALTER TABLE ONLY public.tabla_personas DROP CONSTRAINT fk_tabla_personas__tabla;
       public       postgres    false    2671    282    286            �
           2606    561929 (   fk_tipo_liquidacion_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__conceptos FOREIGN KEY (id_concepto) REFERENCES public.conceptos(id);
 m   ALTER TABLE ONLY public.tipo_liquidacion_conceptos DROP CONSTRAINT fk_tipo_liquidacion_conceptos__conceptos;
       public       postgres    false    251    188    2559            �
           2606    561934 #   fk_tipo_liquidacion_conceptos__tipo    FK CONSTRAINT     �   ALTER TABLE ONLY public.tipo_liquidacion_conceptos
    ADD CONSTRAINT fk_tipo_liquidacion_conceptos__tipo FOREIGN KEY (id_tipo_liquidacion) REFERENCES public.tipos_liquidaciones(id);
 h   ALTER TABLE ONLY public.tipo_liquidacion_conceptos DROP CONSTRAINT fk_tipo_liquidacion_conceptos__tipo;
       public       postgres    false    2661    251    261            �
           2606    561939    fk_vacaciones__personas    FK CONSTRAINT     �   ALTER TABLE ONLY public.vacaciones
    ADD CONSTRAINT fk_vacaciones__personas FOREIGN KEY (id_persona) REFERENCES public.personas(id);
 L   ALTER TABLE ONLY public.vacaciones DROP CONSTRAINT fk_vacaciones__personas;
       public       postgres    false    227    2611    272            �
           2606    561944    fk_reservadas__tipos_datos    FK CONSTRAINT     �   ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_reservadas__tipos_datos FOREIGN KEY (id_tipo_dato) REFERENCES sistema.tipos_datos(id);
 P   ALTER TABLE ONLY sistema.reservadas DROP CONSTRAINT fk_reservadas__tipos_datos;
       sistema       postgres    false    2667    274    276            �
           2606    561949    fk_tipos_reservadas__reservadas    FK CONSTRAINT     �   ALTER TABLE ONLY sistema.reservadas
    ADD CONSTRAINT fk_tipos_reservadas__reservadas FOREIGN KEY (id_tipo_reservada) REFERENCES sistema.tipos_reservadas(id);
 U   ALTER TABLE ONLY sistema.reservadas DROP CONSTRAINT fk_tipos_reservadas__reservadas;
       sistema       postgres    false    2669    274    278            F   �   x����j�@��y��YAB��ԓ��@I�h�e�ua���;}��Zr�lKa/��3���U�Zo��6/p�����Yg��(x]<oW5��O`%"�)u֓b�F�{q�K�'l贶�
���F(�?f�����6r%��w����Yb4jQN�ڈ[�����F���b|�-,��F:�{����o$5;%�:RH	��%'�������ZK�9����^�}�h��      �   �   x����j1��{
�-%[�S����k�];�Ry��yK��/���i��>aZ��^/����t�\�o��|�l���>w��Bc�h1��S��T��8`CRu��m)��8�d�#{f.ƲV�ݬ66	��V[�����b�)k,���h>ǌ��6��e��h>��$̖�B�
6���<����St��Zf��,O�S�(��C�9�:�M�H�"�&�}�2ٶ��h>��0���}s      H   :   x���v
Q���W((M��L�KJ�K�/Vs�	uV�0�QPwOJd&�kZsqq ���      J   �   x���v
Q���W((M��L�KN,IM�/�L,Vs�	uV�0�QP7r�p
S�Q05 =�P����5�'Q��� f�n��C]���4��$c�M2�:b�M�7���71���(1�*h��)�a� ø� ge�      L   �	  x��Z[o�8~��8�Aa�M]�$�n1p3n�A�q`�Zb\�xD)h����<������h��L�,��M������lr�	Φ�>���G�?�����<p9>�<�Ao�ݳ��0+x���O�8:������?�Y$x�ҽ���"��<�rH�l�9�y�s|������s���=��\�bF�ӄX�,���_����5���<+x���R�>~�)j:�����|�/�G��X��X�w����e>�3��Y��w�{��23.Д��%J�%"�A�(X�Đ�y�<�}���=�K`=GXп�I��Cy�����_8r��.�)�]ͫ����"���u��E� ǉnX�f�T��H����Dz�o�kP��I�'������dH�[�L�	t&	͔
�0t�,Db.V\��cˢ9)0��v�|��Y�r�@�1Z�<`�$o>ӖXy���H��J�N$Fb�g��|�8Z[b��ln#�,q��C��ˎo��L)��Pa�[�0�)Ly��=OD���u*}����2�Ҝ �q� 4(<�#�T7/��4ᢕ�c\�x@�˨�J�,y����.�i�"�pb�qy�\�z	_���<m'�ɚ����vS���&�פ�zF.Gk\�$�t�`���Xk��(3*,
���%]�]c��+{�+e�U�w��(�l����.��l�l��2E�\	�x�Q���M�ha��H������g�DVi����ډd2�6�Q^���z����G�pԐa6>U|����bi��4�y��]�R!#̈́�Z^ B�R�� v����e�-��O��1O,����p)~��*������b����5E3m��#
�<�W�e X�-�B��=�z4�/*`P��������" 2����J�FjT���2m�m���o5����g:��Hx�.]��U�7�!u�աŵ�\[_�\W]���ˑ��ˉ���e�B�pk�l7GM���l�dEw�b쥴}�u��;]�Խ�h:\��܌g7!�� ����nQ���w���rܵ�m�T�JYN���B�^!��3h7����-@�$�lE�A����:A;�J�[�s�Tf���o�l �i��L�I�TtUCB��@�������O?m��\��B'������4	���Y���e�v�l�vUe �W������G�L��b��wm#��LP���������p�np�$�3*���y!|V��X`S�I��z�����,�U1D���:�`��M?�~�CK�����[Yl]ǐ?f�i��B7U��z��=�����hI�����K�s��y�g�{�M�)cFo��^g�i%�ʼ]�jg����g���A*��3��K�Ls�c1\�Ӳ)�$z���\ep��ˈ��v��u�����9U/�nW�Ђ�@{K1������٢��ξ�����2-�H�Ԭ�S1��d�®�*���-�0a�5%�6�� 	<�3�0b�֬���I��������ե�)'M"���P[�T�|��۵q�Y�����&iW��wI�sjhPyr뺐�^E��7�foKV�SL��Uɳ�x {���諠�P�@��4���{B;�K^mb��j�����{�3#F�+F?w%�3�"��1g�E&׹u��L]�/��r���b��TK�ғl���K�:ԇ�żG�hm }�*�,'��Ki6��@��"�'�	�i0�FJJ��|%���4i�'�v�r�s� ����2#��g�����cskBxb<zMMssfhu�}�	�@S�qz�z��%�7* C�]��^k��8B�FT�(��;��4�C�o�+����7*�C���_c�T�[�J���P�' ��{RC�sߥk�o9]<�-<�i[#�2�eɣ{�Q3 �$��ُ?�;n�d[�)w3S�zW<���05�H�=�C�zsw<�B}x��v�Il�5.��8��9n}�u���Z�<��ܸU����|ɠ�ӌ�!�:��!����*^�Q��\�W��������D��&�~��Y}wUџ�1I�j�������m4�e1f4����ٜ}E/�/��2��|&}!A=)�[3�o��m�b�.��9
ϗ�<�p,�~���_=���y����-�ݏQ���u�!�$zK>�Vg][�z�<�6�j�L=���=msmg) ��S#��c����.r,���e�E�}ܝ��� ����(�0d�7k�&Ž�Rc��࣡.�`�Q���ƪ鵺�vy���C��S�K�ۙd�UóDҒik��E��Bu ]�����A�Vj�e ����/�ȷ�U?��L�gy���{�X6�ݣ{!p�� ���e}M�w�b��~߉Twbt�|E�h�5>l���o�D�8B�Ǟ}"���� ��|k��G��dc8���x:����g*z:���Ƹy\�I�D��i��M�z���0�Ն	>	�Ǧ������K��q���� "�o3      N   
   x���          O   
   x���          Q   
   x���          S   
   x���          U   �   x���v
Q���W((M��L�K-.IL�IM���L�+�/Vs�	uV�0�QPw,�O�LL�<�9O���ʔ��D��T�Ҭ��ԁ
|�2��|�R�����P������������������ ,�i��� b/)#      W   _   x���v
Q���W((M��L�K-.IL�/�O�,��I-Vs�	uV�0�QP��)I-��OT״��$^�P�sb1P�d��@�.�e�Eəp�\\ l�:	      Y   l   x���v
Q���W((M��L�K-.IL�/���,,�LIL���Ss�	uV�0�QPp�s�t�qU���tqt���S״��$�,#�YP\��o������ ƒ>y      [   
   x���          ]   
   x���          _   K   x���v
Q���W((M��L�KO�K-�/Vs�	uV�0�QP�M,N.����W״��$����-575��� ���      �   
   x���          �   
   x���          �   
   x���          �   
   x���          �   
   x���          �   �   x���M�@໿bn��G�e��&X2�]��%ʂ�����mѡ�y�x���%��,��8\�:87ݽ�5u���˱����`#�
�h���:��}���4��EE4q�0��
0G]�����Q�S�����\�!��F���%&���}jh/� �}�k���LF~~�FS�J�T9,L���f�dyp�'"�~�      �   �  x���=k�1�=�����%�Ht�ᠤФ]C^8H�%߿��x�=J�!���ٲ��r����q8��?��x:�>��������緇��������x�^N������뷟7w�O)��!���%Q��>�:zHC쇩Q��"�!�d��#�d��\�D�dHg5q��77�w�X,	�E�����Uf�!�c�g����!VC�B�p�T#Ⱦy}��Fj����1��Z	i�NZ��v�d_���8��Z %��{'��gl�ߛ{���ثJ�+Ķ�~�ISC��UZE�KN���E<C�+�?�	A9�~�9�:r��Wz	!{��Js.�B	!uQ����If܋�Q,����dڋ��q,$�""I=��$�"��5�\��M�Q���@�R?YG]6�琽ls<��Ѵe�w#�{��-�6`����~E��G�M���"�dM[�*itXZYA(��ѼdF��"�<���A��;��͋]ݳ�-ֽy��3�F�m4/Z� �줌?%�f�I�P�l!Q��(S/��(s��D���%��d^��M�%��d]��M�%�ܤ�Q�u�2/�p�2���(s��D���%��d^��M�%��d���-�9�ܢ,Q�&u�2/�wi�E��L�4��+����I��~2OO�_,�D�O�y��'�<��2O4���7�8O4�d���~�湷��y��'�<���e)��:���d�F�~Q���_�y��%m����eJ��WW� �"K�      a   �   x���v
Q���W((M��L���,,�LIL���K-Vs�	uV�044�QP�A�)�&U�+Z�e@������!n�1�gCPa#�"c�Y>�Y�橣+��$��`�0 �L@j�SJ2Ss��R�5��<���!��\�R��=f��t~��1C����5k;�D/�y�-,�2B�:��������SFx|�� 7�-      b   �  x����jAD���=& �L���,9���@(۹�D�A`,���ng��]�7=z��FO����׻i��2=��|<��Ͽ_Ͽ~�Η�����������e���ps;}����T�ƿ��������]�m7�N-���������M���,
N�$+�i�d����5vV�Ky7(R]�"�U�}�X+�fٍ� ��6(6�vO4(.�����M�Xl�ɶؘK&����Y�ؘ)���yS<#y?�	J�1St�3ي�y\����]Q��qE�=�-	d���lqѮd�ϻ"G)F��Q��5�S�bc�����$�-L�`K�k]���4Ż6���Ɲl���Y���Y���YP��r���,g��rV8?�p~���I�R��Ƶc�p~dp~�h�gA�ςf8?Z��,h���gA����ς*����9��58?Y�u��-p~���٣u8?;��'A���YP�� �� ���gA3����HZ�o���ہm��@����,�Sw�c��Y���YP����y�:�Y����u�:��0u���9P/�΂*Lݩ/�^�΂�����Y�SgAL��0u�a�,h������0E����%L�9L�5�:�a�di����Z�]��zQm���ea]��,�+��uE ���d��9ʞ�"Gٳ�xj����0u����Iп�)@��tu�oJ��      e   G   x���v
Q���W((M��L���ON��LILI-Vs�	uV�0�QP�	�r�S�Q0615�Q0״��� l�      g   E   x���v
Q���W((M��L��KL���K��LILI-Vs�	uV�0�QPw,JO�+���W״��� i��      i   �   x��ѽ�0��&�ʗqr` 1���R*i-� ���|1[����:����ey��K���	�S�
�U�@��	�r@���h�m����< �x-m�����V|�����@���'��|B�q�vB0a��y)�D=@I�4��<����Ԗ�D?�P�ۯ#���,�i��TvB��t�	ىf�r�Ez�~)]oP�� �Q�x      k   A   x���v
Q���W((M��L�+H�,N-Vs�	uV�0�QPw,JO�+��KTG��kZsqq ���      m   �   x���A�0໿�Y��e)�)hC,R�/�a06s��7GXA���c��-�r.!��#��*x�hY�U�4\vYE
���O�J.����H�� �o���?�(���ٔWY6�z���Coj24'#g�"��ٷ{z�7���SN��G�4�|�]�+�J�ѴWkC����nI^����I-m�      n   �  x���=kA��~Ŗ	���}H��\ jڐ�� (����Mq�u���6�=s;�.���y���I��ߏ�mu�N����n��v<����r3_���Tږj�,�?�R���U]�?��#Wgp{rg\2u��Ն�&L�:�[l2��Z�r�����+;��xi�d�;'R1<��F�b4z�����B�dK69ޞEۂG��6"%��A���Km�[/���ks��ΰ���"Y���_�
-;��Y���lb��;�Yn����6˭8zc+<Y�_�,�)F�X�Ҕ�{,Fiʁ�H����0��Q��`t�f��Y*��f������,e����d�ܢ,e�(KY�m���m�q��������6F2�zV�.UFriF�t*����%_��y��^_j/&/,�B�:�.�w�0��8��0yW�.}��{���
�E�xU�N      q     x����j�0�ὟB�L�Ŷ,��"CI�I�-N�"P����wF���~���H�6����M�ݻ�>�?����x�_���c���Z�}��n['_X�6ӿM׺������кLsr5,G
+4�T�r��(1�4O��,0����)ه��(��z�d'�ʁ�l*3�K��sS��Q'�ӬL�,�Հ����)�t�0�Սt^1�b���*8J�2����6>ySl�I��)��Y�ú�1�%���;�)i0���E6�1Mk�_�@       s   =  x��XMo�6��W�����^��|4E�-��z)��j![�lH~}��()���

�l�ޛ73��^,/n���ݟ����ȳ��U�rc�ɗ�����'s�̮��&���E�u9�+\f��`��1'�+�T
�4c�_�j�NV/h���|s�M�͉����ѿ����h?�?:����o�RB04UR�N\�p	~�����Aស�̺�&�ҭsS���f�*��f@�9�s�"�bx.fn� �#6R8*�'Oe��N(~w�(��M.���޻�W[7���V��f@�9������(�̀��� fN�tP1>���a�K�V�|�o��V��I��(|d\Bt+�m�E�\�K�k��=��������E���Y]����Ь�<��ae��
��gn�s	0~�?O�_��R�P�v�c���F���D��/�ɲ,�ʮ|ؿl��U�? ��6�"�I��a",��������N�-zj@��������Y��ͪ�5�*�6��qʨb�v�6�9\�2�8��y8�<U|p���e���|��`��¡�p�9vv�G�/:Yƛ���;ASN�t�e ����1!UPj�%"a�`�D� if�)���U��Q?�~�S���m�e�t�!��D�S�4:t���|TS9�_tBW��T��o�W��&W�]=�ʾ-׮��1@'��9p�4k�{�s��	s^�W-r��T��9��t�D��=����]�`cޅ�k}`?� ��@�E�j�b�d���=��
H�ǘ�h�O8��t�{�G��"���5D�`��tq�ֵ���yo���KML���ǡ�=�\���F���n�ɭ]�{i��?1~�v;�/�Ů�I0�1�w���ԃ�e�c��~�o����)>�cOI�\�������|X�<��!g�Ǌ�M�O�����Ԩx�y[%g�����.��n���w���Aď	@�9�}��P"��� ��*@��T
���w�E�k?�,/�P
�MN�;��PD�0\�76G��C���XX���;<z�Ԍ)�_�w��G��_�x��9�9'�4�ƎO�4 ��ig�I�7����_�e���� �����z�qf���L�G#]��1���z�C/_����6e��.;����!��@��X]_7hv��=����E� ��>���C�e�5�;"7�V�>�v~M|�W�)�c��V6�������w�@$�OA>�Q 5��� ��ah}�u� ��&~�0"u�����z��vx��/�j���-
teW�MA*A*D6l�p�b������gC��4|:vr�?¾�      t   I   x���v
Q���W((M��L�+H-*��K,�O��KN-(�/Vs�	uV�0�Q0�Q0�30�Q0�Դ��� �n�      w   
   x���          y   >  x����N�@��;O174!��/�'$mRՔ�}h7uI�[�;&r�I<r�%��-��y���t��F�:HR���	jڔ2�����*����l�������̤�p��� ��;<�ZZ,!�0X��u�-Vh2d�'�0�,u�+ڐe�;Ǵ���7���)�env��@Y# i�~������t��wpA[��1����y����[�t������	]:+�H��o�|bA���O�����!��5빊�XZ�gNz�`A�vz�K�����$-��Ўg�?�{��Tb�!%��5���T
c�?"$Q0Opa��Q�~�n|08��v      {   �  x��׽J�A��>W�
A�;��V)!�I���E@P��3�Z8����������i�N�����������v�|��O���8ܕ�L롖�0���y���o)5>�?�v��bϒ/�����t����7�� k�ƚOc}���i�3RZ>�bHJϧAVLI�i��)�M�4LIɿ�~Ά=%�6�9�OI�m�s�T6�z�P�4��OT6Ҧx��i�6��M��%��\zZ�i��UD؏���
�u�ڥ��$�.U�z�\���*�$����6pL�T��&���*�1rL�Tz��c���sS-�^b�j����j�t��c���5���J[S-�n1xL�T���1�R�1/�2�����j�q�r�2���W.���.��:�.���6r�Ri�m��� ���K�}�._*�o�|�4�^�|�4�^�|��F7._*��#�/��;�/���>r�Ri�}��� ���K�A����(�o�qC��Se��*�V����      |   
   x���          ~      x���M�%Mv��y�����!3��<Р�i�%yjP�����e��Y�Fo�1�I]��'w擑����_�����?���_�������O��_��������O����׿�����߿�ۏ��_�����?�Sm���~��ۏ�����ۏw���������O����������Q�H��4?��_��������K�������|���7���>��*��N=��w������֯����p�dh��q��]�qN}N���P��=�;��k�����s�@��N���/���Z�T�7Nѧ}�k�w��?���U����u�v2�y�]�������?̝��~����.�7����7w.1+��Kp]��I�\��T���cF3Ԉ�P3d4!�S�Ho�hFJ1�*ǌf����zV�1�j�#��9��y���V�C�B�9ҝ����W��yUr�?s/-O$��R�ϩ:�D�yΩ�q�r��]��j�:��'�:�R��կyB��]	j���ߕ�r��������ߕ��wuN��|��U�]S����95�]S�\ϔ�n�#Jw.2붐�ď�.�W�W�^"��d޵���$�w���+��]W�J�|��D�r2�O�b��:c5��!��e�sj=}�;����}�R\`R���
U�� �ĭy=r�;҈��q��d�',0�FJa��H9.0��Cո�`�5���V����`�7.0*�C��`�U���Z̳��1�j�<k��y|c�5T�y�P%�YC՘g�b�5T�y�P#�YC͘gU��g��<k��rȳF*1���<k��z̳�+1ka�ߑ&�X�z�g��<+��r̳B*ȳ��ȳ�jȳ��ȳ��z�����֫��g��g��gU�gU�gՐgՑg5�g5�g�
��<+��<+��<+��<+��<+��<+��<+��<{N����ɰ^��;'�z�_�\���KUb�RE�TC�TG�Ԉy���ۻ^~�RZ��B�ԋ<+��r̳B*1�
�"�
�!�
�#ϞS�W����ׯ���]�s3�YAe�YA�YAU�YA5�YAu�YA�YAM��sj��ҝ�}��ҝ����ӝ���ҝ��p��)�>\�s^��/�y��Z��a}���ɰ~��ɰ�z�Υo��.T�yVHyVPyVPyVP3��|(�\�֚�*n�QT�Zc���(*T�()V�(*V�(*V�(*�@��+�@PR|�`(�@PTx����AI���

_ (*�@8�>�#aӲ0��ϩu���Oo-��gش|N��*|W�j��Ω]R���*�ԋ���k�#|W����Ω�;��wu\ʜW���9��k��5�]�S������p?��v�J+
�+����/��~)��/�T㪣�Vձ�(��UGq�x��(��UGAe�:
�`�QP���jXuTǪ��V5��(ÃUGA�XuTª��
VU��(��UGA�:
jb��Z�~�a���wN��=�ae�|�d�m��\�֮�K�⪣�:V5��(��U�sj���~P�J�ԷߑR��2R��JL�B��-��Z̳B�ȳ�ȳ��ȳ�9>!�
*#�
� �
�"�
�!�
�#�
j �
j"ϊ��yVP/��2�*���&��9�RG�s2�ԑ��^��뺞�kI.�9�-��YX]�{���<+��<+��<{N�^�w>��|?���u��w��<+��<+��Z̳B�1�
i �
j"ϊ$�2�
�*��:��&�x�� �
�E�TB�TF�TA�TC�TG��D�=�v����j�O�wN��>)�9���|�d�;����Րg�c�҈yVHy�������lv��;p�M�~P��N�~G�(Ca���(#�Q$F��H��Q$f�	F�
�C��!�¤CaR��:��&��9������w��;��z��/UF�TA�TE�TG��@�=�v���St���8�JF�����z�*�[VT�}b6T����b�E��'���O{�(*�>QT�}����DQ����b�C����b�s�sFQԐ�V�t'~�� W�Gy1��W�=�0�MP	#��1fJPS6���P*�l�aʆ�:�ljb�F9�]&�l�S���A���!��)���`͘�qN�_'�	�k�N���~�|'l�qw��:E�ݱ^(���4�z���f��y�ܺv��+�%e�̹�s\/<�ݬj�~G�X/T�z��z\/҈�B�q�P��녂z�^(���BAU�
�a�PP녂X/��z��Ƙ�l�녂JX/T�z��
�U�^(���BA�
jb�P<r�X/T�z��2�
�*��:��f̳��:�;W��[���v�����kx���gϗ�K�~Gjȳ��ȳ�1�
i�<+֙��g��"�
*!�
*#�
�!�
�#�
j �
j"ϊ5�yVP/��2�
�*��:�&�X�~�g��g��gU�gU�gՐgՑg5�g5�gϩ����A�7�Y!�&���MU�gUc�=/�^��;RG��@�ԌyV��{b����2�
�:��&�x�� �
�E�TB�TF�TA�TE�TC�TG��@���YA�ȳ��ȳ�*ȳ��ȳ�jȳ��ȳ�ȳ��ȳ�Tz�g��<+��2�
�*�Zȳb�кP�;҈y�P3�Y�7�	y�HoȳFJ!�)�<k��j̳�1�j�<+�u���g���1gQ�.as��G6���#�CXP�aAQqd��0�QQqd����FE�8�CHqp����pE5��TL��iX({�e� ���s�wR�K�n�\�z�	�x�e��&�P��w%����j{{����x2F۝��*c�0�CP�?�q���0�CP�?���T�;b�\v��;W�ݿ��s��_s�dٸ�W`ϗ���e9C��,g������r�JqY�P%.���e9C��,g���5Ⲝ�f\�Ժ��;'Þ`v�ҷ��\:��ٕ3��bfWT��
��L�[����4�,'�q�է�7.�	)�e9!�,'��e9AU,�	*��STlxa�^(*6�PTlx���<+��<+��<+��<+��<+��<+��<+��YA%�YAe�YAU�YA5�YAu�YA�YAM���u��A�ԋ<+��<+��J̳B�ȳ�jȳ��ȳ�1Ϟ����~E�%��
�ˀ�|�=���
f��K?_߫qB��F���֪�bة�|vj�8��H%>�)�M5Ʀ��yDP�#b}cS������TCal��06�P�j���A<�
cS���M5Ʀ
cS������TCu<�j�yDP�*�������TCal��06�P�j�86�Hql��:�G5������qlj=X�f�j$�M5ƦSe�I�vTj�PLي
)[I!e+)�l%Ŕ����S��↘M�m0ݍ��v����|�7fE�쯨�������ʝ�U�l�8��H->1����z^t���N(t�:��Z�.������c�?m(��6�E
���/���xA<�j�9��z1.�Pm(��y:��b�W|@�60.5��n���op������ϫ�%��b���+1�X���J�9�0��P�m(�6~
���߆jq%FH=��i`%�`V�����%�CM$�sjb���0��P`f(03�
��f���S�� 3Ca���0`�P�a(�0l
6���6�l�ŀCa���0`�Pk��d�l�WN'�Z��w��뉶�f���W��A'��Uݾ��=2�ź_!u�MTlU���&�K�o��Ʒ	�t}=�������]7�\����;Yfw��@0e�P��)U�C��k?R
d$2�*2R
d�8H��?
d(2�
C���@��P Ca(��0ȼ�P Ca(��0�P
d(2�SeϭJw�V�qӣ��GC���QQqӣ��GE�nfC��'�Q�����=B��[1�Qŭ���[1��VLEŭ���[1�b*����    �jl*&��[l*&�X[��X[��>̯y������s�q���w��nU�Ӎ�jx�1RO7F����H#>�jƧA�ҷ�O7��E�f*����3���%>s��g.C���e���5�3��f|�Ԟ�u�l_�t��Q���e���U�{OCa�V��w%ݝ�த��lX86pƷ��V%]�s��J�|����{^؝St��s^�yawΫՉ�ܹ ��g�Hسc�ߡ
j�����#��xN�B�=��ߑ�>�Pxa��>�H�}����!M��0�G
�#�������n3��PxKb> ޒ
oI��$��[�s�縩+���qS����s�ؕ����cW~8{�X�tTx�b(�p1
�5�ϩ]��\9�V��Wn�u�޺s^�ywN�={��ɰg�ݹ2��cwΫ]Rr��ق�[���U�Pتh(lU4T�5��v+{�W�#a֬�0k�P3��s)?1f�1[H�5k(̚5f��"f����~���P��k> &�j"f�S{�ؼC��ق�\Ca��0�P��k(L�5&�
p5�t�s�#���� �;���"/?w> ���\^Ca.��0��P��k(��5�Db?�֋�r炼^�ݹK쎘�*#�� �*��xN���0�v�c;���.�8��Hql��0��P�a(��0&%.���I���0�9L�P/��0L�P&b(1��
�D�a"��0Ca���8L�P/��ϙsI�Qa.��0C�|@�81G�'�Caĉ�0���#N�'�C�؅�A{� =CaО�⌌縯�'��Hla(�0T��]Hq����`#a���0��Pla(̠^��m���rWQ�!>`¸Ca܆�0n�P�a(��0�m
�6�q���a(��0�m*#����sAbG����tz�1���
C@U0�Pb(1��� ����.�Xy�(L�3��	��\��Q�S���墂b���P.*$��
	�Bb���X.zN5��
������X.*(����rQA�\TP,=�����$!�:IP�N:�&����Ӿk��[��X�tN5� �S�5Ȃb�9�Y�,(� �5Ȃb��X�,(� ��#:k��Q�YP�A�5���dA�YP�Ak��d���(<���-��	���V��Q!�dTH(=�:[X�%��bɨ�X2�N�2?�E�;KF�dɨ�X2*(��
�%��k�u��b���X�)(�y
�u��bѯ�X�{�s��>sT�>=��O�?`b��8*V�
�է�b���X}*(V�
�է�b���P}z.eV�
�է�b���P}zܜ�gT�
�է�b���P}z.T�
	էBb���X}*(V�
�է���UX}*(V����SA������>�O��SA��TP�>�O��SA��TP�>�O�΍է�G�X}*(V����SqT�>�O��SA��TP�>�Oϩ��SA��TH�>�O��SA��t�K�>�Oϩ��SA��TH�>]?ǳ�@��8&V�
�է�b���X}:�o[�է�b�����>�O��SA��TP�>�O��SA��TP�>�O��݉8]���nki��9�6��opק�+����;�է�X}*(V�
�է�b��9���TP�>�O��S!��TP�>�O����yL#��TH�>�O��S!��TH�>�Oϩ��~?'6���C;F�tCa���؀n(l@76�*�Y��,EK��gǍ�RdA���f�"��Ȃb)��X�,(�"��Ȃb)��X�|N�"��Ȃb)��X�|�s.,EG�RdA�Y|@�"��b)��X�|NU�"��Ȃb)��X�,(�"
��Bb)��X�,(�"�S-�"���b)��P�l(�"*�")�")�"	�ȆB)�y�@���P(h(

j�P�P(4
�BAC�P�P(�����P(h(
��BAqT���B���P(h(

���°RC���b; #��������*��u�'Rl`$�0*O+O�+O�+O�����P�<5*O����x��|Qyj(T����SC���P�<5*O�Pyj(T�
���B婡Pyj(T�
���B��9'T���B婠2*O�̨<5G��SC���P�<5*O��SC���P�<5T�<RA婡Pyj(T�*V��J�'R�<5*O��SC��S!�Xyj�Xyj$T�
���B婡Py������B����<5*O�Pyj(T�
���B婡Pyj(T�
���B婡Pyj(T���sG�8���SC���|@T���B婡Pyj(T�
���B婡Py*���SC��S#���P�<5*O+Oţ)V�	�����<=�r�Atw�R1�**�M�]�s�ATQ1�����b5T�ATQ1�**QE� ��D���bUT���ATQ1���s�A�U�ATQ1����:�D��9U���пn'6B��3�>6B���FhCa#�1���[�	2�[��b�
#�[��Э�P�Va(t�x�ωn�B���X��*�n�B�
C�[��Э�P�Va(t�0�U
�*�n�zѭ�P�Vq�s�P�Va�
�*�n��[�9*t�0�U
�*�n�J�Va(t�0�U*v�0�U
�*�n�Z��Ǖ_s��/D�α����Ph|a����H��b�#�����P�u`(�:Ϲ��^��:0z
��^�B�C�ׁ����P�u`�O���P�u`(�:0z�0�:G�Pto(�
E��Bѽ�Pto�Xto$�
E��Bѽ�:��Og ~$��E��bѽ�Pt/$�	E�Bbѽ�XtN�_ۯ��+�Pl�&(�_�����k�b�5A���؁AP��pNMv`;0���bA����y��8*v`;0���G�>�� (v`;0���bA���ЁAH�� (v`8�^v`:0��$�H�� $v`;0
��BB�s)���؁AP�� (v`8���؁AP�� > ;0���b�s*���؁AP�� (v`;0���b��sfqT��pNv`8����Q���؁AP�� (v`;0���B�s����؁AP�� �����^޿�޾������������5ۉ���P���T��M���������l�؆9��N��M������M��̯�O��mc|���]�����<_�H+8��|q�U�
Q)կr�5\2���ڋ8��t�[^��#�ٱ��$ߏ��w�e|���}.J8E��m���~�U��Y���ído���{W>�m}����5����h�����mB[_o��Ɓ��L{K����g��^�~�w�7]��k������Mw_v������3~���w��*��\i���upOM_���"�7�j.�=�F��4F._��h�ј�H�7�]����'o4*)��7�����k|s��FE�Qy���M+ܜh�����5� ���M�W:�A�?����+�������U���𾪒��A�l���W?���xM�O�)�V��p
���4����6�t�������@����O���3�\�?w�n���k�����G�֑H^u���]BkB��d~-V�Ph%c����ײ���?	��揆��ϥwo���&�[�{�L�A�[R�ojĖ�FBKJC�%��В�Ph�h(44�?
j�������Ph�h~��ď������y�%��l����Q�ӣj?KR�;^5
���WM�«&C�U����Px�d��)z��;�yGz�K+C���cr4T	���Yq"Ր��br4T���P#$G#͐ф�~y��ƌf�3��r�h�j1��ǌf�3��f�h��e����P)�!C帡�P%n�2T����é�z|85Ԍ)[Pk�9]�������̲���߆���t'�G��FBŦ�P�i�X�i�X�i�X�i$Tl
��*��4j#��HC�6�P��4j#��HC�6RP���Bm��Pi(�F
���BA��P�h(T!
��
�P�B4��*DC�
�P�B4���B��FXh2ҌM���^�YA��gO�Y�����<1�� -  ����nc�E�r�w��]�G��
ӣ��Q�Ty0��P�d(�i2�4��{��0��P��d(�i2�4	�Ŝ&A�������e��+Ԟv1�P9��	��}:]��P�E/��>؆B��s����߿��u�Fm7����|ߪ}~Kݽ�.Qo���TڭQ�lFJ�l��QeTG
��:RPՑ�j�I�H�r.�h�w�0��ؠOPl�'���{.�;�_�������eooy�P}���R��,�����@$AM\����0q]?��z���S��)ǥ
C��Ta���Ԃja�B$�uE�w���Ԃ��Zl��wS������e!e�[T��eA����P#�z3Ԍ���|�;�_�*a߲�2�-�`���*Cհ*��eGA,;
jb��J��e�yX�>��׭&����=w��ݸ��)���9�v�;��z)�/-�M�`�S+��;'�z)_�\E�K�K�Y	ӬU��iV��1��9������fy3���)Ο5R��XH�XP�XP�XP��*��I��¤WCaҫ�2���
���*������0��P��j(Lz5�0��P�j(�g5TE�TC�f�
3U�������j(�T5f�*�<+��*��:�F̳��Z��j�oHu��yVP/�R̳B�1�
��<+��<+��<+��<{N��Yw������w�;S�;TF�TA�TE�TC�TG��@��D����YA�ȳ��ȳ�*ȳ�jȳ��ȳ�ȳ��ȳ�Ԯ�s2��<�9��/�9v��K���]:���0��P��j����~�u�;ҋ<+��<+��J̳B�1�
�!�
�#�
j ϊ�h/��2�
�*��:��&�؜� �
�E�TB�TA�TE�TG��@��D�=�3�����_c��+;6�0^*q��8\|@NG����rA���І�Ph�a(��0�p�#ʏ��^Y�;��]B~�~�^Y�;����:߹߬W��N�Z���T{P�r^��G%��s*�z���Жq=�z�
ߕ���sj����]�s*�:����]	j�:���¿����JP	�K�1(TP����wu<u��-��
��v��Ω}�ynPu���������n���Xx<�vY�D]U������(���GA���(����£�:5��(���GQܙ��(���GA,<
�b�QP���Xx��£�&E�~��(���Caȍ�*�i�B�.C�o��^�>1��
MF�&#�T�}p��̝?ݼ�Wb> ��*�+1R�Wb��h,(t�TBY��b'o�&�bk#�������P�����#�FC��YH�+C����
�Px�`(�B0^!
��Wf)���NކB'oC�������P��m(t�6:y��������P��m(t�6:y
���Nކ����;y	������P��m���[�j����
�*�Z̳B�1�
i�<+��<+�P>ȳ�z�gU�gU�gՐgՑg5�g5�g�;�yVP/��2�
�*�:���9������y�^M�;'�z5������ȳ�jȳ��ȳ�1�
i�<{��f��z������W~6}w)��sȳbo��u��H#��b�5T�#��4�d!�8Yl�z0YP/F *�<k��Z̳��1ϞS)c�Ql��Xs4��5GCa��PXs4��5GA�9
k������h(�9
k��d��s����w���w���wR��xq'0�wn^�ɗ��`κ�*��aκ��jbκ������R� *���J� ����Z� ����F|h6��BZt�ʾ7�~?������8�ݠ�zV
U�����\�������q{걛��+T�(BCa�����������u$�
51��PExN�ԾW�mu�Q��ʘf(L
TŤ�_���aR�9����{�&�;�	�a��mb=,}?������HK���XzԈK�B�q�Q�?>q�QH/����(���GA5,=
�c�QPK���X��V�bU@P	���X8�ZB�r����A�/}���A5�/�c}AP��Z������Ω�J7\������JP�+�$��r%��+A%\��q�T��JPA5\d�q���EF�0<����EFPA,b
�bSP����X���"��&1ϩ=��Υ/�A�F�����Aφ gCaг�Z|�>_�[�~Gx�=���8��Hqг��g#aг�0��P�l��<+(zT��gCaг�0��P�l(z6=�!�
�#�
j �

���[ Lg6�3
ә��̆jȳ��ȳ�ȳ��tfA5Lg6�3*Ng6R��l$Lg6�3�!�
��<{�vU	�;�3�7֘�l�8��Hq:���tf#a:��0��PyVP��,���̆�tfCa:��0��P��l(Lg6TC�TG��@��3�S)�A��R�Р��YZjhP-��ՆB��s*?hP��������A��T��Au:~��T��A��Tj`�i:^��L5����*���Sc�l�;Ifb0��0��PLo��GyAu<�j�Q^P����Lw��+'�|0��PLo�8��H%>�	������+|���C�z�>��������O�P�o��O�H����b?}#�����O�P�/��~��B?}C�����O�P�o(��7��
��5�O�P�/.>hvm(4�6c c���E�9�3q/q���:��9�{�\��s�U��F\�?/Z�T�"�f*��b�_P).�)�e!���/��eA5,��c�����N�|�)���j��w��eA,��b�_P����X������&��Ey�eA�X�T�ڗ�
־հ�%���/A�}	jb���݌���ѝ�aw3�s2�mw�Υo���tP5�Y!5�YAu�YA�YA͘g������w�yVP	yVP9�Y!�BJ#՘g�ԐgՑg5�gE��yVP	yVPyVPyVPyVPyVPyVPyVPyV��x�g�"�
*!�
� �
�"�
�#�
j �
j"ϊE�yVP/��2�
���0<\Pk��|�6��D��+�mE������뉶�K�R��������G�;j�}d�8��H�}$���G���#C��Gbwa������G���#C��GF����g	����W�>2f
����G���#Ca���0��P�}$��a)�°CaX�9���lE렂`+��`+��`+��`+��`+��`{N��;�'�4r�[�.}���.���.�j�[[�+̝&Y�s��R�K��jE�'.�
��BJX�T�B��
j�+����C��`(�����pT��#����p8�RǠKS��A�� KCaХ�0��Pti(�4]���A�� KCaХ�0��Pqx����F!Mo4�7
��7�ם��7	��ፆ����7)o4e��h(o<�Z���zA?Tܺl��u�Hq벑�u�Pغl(l]�.
[���ˆ��eCa벡�u�Pغl(l]6�.
[�ŭˆ��eCa벡�u�Pغl(l]6�.
[�ŭˆ��eCa벡�u�Pq벑��e#a��1�Ii)ޛM��\lC�xo6�b
#k�����F���fC�xo6F�
#k����j��l(��5F֚�Vo�7*�{��0��PYk(��5T��Aad��0��Pqd��rYk�o#��R��0l�Pqآxq��E#aآ�0l�Pqآ��E��/[4ҋ�BA%,

��a��°ECaآ�0l��uİEC�ȳ�Jȳ�°ECaD��0"�P�h(�H4F$�]�h��<+(��F���zﱆ      �   _   x���v
Q���W((M��L�+JM��M�K-Vs�	uV�0�QPJ-H,*�W״��$F�POpfA"����2Ks2��3o���� @�2�      �     x���MN�0��9�w	!�?bU�"��h�~ba�c;A�H�9B/��I7�����'���U���r�$��h��=4�f��Z���鑘Ik��g,�PR�5�b�;���E�����a�!���s�:��� �B
��́\p�F���Icu�jt^�����e"զG��I��Q�� v��lȂ^1(`;x�E*aW�kn������M��I�D˒�?��cx>i�{y�e��MO:3ÑI;.'�)vq�2s�� ��S��ժ�S���Q      �   o  x���1o7�^��:'�B�p�3$R�p! p��Iȉ� *R8�?{+u�67#@��k��Q>������ç_N������?����O�������ӗ��?�������ߟ*�?���������w�'*D�/+�bu�=}�����n��u���U�^l��qqe�r��^z��L�=�fz�EEF+�]�ɼ���y�bqwi�%����y�d�J�
kN�*�l�Fky�X���e{ǻ�q\��zёs���ru�f�e$ݵ��r�\"���]�Ζks=���wm:_�O׬[ўr��t}���m"m�rIwm���1�/Qm��8$��B�,8#\Ĵ��`�щD�H�&���RtE��X�	a^��9�a@0Ѡ"�s;mRz�y��^j�y�`@l?t*^s.À��T{έ0 ���`�q�Pu.�|^�q�Z����Bl�J�l8 �ĸh����U@h����Wc��u@�\��"���s��s�怈�zs@��vs@�\�= b��1��1x��pnZh=o���`@��6�����0!*��R[έ0!j���.�s&�4w*�9WaBhU�fØ�`B4"�%׃��h^����0!Le��\sn�	q�TzrA����%�"�pB�ֵ_��1�aB�Nc��o<�V�sʱb�r��|���c���?�c�ì�r��p�Z��0���c��gm�X?�(_�C>h('��i~PPN8����tU"����ɼ��ɼ�Kɼ�ɼ��ȼ��ȴ�q	�7q�7��<zP<�у�1���j�!��Vɣ�Je:�g�Z�Z�sJ���`v|+}0=N�[m�vx~�'��ߤp�O��OCnu?�Fe<C^޳ױ�NDe<E^�q��^�Ge<GN�{��\lDe<I��hۆ���g�)��W�QO��4��\�a��<y9�s�{��&ʗ���	�`���}�r����� J����A�p);?�L�x"�p+{I�z�����e�,C��φQ7�o�~�;U�����o5ӟ�_i�M|��7�]f��������VȘ��2o�˼��-�&�X\�`Y�k(fq����ͅD��S%#��<�⊩�����A��Su����	�LB��]]Y�>������Q�ť�u�Qx�X\�n�lۉ��7����2�      �   L   x���v
Q���W((M��L�+IL�I�OO�K�K�L,Vs�	uV�0�Q020��QP�Pp�� 	�kZsqq �      �   9  x���Mk1���{L��}=���!�Ф��MJ��B����(+���j탱��<�����w�?������Ͽ���3��O�����6�=���������������t��'��'J��i����ї����wOֽ��E���� �C9�R�QZ�LA@�~���	R��R0�ô�Hg�0@.��b�b���@�?ƀڱ#努+�kFYXY�@�(B��	S ,��kYTmhf�Y��{�X�,U#��d��:�{��9U%z�'����5�,o�N{Ys�$�e�Ս^4
+���}��b��=�]0��y���,a2�9�Sr �R�]�\QgG�$n�ݮ���D!A��͊�3�9�=�[t7+Nh�U��KQ�cκ=Ң��p"cuBΨ����cgG�gv{�(����Đ!Jo�����f!���v��,]��*�-)��a%�A���f���X+%����jyn�oV��X��R1��Q�i�kF���_�mS<V�\�Ƨ`w��b�z�k��A��/��c� ��ws���'&�����5Q5��j�Vwh�X����[�We���} �f�      �   �   x���=O�1����Ф4w׷k���`"�j��	��i���nm�������Ӈ����{�_m^��mXm������G�4�=N��"���V�2#�GZy 0 Zq^����_�tE�	��D��I+�(1XC����"�5�Zh�`�����>�?�N!OdW���C`6��-{dY�5Uϖ�a1�U���c4���b��*�s�S���T��`�ܐ��M�=V4�P���Jg	��?�?Z�jc٪�K �ojם �0@      �   g   x���v
Q���W((M��L�+IL�I�/KLNL���K-Vs�	uV�0�Q0�30�Q0��&��\�$�7��4 SF�$`��
�,H4����L�M�� q�I�      �   �   x���1�@ОSL�&�..��� QLm� [`����,^�Y
�,Lh&3���8	�)Dqz��=��b5`^c����mt���p��Na��%�a�߯J^_���:����ˍ�K��$�s��a3t��'po.Ĥ�	"@L�2����Bc*�I�z.al��s7` �U����bY���      �   �   x����j�@�{�bn*�j�mOArH)�$���f���+�����,�s��>~f���󪁢lNp��h5�'�}����f8�0�������a����2��H;� k\��-�R�� �(�{eg�M��O�V��b'$�L~O���nJN�L��rtv��'K��jҞ80®4>CE��l�GU���S�� t_䃳�G�$?����      �   �  x����j�@��:& ��{�3䔃�����$�ƻ!�����<�
|��hjZ5��������|��e���|�/^����y����qٯ/O��������w���󷻇�]������|h�2��_�a&�qX��6+Y_�X=!B<�� ��&�Ն]G��R�t����t,�caBu6B��#2��&CR[�d�I�9i���������.���CNZ�`�\x�`�(�F�s���й�p���;��j�F!'=��#�<��#�<\pdT�}p�C�}p�C�*�v�й�5�ˏ�0 X�� `��- ��8a��� ��� ��`��j0@�j0@��`���� aU�¦��;NX&5 5 �\U�5 �j0@��`���`�	���S���� ��� aV�¢�U���8a��`�����q�e��g�@��9 5 ��` ��� ����ڤ��S���� ��� aV�¢�U���8�L�"� �*� LF�#��#�Y%F�R� V�Al�1�h�1�ț;�3o�L��z3�������7�"��̋|y0/����H�%�?�3�?�4���`K� ��� �2�ӛ}`���%�&���������>z�إO^t�*���X�N� ^eMg      �   �   x����
�0�{�bo� b���mLm �`L�������ߵ�@���&��4���5�lc��>��3�a��,����%��#^.Y�9c�ܟ��_;�vų�e�[Q�ۄ#�t��	Ij\�2�9�jk�j�\ϱS-N�s��6<U.      �   a   x���v
Q���W((M��L�+�,�/�O��+)J,�/Vs�	uV�0�QPOT(�L�-�WH��-�S�Q���Ѵ��$�#dc
��3sqq ��-�      �   X   x���v
Q���W((M��L�+�,�/�O�O.�M�+�/Vs�	uV�0�QPw��T״��$A�P�3ɺ���|\I�e����� ҥC�      �   W   x���v
Q���W((M��L�+�,�/�O�-�IML�/J-Vs�	uV�0�QPwIMV�04�7 r�J��t2����5����  �#      �   �   x����
�@@�OqwH��lZ��̠1�q��36�y��k���Y�s��K�*��j�;+���>)yu��FMuR3�(�I�>���iv��4�C5	a��f� ��]x7"�:���$�-=��?��c[�^z05Rt�������W-�Z��+{悊�N< U��'      �   
   x���          �   �  x��Y�n���->� @!	Ъ��c��X�FY�Jr���0&�����C���Cy��؞;CR$E�fd.Z�	�᝙;�{�r:_Y�5����(�"�;<bƳ+k�:/{��Hy"j������s�ˎ�1�\�[��������?f���V�2p�	W�1�6��Iu<�3�s'`7a�W��߉P0��k:�̦��N�����Xu~5����~���O��q���X
o؁�%�!��9���=pE����]"ܝ`;��"�8���!M�f����uV�̺X��t6�����ܬ ����(�1������0��Z�����C�Ӿ�n$ڏ��U���v-�@r�T
�`��x��N�����:;NĄ�j��H��z�����Z]XE���7���P�m�|�6����
fdgޤ(��Ό�|��I�t��o^9�JӨ�SG*����.Gp�w�>@�h�ؽ�SO�	�z��c�(�j�&��t����]b�m"@0:�x���|eMƓ4-s���Q���G�XP}! l�ډ���.sv#�;��@pNȻ�x���u;E|z,�D-��5��]V�T	%�!J&��_'���En�-rv�C��$X�|IEH��S�b�(y��9�o�2I��C}[lc�1�X��:<��c9;��c�;A߰\���hOFg[�*�x�� ��>[IZ���$\�B7��n�]�D<����ۀv���"�;���D�C����X���� �glm�:M3ĎۼUE���ҳ�}��v����w(��y��6�+��F�W��0���Ma������oa&Z�[^�)o�t��`F��Z����:��@�A�24�A�7 vi]^ͭ�x=��Xai ��r��b��v�X�g��������4�ܲ��#2/�\cУ�0��C��%�(�Ԙ��*�Г0$J�;:�A�A �4��ܻF��SZ�ݬ�PHx$m-��X��.x�D��PmC�&��ư\�?�4�I�4bDG95:As�4b�2
"m�;�'��
¹cs@�R�g��{��O\��0n�tP^�#u�M�Pu�|�BKC�̇�p۩6YU��d'uA�&��)�?�]���cE���"R�Y��T�������TjAIʩ3��:�(�7�&�{DA̂D	j��H$f¯_�E�eI�'+J:E��購3�7B�A��]K
�}V��&:֪���gV�zX3GG��~p����H���[c�ǃ���ZX~[9���/[<⪲o����Ҙ�t�EM��-Zgn��=�I59R �r']j��A��b�O!�,:Ɯ0�7j����i�d�&f���:k<\h�Mq�{���[CgpЭR �p�-N<]�(��N�uメn'�������#6�#6.>�?G�p��i
!�Z��;IU�|�������1�$S����@�LI���;��/���?��~A
@�u���X�6�*�-��1g*��.i�)
��h��v���q_�3�����b�m1��1|0|��u����%��X��Pc�}�����}�(b�g�!��?ij��/�g��T\���p�F@D��P �'	9�	Xu!--P5��2�r��E�X^��L)cݓ
�K"LC_W�2���� ��/��<{�B��} r���i�2�.��ʔ,��s������2�o����U�	���3��^�F'{X�� �C�k�_�fS
�|�aj]�[Z�����{�{ۃ�4�cN��,������m� P�CJG����F�Xe7�#�2�5�Rðoi�4vϽG��S�5a�?]N���>��<�I�]��jb��H?����uAP*"җ���!8i��r�W2����o @W���Cu�����ް�|�z���1������d#>AE#��L���}���wвg�"H��U���"�_sDuj
��n��nF�����1Y^�y�@�U;�õ�}��0��^u�4Z�މ�8��F��y0�[�㥴�j��V��o)�ݽ���>'��uK�\��5�tS+p<��y���:Y����U�5�������e�/���X�_��/�ث��~�ź�e��1qe���Q��oBJ���=(�1u�j=J��f��J���-#P#��YJ���*�0t(�`��*�+�^��9�m����ͭk�x�_�#��h�      �   e   x���v
Q���W(�,.I�M�+�,�/�OI,�/Vs�	uV�0�QP*ruwR״��$R�P�������)ڌ��B\#BH�c��������� ��A�      �   Y   x���v
Q���W(�,.I�M�+�,�/�/J-N-*KLI,Vs�	uV�0�QP���tqt���S״��$E�P�kP���#H/ �&�     