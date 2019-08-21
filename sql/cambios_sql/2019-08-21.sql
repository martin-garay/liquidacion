CREATE TABLE public.tabla_ganancias(
  id serial NOT NULL,
  minimo numeric(10,2) NOT NULL,
  maximo numeric(10,2),
  base numeric(10,2) NOT NULL,
  porcentaje numeric(10,2) NOT NULL,
  CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id)
);

create table tabla_vacaciones(
	id serial not null,
	desde numeric(10,2) not null,
	hasta numeric(10,2) not null,
	dias integer not null,	
	constraint pk_tabla_vacaciones primary key(id)
);

CREATE TABLE public.tabla_vacaciones_dias(
  id serial NOT NULL,
  desde integer NOT NULL,
  hasta integer NOT NULL,
  dias integer NOT NULL,
  CONSTRAINT pk_tabla_vacaciones_dias PRIMARY KEY (id)
);

alter table tabla_vacaciones_dias add column descripcion text;