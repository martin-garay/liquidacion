alter table conceptos add column remunerativo boolean not null default false;

/*

TRABAJADO A LA TARDE

*/
DROP TABLE tabla_ganancias;
CREATE TABLE public.tabla_ganancias
(
  id serial NOT NULL,
  anio integer NOT NULL,
  descripcion TEXT NOT NULL,
  CONSTRAINT pk_tabla_ganancias PRIMARY KEY (id)
);
CREATE TABLE public.tabla_ganancias_detalle
(
  id serial NOT NULL,
  mes integer not null,
  desde numeric(10,2) NOT NULL,
  hasta numeric(10,2),
  fijo numeric(10,2) NOT NULL,
  porcentaje numeric(10,2) NOT NULL,
  excedente numeric(10,2) NOT NULL,
  id_cabecera integer not null,
  CONSTRAINT pk_tabla_ganancias_detalle PRIMARY KEY (id),
  CONSTRAINT fk_tabla_ganancias_detalle__cabecera FOREIGN KEY (id_cabecera) REFERENCES tabla_ganancias(id)
);

--para ganancias
alter table personas add column cant_hijos integer not null default 0;

--para que no se carguen 2 planillas para el mismo año
ALTER TABLE public.tabla_ganancias ADD CONSTRAINT uk_tabla_ganancias UNIQUE(anio);