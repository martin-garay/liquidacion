create table conceptos_personas(
	id serial not null,
	id_concepto integer not null,
	id_persona integer not null,
	valor_fijo numeric(10,2),
	constraint pk_conceptos_personas primary key(id),
	constraint fk_conceptos_personas__conceptos foreign key (id_concepto) references conceptos(id),
	constraint fk_conceptos_personas__personas foreign key (id_persona) references personas(id),
	constraint uk_conceptos_personas unique(id_concepto,id_persona)
);

CREATE OR REPLACE VIEW public.v_conceptos AS 
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
    (('['::text || c.codigo) || '] '::text) || c.descripcion as descripcion_codigo
   FROM conceptos c
     JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;



/* TRABAJADO A LA TARDE */


CREATE OR REPLACE FUNCTION public.sp_trg_ai_recibos()
  RETURNS trigger AS
$BODY$
DECLARE    
    _id_estado integer;
    _estado character varying(60);
    c record;
BEGIN

    SELECT id_estado,estado INTO _id_estado,_estado FROM v_liquidaciones WHERE id=new.id_liquidacion;
    
    IF _id_estado=1 THEN    --si el estado es PENDIENTE LIQUIDACION

        /* Inserto los conceptos de la liquidacion.
        Si el concepto esta parametrizado para ciertas personas solo se cargan para esas personas */
        FOR c IN SELECT id_concepto, valor_fijo FROM liquidaciones_conceptos lc WHERE id_liquidacion = new.id_liquidacion 
        LOOP
            --Si el concepto esta parametrizado para ciertas personas, veo si esta esa persona, sino no se inserta el concepto
            --PERFORM count(1) ;
            IF exists(SELECT 1 FROM conceptos_personas WHERE id_concepto=c.id_concepto) THEN

                INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo)                
                SELECT id_concepto, (CASE WHEN c.valor_fijo is NULL THEN valor_fijo ELSE c.valor_fijo END), new.id 
                FROM conceptos_personas 
                WHERE id_concepto=c.id_concepto AND id_persona=NEW.id_persona;
            
            ELSE
            --el concepto es para todas los empleados
                INSERT INTO recibos_conceptos(id_concepto,importe,id_recibo)
                VALUES (c.id_concepto, c.valor_fijo, NEW.id);               

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


  --indica si se tiene en cuenta para el calculo de retenciones
    alter table conceptos add column retencion boolean not null default false;


CREATE OR REPLACE VIEW public.v_tipo_liquidacion_conceptos AS 
 SELECT tlc.id,
    tlc.id_concepto,
    tlc.id_tipo_liquidacion,
    (('['::text || c.codigo) || '] '::text) || c.descripcion AS concepto,
    tl.descripcion AS tipo_liquidacion,
    c.codigo,
    c.valor_fijo,
    c.id_tipo_concepto,
    tc.descripcion as tipo_concepto
   FROM tipo_liquidacion_conceptos tlc
     JOIN conceptos c ON c.id = tlc.id_concepto
     JOIN tipos_liquidaciones tl ON tl.id = tlc.id_tipo_liquidacion
     JOIN tipos_conceptos tc ON tc.id=c.id_tipo_concepto;



alter table tipos_contratos add column horas_mes numeric(10,2);
alter table personas add column horas_mes numeric(10,2);


DROP VIEW public.v_periodos_detalle;
alter table periodos_detalle add column inasistencias integer;
alter table periodos_detalle drop column inasistencias_injustificadas;
alter table periodos_detalle drop column inasistencias_justificadas;
CREATE OR REPLACE VIEW public.v_periodos_detalle AS 
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
FROM periodos_detalle pd
JOIN periodos p ON p.id = pd.id_periodo;

--agrego anio, mes y cambio tipos fecha_desde, fecha_hasta
DROP VIEW public.v_liquidaciones;
alter table liquidaciones alter column fecha_desde type date;
alter table liquidaciones alter column fecha_hasta type date;
alter table liquidaciones  add column mes integer;
alter table liquidaciones  add column anio integer;
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
    l.anio
FROM liquidaciones l
JOIN estados_liquidacion el ON el.id = l.id_estado
JOIN tipos_liquidaciones tl ON tl.id = l.id_tipo_liquidacion
JOIN establecimientos e ON e.id = l.id_establecimiento
LEFT JOIN bancos b ON b.id = l.id_banco;

 --renombro el campo valor a valor_fijo
DROP VIEW sistema.v_reservadas;
alter table sistema.reservadas RENAME column valor to valor_fijo;
CREATE OR REPLACE VIEW sistema.v_reservadas AS 
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
FROM sistema.reservadas r
LEFT JOIN sistema.tipos_reservadas tr ON tr.id = r.id_tipo_reservada
LEFT JOIN sistema.tipos_datos td ON td.id = r.id_tipo_dato;

--valores fijos para ciertos conceptos para la persona
create table personas_conceptos(
    id serial not null,
    id_concepto integer not null,
    valor_fijo numeric(10,2),
    id_persona integer not null,
    constraint pk_personas_conceptos primary key(id),
    constraint fk_personas_conceptos__conceptos foreign key(id_concepto) references conceptos(id),
    constraint fk_personas_conceptos__personas foreign key(id_persona) references personas(id),
    constraint uk_personas_conceptos UNIQUE(id_persona,id_concepto)
);


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
$BODY$
  LANGUAGE plpgsql VOLATILE
  COST 100;


  create table acumuladores(
    id serial not null,
    nombre character varying(60) not null,
    descripcion text not null,
    id_tipo_concepto integer not null,
    remunerativo boolean not null default false,
    valor_inicial numeric(10,2) not null default 0,
    constraint pk_acumuladores primary key(id),
    constraint fk_acumuladores__tipo_concepto foreign key(id_tipo_concepto) references tipos_conceptos(id)
);

create table recibos_acumuladores(
    id serial not null, 
    id_acumulador integer not null,
    importe numeric(10,2) not null, 
    id_recibo integer not null,
    constraint pk_recibos_acumuladores primary key(id),
    constraint fk_recibos_acumuladores__acumulador foreign key(id_acumulador) references acumuladores(id),
    constraint fk_recibos_acumuladores__recibo foreign key(id_recibo) references recibos(id),
    constraint uk_recibos_acumuladores UNIQUE(id_recibo,id_acumulador)
);

create view v_acumuladores as
select a.*, tc.descripcion as tipo_concepto
from acumuladores a
left join tipos_conceptos tc ON a.id_tipo_concepto=tc.id;