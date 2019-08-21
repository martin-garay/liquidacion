alter table fichajes_resumen add column periodo date;


/* Ver si lo voy a armar asi */
/* Guarda las descripciones del recibo una vez que se liquida */
create table recibos_descripcion(
	id serial not null,
	id_persona integer not null,
	nombre character varying(100),
	apellido character varying(100),
	legajo integer,
	cuil character varying(15),
	sueldo_basico numeric(10,2),
	id_categoria integer,
	categoria text,
	id_tipo_documento integer,
	tipo_documento text,
	nro_documento character varying(15),
	fecha_ingreso date,
	fecha_egreso date,
	id_obra_social integer,
	obra_social text,
	codigo_obra_social text,
	domicilio text,
	piso character(2),
	departamento character(10),
	id_localidad integer,
	localidad character varying(60),
	tarea text,
	id_tipo_contrato integer,
	tipo_contrato text,
	id_recibo integer not null,
	constraint pk_recibos_descripcion primary key (id),
	constraint fk_recibos_descripcion foreign key(id_recibo) references recibos(id),
	constraint uk_recibos_descripcion unique(id_recibo)
);
create table liquidaciones_descripcion(
	id serial not null,
	id_liquidacion integer not null,
	tipo_liquidacion text,	
	establecimiento text,
	direccion text,
	localidad text,
	cuit text,
	actividad text,
	id_tipo_empleador integer,
	tipo_empleador text,
	banco text,
	constraint pk_liquidaciones_descripcion primary key(id),
	constraint fk_liquidaciones_descripcion foreign key(id_liquidacion) references liquidaciones(id),
	constraint uk_liquidaciones_descripcion unique(id_liquidacion)	
);