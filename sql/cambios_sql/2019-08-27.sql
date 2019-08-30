CREATE OR REPLACE VIEW public.v_recibos_conceptos AS 
SELECT rc.id,
    rc.id_concepto,
    rc.importe,
    rc.id_recibo,
    c.descripcion AS concepto,
    c.codigo,
    'c'::text || c.codigo AS nombre_variable,
    c.formula,
    c.mostrar_en_recibo,
    c.totaliza,
    c.id_tipo_concepto,
    r.nro_recibo,
    r.id_persona,
    r.id_liquidacion,
    l.mes,
    l.anio,
    l.periodo
FROM recibos_conceptos rc
JOIN recibos r ON r.id = rc.id_recibo
JOIN conceptos c ON c.id = rc.id_concepto
JOIN liquidaciones l ON l.id=r.id_liquidacion;



CREATE OR REPLACE FUNCTION public.sp_trg_ai_liquidaciones_conceptos()
  RETURNS trigger AS
$BODY$
DECLARE    
    _id_estado integer;
BEGIN   
    SELECT id_estado INTO _id_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
    IF _id_estado=1 THEN    --si el estado es PENDIENTE LIQUIDACION

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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;

  create view v_tabla_ganancias_detalle as
select d.*, 
    c.anio,
    c.descripcion,
    (anio||'-'||mes||'-01')::date as periodo
from tabla_ganancias c
join tabla_ganancias_detalle d ON c.id=d.id_cabecera;