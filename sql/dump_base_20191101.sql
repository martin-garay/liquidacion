PGDMP     '    .            
    w         
   asociacion    9.5.19    9.5.19 �   �           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                       false            �           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                       false            �           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                       false            �           1262    612303 
   asociacion    DATABASE     ~   CREATE DATABASE "asociacion" WITH TEMPLATE = template0 ENCODING = 'UTF8' LC_COLLATE = 'es_AR.UTF-8' LC_CTYPE = 'es_AR.UTF-8';
    DROP DATABASE "asociacion";
             postgres    false                        2615    2200    public    SCHEMA        CREATE SCHEMA "public";
    DROP SCHEMA "public";
             postgres    false            �           0    0    SCHEMA "public"    COMMENT     8   COMMENT ON SCHEMA "public" IS 'standard public schema';
                  postgres    false    6                        2615    612304    sistema    SCHEMA        CREATE SCHEMA "sistema";
    DROP SCHEMA "sistema";
             postgres    false                        3079    12435    plpgsql 	   EXTENSION     C   CREATE EXTENSION IF NOT EXISTS "plpgsql" WITH SCHEMA "pg_catalog";
    DROP EXTENSION "plpgsql";
                  false            �           0    0    EXTENSION "plpgsql"    COMMENT     B   COMMENT ON EXTENSION "plpgsql" IS 'PL/pgSQL procedural language';
                       false    1            .           1255    612305    antiguedad(integer, "date")    FUNCTION     (  CREATE FUNCTION "public"."antiguedad"("id_persona" integer, "_fecha" "date" DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
	resultado integer;
BEGIN
    SELECT edad(fecha_ingreso, _fecha) INTO resultado FROM personas WHERE id=id_persona;
    return resultado;
END;
$$;
 L   DROP FUNCTION "public"."antiguedad"("id_persona" integer, "_fecha" "date");
       public       postgres    false    1    6            /           1255    612306     antiguedad_dias(integer, "date")    FUNCTION     Z  CREATE FUNCTION "public"."antiguedad_dias"("_id_persona" integer, "_fecha" "date" DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
	resultado integer;
BEGIN    
    SELECT (EXTRACT(epoch from age(fecha_ingreso, _fecha)) / 86400)::int INTO resultado FROM personas WHERE id=_id_persona;
    return abs(resultado);
END;
$$;
 R   DROP FUNCTION "public"."antiguedad_dias"("_id_persona" integer, "_fecha" "date");
       public       postgres    false    6    1            <           1255    612307    dias_mes("date")    FUNCTION       CREATE FUNCTION "public"."dias_mes"("fecha" "date") RETURNS integer
    LANGUAGE "plpgsql"
    AS $$
DECLARE
    cant_dias integer;
BEGIN
	SELECT DATE_PART('days', DATE_TRUNC('month', fecha) + '1 MONTH'::INTERVAL - '1 DAY'::INTERVAL ) into cant_dias;
	return cant_dias;
END;
$$;
 3   DROP FUNCTION "public"."dias_mes"("fecha" "date");
       public       postgres    false    6    1            =           1255    612308    edad("date", "date")    FUNCTION     �  CREATE FUNCTION "public"."edad"("date", "date" DEFAULT NULL::"date") RETURNS integer
    LANGUAGE "plpgsql"
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
 /   DROP FUNCTION "public"."edad"("date", "date");
       public       postgres    false    6    1            >           1255    612309     fecha_hasta_liquidacion(integer)    FUNCTION       CREATE FUNCTION "public"."fecha_hasta_liquidacion"("id_liquidacion" integer) RETURNS "date"
    LANGUAGE "plpgsql"
    AS $$
DECLARE 
	_fecha_hasta date;
BEGIN
	SELECT fecha_hasta INTO _fecha_hasta FROM liquidaciones WHERE id=id_liquidacion;
	return _fecha_hasta;
END;
$$;
 L   DROP FUNCTION "public"."fecha_hasta_liquidacion"("id_liquidacion" integer);
       public       postgres    false    6    1            ?           1255    612310    fu_numero_letras(numeric)    FUNCTION     �  CREATE FUNCTION "public"."fu_numero_letras"("numero" numeric) RETURNS "text"
    LANGUAGE "plpgsql"
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
 =   DROP FUNCTION "public"."fu_numero_letras"("numero" numeric);
       public       postgres    false    1    6            �           0    0 -   FUNCTION "fu_numero_letras"("numero" numeric)    COMMENT     z   COMMENT ON FUNCTION "public"."fu_numero_letras"("numero" numeric) IS 'Funcion para Convertir el Monto Numerico a Letras';
            public       postgres    false    319            @           1255    612311    numero_a_letras(numeric)    FUNCTION     w  CREATE FUNCTION "public"."numero_a_letras"("numero" numeric) RETURNS "text"
    LANGUAGE "plpgsql"
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
 <   DROP FUNCTION "public"."numero_a_letras"("numero" numeric);
       public       postgres    false    1    6            A           1255    612312    numero_a_letras_back(numeric)    FUNCTION     �  CREATE FUNCTION "public"."numero_a_letras_back"("numero" numeric) RETURNS "text"
    LANGUAGE "plpgsql"
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
 A   DROP FUNCTION "public"."numero_a_letras_back"("numero" numeric);
       public       postgres    false    6    1            B           1255    612313 (   sp_grabar_historico_liquidacion(integer)    FUNCTION       CREATE FUNCTION "public"."sp_grabar_historico_liquidacion"("_id_liquidacion" integer) RETURNS "void"
    LANGUAGE "plpgsql"
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
 U   DROP FUNCTION "public"."sp_grabar_historico_liquidacion"("_id_liquidacion" integer);
       public       postgres    false    6    1            C           1255    612314 #   sp_trg_ai_liquidaciones_conceptos()    FUNCTION     �  CREATE FUNCTION "public"."sp_trg_ai_liquidaciones_conceptos"() RETURNS "trigger"
    LANGUAGE "plpgsql"
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
 >   DROP FUNCTION "public"."sp_trg_ai_liquidaciones_conceptos"();
       public       postgres    false    6    1            D           1255    612315    sp_trg_ai_recibos()    FUNCTION     �  CREATE FUNCTION "public"."sp_trg_ai_recibos"() RETURNS "trigger"
    LANGUAGE "plpgsql"
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
 .   DROP FUNCTION "public"."sp_trg_ai_recibos"();
       public       postgres    false    6    1            E           1255    612316    sp_trg_au_liquidaciones()    FUNCTION     �  CREATE FUNCTION "public"."sp_trg_au_liquidaciones"() RETURNS "trigger"
    LANGUAGE "plpgsql"
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
 4   DROP FUNCTION "public"."sp_trg_au_liquidaciones"();
       public       postgres    false    1    6            F           1255    612317 #   sp_volver_a_estado_inicial(integer)    FUNCTION       CREATE FUNCTION "public"."sp_volver_a_estado_inicial"("_id_liquidacion" integer) RETURNS "void"
    LANGUAGE "plpgsql"
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
 P   DROP FUNCTION "public"."sp_volver_a_estado_inicial"("_id_liquidacion" integer);
       public       postgres    false    1    6            G           1255    612318 !   total_vacaciones(integer, "date")    FUNCTION     �  CREATE FUNCTION "public"."total_vacaciones"("_id_persona" integer, "_fecha" "date" DEFAULT "now"()) RETURNS integer
    LANGUAGE "plpgsql"
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
 S   DROP FUNCTION "public"."total_vacaciones"("_id_persona" integer, "_fecha" "date");
       public       postgres    false    1    6            �            1259    612319    acumuladores    TABLE     &  CREATE TABLE "public"."acumuladores" (
    "id" integer NOT NULL,
    "nombre" character varying(60) NOT NULL,
    "descripcion" "text" NOT NULL,
    "id_tipo_concepto" integer NOT NULL,
    "remunerativo" boolean DEFAULT false NOT NULL,
    "valor_inicial" numeric(10,2) DEFAULT 0 NOT NULL
);
 $   DROP TABLE "public"."acumuladores";
       public         postgres    false    6            �            1259    612327    acumuladores_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."acumuladores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE "public"."acumuladores_id_seq";
       public       postgres    false    182    6            �           0    0    acumuladores_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE "public"."acumuladores_id_seq" OWNED BY "public"."acumuladores"."id";
            public       postgres    false    183            �            1259    612329    back_sueldo_basico    TABLE     ]   CREATE TABLE "public"."back_sueldo_basico" (
    "id" integer,
    "basico" numeric(10,2)
);
 *   DROP TABLE "public"."back_sueldo_basico";
       public         postgres    false    6            �            1259    612332    bancos    TABLE     a   CREATE TABLE "public"."bancos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
    DROP TABLE "public"."bancos";
       public         postgres    false    6            �            1259    612338    bancos_id_seq    SEQUENCE     z   CREATE SEQUENCE "public"."bancos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE "public"."bancos_id_seq";
       public       postgres    false    185    6            �           0    0    bancos_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE "public"."bancos_id_seq" OWNED BY "public"."bancos"."id";
            public       postgres    false    186            �            1259    612340 
   categorias    TABLE     �   CREATE TABLE "public"."categorias" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "sueldo_basico" numeric(10,2),
    "valor_hora" numeric(10,2),
    "codigo" "text" NOT NULL
);
 "   DROP TABLE "public"."categorias";
       public         postgres    false    6            �            1259    612346    categorias_id_seq    SEQUENCE     ~   CREATE SEQUENCE "public"."categorias_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE "public"."categorias_id_seq";
       public       postgres    false    187    6            �           0    0    categorias_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE "public"."categorias_id_seq" OWNED BY "public"."categorias"."id";
            public       postgres    false    188            �            1259    612348 	   conceptos    TABLE     �  CREATE TABLE "public"."conceptos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "codigo" "text" NOT NULL,
    "id_tipo_concepto" integer NOT NULL,
    "formula" "text",
    "mostrar_en_recibo" boolean DEFAULT false,
    "totaliza" boolean DEFAULT false,
    "mostrar_si_cero" boolean DEFAULT false NOT NULL,
    "observaciones" "text",
    "valor_fijo" numeric(10,2),
    "remunerativo" boolean DEFAULT false NOT NULL,
    "retencion" boolean DEFAULT false NOT NULL
);
 !   DROP TABLE "public"."conceptos";
       public         postgres    false    6            �            1259    612359    conceptos_id_seq    SEQUENCE     }   CREATE SEQUENCE "public"."conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE "public"."conceptos_id_seq";
       public       postgres    false    6    189            �           0    0    conceptos_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE "public"."conceptos_id_seq" OWNED BY "public"."conceptos"."id";
            public       postgres    false    190            �            1259    612361    conceptos_personas    TABLE     �   CREATE TABLE "public"."conceptos_personas" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "id_persona" integer NOT NULL,
    "valor_fijo" numeric(10,2)
);
 *   DROP TABLE "public"."conceptos_personas";
       public         postgres    false    6            �            1259    612364    datos_actuales    TABLE     Q  CREATE TABLE "public"."datos_actuales" (
    "id" integer NOT NULL,
    "domicilio" "text" NOT NULL,
    "id_localidad" integer,
    "telefono_particular" character varying(30),
    "telefono_celular" character varying(30),
    "email" character varying(100),
    "id_estado_civil" integer NOT NULL,
    "id_persona" integer NOT NULL
);
 &   DROP TABLE "public"."datos_actuales";
       public         postgres    false    6            �            1259    612370    datos_actuales_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."datos_actuales_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE "public"."datos_actuales_id_seq";
       public       postgres    false    6    192            �           0    0    datos_actuales_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE "public"."datos_actuales_id_seq" OWNED BY "public"."datos_actuales"."id";
            public       postgres    false    193            �            1259    612372    datos_laborales    TABLE     �  CREATE TABLE "public"."datos_laborales" (
    "id" integer NOT NULL,
    "id_categoria" integer,
    "id_establecimiento" integer,
    "email_laboral" character varying(255),
    "id_persona" integer NOT NULL,
    "legajo" integer NOT NULL,
    "id_tipo_contrato" integer NOT NULL,
    "fecha_ingreso" "date",
    "fecha_egreso" "date",
    "hora_entrada" time without time zone,
    "hora_salida" time without time zone
);
 '   DROP TABLE "public"."datos_laborales";
       public         postgres    false    6            �            1259    612375    datos_laborales_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."datos_laborales_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE "public"."datos_laborales_id_seq";
       public       postgres    false    6    194            �           0    0    datos_laborales_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE "public"."datos_laborales_id_seq" OWNED BY "public"."datos_laborales"."id";
            public       postgres    false    195            �            1259    612377    datos_salud    TABLE     �   CREATE TABLE "public"."datos_salud" (
    "id" integer NOT NULL,
    "id_obra_social" integer,
    "observaciones_medicas" character varying(255),
    "id_persona" integer NOT NULL
);
 #   DROP TABLE "public"."datos_salud";
       public         postgres    false    6            �            1259    612380    datos_salud_id_seq    SEQUENCE        CREATE SEQUENCE "public"."datos_salud_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE "public"."datos_salud_id_seq";
       public       postgres    false    6    196            �           0    0    datos_salud_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE "public"."datos_salud_id_seq" OWNED BY "public"."datos_salud"."id";
            public       postgres    false    197            �            1259    612382    establecimientos    TABLE     �   CREATE TABLE "public"."establecimientos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "direccion" "text" NOT NULL,
    "id_localidad" integer NOT NULL,
    "cuit" "text",
    "actividad" "text",
    "id_tipo_empleador" integer
);
 (   DROP TABLE "public"."establecimientos";
       public         postgres    false    6            �            1259    612388    establecimientos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."establecimientos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE "public"."establecimientos_id_seq";
       public       postgres    false    6    198            �           0    0    establecimientos_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE "public"."establecimientos_id_seq" OWNED BY "public"."establecimientos"."id";
            public       postgres    false    199            �            1259    612390    estados_civiles    TABLE     j   CREATE TABLE "public"."estados_civiles" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 '   DROP TABLE "public"."estados_civiles";
       public         postgres    false    6            �            1259    612396    estados_civiles_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."estados_civiles_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE "public"."estados_civiles_id_seq";
       public       postgres    false    6    200            �           0    0    estados_civiles_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE "public"."estados_civiles_id_seq" OWNED BY "public"."estados_civiles"."id";
            public       postgres    false    201            �            1259    612398    estados_liquidacion    TABLE     t   CREATE TABLE "public"."estados_liquidacion" (
    "id" integer NOT NULL,
    "descripcion" character varying(60)
);
 +   DROP TABLE "public"."estados_liquidacion";
       public         postgres    false    6            �            1259    612401    estados_liquidacion_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."estados_liquidacion_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE "public"."estados_liquidacion_id_seq";
       public       postgres    false    6    202            �           0    0    estados_liquidacion_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE "public"."estados_liquidacion_id_seq" OWNED BY "public"."estados_liquidacion"."id";
            public       postgres    false    203            �            1259    612403    feriados    TABLE     �   CREATE TABLE "public"."feriados" (
    "id" integer NOT NULL,
    "fecha" "date" NOT NULL,
    "descripcion" "text" NOT NULL,
    "hora_desde" time without time zone,
    "hora_hasta" time without time zone
);
     DROP TABLE "public"."feriados";
       public         postgres    false    6            �            1259    612409    feriados_id_seq    SEQUENCE     |   CREATE SEQUENCE "public"."feriados_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE "public"."feriados_id_seq";
       public       postgres    false    204    6            �           0    0    feriados_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE "public"."feriados_id_seq" OWNED BY "public"."feriados"."id";
            public       postgres    false    205            �            1259    612411    fichajes    TABLE     '  CREATE TABLE "public"."fichajes" (
    "id" integer NOT NULL,
    "fecha" "date" NOT NULL,
    "hora_entrada" timestamp without time zone,
    "hora_salida" timestamp without time zone,
    "horas_trabajadas" numeric(10,2),
    "horas_extras" numeric(10,2),
    "id_persona" integer NOT NULL
);
     DROP TABLE "public"."fichajes";
       public         postgres    false    6            �            1259    612414    fichajes_id_seq    SEQUENCE     |   CREATE SEQUENCE "public"."fichajes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE "public"."fichajes_id_seq";
       public       postgres    false    206    6            �           0    0    fichajes_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE "public"."fichajes_id_seq" OWNED BY "public"."fichajes"."id";
            public       postgres    false    207            �            1259    612416    generos    TABLE     b   CREATE TABLE "public"."generos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
    DROP TABLE "public"."generos";
       public         postgres    false    6            �            1259    612422    generos_id_seq    SEQUENCE     {   CREATE SEQUENCE "public"."generos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE "public"."generos_id_seq";
       public       postgres    false    208    6            �           0    0    generos_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE "public"."generos_id_seq" OWNED BY "public"."generos"."id";
            public       postgres    false    209            �            1259    612424    historico_liquidaciones    TABLE       CREATE TABLE "public"."historico_liquidaciones" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "periodo" "date" NOT NULL,
    "fecha_desde" "date",
    "fecha_hasta" "date",
    "id_tipo_liquidacion" integer NOT NULL,
    "id_establecimiento" integer DEFAULT 1 NOT NULL,
    "id_banco" integer NOT NULL,
    "fecha_pago" "date" NOT NULL,
    "periodo_depositado" character varying(10),
    "lugar_pago" "text",
    "fecha_deposito" "date",
    "id_estado" integer DEFAULT 1 NOT NULL,
    "mes" integer,
    "anio" integer,
    "nro_recibo_inicial" integer NOT NULL,
    "banco" "text",
    "estado" "text",
    "tipo_liquidacion" "text",
    "establecimiento" "text",
    "direccion_establecimiento" "text",
    "localidad_establecimiento" "text",
    "cp_establecimiento" "text",
    "provincia_establecimiento" "text",
    "cuit" "text",
    "actividad" "text",
    "id_tipo_empleador" integer,
    "tipo_empleador" "text",
    "fecha_carga_social" "date" NOT NULL,
    "mes_carga_social" character varying(10)
);
 /   DROP TABLE "public"."historico_liquidaciones";
       public         postgres    false    6            �            1259    612432 !   historico_liquidaciones_conceptos    TABLE     "  CREATE TABLE "public"."historico_liquidaciones_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "id_liquidacion" integer NOT NULL,
    "valor_fijo" numeric(10,2),
    "concepto" "text",
    "codigo" "text",
    "formula" "text",
    "tipo_concepto" "text"
);
 9   DROP TABLE "public"."historico_liquidaciones_conceptos";
       public         postgres    false    6            �            1259    612438    historico_recibos    TABLE     �  CREATE TABLE "public"."historico_recibos" (
    "id" integer NOT NULL,
    "nro_recibo" integer,
    "id_persona" integer NOT NULL,
    "total_remunerativos" numeric(10,2),
    "total_no_remunerativos" numeric(10,2),
    "total_deducciones" numeric(10,2),
    "total_neto" numeric(10,2),
    "total_basico" numeric(10,2),
    "id_liquidacion" integer NOT NULL,
    "apellido" "text",
    "nombre" "text",
    "legajo" integer,
    "tipo_documento" "text",
    "nro_documento" character varying(15),
    "genero" "text",
    "id_estado_civil" integer,
    "estado_civil" "text",
    "fecha_nacimiento" "date",
    "edad" integer,
    "regimen" "text",
    "cuil" "text",
    "id_categoria" integer,
    "categoria" "text",
    "tarea" "text",
    "sueldo_basico" numeric(10,2),
    "fecha_ingreso" "date",
    "fecha_egreso" "date",
    "id_tipo_contrato" integer,
    "tipo_contrato" "text",
    "id_obra_social" integer,
    "obra_social" "text",
    "codigo_obra_social" "text",
    "id_localidad" integer,
    "localidad" "text",
    "cp" integer,
    "domicilio" "text",
    "id_nacionalidad" integer,
    "nacionalidad" "text",
    "pais" "text",
    "provincia" "text",
    "id_establecimiento" integer,
    "establecimiento" "text"
);
 )   DROP TABLE "public"."historico_recibos";
       public         postgres    false    6            �            1259    612444    historico_recibos_acumuladores    TABLE     /  CREATE TABLE "public"."historico_recibos_acumuladores" (
    "id" integer NOT NULL,
    "id_acumulador" integer NOT NULL,
    "importe" numeric(10,2) NOT NULL,
    "id_recibo" integer NOT NULL,
    "nombre" "text",
    "descripcion" "text",
    "id_tipo_concepto" integer,
    "tipo_concepto" "text"
);
 6   DROP TABLE "public"."historico_recibos_acumuladores";
       public         postgres    false    6            �            1259    612450    historico_recibos_conceptos    TABLE     �  CREATE TABLE "public"."historico_recibos_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "importe" numeric(10,2),
    "id_recibo" integer NOT NULL,
    "concepto" "text",
    "codigo" "text",
    "formula" "text",
    "id_tipo_concepto" integer,
    "tipo_concepto" "text",
    "mostrar_en_recibo" boolean,
    "mostrar_si_cero" boolean,
    "totaliza" boolean,
    "valor_fijo" numeric(10,2),
    "remunerativo" boolean,
    "retencion" boolean
);
 3   DROP TABLE "public"."historico_recibos_conceptos";
       public         postgres    false    6            �            1259    612456    historico_sueldo_basico    TABLE     �   CREATE TABLE "public"."historico_sueldo_basico" (
    "id" integer NOT NULL,
    "mes" integer NOT NULL,
    "anio" integer NOT NULL,
    "fecha" timestamp without time zone DEFAULT "now"() NOT NULL,
    "descripcion" character varying(255)
);
 /   DROP TABLE "public"."historico_sueldo_basico";
       public         postgres    false    6            �            1259    612460    historico_sueldo_basico_detalle    TABLE     �   CREATE TABLE "public"."historico_sueldo_basico_detalle" (
    "id" integer NOT NULL,
    "id_persona" integer NOT NULL,
    "basico" numeric(10,2) NOT NULL,
    "id_cabecera" integer NOT NULL
);
 7   DROP TABLE "public"."historico_sueldo_basico_detalle";
       public         postgres    false    6            �            1259    612463 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."historico_sueldo_basico_detalle_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 A   DROP SEQUENCE "public"."historico_sueldo_basico_detalle_id_seq";
       public       postgres    false    216    6            �           0    0 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE OWNED BY     {   ALTER SEQUENCE "public"."historico_sueldo_basico_detalle_id_seq" OWNED BY "public"."historico_sueldo_basico_detalle"."id";
            public       postgres    false    217            �            1259    612465    historico_sueldo_basico_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."historico_sueldo_basico_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE "public"."historico_sueldo_basico_id_seq";
       public       postgres    false    215    6            �           0    0    historico_sueldo_basico_id_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE "public"."historico_sueldo_basico_id_seq" OWNED BY "public"."historico_sueldo_basico"."id";
            public       postgres    false    218            �            1259    612467    liquidaciones    TABLE     �  CREATE TABLE "public"."liquidaciones" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "periodo" "date" NOT NULL,
    "fecha_desde" "date",
    "fecha_hasta" "date",
    "id_tipo_liquidacion" integer NOT NULL,
    "id_establecimiento" integer DEFAULT 1 NOT NULL,
    "id_banco" integer NOT NULL,
    "fecha_pago" "date" NOT NULL,
    "periodo_depositado" character varying(10),
    "lugar_pago" "text",
    "fecha_deposito" "date",
    "id_estado" integer DEFAULT 1 NOT NULL,
    "mes" integer,
    "anio" integer,
    "nro_recibo_inicial" integer NOT NULL,
    "fecha_carga_social" "date" NOT NULL,
    "mes_carga_social" character varying(10)
);
 %   DROP TABLE "public"."liquidaciones";
       public         postgres    false    6            �            1259    612475    liquidaciones_conceptos    TABLE     �   CREATE TABLE "public"."liquidaciones_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "id_liquidacion" integer NOT NULL,
    "valor_fijo" numeric(10,2)
);
 /   DROP TABLE "public"."liquidaciones_conceptos";
       public         postgres    false    6            �            1259    612478    liquidaciones_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."liquidaciones_conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE "public"."liquidaciones_conceptos_id_seq";
       public       postgres    false    6    220            �           0    0    liquidaciones_conceptos_id_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE "public"."liquidaciones_conceptos_id_seq" OWNED BY "public"."liquidaciones_conceptos"."id";
            public       postgres    false    221            �            1259    612480    liquidaciones_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."liquidaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE "public"."liquidaciones_id_seq";
       public       postgres    false    6    219            �           0    0    liquidaciones_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE "public"."liquidaciones_id_seq" OWNED BY "public"."liquidaciones"."id";
            public       postgres    false    222            �            1259    612482    localidades    TABLE     �   CREATE TABLE "public"."localidades" (
    "id" integer NOT NULL,
    "nombre" character varying(60) NOT NULL,
    "cp" integer NOT NULL,
    "id_provincia" integer NOT NULL
);
 #   DROP TABLE "public"."localidades";
       public         postgres    false    6            �            1259    612485    localidades_id_seq    SEQUENCE        CREATE SEQUENCE "public"."localidades_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE "public"."localidades_id_seq";
       public       postgres    false    6    223            �           0    0    localidades_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE "public"."localidades_id_seq" OWNED BY "public"."localidades"."id";
            public       postgres    false    224            �            1259    612487    nacionalidades    TABLE     i   CREATE TABLE "public"."nacionalidades" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 &   DROP TABLE "public"."nacionalidades";
       public         postgres    false    6            �            1259    612493    nacionalidades_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."nacionalidades_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE "public"."nacionalidades_id_seq";
       public       postgres    false    6    225            �           0    0    nacionalidades_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE "public"."nacionalidades_id_seq" OWNED BY "public"."nacionalidades"."id";
            public       postgres    false    226            �            1259    612495    obras_sociales    TABLE     �   CREATE TABLE "public"."obras_sociales" (
    "id" integer NOT NULL,
    "codigo" "text" NOT NULL,
    "descripcion" "text" NOT NULL
);
 &   DROP TABLE "public"."obras_sociales";
       public         postgres    false    6            �            1259    612501    obras_sociales_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."obras_sociales_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE "public"."obras_sociales_id_seq";
       public       postgres    false    227    6            �           0    0    obras_sociales_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE "public"."obras_sociales_id_seq" OWNED BY "public"."obras_sociales"."id";
            public       postgres    false    228            �            1259    612503    paises    TABLE     �   CREATE TABLE "public"."paises" (
    "id" integer NOT NULL,
    "nombre" character varying(60) NOT NULL,
    "nacionalidad" character varying(60) NOT NULL
);
    DROP TABLE "public"."paises";
       public         postgres    false    6            �            1259    612506    paises_id_seq    SEQUENCE     z   CREATE SEQUENCE "public"."paises_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE "public"."paises_id_seq";
       public       postgres    false    6    229            �           0    0    paises_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE "public"."paises_id_seq" OWNED BY "public"."paises"."id";
            public       postgres    false    230            �            1259    612508    periodos    TABLE       CREATE TABLE "public"."periodos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "anio" integer NOT NULL,
    "mes" integer NOT NULL,
    "periodo" "date" NOT NULL,
    "fecha_desde" "date" NOT NULL,
    "fecha_hasta" "date" NOT NULL,
    "observaciones" "text"
);
     DROP TABLE "public"."periodos";
       public         postgres    false    6            �            1259    612514    periodos_detalle    TABLE     q  CREATE TABLE "public"."periodos_detalle" (
    "id" integer NOT NULL,
    "id_persona" integer NOT NULL,
    "dias_trabajados" numeric(10,2),
    "horas_comunes" numeric(10,2),
    "horas_extras_50" numeric(10,2),
    "dias_vacaciones" integer DEFAULT 0,
    "id_periodo" integer NOT NULL,
    "inasistencias" integer,
    "horas_extras_100" numeric(10,2) DEFAULT 0
);
 (   DROP TABLE "public"."periodos_detalle";
       public         postgres    false    6            �           0    0 ,   COLUMN "periodos_detalle"."horas_extras_100"    COMMENT     \   COMMENT ON COLUMN "public"."periodos_detalle"."horas_extras_100" IS 'Horas extras al 100%';
            public       postgres    false    232            �            1259    612519    periodos_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."periodos_detalle_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE "public"."periodos_detalle_id_seq";
       public       postgres    false    232    6            �           0    0    periodos_detalle_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE "public"."periodos_detalle_id_seq" OWNED BY "public"."periodos_detalle"."id";
            public       postgres    false    233            �            1259    612521    periodos_id_seq    SEQUENCE     |   CREATE SEQUENCE "public"."periodos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE "public"."periodos_id_seq";
       public       postgres    false    231    6            �           0    0    periodos_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE "public"."periodos_id_seq" OWNED BY "public"."periodos"."id";
            public       postgres    false    234            �            1259    612523    persona_tareas    TABLE     �   CREATE TABLE "public"."persona_tareas" (
    "id" integer NOT NULL,
    "id_persona" integer NOT NULL,
    "id_tarea" integer NOT NULL
);
 &   DROP TABLE "public"."persona_tareas";
       public         postgres    false    6            �            1259    612526    persona_tareas_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."persona_tareas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE "public"."persona_tareas_id_seq";
       public       postgres    false    235    6            �           0    0    persona_tareas_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE "public"."persona_tareas_id_seq" OWNED BY "public"."persona_tareas"."id";
            public       postgres    false    236            �            1259    612528    personas    TABLE     �  CREATE TABLE "public"."personas" (
    "id" integer NOT NULL,
    "nombre" character varying(100) NOT NULL,
    "apellido" character varying(100) NOT NULL,
    "fecha_nacimiento" "date",
    "id_tipo_documento" integer NOT NULL,
    "nro_documento" character varying(15),
    "id_genero" integer NOT NULL,
    "id_nacionalidad" integer NOT NULL,
    "activo" boolean DEFAULT true NOT NULL,
    "legajo" integer NOT NULL,
    "id_estado_civil" integer NOT NULL,
    "id_categoria" integer NOT NULL,
    "id_tipo_contrato" integer NOT NULL,
    "id_establecimiento" integer NOT NULL,
    "email" "text",
    "fecha_ingreso" "date" NOT NULL,
    "fecha_egreso" "date",
    "hora_entrada" time without time zone NOT NULL,
    "hora_salida" time without time zone NOT NULL,
    "id_localidad" integer NOT NULL,
    "domicilio" "text",
    "piso" character(2),
    "departamento" character(10),
    "telefono_particular" character varying(30),
    "telefono_celular" character varying(30),
    "id_obra_social" integer,
    "cuil" character varying(15) NOT NULL,
    "horas_jornada" numeric(10,2) NOT NULL,
    "basico" numeric(10,2),
    "cant_hijos" integer DEFAULT 0 NOT NULL,
    "horas_mes" numeric(10,2),
    "id_regimen" integer
);
     DROP TABLE "public"."personas";
       public         postgres    false    6            �            1259    612536    personas_conceptos    TABLE     �   CREATE TABLE "public"."personas_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "valor_fijo" numeric(10,2),
    "id_persona" integer NOT NULL
);
 *   DROP TABLE "public"."personas_conceptos";
       public         postgres    false    6            �            1259    612539    personas_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."personas_conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 4   DROP SEQUENCE "public"."personas_conceptos_id_seq";
       public       postgres    false    6    238            �           0    0    personas_conceptos_id_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE "public"."personas_conceptos_id_seq" OWNED BY "public"."personas_conceptos"."id";
            public       postgres    false    239            �            1259    612541    personas_id_seq    SEQUENCE     |   CREATE SEQUENCE "public"."personas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 *   DROP SEQUENCE "public"."personas_id_seq";
       public       postgres    false    237    6            �           0    0    personas_id_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE "public"."personas_id_seq" OWNED BY "public"."personas"."id";
            public       postgres    false    240            �            1259    612543    personas_jornadas    TABLE     �   CREATE TABLE "public"."personas_jornadas" (
    "id" integer NOT NULL,
    "hora_desde" time without time zone NOT NULL,
    "hora_hasta" time without time zone NOT NULL,
    "id_persona" integer NOT NULL
);
 )   DROP TABLE "public"."personas_jornadas";
       public         postgres    false    6            �            1259    612546    personas_jornadas_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."personas_jornadas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE "public"."personas_jornadas_id_seq";
       public       postgres    false    6    241            �           0    0    personas_jornadas_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE "public"."personas_jornadas_id_seq" OWNED BY "public"."personas_jornadas"."id";
            public       postgres    false    242            �            1259    612548 
   provincias    TABLE     �   CREATE TABLE "public"."provincias" (
    "id" integer NOT NULL,
    "nombre" character varying NOT NULL,
    "id_pais" integer NOT NULL
);
 "   DROP TABLE "public"."provincias";
       public         postgres    false    6            �            1259    612554    provincias_id_seq    SEQUENCE     ~   CREATE SEQUENCE "public"."provincias_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE "public"."provincias_id_seq";
       public       postgres    false    6    243            �           0    0    provincias_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE "public"."provincias_id_seq" OWNED BY "public"."provincias"."id";
            public       postgres    false    244            �            1259    612556    recibos    TABLE     �  CREATE TABLE "public"."recibos" (
    "id" integer NOT NULL,
    "nro_recibo" integer,
    "id_persona" integer NOT NULL,
    "total_remunerativos" numeric(10,2),
    "total_no_remunerativos" numeric(10,2),
    "total_deducciones" numeric(10,2),
    "total_neto" numeric(10,2),
    "total_basico" numeric(10,2),
    "id_liquidacion" integer NOT NULL,
    "json_variables" character varying
);
    DROP TABLE "public"."recibos";
       public         postgres    false    6            �            1259    612562    recibos_acumuladores    TABLE     �   CREATE TABLE "public"."recibos_acumuladores" (
    "id" integer NOT NULL,
    "id_acumulador" integer NOT NULL,
    "importe" numeric(10,2) NOT NULL,
    "id_recibo" integer NOT NULL
);
 ,   DROP TABLE "public"."recibos_acumuladores";
       public         postgres    false    6            �            1259    612565    recibos_acumuladores_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."recibos_acumuladores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 6   DROP SEQUENCE "public"."recibos_acumuladores_id_seq";
       public       postgres    false    6    246            �           0    0    recibos_acumuladores_id_seq    SEQUENCE OWNED BY     e   ALTER SEQUENCE "public"."recibos_acumuladores_id_seq" OWNED BY "public"."recibos_acumuladores"."id";
            public       postgres    false    247            �            1259    612567    recibos_conceptos    TABLE     �   CREATE TABLE "public"."recibos_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "importe" numeric(10,2),
    "id_recibo" integer NOT NULL,
    "importe_fijo" numeric(10,2)
);
 )   DROP TABLE "public"."recibos_conceptos";
       public         postgres    false    6            �            1259    612570    recibos_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."recibos_conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE "public"."recibos_conceptos_id_seq";
       public       postgres    false    248    6            �           0    0    recibos_conceptos_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE "public"."recibos_conceptos_id_seq" OWNED BY "public"."recibos_conceptos"."id";
            public       postgres    false    249            �            1259    612572    recibos_id_seq    SEQUENCE     {   CREATE SEQUENCE "public"."recibos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 )   DROP SEQUENCE "public"."recibos_id_seq";
       public       postgres    false    6    245            �           0    0    recibos_id_seq    SEQUENCE OWNED BY     K   ALTER SEQUENCE "public"."recibos_id_seq" OWNED BY "public"."recibos"."id";
            public       postgres    false    250            �            1259    612574 	   regimenes    TABLE     d   CREATE TABLE "public"."regimenes" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 !   DROP TABLE "public"."regimenes";
       public         postgres    false    6            �            1259    612580    regimenes_id_seq    SEQUENCE     }   CREATE SEQUENCE "public"."regimenes_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE "public"."regimenes_id_seq";
       public       postgres    false    251    6            �           0    0    regimenes_id_seq    SEQUENCE OWNED BY     O   ALTER SEQUENCE "public"."regimenes_id_seq" OWNED BY "public"."regimenes"."id";
            public       postgres    false    252            �            1259    612582    tabla    TABLE     �   CREATE TABLE "public"."tabla" (
    "id" integer NOT NULL,
    "clave" character varying(60) NOT NULL,
    "descripcion" "text" NOT NULL
);
    DROP TABLE "public"."tabla";
       public         postgres    false    6            �            1259    612588    tabla_detalle    TABLE       CREATE TABLE "public"."tabla_detalle" (
    "id" integer NOT NULL,
    "anio" integer NOT NULL,
    "mes" integer NOT NULL,
    "periodo" "date" NOT NULL,
    "valor" numeric(10,2) NOT NULL,
    "tope" numeric(10,2) NOT NULL,
    "id_tabla" integer NOT NULL
);
 %   DROP TABLE "public"."tabla_detalle";
       public         postgres    false    6            �            1259    612591    tabla_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tabla_detalle_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE "public"."tabla_detalle_id_seq";
       public       postgres    false    6    254            �           0    0    tabla_detalle_id_seq    SEQUENCE OWNED BY     W   ALTER SEQUENCE "public"."tabla_detalle_id_seq" OWNED BY "public"."tabla_detalle"."id";
            public       postgres    false    255                        1259    612593    tabla_ganancias    TABLE     �   CREATE TABLE "public"."tabla_ganancias" (
    "id" integer NOT NULL,
    "anio" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 '   DROP TABLE "public"."tabla_ganancias";
       public         postgres    false    6                       1259    612599    tabla_ganancias_detalle    TABLE     B  CREATE TABLE "public"."tabla_ganancias_detalle" (
    "id" integer NOT NULL,
    "mes" integer NOT NULL,
    "desde" numeric(10,2) NOT NULL,
    "hasta" numeric(10,2),
    "fijo" numeric(10,2) NOT NULL,
    "porcentaje" numeric(10,2) NOT NULL,
    "excedente" numeric(10,2) NOT NULL,
    "id_cabecera" integer NOT NULL
);
 /   DROP TABLE "public"."tabla_ganancias_detalle";
       public         postgres    false    6                       1259    612602    tabla_ganancias_detalle_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tabla_ganancias_detalle_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 9   DROP SEQUENCE "public"."tabla_ganancias_detalle_id_seq";
       public       postgres    false    257    6            �           0    0    tabla_ganancias_detalle_id_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE "public"."tabla_ganancias_detalle_id_seq" OWNED BY "public"."tabla_ganancias_detalle"."id";
            public       postgres    false    258                       1259    612604    tabla_ganancias_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tabla_ganancias_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE "public"."tabla_ganancias_id_seq";
       public       postgres    false    256    6            �           0    0    tabla_ganancias_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE "public"."tabla_ganancias_id_seq" OWNED BY "public"."tabla_ganancias"."id";
            public       postgres    false    259                       1259    612606    tabla_id_seq    SEQUENCE     y   CREATE SEQUENCE "public"."tabla_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 '   DROP SEQUENCE "public"."tabla_id_seq";
       public       postgres    false    253    6            �           0    0    tabla_id_seq    SEQUENCE OWNED BY     G   ALTER SEQUENCE "public"."tabla_id_seq" OWNED BY "public"."tabla"."id";
            public       postgres    false    260                       1259    612608    tabla_personas    TABLE       CREATE TABLE "public"."tabla_personas" (
    "id" integer NOT NULL,
    "anio" integer NOT NULL,
    "mes" integer NOT NULL,
    "periodo" "date" NOT NULL,
    "valor" numeric(10,2) NOT NULL,
    "id_persona" integer NOT NULL,
    "id_tabla" integer NOT NULL
);
 &   DROP TABLE "public"."tabla_personas";
       public         postgres    false    6                       1259    612611    tabla_personas_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tabla_personas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 0   DROP SEQUENCE "public"."tabla_personas_id_seq";
       public       postgres    false    261    6            �           0    0    tabla_personas_id_seq    SEQUENCE OWNED BY     Y   ALTER SEQUENCE "public"."tabla_personas_id_seq" OWNED BY "public"."tabla_personas"."id";
            public       postgres    false    262                       1259    612613    tabla_vacaciones    TABLE     �   CREATE TABLE "public"."tabla_vacaciones" (
    "id" integer NOT NULL,
    "desde" numeric(10,2) NOT NULL,
    "hasta" numeric(10,2) NOT NULL,
    "dias" integer NOT NULL
);
 (   DROP TABLE "public"."tabla_vacaciones";
       public         postgres    false    6                       1259    612616    tabla_vacaciones_dias    TABLE     �   CREATE TABLE "public"."tabla_vacaciones_dias" (
    "id" integer NOT NULL,
    "desde" integer NOT NULL,
    "hasta" integer NOT NULL,
    "dias" integer NOT NULL,
    "descripcion" "text"
);
 -   DROP TABLE "public"."tabla_vacaciones_dias";
       public         postgres    false    6            	           1259    612622    tareas    TABLE     a   CREATE TABLE "public"."tareas" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
    DROP TABLE "public"."tareas";
       public         postgres    false    6            
           1259    612628    tareas_id_seq    SEQUENCE     z   CREATE SEQUENCE "public"."tareas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 (   DROP SEQUENCE "public"."tareas_id_seq";
       public       postgres    false    6    265            �           0    0    tareas_id_seq    SEQUENCE OWNED BY     I   ALTER SEQUENCE "public"."tareas_id_seq" OWNED BY "public"."tareas"."id";
            public       postgres    false    266                       1259    612630    tipo_liquidacion_conceptos    TABLE     �   CREATE TABLE "public"."tipo_liquidacion_conceptos" (
    "id" integer NOT NULL,
    "id_concepto" integer NOT NULL,
    "id_tipo_liquidacion" integer NOT NULL
);
 2   DROP TABLE "public"."tipo_liquidacion_conceptos";
       public         postgres    false    6                       1259    612633 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipo_liquidacion_conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 <   DROP SEQUENCE "public"."tipo_liquidacion_conceptos_id_seq";
       public       postgres    false    267    6            �           0    0 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE OWNED BY     q   ALTER SEQUENCE "public"."tipo_liquidacion_conceptos_id_seq" OWNED BY "public"."tipo_liquidacion_conceptos"."id";
            public       postgres    false    268                       1259    612635    tipos_conceptos    TABLE     �   CREATE TABLE "public"."tipos_conceptos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "desde" integer,
    "hasta" integer
);
 '   DROP TABLE "public"."tipos_conceptos";
       public         postgres    false    6                       1259    612641    tipos_conceptos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipos_conceptos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE "public"."tipos_conceptos_id_seq";
       public       postgres    false    6    269            �           0    0    tipos_conceptos_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE "public"."tipos_conceptos_id_seq" OWNED BY "public"."tipos_conceptos"."id";
            public       postgres    false    270                       1259    612643    tipos_contratos    TABLE     �   CREATE TABLE "public"."tipos_contratos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "horas_mes" numeric(10,2)
);
 '   DROP TABLE "public"."tipos_contratos";
       public         postgres    false    6                       1259    612649    tipos_contratos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipos_contratos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 1   DROP SEQUENCE "public"."tipos_contratos_id_seq";
       public       postgres    false    271    6            �           0    0    tipos_contratos_id_seq    SEQUENCE OWNED BY     [   ALTER SEQUENCE "public"."tipos_contratos_id_seq" OWNED BY "public"."tipos_contratos"."id";
            public       postgres    false    272                       1259    612651    tipos_documentos    TABLE     k   CREATE TABLE "public"."tipos_documentos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 (   DROP TABLE "public"."tipos_documentos";
       public         postgres    false    6                       1259    612657    tipos_documentos_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipos_documentos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 2   DROP SEQUENCE "public"."tipos_documentos_id_seq";
       public       postgres    false    6    273            �           0    0    tipos_documentos_id_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE "public"."tipos_documentos_id_seq" OWNED BY "public"."tipos_documentos"."id";
            public       postgres    false    274                       1259    612659    tipos_empleadores    TABLE     l   CREATE TABLE "public"."tipos_empleadores" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 )   DROP TABLE "public"."tipos_empleadores";
       public         postgres    false    6                       1259    612665    tipos_empleadores_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipos_empleadores_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE "public"."tipos_empleadores_id_seq";
       public       postgres    false    275    6            �           0    0    tipos_empleadores_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE "public"."tipos_empleadores_id_seq" OWNED BY "public"."tipos_empleadores"."id";
            public       postgres    false    276                       1259    612667    tipos_liquidaciones    TABLE     �   CREATE TABLE "public"."tipos_liquidaciones" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL,
    "activo" boolean DEFAULT true NOT NULL
);
 +   DROP TABLE "public"."tipos_liquidaciones";
       public         postgres    false    6                       1259    612674    tipos_liquidaciones_id_seq    SEQUENCE     �   CREATE SEQUENCE "public"."tipos_liquidaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE "public"."tipos_liquidaciones_id_seq";
       public       postgres    false    6    277            �           0    0    tipos_liquidaciones_id_seq    SEQUENCE OWNED BY     c   ALTER SEQUENCE "public"."tipos_liquidaciones_id_seq" OWNED BY "public"."tipos_liquidaciones"."id";
            public       postgres    false    278                       1259    612676    v_acumuladores    VIEW     [  CREATE VIEW "public"."v_acumuladores" AS
 SELECT "a"."id",
    "a"."nombre",
    "a"."descripcion",
    "a"."id_tipo_concepto",
    "a"."remunerativo",
    "a"."valor_inicial",
    "tc"."descripcion" AS "tipo_concepto"
   FROM ("public"."acumuladores" "a"
     LEFT JOIN "public"."tipos_conceptos" "tc" ON (("a"."id_tipo_concepto" = "tc"."id")));
 %   DROP VIEW "public"."v_acumuladores";
       public       postgres    false    269    182    182    182    182    182    182    269    6                       1259    612680    v_conceptos    VIEW     >  CREATE VIEW "public"."v_conceptos" AS
 SELECT "c"."id",
    "c"."descripcion",
    "c"."codigo",
    "c"."id_tipo_concepto",
    "c"."formula",
    "tc"."descripcion" AS "tipo_concepto",
    "c"."mostrar_en_recibo",
    "c"."totaliza",
    "c"."mostrar_si_cero",
    "c"."valor_fijo",
    "c"."observaciones",
    ((('['::"text" || "c"."codigo") || '] '::"text") || "c"."descripcion") AS "descripcion_codigo",
    "c"."remunerativo",
    "c"."retencion"
   FROM ("public"."conceptos" "c"
     JOIN "public"."tipos_conceptos" "tc" ON (("tc"."id" = "c"."id_tipo_concepto")));
 "   DROP VIEW "public"."v_conceptos";
       public       postgres    false    269    189    189    189    189    189    189    189    189    189    189    189    189    269    6                       1259    612685    v_localidades    VIEW     u  CREATE VIEW "public"."v_localidades" AS
 SELECT "l"."id",
    "l"."nombre",
    "l"."cp",
    "l"."id_provincia",
    "p"."nombre" AS "provincia",
    "p"."id_pais",
    "pa"."nombre" AS "pais"
   FROM (("public"."localidades" "l"
     JOIN "public"."provincias" "p" ON (("p"."id" = "l"."id_provincia")))
     JOIN "public"."paises" "pa" ON (("pa"."id" = "p"."id_pais")));
 $   DROP VIEW "public"."v_localidades";
       public       postgres    false    229    229    243    243    243    223    223    223    223    6                       1259    612689    v_establecimientos    VIEW     9  CREATE VIEW "public"."v_establecimientos" AS
 SELECT "e"."id",
    "e"."descripcion",
    "e"."direccion",
    "e"."id_localidad",
    "l"."nombre" AS "localidad",
    "l"."cp",
    "l"."id_provincia",
    "l"."provincia",
    "l"."id_pais",
    "e"."cuit",
    "e"."actividad",
    "e"."id_tipo_empleador",
    "te"."descripcion" AS "tipo_empleador"
   FROM (("public"."establecimientos" "e"
     LEFT JOIN "public"."v_localidades" "l" ON (("e"."id_localidad" = "l"."id")))
     LEFT JOIN "public"."tipos_empleadores" "te" ON (("te"."id" = "e"."id_tipo_empleador")));
 )   DROP VIEW "public"."v_establecimientos";
       public       postgres    false    281    281    281    281    281    281    198    198    198    198    198    198    198    275    275    6                       1259    612694    v_liquidaciones    VIEW     �  CREATE VIEW "public"."v_liquidaciones" AS
 SELECT "l"."id",
    "l"."id_estado",
    "el"."descripcion" AS "estado",
    "l"."descripcion",
    "l"."periodo",
    (("date_part"('year'::"text", "l"."periodo") || '-'::"text") || "date_part"('month'::"text", "l"."periodo")) AS "periodo_descripcion",
    "l"."fecha_desde",
    "l"."fecha_hasta",
    "l"."id_tipo_liquidacion",
    "l"."id_establecimiento",
    "l"."id_banco",
    "l"."fecha_pago",
    "l"."periodo_depositado",
    "l"."lugar_pago",
    "tl"."descripcion" AS "tipo_liquidacion",
    "e"."descripcion" AS "establecimiento",
    "b"."descripcion" AS "banco",
    "l"."mes",
    "l"."anio",
    "l"."fecha_deposito",
    "l"."nro_recibo_inicial",
    "e"."direccion" AS "direccion_establecimiento",
    "e"."localidad" AS "localidad_establecimiento",
    "e"."cp" AS "cp_establecimiento",
    "e"."provincia" AS "provincia_establecimiento",
    "e"."cuit",
    "e"."actividad",
    "e"."id_tipo_empleador",
    "e"."tipo_empleador",
    "l"."fecha_carga_social",
    "l"."mes_carga_social"
   FROM (((("public"."liquidaciones" "l"
     JOIN "public"."estados_liquidacion" "el" ON (("el"."id" = "l"."id_estado")))
     JOIN "public"."tipos_liquidaciones" "tl" ON (("tl"."id" = "l"."id_tipo_liquidacion")))
     JOIN "public"."v_establecimientos" "e" ON (("e"."id" = "l"."id_establecimiento")))
     LEFT JOIN "public"."bancos" "b" ON (("b"."id" = "l"."id_banco")));
 &   DROP VIEW "public"."v_liquidaciones";
       public       postgres    false    282    282    282    282    282    282    282    282    282    282    277    277    219    219    219    219    219    219    219    219    219    219    219    219    219    219    219    219    219    219    202    202    185    185    6                       1259    612699    v_periodos_detalle    VIEW       CREATE VIEW "public"."v_periodos_detalle" AS
 SELECT "pd"."id",
    "pd"."id_persona",
    "pd"."dias_trabajados",
    "pd"."horas_comunes",
    "pd"."horas_extras_50",
    "pd"."horas_extras_100",
    "pd"."inasistencias",
    "pd"."dias_vacaciones",
    "pd"."id_periodo",
    "p"."descripcion" AS "descripcion_periodo",
    "p"."anio",
    "p"."mes",
    "p"."periodo",
    "p"."fecha_desde",
    "p"."fecha_hasta"
   FROM ("public"."periodos_detalle" "pd"
     JOIN "public"."periodos" "p" ON (("p"."id" = "pd"."id_periodo")));
 )   DROP VIEW "public"."v_periodos_detalle";
       public       postgres    false    231    231    231    231    232    232    232    232    232    232    232    232    232    231    231    231    6                       1259    612703 
   v_personas    VIEW     �  CREATE VIEW "public"."v_personas" AS
 SELECT "a"."legajo",
    "a"."id",
    "a"."nombre",
    "a"."apellido",
    "a"."fecha_nacimiento",
    "a"."id_tipo_documento",
    "a"."nro_documento",
    "a"."cuil",
    "a"."id_genero",
    "a"."id_nacionalidad",
    "a"."activo",
    "a"."domicilio",
    "g"."descripcion" AS "genero",
    "td"."descripcion" AS "tipo_documento",
    "a"."id_localidad",
    "loc"."nombre" AS "localidad",
    "loc"."cp",
    "loc"."provincia",
    "loc"."pais",
    "n"."descripcion" AS "nacionalidad",
    "a"."telefono_particular",
    "a"."telefono_celular",
    "a"."email",
    "a"."id_estado_civil",
    "ec"."descripcion" AS "estado_civil",
    "a"."id_categoria",
    "c"."descripcion" AS "categoria",
    "a"."id_establecimiento",
    "es"."descripcion" AS "establecimiento",
    "a"."id_obra_social",
    "os"."descripcion" AS "obra_social",
    "os"."codigo" AS "codigo_obra_social",
    "c"."sueldo_basico",
    "c"."valor_hora",
    "a"."id_tipo_contrato",
    "tc"."descripcion" AS "tipo_contrato",
    "a"."horas_jornada",
    "a"."fecha_ingreso",
    "a"."fecha_egreso",
    "a"."id_regimen",
    "r"."descripcion" AS "regimen",
    "a"."cant_hijos",
    "a"."piso",
    "a"."departamento",
    "a"."hora_entrada",
    "a"."hora_salida",
    "a"."basico"
   FROM (((((((((("public"."personas" "a"
     LEFT JOIN "public"."estados_civiles" "ec" ON (("ec"."id" = "a"."id_estado_civil")))
     LEFT JOIN "public"."categorias" "c" ON (("c"."id" = "a"."id_categoria")))
     LEFT JOIN "public"."establecimientos" "es" ON (("es"."id" = "a"."id_establecimiento")))
     LEFT JOIN "public"."obras_sociales" "os" ON (("os"."id" = "a"."id_obra_social")))
     LEFT JOIN "public"."v_localidades" "loc" ON (("loc"."id" = "a"."id_localidad")))
     LEFT JOIN "public"."nacionalidades" "n" ON (("n"."id" = "a"."id_nacionalidad")))
     LEFT JOIN "public"."tipos_documentos" "td" ON (("td"."id" = "a"."id_tipo_documento")))
     LEFT JOIN "public"."generos" "g" ON (("g"."id" = "a"."id_genero")))
     LEFT JOIN "public"."tipos_contratos" "tc" ON (("tc"."id" = "a"."id_tipo_contrato")))
     LEFT JOIN "public"."regimenes" "r" ON (("r"."id" = "a"."id_regimen")));
 !   DROP VIEW "public"."v_personas";
       public       postgres    false    237    237    237    237    200    200    198    198    187    187    187    187    208    208    225    225    227    227    227    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    237    251    251    271    271    273    273    281    281    281    281    281    6                       1259    612708 	   v_recibos    VIEW     q  CREATE VIEW "public"."v_recibos" AS
 SELECT "r"."id",
    "r"."nro_recibo",
    "r"."id_persona",
    "r"."total_remunerativos",
    "r"."total_no_remunerativos",
    "r"."total_deducciones",
    "r"."total_neto",
    "r"."total_basico",
    "r"."id_liquidacion",
    ((((("l"."descripcion" || '(Período '::"text") || "date_part"('month'::"text", "l"."periodo")) || '-'::"text") || "date_part"('year'::"text", "l"."periodo")) || ')'::"text") AS "descripcion_liquidacion",
    "l"."periodo",
    "p"."nombre",
    "p"."apellido",
    "p"."nro_documento",
    "p"."tipo_documento",
    "p"."legajo",
    "p"."id_categoria",
    "p"."categoria",
    "p"."id_tipo_contrato",
    "p"."tipo_contrato"
   FROM (("public"."recibos" "r"
     JOIN "public"."liquidaciones" "l" ON (("l"."id" = "r"."id_liquidacion")))
     JOIN "public"."v_personas" "p" ON (("p"."id" = "r"."id_persona")));
     DROP VIEW "public"."v_recibos";
       public       postgres    false    285    219    245    219    245    285    245    245    285    285    285    245    245    219    245    245    245    285    285    285    285    285    6                       1259    612713    v_recibos_conceptos    VIEW       CREATE VIEW "public"."v_recibos_conceptos" AS
 SELECT "rc"."id",
    "rc"."id_concepto",
    "rc"."importe",
    "rc"."id_recibo",
    "c"."descripcion" AS "concepto",
    "c"."codigo",
    ('c'::"text" || "c"."codigo") AS "nombre_variable",
    "c"."formula",
    "c"."mostrar_en_recibo",
    "c"."totaliza",
    "c"."id_tipo_concepto",
    "r"."nro_recibo",
    "r"."id_persona",
    "r"."id_liquidacion",
    "l"."mes",
    "l"."anio",
    "l"."periodo",
    "l"."descripcion" AS "liquidacion_descripcion"
   FROM ((("public"."recibos_conceptos" "rc"
     JOIN "public"."recibos" "r" ON (("r"."id" = "rc"."id_recibo")))
     JOIN "public"."conceptos" "c" ON (("c"."id" = "rc"."id_concepto")))
     JOIN "public"."liquidaciones" "l" ON (("l"."id" = "r"."id_liquidacion")));
 *   DROP VIEW "public"."v_recibos_conceptos";
       public       postgres    false    245    219    189    189    189    189    189    189    189    219    219    219    219    245    245    248    248    248    248    245    6                        1259    612718    v_recibos_conceptos_detallado    VIEW       CREATE VIEW "public"."v_recibos_conceptos_detallado" AS
 SELECT "c"."id",
    "c"."id_concepto",
    "c"."importe",
    "c"."id_recibo",
    "c"."concepto",
    "c"."codigo",
    "c"."nombre_variable",
    "c"."formula",
    "c"."mostrar_en_recibo",
    "c"."totaliza",
    "c"."id_tipo_concepto",
    "c"."nro_recibo",
    "c"."id_persona",
    "c"."id_liquidacion",
    "c"."mes",
    "c"."anio",
    "c"."periodo",
    "c"."liquidacion_descripcion",
    "p"."legajo",
    "p"."nombre",
    "p"."apellido",
    "p"."nro_documento",
    "p"."id_tipo_documento",
    "p"."tipo_documento",
    "p"."estado_civil",
    "p"."id_categoria",
    "p"."categoria",
    "p"."sueldo_basico",
    "p"."fecha_ingreso",
    "p"."fecha_egreso",
    "p"."cuil",
    "p"."id_establecimiento",
    "p"."establecimiento",
    "tc"."descripcion" AS "tipo_concepto"
   FROM (("public"."v_recibos_conceptos" "c"
     JOIN "public"."v_personas" "p" ON (("p"."id" = "c"."id_persona")))
     JOIN "public"."tipos_conceptos" "tc" ON (("tc"."id" = "c"."id_tipo_concepto")));
 4   DROP VIEW "public"."v_recibos_conceptos_detallado";
       public       postgres    false    285    285    285    269    269    287    287    287    287    287    287    287    287    287    287    287    287    287    287    287    287    287    287    285    285    285    285    285    285    285    285    285    285    285    285    285    6            !           1259    612723    v_tabla_detalle    VIEW     F  CREATE VIEW "public"."v_tabla_detalle" AS
 SELECT "td"."id",
    "td"."anio",
    "td"."mes",
    "td"."periodo",
    "td"."valor",
    "td"."tope",
    "td"."id_tabla",
    "t"."descripcion" AS "tabla",
    "t"."clave"
   FROM ("public"."tabla_detalle" "td"
     JOIN "public"."tabla" "t" ON (("t"."id" = "td"."id_tabla")));
 &   DROP VIEW "public"."v_tabla_detalle";
       public       postgres    false    253    253    253    254    254    254    254    254    254    254    6            "           1259    612727    v_tabla_ganancias_detalle    VIEW     �  CREATE VIEW "public"."v_tabla_ganancias_detalle" AS
 SELECT "d"."id",
    "d"."mes",
    "d"."desde",
    "d"."hasta",
    "d"."fijo",
    "d"."porcentaje",
    "d"."excedente",
    "d"."id_cabecera",
    "c"."anio",
    "c"."descripcion",
    (((("c"."anio" || '-'::"text") || "d"."mes") || '-01'::"text"))::"date" AS "periodo"
   FROM ("public"."tabla_ganancias" "c"
     JOIN "public"."tabla_ganancias_detalle" "d" ON (("c"."id" = "d"."id_cabecera")));
 0   DROP VIEW "public"."v_tabla_ganancias_detalle";
       public       postgres    false    257    257    257    256    257    257    256    256    257    257    257    6            #           1259    612731    v_tabla_personas    VIEW     �  CREATE VIEW "public"."v_tabla_personas" AS
 SELECT "tp"."id",
    "tp"."anio",
    "tp"."mes",
    "tp"."periodo",
    "tp"."valor",
    "tp"."id_persona",
    "tp"."id_tabla",
    "t"."descripcion" AS "tabla",
    "t"."clave",
    "p"."nombre",
    "p"."apellido",
    "p"."id_tipo_documento",
    "p"."nro_documento",
    "p"."legajo",
    (((("p"."legajo" || ' '::"text") || ("p"."apellido")::"text") || ' '::"text") || ("p"."nombre")::"text") AS "persona_descripcion",
    (("tp"."anio" || '-'::"text") || "tp"."mes") AS "periodo_descripcion"
   FROM (("public"."tabla_personas" "tp"
     JOIN "public"."tabla" "t" ON (("t"."id" = "tp"."id_tabla")))
     JOIN "public"."personas" "p" ON (("p"."id" = "tp"."id_persona")));
 '   DROP VIEW "public"."v_tabla_personas";
       public       postgres    false    261    261    261    237    237    253    253    261    253    237    237    237    237    261    261    261    6            $           1259    612736    v_tipo_liquidacion_conceptos    VIEW     �  CREATE VIEW "public"."v_tipo_liquidacion_conceptos" AS
 SELECT "tlc"."id",
    "tlc"."id_concepto",
    "tlc"."id_tipo_liquidacion",
    ((('['::"text" || "c"."codigo") || '] '::"text") || "c"."descripcion") AS "concepto",
    "tl"."descripcion" AS "tipo_liquidacion",
    "c"."codigo",
    "c"."valor_fijo",
    "c"."id_tipo_concepto",
    "tc"."descripcion" AS "tipo_concepto"
   FROM ((("public"."tipo_liquidacion_conceptos" "tlc"
     JOIN "public"."conceptos" "c" ON (("c"."id" = "tlc"."id_concepto")))
     JOIN "public"."tipos_liquidaciones" "tl" ON (("tl"."id" = "tlc"."id_tipo_liquidacion")))
     JOIN "public"."tipos_conceptos" "tc" ON (("tc"."id" = "c"."id_tipo_concepto")));
 3   DROP VIEW "public"."v_tipo_liquidacion_conceptos";
       public       postgres    false    189    189    189    267    267    269    269    277    277    267    189    189    6            %           1259    612741 
   vacaciones    TABLE     �   CREATE TABLE "public"."vacaciones" (
    "id" integer NOT NULL,
    "fecha_desde" "date" NOT NULL,
    "fecha_hasta" "date" NOT NULL,
    "observaciones" "text",
    "id_persona" integer NOT NULL
);
 "   DROP TABLE "public"."vacaciones";
       public         postgres    false    6            &           1259    612747    vacaciones_id_seq    SEQUENCE     ~   CREATE SEQUENCE "public"."vacaciones_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 ,   DROP SEQUENCE "public"."vacaciones_id_seq";
       public       postgres    false    293    6            �           0    0    vacaciones_id_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE "public"."vacaciones_id_seq" OWNED BY "public"."vacaciones"."id";
            public       postgres    false    294            '           1259    612749 
   reservadas    TABLE     -  CREATE TABLE "sistema"."reservadas" (
    "id" integer NOT NULL,
    "nombre" "text" NOT NULL,
    "descripcion" "text" NOT NULL,
    "descripcion_larga" "text",
    "query" "text",
    "valor_fijo" "text",
    "id_tipo_reservada" integer NOT NULL,
    "id_tipo_dato" integer,
    "defecto" "text"
);
 #   DROP TABLE "sistema"."reservadas";
       sistema         postgres    false    8            (           1259    612755    reservadas_id_seq    SEQUENCE        CREATE SEQUENCE "sistema"."reservadas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE "sistema"."reservadas_id_seq";
       sistema       postgres    false    8    295            �           0    0    reservadas_id_seq    SEQUENCE OWNED BY     S   ALTER SEQUENCE "sistema"."reservadas_id_seq" OWNED BY "sistema"."reservadas"."id";
            sistema       postgres    false    296            )           1259    612757    tipos_datos    TABLE     g   CREATE TABLE "sistema"."tipos_datos" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 $   DROP TABLE "sistema"."tipos_datos";
       sistema         postgres    false    8            *           1259    612763    tipos_datos_id_seq    SEQUENCE     �   CREATE SEQUENCE "sistema"."tipos_datos_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 .   DROP SEQUENCE "sistema"."tipos_datos_id_seq";
       sistema       postgres    false    8    297            �           0    0    tipos_datos_id_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE "sistema"."tipos_datos_id_seq" OWNED BY "sistema"."tipos_datos"."id";
            sistema       postgres    false    298            +           1259    612765    tipos_reservadas    TABLE     l   CREATE TABLE "sistema"."tipos_reservadas" (
    "id" integer NOT NULL,
    "descripcion" "text" NOT NULL
);
 )   DROP TABLE "sistema"."tipos_reservadas";
       sistema         postgres    false    8            ,           1259    612771    tipos_reservadas_id_seq    SEQUENCE     �   CREATE SEQUENCE "sistema"."tipos_reservadas_id_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE "sistema"."tipos_reservadas_id_seq";
       sistema       postgres    false    8    299            �           0    0    tipos_reservadas_id_seq    SEQUENCE OWNED BY     _   ALTER SEQUENCE "sistema"."tipos_reservadas_id_seq" OWNED BY "sistema"."tipos_reservadas"."id";
            sistema       postgres    false    300            -           1259    612773    v_reservadas    VIEW       CREATE VIEW "sistema"."v_reservadas" AS
 SELECT "r"."id",
    "r"."nombre",
    "r"."descripcion",
    "r"."descripcion_larga",
    "r"."query",
    "r"."valor_fijo",
    "r"."id_tipo_reservada",
    "r"."id_tipo_dato",
    "tr"."descripcion" AS "tipo_reservada",
    "td"."descripcion" AS "tipo_dato",
    "r"."defecto"
   FROM (("sistema"."reservadas" "r"
     LEFT JOIN "sistema"."tipos_reservadas" "tr" ON (("tr"."id" = "r"."id_tipo_reservada")))
     LEFT JOIN "sistema"."tipos_datos" "td" ON (("td"."id" = "r"."id_tipo_dato")));
 $   DROP VIEW "sistema"."v_reservadas";
       sistema       postgres    false    295    295    295    295    295    295    295    295    295    299    299    297    297    8            �	           2604    612777    id    DEFAULT     �   ALTER TABLE ONLY "public"."acumuladores" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."acumuladores_id_seq"'::"regclass");
 D   ALTER TABLE "public"."acumuladores" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    183    182            �	           2604    612778    id    DEFAULT     t   ALTER TABLE ONLY "public"."bancos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."bancos_id_seq"'::"regclass");
 >   ALTER TABLE "public"."bancos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    186    185            �	           2604    612779    id    DEFAULT     |   ALTER TABLE ONLY "public"."categorias" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."categorias_id_seq"'::"regclass");
 B   ALTER TABLE "public"."categorias" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    188    187            �	           2604    612780    id    DEFAULT     z   ALTER TABLE ONLY "public"."conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."conceptos_id_seq"'::"regclass");
 A   ALTER TABLE "public"."conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    190    189            �	           2604    612781    id    DEFAULT     �   ALTER TABLE ONLY "public"."datos_actuales" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."datos_actuales_id_seq"'::"regclass");
 F   ALTER TABLE "public"."datos_actuales" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    193    192            �	           2604    612782    id    DEFAULT     �   ALTER TABLE ONLY "public"."datos_laborales" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."datos_laborales_id_seq"'::"regclass");
 G   ALTER TABLE "public"."datos_laborales" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    195    194            �	           2604    612783    id    DEFAULT     ~   ALTER TABLE ONLY "public"."datos_salud" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."datos_salud_id_seq"'::"regclass");
 C   ALTER TABLE "public"."datos_salud" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    197    196            �	           2604    612784    id    DEFAULT     �   ALTER TABLE ONLY "public"."establecimientos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."establecimientos_id_seq"'::"regclass");
 H   ALTER TABLE "public"."establecimientos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    199    198            �	           2604    612785    id    DEFAULT     �   ALTER TABLE ONLY "public"."estados_civiles" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."estados_civiles_id_seq"'::"regclass");
 G   ALTER TABLE "public"."estados_civiles" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    201    200            �	           2604    612786    id    DEFAULT     �   ALTER TABLE ONLY "public"."estados_liquidacion" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."estados_liquidacion_id_seq"'::"regclass");
 K   ALTER TABLE "public"."estados_liquidacion" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    203    202            �	           2604    612787    id    DEFAULT     x   ALTER TABLE ONLY "public"."feriados" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."feriados_id_seq"'::"regclass");
 @   ALTER TABLE "public"."feriados" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    205    204            �	           2604    612788    id    DEFAULT     x   ALTER TABLE ONLY "public"."fichajes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."fichajes_id_seq"'::"regclass");
 @   ALTER TABLE "public"."fichajes" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    207    206            �	           2604    612789    id    DEFAULT     v   ALTER TABLE ONLY "public"."generos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."generos_id_seq"'::"regclass");
 ?   ALTER TABLE "public"."generos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    209    208            �	           2604    612790    id    DEFAULT     �   ALTER TABLE ONLY "public"."historico_sueldo_basico" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."historico_sueldo_basico_id_seq"'::"regclass");
 O   ALTER TABLE "public"."historico_sueldo_basico" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    218    215            �	           2604    612791    id    DEFAULT     �   ALTER TABLE ONLY "public"."historico_sueldo_basico_detalle" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."historico_sueldo_basico_detalle_id_seq"'::"regclass");
 W   ALTER TABLE "public"."historico_sueldo_basico_detalle" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    217    216            �	           2604    612792    id    DEFAULT     �   ALTER TABLE ONLY "public"."liquidaciones" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."liquidaciones_id_seq"'::"regclass");
 E   ALTER TABLE "public"."liquidaciones" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    222    219            �	           2604    612793    id    DEFAULT     �   ALTER TABLE ONLY "public"."liquidaciones_conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."liquidaciones_conceptos_id_seq"'::"regclass");
 O   ALTER TABLE "public"."liquidaciones_conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    221    220            �	           2604    612794    id    DEFAULT     ~   ALTER TABLE ONLY "public"."localidades" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."localidades_id_seq"'::"regclass");
 C   ALTER TABLE "public"."localidades" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    224    223            �	           2604    612795    id    DEFAULT     �   ALTER TABLE ONLY "public"."nacionalidades" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."nacionalidades_id_seq"'::"regclass");
 F   ALTER TABLE "public"."nacionalidades" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    226    225            �	           2604    612796    id    DEFAULT     �   ALTER TABLE ONLY "public"."obras_sociales" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."obras_sociales_id_seq"'::"regclass");
 F   ALTER TABLE "public"."obras_sociales" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    228    227            �	           2604    612797    id    DEFAULT     t   ALTER TABLE ONLY "public"."paises" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."paises_id_seq"'::"regclass");
 >   ALTER TABLE "public"."paises" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    230    229            �	           2604    612798    id    DEFAULT     x   ALTER TABLE ONLY "public"."periodos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."periodos_id_seq"'::"regclass");
 @   ALTER TABLE "public"."periodos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    234    231            �	           2604    612799    id    DEFAULT     �   ALTER TABLE ONLY "public"."periodos_detalle" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."periodos_detalle_id_seq"'::"regclass");
 H   ALTER TABLE "public"."periodos_detalle" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    233    232            �	           2604    612800    id    DEFAULT     �   ALTER TABLE ONLY "public"."persona_tareas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."persona_tareas_id_seq"'::"regclass");
 F   ALTER TABLE "public"."persona_tareas" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    236    235            �	           2604    612801    id    DEFAULT     x   ALTER TABLE ONLY "public"."personas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."personas_id_seq"'::"regclass");
 @   ALTER TABLE "public"."personas" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    240    237            �	           2604    612802    id    DEFAULT     �   ALTER TABLE ONLY "public"."personas_conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."personas_conceptos_id_seq"'::"regclass");
 J   ALTER TABLE "public"."personas_conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    239    238            �	           2604    612803    id    DEFAULT     �   ALTER TABLE ONLY "public"."personas_jornadas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."personas_jornadas_id_seq"'::"regclass");
 I   ALTER TABLE "public"."personas_jornadas" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    242    241            �	           2604    612804    id    DEFAULT     |   ALTER TABLE ONLY "public"."provincias" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."provincias_id_seq"'::"regclass");
 B   ALTER TABLE "public"."provincias" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    244    243            �	           2604    612805    id    DEFAULT     v   ALTER TABLE ONLY "public"."recibos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."recibos_id_seq"'::"regclass");
 ?   ALTER TABLE "public"."recibos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    250    245            �	           2604    612806    id    DEFAULT     �   ALTER TABLE ONLY "public"."recibos_acumuladores" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."recibos_acumuladores_id_seq"'::"regclass");
 L   ALTER TABLE "public"."recibos_acumuladores" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    247    246            �	           2604    612807    id    DEFAULT     �   ALTER TABLE ONLY "public"."recibos_conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."recibos_conceptos_id_seq"'::"regclass");
 I   ALTER TABLE "public"."recibos_conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    249    248            �	           2604    612808    id    DEFAULT     z   ALTER TABLE ONLY "public"."regimenes" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."regimenes_id_seq"'::"regclass");
 A   ALTER TABLE "public"."regimenes" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    252    251            �	           2604    612809    id    DEFAULT     r   ALTER TABLE ONLY "public"."tabla" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tabla_id_seq"'::"regclass");
 =   ALTER TABLE "public"."tabla" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    260    253            �	           2604    612810    id    DEFAULT     �   ALTER TABLE ONLY "public"."tabla_detalle" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tabla_detalle_id_seq"'::"regclass");
 E   ALTER TABLE "public"."tabla_detalle" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    255    254            �	           2604    612811    id    DEFAULT     �   ALTER TABLE ONLY "public"."tabla_ganancias" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tabla_ganancias_id_seq"'::"regclass");
 G   ALTER TABLE "public"."tabla_ganancias" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    259    256            �	           2604    612812    id    DEFAULT     �   ALTER TABLE ONLY "public"."tabla_ganancias_detalle" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tabla_ganancias_detalle_id_seq"'::"regclass");
 O   ALTER TABLE "public"."tabla_ganancias_detalle" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    258    257            �	           2604    612813    id    DEFAULT     �   ALTER TABLE ONLY "public"."tabla_personas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tabla_personas_id_seq"'::"regclass");
 F   ALTER TABLE "public"."tabla_personas" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    262    261            �	           2604    612814    id    DEFAULT     t   ALTER TABLE ONLY "public"."tareas" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tareas_id_seq"'::"regclass");
 >   ALTER TABLE "public"."tareas" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    266    265            �	           2604    612815    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipo_liquidacion_conceptos_id_seq"'::"regclass");
 R   ALTER TABLE "public"."tipo_liquidacion_conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    268    267            �	           2604    612816    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipos_conceptos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_conceptos_id_seq"'::"regclass");
 G   ALTER TABLE "public"."tipos_conceptos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    270    269            �	           2604    612817    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipos_contratos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_contratos_id_seq"'::"regclass");
 G   ALTER TABLE "public"."tipos_contratos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    272    271            �	           2604    612818    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipos_documentos" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_documentos_id_seq"'::"regclass");
 H   ALTER TABLE "public"."tipos_documentos" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    274    273            �	           2604    612819    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipos_empleadores" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_empleadores_id_seq"'::"regclass");
 I   ALTER TABLE "public"."tipos_empleadores" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    276    275            �	           2604    612820    id    DEFAULT     �   ALTER TABLE ONLY "public"."tipos_liquidaciones" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."tipos_liquidaciones_id_seq"'::"regclass");
 K   ALTER TABLE "public"."tipos_liquidaciones" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    278    277            �	           2604    612821    id    DEFAULT     |   ALTER TABLE ONLY "public"."vacaciones" ALTER COLUMN "id" SET DEFAULT "nextval"('"public"."vacaciones_id_seq"'::"regclass");
 B   ALTER TABLE "public"."vacaciones" ALTER COLUMN "id" DROP DEFAULT;
       public       postgres    false    294    293            �	           2604    612822    id    DEFAULT     ~   ALTER TABLE ONLY "sistema"."reservadas" ALTER COLUMN "id" SET DEFAULT "nextval"('"sistema"."reservadas_id_seq"'::"regclass");
 C   ALTER TABLE "sistema"."reservadas" ALTER COLUMN "id" DROP DEFAULT;
       sistema       postgres    false    296    295            �	           2604    612823    id    DEFAULT     �   ALTER TABLE ONLY "sistema"."tipos_datos" ALTER COLUMN "id" SET DEFAULT "nextval"('"sistema"."tipos_datos_id_seq"'::"regclass");
 D   ALTER TABLE "sistema"."tipos_datos" ALTER COLUMN "id" DROP DEFAULT;
       sistema       postgres    false    298    297            �	           2604    612824    id    DEFAULT     �   ALTER TABLE ONLY "sistema"."tipos_reservadas" ALTER COLUMN "id" SET DEFAULT "nextval"('"sistema"."tipos_reservadas_id_seq"'::"regclass");
 I   ALTER TABLE "sistema"."tipos_reservadas" ALTER COLUMN "id" DROP DEFAULT;
       sistema       postgres    false    300    299            F          0    612319    acumuladores 
   TABLE DATA                     public       postgres    false    182   G�      �           0    0    acumuladores_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('"public"."acumuladores_id_seq"', 5, true);
            public       postgres    false    183            H          0    612329    back_sueldo_basico 
   TABLE DATA                     public       postgres    false    184   n�      I          0    612332    bancos 
   TABLE DATA                     public       postgres    false    185   ��      �           0    0    bancos_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('"public"."bancos_id_seq"', 1, true);
            public       postgres    false    186            K          0    612340 
   categorias 
   TABLE DATA                     public       postgres    false    187   ��      �           0    0    categorias_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('"public"."categorias_id_seq"', 5, false);
            public       postgres    false    188            M          0    612348 	   conceptos 
   TABLE DATA                     public       postgres    false    189   ��      �           0    0    conceptos_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('"public"."conceptos_id_seq"', 53, true);
            public       postgres    false    190            O          0    612361    conceptos_personas 
   TABLE DATA                     public       postgres    false    191   ��      P          0    612364    datos_actuales 
   TABLE DATA                     public       postgres    false    192   �      �           0    0    datos_actuales_id_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('"public"."datos_actuales_id_seq"', 1, true);
            public       postgres    false    193            R          0    612372    datos_laborales 
   TABLE DATA                     public       postgres    false    194   -�      �           0    0    datos_laborales_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."datos_laborales_id_seq"', 1, true);
            public       postgres    false    195            T          0    612377    datos_salud 
   TABLE DATA                     public       postgres    false    196   G�      �           0    0    datos_salud_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('"public"."datos_salud_id_seq"', 1, true);
            public       postgres    false    197            V          0    612382    establecimientos 
   TABLE DATA                     public       postgres    false    198   a�      �           0    0    establecimientos_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('"public"."establecimientos_id_seq"', 1, false);
            public       postgres    false    199            X          0    612390    estados_civiles 
   TABLE DATA                     public       postgres    false    200   2�      �           0    0    estados_civiles_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('"public"."estados_civiles_id_seq"', 1, false);
            public       postgres    false    201            Z          0    612398    estados_liquidacion 
   TABLE DATA                     public       postgres    false    202   ��      �           0    0    estados_liquidacion_id_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('"public"."estados_liquidacion_id_seq"', 1, false);
            public       postgres    false    203            \          0    612403    feriados 
   TABLE DATA                     public       postgres    false    204   O�      �           0    0    feriados_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('"public"."feriados_id_seq"', 1, false);
            public       postgres    false    205            ^          0    612411    fichajes 
   TABLE DATA                     public       postgres    false    206   i�      �           0    0    fichajes_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('"public"."fichajes_id_seq"', 1, false);
            public       postgres    false    207            `          0    612416    generos 
   TABLE DATA                     public       postgres    false    208   ��      �           0    0    generos_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('"public"."generos_id_seq"', 1, false);
            public       postgres    false    209            b          0    612424    historico_liquidaciones 
   TABLE DATA                     public       postgres    false    210   ��      c          0    612432 !   historico_liquidaciones_conceptos 
   TABLE DATA                     public       postgres    false    211   ��      d          0    612438    historico_recibos 
   TABLE DATA                     public       postgres    false    212   f�      e          0    612444    historico_recibos_acumuladores 
   TABLE DATA                     public       postgres    false    213   �      f          0    612450    historico_recibos_conceptos 
   TABLE DATA                     public       postgres    false    214   �      g          0    612456    historico_sueldo_basico 
   TABLE DATA                     public       postgres    false    215   �K      h          0    612460    historico_sueldo_basico_detalle 
   TABLE DATA                     public       postgres    false    216   �L      �           0    0 &   historico_sueldo_basico_detalle_id_seq    SEQUENCE SET     Z   SELECT pg_catalog.setval('"public"."historico_sueldo_basico_detalle_id_seq"', 243, true);
            public       postgres    false    217            �           0    0    historico_sueldo_basico_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('"public"."historico_sueldo_basico_id_seq"', 22, true);
            public       postgres    false    218            k          0    612467    liquidaciones 
   TABLE DATA                     public       postgres    false    219   �P      l          0    612475    liquidaciones_conceptos 
   TABLE DATA                     public       postgres    false    220   R      �           0    0    liquidaciones_conceptos_id_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('"public"."liquidaciones_conceptos_id_seq"', 2871, true);
            public       postgres    false    221            �           0    0    liquidaciones_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."liquidaciones_id_seq"', 114, true);
            public       postgres    false    222            o          0    612482    localidades 
   TABLE DATA                     public       postgres    false    223   �U      �           0    0    localidades_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('"public"."localidades_id_seq"', 1, true);
            public       postgres    false    224            q          0    612487    nacionalidades 
   TABLE DATA                     public       postgres    false    225   PV      �           0    0    nacionalidades_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."nacionalidades_id_seq"', 1, false);
            public       postgres    false    226            s          0    612495    obras_sociales 
   TABLE DATA                     public       postgres    false    227   �V      �           0    0    obras_sociales_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."obras_sociales_id_seq"', 1, false);
            public       postgres    false    228            u          0    612503    paises 
   TABLE DATA                     public       postgres    false    229   �W      �           0    0    paises_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('"public"."paises_id_seq"', 1, true);
            public       postgres    false    230            w          0    612508    periodos 
   TABLE DATA                     public       postgres    false    231   (X      x          0    612514    periodos_detalle 
   TABLE DATA                     public       postgres    false    232   1Y      �           0    0    periodos_detalle_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('"public"."periodos_detalle_id_seq"', 62, true);
            public       postgres    false    233            �           0    0    periodos_id_seq    SEQUENCE SET     A   SELECT pg_catalog.setval('"public"."periodos_id_seq"', 5, true);
            public       postgres    false    234            {          0    612523    persona_tareas 
   TABLE DATA                     public       postgres    false    235   �[                  0    0    persona_tareas_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."persona_tareas_id_seq"', 38, true);
            public       postgres    false    236            }          0    612528    personas 
   TABLE DATA                     public       postgres    false    237   �\      ~          0    612536    personas_conceptos 
   TABLE DATA                     public       postgres    false    238   Zc                 0    0    personas_conceptos_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('"public"."personas_conceptos_id_seq"', 1, true);
            public       postgres    false    239                       0    0    personas_id_seq    SEQUENCE SET     B   SELECT pg_catalog.setval('"public"."personas_id_seq"', 26, true);
            public       postgres    false    240            �          0    612543    personas_jornadas 
   TABLE DATA                     public       postgres    false    241   �c                 0    0    personas_jornadas_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('"public"."personas_jornadas_id_seq"', 1, false);
            public       postgres    false    242            �          0    612548 
   provincias 
   TABLE DATA                     public       postgres    false    243   �c                 0    0    provincias_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('"public"."provincias_id_seq"', 24, true);
            public       postgres    false    244            �          0    612556    recibos 
   TABLE DATA                     public       postgres    false    245   \e      �          0    612562    recibos_acumuladores 
   TABLE DATA                     public       postgres    false    246   �                 0    0    recibos_acumuladores_id_seq    SEQUENCE SET     P   SELECT pg_catalog.setval('"public"."recibos_acumuladores_id_seq"', 9860, true);
            public       postgres    false    247            �          0    612567    recibos_conceptos 
   TABLE DATA                     public       postgres    false    248   ��                 0    0    recibos_conceptos_id_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('"public"."recibos_conceptos_id_seq"', 57663, true);
            public       postgres    false    249                       0    0    recibos_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('"public"."recibos_id_seq"', 1876, true);
            public       postgres    false    250            �          0    612574 	   regimenes 
   TABLE DATA                     public       postgres    false    251   �                 0    0    regimenes_id_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('"public"."regimenes_id_seq"', 1, false);
            public       postgres    false    252            �          0    612582    tabla 
   TABLE DATA                     public       postgres    false    253   ��      �          0    612588    tabla_detalle 
   TABLE DATA                     public       postgres    false    254   ��      	           0    0    tabla_detalle_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."tabla_detalle_id_seq"', 120, true);
            public       postgres    false    255            �          0    612593    tabla_ganancias 
   TABLE DATA                     public       postgres    false    256   ��      �          0    612599    tabla_ganancias_detalle 
   TABLE DATA                     public       postgres    false    257   /�      
           0    0    tabla_ganancias_detalle_id_seq    SEQUENCE SET     Q   SELECT pg_catalog.setval('"public"."tabla_ganancias_detalle_id_seq"', 34, true);
            public       postgres    false    258                       0    0    tabla_ganancias_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."tabla_ganancias_id_seq"', 2, true);
            public       postgres    false    259                       0    0    tabla_id_seq    SEQUENCE SET     ?   SELECT pg_catalog.setval('"public"."tabla_id_seq"', 11, true);
            public       postgres    false    260            �          0    612608    tabla_personas 
   TABLE DATA                     public       postgres    false    261   ��                 0    0    tabla_personas_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."tabla_personas_id_seq"', 24, true);
            public       postgres    false    262            �          0    612613    tabla_vacaciones 
   TABLE DATA                     public       postgres    false    263   �      �          0    612616    tabla_vacaciones_dias 
   TABLE DATA                     public       postgres    false    264   ��      �          0    612622    tareas 
   TABLE DATA                     public       postgres    false    265   ��                 0    0    tareas_id_seq    SEQUENCE SET     @   SELECT pg_catalog.setval('"public"."tareas_id_seq"', 1, false);
            public       postgres    false    266            �          0    612630    tipo_liquidacion_conceptos 
   TABLE DATA                     public       postgres    false    267   ��                 0    0 !   tipo_liquidacion_conceptos_id_seq    SEQUENCE SET     U   SELECT pg_catalog.setval('"public"."tipo_liquidacion_conceptos_id_seq"', 133, true);
            public       postgres    false    268            �          0    612635    tipos_conceptos 
   TABLE DATA                     public       postgres    false    269   r�                 0    0    tipos_conceptos_id_seq    SEQUENCE SET     H   SELECT pg_catalog.setval('"public"."tipos_conceptos_id_seq"', 4, true);
            public       postgres    false    270            �          0    612643    tipos_contratos 
   TABLE DATA                     public       postgres    false    271   6                  0    0    tipos_contratos_id_seq    SEQUENCE SET     I   SELECT pg_catalog.setval('"public"."tipos_contratos_id_seq"', 1, false);
            public       postgres    false    272            �          0    612651    tipos_documentos 
   TABLE DATA                     public       postgres    false    273   �                  0    0    tipos_documentos_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('"public"."tipos_documentos_id_seq"', 1, false);
            public       postgres    false    274            �          0    612659    tipos_empleadores 
   TABLE DATA                     public       postgres    false    275   K                 0    0    tipos_empleadores_id_seq    SEQUENCE SET     J   SELECT pg_catalog.setval('"public"."tipos_empleadores_id_seq"', 1, true);
            public       postgres    false    276            �          0    612667    tipos_liquidaciones 
   TABLE DATA                     public       postgres    false    277   �                 0    0    tipos_liquidaciones_id_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('"public"."tipos_liquidaciones_id_seq"', 6, true);
            public       postgres    false    278            �          0    612741 
   vacaciones 
   TABLE DATA                     public       postgres    false    293   �                 0    0    vacaciones_id_seq    SEQUENCE SET     D   SELECT pg_catalog.setval('"public"."vacaciones_id_seq"', 1, false);
            public       postgres    false    294            �          0    612749 
   reservadas 
   TABLE DATA                     sistema       postgres    false    295   �                 0    0    reservadas_id_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('"sistema"."reservadas_id_seq"', 28, true);
            sistema       postgres    false    296            �          0    612757    tipos_datos 
   TABLE DATA                     sistema       postgres    false    297   �                 0    0    tipos_datos_id_seq    SEQUENCE SET     F   SELECT pg_catalog.setval('"sistema"."tipos_datos_id_seq"', 1, false);
            sistema       postgres    false    298            �          0    612765    tipos_reservadas 
   TABLE DATA                     sistema       postgres    false    299   t                 0    0    tipos_reservadas_id_seq    SEQUENCE SET     K   SELECT pg_catalog.setval('"sistema"."tipos_reservadas_id_seq"', 1, false);
            sistema       postgres    false    300            C
           2606    612827 )   persona_tareas_id_persona_id_tarea_unique 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."persona_tareas"
    ADD CONSTRAINT "persona_tareas_id_persona_id_tarea_unique" UNIQUE ("id_persona", "id_tarea");
 h   ALTER TABLE ONLY "public"."persona_tareas" DROP CONSTRAINT "persona_tareas_id_persona_id_tarea_unique";
       public         postgres    false    235    235    235            �	           2606    612829    pk_acumuladores 
   CONSTRAINT     b   ALTER TABLE ONLY "public"."acumuladores"
    ADD CONSTRAINT "pk_acumuladores" PRIMARY KEY ("id");
 L   ALTER TABLE ONLY "public"."acumuladores" DROP CONSTRAINT "pk_acumuladores";
       public         postgres    false    182    182            �	           2606    612831 	   pk_bancos 
   CONSTRAINT     V   ALTER TABLE ONLY "public"."bancos"
    ADD CONSTRAINT "pk_bancos" PRIMARY KEY ("id");
 @   ALTER TABLE ONLY "public"."bancos" DROP CONSTRAINT "pk_bancos";
       public         postgres    false    185    185            �	           2606    612833    pk_categorias 
   CONSTRAINT     ^   ALTER TABLE ONLY "public"."categorias"
    ADD CONSTRAINT "pk_categorias" PRIMARY KEY ("id");
 H   ALTER TABLE ONLY "public"."categorias" DROP CONSTRAINT "pk_categorias";
       public         postgres    false    187    187            �	           2606    612835    pk_conceptos 
   CONSTRAINT     \   ALTER TABLE ONLY "public"."conceptos"
    ADD CONSTRAINT "pk_conceptos" PRIMARY KEY ("id");
 F   ALTER TABLE ONLY "public"."conceptos" DROP CONSTRAINT "pk_conceptos";
       public         postgres    false    189    189            
           2606    612837    pk_conceptos_personas 
   CONSTRAINT     n   ALTER TABLE ONLY "public"."conceptos_personas"
    ADD CONSTRAINT "pk_conceptos_personas" PRIMARY KEY ("id");
 X   ALTER TABLE ONLY "public"."conceptos_personas" DROP CONSTRAINT "pk_conceptos_personas";
       public         postgres    false    191    191            
           2606    612839    pk_datos_actuales 
   CONSTRAINT     f   ALTER TABLE ONLY "public"."datos_actuales"
    ADD CONSTRAINT "pk_datos_actuales" PRIMARY KEY ("id");
 P   ALTER TABLE ONLY "public"."datos_actuales" DROP CONSTRAINT "pk_datos_actuales";
       public         postgres    false    192    192            	
           2606    612841    pk_datos_laborales 
   CONSTRAINT     h   ALTER TABLE ONLY "public"."datos_laborales"
    ADD CONSTRAINT "pk_datos_laborales" PRIMARY KEY ("id");
 R   ALTER TABLE ONLY "public"."datos_laborales" DROP CONSTRAINT "pk_datos_laborales";
       public         postgres    false    194    194            
           2606    612843    pk_datos_salud 
   CONSTRAINT     `   ALTER TABLE ONLY "public"."datos_salud"
    ADD CONSTRAINT "pk_datos_salud" PRIMARY KEY ("id");
 J   ALTER TABLE ONLY "public"."datos_salud" DROP CONSTRAINT "pk_datos_salud";
       public         postgres    false    196    196            
           2606    612845    pk_establecimientos 
   CONSTRAINT     j   ALTER TABLE ONLY "public"."establecimientos"
    ADD CONSTRAINT "pk_establecimientos" PRIMARY KEY ("id");
 T   ALTER TABLE ONLY "public"."establecimientos" DROP CONSTRAINT "pk_establecimientos";
       public         postgres    false    198    198            
           2606    612847    pk_estados_civiles 
   CONSTRAINT     h   ALTER TABLE ONLY "public"."estados_civiles"
    ADD CONSTRAINT "pk_estados_civiles" PRIMARY KEY ("id");
 R   ALTER TABLE ONLY "public"."estados_civiles" DROP CONSTRAINT "pk_estados_civiles";
       public         postgres    false    200    200            
           2606    612849    pk_estados_liquidacion 
   CONSTRAINT     p   ALTER TABLE ONLY "public"."estados_liquidacion"
    ADD CONSTRAINT "pk_estados_liquidacion" PRIMARY KEY ("id");
 Z   ALTER TABLE ONLY "public"."estados_liquidacion" DROP CONSTRAINT "pk_estados_liquidacion";
       public         postgres    false    202    202            
           2606    612851    pk_feriados 
   CONSTRAINT     Z   ALTER TABLE ONLY "public"."feriados"
    ADD CONSTRAINT "pk_feriados" PRIMARY KEY ("id");
 D   ALTER TABLE ONLY "public"."feriados" DROP CONSTRAINT "pk_feriados";
       public         postgres    false    204    204            
           2606    612853    pk_fichajes 
   CONSTRAINT     Z   ALTER TABLE ONLY "public"."fichajes"
    ADD CONSTRAINT "pk_fichajes" PRIMARY KEY ("id");
 D   ALTER TABLE ONLY "public"."fichajes" DROP CONSTRAINT "pk_fichajes";
       public         postgres    false    206    206            
           2606    612855 
   pk_generos 
   CONSTRAINT     X   ALTER TABLE ONLY "public"."generos"
    ADD CONSTRAINT "pk_generos" PRIMARY KEY ("id");
 B   ALTER TABLE ONLY "public"."generos" DROP CONSTRAINT "pk_generos";
       public         postgres    false    208    208            +
           2606    612857    pk_historico_sueldo_basico 
   CONSTRAINT     x   ALTER TABLE ONLY "public"."historico_sueldo_basico"
    ADD CONSTRAINT "pk_historico_sueldo_basico" PRIMARY KEY ("id");
 b   ALTER TABLE ONLY "public"."historico_sueldo_basico" DROP CONSTRAINT "pk_historico_sueldo_basico";
       public         postgres    false    215    215            -
           2606    612859 "   pk_historico_sueldo_basico_detalle 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_sueldo_basico_detalle"
    ADD CONSTRAINT "pk_historico_sueldo_basico_detalle" PRIMARY KEY ("id");
 r   ALTER TABLE ONLY "public"."historico_sueldo_basico_detalle" DROP CONSTRAINT "pk_historico_sueldo_basico_detalle";
       public         postgres    false    216    216            �
           2606    612861    pk_liquidaciones 
   CONSTRAINT     j   ALTER TABLE ONLY "public"."tipos_liquidaciones"
    ADD CONSTRAINT "pk_liquidaciones" PRIMARY KEY ("id");
 T   ALTER TABLE ONLY "public"."tipos_liquidaciones" DROP CONSTRAINT "pk_liquidaciones";
       public         postgres    false    277    277            /
           2606    612863    pk_liquidaciones2 
   CONSTRAINT     e   ALTER TABLE ONLY "public"."liquidaciones"
    ADD CONSTRAINT "pk_liquidaciones2" PRIMARY KEY ("id");
 O   ALTER TABLE ONLY "public"."liquidaciones" DROP CONSTRAINT "pk_liquidaciones2";
       public         postgres    false    219    219            1
           2606    612865    pk_liquidaciones_conceptos 
   CONSTRAINT     x   ALTER TABLE ONLY "public"."liquidaciones_conceptos"
    ADD CONSTRAINT "pk_liquidaciones_conceptos" PRIMARY KEY ("id");
 b   ALTER TABLE ONLY "public"."liquidaciones_conceptos" DROP CONSTRAINT "pk_liquidaciones_conceptos";
       public         postgres    false    220    220            
           2606    612867 $   pk_liquidaciones_conceptos_historico 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_liquidaciones_conceptos"
    ADD CONSTRAINT "pk_liquidaciones_conceptos_historico" PRIMARY KEY ("id");
 v   ALTER TABLE ONLY "public"."historico_liquidaciones_conceptos" DROP CONSTRAINT "pk_liquidaciones_conceptos_historico";
       public         postgres    false    211    211            
           2606    612869    pk_liquidaciones_historico 
   CONSTRAINT     x   ALTER TABLE ONLY "public"."historico_liquidaciones"
    ADD CONSTRAINT "pk_liquidaciones_historico" PRIMARY KEY ("id");
 b   ALTER TABLE ONLY "public"."historico_liquidaciones" DROP CONSTRAINT "pk_liquidaciones_historico";
       public         postgres    false    210    210            5
           2606    612871    pk_localidad 
   CONSTRAINT     ^   ALTER TABLE ONLY "public"."localidades"
    ADD CONSTRAINT "pk_localidad" PRIMARY KEY ("id");
 H   ALTER TABLE ONLY "public"."localidades" DROP CONSTRAINT "pk_localidad";
       public         postgres    false    223    223            7
           2606    612873    pk_nacionalidades 
   CONSTRAINT     f   ALTER TABLE ONLY "public"."nacionalidades"
    ADD CONSTRAINT "pk_nacionalidades" PRIMARY KEY ("id");
 P   ALTER TABLE ONLY "public"."nacionalidades" DROP CONSTRAINT "pk_nacionalidades";
       public         postgres    false    225    225            9
           2606    612875    pk_obras_sociales 
   CONSTRAINT     f   ALTER TABLE ONLY "public"."obras_sociales"
    ADD CONSTRAINT "pk_obras_sociales" PRIMARY KEY ("id");
 P   ALTER TABLE ONLY "public"."obras_sociales" DROP CONSTRAINT "pk_obras_sociales";
       public         postgres    false    227    227            ;
           2606    612877 	   pk_paises 
   CONSTRAINT     V   ALTER TABLE ONLY "public"."paises"
    ADD CONSTRAINT "pk_paises" PRIMARY KEY ("id");
 @   ALTER TABLE ONLY "public"."paises" DROP CONSTRAINT "pk_paises";
       public         postgres    false    229    229            A
           2606    612879    pk_periodo_detalle 
   CONSTRAINT     i   ALTER TABLE ONLY "public"."periodos_detalle"
    ADD CONSTRAINT "pk_periodo_detalle" PRIMARY KEY ("id");
 S   ALTER TABLE ONLY "public"."periodos_detalle" DROP CONSTRAINT "pk_periodo_detalle";
       public         postgres    false    232    232            =
           2606    612881    pk_periodos 
   CONSTRAINT     Z   ALTER TABLE ONLY "public"."periodos"
    ADD CONSTRAINT "pk_periodos" PRIMARY KEY ("id");
 D   ALTER TABLE ONLY "public"."periodos" DROP CONSTRAINT "pk_periodos";
       public         postgres    false    231    231            E
           2606    612883    pk_persona_tareas 
   CONSTRAINT     f   ALTER TABLE ONLY "public"."persona_tareas"
    ADD CONSTRAINT "pk_persona_tareas" PRIMARY KEY ("id");
 P   ALTER TABLE ONLY "public"."persona_tareas" DROP CONSTRAINT "pk_persona_tareas";
       public         postgres    false    235    235            G
           2606    612885    pk_personas 
   CONSTRAINT     Z   ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "pk_personas" PRIMARY KEY ("id");
 D   ALTER TABLE ONLY "public"."personas" DROP CONSTRAINT "pk_personas";
       public         postgres    false    237    237            K
           2606    612887    pk_personas_conceptos 
   CONSTRAINT     n   ALTER TABLE ONLY "public"."personas_conceptos"
    ADD CONSTRAINT "pk_personas_conceptos" PRIMARY KEY ("id");
 X   ALTER TABLE ONLY "public"."personas_conceptos" DROP CONSTRAINT "pk_personas_conceptos";
       public         postgres    false    238    238            O
           2606    612889    pk_personas_jornadas 
   CONSTRAINT     l   ALTER TABLE ONLY "public"."personas_jornadas"
    ADD CONSTRAINT "pk_personas_jornadas" PRIMARY KEY ("id");
 V   ALTER TABLE ONLY "public"."personas_jornadas" DROP CONSTRAINT "pk_personas_jornadas";
       public         postgres    false    241    241            Q
           2606    612891    pk_provincias 
   CONSTRAINT     ^   ALTER TABLE ONLY "public"."provincias"
    ADD CONSTRAINT "pk_provincias" PRIMARY KEY ("id");
 H   ALTER TABLE ONLY "public"."provincias" DROP CONSTRAINT "pk_provincias";
       public         postgres    false    243    243            S
           2606    612893 
   pk_recibos 
   CONSTRAINT     X   ALTER TABLE ONLY "public"."recibos"
    ADD CONSTRAINT "pk_recibos" PRIMARY KEY ("id");
 B   ALTER TABLE ONLY "public"."recibos" DROP CONSTRAINT "pk_recibos";
       public         postgres    false    245    245            W
           2606    612895    pk_recibos_acumuladores 
   CONSTRAINT     r   ALTER TABLE ONLY "public"."recibos_acumuladores"
    ADD CONSTRAINT "pk_recibos_acumuladores" PRIMARY KEY ("id");
 \   ALTER TABLE ONLY "public"."recibos_acumuladores" DROP CONSTRAINT "pk_recibos_acumuladores";
       public         postgres    false    246    246            #
           2606    612897 !   pk_recibos_acumuladores_historico 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_acumuladores"
    ADD CONSTRAINT "pk_recibos_acumuladores_historico" PRIMARY KEY ("id");
 p   ALTER TABLE ONLY "public"."historico_recibos_acumuladores" DROP CONSTRAINT "pk_recibos_acumuladores_historico";
       public         postgres    false    213    213            [
           2606    612899    pk_recibos_conceptos 
   CONSTRAINT     l   ALTER TABLE ONLY "public"."recibos_conceptos"
    ADD CONSTRAINT "pk_recibos_conceptos" PRIMARY KEY ("id");
 V   ALTER TABLE ONLY "public"."recibos_conceptos" DROP CONSTRAINT "pk_recibos_conceptos";
       public         postgres    false    248    248            '
           2606    612901    pk_recibos_conceptos_historico 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_conceptos"
    ADD CONSTRAINT "pk_recibos_conceptos_historico" PRIMARY KEY ("id");
 j   ALTER TABLE ONLY "public"."historico_recibos_conceptos" DROP CONSTRAINT "pk_recibos_conceptos_historico";
       public         postgres    false    214    214            
           2606    612903    pk_recibos_historico 
   CONSTRAINT     l   ALTER TABLE ONLY "public"."historico_recibos"
    ADD CONSTRAINT "pk_recibos_historico" PRIMARY KEY ("id");
 V   ALTER TABLE ONLY "public"."historico_recibos" DROP CONSTRAINT "pk_recibos_historico";
       public         postgres    false    212    212            _
           2606    612905    pk_regimenes 
   CONSTRAINT     \   ALTER TABLE ONLY "public"."regimenes"
    ADD CONSTRAINT "pk_regimenes" PRIMARY KEY ("id");
 F   ALTER TABLE ONLY "public"."regimenes" DROP CONSTRAINT "pk_regimenes";
       public         postgres    false    251    251            a
           2606    612907    pk_tabla 
   CONSTRAINT     T   ALTER TABLE ONLY "public"."tabla"
    ADD CONSTRAINT "pk_tabla" PRIMARY KEY ("id");
 >   ALTER TABLE ONLY "public"."tabla" DROP CONSTRAINT "pk_tabla";
       public         postgres    false    253    253            e
           2606    612909    pk_tabla_detalle 
   CONSTRAINT     d   ALTER TABLE ONLY "public"."tabla_detalle"
    ADD CONSTRAINT "pk_tabla_detalle" PRIMARY KEY ("id");
 N   ALTER TABLE ONLY "public"."tabla_detalle" DROP CONSTRAINT "pk_tabla_detalle";
       public         postgres    false    254    254            i
           2606    612911    pk_tabla_ganancias 
   CONSTRAINT     h   ALTER TABLE ONLY "public"."tabla_ganancias"
    ADD CONSTRAINT "pk_tabla_ganancias" PRIMARY KEY ("id");
 R   ALTER TABLE ONLY "public"."tabla_ganancias" DROP CONSTRAINT "pk_tabla_ganancias";
       public         postgres    false    256    256            m
           2606    612913    pk_tabla_ganancias_detalle 
   CONSTRAINT     x   ALTER TABLE ONLY "public"."tabla_ganancias_detalle"
    ADD CONSTRAINT "pk_tabla_ganancias_detalle" PRIMARY KEY ("id");
 b   ALTER TABLE ONLY "public"."tabla_ganancias_detalle" DROP CONSTRAINT "pk_tabla_ganancias_detalle";
       public         postgres    false    257    257            o
           2606    612915    pk_tabla_personas 
   CONSTRAINT     f   ALTER TABLE ONLY "public"."tabla_personas"
    ADD CONSTRAINT "pk_tabla_personas" PRIMARY KEY ("id");
 P   ALTER TABLE ONLY "public"."tabla_personas" DROP CONSTRAINT "pk_tabla_personas";
       public         postgres    false    261    261            s
           2606    612917    pk_tabla_vacaciones 
   CONSTRAINT     j   ALTER TABLE ONLY "public"."tabla_vacaciones"
    ADD CONSTRAINT "pk_tabla_vacaciones" PRIMARY KEY ("id");
 T   ALTER TABLE ONLY "public"."tabla_vacaciones" DROP CONSTRAINT "pk_tabla_vacaciones";
       public         postgres    false    263    263            u
           2606    612919    pk_tabla_vacaciones_dias 
   CONSTRAINT     t   ALTER TABLE ONLY "public"."tabla_vacaciones_dias"
    ADD CONSTRAINT "pk_tabla_vacaciones_dias" PRIMARY KEY ("id");
 ^   ALTER TABLE ONLY "public"."tabla_vacaciones_dias" DROP CONSTRAINT "pk_tabla_vacaciones_dias";
       public         postgres    false    264    264            w
           2606    612921 	   pk_tareas 
   CONSTRAINT     V   ALTER TABLE ONLY "public"."tareas"
    ADD CONSTRAINT "pk_tareas" PRIMARY KEY ("id");
 @   ALTER TABLE ONLY "public"."tareas" DROP CONSTRAINT "pk_tareas";
       public         postgres    false    265    265            y
           2606    612923    pk_tipo_liquidacion_conceptos 
   CONSTRAINT     ~   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos"
    ADD CONSTRAINT "pk_tipo_liquidacion_conceptos" PRIMARY KEY ("id");
 h   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos" DROP CONSTRAINT "pk_tipo_liquidacion_conceptos";
       public         postgres    false    267    267            }
           2606    612925    pk_tipos_conceptos 
   CONSTRAINT     h   ALTER TABLE ONLY "public"."tipos_conceptos"
    ADD CONSTRAINT "pk_tipos_conceptos" PRIMARY KEY ("id");
 R   ALTER TABLE ONLY "public"."tipos_conceptos" DROP CONSTRAINT "pk_tipos_conceptos";
       public         postgres    false    269    269            �
           2606    612927    pk_tipos_documentos 
   CONSTRAINT     j   ALTER TABLE ONLY "public"."tipos_documentos"
    ADD CONSTRAINT "pk_tipos_documentos" PRIMARY KEY ("id");
 T   ALTER TABLE ONLY "public"."tipos_documentos" DROP CONSTRAINT "pk_tipos_documentos";
       public         postgres    false    273    273            �
           2606    612929    pk_tipos_empleadores 
   CONSTRAINT     l   ALTER TABLE ONLY "public"."tipos_empleadores"
    ADD CONSTRAINT "pk_tipos_empleadores" PRIMARY KEY ("id");
 V   ALTER TABLE ONLY "public"."tipos_empleadores" DROP CONSTRAINT "pk_tipos_empleadores";
       public         postgres    false    275    275            �
           2606    612931    pk_vacaciones 
   CONSTRAINT     ^   ALTER TABLE ONLY "public"."vacaciones"
    ADD CONSTRAINT "pk_vacaciones" PRIMARY KEY ("id");
 H   ALTER TABLE ONLY "public"."vacaciones" DROP CONSTRAINT "pk_vacaciones";
       public         postgres    false    293    293            
           2606    612933    tipos_contratos_pkey 
   CONSTRAINT     j   ALTER TABLE ONLY "public"."tipos_contratos"
    ADD CONSTRAINT "tipos_contratos_pkey" PRIMARY KEY ("id");
 T   ALTER TABLE ONLY "public"."tipos_contratos" DROP CONSTRAINT "tipos_contratos_pkey";
       public         postgres    false    271    271            
           2606    612935    uk_conceptos 
   CONSTRAINT     [   ALTER TABLE ONLY "public"."conceptos"
    ADD CONSTRAINT "uk_conceptos" UNIQUE ("codigo");
 F   ALTER TABLE ONLY "public"."conceptos" DROP CONSTRAINT "uk_conceptos";
       public         postgres    false    189    189            
           2606    612937    uk_conceptos_personas 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."conceptos_personas"
    ADD CONSTRAINT "uk_conceptos_personas" UNIQUE ("id_concepto", "id_persona");
 X   ALTER TABLE ONLY "public"."conceptos_personas" DROP CONSTRAINT "uk_conceptos_personas";
       public         postgres    false    191    191    191            
           2606    612939    uk_estados_liquidacion 
   CONSTRAINT     t   ALTER TABLE ONLY "public"."estados_liquidacion"
    ADD CONSTRAINT "uk_estados_liquidacion" UNIQUE ("descripcion");
 Z   ALTER TABLE ONLY "public"."estados_liquidacion" DROP CONSTRAINT "uk_estados_liquidacion";
       public         postgres    false    202    202            3
           2606    612941    uk_liquidaciones_conceptos 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones_conceptos"
    ADD CONSTRAINT "uk_liquidaciones_conceptos" UNIQUE ("id_concepto", "id_liquidacion");
 b   ALTER TABLE ONLY "public"."liquidaciones_conceptos" DROP CONSTRAINT "uk_liquidaciones_conceptos";
       public         postgres    false    220    220    220            ?
           2606    612943    uk_periodos 
   CONSTRAINT     Z   ALTER TABLE ONLY "public"."periodos"
    ADD CONSTRAINT "uk_periodos" UNIQUE ("periodo");
 D   ALTER TABLE ONLY "public"."periodos" DROP CONSTRAINT "uk_periodos";
       public         postgres    false    231    231            M
           2606    612945    uk_personas_conceptos 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."personas_conceptos"
    ADD CONSTRAINT "uk_personas_conceptos" UNIQUE ("id_persona", "id_concepto");
 X   ALTER TABLE ONLY "public"."personas_conceptos" DROP CONSTRAINT "uk_personas_conceptos";
       public         postgres    false    238    238    238            I
           2606    612947    uk_personas_dni 
   CONSTRAINT     y   ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "uk_personas_dni" UNIQUE ("id_tipo_documento", "nro_documento");
 H   ALTER TABLE ONLY "public"."personas" DROP CONSTRAINT "uk_personas_dni";
       public         postgres    false    237    237    237            U
           2606    612949 
   uk_recibos 
   CONSTRAINT     m   ALTER TABLE ONLY "public"."recibos"
    ADD CONSTRAINT "uk_recibos" UNIQUE ("id_liquidacion", "id_persona");
 B   ALTER TABLE ONLY "public"."recibos" DROP CONSTRAINT "uk_recibos";
       public         postgres    false    245    245    245            Y
           2606    612951    uk_recibos_acumuladores 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos_acumuladores"
    ADD CONSTRAINT "uk_recibos_acumuladores" UNIQUE ("id_recibo", "id_acumulador");
 \   ALTER TABLE ONLY "public"."recibos_acumuladores" DROP CONSTRAINT "uk_recibos_acumuladores";
       public         postgres    false    246    246    246            %
           2606    612953    uk_recibos_acumuladoresh 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_acumuladores"
    ADD CONSTRAINT "uk_recibos_acumuladoresh" UNIQUE ("id_recibo", "id_acumulador");
 g   ALTER TABLE ONLY "public"."historico_recibos_acumuladores" DROP CONSTRAINT "uk_recibos_acumuladoresh";
       public         postgres    false    213    213    213            ]
           2606    612955    uk_recibos_conceptos 
   CONSTRAINT     }   ALTER TABLE ONLY "public"."recibos_conceptos"
    ADD CONSTRAINT "uk_recibos_conceptos" UNIQUE ("id_concepto", "id_recibo");
 V   ALTER TABLE ONLY "public"."recibos_conceptos" DROP CONSTRAINT "uk_recibos_conceptos";
       public         postgres    false    248    248    248            )
           2606    612957    uk_recibos_conceptosh 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_conceptos"
    ADD CONSTRAINT "uk_recibos_conceptosh" UNIQUE ("id_concepto", "id_recibo");
 a   ALTER TABLE ONLY "public"."historico_recibos_conceptos" DROP CONSTRAINT "uk_recibos_conceptosh";
       public         postgres    false    214    214    214            !
           2606    612959    uk_recibosh 
   CONSTRAINT     x   ALTER TABLE ONLY "public"."historico_recibos"
    ADD CONSTRAINT "uk_recibosh" UNIQUE ("id_liquidacion", "id_persona");
 M   ALTER TABLE ONLY "public"."historico_recibos" DROP CONSTRAINT "uk_recibosh";
       public         postgres    false    212    212    212            c
           2606    612961    uk_tabla 
   CONSTRAINT     R   ALTER TABLE ONLY "public"."tabla"
    ADD CONSTRAINT "uk_tabla" UNIQUE ("clave");
 >   ALTER TABLE ONLY "public"."tabla" DROP CONSTRAINT "uk_tabla";
       public         postgres    false    253    253            g
           2606    612963    uk_tabla_detalle 
   CONSTRAINT     t   ALTER TABLE ONLY "public"."tabla_detalle"
    ADD CONSTRAINT "uk_tabla_detalle" UNIQUE ("id_tabla", "anio", "mes");
 N   ALTER TABLE ONLY "public"."tabla_detalle" DROP CONSTRAINT "uk_tabla_detalle";
       public         postgres    false    254    254    254    254            k
           2606    612965    uk_tabla_ganancias 
   CONSTRAINT     e   ALTER TABLE ONLY "public"."tabla_ganancias"
    ADD CONSTRAINT "uk_tabla_ganancias" UNIQUE ("anio");
 R   ALTER TABLE ONLY "public"."tabla_ganancias" DROP CONSTRAINT "uk_tabla_ganancias";
       public         postgres    false    256    256            q
           2606    612967    uk_tabla_personas 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."tabla_personas"
    ADD CONSTRAINT "uk_tabla_personas" UNIQUE ("id_tabla", "id_persona", "anio", "mes");
 P   ALTER TABLE ONLY "public"."tabla_personas" DROP CONSTRAINT "uk_tabla_personas";
       public         postgres    false    261    261    261    261    261            {
           2606    612969    uk_tipo_liquidacion_conceptos 
   CONSTRAINT     �   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos"
    ADD CONSTRAINT "uk_tipo_liquidacion_conceptos" UNIQUE ("id_concepto", "id_tipo_liquidacion");
 h   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos" DROP CONSTRAINT "uk_tipo_liquidacion_conceptos";
       public         postgres    false    267    267    267            �
           2606    612971    pk_reservadas 
   CONSTRAINT     _   ALTER TABLE ONLY "sistema"."reservadas"
    ADD CONSTRAINT "pk_reservadas" PRIMARY KEY ("id");
 I   ALTER TABLE ONLY "sistema"."reservadas" DROP CONSTRAINT "pk_reservadas";
       sistema         postgres    false    295    295            �
           2606    612973    pk_tipos_datos 
   CONSTRAINT     a   ALTER TABLE ONLY "sistema"."tipos_datos"
    ADD CONSTRAINT "pk_tipos_datos" PRIMARY KEY ("id");
 K   ALTER TABLE ONLY "sistema"."tipos_datos" DROP CONSTRAINT "pk_tipos_datos";
       sistema         postgres    false    297    297            �
           2606    612975    pk_tipos_reservadas 
   CONSTRAINT     k   ALTER TABLE ONLY "sistema"."tipos_reservadas"
    ADD CONSTRAINT "pk_tipos_reservadas" PRIMARY KEY ("id");
 U   ALTER TABLE ONLY "sistema"."tipos_reservadas" DROP CONSTRAINT "pk_tipos_reservadas";
       sistema         postgres    false    299    299            �
           2620    612976    trg_ai_liquidaciones_conceptos    TRIGGER     �   CREATE TRIGGER "trg_ai_liquidaciones_conceptos" AFTER INSERT ON "public"."liquidaciones_conceptos" FOR EACH ROW EXECUTE PROCEDURE "public"."sp_trg_ai_liquidaciones_conceptos"();
 U   DROP TRIGGER "trg_ai_liquidaciones_conceptos" ON "public"."liquidaciones_conceptos";
       public       postgres    false    220    323            �
           2620    612977    trg_ai_recibos    TRIGGER     �   CREATE TRIGGER "trg_ai_recibos" AFTER INSERT ON "public"."recibos" FOR EACH ROW EXECUTE PROCEDURE "public"."sp_trg_ai_recibos"();
 5   DROP TRIGGER "trg_ai_recibos" ON "public"."recibos";
       public       postgres    false    245    324            �
           2620    612978    trg_au_liquidaciones    TRIGGER     �   CREATE TRIGGER "trg_au_liquidaciones" AFTER UPDATE ON "public"."liquidaciones" FOR EACH ROW EXECUTE PROCEDURE "public"."sp_trg_au_liquidaciones"();
 A   DROP TRIGGER "trg_au_liquidaciones" ON "public"."liquidaciones";
       public       postgres    false    325    219            �
           2606    612979 "   conceptos_id_tipo_concepto_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."conceptos"
    ADD CONSTRAINT "conceptos_id_tipo_concepto_foreign" FOREIGN KEY ("id_tipo_concepto") REFERENCES "public"."tipos_conceptos"("id");
 \   ALTER TABLE ONLY "public"."conceptos" DROP CONSTRAINT "conceptos_id_tipo_concepto_foreign";
       public       postgres    false    269    189    2685            �
           2606    612984 %   establecimientos_id_localidad_foreign    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."establecimientos"
    ADD CONSTRAINT "establecimientos_id_localidad_foreign" FOREIGN KEY ("id_localidad") REFERENCES "public"."localidades"("id");
 f   ALTER TABLE ONLY "public"."establecimientos" DROP CONSTRAINT "establecimientos_id_localidad_foreign";
       public       postgres    false    223    198    2613            �
           2606    612989    fk_acumuladores__tipo_concepto    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."acumuladores"
    ADD CONSTRAINT "fk_acumuladores__tipo_concepto" FOREIGN KEY ("id_tipo_concepto") REFERENCES "public"."tipos_conceptos"("id");
 [   ALTER TABLE ONLY "public"."acumuladores" DROP CONSTRAINT "fk_acumuladores__tipo_concepto";
       public       postgres    false    269    2685    182            �
           2606    612994     fk_conceptos_personas__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."conceptos_personas"
    ADD CONSTRAINT "fk_conceptos_personas__conceptos" FOREIGN KEY ("id_concepto") REFERENCES "public"."conceptos"("id");
 c   ALTER TABLE ONLY "public"."conceptos_personas" DROP CONSTRAINT "fk_conceptos_personas__conceptos";
       public       postgres    false    191    189    2559            �
           2606    612999    fk_conceptos_personas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."conceptos_personas"
    ADD CONSTRAINT "fk_conceptos_personas__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 b   ALTER TABLE ONLY "public"."conceptos_personas" DROP CONSTRAINT "fk_conceptos_personas__personas";
       public       postgres    false    2631    191    237            �
           2606    613004    fk_datos_actuales__estado_civil    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_actuales"
    ADD CONSTRAINT "fk_datos_actuales__estado_civil" FOREIGN KEY ("id_estado_civil") REFERENCES "public"."estados_civiles"("id");
 ^   ALTER TABLE ONLY "public"."datos_actuales" DROP CONSTRAINT "fk_datos_actuales__estado_civil";
       public       postgres    false    200    192    2575            �
           2606    613009    fk_datos_actuales__peresona    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_actuales"
    ADD CONSTRAINT "fk_datos_actuales__peresona" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 Z   ALTER TABLE ONLY "public"."datos_actuales" DROP CONSTRAINT "fk_datos_actuales__peresona";
       public       postgres    false    237    192    2631            �
           2606    613014    fk_datos_actuales_localidades    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_actuales"
    ADD CONSTRAINT "fk_datos_actuales_localidades" FOREIGN KEY ("id_localidad") REFERENCES "public"."localidades"("id");
 \   ALTER TABLE ONLY "public"."datos_actuales" DROP CONSTRAINT "fk_datos_actuales_localidades";
       public       postgres    false    2613    192    223            �
           2606    613019    fk_datos_laborales__categorias    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_laborales"
    ADD CONSTRAINT "fk_datos_laborales__categorias" FOREIGN KEY ("id_categoria") REFERENCES "public"."categorias"("id");
 ^   ALTER TABLE ONLY "public"."datos_laborales" DROP CONSTRAINT "fk_datos_laborales__categorias";
       public       postgres    false    194    2557    187            �
           2606    613024 #   fk_datos_laborales__establecimiento    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_laborales"
    ADD CONSTRAINT "fk_datos_laborales__establecimiento" FOREIGN KEY ("id_establecimiento") REFERENCES "public"."establecimientos"("id");
 c   ALTER TABLE ONLY "public"."datos_laborales" DROP CONSTRAINT "fk_datos_laborales__establecimiento";
       public       postgres    false    198    194    2573            �
           2606    613029    fk_datos_laborales__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_laborales"
    ADD CONSTRAINT "fk_datos_laborales__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 \   ALTER TABLE ONLY "public"."datos_laborales" DROP CONSTRAINT "fk_datos_laborales__personas";
       public       postgres    false    2631    237    194            �
           2606    613034 #   fk_datos_laborales__tipos_contratos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_laborales"
    ADD CONSTRAINT "fk_datos_laborales__tipos_contratos" FOREIGN KEY ("id_tipo_contrato") REFERENCES "public"."tipos_contratos"("id");
 c   ALTER TABLE ONLY "public"."datos_laborales" DROP CONSTRAINT "fk_datos_laborales__tipos_contratos";
       public       postgres    false    271    194    2687            �
           2606    613039    fk_datos_salud__obra_social    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_salud"
    ADD CONSTRAINT "fk_datos_salud__obra_social" FOREIGN KEY ("id_obra_social") REFERENCES "public"."obras_sociales"("id");
 W   ALTER TABLE ONLY "public"."datos_salud" DROP CONSTRAINT "fk_datos_salud__obra_social";
       public       postgres    false    2617    196    227            �
           2606    613044    fk_datos_salud__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."datos_salud"
    ADD CONSTRAINT "fk_datos_salud__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 T   ALTER TABLE ONLY "public"."datos_salud" DROP CONSTRAINT "fk_datos_salud__personas";
       public       postgres    false    237    196    2631            �
           2606    613049 #   fk_establecimientos__tipo_empleador    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."establecimientos"
    ADD CONSTRAINT "fk_establecimientos__tipo_empleador" FOREIGN KEY ("id_tipo_empleador") REFERENCES "public"."tipos_empleadores"("id");
 d   ALTER TABLE ONLY "public"."establecimientos" DROP CONSTRAINT "fk_establecimientos__tipo_empleador";
       public       postgres    false    198    275    2691            �
           2606    613054    fk_fichajes__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."fichajes"
    ADD CONSTRAINT "fk_fichajes__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 N   ALTER TABLE ONLY "public"."fichajes" DROP CONSTRAINT "fk_fichajes__personas";
       public       postgres    false    2631    237    206            �
           2606    613059 ,   fk_historico_sueldo_basico_detalle__cabecera    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_sueldo_basico_detalle"
    ADD CONSTRAINT "fk_historico_sueldo_basico_detalle__cabecera" FOREIGN KEY ("id_cabecera") REFERENCES "public"."historico_sueldo_basico"("id");
 |   ALTER TABLE ONLY "public"."historico_sueldo_basico_detalle" DROP CONSTRAINT "fk_historico_sueldo_basico_detalle__cabecera";
       public       postgres    false    2603    215    216            �
           2606    613064    fk_liquidacion__estado    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones"
    ADD CONSTRAINT "fk_liquidacion__estado" FOREIGN KEY ("id_estado") REFERENCES "public"."estados_liquidacion"("id");
 T   ALTER TABLE ONLY "public"."liquidaciones" DROP CONSTRAINT "fk_liquidacion__estado";
       public       postgres    false    2577    219    202            �
           2606    613069    fk_liquidaciones__bancos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones"
    ADD CONSTRAINT "fk_liquidaciones__bancos" FOREIGN KEY ("id_banco") REFERENCES "public"."bancos"("id");
 V   ALTER TABLE ONLY "public"."liquidaciones" DROP CONSTRAINT "fk_liquidaciones__bancos";
       public       postgres    false    185    219    2555            �
           2606    613074    fk_liquidaciones__tipos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones"
    ADD CONSTRAINT "fk_liquidaciones__tipos" FOREIGN KEY ("id_tipo_liquidacion") REFERENCES "public"."tipos_liquidaciones"("id");
 U   ALTER TABLE ONLY "public"."liquidaciones" DROP CONSTRAINT "fk_liquidaciones__tipos";
       public       postgres    false    219    2693    277            �
           2606    613079 %   fk_liquidaciones_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones_conceptos"
    ADD CONSTRAINT "fk_liquidaciones_conceptos__conceptos" FOREIGN KEY ("id_concepto") REFERENCES "public"."conceptos"("id");
 m   ALTER TABLE ONLY "public"."liquidaciones_conceptos" DROP CONSTRAINT "fk_liquidaciones_conceptos__conceptos";
       public       postgres    false    189    220    2559            �
           2606    613084 )   fk_liquidaciones_conceptos__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."liquidaciones_conceptos"
    ADD CONSTRAINT "fk_liquidaciones_conceptos__liquidaciones" FOREIGN KEY ("id_liquidacion") REFERENCES "public"."liquidaciones"("id");
 q   ALTER TABLE ONLY "public"."liquidaciones_conceptos" DROP CONSTRAINT "fk_liquidaciones_conceptos__liquidaciones";
       public       postgres    false    2607    219    220            �
           2606    613089 ,   fk_liquidaciones_conceptos_h__liquidacionesh    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_liquidaciones_conceptos"
    ADD CONSTRAINT "fk_liquidaciones_conceptos_h__liquidacionesh" FOREIGN KEY ("id_liquidacion") REFERENCES "public"."historico_liquidaciones"("id");
 ~   ALTER TABLE ONLY "public"."historico_liquidaciones_conceptos" DROP CONSTRAINT "fk_liquidaciones_conceptos_h__liquidacionesh";
       public       postgres    false    2587    211    210            �
           2606    613094 )   fk_liquidaciones_historico__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_liquidaciones"
    ADD CONSTRAINT "fk_liquidaciones_historico__liquidaciones" FOREIGN KEY ("id") REFERENCES "public"."liquidaciones"("id");
 q   ALTER TABLE ONLY "public"."historico_liquidaciones" DROP CONSTRAINT "fk_liquidaciones_historico__liquidaciones";
       public       postgres    false    219    2607    210            �
           2606    613099    fk_localidad_provincia    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."localidades"
    ADD CONSTRAINT "fk_localidad_provincia" FOREIGN KEY ("id_provincia") REFERENCES "public"."provincias"("id");
 R   ALTER TABLE ONLY "public"."localidades" DROP CONSTRAINT "fk_localidad_provincia";
       public       postgres    false    243    2641    223            �
           2606    613104    fk_periodo_detalle__periodo    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."periodos_detalle"
    ADD CONSTRAINT "fk_periodo_detalle__periodo" FOREIGN KEY ("id_periodo") REFERENCES "public"."periodos"("id");
 \   ALTER TABLE ONLY "public"."periodos_detalle" DROP CONSTRAINT "fk_periodo_detalle__periodo";
       public       postgres    false    232    231    2621            �
           2606    613109    fk_periodo_detalle__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."periodos_detalle"
    ADD CONSTRAINT "fk_periodo_detalle__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 ]   ALTER TABLE ONLY "public"."periodos_detalle" DROP CONSTRAINT "fk_periodo_detalle__personas";
       public       postgres    false    2631    237    232            �
           2606    613114    fk_persona__nacionalidades    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "fk_persona__nacionalidades" FOREIGN KEY ("id_nacionalidad") REFERENCES "public"."nacionalidades"("id");
 S   ALTER TABLE ONLY "public"."personas" DROP CONSTRAINT "fk_persona__nacionalidades";
       public       postgres    false    237    2615    225            �
           2606    613119    fk_personas__generos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."personas"
    ADD CONSTRAINT "fk_personas__generos" FOREIGN KEY ("id_genero") REFERENCES "public"."generos"("id");
 M   ALTER TABLE ONLY "public"."personas" DROP CONSTRAINT "fk_personas__generos";
       public       postgres    false    237    208    2585            �
           2606    613124     fk_personas_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."personas_conceptos"
    ADD CONSTRAINT "fk_personas_conceptos__conceptos" FOREIGN KEY ("id_concepto") REFERENCES "public"."conceptos"("id");
 c   ALTER TABLE ONLY "public"."personas_conceptos" DROP CONSTRAINT "fk_personas_conceptos__conceptos";
       public       postgres    false    189    2559    238            �
           2606    613129    fk_personas_conceptos__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."personas_conceptos"
    ADD CONSTRAINT "fk_personas_conceptos__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 b   ALTER TABLE ONLY "public"."personas_conceptos" DROP CONSTRAINT "fk_personas_conceptos__personas";
       public       postgres    false    2631    238    237            �
           2606    613134    fk_personas_jornadas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."personas_jornadas"
    ADD CONSTRAINT "fk_personas_jornadas__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 `   ALTER TABLE ONLY "public"."personas_jornadas" DROP CONSTRAINT "fk_personas_jornadas__personas";
       public       postgres    false    237    241    2631            �
           2606    613139    fk_personas_tareas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."persona_tareas"
    ADD CONSTRAINT "fk_personas_tareas__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 [   ALTER TABLE ONLY "public"."persona_tareas" DROP CONSTRAINT "fk_personas_tareas__personas";
       public       postgres    false    237    2631    235            �
           2606    613144    fk_provincias_pais    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."provincias"
    ADD CONSTRAINT "fk_provincias_pais" FOREIGN KEY ("id_pais") REFERENCES "public"."paises"("id");
 M   ALTER TABLE ONLY "public"."provincias" DROP CONSTRAINT "fk_provincias_pais";
       public       postgres    false    229    243    2619            �
           2606    613149    fk_recibos__liquidaciones    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos"
    ADD CONSTRAINT "fk_recibos__liquidaciones" FOREIGN KEY ("id_liquidacion") REFERENCES "public"."liquidaciones"("id");
 Q   ALTER TABLE ONLY "public"."recibos" DROP CONSTRAINT "fk_recibos__liquidaciones";
       public       postgres    false    219    245    2607            �
           2606    613154    fk_recibos__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos"
    ADD CONSTRAINT "fk_recibos__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 L   ALTER TABLE ONLY "public"."recibos" DROP CONSTRAINT "fk_recibos__personas";
       public       postgres    false    2631    237    245            �
           2606    613159 #   fk_recibos_acumuladores__acumulador    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos_acumuladores"
    ADD CONSTRAINT "fk_recibos_acumuladores__acumulador" FOREIGN KEY ("id_acumulador") REFERENCES "public"."acumuladores"("id");
 h   ALTER TABLE ONLY "public"."recibos_acumuladores" DROP CONSTRAINT "fk_recibos_acumuladores__acumulador";
       public       postgres    false    182    246    2553            �
           2606    613164    fk_recibos_acumuladores__recibo    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos_acumuladores"
    ADD CONSTRAINT "fk_recibos_acumuladores__recibo" FOREIGN KEY ("id_recibo") REFERENCES "public"."recibos"("id") ON DELETE CASCADE;
 d   ALTER TABLE ONLY "public"."recibos_acumuladores" DROP CONSTRAINT "fk_recibos_acumuladores__recibo";
       public       postgres    false    2643    245    246            �
           2606    613169 !   fk_recibos_acumuladoresh__reciboh    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_acumuladores"
    ADD CONSTRAINT "fk_recibos_acumuladoresh__reciboh" FOREIGN KEY ("id_recibo") REFERENCES "public"."historico_recibos"("id");
 p   ALTER TABLE ONLY "public"."historico_recibos_acumuladores" DROP CONSTRAINT "fk_recibos_acumuladoresh__reciboh";
       public       postgres    false    212    2591    213            �
           2606    613174    fk_recibos_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos_conceptos"
    ADD CONSTRAINT "fk_recibos_conceptos__conceptos" FOREIGN KEY ("id_concepto") REFERENCES "public"."conceptos"("id");
 a   ALTER TABLE ONLY "public"."recibos_conceptos" DROP CONSTRAINT "fk_recibos_conceptos__conceptos";
       public       postgres    false    248    189    2559            �
           2606    613179    fk_recibos_conceptos__recibo    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."recibos_conceptos"
    ADD CONSTRAINT "fk_recibos_conceptos__recibo" FOREIGN KEY ("id_recibo") REFERENCES "public"."recibos"("id") ON DELETE CASCADE;
 ^   ALTER TABLE ONLY "public"."recibos_conceptos" DROP CONSTRAINT "fk_recibos_conceptos__recibo";
       public       postgres    false    248    245    2643            �
           2606    613184    fk_recibos_conceptos__reciboh    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos_conceptos"
    ADD CONSTRAINT "fk_recibos_conceptos__reciboh" FOREIGN KEY ("id_recibo") REFERENCES "public"."historico_recibos"("id");
 i   ALTER TABLE ONLY "public"."historico_recibos_conceptos" DROP CONSTRAINT "fk_recibos_conceptos__reciboh";
       public       postgres    false    2591    212    214            �
           2606    613189 $   fk_recibos_historico__liquidacionesh    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."historico_recibos"
    ADD CONSTRAINT "fk_recibos_historico__liquidacionesh" FOREIGN KEY ("id_liquidacion") REFERENCES "public"."historico_liquidaciones"("id");
 f   ALTER TABLE ONLY "public"."historico_recibos" DROP CONSTRAINT "fk_recibos_historico__liquidacionesh";
       public       postgres    false    2587    210    212            �
           2606    613194    fk_tabla_detalle__tabla    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tabla_detalle"
    ADD CONSTRAINT "fk_tabla_detalle__tabla" FOREIGN KEY ("id_tabla") REFERENCES "public"."tabla"("id");
 U   ALTER TABLE ONLY "public"."tabla_detalle" DROP CONSTRAINT "fk_tabla_detalle__tabla";
       public       postgres    false    2657    253    254            �
           2606    613199 $   fk_tabla_ganancias_detalle__cabecera    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tabla_ganancias_detalle"
    ADD CONSTRAINT "fk_tabla_ganancias_detalle__cabecera" FOREIGN KEY ("id_cabecera") REFERENCES "public"."tabla_ganancias"("id");
 l   ALTER TABLE ONLY "public"."tabla_ganancias_detalle" DROP CONSTRAINT "fk_tabla_ganancias_detalle__cabecera";
       public       postgres    false    2665    256    257            �
           2606    613204    fk_tabla_personas__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tabla_personas"
    ADD CONSTRAINT "fk_tabla_personas__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 Z   ALTER TABLE ONLY "public"."tabla_personas" DROP CONSTRAINT "fk_tabla_personas__personas";
       public       postgres    false    261    2631    237            �
           2606    613209    fk_tabla_personas__tabla    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tabla_personas"
    ADD CONSTRAINT "fk_tabla_personas__tabla" FOREIGN KEY ("id_tabla") REFERENCES "public"."tabla"("id");
 W   ALTER TABLE ONLY "public"."tabla_personas" DROP CONSTRAINT "fk_tabla_personas__tabla";
       public       postgres    false    253    261    2657            �
           2606    613214 (   fk_tipo_liquidacion_conceptos__conceptos    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos"
    ADD CONSTRAINT "fk_tipo_liquidacion_conceptos__conceptos" FOREIGN KEY ("id_concepto") REFERENCES "public"."conceptos"("id");
 s   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos" DROP CONSTRAINT "fk_tipo_liquidacion_conceptos__conceptos";
       public       postgres    false    2559    267    189            �
           2606    613219 #   fk_tipo_liquidacion_conceptos__tipo    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos"
    ADD CONSTRAINT "fk_tipo_liquidacion_conceptos__tipo" FOREIGN KEY ("id_tipo_liquidacion") REFERENCES "public"."tipos_liquidaciones"("id");
 n   ALTER TABLE ONLY "public"."tipo_liquidacion_conceptos" DROP CONSTRAINT "fk_tipo_liquidacion_conceptos__tipo";
       public       postgres    false    267    277    2693            �
           2606    613224    fk_vacaciones__personas    FK CONSTRAINT     �   ALTER TABLE ONLY "public"."vacaciones"
    ADD CONSTRAINT "fk_vacaciones__personas" FOREIGN KEY ("id_persona") REFERENCES "public"."personas"("id");
 R   ALTER TABLE ONLY "public"."vacaciones" DROP CONSTRAINT "fk_vacaciones__personas";
       public       postgres    false    2631    293    237            �
           2606    613229    fk_reservadas__tipos_datos    FK CONSTRAINT     �   ALTER TABLE ONLY "sistema"."reservadas"
    ADD CONSTRAINT "fk_reservadas__tipos_datos" FOREIGN KEY ("id_tipo_dato") REFERENCES "sistema"."tipos_datos"("id");
 V   ALTER TABLE ONLY "sistema"."reservadas" DROP CONSTRAINT "fk_reservadas__tipos_datos";
       sistema       postgres    false    295    2699    297            �
           2606    613234    fk_tipos_reservadas__reservadas    FK CONSTRAINT     �   ALTER TABLE ONLY "sistema"."reservadas"
    ADD CONSTRAINT "fk_tipos_reservadas__reservadas" FOREIGN KEY ("id_tipo_reservada") REFERENCES "sistema"."tipos_reservadas"("id");
 [   ALTER TABLE ONLY "sistema"."reservadas" DROP CONSTRAINT "fk_tipos_reservadas__reservadas";
       sistema       postgres    false    2701    299    295            F     x�͑Ak�0����B�m��:(,0:h�]�#����2���ӎ2���|��y�^��,�[hV�PC�EU)��ON

��U���wBce(��-�QZ�F;p�쑆�cO�O�DG{8�v,���vjo�����7%L"G���a�ۋ�p�Iw����b(�GITB]���h��g~���;��D��.\�m6�I�<Rl9�����.��s�Ӎ������� �B��s ���Ő(��5�@� @�09� Y�ޭ\e@�gfC&���p�/���(PdQ      H   
  x�����1D��
�*�EX�e�\uE��e.ɵ!��b�@!�9�'ȝ��H��a��n�_�ߟ�u]<���������v�Ϗu�y�����������s<��nC�àB�~t�0�.Q�lE��EA;b��KNP��Q5V�l�E�I*�d�4`d2RX���A 6�d	��DT�P
!E#�Z'2Q63#�u��D+bR{b�P#�n:��-����'�ɮ"�����F�V�9g+bK $���VU��J#魹�����^hR�Z      I   T   x���v
Q���WP*(M��LV�SJJ�K�/VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QPwO��LT״��� {X�      K   �   x���=�0��_qdQA��.��ů��(6 F��_߄:�{����]ZTIYCZ�7@��M� �#��=� �� �.��Y�b��=:,(aj���'�Xu��tdȄ6ʚ�õ@w�Ȯ�{R���#�v�&��V7�Zz�Ǔ�^��	��T���'�s��1���`?�����TL(s<��������Py4�l2�      M   #  x��\�n�8��S���$�~�$�n1p3i�A�u[`�Zb�������˹��b{II�%�Y,P3�l�?���|q��3��� �u�L�p0�"��r �A�`q��:�EFoC�+A��袈��Cm�"O˄��T�"g��.r�K�_��%�2�y���R����gqI�,��e�Mu�<-3��"�6�����������F�=�F<�EɓH�k&�P�u��__�.��d�����+�A� 9�EL�@�!����}
���8������y���9�I�=B�~/�q�f!T�`���2/���L\��K^�5�h�z،���|�������;s|������yB�PsD��2g�a���Y7d3��[H��qe[��R��U�F����|g̗�rPK@��D�;\�҈�F튛��2f@�*Z6���dk�K����IF#e���*�<Fb.7T�?��`!�+v�B����<j���m�!��J�H���t��<��,c������L�Z�|��Le�;������3�� �>�>	H��~���Z�}��=D����P����F��c�ݘ�nDqqb�	%Lst�T�>tPҒӷ��J��A�}�j��ۆ^�x�:���ś�v���b4���1��)��-��K�Td�$�X��"�����<� �n�%t�����@��>\����[�h)*�����h���v�W�N-o���-�_�!�6���B�/q\�dƆ)'�v�Ќ�F�n���yQD���~Ђ}1?�P�A�ٳ_h-��#q�E�;����C�]@��hM�hMq�s�(S�Tc�%��B<[���Zb�-H��}SS��KP�Q���7�~`�PEgԮy���������ƣ2ԳL�c��l���?4�*�`|˒Q�Ѣ��F������1 l{@d)�p��F&�|�!wvS�x�)j�K�E��kƋ�E�a.X���-h���:�w�S+�׏�~�q���q�3��j�f�4��9��e��+�rC�,���Hу�r�Τ����읳�;m<8e�o ��_�0�(ȩ"���Hz�V�m���H�����i����@M�.�E{7���앸���4�F�3h��F���=OGԝ��XX���E>��s�+�6�B���7%���ca�w�s��_�?7k�׮٢@�@��E/�6���7l�\ЭU:d�NX�^�挽��l]��Qd7�J#W2I���l��}u"(�����)����e)C֤�yFѻ�P���)M�zM�>8F��I�GG:�_��0K���em��Gk����-Kٍ�GWԩ=�uԂ�=�u����]<l�ۨ%�RJ���m��4��[ >��:���]���O�:�u�L�N��{tJ��\���o��b�v��kQ�!hF<�]V@[=z����c3O�	��}���^M�-�Ir�4�mB���d!����v�^xc-˔z�t����gUT� R$�N9�Y�`�ˢ�g�UlU�#�P� E�%�7���cZ�`�rvL�S����y�t��I�v|�ؾ�	�D�)��sV)09
�c���O��EsfC.i�6���C��� �,ղj�Ѹ�N~�@/��F���d>Qg�AU�S � o�ʱ���6���GFuMk^�	�Φ������^�7�b�j2zy���Ez�+��m�|U�
���ɗ�3��l'��r�����p�����xאB��f�6��v��[ ��N^�#ӈ�>��H�ɸm�!�2_�Y�Ҡ�wRR(��WjQ͐6���D�;�I~�{r(�ʇ<��!SN��� �.�Է�$h��o"�k	�ΰ}�e�cd��ĽC�-z-�MC� ����j��>	���a��#��'��P3�{/�0C�X���54-�i:j���������y����@����2LUn�=�#�Q#[<��צ�j��cs�	�v��.](My �/�nB]�r�5U��tiE�%�����T�tY�K`%]�3��Cl7<���������P���6nN��#K�s�е�!Rp����s\�t���՘�Sއ����?1��� �^=硂�ቕ��t������z�R���H��#�4�Ta�)���6}j:�z'r&��{A�q�)iR#X��Δ�s��@���+�� W]�}��3�XN��t'��0�',+/���H��tEM士��v�*S�?�I���F�ϝ�M���)Ż��V���+��E.ٗ^wE�U<J�� ZEykF7h�e��e��;�����b��w�{��5CG���D�
1tv��w�{#}����ݾz����Ԕ��~LJ	�Z���$3wp�+�2��@���n_���>�9=����)$���p-lɾ��"a��jO�TK�n����_ux���7���|o�������B�}���B�Ё}�;~C��l�1g���}n��sS�	��B���������WO��澬�Es�_M�7�sJn�k%���� (�;��7� U���.�ˇ��b8�oE��Q�z����ή�4tw��LX*�!v& ѿ��Ե�taM�c�D�S�E��oDl�ܣ�]O��	�~�*uV��-}�.uHo~���?�o��s *&�4([��%t�Hg��#�,4jy��(Y�|�CL�;�l�w�Kn
��z][�Z3=�dT��2������s��)� �>�:�.��*�ы�q	�l|F�w�ODn8fZyWU�h��y�;�s܇*�SS�`�ߒB���N��56�iV�JuI��w3꩚[�;�4��Ĉ�?��tM��!,3�wd��,�{��{�7ʦdw������      O   
   x���          P   
   x���          R   
   x���          T   
   x���          V   �   x�5�;�0D��b��_DEA�D@�עe��"cG��}(�9B.F�j�f�l������� ���VH���I��.�RA_�QCP�K
R�xס�?��YOh�`�R%�M�(��HQ
�ga�j ���9A_��.=	��_y�1B�aW=��5B�A�y�}�&�t>n�����4[�l1�Z1�z2��*I���G�      X   z   x���v
Q���WP*(M��LV�SJ-.IL�/�O�,��I-VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QP��)I-��OT״�򤆩F@S���Z�h�1�P�̲���L��\\ �uO�      Z   �   x���v
Q���WP*(M��LV�SJ-.IL�/���,,�LIL���SR�P�LQ�QPJI-N.�, j*�9���+h�(����x����*�x�z�8:{���kZsyR�#�-P�]�j�1�dgנ ��\\ ��T       \   
   x���          ^   
   x���          `   e   x���v
Q���WP*(M��LV�SJO�K-�/VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QP�M,N.����W״���4#�in���yPø� ��.      b   �  x�uQ�n�0��+]� �+JN�'51��8����X{��RR��Ǟ�	����lˁ
 w�53|\=����q���E��(�$�aU�EA��_� ���"va�YT�JX4����$��!�
�/�9�AU��,j4c;X�����(uM�-zcl��ϭ1Ta�j�l��j�DB����{'�]�1��Ra���Q (��֟���p/�M��!a�(�?�Z�!�XzC�x�4X1��7?�o��%y{b��6	�[(*:
w�\b��5_�̟��|����6��K>�]�������G�x:8�~��h~~��}I�<��un:���~�^�yܧx���R��Vd��|:ʺ��O�X)�y�,�&�$+�ŧ�I��-_�G6�	�=Y�BV�n���}�
f��IҪ��`w|�1q�z��1s�:a_�椡1�_�F� �O�      c   �  x��Z�n�8��)�'Ꮤ�ؓ����	���Eb\.dѫ��}�=���#��vHJ���޽Jhc��(�|��C�����Ϳ��`S<�2���,W��2�2
B��-C��b��l �@F��綷�Z{D�<�J�O�O3^�U$W�'���8п�r�vq_����vI��PJG0����,kX"��2|�#��R���?��.�����uGU��T����No� �u�Q�1-r�@�l����a2��λ���:��޷�i � �:�~�L������?*�{���Z�$7��v�Iwy�.F�XS�A$��0y �E�v�93ꆜ�OCΌ��f�ps��?�����z��& �"�}98�Oţ�q�_���
CwJ{����!Zf�)m�`���0����!�׷�>"����CL
�k&�8}�?��7�`^/��@`<�^4� 1����,}%p�P�0��(�[T�.8�E̇4���,6U�E�0^�b��bU�Qٸ��\A���|���R���U~�KO �O�!k��Y�[>�ZDEh_��R�	V~��L: W�U92�s�r+6���S#�bk��kZaxS�d�#o���@��/o�j����6({����ҎӲ����6�m<�\���6W��Ƶn��E��1�c��j�u�+4�H�S���,��G�щqr ��H�%~�H�_~fyY�@����d�ݽ??,�����2�eڔV��2A�eP�<.���ֆ�t��x��UĐ��*���2�e�&���}]D�_�a�^x��J�c,d�):K�f����wt�*�Q����V�=2����1=�������:�a���8�ƜU���*u���������`�z�Wvy ��9��1qW7%>���]a�:��,�E*2�^����H�{"36*a�ʊU���2�J� ����\n/1�}�
��{���A��8C���䬃�6b��!>�k=2�/;����"Z.���bb�K�*�ʜW/ �9=sߴ��_���Fl������(G�a::g�o�Pe��"Uz�U��-o���V;3��(�w�vsvw�؞�{$W��Bs�^�a�� �/V�cb��g�����_���Z������K15"�*�Q]�,!Չ�������5yK�]G������5�9u����Z?Ɖc��إ���"(E��R��-����R��KQ���R�eh.�=y�ʓ� r��%ھxaϟ�{��(�^5kT>��H]�+r��Z�F(�W��Xu�:����m�&�L��	�0������j"�E���}������p�/jl���*�%�T~[�k��Kz�H���U����\7���������#t�@���[&�4
w�^��t�Px	w�����
��H� � ��דٺ���>TC82s"de�u ���B��Q@po��Q|�bU��.���!E8l��%��CG�C���-����T�����	�Z���j{���ȱE��S�e��X�l%�]f�4ܖ�}oҦ�L�.U��Im� 57y�u/����Y�}�nq��$��rS��	�7z=6<	/ȉS�|��^�S��jT��_���O�*{�*ԛ�~Չ�ꒁ�3��jK���"�]�U�9p�Q��t'����ݿ�SV      d   3	  x���n�H��y
�� ��?�'O�d3�����a/F��8H���<H�f�{�GȋmU�h��=�`ۀ:�gQ�f����ߞ]��/ޞ��[q��^-CuP|
ݦiC�\��
WMwP�p��A��q-,.׾���ڦٸ%�]mkߺM��o7��c{~�����~x��4wkW��o���2���g����eXĽu��j=.-����,�us�h�����&�a��������n��en�7M�?�ꓻ�������N�X��j�����k���&�V6��q���%\䮟�*��n}7��o��n�Y����w]n�����]vM\�:�ժY��fz��rpWS�F+��]4�P�e�/S��;j��v!��mnB]������ҏn�dӏůG'�/���䰠���Q�d���3IHI`���T��
RR~X�}89�s(�1{窪ig�t�`��f�#�������>�	��h\~�a8C���egp�����V�9�s"aM��g/�:���B���N�zs/����G�Nq��Rv۫�Ï��l�x�`�"dץ#T�)�+�n{����W릨�պ�}����u��/^A��u�ᗣ3�
B������M���J��˦mq|�3q��ص���?�"��'����Q�~�ˋ��&�&�K4A�����R�1M�-�[�!F��M��E�Y�Ϯ^��5�ށ�˭��i��G_�$z$�7'�$jN������}��E�dЄRD��Ab#>P�H��R�{ ���Ҁ�,�נ�[E"�0F�g(� ���Ȳ�EX����0��q��oPM�����������'0����S��V�A��D���/���&���5�*���(B��\�(,:xzZ(�t$Ѣ7av�WG�Ňw�����r��[����t��f��y�y�g^  0`�Bp;JSYj�d�G�qq*p�Et������|�08��P�Rn�����c�(1��-���k7�6#���1
�S������7� ;�Ŕd)�!�/Y�ZR3aH��m��o�n��9����Hk&�#�m�| ="E�2�8P���#"B�ǹ��M�a/��O����/�%_Bȉ"A��I�I��^q����9�2�b H8ץ@�Iu�'����:��EXބ��?��J*N������6Q�4@ɛ�����e��$r�I4�*O�d�d��"�>L�p�-�(���@���ދj��LGGY��"4�+W�n��&�q�3h��1�!F���Pߏ����4�]7�i�z��
Ef�)�)��L�����I^�Q�%D�R[�єĀg��}�>����qu�Fh��U�c�H�n8F�$I����Q����L�>��C����n�~����N�L�L�3S,�#5˵�%)�r+-��RH1�w^��61�q�pG�T�Q!,:==iC��F3Ҍ3';O�<.T�S8��IfHf�^&Q}�Ԙ����ͨ��&=cN��h,l!�wk��]q�V��_�i�{��!�@�$kN��N�>�����4�͈�N��u�׸��/E��$�C!Bba�D�" �p�2F2F2F�c� BXj\̋�Q҄�:�RUp^k�!F^a�*5�v�M���ǘ0��O�����V�'%	���4��h���=��M,g��x�r\�a�a�g� HxjZ(.J:��Z]��6RH�J+'4��k��J��
Ņ��U"f���N0�@�D*��`8�&��;Oԣ�)v�W���Q�d�d�d��#��k��>��LF��ྱ��Rme\R��P�m�g)�qmqT���y| � �*鑧���$����8뺳�@)�s��dL���&�$�d�,A��Ԙ��S�T�OJ�Kc�`�tL�Y�ڷ�kì�-^z�D��W�Xi�Q�x��0��U�4Io����à���K�H�H��1�Q�:Xz�n�&�#"Y�Ռ�B�ǈ����;o-��8wۨHo�pa8�q��ɲy��E_��IoG�qnQR>� �E�##F!:5�	#�td� �\��a��"�JFi�
�mR����1W�.3,S��sp��)��$�I�A̒a^�%��v6)!� y�7$d�Az�Ԥ攗��B��  D|�wH�7n��]�����7�����!�װQUU��g$Z�(��	�q���m��O�L�K7&&LL��9[r:���4�#!�3�n�+�5��f���2e���n�l�!��%T��K|s�Ф~�7�@�u
5���i29�#�#�c�� h0������_V%�]!�Q�����x>�?"��Ȩn�'|�Z�y������R�d�a����F~����x�oj�      e   /  x��]k"I���+
o2nQ��Uf&0�%���m����������SΚ��]H�	hLb��>�ׇ���������72�w�ͺ�����pl�uռ�u�^6��E�m��bմ�aF>�ٜ֫�/>1ܰ�7����/>]�5�e;ܼ�U��W�f�u\��U��8�����w���&�6|N��t�*l�q6'�����?n���vq\��n���౑Ms _˺��it����~��t�t�|��כ���C�I�Eh�(c#��:$��Ĩ�~DS�l�cs���՛UC>�����Us��u^�O<��ͦ��v59�d�Շc�ؑ��l<�~�]ݳy]TuK�{ԤZl�n�PR5m[��n�=2='��*!(W#b�z�U���P럪�_��������$g���{K����kc�r�����d����9�7�̲�_�C���A�U�0EOO��(ؿ6�E�����)��m"�
�o�_Ϝ�����s� �a8�d��M�_����M�4��ȿ��C� �r!��'��A�Ρ`��?GU��]" ����x<%��K`��"� l,�Ԫ1�o�`o��T��.ٿ� �ѿ��)��X�s�<`��WP�F�P�9t! K�5��,`���x���S2I�D 6(�,����T�1�o�\8�[ũ>;XoK�o�/y��p�xJ���( _� �7FfX8�*O͘�7G��BK��Ε�_â�{ɣP��7��)�װ(�^� �7��/gL	z��d(�����K*!�����6��)���أ�s�x� +�=��� C��A�F�pv=+�gxH���\���;p�C��d��!�G �B	X9��hv�#6��y/]�܁3<>�G����Lӿ�)#��M a���#/G�п9r��2RQ/]w���π��Q���hJ&�_�q1������Y:(�
8�07L�<�,�gD��}~�_�3p4%�p��@'�I��J�;pב`��j����;pF����S|�Ȱ O�$�+����S�  k�%unD��#��5q~�Vp���������)��`��e��� �A�_��w9ȿ��`p�cW��J,�����7��I�W%�X��#`)��ڍ���s�  k+������Q� \|�(�єLS�� ��,2������u�B	�;멄c˒Kp:����C	n<%��N$`,�呅̽��m���CV�^sw�6%��t"c	N��xJ�)�D�\��|�	=�1����{s�7D�S�      f      x���nG����SDZT*��+Z�x4�=�h��u%��m�H�6�4��m�r.~�����:)�`W%�X��2��I��<D���߽y����^��������|�~���_﮶��۫�z��n�v��\o�_��O��'۳''U��y5}y�~wu��������=����]���vW7�|�������F/\���W�����η�_�o߮7W�����|���7�eu��z����;W�������z�K��zs���.�W?�~�Wo�#c��'�P'�t.0��^ؓ��׫�U�}���WoN_V_m~�\�[���7p�o��j�:_��l�ZW�Iut����fs~�{!��G�7��I������q���~y���|�����N�{���M|����~3�|��o��v���5qp�E|���i�_÷�i�^�g7{�(��/�D�#D�3
���
)(�p8
&>��GY�4s~�D�)�q��2	pI�V�,.rqŋ�x�xQ���?-�|@ZV{Xb�'Ze�
�����	e����׷o �_o~ܞ�]��o�	����i��/�"&�9<⟠-��8��jU��řu�pD͜�Jg�
N3��M�fN	p\�9�k��-ph�,'-i��������{�"��\Ld��^�2�n7_�.�3�bU�U�?�\6K�8���v��/�_���+ q}u��/��y�0�v}��5gN<��U��_��.��?�yU?���9U/*�yug������tw���'�A�D�N2.b�4�v��	=Ņ��7��'�j�0�\��L�dŏ<���W�x���߾�-Uw.U<D��4��vsv����U�/�7W�}�J�W�}����9�{�7���v��3eಽ��su�;zR��\����)~�7��_���lw��������%���UM�=BK%w�d��ڼ_�Co�ru�`��fu~ԙB��'�'��� N*��bs�Yxs5yw�VRU�ɷ��c��1�`�(u׬�z���[XI�������ޤ��@���T�����U\87�۳<OC�Ͻ}���x/L?��N��|��#׻���K�U�vߋ�?PU��4`b�&���\8=�T=��m�q}.o�.<������ڬ�w��V/$iQ�����=
�A8pVAPaV�Kn�%���l�����fsy���맛�7��M܀����9��N�OLM�aVsN�<��Lc��l�����fì���$��'p�y����y�
/W��N4FP��~��?yIO~�'�O�ғ?��LiH۰���RN�����i��M��؋�ʷ�|(��P:��?�}a��l�h|'����or��1
؏����,!�߹ꌓ46L��Q���WL\T
//////!]4�e�.�:"��"�3,ex#�:?���D�~�����f�RV�#��P�S�8�����py�_��ѯ��wuF��:���0LDJz"H��F*��� 
��!r����}aZ�L�����߸��ηg���^��zs��-��̐���+�؃��������#:��9}��"�[��qK�w������)|Jx��KgW�aN$@�Y�&��V_~��>���E�ծ>m�����z�ƌ�ዊ�a���sN���W{��f��\�V__T�t��:R�y{S�rM���ݿ���q�6���<Y9�4փ�*O~`}���������/Ӷ�f{Y}���*|-���%k���:���c��}���}v��I�_p&*�����^�}�������y�lm�������V���n�Vg�\�\i؊�3�F�%���撥
�%+��璍!Q.�����k�|WގWT��=�g��O��w�G���y�F3B:/���P�#��)���)�wt��8����x��@W`<EscY:���>(����i4vL��)KPqr�)�Ǿ􀐦��Ρ,S�D���9�9���RL�PXz{z��~��u�}7���w�C2=��$r�р�T�3����Cr�q���^W�:�������f��*�R�#�c�z�|�؁\�hސ\�X\�@��B�g���JF��@]Rh�L��d�Ҁi�=7pU[�XMn_�Bo�S�lu�ƍPM��A�;��?#�V�Iϔ�F�:�%H2�|F�����	t=�d��gm�%�(k㱎��mP��tR�n�s�(iW���H��J�T+T҄��� �����M�Q�����5.�4{�7�� 9ȹ��DT���ׄJt����Z&ڐJ��5���*nsc��{��Ek��uC��Ժ��5��#hޑr�4�}�4������(��]�Wt�^V��]�z�s�T���^��9
&�������pדv���Ge��*8��%~��ē5��կ�������fd�����[��p�Z��H�,K	<�.K����v(A�ԡ�2jp*��S�Bd4�
`�d�]0�TP
##�)�	�B�����zLc��j�=6/3��f�*!�And�Oz�K��Ѓ�=����F����NT��Q�%����p�o\�������&�'G�&$���鋓ub�J�S ���P��g���2��$��8�Z����B��Z�Mx�,)Y�0D��S�
)P��)�	a)�c�N��?%�3.��"�9�m�d���#��9��G�~ Z)
����\k}�3�z���|�8#��DTA����I�������mlu�J��8b[��G,��́%��[�Yз`���E��z#�f涩C��� ˉ�R8�Y)1v.ʈ�G��v��#��I�:�<H���	׽'���᥮���{�(5d5�Ԣ��:�6�8@at��O���B��q�eCJ�1��8ح@�G+�m�A9�2�cY�j�~Ӝ�Rp�iN���w�h�@xT?k������B��Y�}T��\,7������\]�[�S���b{����? (p'�F3�r»���ҝ=�6�i�:+�Y��PdS�e(�ˠQҭC3U��a����U�=x�Z%yh� N�܅2P�ϣ������}�jLJ�#s�y��~C8TcR#��ݣ��t�(LǱ^:�R�Ԙ��BN��Gw���8]Z�df96��uu�YK����b�̶���<����T"�c����8�W��V3�jff"��1�t�|j5� 8���������-�)�Vߜ��m
������7��<"to�<7��^ԓF��5?��'Ks�[�'�v-ל��a��Ut2��Aa��5`A���\6��r,��-S2�hb���}U
�Bz2ǙL� !������а'-�"����h(ι����&KAO�Cq�b/���F_�T	�0���wb���e�(���J3'naCU��"�X��T�LјU��`��P��bmC��t��b�J�#\�J�\�d��z-=��ڐ�pq�P�m!x�D��:�Z�"�(���m�~8�>�����KC�;�+Y���'URXi9$ ����V*�°��FԑXAa�G_��3	�)�B��3��PLi!26ǔ��d�bJ�0R���g��ʩ�=���.=֑���lsQ�vϪ6{z��hr�?N ������v����ڭ�[h\������������86��L�A�z���#�(�wעVF�PG�%��L�I��(iG��2�'K2���VF�;͔jhR+��QZ!R�sn"C픉i�H;��v�
�Z � �RhYle�U��B�Z �S�BhZa���zξ��ÿ��ʊ©�l��t��7)W�@��q�������D���\sn�zܧ�������y{A�b������8!{/B ��A���ԣCn�G<:�v�]������l�7W�����U��SGG�~$޾0����D��P���N�;��B�ɟ]�C�[�\�tO�%Su!�s��+(U�<��Xk3#:��$Z�@���5�2�U�愤Z�g�B.�Aۺъ���&{f.�ͺ�#=}J�\���kR��R�ԭTL��o��Y#��@��	��%��d������Q�\�4`n0�ﺞ    0�~ģ�ﺞ�~ģc�����]�;�Zc�Ze�K��������/�f�4�6��b1�_;.<��%��(i��x�N�T�:W�l��9Z��Z�6�&hK2q ���_��,�&�A��3��xm�Lj�27	# ���̹�^����'�r��i�2 ��G� .�����C`	�@,�Ŗ��g'�(���e���7�MZ����^1@j7D_��TR��"R\.$SC�qm���0"��r�	T\��{��D�#0)./�E���G���e!���
v�lh��o	|���HƳi�gژJ%�[)E`�4�hcZ�K�b�ژ
�������Т��>�p�(gI����g\�ҥC�,eт�����GO��0�2����������
hgd��'�����98��������jN�V��m�}%�B��(��H��4�6�h7�%R��M�&mSb�q�z}yy�񔻾u���9�{�7��ն^SχNnf}q;�������fs��6~Q��.>�{��/����dN������pê�f���۞�a��)����U<w�j�(ݾ�Ӕ<{�����H�kiH�_)5�nR�����t��SL���N�����:e��tsQ�����g��OO�"�O���_�6��T���G��W��GU�=��as�Zqo=T��9�uu�Z %~��/T���/��s�r��p�ˮ�u`W��L]v�������ha��B����E�@�EA�g�(�=u��
bP.*"�u�+0"����c��o����q�*n�E@�KB�Y�!e�{�`!%�(Q���i�P���RgE�s�B�����oA���s����S�
)P�)8��h���i1I��7�B�c�FcLo7����	(0$�$L�LRtb[�����J�t��Nl4J�Q��"�pa"~`��y8���u^zf�$	2��e8�=����P��%�I!H�)]k������+�kʱ�����s 8���p���\j�	s�.$ʷ(�Z�HIi��m��Q9�j�#O�,ؑUG�G�p�ŏ��B�G��ŏ��fs{J%�B��	�#uB�G���3w�P:sQ�`}�C���MďF�H�h~(r,~4�B�Ge�R�(?*��������X�@ gb�#��!9��F0�o�=$�CC�2~ �20$��GGH��FI�<��>�^1�i�D�eB�+�]��+ov�	^Y�D��m-��#C�+�PQ�'���3�*�u�\�1�A���T`�p0Ո���I�p 9���''�6���~�����MoO�P���}�IV��)��R��t����9ix��)�U맴��ծ>q�+�G/*�
\0�\�S�]l�'mIz}[}}QE����H���Mխ��ݿ�p����ʞ���C }OJp�J�Ą d�4�S�� սUUX0R8f���&Q���1�11�xM1�x[��D�7����OH�(F*-J#�$�f#��o��I�m��oP1`�H�`��P,
( k��B�4J��/�'�td�X��z!S˗�A�t'�six��2����G�u��.�u�z!�HyD�wC�D&��	� �	AC o!�Y!x����!ǋ m�s�y2WO�L�&�\��H�<��A�f�� �hk�$h6���#���0�$͆@���͆� X^�L�.+�rE�a��M��,�ɠh2�
!u�� ����A�d���+L6X��ڦ!q��Ä��$hQ��L2!��s�O�1�(q�	b�Zr/���Li�8�bp(�둅���~=��I���Z�Mt��~g
D�����j���Fe��Oǀ+a�suJ�N}	��� 	��X����"��*�X���\���E-�c��˭�w�ra����"VP���QP��r�3e�t�0/�(n�b�Ya���� ���5�>�0�q㿛؞���^ �1�]��W��^#��U@������9��˅�u��"�"T-�ܤP�v���ϼ(�NN�)8g�fU�NN�򹓓Bv�y��<�N%-��L`u5��T$-��@SS�`S�q�SS�"q����v,��5�(��7�H���Fx6�h���Q*���GE5����5�ܨ���PҖt�G�ӏ|t����xt����b�:�Z�eIeK�_?�wsr���-8�G�:M��2�8H�����P�l��k{fJ���jB���5��"~�<}q�!�+�.'ņ�����`N���$�� 8z���W��8z*�?R���v����=_�� `�m�7�F��؟�D�촰�%X ͳb���0cZ�'��\�J����Iìh��d$��v�8<�	c�d�z)�:�=H�Or΋�5D�t�{`S��C��V�6�#�`�=��p��A$N+�@�R�L��Yꃆ �)��R�&��g�S	�KD�dzZ���`�	^(�9	ۨv^Ä��-,����lT�٨��Q���R��cť�N��VM=�|�zr)h&LÞ�r��j^'�P��Bd|n�M�D�j^b���p_����^�e�A94�=�\�*H�Z�y�< A�6�E=�|�������&ǳ��Ϯ��xF�c��s�X��.T�W��Ey����ohQQ^|�8QԾ<��j=���!yRM#�ґ��<n�B@�7�7���Nj��N�vv�͜�[����/>��Bpe�a�gV7���.��s�\�����M��rE�D(Wd���)(��6�2��d�j��#r���]G��W{(���o��!�
n.6�&� 	,}w�ͻ��ԭ��͆�
�l� �����{GB�)!�>��ݗ���B��F��"�4`3`��*�C�*�xtUF��U��8x*�V1�6g�D��8Ic��DT�QU�|�TT���b�b������EcB�&����u��0!p��ةD���|�e��W���m;�x�޽��:���0L�I���q�\��~gϿy�?��0|؆ ^�.��"u9�c��
b�uxܠώ8�Cn��d�]��AǂH��;��o����GtZ}s���!D$�t���ĉ�!"�sx�pHya8��B.�� �z�s�j� 262���Q�I��EK����(˫Tn�D�������D�F�H�m	,��/�����;��=����E>v�W�wWk%U5pַoû�4%�����#��_�_G�(���G�_G�����xt�|:(f}3B(��9�5u�58���n�Q
�.���=.|]�uڗ��𝒬�Bd���4o#$�S
#�S�������9~���)5c�F��<գ��gܭ��CxB�sE�B�]�Ƞ�r,���E'�Qd�Hn���F��%������#{�q෽��{
.��Jy'�N*��ߋ&O�&?��z���A���;:��d�gF5#��ɟ]���`}���)�\��d�Vc0K^"b	�P"��Q�}#�T%W!�q��8i��^**=P\6C��<�Er����.n/WW�V{p?���؞o���ˣ��ь�i.�Y�uJw���E����r*WrK��(�L- |��v:Z�V6쩘� 8>�'ŭ��4�����u�߾c�W�u��.����"�=�y�[	��Gj�5=CL���š@j�оq!��VbP,?E)1Er��b�7J�Y��)1�w�i2����׃z��m�Rb��d��K'��Ѐi�,���<�ѡA�*���ͨ=1t�?&�;.ނ&)�(<�(�Q���H����,�\`�Ag.!�c�m�o��כ�竦�9�!�V�cr:��G����0+!zph�ht)��>H��ut���Ie�M�j���4Ɉ�2%�6�ap�HƈE2�"Ǒ��*'�d��J"T��0��A$��{��b��T��X�+�SޑpR3-���;*N�i�M�!��e�$I�H�;Ɍ��_�D])�D�0"!�RzD��lsQ�)��:�6��W��>m-@����������7��[o/�q��"j���}=�xJ��%�4.O�n    6g�3|�>�vW��=�KE&i��z�wU�$�[� ��FG7x�5|��61fdD���W�P�K���K�@޷RY7�ă�t�$(�^-á} /�E����E��3(vT�\,�A���b��M'��6)�T,����O!��3�ܗE�Q�c4�\��F���F0k8�,��I;7 �(�ȁ9�u`��'���%��:pflˀ\�KR1�H&�s-�/���f{Y}���*|��"���w���?�Y����?��_������o�w~��Z��W�<~����Q��w���Es���]�?��~m�k�bJ��G&dlN��Y�4_į��/N�q��+�6"��Z��y7q-ê�Ds�$������|�:Ì-ފ�W�����Wk(u<�X��B������x�B�B���@E/�4�H�����^�irZQ���T]�i�,���((�T
.]Wu�X�/�EU�%�1��S�r�Uu.k�cp0��\$q�C?��BP�B!�"�@���VԜ��59a�	 ]}�l�9�q���V����*I�\�\�����������w�o�T�S e���d�`N51�����&�����o�VW��UB��I}��\���U�a:	U�mu	#�;Hsʷ'��<<u��:a4y�*J��j�m`�54�S��8���z�<�3�|ਫ਼�V�>8��?�\��뼭!	rTAK[؍z
�zh��B�Ґ��9F����$%3J1Z�� A=6#��A�Ԙ-�SfD����h������Mn�$tp{`���c�tp���m,o4Ӻ1Cx��H�@�8�9���G��c.$�Y�З��"�����gW�s̍$?��"���c,$��ٲ�}��ԞG~ɥ!�~粩u�:�рi��w.�\��G��������Gt=�4(����$����8Ic��R�1��D�b<Y)�h��X�8�x��t�/T�s���+2}u���8f����j�ܰ���������s��$6 �0<7\^�׫s4�\�Q{��G�H�V��0	��&T`A6TH�m~)팏YP�bf����ó	{�s�Ǫ������5��gF*� $��dXU ���$<&��(����:���5��U�Iծ>m���F/*��
�/9W夓�]l�'m:S}[}}QE����H���MխYOݿ)��S�[l�d�d!4쩤wy8F@u��Sr�\!�xt��
1�͵Ҩ�
��t�(��6. W��l,�B�T�y=FCސE����A�E�BLސ�Qx�Y�7df�!RK�]�������)��J'X�,�F	�<"��F����V�<"E�1�>-#4ԧe!2����Y{�i)��K��ѾF����>-���Oˌ�?$c<�$��  u��{c�����QҎ1о�BB��v�p���������/�44Ii�FF�$�9gֶF?�EfGa�$�
����H`W�2-��/w�Y���o�U�U�?�\6�YP�D�v��h���5y��CD��V�g�H�Q�6L�&��o:`.S�d:Ȝ�"0I�H��L&A"�Q̂:o�N�J3�l=��'��bf T�����F�,��o߱��:~p��^H.����:/�1���f�q�%19�G4fa'f���0�f�����j9�����iJ�hI����$h6����r�9ޜ/h6�}��G,�dR�r�#񢌠����S��4|�&�n.�7��l�>_ぜ��?H�Q�r���dr+\	n�&Wʅz	Ä��q�O�Z\I&lC++T�{����
ߡ�kw��TS���9Z����@٤V�D��Q��%?�vɪW�����w�j��M~��$�������]$�rw��ͻ,i݄֫�������z�f���G���6TP�������Q]�~�]��`�&#�W�@�Tz���[��������P�t:T�q!u�2X�������M��G�H�	,j��?�B���-{;��'��::})Z*��k��ɗR38I����$1?;>I���I� V�y�oT?�F�4cFA�y�۽���54`n06�<u |����Hn�� s#�XB�0�B�ϕ����~c���oyHCib�$�L;`d߭70��{ģc�i?�i��G����i�����T!t[���.bV!5��{m��Qj,�
5"ͬj�P�l�B���g~�(�(�Ӝ��2 ��CV<K5�]���I��FIw�H�2?e��U0�Ɍd}>��5Hє�����׮5�Ț����T~WE+�ciyt``J��z���|���)����Y�W�0pRI:��X� y�@�Q	у�It�0p�q��2E.����EeQ�=m�I.$�dj�gv2^��(�ei,�i��K��mk)_�C�du��2�Xdb���$������(4��e!�����5�����6���)ĮB�̷z�b��lo���.u�_8����֪�9�#CM��"�;��K����:�cW�g.4,�+ǜ3"u����4��T&R{�B �@SwjoQ
�#~�B�F����l�?��3ӊ)�}�8���޲L���L�u��g��1E��(d�}8`A�g� '�8�5LȆ�j�9V���q�9�u���pj��-1�?&�\���\����Ve��a
	QB�c��mי� �/��վz��k�����:��N[�^T��_2t���M�[�qb%UI�A2�G^ޅ� }�h�g4�����s�a\1�R�1,��Jmel';\�?���8�$�M�d��3���%S�4_į��/N�"x�ݣ彡���*(!0��4b��W�_6��Vg���[ce�:_��l�Z�rt��'��������x'	���=GȒу)م�5|�5\</S��a�؞F��B
T�t@
p�����&��$��S�?��-,R�g�u[���lY��J0;-��Nک�aQ�S	p�Y6@��C)���Qu��p(evv.u[�,g��P�Ӣ�$V�xӷ�*�)Xn9��5���QGE5�p�-�?Z�+�NI�u����g�rQ��"������̈u.�V��� u.�[���7���u��B���`��:<���M$XF�H�e�����Ä>�W��@_�P�"���@x��.L�v�3eoS����IS�ɲDRp��A��L� 0�Dq���$(ͤZ�L�
5���� Ga�I�&kM��,�e�h�2��%�̎�`��s�ATb�,��b����2�oaD9&� s�c"�W��0��(�d.sL>rL
�r��Ԃ�Т�"��`�<EμG����]�^�!�-D�u ��x��~
}�7�9=�?�����
�<����6��ݦ�����u_:��ӷ�^#��{d+h�f���߰cWo�|�{����R��N��&�ع��/����f�t^"��C��� � }���
��B���Kd;�7I!�DoJ ��Լ��J�)����pR�x��l�F��˳Ѩ�keܶ0��GC��`1IBWz�jm!�B���(�;dA�3sp(�+��̫�I�.�ģ��p� �B��M����"QC��duɥ@q�).�y�(��n"���iw$J=)�X�7��Ǔ�l�;J=Y�K�7�J=)W�7QЍNن���g,o��Hޤ<Yޤ��Z��II���&T�mR,����7�6��i�Lp!m�2X��M&@��I����&�H�d	,
���'&��� |bۣ|�!�A>���I��4`�c��C���xt�A>�htP>�c.U�{h��3m;�Zew�9C����V(���(�D�X�7��'
�S����J8&]�%D���`ؑ
6.�0/p�����gB4*�Da^
"Q��ZwQ���č�Y�LhJ�¼T�������Q����}As�8��0;�(��B��,Q�������MM'Q�����9�(��y~
xx6Z;�qw������E�ɑ���g����Y��W$Ag��)���i�A
tv�;��ϭ���YQ:-IT�T*��[/+T�&KĨ6iQ.PҟZ/�ͅj� �  
�%�,�5�ٖ�&�G�k� �M*���&u�PmRY�t�6���j���f��IcnT�4?;�Ms�ڤ2X�~m��&���k��ܨ6i	,�ߨb��
�>W��O�[�4��Qa�ҐD�0ijݤ�$0퀑�¤�¤G<:T�0i<:�0��=nT�F5�������Yh��"����X���ˤ��,�t��Ђ�6�H:���?dA:�3s���`�6Hf1$!5F�Hc�<*u���{͜n�R�`
ʗ��ώ��UU���u��_V�������P��U�_�}��Is�q}[}}QE����H���M��mݭ�Ss�O�y���)߰�5���%Cb�;d$5����p���Œ4��� 5,��6U==W��x��O�'�8��"9��O?�g�������h�]l7�׹I��À�����rv���`�����"q�������j4���F�ʫ���	5-��K�����~6>m��勶��?4���UL�A\���lr1�.���sa�jރ�L�������u	�&(c(஁C��vzTe,_&�ٛ�e���.���Q�r���;����G?��>���G��K�߳�������8Z+~<���֖?;�?��2޹h���QgU;X; wM����.�\G��7�?:9J���|�z��8Y�!��N!�C�%ԧ%Ex�h���*sߜ�������|�:�$X�z׫�u����5���.V��r��8~ts�T�UHʕ8GX��`Jv!~��mw�*�\)��0D��.��i����`IOE�3��$J�g\��E
�J<�qD�Qx�c.�>-8���H�xk}��"j���%�%rRPn2,(a�0p�'	\KJ� o�3ȁPB����9����C��g��y��20�o�B�ӗd���'}"i���#�'*�h���v�O�,���Ņ"���R�>Q#�ㄤOT=�O$NH��<N�qa{B:E�
��#P��Q"70�{=�G�H�c	,u:�ӎ7M��:>[�r�Cxb�#���!�Aብ��:h�4�א̛�/��ܿb�|)���!Bn�3��/���9�r'
����`�Zd��1��,��b��Ig��1#�������Jc�d$F��e��{���^
�r��p��hhQ�>�O�^4�^J�#�!:h�7DY��7D��(���!���f�`R�.�����G���F��>�ѡ�������HB����!�b]��A!V�����X@a��	����T?ӄ ��"�h���˲�n�@:�Ć�#��bC��Ilh��o��F�t:X�Si
L2r�#�Fn���0Q���^0�N�q a��� ۪<�9W���<�͞�|���SF�U*OY �܀
��AF�E��hH4z���9̊kϠT2�R)�y�#��w40�ͤ!1��md�m6=�>}����M�֜;f|��ļ��bQ�[<��Db�4J�Q��b�i�����Ci�á��;� c4ᡉ՗�ˬ����*��՟o.�
^�->ޏR�1B�P*��\�hZ�P ��(t������9l�+��C2�Ի �W����U�Ke��P�)� g�[x��z�ڃ~�O����6K�P;�B�Lp���2X����(��+��Cq9����	t$.���W��|���@��X�Z�(iF�A��r�d%�z�8-������6H���=,�^-�-�C��CˈZJ`�L]ꀦsؓ���pH�s8���r��\�m:������"���@V�CE鳕.�e�64�J`C�Y�"5������"I͢� �Y�QV,���fѥ���
L������R	p�~���-p訴��_��p�4;�ܯ@(-�P�p���2�ז3/o�D�!�;h%��\��UG��;|�u,(W�X �	L��u,(����X�;ySԱ`Y<�c��603�CMʢ5hZ�G	�Դ�Hn���	n�2?�q'�1�?)�U?i~%��m�D6�FJdK`ɵ�c�B�ϖ=����������-,��z���boҺy H���B�Mh?���R��hϽ^��~���z��>2nz\��o���UN�E�s�c����Zm=��1h�5�j���풪�UL�'a�v�I&GǴ"%��J�E���������%��ƨ�����Э���|���ǳ���bl}��\���L��Ω��CJD� ��f�C��&�7
��eT�;���!e�R�p��C���7
�̏�9��8��;M����T���J2��ǹ ��8��N�,�Ku�Jq��I2*���1����b �Z�@�'%88�
ǙT��5ߙ���5�IO���̷6A�X(�v���ڎ*Ҩz8�%�����B�e�x,��B��%�B踶1/n�B��K2�m>B��șз@�B�r�	,�6:��T��Q!�\O
y� (?<=��7�h^������U4�W7`Gg=���ܶ�Α��v dCM��Y�F���"�xp�8�6��f�́5�+�D*ōbs�$�R-�E���R���o�9� �����������v��炞b�=�:�\�K�=�o߱��:~p�Z��"���߽�w^"���x��B�pIJ��V�21�t@B"�ene$�r̸�&��?(����)�`I�>G6��9�J��8����r�,N��M-��8�5[��8�h�q�h:-��c�gc�i��,��C��k��C9���L9�F['�J�,N��Y8Gh�ѷ��@�iFc�̽���"q�dF4p��������"g~�+�]�עی����$=��(Iz6�$���)Iz����{�H��{Ɍ4X�RO�)z��E�&�I���Xh�͗�C�f{Y}���*|};"`7<4� �3����t��֏�n�����˷�;?�h�Q�y�lm�������c˂F�%a�2�z�(S��1S�0k��z`Š��"u����t���VH���HAa�_��Uut~H�:��BKc�W;�|C��B��\/�����E~��cs��;�Pa��\���v���X��K�"�Q�a?��X ���pT;13��k'x��ڕ�2��c����!C�C%�Q���̪���2�|�W���6T
3H�������.k�p��͹C?�2���1u�ŘI��,�ďҁ;f��m��Y�����}�!�8�$�-MEbzK����l���[h���D�[$��<T��[�����Qz��h�-C���2��	NbP���y�q>F�3%�%t��y)i�?.����iS+�J�.�OJ���T`�=y�V~�dի��M�X�d'�p���;��ó��sA1-o�
%�H)�,��{�f�	��-������^��rS�^�#n�kv~(z�kvąz͖��$����DsSpX!�7�>�IP�@�(+�A��A��8f�1{��P��"�A����[�!W�uȫ�o{r�v8?���e�7�����q��*��&߆w���A�<(��Z;�k�@��Ѓ�	���q�S"_q�S
//////!]4zB4jd�LM��ݫ�c\5"��3���:����ό��o\�?fC���o����o��B�E&��oh��F�0��Q��CE��o�s���(���q&�!��en"C��Ĵ"���)dϱ�܇�zyH�<ǥ��]E���o`��L	prW��H[� 8�gm�;ᐶ��\D.�4F2in�B��2��8(���y$�,��J��LɑUG��p�Xp�.TpP.;���(��<n��AC��e����*ʏ.�[p�������<�=�B}IQ뚠�A]l�MZ	�� �ټ���A��lU�Є(�	N�t�/�^�q����K���#׻���K�U?G��L��*����_����i1�      g   �   x���Ak�0�⑋-XIb��;Y���SHt�^�����4��_=�R�$���Ï�R������ ]n��V(DGm�U+����ԙ����`�t�@߽�=k3�W���Pt�UW}Qڜ�>�m�%�H 	�b�
�bA�3 $]F)MB�d��:�߁�\T����+&!�8�"�҈�	&1�e�W��Z𩝎=r�n�a�0�����M��x���uֈ,/�6d÷���#��#��v���~o<j      h   �  x���MK#A໿b�IA���dO{� ,.��^%���F������Ū�� bD��I����?<��z���~N��ϗ�a�	��������;=�?�������<^��?���~3]o���I??���ϧ��j�������~��nn�?���{��cl�S��IZ�Z�W��������~W�!	�����҂$"�e"�Q�1��H�R��+ b��p�C��e�ۡw"��:
�FH�M��P���fH�b� � 7�H4.u�T׮��F�.S�25X��.�\nDɁ1�@G��n�X�ƚ=V��1;���>6�R`Н�blܩ�P1[��b�H�C͎13xі�N�y�ʡ�c�һ�R�%d�/S47�yv����)*�4���@�y�
U��2���)���@�2Eu�@�����:�S�a�DY։Jz�И�6jˁ<��`�wc9��\�H���W�E�����@��,��Q�;��Y��1!�0	IH�H�0��!b�˜�#�.�}N� C�����3G��r�9�@�і?ۥ�6"�rM�4�aV�B.���х\ �]� ą\ "��@dr��B. Q]� �� Cw!w}D%r��B. �.��B. �\� �� D�!`�6�ͅ\ ����>b>�	� D4M��l�!���L�@�}�@��������/��'_ D'�����ޅ@�m5!b[MD��&"�2Ql����̃04S�A�-�Ё`��k!lCn\� .�Ʌ\ ��/��B. Q]� �� Dw!w}�HT&�х\ �]� ą\ "��@dr�XG \c���u��6�v�u"��@�� ���>��`��1$�Plw���;�@4�A �� ���;�@D[�@ ��6��	"ٺ�m]�(���@T[W@ ��+ �� ��>_�
C�u�m]�[W� ���O;�c      k   �  x��Mn�0��9�ņDJ*lP���,R)R�HM�-2�M�"65��mz�^�6?��l���d���[,V���+Z�^��I�(��9	|SR��ACbg���gLAj�F�\���y��lGC��V�h�S#!sHe؉��\;��3������ҭ���cR�AN��I����iR:dgJe����
(�P2Tzz$C��&m�jK�L6U�گ���l�6ߠ!�����vh)H����w�:񂉇O+��
7O��z�!kY|���c���4F�� �M��x�,/"����`q#~�E���oi�{�m��#�Im����k����A`>	���4��A�&tlA��l踇�V��K������;��l*�s�}5��������8�!���N.'�S'g�2 IM      l   �  x�Ř�J\AF�>�eV
�����GVY��@�lEG�11��Sm�W��
2���k�����������S�yy���6���������nx~|���w�/?���x��l����]��O�o~�=~�~�;lN�//nή�c�ʼ����������ɇ���L�l�	%�˶��"�3���+K��n`	b #K��:�*<�6gZ0j�i) B$c?��س;i-ٍ���3�жaab���W����B���`l:Zl��S�m0���Ʀ��'[��؂֔�6��ґ����=������=p6��#M���FS���l4��dgs��gs��6T��Vc��km� �}X���A�2�m���e(�w5��~���ɻr.��!�ջr��]9�q���$��!���"�!�E�ըl{yW��]��pyW�ʻr��+�0ʻr��+�0˻r��+�0yW��w�LޕCpyW�ʻb55��FyWa�w�b�w妰Ȼbs�w�zyW��]9�w���+�0Ȼrq�!L���f�_a����"��!���t��V����'�P�<9�au���:O�`Z�'G0�yr��'�0�"��!�r��1���\Γ;�*��!r��(��!Lr��,��!,r�B{8������LΓCp9O��yr��'VS�%��VQ�vD�(/�A,r��ZE9�������VQ�FS�(g����������\h�Pه[gx��<9�E�C��,B/��!��<+F�ƑCH��!�8r2���#G�ƑCH�!�4�B�J=�kG!�#wi9�4�BG!�#��ƑCH�!i9�4�BG!�#��ƑCH��ԐƑ�BG!�#wi�)�i9�4�BG!�#��ƑCH��!�q�d9G� �#�0�q��8�E8:��nƋ      o   m   x���v
Q���WP*(M��LV�S��ON��LILI-VR�P�LQ�QP���M*J��@dfJ|AQ~Yf^rf���B��O�k�������O���������������5 ��      q   [   x���v
Q���WP*(M��LV�S�KL���K��LILI-VR�P�LQ�QPr��2@�J�
a�>���
�:
�E�y%�y���\\\ �-      s   �   x��ҽj�0��Oqhq�ȑ?2u�`()4iעH�9ptP�X}��X%���Iq����pܿ��=��A�۹G#���Lu�X�B�+�,v�nֱ0$/������?¢XA^�:�"3\�E��|���I�u$
YKY%�vu��L������+)̇�^)G�jd3f��������V���&��ΐ����0�z��)���u�����&���*���/��_���)6Lp��H�      u   b   x���v
Q���WP*(M��LV�S*H�,N-VR�P�LQ�QP���M*J��3��s2SS�4�}B]�4u���S�J2�Ց8���\\\ F�e      w   �   x�͐�N�0��}
+�nR756���表*�m\Q�-RhJ���8�Ա!�;ٟ����Y�����3�.��b.:�7�L�5"a�to;m}Q������q>������p��"�a��bߜ��C�-�0�� }q������4��\�g�������,��T�LͶ�������?b��r���L�
yub�Q<���c`���FG9z�3�KӒ��!�|�[���xBp�+X^dyz���$?@Hɨ      x   B  x��OO�@��|�MO�4M�Oi�'H&�^�R�X���j��Ί�X�s�����R����y���q�����^D��ͮ.�$:TǺ�6�z[uv��"q��(t]ӗm���n[�v��ƾZ��^�#������:�>;�����>li˺��uz���﻽m붫�%ͼx�L��Z<�-�f��j�c�|Z,�^�X��i��׷����͉VC[�M0�D*�`h�"�,\BRi8��tU0�.�҄��y�+�7�����Hxq=�� G�U��U�G��Ux���D�`i���U�U�S̀��,px	iP���y���NUM�)]�sU@+���E.]�[5���p�= �Uc� .�:�)n.;�Fy�!�k<fU���hx][��ys���y' .���r'����7���y�9d\�5���Ys��܁6 �3�L{��!�r� .���r�� �z�9`�)���r� �3L+����J��rB?�%Rc�r2�Ǖ7��1x9��Ή�������`��v��l��
#�Gmu�7|%���0���g�\�@0�Ǽ�3��0�)�q�ʓ\��w��L� ��ar      {   "  x���K�0���KN
E�h�O<D��U�� �����n�?��P)�0�I����[�����x����</����>��ҿ���lJ��a8v�3��l��oh�K���Ӣ�/�*������7%E��� ��C�(NP�l& ٱ��F���+ ��0�v��k �[(�4 tTt�e�U�����R���;E#TK������tp  -f��\��h@��-��A˭� �Vр��bn���P�	Ʌ� ��
�k�z��E#̖����v`���4�      }   �  x��Mo�6����/�X����]��i�!͆��a��Y��,z����#)Q�{'��H|(�ǿ�|H��y��|���W�87���⠪ڔ�^$oz��J��o*��Ƀ*
�5��w�?�u)s�תl|�ޮ}0�ɏ�PYV�
{�N��
׆�h�>�����X��|����[����.��\6jg*-��sS6�lƗm
5��˶��t��T=�)՗�Le�����˵�j�|a��[�׹.�����6�� �F��ߨB}7�Y�j�Y�T�u�}�qM���q~l{�:R��MUv=��Z��\���I?�z8q�ꮽJ���������כ��-dW��Υ*dro�^/m�G{Y.+S�� Z!fK�V �0�$�E�k����m�=��ݹ��+V .�:������_t��Gg!���� \%X@LR��[�
��ۛO�y�9�]WJ�ۭ�䏎k��
k�T�����ﲨ-؄B��c����\Sk�~߹�;��~遇�]�ߕ�
���?�/e�|ӹ�Uq�/��{�����1� �^� ��F�0@2�q��h��8@� i����߭m�P��8�ީ\>��q7P@(�fs����> 0�� �x�
��  ���$c8�D�;�}�`qXޛj/��B���<9���]V[�BN�}�z���b�r��3.���l����D�2���r"�� ����2y4�����[湩:��Z%�}S�&����k'n|�x��G0�|8��G�;����.Գ,��l�t�Yy�
Vl�s:E��۴w�s��C��x�a
��vd���埦کB���r���d��2@8'xjL����@��v�l#A
A4&��3l��=�֛4M�X��[��X��(��}�q[ͷ�B̘W�G`s�@
D;�}���!屑��B>�<��ܫ6�� �8��4grI�a�4gs�LB���	³��3�p���:�]�䶐��e?���B���H����$��o�Ȟ(������z���\�ӄwT�wX��ޒ��NՋj��U�dP�:��<!�@:M��	�V���!��݅�	�Z��|G��.����-�l���e9Ju�B}���|��������ջ?��\��G��t���a�E�[�M��j���A�u�~v�gހ��u�2ΐL'��[�,T��d�l���CFE���%��G�O w��[]��Y'��\�[��,����gA�Ԉ_&�u �qQ'�G�i&�"�(&�#�g0'�~�*�.�F���I��ߣ�w�8��2
1%d�Ia!�2U���>�K�A�?�H0�)�#%����x@<���+�{�Y>���u�[6l=A"��W+<����Z�3��6�ȫ@�P
q�*��ׄ�0������ {�[pD3�AF'�M�%s¬��wߠ�?6'����hN"ׯ��Λ��&��[+�N�sS7#��
�p�0�d�� �p:�� �'��#�4�gS)�:�e���"�q�ӌ��J$��W�~��N0w&y��"X�#�F��e�a���}i�s�E9����]|6��X�a\׌��!\��.��rc%Ճ���<0�R�d���C�1&�N�8l}�t�
��d�K�w�G	r"~<�xd��qg\ީƱ��˟��r���(T��`^��:DRf��:/}�̼����D`��ۯ޼�f�1G      ~   j   x���v
Q���WP*(M��LV�S*H-*��K,�O��KN-(�/VR�P�LQ�Q �pQ�,1'�(>-3+*	ի�������a��`��`�g`��`h�i��� �+#T      �   
   x���          �   ^  x���Mn�0�=�yH�"��+�	i�n�IbQ��N�R��$]���b��	f��7��<{m�8�E�<�lZ��]�J�O!3�5�9��L5w'��U(j6����%���A��r�j�	�����CoA��->�J, �9�X��םo�D�!�|��w��z۩6����s�ҹJiC�?�Zpi�7c�ҁ4�C�|���V��z�t�j�@�q/��~Ѳ��+�g,+��g9jG,��՞v�[�Z(I�s��_��m�Vv�����o5��n�0�1O:V��"qӋ����;�e�0�vOk{�v�hi�B�*�yAm8������Zc7"�|K<�3��-������~;{      �      x��}ˎ9�徾B�Mw!���|�fы
5�t�l���K��TN*Uh`0�>�F���=,2=�Q�
dT�������s��������o����o�~����ݙ�_>������wo�������7w?���/m#����_~����O?=�_�~��������<���o8pl��ӹ���y��㧟>,w����_�?|���_������<�[�����~����8�?��_��O������]v����#���F1��߼�`��J*b�b�����������'�p�?�߻�>��s~���ݻ��}����û������?��>�w�J.�R���)��������|��^8�����|���}7=����f���Ï?z��ǟ����/���~������/��}wg��������O�~��/�?���N�U����_�w7���d�x��'l��뇟�����v&KVC��飼�zѻ�,_��������D���?=�Z\6yx��G����	��v�Ǉ������?��~��_~�w�ɘ������jx{����rw5ʍ<s�6��cF%{��:���=��m/c�^��s���|4�cю5���ɝu�t8D��&���P
_'���fm���W���!���(ZG����8���8I�ھ�#|>��J��\}��tY�.ޒꈜ�LYoq7��Ip�l�Ǡ9�0}��{W0�I��z�"{y����G�k����y�c�����a}|����a����}$�?R�#�?����~�/u�{��f�;�BLl�)G��� i:6�zH�&k�1I��yv�7!�B���G�nJpk#��E�:�G���O��|��A����x�dԯq�,q��dʕp�]	_�ˇc�CX��+#[�#뮌r +lV��V<���X�yk`���B��_��͐l���Bpi�Ňq�5>8��T�����΀���w1⊢�%��Ur���w7�dH�Xb�%,BMqQ����@��֊R�-����$�"�ե�U�ut ~�	/�rf{�J�(8:�+�D��mbq��bJ���-D�b�K�	�3F�
�9����X�A�͇$����
D�|�j�V9�P(
hi`1��*�Я�Y�GAa��0=����ʀ��"P���o?��7Dxl�	��M�C(b 6�Nrۭq�{i{|�=����9�`��k���j�E�� Qі���l7	���\�"�� ��Q���|� ���h�E�5i�DpX�A�|f�8�Zm-Z<x�T �tzBEɊy�&�-�
סB-��8���Ee߱b �a���ǆ
mսT�"X�VG ��r������q��/�8��F�Zl7�7�4@^�s}m�v� X 3�%:k`2/0� ���X6�b�*��/%v�c�q���џņ�	�%�+c�ߵ*���
d��_C��5�pvi�� �nc�j�t���!�8���D�ܻ"B�,�ZqɄ�C��s�,L��%8���E���.�7�
Hg�K+��x<Bƙ���� ��'m�w؀�D![S�G� d����:n�7��4bJ����q�.�H����3W\�]���y\	@�*��Y:�H�&5	ϩ���
/PU���\�԰�o"��5D�_g� ���2�gw��@<a��w�9��WGa%��q��"��NŘ�r�S1f��۞�h�'���3����b�������Л��1�)o}.��x�s1f������~�jg3�n^�c����4f@n^�Lc����4f@n^�Lc����4f@n^�Lc����4f���N�0o��¿���MRxU�V�+1��0� �k�����IglWJ%�f<=�@��>��ҵ���y���`�W�8�}g��Q��۴��cLb��/���\F�kB���qe'�8�r{���]���&�(0MLI�;-s��~��'����;g0:��2�����\1�K(�缔��8w���yI5T6�Ɣ���S6"����JI�h��w6�!��>1y���.�B1�ܛ<=�*ŧ���̚H�<vWS]=����ɋ�m|9ZS
���B�"$l��b�	q	 ,�,,B����n�߅ �R��v����9��T����8Q.���7�<�d��݌��8�=�����	gh_�"[1�|����>_f�	Y	
��Aq5'1./���lsd��Yp6P���A���JG ��wieE�"�3#��� �D�"����X��9��+0%�HT(�݄S�xt���|��'�8
!	�Ɓ|�>�qoR$( 
Z�}�Ӈ�p�� ��F~"���bZNmE�����MB���^/J�j5�?��*,��X�D|Tɤ�*NW�?1U��G,��(��8������N|KT<R*;`�O[�,�h|I�JY*���)�=c�$H�x�t�N�Ɖ2��O��W�Ϟ��J��B���cI�>:h�)Q��ϰ#�l�	�|��\.ˢ-���&k���
�1���u?�f����[�,�6,�8W��cG�3#|'L�W�b�,�=k�i�Ff��[�,Ռ�Î���4c�7i��� ;d���;�7���z�fu�1�\�΄U�;��S��hqW�8MW��]N;�)�m ڶr�+#H�-�rK����J�R�����\};m��x�� i�fF�%�`o�ܨ��x5eB�Ӯ!��eQ�
���5R��8*4~�sճX|��>�2 P]cr�e�O���ȰZ��R�l���	�
��5w|�"�X*N�cD~`�{������<i�b��@rG��	��*9X*�D>��	������EpX��S���ٽ�ZB[`�yhAn rͶ��	��[���[U|l�\=��ꏺ*�Ka�j����)���69,�|�b��#^,}NC�����X2DN����O��:&�A�نƅ� ��� ͎��9yS5�-|�]t�#��#@����Qq��u��$|�<<�
ėe��T��<�P2�����Ӯ|���9		a[���mR��]r��pv=�	g1m%�.��`%��G���ڠ�i�F�`�t��3MjI���eM��@���_g�t��d��8�C0��#]Q%�a�(�1���9�
a5�6�+��''�c � ��� ��Z��ݑ�Gdg�\��������J���o��Ư�ѐ�@{���q��K��a2�݃��T�g�e�����Dr��a׺��v1���˵n ���ż���/c+�FK���D;�[u1ao��0�l�*Mp���=�Z\dY�����&"[��+��14�B2Ź�'JP�>��8qq�4VA �b'ih�HN @ 懹�M�H���9b`v��!j G @�;���Bq`S�մ�ߘ�e!��_є�`��`P��bR��w�R_���HwΪ� wO�" �GxnR��O3�(�=�
T��C���	-���FR'桄4m���5:�q��%N[C���K�V��Xr�W�J0@!Z*�4�R#�.��*��@h���%�H�{Ht����;p4=��Z����.��A�Qʏ��\!��s߂�OB�>m+�vMt=�O񃸴���0��ljP�,�z���X8Yo���\P��[y�0#��!�w�cb85�kG>T�qRF��vSM{SS|qt����$R2��"��wX��5���G5�;P�y9�Hu�'e������{�O�BΓ�i�C���Oϐ}g�ؑv���uI!gjF0Yxo������k�Е�V��V�""C*\�
��u�5"2ӕ�sםq$So^�C��I�����-�$��Ӷ�4nʺ��Ķ�z]b�[�qk�@_��p�wI�8��cT�K��6�K�6��s�/���g�!�����N�1>_
�Z삱4фWƨ]��}!�*���*=�Z��l�XuQr��S�"�.�k`��t�W�lȅe&W�bK�Ӕt�M5�"09a��H��҈*��4��}��� �0� ��g��^E�O�
yf�<&��x$�2=��d�x�/ ��U�Y
O�    UMӶ���)
�H0�E�Pi��̫�����7�����XF
p,�!�C>�(��U��G��ls�b�\v��-�9�*����<��F�i���C�K�ό�#e��K�栮�PuH�0�k��I�l%St �nlȹ_�;�f��(���B����g�tF�PXu��D,��L
�BV�)5o"X^�	�.�;�������AS��T�>����������%_/��FT��=��bw�Dٕ$��u虮$�M\Ձ&�9=bᎪ;��t�f�U�R�Q���na]Ú�y��i����Oi�@55�x*K�:t���m�����"�E\�f����GX#�cbz�	g���r_tPa;h����Y��w*�?�Kǔ��zl���a|@zZ�|,6ώ�
&��%!&[���6z�J:���_�ۉ�h_���E���Ҝ���`�� �"���JN�����Mo_Km��l�u���]�EZ��HJFsd-�kK��ޥzY��s����e:s�@�~�����CUJ�c�|e����
`~F��~"�~Zg��M�
z˻ˠ����B�Ln'kd��}k���^�т
Ů����vr+���.�P�����!�!���g�g�Ů�7�=�m�D�V��C��.��\sP�7���n�aѵ�:�"�EJQ|C�VG�Z�H� �F�f��>2��yQH[`Y�q2*nD�`W�S��ҵ�#K����)��%0�j�,�ր� �j�����ⵖs#�w�lo�[Ƽ^7�Xm���ŧ���̵r:��jhJo��#�x�5��ӕ�%+B����#B�x��[�4�����x�G�z������4m'�P����OH�=M*n E�)�M�c�:�.�s�!�U&d�:�u�gpnT;�T"�T]n_F�ن�ľsGf��S�N"�u��15�t�;C�<�lZ'l�WHk�,�pz;�#�`+16�c:��a��5��!��
K^�¤�`v�ݛ��@tH�7a�d�䥑Y�Ͻ��#�)����Q�����l�`7�D)I�U��_	�e|R���GB��Q$�"���!���O+D,|P�yk�BG>)&�LI��i'�L^A�����~������k}���;$)l�I}��pP���]v�J�KW���;EI�ȲU�@Ev�s�"[3���u���f����u�Pȳ��wM-_T�W �B�f��<��
fL���ܒg�� )���J�(Y^�[�!���q��w�ղ������8�{�:L�䔇�Q���7��Kb���X'�1��7b��Z����,��so49m��+`L�����Ɯ=�H�}zG66��k��̺;h!GF�J�)�(��O�vb�4z� ʈT����
�ߋ�3���*���v�N�j���%�f#�k�����AX��W;^(P�Y*d���X)0�6%��g����å���#O-����@gRN,\�=��S�SYh���ܮ���}iǗ3#�&�w#�7�a~=K}��G�iZч7݁�1O��R[�������ɸ� yD�#�.%'��ک�[��[��2FY��Hk�	�J���rz��<����G�y�n�ce1�k���g�j
I����#܈͹X�aC4��kW�UB'A��!��q��T���`�)ё��kE��O\,��h�Ć�H4��4��:��s�}<M���Ah(�ۺ��S�@n^|'�7�0S^S;����l�� �T�}K��d�,�r-=Jt��C9�����*N,�-_�����+,��2iH�h�O����(���8L�T�����nU&}�kE�J�b������$�B�U��1x�oD�=�:70Ǌa�����m��z�]fɐ�i27P2�Ul@="FG�.v� 9��nA��<�k�F���g� x�=��������ݦ��.��m2�s��m$�[Pd*Xw�P�U]�H:��e ����	HjZ�k��b�du`���
��P��LA1����l[�WWh��90;tk��^͓�z9L��!��w�m��l!�'d���|�42���K�*�q�9�ܗ��O��� ���C������ծGjN`"1���}~��5�Wu� �� Bf�u��CM�?��5TT�)�do�r�gw��)ѿ�:��$�)����m|�@��4K*�AP2�E�4k��F��Y8]ņ����!G���>Dlq���q�Zȹ�\�-��SE����΅qtZ�>��d�LӺo��~���bW�n��3��^��o���j�{���BO�!M�l��}X�A��C�4�Fa�H�96�(���m�\k`0Z��ɱ����@���:W��/�]l��ԑ��q���խ/+W��"��c�)k���ߢ(RT�*.�Xo�8g�R�7����Yl*yA�)w ���ڌ@29�l���j���W�#���v����iPt�n>'�o�ZMe�O�ZM��x�jI�&�_?�浪Ӻ/�1q(��k�����~��V��J���=U9x{d�y�xR��rgB����\R�-���@.�L*s{���SԧY���-})0a��:��c��GFޅw�R(xn�B/�hx˨`0�o���n��Ǫ-Q��g��na�F`���n���r�W.��a��;���u�nh�hh��7>�v rZ��L,j�7>���-�g�_��Œ3�%4�� ��'TR͸���jr���{�F]>{�!}{�����x���ƏֳG�s�~���D�q�_?�PlU��tY���P�I�n�c5TWgvW�� T�4��~R�Gm��J���;W���ͭ���w�w���B��Y���2��P�x����7R}���a�Ie��a93�kNT1Q�ˍPy.�w�{N����Q�����$��\��{/8	������cG1)�'�/�ݢ����[���d�`$<�KW������ ���=���<�p���;R�ď�:[�u1|3�9������Vqgq��N�h���quhj�%�!� WA��*���~N9�;��;�2���&���[��;�G|�ۦs]ƜF���+��6��Ӻ�9$���7a��$�X]q�\���z<��]Qʁ�#��S�}Iy7l�*K^ bc؁j�i�l���-�A�.8�+G;e�5F���ұ��	��bc��Ґ��62���`��+��\X���-�-9׏��5_L �D�F�B�\�Ŭ�T���J.K��{z��J�Z菥ъe�"��D��p���
`���'9�= �q�Dy�p���<�*���'��0 �u�O��N���{[��s��S�>�� �A��n�,��d�2c7Ǽ����Y�'���M���l�?j�[�}[�?!0E�eaD5f�MQ��~�Z��;�����%4�0�jL�-��Na(-�ŵ��'r�&���kH�9d��W��Z ��j���)H�dzP=A��r�KOQ~&@a�[��݁)������z��L[e�ݣ����c`l5RrP��2����*Ǒ��c�z���q|$`ȳ��,�^������kb�s������Ӻ�l,��X���	�5w0^��L�X�t��̴
�Ώ.�]���a���mmV� ��4J�z���0O�� �ԏ��P���0;Cp�_�W�K�3_R�)@���q���ѳS���s,x��ł�ѷ�oA�S�K���S��^����v�	%�v��s�_�@���$�ܑ�J��ؚ>��ʚ��"�{��9��J}�V�w��B*<fk�*e������-��՞Yt�]�`C�ƅ�b=)�'%$�.(ɏ�-�:a��1J$�s�MΓeI>^i�&u�̭&w�,�hb�i��2SQ>>���ыZ^!)�!��R�*��F<q�2WaeU���˙K�W���p���4j���?�l$��4I˪�&_F��Z��0ڗ�h��%Φ���s��ݑV�Ϗ1�9�XO�|ay�p�e($�zn34A���L`�Ɣ�gg�z����L��o��=����IL�U�"��L߇����i���}���rD��n߻�2�J��� �  �vs��
}%��/�֋t<���B�:E�W�<�
���^��5U��s��'��>���<���j�ž��1������Y��-WE&ك�ܹ~/T hI�&��70J�R�2���-��s+��6_�w�Ĕ�a�5�/>\!�5{��\��W���2���n���"�40�(��,�������$ܷ�����p��#iM�h�`h�x�#��LP��f���f}{���ޔ/3�84��s�J�G�B���6�^�6��9q�ß�d�v8T%Q�^��b���,�8��?��k�=��R��#��d�U3�~���ڱ �OM����\�'8Rș�	Ч�Ȕ��j�O�!��"/���x(y��ʢ�@��7��>xF!�t�ɴ�'�H��w!/���Q�Mh�V灚/�'r)D6�]y}Ό�T� �ї8���(�Jf��Q�g��˗P��7ǎsw)	��p��8�%���9�/��L�7���9����*�c0�4��%]f�P�xMg�@+qѕň�iT͙k0���-]|V3ْᏯ7Օ!f�݆�㱢�3c��+I���Zaf^ŗtkN�8fn7�#tqU�y4��Tiglxa�
�:c+5>^������R�~�4��<�O�>�`�n�p��w0"ň(OK�$��ȩ3:��K�z���VU�9iM񟌈���lBjeӇ�̈��0{*�E4�4������-��0� �=Ǣ}��bk-V�l���10�N8�򌓷;If[��i2�o݌��"5�ֆueѼj���Iy詧޿�ȴ�~)H{��m�Ne8��m���H�:���*�3�N�8䶪7=����sU�d��ξ0P�W����h���б�乼US��4���(�H8��\#@h�"�"�b�mU��7�T\HK�H�M��AE�Xi��&�e����LY�?�k,\(��,����/M�
 ��J<ޢ�?Մ(�K�F�O*H���M?�@�īɧ�HJ�!+1̙HR ��نS#��� $i�o�X�R�Od�|�n���u���&�)��u���˄\
)�����L�ӈ���ҫ,Y{Z�� _��I�u͕����l{z��$�5͇t1ɱ��s9�z�b��} #��#`1�mp뫇9=��Y�'䧐��y���)�����>Z@$�:k��`kۻ\�"����KT��D����O���#���&๋�!��C�$5�ԑ�!��K����^�kɅ�������٣7���s���̧	VR	��Gh��3G`�;21�z�/nN���F��ʯ��#�6{�S�BC��	ҷ�F�~�3A+5V��	� ���<����媥_�����/g���X��ڮ�����|��Â)�kW~i/���[���|�l���F2;�>焟�0}Zwup2Kz�)vuԶl�G��c9���w�u�.���%�}]�E�6�Ah��V)8���u���xRf$�O|�U�,��x$�Jv��[��Kvl��*K@�J�
���%�U�씅����޲�.�B�����*t������a���@yc��~G� �8���i R{8Rq(����x��ed��`p��#�ПF���=;����/�;�5
{����,WY�� ��.n��gl�O���xmfw��c����垛��a7�}q=Nz��7���=��=�`BΑ�5$8Xp?�ː�΄�d��\ Y�E�������#��0Ev���$�p�$�d,J�خwwty���p>��P
���hv֧�/ԡ��e���N-����ib��)�ul�3�[��;��Lu�;2�Ѝo�j���ֲ���^�!��������3Y�SSM���&�^��hW�979N9ds��E&b�k�������6-/��/3��|�́�����7����6�l�z�樁�aiL���%ps�G[�-����H�b�`v)(�����uԏ�=#Cė�h�Y��T;g�\��ٙ�Z��S���k�d!V�$:��3+Q΄b'���(�Cswcd��ͫD�]��|�A��JllM�e�g����)���z�R� -Hx�����
[�ގ��h��^�7������k�ٴ����em�o�R{j�L��L����j�V'�;�N�KA�uA8�VԛZ��#�v1��XО
�c��X�B
���s��'�畊�F�H��u���� T3�ڼ5�!)�C]�U�~�J���u7$���ޔ%En�4$�b�r��56Ig�/s�X��W4���m�J+�d��c6+�D��P
�Vu�|��Sl���ܪ��9��-�Z����̈��� OY���j��c���ŏ��Z�2���4=�v6S�`mdc�lט�R����ٚ��a���̕��Ka'�qxW:K�V�s�[��h�h�u���c���u��-�7ˆ�Q�����2�d�{�a�;�r	�բ���b$����URlnŔ��r��[CR�δ�D�iU��{ �]ʦŔ(:9�ջz������"Jocn-���o_(�MӶk�r�L�G�fYSa{0�	\-��{�3_�����Rn̵K��	�9���P�����dD����q�%�s�d�������&�]���:�m�>w�~"aj�k�T�4�sU��F�IMZ��e_2�@���7��'Y����3w�P˞��~E�ԑ�U�
�����r4I|gZlU���S���כ&.����tt8���E����v��^,��2�<4���JT���r��`�FC��`��XQv���
R��L�~�PѦ�TF	{gX�ҍ�h�3s��|k�$�#�ꨎ��� &ٓ��E���]��"���H�RF4�MI)��5e�l<��^�|���=����%/Hd*�X�gQ���l�f���G�)�|k�u����=�2�[���/okH-�<�T���U
ir�h&�hs��Рew��:�� ��������a�L�xʎ(&��fWI��K�Fծ��U���䚃1������b�]Ps H�h#/��eOj��Վ��҄�sq��<�4��@Cb]/��{d�-���	�Ĕ���=N뾷 O����B.򁱜=it�Ac0)�����̒���E��z��h��帠�bZ�fd����>J>��ׯbb�ª`�́7O����^~#�JR C��� �Ȟf����wʯ`��v���4�UFL����/�("aM�B����&��P[Ra2��k5��b���>
�<��a��������5�g6:~S���"�sX�yC�R�*�O�>�K`!�5����l���Ѭ�bW�n����.#���C;ӈ�\(�,);���5'�(��!���u105��l����Z�O
Ku���Z���te��'XE��`�ׂ`�B��T��,zX�_���3������==`q���A�5.f�~��!V���機�����E:��\r�;��f<�D��S�������?�0.&(      �   �  x�ŜAk�7���˞p�F3�H��C��B��Z�C��S����f�v���,�؄�w����h�w>������ç�O�/_�=ޟ��������Ͽ?߿|��������������������/�|����σ�������_����ӛ�ݞ��k,)$��߾��������~I9�#��=���r{�u�����TR
$hx�E��i�鄣���ҫ-�E������5���-d8�L'�D	��B�'��t@��nU���f���Fh����B14�,�����t���G�f:J�K���{Q'�m<�H��nQ��馺���
n�k�C.;=����Mu���Go���]
\�tWs΁�^p��鮺E�T����.���m*�&Zm��_�J����W��K���J/-�p3]��9���_�J7ӭ�~e:(�LG1J
ۮK����q`{��~�: ݫ�E�T���Wuҷsa+s�ts]��b�{�4��Ӆ�u����n�[��]�(��Njn��B½�+��-�a��B�X$ݫ�Eٯ7�@z򪎺���f:��Ȗ<�=]���I7ӭ�~�Eҽ��^�}@�:����g�=]���z9?�y �T�*��nMv6�1��gaH�uU*���֞.<�:��qҽ�[�}uk���r�{�Z�p3]���o�u�u@��nU���G/�:s<o@����o���M���t���H7ӭ�~P��^�1+�\�tS]V&j�q�i9P�n�[��@u8z�Y����t?�hU[`�������t?�X���u@����ϱ"�^ֵLu<��t>p��eݢ���ы�n[ ak#��w%$�RBޗ|�Mu�MG�}zxQn�܊ܦ�ڄCS4|�Fpi!�o:��B��H�7I'kr���$����p7I�^���\��lH��mQ�K�!�n�(�{t$|�M�n{�a��K�!��lkr_�H��|��1�{+�iP��>��d6 ��p�rOf�G.i�M(�Ԗ�h�ϓ����jC�Mm�r_�H��Ҋ���Wr�t5:lpE۴���â��vH�+�sЄ���4�����Z�ͫh��$��V��#W��@ʩ�*�N>���qĽzI�A�'���IkrOj�Mm����,	����}��%؀J��ڀd/��Ԇ#�Ն,҂�c�(�$k(F��T��$��mM��l@�(�H�������0�K<5��Q*Mf���G�̆#�Mb�mH=��w���WӤ6 ��xtI�Im@�8�j�����[Nۀ�-u�FM�ڀdt[�{R��7(*��QF�Gն}����,��R�RmH����T��U[g�}�
��6����������sm�rO�8�_U�"9pB�_�G�xǉq���$���.�=�H��Q�mx4��>�����u��{�Im@��~,�=�G��	��q3	7�U��_/g\�%Oj�Mm�rOj�Mm)i,�f4���1�Q3�z/yR��j[�{R��7�Șj��77�#ۺ#      �      x�͝˪6Iz^纊�GTq>�����@m��n!���|#"w}��=���i����_dFfF���7���_�ᗿ���/���_��?��?�����/��?������?����?��~��?�����_����������?�����_�������������������������RB���ү��ֆ����C�����ǿ�ۿ�O�7��y����;�cf`���I�I�w����j��R6����w�еyp��<�#�S��S��,�8Ap�e�A�(8���$�y�Nq���F��fo�?�,������{�na�G���SPoay���.���W!_re����&5�ʄ�	��ʴn��;�Vm�P>�x�����߱f�[pͣ]�?w�;��I��N�������4;��v̳^b�&�Fa�,`�y�|��$�r��$�k��IJ�<��_�ny����-0�;��|��-,v6��&٦󖏁��5��6���������-,�TV,�8�
���X�p(+�%ʊeI��ba�X�rZ"������Aa�?]cfq�-*y��o�>ؙ6��3m��=cg�t͕y�1���i�-o`;�[>�9�f����Yda�iY�r�E��f��i�Yda�iY�q�E�Ҝ�-�����[6W���¤�,�,�4�,L9�"SO��´�,r��K?�"�2�,�03Y��p�E�%�feI�YDY��E��YDa��Ef�Y$a����1�(L���$1�(L���1�(L���41�(L���1�$�e��[>�=�YDa��E��YDa��E��YDa��Ef�Y$a����1�(L��¤�,�,�4�(K���T1�(L�����,F�e�fd�Vr�E&�YDa�iQ�t�E�%�fe)bQ�*f�ibI�>�[֯}�-k��v�YDa��E&�YDa��E��YDa��E��YDa��Eƞ�x�؞�xˇ2&1�(L���T1�(L���t1�(��H�XF��Ѷśny����ny��Iʷl��I���,�,U�"
��,�0]�"
3N���o��Io�0��L��_�_�l;��&�_��g��X��fP�*k�����f2	d̀0��fP�&k���z4JB{�i���Ti�D�Lm��O�(��ѵ	�M]�6�0iV���	�L��_~��Q�.o`f�G��%f���c̀0�N��:��[Y2ȑw��D�;@aҙw���3֏�T���0Mb�(L�X?z��Ga���Q�$�~&K��)�Ga���Q�&�~�K���G���X?
$֏�D���0Yb�(L�X?
�$֏�t���0Cb�$�UE�[m��N�<�v�O�<�v�Ow<ڭ��*��������������o������r}�~�ęP�Neq��4��}�vf3��՝����[�u֏�W��R�,#��I�
�%���eD�X7��C�"�ԼvK�8
�$����3�����~e�gLei�@a��4P�!14�*JL�I�@a��4P�"1�JL�i�@a��4P�!14��KL�	�@a��4P�$1�HL���@a��4P�!1����G����G�No�G����G�R*�-��m��%��dыk.L;�"���,�0C�"	c�t�m�s��!s��X�naIbQ�,f�)�YDY�iQ�v�E���YDa��E��ǋYDa��E&�YDa��E��YDa��E��YDa��E�(΋YDa��E&�YDa��E&�YDa��E��YDa��Efü�=c�_�G۪��-��U�[m��J�<ږ��ny�g6�-�+������,�,C�"	3�a��1��t�m����C6b�.W��,f�)bQ�z�E���fe�YDY��E������1�(L���1�(L���41�(L���1�$��y�W��/�-�+�H�\�$f��bQ�"f�ibQ�.f����0oy��a�׼g�4<Da�4<a�����{�f9�0Q���0s4��f���\3`��l�X3$���5C��+��Y^��f	Sè0Œ��5C��v	�L��X3œ0�\3$L���t�Q�jJ�-G�)M�U쥗n9��K/]sTi)Ea�)EY�)%�VQ.�Iy����p���4]s��)%�6ۥ��R$R��T���0팔�,����,㌔�.�K��	)Ea�DJQ�"�R�J��i)Ea�DJQ�!�RTsz���0A"�(L�H)��lieUr���>��sB/�9��"-��f����&�\��0O	q����nv��٩��ٯ��{v>�<��|�ll�U�����Kz����f-xm-����Vo�����s���,�߯L?�g"I��ʒÂ��aAa�䰠0]rXP�!9,h�;J�
�$̂�d	��0E�,(L�0
�$̂�t	��0���,vQn�V^n�Is��-:����5�)�a2��*��*a�I���g�eg�M��g�e	fAa��YP�$a�J��ifAa��YP�!a4�K��	fAa��YP�$a&��Ca��<���Ca��<f��C����<&JA
��,�0Y�"
S�,�0U�"
��,�0]�"
3�,�0V`˅���[v�V^��II�"
��,�0�4�di\��YDY��E��YDa�i�bJ�E�%�fe�bQ�$f��bQ�&f��bQ�!f���bQ� f��bQ�$f��bQ�"f��bQ�&f��b�n^�"
�,�0I�"
��,�0E�"
S�,�0M�"
��,�0C�"	c�|���6V�\�x�E�%�YDa��E��YDa�a�J��i����,�0�4�l�+�E�%f�e��YdY�iY�|�E��f���Yda�iQ��O����_����Ig�Ef���ƞ�z	�ř�5��dY3 L�->�X�]g�z	�� �5��Y3$���\3	����%0��x��ʚa�,���=g��՞3�o9�ϙķ�m�j2�r:�3S��ʴ3���3�3Ȟ�da�da�da�da�da�da�da�Dal�ny��r2߲����k.L:�,K>�,L9�,L=�,L;つ��YI��!�@�tz��0�r,e����tC��b����38��d	N�+�[r��Q�������'�������c
�7���$vf��N��3�0y�����ֻyX��I��b�_�'��Y�3�G�57s>�w3�-ȱ~!@���v�2{��-2�f�������� ��S���mݧM�y�>�f��� ��H�DzvE��ЭP�l$fH6	ӽd#�0A��P�(qM&I\���Da��5Q�*qM�I\���Da��5Ѥ1/qM&J\�I�Da��5Q�*qM�I\��z�X��l�<-��oɦ��|�����e�bIQ�&�&�ˡ	MrhBa��P�$�&&ˡ	�)rhBa��P�&�&�ˡ	�rhB��P� �&&ʡ	��rhBa��P�&�&�ˡ	�rh"aL�[m���G�$p���6	�ny�M�[6W&���0�LEY�$��0]�AQ�!ɠ$̜����I�p&��,Q�AQ�$f�i3"�S����rjN����ei�9Ad���b`d8	S-35_�f�`�E �0I0
�E �0E0
SE �0M0
�E �0C0	cǥt˕���/�Z5���k����C��#���ҩ�iҩ����j>�&���2E��m�4@a�P�!A��2�ρ�e�-��ˤ[����I�<ڶ}H�<ڶ}ȷ|�}ͅig� e�4 af���T��y�r�$af{�&�y��r�Da��'Q�,�I���ir6@a��@�Yp�.y�ͪ�t�{f���K�n~<]�hw���G��თ<���x���nr6@a�y6@Y�y6 Y�\n�If��-����d�g���f��]�O^�E>yBO�%���l#�2*�/#��g"�6's��f�D�=���$	h�E�-�⋛s�X���#^q���֒5ΎT4N\_�kx��P��\�`�����c�F�����'����֘�H-�<�Py�?�>;+�^٥>ky�����=�G{>ޭ�g�l����u�f�sf洜�s(��y���    ��y���ǒݨ8�U7���<֟4Ͻ{Xߩ��kg���8O�)?�$���ۡ��� Ô��@�<��"��]�S�q�v,`��t�>¤��w~�5�L�;�?gH7d�NYd>��e�����M�gp�"�>��R����x�x�K�^=a��ݐR�
_�a�YL2X��hP�;��'���b�>y��rMz�1�T�+��8�a�����̒�|u=�<��ϳg��S���)�a����pq�
�*�@&��xK���y�Bd{���c��$y�Q���q�S��7�kA'ᴀ���򊀆4J��������:4�8�=��[�kS��O釡���<q;������;`�J�+^H�Qߪk��ٕ^�[:El.c+w�s�h�T�V���,���\��C}N~�qN]���l�S[v��|;��|B]����i-�mQ �l�� �Q��V��n=W'�ڌ�{}���݊�<#e3t������������Ue�G}��~��-��|�/����`���,sz�u����sb�p�$�/�����.g��h�(�y�=��.����<���继r���d#4zlѕH+�Y�<3C|��ģ@}��<��}!ʳJ8B��K�]�q�.����sڵ�,��w
V��<ඹ����|5vF,�3����z��
�S1��uO��9��Yõ���"����m����扩����ӏ� ��x`�yӛ���x`�=�<x		�0;$h7���3��5=�į�?����,|��S^E70��ҳ���g��ɂ��@{��-@�I����4\�v���?XT(��zr����+����s���jL�[���9~h\"v���R_»#$��������I�Ba���t+�y���{�-���J�7��~dW�,c��1g*�c��f~uh9�y� �E(L\�Eɷ�R�y�d0�74*���ĳE�uŴ�[UWfQN��8O�R�I���L&y�t�0A�0o�zD�\��K5�Wkp��4��Է�����Kl��+8Ϝ�9'�ҫ��M��bkc��0r}sU�vvrh���|�¼)i��8�Ó��p�+����d�I
�ɖI5�_s����0?���@�m�Wk);���ۚ���?������u8�͇��_,Pە6)��C�|5�"�x���y�륺��b׼2Szy�r��N	�;֦����J3W���?$;۞p���v.��;۶��g�;�v����w��5@i�d{�#̓ט���dz�ߊk�F�\��k����{�v@=>۠�Z	�y����}ƾ[�G�x�0�,Mz#L�V��^�!m I�yR��ܩyR�\�(m Q�$m���ym5�H)��J�~1W'K�2�V�S��0o뫏��,P{uϰpz����� ��m&��+*j�	ԗ��b嘶���R@��Y3��4��]|Y�������;Xv��0;o���'x����e�^�R��	�w����;`vr�0;�����vL[�Ww��_���,�8���<_w-l��t$[�̝�fR�Rv�0�g�'�!��ٓ	Rx���<��}�}CwЃ�)g7w�%�����n&���~�y�V���%
�w~E�ɵr9�B�R���fQo�ik�U|�������k�UJ�b錕��åu}�2�if����<P�g+��y�ޮ����l����x��_����r+���~ѧ���<;�����"Ա���<oL���L,Л����9��I0� �I0-y�f�e��oI0(��2�c�(���	��}N��=	�8I�`P�,I0蝒����ӵ{	��{� �Y�����N��m	-����B\�t➯r}�2��v;��wO	睰}�;a�Բ��<u��d�����_�)^� ޴*���Ot�f�7�d��\��:Ij��[�k�m���Y5��,峦�eY���ܪ���v���r���Cߗ/�u+�'�T�M�L���db�T������,J�����y�_�;�2���S�￑3��|��x��O)�0�3�����~�1�S��� }?M&�:U��䶣�>�����B|G����)��*��߁V���TN��m����/臗�!�/��V���5��>qX��mQ�tڞޏ\��� �Մ!�g5��'r����Q���Na�� ��i��P����v�c���f!����w�0�d�fO�9�����F\)W�m`��X���-E�]Ȑ.sd����h��%M�<a�i���W���h�������@�̬?����iJ�%{�|����F�������b�.�#�Z�o��(ϱ���(�Y&�k ��SC[��hF���0�g�	�;�T�0�0y�����T]���x��%�7��r��!�����VN{�KK,Ⴉ�=lSz�n|�)�?��i께�qٯ�V�q4�_N]��X�]LTz.W�쒙VF�
�Kfz*�9`y�N�m��_���v\�vZ��"�<q����q��I�0{[β�����,��Y�g�/��"�nO��]c�����z�K���%*{�f2��_����ci��J�[�s?f��XS��v���b-�5�F�7,�\v���Ƈ����1�*�
�l��O��m����R�y�L�n�}��%�j~����K���+�2�r=(���)����Ύ`y���w3�@�T��"��'�^�h��aq�:w݂ױ+?����@q�:u��,ʓױ"؀uW.�@eϤ��9����w&EL�gAy��ε���R��(3�(	-\��!��]���*�S��0���������g���Z���Zf�:�Go�w*/�B���A�����gӷ�1؞3�]�}/+T����^����Aw4P[�Pj�n�a��魇�����s�;V7��[`�:ƒ�:�wj���#zi��@�RXA��}l��Ǭ;�x�l	����(<��:�٭��f��t0�j�|�ډG�7̲��iĴJ]Q�<3>�����>sU�M@c����>\�8O�����w��oy	y��P�V��U�X�͢�������㎟7Q�o�/z�v�=@������ISg�Q.M�:�0�Ͻ���s���B��ȇBf|�rEf|�0Ź�h1
��HM�k�fûTx"���i1���Q����/��ս#F���5w:㒥�SI�Gʻ�����Tn(|�yqg�o���ccs̎�Y�W�m<�q���g��2������0Qv\(L�
���+�v�I�|1oտGN��ʎ�)Q����wL��w���?�2ᖙ"9�wƉ���+P�S�Շ�Ƒ���t/���Ü3<&�p���%U?g��0��\0�9Q�9'��0���&gJ������+���0���C�[aq�<�<�[����q"���i"�b��fq��X�����C�6���q�,Ҧ���M�ݩ�^�Ym*�Y8V�Xn�Wi&�Z����c�c���S�R���b�ݍ�n)�|lՅ���R4%k�y�=�x���8{��-8{�q+���j{�q>��0̳�ǜ��d����<b�.�5�ϖc^gy���(�iY1�0L��8�1�,L��XF��0��ad�0#C�Q�N|+�E�����Rj�^���ֈ�(Q�=ŷ|�w�Z��]��(�߃S�����?EX���(Q���xއ�/}����YA��(A�b��Da�v�ϝzM;����d��J�r˽ʫ[�-������Xu�0PG�´�(/�[3qif���6�(PX�2�l�ݠ��Q�P�<��=>����P�w��S��l����<u}�����e)kyo?S�/K��.w�g�`)I��-��׬��c:�b��D��XJ���Da�XJ�Z8���"G�Y��/��Q�[���l����2~q�%=�)��=��,D�3.�Y�.�:����"S��]g8V�~���]��oίf`��Vj��S��ȓ8}��?k�X�����F�����m2-oP4��j��X&Jm,z�Ү�֙	�����[�T��((L�Z]�%\X..�P�p�o<�Z�l
����0PZ6.��s�P�f���jr>�    �碉�Sﮟ�W�KR��y� 9��\ea�vg��b0��|��}k��)��ba�l-���y�9�n��`����r����*���-�1B0�*���@~7*Fq��eY5>�ܨ��$[�^Ϟ�0�.����E�V?'F��
��$f��3I���Y��Qw���,�*����aIg���W�˺Zx�2?����}x�wƲ��w�-բT���ĳzO�[4��3f�Y��uWy�<���L��u��>�I�,!<���߫�j�b��T���Օ�w	��w�a�0CʰH9��%9�ʰP����l�4�.�DIʰP��ʰ��.e��C�^�-�8�~�E<��ܱgÓ/�[]
�P���QFHy��쬎��#�Y���)�Ba�:۝r��<i��Y8�,�BY���Z~���y�����w�!�I%
�G�>���F�y�����ּ�q�@;��=���/ʳs?�/Í���u軆gO�}��ugt�<�dݔ�ؽ�Y�=rӪ�[ك푛!x�/]O�gnZ滇'yfΫc�@A��P�(�X(L��*R��´��s̓ե��+A�0�|� �t� �>0hÊ�%k�\%���}9��w�9
5���hD�UE���޲����<rq��@;���d�#ϳ�}!�;^�<;�wO���>f�<}��z�yw�ay�n�Q�'��i���!,8�r���- ڭr��ǽ9>q���۝�+��6��3Ȳ�n�mv�g�O7���I��	���#�&X���铄Iְ�c'K&;��	���@����	�x&I�Fj�Y�9ga�朅�f��������)��z���a�e.�~`�
_��V���V{����Kf�Qǅ�v��U�LZyw�䙑���	����l�;X��ƻ��l�;`�LŻ�e/<���H��%� �0q�a�I+sL]1�;`ڊ���W����"/W�X5p����&��D9��0I)(L�C

S����.�yL[������03��A��<Ln�Um��t���d�J��x&Y�t&Y�|&Y�r&Y�z�3���|��H���3�qeZ	�^�)��<�7ߩ�d�`f}�	��\Pf&��[`�dh�0�����)�����Ҹ���v�$L��zoi�2��.��3��;��[w�<g�������C�h���p���z�]z�o8�DX�xf��0ie���b}+8P���&�Qs�i",Q9�&�0u�g�����i�kR�aWɳ~�
���V�(��#��i�eH����������(;t��`�:	3c���6�����b��d͠0U�	3�@��!�bf�ȲC�e>aپO�>�xNZ��w�To��S���$r���<��w�:��[�XZ��`�����Ի:��[X���0]�Q�q��,&@�-,��FY���0I�Q�,��(L��`�K~0
3$?����qL��`&J~0
�$?�ɒL��6�����Q��d��%�.�y��y�RB�q/�9ۚ��[�ps6�5��*k}�Y� L�!�K>O�M�{a����k�y���I�Aa�t�/�@�tY3$̛.wL�5��7]��j�7]�?�T���*�i L+�a���Y&���L���g�Ӥj��-�0V@�n)a��[m�EK�<ږ��ny���q��Ѷ��G۲V>S�Y�v�Y�~�Y�q�Q�9������=}�m�y,\�ÒΚi�%�	�_��B��)]?kN�#S5�|K>b�,K9c�,L=c�,L;c�(����Ie��snY3sv�%5�u�����3��3����3���4���t����y$�i�x��Q��Ci�(��90�nyϘI�<��A�5O�F�I�<MrK�<M�J�l��0�o���A��SN��T�gh�U;ʵ��Aտs�n�f�B~~%3X&XM����ғKk,wq��j���b�y�1V�e�S]=���F�q�+\z����ʌ���\&,��z�.�'/��G���9�,�Ur-�U��.���^�Ӗκ����1?��R���ֳ��j��t����7�`���VOφ�����r(_�#Q���8K(�mjH)�>bV�o���
�6�Jo	~�_��K�--�w)���K\������<�wsX��?�,P9�ׂ0�̹ǟZ�?/s�q������ Z���Q�tjA�%�Ze)�Q�*iu(L��:��iu�I���[� sb�-a񹋹�.�ȹc��0�\�d��U��;X�-�pI�@���,�]����W�~���t��Uu��ycVw�ĕ�qL:�'�0��>���uj�q��/5�v���}�����9���r���>��n����u��@#��5fq�n��u��܊6v��`�gwj&ĳ;5
�d�Yw[���fH�"��X�m��4�m�f�202��2ی���f$�2�,qG�Ff��0I�m�02m�)2m#q��eT��A�4K7�x��s
$Kt�cgD�8iI�+�,3�ƞ���{5����l���g���3�X���;�fq:��W��5gy�(�m�������<NXyƩ���,(�y�,LZy���x��/d��ayƩ�]� ��<��;q���;�8����<Շ,-��C�H�
3��t(L��!&���,L:kkY�|&ѱ0�L�ca�D�´3����2f���7�%�s�X(9{�N�u�g����V�3rw=�8aU����,`ί�/�6��9�Ւ��ߍ��U��B�7��[r>
T%9�i�+�r�H ��=r�P�(�R$����r��D6ua�d+��ϳǲ��+���~Of��gg��������l#��+��x�=�-����7l�ik=��J����4�w⻯?l4P�&��F���?l4P� &�F�ɒ���I�Fa�R�w�4�Ga��(���X��-w�y	�(LX	��v�s��}��.v'���[x�ѫ�G�.�]E�P������3��x6KdY���0c�=w����XH"_�pl�W.�W�DϳUJ����8d�6��.P�,�C(LY�C����OV_���Z�nW�b������w���Y9��3�&|�Y@3�i��^?	�6Җ�5�����D�\�I��c�}:&�������z[<�#s��m�E>�+��T��p��,��v���Ϸ�=]�7�8���I�E�?#0Y�EX��&�&?��Mު�fM|�8�t�[۞0�����NT����L~����<; �8\	<P]/�<����<�����=��k�B�+�N>X#�V'p[�f7�iv�Z%s��zxx�w
c����S�ȇ�2�ȇ��F>,L>cF,�tbavyϟ]��5_]�z*u2`���3V�&�gGq�yr�����p�8�Ѱ0e�h�/��u�@�6l8�)Gt+k�)�"��[�&l+<���d}O�a��z+��Gu��+T�[���wf���9�v\�����|�X/�c��vٵ��.Y>�	��4�J2����2<y��C��E �S�:SW�n���By��ݳv�CgY����ty��~f��Kq��@AbjL�s �'h�g���b�} 
�S���&O�5>���V�1�i����B��*�r��*r�vޚ����gf��)5�7��i?T��@���8hH���5�P=�E�Aa�T��0E�GP�*�#(L���K�
3�s5��V��@��\Y����s
�s
��=��剳����ޞ�(NZ������aq�M��S��$>׆�/��+��U���;Q;%���c�
ӗo�feq_�bY ��0E�,qi�;`Ҳ:w�䕑w���aad����q�v��;`v{�+`��s�n�s��s�n�s�n�s�n�sL=G�0�l���:w��x6��>W\����,��ca��l���g�q����Y�z6ga��l���g�qf���Q���f�,L8���,�h6β�^Bw��FBw��.Bw���j%�,�=0
��L�41�(�`�E0
��Q�¨Fa� �0j�Q5�(�`��Fa� �0j�Q5�(�`F0
��Q�¨Fa� �0C0
��Q�¨Fa� �0j�Q5�(�`F0
��    ^0
#e���Fa� �0j�Q1��dQ�¨Fa� �,A0�"eQ�¨Fa� �0j�Q5�(�`F0
����j�Q5�(�`F0
��Q�¨Fa� �0j�Q5�$LR�¨Fa� �0j�Q5�(�`F0
��Q�¨&a�`F0�"eQ�¨Fa� �0��\Ͻ�E0#��90�RN̲��e�fa� �0b�Y1�,�`F0#��b�Y1�,�`F0#���fa� �0b�Y1�(L�fa� �0b�Y1�,�`F0#��Y�m���{qi�S��>G�4z��i�4�,�i�Y1�,�iF�4#F�������Fa�H�0b�I�!Fe#����Fa�H�0j�Q5�(�iF�4
�F�Q#��4��H�0j�Q5�(�iF�4
�F�Q#�¨�Fa�H�0j�I��F�Q#�¨�Fa�H�0j�Q5�(�iF�4
�F�QL�D5�(�`�E0ʢ�Q�¨Fa� G�E0
��L��d:�E0ʢ�Q�¨Fa� �0j�Q5�(�`F0	���X5�(�`F0
��Q�¨Fa� �0j�Q5�$�N�ca� �0j�Q5�(�`F0
��Q�¨Fa� �0:������FY� �0j�Q5�(��D��Fa� �0b�I�Lǲ�FY� �0j�Q5�(�`F0
��Q�¨&at2��Q�¨Fa� �0j�Q5�(�`F0
�����t,�`F0
��Q�¨Fa� �0j�Q5�(�`&�d:F0�"eQ�¨Fa� �0b��V3�`F0
#�d��t,�`�E0
��Q�¨Fa� �0j�Q5�(�`F'ӱ0j�Q5�(�`F0
��Q�¨Fa� �0j�I�L�¨Fa� �0j�Q5�(�`F0
��Q�¨&at2#e���Fa� �0j�Q1��dQ�¨Fa� �,:�e���Fa� �0j�Q5�(�`F0
��QL�|�L�¨Fa� �0j�Q5�(�`F0
��Q�¨&a�M�Ca� �0j�Q5�(�`F0
��Q�¨Fa� �0�&��0b�Q1�(�`F0
��\I5�(�`F0ɢ��P1�(�`F0
��Q�¨Fa� �0j�Q5� L�6	�Q�¨Fa� �0j�Q5�(�`F0
��QL�|��¨Fa� �0j�Q5�(�`F0
��Q�¨&a�M�Ca� �,b�Q5�(�`F0
#��,j�Q5�(�`�E'��,b�Q5�(�`F0
��Q�¨Fa� �0j�I�o��P5�(�`F0
��Q�¨Fa� �0j�Q5�$̷Ip(�`F0
��Q�¨Fa� �0j�Q5�(�`��$8F0�"eQ�¨Fa� �0b�;ɢ�Q�&Y�$��n�P1�(�`F0
��Q�¨Fa� �0j�Q5�$̷Ip(�`F0
��Q�¨Fa� �0j�Q5�(�`��$8F0
��Q�¨Fa� �0j�Q5�(�`F0��M�Ca� �,b�Q5�(�`F0
#x�,j�Q5�(�`�E'��,b�Q5�(�`F0
��Q�¨Fa� �0j�I�o��P5�(�`F0
��Q�¨Fa� �0j�Q5�$̷Ip(�`F0
��Q�¨Fa� �0j�Q5�(�`��$8F0�"eQ�¨Fa� �0�n�d�faN���$8��4�,�`F0#���fa� �0b�Y1�(�N�ca� �0b�Y1�,�`F0#���fa� �0:	���fa� �0b�Y1�,�`F0#�����$8�4�,�i�Y1�,�`F0#8�,j�Q5�(�`�E&��,b�Q5�(�`F0
��Q�¨Fa� �0j�A����X5�(�`F0
��Q�¨Fa� �0j�Q5�$�N�ca� �0j�Q5�(�`F0
��Q�¨Fa� �0:	�����FY� �0j�Q5�(��H��Fa� �0b�I�ǲ�FY� �0j�Q5�(�`F0
��Q�¨&at��Q�¨Fa� �0j�Q5�(�`F0
����Ip,�`F0
��Q�¨Fa� �0j�Q5�(�`F'��0b�Q1�(�`F0
���H5�(�`F0��� �,b�Q5�(�`F0
��Q�¨Fa� �0j�I��¨Fa� �0j�Q5�(�`F0
��Q�¨&at��Q�¨Fa� �0j�Q5�(�`F0
��):	�����FY� �0j�Q5�(��L��Fa� �0b�I�ǲ�FY� �0j�Q5�(�`F0
��Q�¨&at��Q�¨Fa� �0j�Q5�(�`F0
����Ip,�`F0
��Q�¨Fa� �0j�Q5�(�`F'��0b�Q1�(�`F0
��\H5�(�`F0ɢ��P1�(�`F0
��Q�¨Fa� �0j�Q5�$̷Ip(�`F0
��Q�¨Fa� �0j�Q5�(�`��$8F0
��Q�¨Fa� �0j�Q5�(�`F0	�m
#e���Fa� �0j�Q1��dQ�¨Fa� �,:	e���Fa� �0j�Q5�(�`F0
��Q��o��P5�(�`F0
��Q�¨Fa� �0j�Q5�$̷Ip(�`F0
��Q�¨Fa� �0j�Q5�(�`��$8F0�"eQ�¨Fa� s0%Xv��o��n��ı��/��^�[�Y83�<��� t;��R�D����I\:��2V �
���p����C0����/�'�8��*�8�5�*�PB*�G�/ *+�p�ͪ+�p��˛���wS\�@�O�����+���ó�p��y�2���%�G�.�/��2��e־�����%�K��ކ�s�}1|޵���z���;֗T����Vh,�~��+���I�F������E&��p��3���Y3 L��=?�� f`�fP�u}�����5������	$L�5C�X��fH��;�	�%U�M�``$U�'a���/	�焆[L����]~�..�G;;�Z��W����0u���i+>L_��;`Ɗ�� 3�Dz��7�*V������J�i���wܯ4��y/;�����\f��/�)o�����=N�c���;`,�ũ!��B��	G�e�g��Io�y��7*��-�!`���p��qN�!�ڢw+���3�N���)GyfDq&u��ܭ��N��<�gx$7���<�_�Swxdgg4N�!�V�I�<}�����U�m8���7�
�@���pJ�y�4��J���؋0��*��E?VB��y�P��Ҟ�����^�vV�)���#װ���I���^y����8y�m��޵��to'�џ��L�I�f^9�@���ׯ���������1����ejש<�ֹ���ۯ�R��:5�:-�*P�:@���}.�Q��� ��ȍ	�N�]�E���r�?���n�b�.�}9���לvؔ����-�Oх���.
)?� W=�΄O��9	,����-����n���J^����wJ��w*��앩gJS���4�N)�.�����y��l����.NnS���}瞩����\-������m�MJ$<���q���+c�}�yj,�.`&�&�yj,L^yj9�\�8��x���*������9�=���`�iİ�dI�y�d7+�`�~$k�,c&k�вwi�<�.�ek�֛w��dL䤒�>���"�|oYrq��xarj�V��ܼkmpq���կ���������Z��zwSp�<9���m��Jmw����wk���9u�T�,�PB�����ͤ/�iu�    <�i���W���m��cgf�<mw>�9��P��jZ<N	VK�g��t��˳2�u���%�Q_��Uyԕv�{��l�I;��0}n���|�.-��K��l�G�X~��Z�	�nwj�Y�8���,K�/�ܫ<��ɇ�^��UYG����+T��
c'P�k�ѻ�_�yԲT�^뛨��u^�ķ��ׁ"�2v�˓ց������z!���S����@�۰�@u�[x���_�ȷ�l�?����D����6�kܲ�C{=ȶ<���j�-�S�~� �e� ��4i���ti���i�BoJ�<Q�=��t����G�(-E�h�E~�jy���>�v��)�Y�\����s���x�2���S�X��am��ݟQ�U�f��� _�h�4��e	b	Q����8F�y�� �;N>-!�R�%,veOSw��cw%�@M!
ӗ#���R�yf;+�*�7_a��r�i���
˓vҁo_��;����a�j���ԥ�ho���-C{�o��/C�<�#�$,h�rL[A\�YV��
K�d��|�,�0��A�is*	Q�"��i�&��b,Q�!��I��X�0A�%
��|�a���J�Mt�9eO��M4
�w�\,�p/gH�	c��9�vT���+����A
ߺ+E��҃4S����0�a���@�f>�0t��̿��T�~�X����c�ʁGq�
��3'r�VN�m���B�-��u+�g< ��U����3��ٍe�ҍ�)+`wj�EY��
|�Y8��Ǝ��5�;�Tv�:�3VD���k�­�;
VD�������S��p��%m�X�]��[/~�P��ek��삶4��;��Ľ��'��`�Ņ����p�¬���.
`o�)2>w�(ː� 	3c�q�)�͓fo�߿Wm�%�i6�6C�BX�R��;a��ô����/�'󷪯ć��n�����+-˓�n�𼍟}��=����=Y���g7�N������݈��݈:�W���5�Q�Z�+𜽨a��5�5��zQ�'���a��5z�V��s�8�ɑ,��G��@z��6�-��\i��,k��z�'���j��~O[�kx�ޠ��]<����iԶs�Q �&��E,P]r9������\��[˒�����Ca�d�0�c��M�:�DC2�H���
��z��8;��K���1�[xv��X���H��)+�{�.,p�M���gq1�Ҥ���;���)��3֙���c.�\r���:����/�ŉ+���c�Y�$��(�~���	����l�#�yHU��,�l�Y��� ��[��B*{�K$[v��-��k��1��m/��|mٯ�����,w�ջ�g�΂�4E��M�sN��"�u� g^U�A%R���5�,P���(L�^�u��Ze/�gQ�pe&��S&�\^��F{��n�q�ht{	[̺𑵙��/�	;��Z_����eSk�^����>���D�.��ɇdY��Y�=E����YSD�Y8�Q�eMM�9�{�Ҥw�h��c.(�^������{$Fy��mz�㵸,P]�M�[��x��m�Q�kP
��Wj�-8ce6�>n����ǽ�V��v��C{!T���3 ���3�^c9^���Y�~�)�0��~��Q���z	��k��f�tE��|�����,8���̹P���?�
c]v�-Y����-��3���.�Yk�)�o;u�.��/�W��&y�"��2���x��2XV�|�Y���"1�����|�H�%��Da��S|��n ��䕧x��)��DY���ݎ�[�8m�)���{G���Hf�<���籀�l2�o{n���,�6�.���G�<�nc��%$�᩻�2��Ա<m)�Q�=�<})��}�;�+��1�\CU{+���z�]����)p,P<�$�0�Lca���7���o,L?��X�q���0���&Hu
�:�I��I�8�>/���!�	��J���S�1Q�w�I3��J�Ұ��t*J�k���c's͐�܈�[`�Q����G_v��;�3��|�y�(������I����A���������v�b~q��>ϰ@{�=@{g0�<S�Q��x�nldk8<�w��w��wf�[Sf)^A�$M@<����& ٿ�'�=�1������pKN{���bN���Sf�C�!���Q�����i+�!�����y��z�d���w��O����^�GJ���g�Q�<����O�ˍ��k���]���� ���'#o1��|o��3f���a��{����S1-xvog/N9���0g�v�N�u&��cٔǱ�)r,Fa��Q��´ig��Vv09��M1hu�557;����=����Sx�8޶�i���r�%���V��K��!mV6�2]?�`[�Ѳ���R�+�MNZ}��7��P~p�Z;�'�
�-s��)�����'��Jxp�k�y��l�g��k���Z����rZ���ڜ_K�|+��V��:}�g"��y���oվY�|+��V.!����hےfϴ;��vQl��Cj'
T$����ډ��R;Q�!��$L�y],L��N&Ij'���K7L�a��Uk��n�,�t�da�&#	�,�S�X���Wzv�-@G��4kGa�����R�qv+���W�M��J5��*�p5�K,�j��lE-d>�Dh�6ReY��*��ڝڍH�a_��MW�[���/��^[�P�����F��|��z!���,�c'){!���6o,NX��<�wa�%�m���?{ɠ,Izɠ0y�������^2�,�z��AY��%��������L����,�!�dІ��ke@���,�=L�i��nu~���V[ҥ�=����hf6�w��ԕ�|O��d�(.\����L���	h�n2=���>4�4�S�O���JV̱��7By�1G(}���e�;�0���#
�$����!�0vF?bH(L�
%���$�!�0��
TV)���v���R��|��p�ŝ�����,�����Aq�V�����+۔��o�.[��T�%��l�~��f�)������t*K�%��$�}�!��~�!��wL����+�;�{ۇ�����܇g��S
#��a��3�=@�H�|&�����պ,P:�pY9�02�+x�����Z��8r4gad�{���Wf�'`a��0�	X�,L����ڞ�g3�w����,�N%
��C�⼩D���T�Q�n�K����Nf�v��{vm:����Y����7Ӕ�ivv��.|�o�(Ρ<<qfˤ��C_&N�~�^��n�����I�e�Nŵ'�=�<m��{�~�}�,c�}���x5�>�b����r����ĕ�����+<��;y>��������1�9�/v�/x��N��)�A�Oxx�N���g�8ǎ`�<�m�t����6,O�r���p�b�r�� �/���0��?���6��l�u#zx��
3k~�	C}M���"���h�ő�,��� aJ�G�{�eϣ˲�Z1ײ�Q���VMu�H�Z,�{��ɻ�x�}�H#�;.�{�Hφ���@z��'�W�޺Kk��ŴsA���ݟ�<?�G�@���h.
�Ci��(�NyH��ݠ�ɚ���h�
�Y(�f=�0;�א�b6(Л�Pb�W�r4�i_���N{m����WV���<������K�(Y�l��"Ub(L�a�8
��{0��[��u�4���Q���Fq���ɻ�=KV2�-8q�U��'I�A&�\����e&yx�Y ��T)Caڛ�T����;�閅3ΞV$ˬ���V�Qx�6��\Á|�[�������yxҫp��,�'���Kx�>e���1�8u��b+o�2��vJ��)�9b0P�)!� ��R|�!H�g�Ԕ(��h�~/�
A^���;�K
;&�~����O����(&��%y��N�ܩ��;e�8�$���؍NY�,�}(LY�}>�7D���eT���RO��؈ɕ�U���k�,خ$[=�����Z����ǖGu~Mw��>D�|�Y�4�����4�|�X��̠�6 �  qK��e��|$g.1�N�}�`f�/�;`r��"=�P;����q-c�}}jXߪk��p|�`�2�i����y���i,e|@G��)	@�lGj^����lz?���_��Ic}�Cy��_ �f%k�2w�����̱	0���X�N�c:���7��\��M���;R}$��0m%���ڳ�<iZ�Y��Cr��}��\�M�˖�0P]:��uaU�<=ȳ޹g=�Ɣ�	�if��r����eQ����l)n�g���;xf$����o��vh�</�zOܡ�`�Y<:J6��65�����}s<��Be�r��.?�A���k8��Қ�g�����ò����'�]c�;�[`���;`���;`�|�;`�p�;`�d�;`��;`v��`��S�Qf�r�0ʌ2�v�2Ca��2Ca��2;"��?	�YB�]0�㝚S�1s�睚z	O�H9fF�/�Xw�i��nT>/6a�������}�>��L�V�]�P��;ӕ�y����yn�م!��fX�gW"���UP,�.E�)����@���]��wE���JX���^k�\�#��,�'f?��{�={q�81���j�ɏ�2]���0C���0E�EX�aa�Nխ�|��5�-_ɣ��X �^!a���,P#�˜YSo�	�O�g��o���I�Ga�|��;�Z�ٜ-��r�q����9s��g�'�lΜ��<y�h�����,Y����`h~w�F]��^2���[�?^H�����t�j�p�n�x�;��s��'��������y�=���Q��B�i�3r��@����պ}t7Vq-c]�`���u��?�]�	���ٗ��}w��Ca�_X.^�q����w_�|���%����3����ϓ���H�y~ށ=Ľ�A�9�H,�ٵ����h�a���F1�r⾦\ϟ�%�Q���G�	��#���Z)W�Sg�� <��_; �h6K�Ɯ�'6���>���jZ��r��E@q�t2@a�z�u�\	<�>�_�v�s;˲J"��U�*"���<�@C�$Lݕ)��Uy� �zl,3��]6�S�������nu�v���N�?�?������W	��0m5�ϵ�`�3g���x�V��i����ձqGa�
(�������Ղ��%��Ȯ����_߳�|!v�Z��/�_�u׮�<|s��K��É����N�k��<b�
�9�(P��;
��޽�0ޓ�Sd����}4�P�;��������;(��?亓/�㵭��r��5Icy��&ޣ0�xOvM?$ރ�̯T��-X株2珗���oD� �����	��Ҳr�4�)���F��u3�����k���h"��ۀ��]{{��m�X��i/����H7�(�޴��ꛔ��覽���Y��(��v����!�;�d�����y���z�7<�>v\���*%�P��bc���J�@~�]� (��k��.��\���� P�&�t��!��
裲8���ay����0��]Q؁      �   y   x���v
Q���WP*(M��LV�S*JM��M�K-VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QPJ-H,*�W״���4#�i���T0�h�sbAfIbNfUbr���y S�� �H?      �   2  x���MN�0��=�ț�R���J�PA�t��C���N*q$���N�M��=�D�ߌ�M��m��l_�ٮR$�ky�8�#����{�B��� ��v���������蟮�i�(;A������'E�e���/s�y�^"�U���)����$��LĹ�5�\��8j���FS��w�gM����E�>T'��WRk<�;2>wX�Ι=ɞ\����.:�8�!�:���!��L��e!������5&+*;��h�~�G�qR�$̰n>�����Bo1,�:}���W�L�jZ�      �   �  x����jGໞbًm�U]�U�䔃��@��j��֖p�<ff{[kAM����,0���g����������������/��_[�>ￜ������ݼ����v���8~=�=<����wz�>���t�?���d�n��/������m��&!�݆v�7�W?!M��6��f�4���|w?PV.��e�Z&����E�]��2�R���2������Lca�j�(i�����j�N563ΐ�l����F�dJhH�l�^��Z!c�T�Ľ@��sm1�Ȳ{�&D, 5J��t�4���0Y��e�]��b�Ǭ�v��k�4�� �.�&S-
R�d�A�r�e�<�@���@���ng�)���|�����~v�
�E�ď΂�5���䜎���S79��tC�(���I��5JV��$��PYu����A�:f�npN�KQ2r�3q�(Yr�3iE[^�cd�'c2;f��|��E�~p��jW�>��~p
�H�Q��^���kB��s4�_z��e�7�h���e���-㛃s�Ln�Ѳ|sp�����9�f��hZ�=8GӪ�FY �1�ca��$a,W���2r�3�h���d�M�T���d�&'g3�(���)�&��V��e793��aצ�ə-q�(��ɩ�E�$JV���%��~rZY����NE?9K.R�F)�i�&g��"������&g[Ԏ���m� 
&nn���(Xvc���Q0uS�J�`�f�D����gO��U72Ϟ��j��6���j������-��o~/��7e��/E��BP��/E��"P��/E��P����H�_��T��~"Y+��H�J�'�UW�׬:��2|�d��Y�+Ӑ���Y�+���+�x��D��,��%������l���i��*ry�E��6.r9�,ե-;��OF.���R�o�g#�f�$�G��m�t�-ٱ�5���G��"��3��OHڊ�(̏�m��䲨H�,#��)�˽W���V�$mՓX�2�p���	/QU+�2��C�����,�I��t]5��vm���f�*��x������]�6��m+������o=�T��N"U���H���$rQ�������D��=&�*I���O/K�k[���2���2�M�P����:A�	fW5��2�O�L����X"���^m-�"�����P���--j�������T�~����0ʗ      �   k   x���v
Q���WP*(M��LV�S*IL�I�OO�K�K�L,VR�P�LQ�QPJ����)���E�ə�yJ�
a�>���
F:
F��:
�! �a���5���� � |      �   �  x�͘Mn�0��>��Ug��誋,)Ф����\'�]��/9�I��["g�=j�����÷�n����������W�y�����8��p�N�y8澻��S���?�)�L�i�����t�����k�}{}��yx����8O�o��vv�8��}����Oݝ[w���zݡ��/���?��?�6R�=3WZk�S�� y��d�V#�=0{Eh��v�Q��䇁e�/��#�Wf �0���B�/=S+Dуf�F�B��À�(��jd)���r#jtʚt�*��NEA�� �ޭ�D��
i���r����6Q
�4nct2�6�3��1���V#K�a�;�c��(?���[�,	�MjN]�Rxl�c�W�d��%��L������{�"��j���a�`Ҏ�T�K�yFVp�<�Wk�	5OԬ��y�Z��&�<X�����Q�4�BHmk�	�NDVиC�d8�R�)�4C?�ɒ@,��/��A�X#�U�Ґ�������ց���)��Pe�Qn�� ̅{�e�xec5�V#JiV���hӛ���]H���
�#Vиvd1�*\5�V#JA���pkv<
~�D���Q�A4�)B�V�Қ�||ЄFESCLh��2]�BZ���ؒ %�Z�,����hBP�j�-ʲ���?`���      �   0  x��սN�0 �=Oayi+�֝bGL"�"�\�!Rh�x~�,6���ر>��z��<�I���z~?t����:�|>^���J��m(#ԝ�>���!~C�7��������4Ϣ+�t{��ّ%2" +FP0���p�� ��������w��q���Ne�ɘ���/�� ��f�h��T2qK�mz�U�V}u��(�$�'�鲖��=?�ɓ;TI��Ҏ�C�M�ӹ��p�j��lR���"�tURg�܆ʫ\:I��q&�n�p�dJ]�'v-+�"�NN-����+�OHR�      �   �   x���v
Q���WP*(M��LV�S*IL�I�/KLNL���K-VR�P�LQ�QPJI-NI12�K�"���J�
a�>���
�:
�z:
�`��DӚ˓ږ��7 SF����a>����5&p�--���)�.. V�oT      �   �   x���ˊ�0�}��'�*1�jŕ�.
^@���i0�U�*��̳�b�t�Y�v�	�B��?�z�m������^�])���L��T�ke��8�=ጐ�zcCq$�P;	��MY�[�%��\,?�zc	��I�7����a,��^���kj*�t���(��H"MX���qV5�����w	)M�(�v����dqL:eZ8盕0kڥ�� ǤF3��������Y� �;�j      �   �   x����j�0�{�B�������N��2��t�+�:���з��8g}���P�o������0u�3J�#!+X*g��%6���V�S}|�-,�5,�y� �������;���i��m�3�_Ȼ��أ`g$��S��\�ID��[{���/�l�E��s��^�n�����R�m�#v=�彈-�H�w�����!x��^�����,�E���]       �   �  x����jAE���aV6a���EVYx!�N�&��0����Ou]�E>��H ��W�S}����~�o�u�����~�?�o���𴿼N����t~>����_��������~���S�u����7w�U����|82�y�*
\�nB����(p��1p#��S��D���3���,�ő��Ɇ��H��S�y
�-�+��V<lXԀ�}gQƶ�E�>1�},j��o�4��,2il�Xd�؎�Ȥ�U�
؎m��؎�Ȥ���g�[���qt�����lxd��*�qZ��e���l.kTAesY[�[kJ	�SZ	�8�� �Kz	���� ������$�HL�H�� �.1A"����$&H�,1A"�	�JL��MbDΣ��,$�$&H�KL��*1A"'�	9KL��Eb�D�$r�� ��(1A"���4�	�$�JL��Ib�D�$r�� �����$&@�:JL�Hݖ� �RL�DO1Ak�	�8�� ����\RL��Ub�Dn r%&Hd�� �&1A"]b�DV�	9IL��Yb�D.$r�� ����,�(3�2���4�	��(��N��Ize��(s��@���ܤ(Hf���ʭ�	���;!�^p'���g���|�P�3w_p���j˒C&�C9e�w�s�dW5%�Lx�9�P�3|U?g>�і��X]r�;>�L����_�ż��/V������l��qc�p�.�	      �   �   x��б
�0�ݯxdQA�j�SS��Zl(*�����_p��{��	I��hk@���2�h1�d�z�0/�E ӣP?X�6�6�������.
ᆹ��,KV	LX-�r����|���}䃓��L*��ZZ�iG�̉�5TX`A^�,I\�)�N.i���`g櫙�L��ŀ��      �   �   x��ͱ
�0 �=_q��BAW'����m]KL4�#��/N��oz�M�m��P^���XI�����}��"m��XB&	�ǇOξ�)��~��0A{��x��0N�7�bmwQ����w����)��-D�      �   s   x���v
Q���WP*(M��LV�S*�,�/�O�O.�M�+�/VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QPw��T״�򤊁F@��h�1�<W�g2�d 9�`F      �   q   x���v
Q���WP*(M��LV�S*�,�/�O�-�IML�/J-VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QPwIMV�04�7 r�J��t2����5���� �&P      �   �   x���M
�0��}O1d��"��q%��B�`k��bS3��^�<�v�}��y�JH�r�ugMJLDG�ᓦ��Z*2����ZD jde���~J��݈�MvL
O#e���h`�;�!7�*�(��:�A�{{��)Z(���Y�b�\xpV������-y46�ұ������g^��zw��Hͽ/��ع      �   
   x���          �   	  x��[�n�F�-=Ł���jE9Υ�(6�Q!K���E��0&��$G�j�bj�Gȋ�9s�HJ�%Qb�)��33��;wNG��>��d>�V*ҌǬ�k)�r�b!K[�n��ՅV"�K��)�i��22��\DL]3�=��=�X$��J���K��L,�8�<�L��x��x;_�3h?��A(X�� OX�����v��H������]F�'7@���\	JZ���:`�+�v�,d4�2J�R2.�G�q��5:]�G���OF��p���x�O��s���h?�}�"���2��4W쒽c(R34�LKr�8��B�s%!� dfU(-K8�Jp,�����c�dmǠ�>�j@��|z�Q*����w��?�M'õ�����E)?��,�
�B@�E�E���N � /��!	j�3̝8S�	lu=ډ@���
�d:����N�Q�����Ԃ^-�?J!�Xqh:�/,
�Cs89��mO��xU7VA���:?�q$'��#�ߛ��D���J@�t=�صn�,:���*���N���]�� l<aH�� ��9�8��~��O���-r��-4dr����(�_��EAṔ0�snܠ�3B>beq�`^��.����ha6zH�Ё��TP��%�`�ȌP��<0/_��ʠO�Z1%0+㐢|AAH��(BA> J1Q�����/�H��&_fc8�O/NH��	�n(�$cI({M?���X�1�%��8�+��=�	�1�O���FW"aQ��䐧L!Q��kI'ܰK����ed��|�L*s�+T �wֺ_�����b�끎���o+sE���ꡔ�7���˭C\��f��i�u~k�^��Ei���EC�
��T�I�_�_̧�n��ʍ��eX�P��$<	�3����<&SDc�Z��m4jg7�v1�χ������
��k�3�LDH;�·�ѿ�ڶ5�t�1i�Gb+�Y�q�$_ 7u�KU�5*f��v� z��P���U,��L��1'��s�q���ŗ�d�Y�l{�T�T���"0�Z,��u1�:O�!�� kT�8��J�$
u�D�%Z�ֆ�d�K�1��(�r)���xe�R��B��6q���� �#T��x���)�w��ba'uVU^J�P8�p��I���D{��y�0�<�a���Q��ꓻ�zem\H`EY���d��n&ڶ)ԢI��)\���y������K&�ҍU��K���ab*�\��+ł�J�H��K�E�^G��07�ZI�L�d:�T`o\(�]ӡ]� G�<��o�P�%��BP��MV��љ�%p��������Y�S��[��g:�C�^ƬJq�V�:E��[5{���Q���ML�o����@�DD	%`E�J��d8�N�6,C:��$�	ab.����i��$}��- q�yw������=n���#���, D�0����i�KdF��"A�`A뒕􋝂	N��<�:���Bq�!�.���,�L�^�|����3,�tcK2��pƓ����	�޾|��k	���+��X�E��*�[���,��:��
l�&�v��#�G��yMb�X{L��uE�WeEڮCw��Zs�Q�f�sNsV�/�Z;���;��j���E��Ϙ�7U�G�?c�[�{yL
�+ޞ��XN�Z�`���5��)��g�ߦ��\ƥ�)E���'*��a�m���ޅ
 ��u:��IP0�=L1��U0DUh#"�4)Q�&׉����C�G�t{:G�Q�Z�!Av�^w�=�>������6�P��{���z1��M�oG���s�I��q/�/���XUyޞ��0��,��m6<���5����.9ؘ�:>��uwD*Wn	T�uJ�ǔn���"����H����wp7r���}(��"� ��r_7t��&�x-@8i�Re�On� �l� :��@�t�kJ���r����b���������X�G�k��0���s����wa��e�JEL�ZWP��ܦ��� so��.��_s�}��y���u�L����>�dۼ��5�������5������J����F��&o�;kv��|M��֐�zӲ��$"kE:����Q��U�F��
/J�IbMg���G�7.��9+n��?��6]�?�f,K�A�]	�c�L��{�Q����X%�U�4��O,YM=<]�x[k���Rp�.S�^]�qh�н��+�<�wټ_����5A����P��m)
�=�(_JJ5ݝ��w$n�!���܏�JY_�5W�oL���'�g}i�1�����AY      �   �   x���v
Q���WP*�,.I�MT�S*�,�/�OI,�/VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QPjwuwR״���@#��N��>��~�1�h`�kDuL3������2�� �^i      �   t   x���v
Q���WP*�,.I�MT�S*�,�/�/J-N-*KLI,VR�P�LQ�QPJI-N.�,H���S�Ts�	uV�0�QP���tqt���S״���F@�\����A�rq @B4�     