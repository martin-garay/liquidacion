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
    l.periodo,
    l.descripcion AS liquidacion_descripcion,
    l.id_estado as id_estado_liquidacion
FROM recibos_conceptos rc
JOIN recibos r ON r.id = rc.id_recibo
JOIN conceptos c ON c.id = rc.id_concepto
JOIN liquidaciones l ON l.id = r.id_liquidacion;

--cambio la reservada ganancia_acumulada para que sume solo sobre las liquidaciones cerradas
UPDATE sistema.reservadas
SET query = 
'select sum(importe) as resultado 
from v_recibos_conceptos 
where id_persona={ID_PERSONA} and codigo=''515''
and id_estado_liquidacion=3 /*CERRADA*/
and anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION});'
WHERE id = '19';

--cambio la reservada ganancia_neta_acumulada para que sume solo sobre las liquidaciones cerradas
UPDATE sistema.reservadas
SET query = 
'select sum(importe) as resultado 
from v_recibos_conceptos 
where id_persona={ID_PERSONA} and codigo=''321''
and id_estado_liquidacion=3 /*CERRADA*/
and anio=(SELECT anio FROM liquidaciones WHERE id={ID_LIQUIDACION});'
WHERE id = '18';

--agrego los totales de la liquidacion
alter table liquidaciones add column total_remunerativos numeric(10,2) default 0.00;
alter table liquidaciones add column total_no_remunerativos numeric(10,2) default 0.00;
alter table liquidaciones add column total_deducciones numeric(10,2) default 0.00;
alter table liquidaciones add column total_neto numeric(10,2) default 0.00;

alter table historico_liquidaciones add column total_remunerativos numeric(10,2) not null default 0.00;
alter table historico_liquidaciones add column total_no_remunerativos numeric(10,2) not null default 0.00;
alter table historico_liquidaciones add column total_deducciones numeric(10,2) not null default 0.00;
alter table historico_liquidaciones add column total_neto numeric(10,2) not null default 0.00;



CREATE OR REPLACE FUNCTION public.sp_volver_a_estado_inicial(_id_liquidacion integer)
  RETURNS void AS
$BODY$
declare 
    _id_estado integer;
begin 
    select id_estado into _id_estado from liquidaciones where id=_id_liquidacion;
    IF _id_estado=2 THEN

        update liquidaciones 
        set id_estado=1, total_remunerativos=0.00, total_no_remunerativos=0.00, total_deducciones=0.00,total_neto=0.00
        where id=_id_liquidacion;

        update recibos set total_remunerativos=null,total_no_remunerativos=null,total_deducciones=null,total_neto=null,json_variables=null
        where id_liquidacion=_id_liquidacion;

        update recibos_conceptos set importe=null where id_recibo in (select id from recibos where id_liquidacion=_id_liquidacion);

        delete from recibos_acumuladores where id_recibo in (select id from recibos where id_liquidacion=_id_liquidacion);
    
    END IF;
END;
$BODY$
LANGUAGE plpgsql VOLATILE
COST 100;

CREATE OR REPLACE VIEW public.v_liquidaciones AS 
 SELECT l.id,
    l.id_estado,
    el.descripcion AS estado,
    l.descripcion,
    l.periodo,
    (date_part('year'::text, l.periodo) || '-'::text) || date_part('month'::text, l.periodo) AS periodo_descripcion,
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
    l.mes_carga_social,
    l.total_remunerativos,l.total_no_remunerativos,l.total_deducciones,l.total_neto
   FROM liquidaciones l
     JOIN estados_liquidacion el ON el.id = l.id_estado
     JOIN tipos_liquidaciones tl ON tl.id = l.id_tipo_liquidacion
     JOIN v_establecimientos e ON e.id = l.id_establecimiento
     LEFT JOIN bancos b ON b.id = l.id_banco;


CREATE OR REPLACE FUNCTION public.sp_grabar_historico_liquidacion(_id_liquidacion integer)
  RETURNS void AS
$BODY$
begin 
    --historico_liquidaciones
    INSERT INTO public.historico_liquidaciones(id, descripcion, periodo, fecha_desde, fecha_hasta, id_tipo_liquidacion, id_establecimiento, id_banco, fecha_pago, 
    periodo_depositado, lugar_pago, fecha_deposito, id_estado, mes, anio, nro_recibo_inicial, banco, estado, tipo_liquidacion, 
    establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad,
    id_tipo_empleador,tipo_empleador,fecha_carga_social,mes_carga_social,total_remunerativos,total_no_remunerativos,total_deducciones,total_neto)
    select id,descripcion,periodo,fecha_desde,fecha_hasta,id_tipo_liquidacion,id_establecimiento,id_banco,fecha_pago,
    periodo_depositado,lugar_pago,fecha_deposito,id_estado,mes,anio,nro_recibo_inicial,banco, estado, tipo_liquidacion,
    establecimiento, direccion_establecimiento, localidad_establecimiento, cp_establecimiento, provincia_establecimiento,cuit,actividad,
    id_tipo_empleador,tipo_empleador,fecha_carga_social,mes_carga_social,
    total_remunerativos,total_no_remunerativos,total_deducciones,total_neto
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
    rc.mostrar_en_recibo,c.mostrar_si_cero,totaliza,valor_fijo,remunerativo,retencion
    from recibos_conceptos rc 
    join v_conceptos c ON c.id=rc.id_concepto
    WHERE id_recibo IN (SELECT id FROM recibos WHERE id_liquidacion=_id_liquidacion);
END;
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


/* --------------------------------------------------------------------------------------
para 30 dias de vacaciones debo ocultar todos los conceptos y dejar solo el de vacaciones 
-------------------------------------------------------------------------------------- */
alter table recibos_conceptos add column mostrar_en_recibo boolean;

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

                INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo,mostrar_en_recibo)              
                SELECT id_concepto, (CASE WHEN c.valor_fijo is NULL THEN valor_fijo ELSE c.valor_fijo END), new.id, c.mostrar_en_recibo 
                FROM conceptos_personas 
                WHERE id_concepto=c.id_concepto AND id_persona=NEW.id_persona;
            
            ELSE
            --el concepto es para todas los empleados
                --si el concepto tiene un valor fijo definido en la Persona
                SELECT valor_fijo INTO _valor_fijo FROM personas_conceptos WHERE id_persona=new.id_persona AND id_concepto=c.id_concepto;
                IF(FOUND)THEN
                    INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo,mostrar_en_recibo)
                    VALUES (c.id_concepto, _valor_fijo, NEW.id, c.mostrar_en_recibo);
                ELSE
                    INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo,mostrar_en_recibo)
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

CREATE OR REPLACE VIEW public.v_recibos_conceptos AS 
SELECT rc.id,
    rc.id_concepto,
    rc.importe,
    rc.id_recibo,
    c.descripcion AS concepto,
    c.codigo,
    'c'::text || c.codigo AS nombre_variable,
    c.formula,
    rc.mostrar_en_recibo,
    c.totaliza,
    c.id_tipo_concepto,
    r.nro_recibo,
    r.id_persona,
    r.id_liquidacion,
    l.mes,
    l.anio,
    l.periodo,
    l.descripcion AS liquidacion_descripcion,
    l.id_estado AS id_estado_liquidacion
FROM recibos_conceptos rc
JOIN recibos r ON r.id = rc.id_recibo
JOIN conceptos c ON c.id = rc.id_concepto
JOIN liquidaciones l ON l.id = r.id_liquidacion;
