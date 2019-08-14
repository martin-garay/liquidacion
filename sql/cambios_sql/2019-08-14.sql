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

