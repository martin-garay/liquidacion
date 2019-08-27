create table tabla(
	id serial not null,
	clave character varying(60) not null,
	descripcion text not null,
	constraint pk_tabla primary key(id)
);

create table tabla_detalle(
	id serial not null,
	anio integer not null,
	mes integer not null,
	periodo date not null,
	valor numeric(10,2) not null,
	tope numeric(10,2) not null,	
	id_tabla integer not null,
	constraint pk_tabla_detalle primary key(id),
	constraint fk_tabla_detalle__tabla foreign key(id_tabla) references tabla(id)
);

create table tabla_personas(
	id serial not null,
	anio integer not null,
	mes integer not null,
	periodo date not null,
	valor numeric(10,2) not null,	--valor que informa la persona
	id_persona integer not null,
	id_tabla integer not null,		
	constraint pk_tabla_personas primary key(id),
	constraint fk_tabla_personas__personas foreign key(id_persona) references personas(id),
	constraint fk_tabla_personas__tabla foreign key(id_tabla) references tabla(id)
);

create view v_tabla_detalle as 
select td.*,t.descripcion as tabla,t.clave
from tabla_detalle td 
join tabla t ON t.id=td.id_tabla;

CREATE OR REPLACE VIEW public.v_tabla_personas AS 
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
    p.legajo||' '||p.apellido||' '||p.nombre as persona_descripcion,
    tp.anio||'-'||tp.mes as periodo_descripcion
FROM tabla_personas tp
JOIN tabla t ON t.id = tp.id_tabla
JOIN personas p ON p.id = tp.id_persona;

ALTER TABLE public.tabla_detalle ADD CONSTRAINT uk_tabla_detalle UNIQUE(id_tabla, anio, mes);
ALTER TABLE public.tabla_personas ADD CONSTRAINT uk_tabla_personas UNIQUE(id_tabla, anio, mes);
ALTER TABLE public.tabla ADD CONSTRAINT uk_tabla UNIQUE(clave);

