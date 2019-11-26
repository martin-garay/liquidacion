-- Function: public.sp_trg_ai_liquidaciones_conceptos()

-- DROP FUNCTION public.sp_trg_ai_liquidaciones_conceptos();

CREATE OR REPLACE FUNCTION public.sp_trg_ai_liquidaciones_conceptos()
  RETURNS trigger AS
$BODY$
DECLARE    
	_id_estado integer;
BEGIN	
	SELECT id_estado INTO _id_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
	IF _id_estado=1 THEN	--si el estado es PENDIENTE LIQUIDACION

		/* Inserto el nuevo concepto en todos los recibos*/
		INSERT INTO public.recibos_conceptos(id_concepto, importe_fijo, id_recibo)
		SELECT NEW.id_concepto, NEW.valor_fijo,r.id
		FROM recibos r 
		JOIN liquidaciones l ON l.id=r.id_liquidacion
		WHERE l.id=new.id_liquidacion;
		
	ELSE
		RAISE EXCEPTION 'NO SE PUEDE MODIFICAR UNA LIQUIDACION EN ESTADO %',_estado;
	END IF;
    
RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


-- Function: public.sp_trg_ai_recibos()

-- DROP FUNCTION public.sp_trg_ai_recibos();

CREATE OR REPLACE FUNCTION public.sp_trg_ai_recibos()
  RETURNS trigger AS
$BODY$
DECLARE    
    _id_estado integer;
    _estado character varying(60);      --estado de la liquidacion
    _valor_fijo numeric(10,2);      --valor fijo para el concepto de una persona
    c record;               --record para guardar los registros de la liquidacion
BEGIN

    SELECT id_estado,estado INTO _id_estado,_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
    
    IF _id_estado=1 THEN    --si el estado es PENDIENTE LIQUIDACION

        /* Inserto los conceptos de la liquidacion.
        Si el concepto esta parametrizado para ciertas personas solo se cargan para esas personas */
        FOR c IN SELECT lc.id_concepto, lc.valor_fijo,co.mostrar_en_recibo
             FROM liquidaciones_conceptos lc join conceptos co ON lc.id_concepto=co.id WHERE id_liquidacion = new.id_liquidacion 
        LOOP
            --Si el concepto esta parametrizado para ciertas personas, veo si esta esa persona, sino no se inserta el concepto          
            IF exists(SELECT 1 FROM conceptos_personas WHERE id_concepto=c.id_concepto) THEN

                INSERT INTO recibos_conceptos(id_concepto,importe_fijo,id_recibo,mostrar_en_recibo)              
                SELECT id_concepto, (CASE WHEN c.valor_fijo is NULL THEN valor_fijo ELSE c.valor_fijo END), new.id, c.mostrar_en_recibo 
                FROM conceptos_personas 
                WHERE id_concepto=c.id_concepto AND id_persona=NEW.id_persona;
            
            ELSE
            --el concepto es para todas los empleados
                --si el concepto tiene un valor fijo definido en la Persona
                SELECT valor_fijo INTO _valor_fijo FROM personas_conceptos WHERE id_persona=new.id_persona AND id_concepto=c.id_concepto;
                IF(FOUND)THEN
                    INSERT INTO recibos_conceptos(id_concepto,importe_fijo,id_recibo,mostrar_en_recibo)
                    VALUES (c.id_concepto, _valor_fijo, NEW.id, c.mostrar_en_recibo);
                ELSE
                    INSERT INTO recibos_conceptos(id_concepto,importe_fijo,id_recibo,mostrar_en_recibo)
                    VALUES (c.id_concepto, c.valor_fijo, NEW.id, c.mostrar_en_recibo);
                END IF;
                
            END IF;
            
        END LOOP;       
            
    ELSE
        RAISE EXCEPTION 'NO SE PUEDE MODIFICAR UNA LIQUIDACION EN ESTADO %',_estado;
    END IF;
    
RETURN NEW;
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


/* borro las liquidacion de enero,febrero y marzo */
delete from liquidaciones_conceptos where id_liquidacion in (111,112,113);
delete from recibos where id_liquidacion in (111,112,113); --los conceptos y acumuladores estan como delete cascade

delete from historico_liquidaciones_conceptos where id_liquidacion in (111,112,113);
delete from historico_recibos_acumuladores where id_recibo in (select id from historico_recibos where id_liquidacion IN (111,112,113));
delete from historico_recibos_conceptos where id_recibo in (select id from historico_recibos where id_liquidacion IN (111,112,113));
delete from historico_recibos where id_liquidacion IN (111,112,113);
delete from historico_liquidaciones where id IN (111,112,113);

delete from liquidaciones where id IN (111,112,113);


--agrego el  estado de la liquidacion
CREATE OR REPLACE VIEW public.v_recibos_conceptos_detallado AS 
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
    tc.descripcion AS tipo_concepto,
    c.id_estado_liquidacion
FROM v_recibos_conceptos c
JOIN v_personas p ON p.id = c.id_persona
JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;