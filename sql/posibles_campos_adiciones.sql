

alter table personas add column fecha_egreso date; --para calcular el proporcional en caso de renuncia.

/* Tabla conceptos */
alter table conceptos add column valor_fijo numeric(10,2);
alter table conceptos add column porcentaje numeric(10,2);
alter table conceptos add column activo boolean not null default true;
alter table conceptos add column imprime_recibo boolean not null default false; --si se imprime en recibo
alter table conceptos add column imprime_recibo_cera boolean not null default false; --si se imprime en recibo si el valor es cero
alter table conceptos add column vigente_desde timestamp without time zone;
alter table conceptos add column vigente_hasta timestamp without time zone;
/*Se  prorratea  si  es  un  importe  fijo?. Hay  algunos  conceptos  que  deben  ser  incorporados  en la liquidación  del  SAC  y  son  importes  fijos,  estos  conceptos  deberán  ser  prorrateados  en  el  SAC  (por ejemplo al 50%). Si incluye un concepto con importe fijo para su liquidación en el SAC no olvide de tildar esta opción para que el sistema prorratee el importe.*/



/* Tipos de Liquidaciones 
	Los conceptos van a estar asociados a varias de estas para saber si aplica o no
*/
create table tipos_liquidaciones(
	id serial not null,
	descripcion text not null,
	constraint pk_tipos_liquidaciones primary key(id)
);
insert into tipos_liquidaciones('descripcion') values ('1ra Quincena');
insert into tipos_liquidaciones('descripcion') values ('2da Quincena');
insert into tipos_liquidaciones('descripcion') values ('Vacaciones');
insert into tipos_liquidaciones('descripcion') values ('1er Semestre SAC');
insert into tipos_liquidaciones('descripcion') values ('2do Semestre SAC');
insert into tipos_liquidaciones('descripcion') values ('Liquidacion Mensual Normal');
insert into tipos_liquidaciones('descripcion') values ('Pagos Extraordinarios');
insert into tipos_liquidaciones('descripcion') values ('Renuncia');
insert into tipos_liquidaciones('descripcion') values ('Despido Sin Causa');
insert into tipos_liquidaciones('descripcion') values ('Despido Con Causa');




--con palabra reservada feriados() esta función devuelve la cantidad de feriados que existen en el mes basándose en lo ingresado  en  esta  pantalla.  Esta  función  puede  ser  muy  útil  para  calcular  los  dias  feriados  a  abonar  a los empleados que trabajen siempre los dias feriados.  
create table feriados(
	id serial not null,
	fecha date not null,
	descripcion text not null,
	constraint pk_feriados primary key(id)
);

create table test.reservadas(
	id serial not null,
	nombre text not null,
	descripcion text not null,
	descripcion_larga text,	
	query text,
	valor text,
	constraint pk_reservadas primary key(id)
);
insert into test.reservadas(id,nombre,descripcion,descripcion_larga,query)
values(1,'BASICO','Sueldo Basico','Trae el sueldo basico de la categoria correspondiente del empleado',
'SELECT sueldo_basico FROM categorias WHERE id=(SELECT id_categoria FROM datos_laborales WHERE id_persona={ID_PERSONA})');

insert into test.reservadas(id,nombre,descripcion,descripcion_larga,query)
values(2,'ANTIGUEDAD','ANTIGUEDAD','Trae la antiguedad en años del empleado',
'SELECT edad(fecha_ingreso) FROM datos_laborales WHERE id_persona={ID_PERSONA}');




--horarios de trabajo real
create table fichajes(
	id serial not null,
	fecha date not null,
	hora_entrada timestamp without time zone,
	hora_salida timestamp without time zone,
	horas_trabajadas numeric(10,2),
	horas_extras numeric(10,2),
	id_persona integer not null,
	constraint pk_fichajes primary key (id),
	constraint fk_fichajes__personas foreign key(id_persona) references personas(id)
);


--horarios de trabajo normales
create table personas_jornadas(
	id serial not null,
	hora_desde time not null,
	hora_hasta time not null,
	id_persona integer not null,
	constraint pk_personas_jornadas primary key(id),
	constraint fk_personas_jornadas__personas foreign key(id_persona) references personas(id)
);




/*-----------------------------------------------------------------------------------*/
create table bancos(
	id serial not null,
	descripcion not null,
	constraint pk_bancos primary key (id)
);

create table tipos_liquidaciones(
	id serial not null,
	descripcion not null,
	constraint pk_liquidaciones primary key (id)
);

create table liquidaciones (
	id serial not null,
	descripcion not null,	
	periodo date not null,
	fecha_desde timestamp without time zone,
	fecha_desde timestamp without time zone,
	id_tipo_liquidacion integer not null,
	id_establecimiento integer not null default 1,
	id_banco integer not null,	
	id_localidad_pago integer not null, --lugar de pago
	tipo_liquidacion text not null,
	establecimiento text not null,
	direccion_establecimiento text not null,
	cuit_establecimiento text not null,
	actividad_establecimiento not null,	
	banco text not null,	
	localidad_pago text not null,
	fecha_pago date not null,
	mes caracter varying(10) not null,	
	constraint pk_liquidaciones primary key (id),
	constraint fk_liquidaciones__bancos foreign key (id_banco) references bancos(id)
	constraint fk_liquidaciones__tipos foreign key(id_tipo_liquidacion) references tipos_liquidaciones(id),
	constraint fk_liquidaciones__localidades foreign key(id_localidad_pago) references localidades(id)	
);

create table recibos(
	id serial not null,
	nro_recibo integer not null,
	legajo integer not null,
	nombre text not null,
	apellido text not null,
	cuil text not null,	
	domicilio text not null,
	fecha_ingreso date not null,
	categoria text not null,
	tarea text not null,
	obra_social text not null,	
	neto_palabras text not null,
	tipo_contratacion text not null,
	id_persona integer not null,		
	total_remunerativos numeric(10,2) not null,
	total_no_remunerativos numeric(10,2) not null,
	total_deducciones numeric(10,2) not null,
	total_neto numeric(10,2) not null,
	total_basico numeric(10,2) not null,
	constraint pk_recibos primary key (id),
	constraint fk_recibos__personas foreign key(id_persona) references personas(id),	
);

create table recibos_conceptos(
	id serial not null,
	id_concepto integer not null,
	id_tipo_concepto integer not null,
	codigo_concepto text not null,
	concepto text not null,
	tipo_concepto text not null,	
	importe numeric(10,2) not null,
	mostrar_recibo boolean,
	constraint pk_recibos_conceptos primary key (id),
);

/* temporales */

create table liquidaciones_temp (
	id serial not null,
	descripcion not null,	
	periodo date not null,
	fecha_desde timestamp without time zone,
	fecha_desde timestamp without time zone,
	id_tipo_liquidacion integer not null,
	id_establecimiento integer not null default 1,
	id_banco integer not null,	
	id_localidad_pago integer not null, --lugar de pago	
	fecha_pago date not null,
	mes caracter varying(10) not null,	
	constraint pk_liquidaciones_temp primary key (id),
	constraint fk_liquidaciones_temp__bancos foreign key (id_banco) references bancos(id)
	constraint fk_liquidaciones_temp__tipos foreign key(id_tipo_liquidacion) references tipos_liquidaciones(id),
	constraint fk_liquidaciones_temp__localidades foreign key(id_localidad_pago) references localidades(id)	
);

create table recibos_temp(
	id serial not null,
	nro_recibo integer not null,

	tarea text not null,
	obra_social text not null,	
	neto_palabras text not null,
	tipo_contratacion text not null,
	id_persona integer not null,		
	total_remunerativos numeric(10,2) not null,
	total_no_remunerativos numeric(10,2) not null,
	total_deducciones numeric(10,2) not null,
	total_neto numeric(10,2) not null,
	total_basico numeric(10,2) not null,
	constraint pk_recibos_temp primary key (id),
	constraint fk_recibos_temp__personas foreign key(id_persona) references personas(id),	
);

create table recibos_conceptos_temp(
	id serial not null,
	id_concepto integer not null,
	id_tipo_concepto integer not null,
	codigo_concepto text not null,
	concepto text not null,
	tipo_concepto text not null,	
	importe numeric(10,2) not null,
	mostrar_recibo boolean,
	constraint pk_recibos_conceptos_temp primary key (id),
);

