--agrego estado a la liquidacion

create table estados_liquidacion(
	id serial not null,
	descripcion character varying(60),
	constraint pk_estados_liquidacion primary key(id),
	constraint uk_estados_liquidacion unique(descripcion)
);

insert into estados_liquidacion(id,descripcion) values(1,'PENDIENTE LIQUIDACION');
insert into estados_liquidacion(id,descripcion) values(2,'LIQUIDADA');

alter table liquidaciones add column id_estado integer not null default 1;
alter table liquidaciones add constraint fk_liquidacion__estado foreign key(id_estado) references estados_liquidacion(id);

drop view v_liquidaciones;
CREATE OR REPLACE VIEW public.v_liquidaciones AS 
 SELECT l.id,
	l.id_estado,
	el.descripcion as estado,
    l.descripcion,
    l.periodo,
    l.fecha_desde,
    l.fecha_hasta,
    l.id_tipo_liquidacion,
    l.id_establecimiento,
    l.id_banco,
    l.fecha_pago,
    l.periodo_depositado AS mes,
    l.lugar_pago,
    tl.descripcion AS tipo_liquidacion,
    e.descripcion AS establecimiento,
    b.descripcion AS banco
FROM liquidaciones l
JOIN estados_liquidacion el ON el.id=l.id_estado
JOIN tipos_liquidaciones tl ON tl.id = l.id_tipo_liquidacion
JOIN establecimientos e ON e.id = l.id_establecimiento
LEFT JOIN bancos b ON b.id = l.id_banco;

alter table recibos_conceptos add column id_recibo integer not null;
alter table recibos_conceptos add constraint fk_recibos_conceptos__recibo foreign key (id_recibo) references recibos(id);
