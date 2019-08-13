create table bancos(
	id serial not null,
	descripcion text not null,
	constraint pk_bancos primary key (id)
);

create table tipos_liquidaciones(
	id serial not null,
	descripcion text not null,
	constraint pk_liquidaciones primary key (id)
);

create table liquidaciones (
	id serial not null,
	descripcion text not null,	
	periodo date not null,
	fecha_desde timestamp without time zone,
	fecha_hasta timestamp without time zone,
	id_tipo_liquidacion integer not null,
	id_establecimiento integer not null default 1,
	id_banco integer not null,	
	id_localidad_pago integer not null, --lugar de pago
	tipo_liquidacion text not null,
	fecha_pago date not null,
	mes character varying(10) not null,	
	constraint pk_liquidaciones2 primary key (id),
	constraint fk_liquidaciones__bancos foreign key (id_banco) references bancos(id),
	constraint fk_liquidaciones__tipos foreign key(id_tipo_liquidacion) references tipos_liquidaciones(id),
	constraint fk_liquidaciones__localidades foreign key(id_localidad_pago) references localidades(id)	
);

create table recibos(
	id serial not null,
	nro_recibo integer not null,
	id_persona integer not null,		
	total_remunerativos numeric(10,2),
	total_no_remunerativos numeric(10,2),
	total_deducciones numeric(10,2),
	total_neto numeric(10,2),
	total_basico numeric(10,2),
	id_liquidacion integer not null,
	constraint pk_recibos primary key (id),
	constraint fk_recibos__personas foreign key(id_persona) references personas(id),
	constraint fk_recibos__liquidaciones foreign key(id_liquidacion) references liquidaciones(id)		
);

create table recibos_conceptos(
	id serial not null,
	id_concepto integer not null,		
	importe numeric(10,2) not null,	
	constraint pk_recibos_conceptos primary key (id),
	constraint fk_recibos_conceptos__conceptos foreign key(id_concepto) references conceptos(id)		
);
