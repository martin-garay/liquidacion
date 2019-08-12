

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

