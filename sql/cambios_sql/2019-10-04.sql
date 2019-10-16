create table historico_sueldo_basico(
	id serial not null,
	mes integer not null,
	anio integer not null,
	fecha timestamp without time zone not null default now(),
	constraint pk_historico_sueldo_basico primary key(id)
);

create table historico_sueldo_basico_detalle(
	id serial not null,
	id_persona integer not null,
	basico numeric(10,2) not null,
	id_cabecera integer not null,
	constraint pk_historico_sueldo_basico_detalle primary key(id),
	constraint fk_historico_sueldo_basico_detalle__cabecera foreign key(id_cabecera) references historico_sueldo_basico(id)
);

alter table historico_sueldo_basico add column descripcion character varying(255);