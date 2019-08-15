/*-----------------------------------------------------
Trabajado el 2019-08-13 a la noche
------------------------------------------------------*/

create table liquidaciones_conceptos(
	id serial not null,
	id_concepto integer not null,
	id_liquidacion integer not null,
	valor_fijo numeric(10,2), --por si quiere cambiar el valor del concepto para esa liquidacion
	constraint pk_liquidaciones_conceptos primary key (id),
	constraint fk_liquidaciones_conceptos__conceptos foreign key(id_concepto) references conceptos(id),
	constraint fk_liquidaciones_conceptos__liquidaciones foreign key(id_liquidacion) references liquidaciones(id)
);

CREATE TABLE public.tipos_liquidaciones
(
  id serial NOT NULL,
  descripcion text NOT NULL,
  CONSTRAINT pk_liquidaciones PRIMARY KEY (id)
);

insert into tipos_liquidaciones(id,descripcion) VALUES(1,'Liquidación Mensual Normal');
insert into tipos_liquidaciones(id,descripcion) VALUES(2,'Vacaciones');
insert into tipos_liquidaciones(id,descripcion) VALUES(3,'1er Semestre SAC');
insert into tipos_liquidaciones(id,descripcion) VALUES(4,'2do Semestre SAC');
insert into tipos_liquidaciones(id,descripcion) VALUES(5,'Despido Con Causa');
insert into tipos_liquidaciones(id,descripcion) VALUES(6,'Despido sin Causa');


create table tipo_liquidacion_conceptos(
	id serial not null,
	id_concepto integer not null,
	id_tipo_liquidacion integer not null,
	constraint pk_tipo_liquidacion_conceptos primary key(id),
	constraint fk_tipo_liquidacion_conceptos__conceptos foreign key (id_concepto) references conceptos(id),
	constraint fk_tipo_liquidacion_conceptos__tipo foreign key (id_tipo_liquidacion) references tipos_liquidaciones(id),
	constraint uk_tipo_liquidacion_conceptos unique (id_concepto,id_tipo_liquidacion)
);

create view v_tipo_liquidacion_conceptos as 
SELECT tlc.*,'['||c.codigo||'] '||c.descripcion as concepto,tl.descripcion as tipo_liquidacion FROM tipo_liquidacion_conceptos tlc
INNER JOIN conceptos c ON c.id=tlc.id_concepto
INNER JOIN tipos_liquidaciones tl ON tl.id=tlc.id_tipo_liquidacion;

alter table recibos alter column nro_recibo DROP NOT NULL ; --se lo asigno despues de liquidar

alter table liquidaciones drop column id_localidad_pago;
alter table liquidaciones add column lugar_pago text;
alter table liquidaciones drop column tipo_liquidacion;
alter table liquidaciones alter column mes DROP NOT NULL; 

create view v_liquidaciones as 
select l.*, tl.descripcion as tipo_liquidacion,e.descripcion as establecimiento,b.descripcion as banco
from liquidaciones l
inner join tipos_liquidaciones tl ON tl.id=l.id_tipo_liquidacion
inner join establecimientos e ON e.id=l.id_establecimiento
left join bancos b ON b.id=l.id_banco;

alter table liquidaciones add column fecha_deposito date;

/* ---------------------------------------------------
		Tabajado a la mañana 
------------------------------------------------------*/
INSERT INTO tipo_liquidacion_conceptos ( id_concepto, id_tipo_liquidacion ) VALUES ('1', '1');

alter SCHEMA test RENAME TO sistema;

/* ------------------------------------------------------------------------ */
/* Cambio tipos_reservadas por sistema.tipos_reservadas */
/* ------------------------------------------------------------------------ */
--dropeo foreign key y columna
ALTER TABLE sistema.reservadas DROP CONSTRAINT fk_tipos_reservadas__reservadas;
alter table sistema.reservadas drop column id_tipo_reservada;

--creo la tabla en el esquema sistemas
drop table tipos_reservadas;
create table sistema.tipos_reservadas(
	id serial not null,
	descripcion text not null,
	constraint pk_tipos_reservadas primary key (id)
);

--agrego la columna apuntando a la tabla de tipos en el esquema sistema
alter table sistema.reservadas add column id_tipo_reservada integer;
--agrego la clave foranea
ALTER TABLE sistema.reservadas
  ADD CONSTRAINT fk_tipos_reservadas__reservadas FOREIGN KEY (id_tipo_reservada)
      REFERENCES sistema.tipos_reservadas (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION;

insert into sistema.tipos_reservadas(id,descripcion) values(1,'LIQUIDACION');
insert into sistema.tipos_reservadas(id,descripcion) values(2,'PERSONA');

update sistema.reservadas set id_tipo_reservada =1;
alter table sistema.reservadas alter column id_tipo_reservada SET NOT NULL;
/* ------------------------------------------------------------------------ */
/* ------------------------------------------------------------------------ */



/* ------------------------------------------------------------------------ */
/* Agrego el tipo de dato de la palabra reservada 		*/
/* ------------------------------------------------------------------------ */
alter table sistema.reservadas add column id_tipo_dato integer;

create table sistema.tipos_datos(
	id serial not null,
	descripcion text not null,
	constraint pk_tipos_datos primary key(id)
);
insert into sistema.tipos_datos(id,descripcion) values(1,'INTEGER');
insert into sistema.tipos_datos(id,descripcion) values(2,'BOOLEAN');
insert into sistema.tipos_datos(id,descripcion) values(3,'TEXT');
insert into sistema.tipos_datos(id,descripcion) values(4,'NUMERIC');
alter table sistema.reservadas add constraint fk_reservadas__tipos_datos foreign key (id_tipo_dato) references sistema.tipos_datos(id);
/* ------------------------------------------------------------------------ */
/* ------------------------------------------------------------------------ */

create view sistema.v_reservadas as 
select r.*,tr.descripcion as tipo_reservada,td.descripcion as tipo_dato 
from sistema.reservadas r
left join sistema.tipos_reservadas tr ON tr.id=r.id_tipo_reservada
left join sistema.tipos_datos td ON td.id=r.id_tipo_dato;

--cambio la secuencia
SELECT pg_catalog.setval('public.tipos_conceptos_id_seq', 4, false);

INSERT INTO sistema.reservadas ( id, nombre, descripcion, descripcion_larga, query, valor, id_tipo_reservada ) 
 VALUES (5,'TIEMPOCOMP', 'Trabaja a tiempo completo', 'Devuelve verdadero si el trabajador tiene contrato a tiempo completo', 'SELECT (id_tipo_contrato=1) as resultado FROM datos_laborales WHERE id_persona={ID_PERSONA}', DEFAULT, '1');

INSERT INTO sistema.reservadas ( id, nombre, descripcion, descripcion_larga, query, valor, id_tipo_reservada ) 
 VALUES (6,'TIEMPOPARC', 'Trabaja a tiempo parcial', 'Devuelve verdadero si el trabajador tiene contrato a tiempo parcial', 'SELECT (id_tipo_contrato<>1) as resultado FROM datos_laborales WHERE id_persona={ID_PERSONA}', DEFAULT, '1');
