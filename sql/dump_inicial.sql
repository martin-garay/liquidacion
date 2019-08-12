CREATE TABLE public.tipos_conceptos
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_tipos_conceptos PRIMARY KEY (id)
)
WITH (
  OIDS=FALSE
);

CREATE TABLE public.conceptos
(
  id serial not null,
  descripcion text NOT NULL,
  codigo text NOT NULL,
  id_tipo_concepto integer NOT NULL,  
  CONSTRAINT pk_conceptos PRIMARY KEY (id),
  CONSTRAINT conceptos_id_tipo_concepto_foreign FOREIGN KEY (id_tipo_concepto)
      REFERENCES public.tipos_conceptos (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.tipos_contratos
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT tipos_contratos_pkey PRIMARY KEY (id)
);

CREATE TABLE public.regimenes
(
  id serial not null,
  descripcion text NOT NULL,
  CONSTRAINT pk_regimenes PRIMARY KEY (id)
);

CREATE TABLE public.obras_sociales
(
  id serial not null,
  codigo text NOT NULL,
  descripcion text NOT NULL,  
  CONSTRAINT pk_obras_sociales PRIMARY KEY (id)
);

CREATE TABLE public.estados_civiles
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_estados_civiles PRIMARY KEY (id)
);

CREATE TABLE public.tipos_documentos
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_tipos_documentos PRIMARY KEY (id)
);

CREATE TABLE public.generos
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_generos PRIMARY KEY (id)
);

CREATE TABLE public.nacionalidades
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_nacionalidades PRIMARY KEY (id)
);

CREATE TABLE public.categorias
(
  id serial not null,
  descripcion text NOT NULL,
  sueldo_basico numeric(10,2),
  valor_hora numeric(10,2),  
  CONSTRAINT pk_categorias PRIMARY KEY (id)
);

CREATE TABLE public.tareas
(
  id serial not null,
  descripcion text NOT NULL,  
  CONSTRAINT pk_tareas PRIMARY KEY (id)
);

CREATE TABLE public.establecimientos
(
  id serial not null,
  descripcion text NOT NULL,
  direccion text NOT NULL,
  id_localidad integer NOT NULL,  
  CONSTRAINT pk_establecimientos PRIMARY KEY (id),
  CONSTRAINT establecimientos_id_localidad_foreign FOREIGN KEY (id_localidad)
      REFERENCES public.localidades (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.personas
(
  id serial not null,
  nombre character varying(100) NOT NULL,
  apellido character varying(100) NOT NULL,
  fecha_nacimiento date,
  id_tipo_documento integer not null,
  nro_documento character varying(15),
  id_genero integer NOT NULL,
  id_nacionalidad integer NOT NULL,
  CONSTRAINT pk_personas PRIMARY KEY (id),
  CONSTRAINT uk_personas_dni UNIQUE (id_tipo_documento,nro_documento),
  CONSTRAINT fk_personas__generos FOREIGN KEY (id_genero)
      REFERENCES public.generos (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_persona__nacionalidades FOREIGN KEY (id_nacionalidad)
      REFERENCES public.nacionalidades (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.datos_actuales
(
  id serial NOT NULL,
    domicilio text NOT NULL,  
    id_localidad integer,
    telefono_particular character varying(30),
    telefono_celular character varying(30),  
    email character varying(100),  
    id_estado_civil integer not null,
  id_persona integer NOT NULL,
  CONSTRAINT pk_datos_actuales PRIMARY KEY (id),
  CONSTRAINT fk_datos_actuales__peresona FOREIGN KEY (id_persona)
      REFERENCES public.personas (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_datos_actuales_localidades FOREIGN KEY (id_localidad)
      REFERENCES public.localidades (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_datos_actuales__estado_civil FOREIGN KEY (id_estado_civil)
      REFERENCES public.estados_civiles (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.datos_laborales
(
  id serial not null,
  id_categoria integer,
  id_establecimiento integer,  
  email_laboral character varying(255),
  id_persona integer NOT NULL,  
  CONSTRAINT pk_datos_laborales PRIMARY KEY (id),
  CONSTRAINT fk_datos_laborales__personas FOREIGN KEY (id_persona)
      REFERENCES public.personas (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_datos_laborales__establecimiento FOREIGN KEY (id_establecimiento)
      REFERENCES public.establecimientos (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_datos_laborales__categorias FOREIGN KEY (id_categoria)
      REFERENCES public.categorias (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.datos_salud
(
  id serial NOT NULL,
  id_obra_social integer,
  observaciones_medicas character varying(255),
  id_persona integer NOT NULL,
  CONSTRAINT pk_datos_salud PRIMARY KEY (id),
  CONSTRAINT fk_datos_salud__personas FOREIGN KEY (id_persona)
      REFERENCES public.personas (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION,
  CONSTRAINT fk_datos_salud__obra_social FOREIGN KEY (id_obra_social)
      REFERENCES public.obras_sociales (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);

CREATE TABLE public.persona_tareas
(
  id serial not null,
  id_persona integer NOT NULL,
  id_tarea integer NOT NULL,  
  CONSTRAINT pk_persona_tareas PRIMARY KEY (id),
  CONSTRAINT persona_tareas_id_persona_id_tarea_unique UNIQUE (id_persona, id_tarea),
  CONSTRAINT fk_personas_tareas__personas FOREIGN KEY (id_persona)
      REFERENCES public.personas (id) MATCH SIMPLE
      ON UPDATE NO ACTION ON DELETE NO ACTION
);


/* Datos */ 


INSERT INTO public.categorias VALUES (1, '1RA.SUPERV', NULL, NULL);
INSERT INTO public.categorias VALUES (2, '2DA.SUPERV', NULL, NULL);
INSERT INTO public.categorias VALUES (3, '1RA.ADM', NULL, NULL);
INSERT INTO public.categorias VALUES (4, '2DA.ADM', NULL, NULL);
INSERT INTO public.categorias VALUES (5, 'Maestranza', NULL, NULL);
SELECT pg_catalog.setval('public.categorias_id_seq', 1, false);

INSERT INTO public.establecimientos VALUES (1, 'Asociación Médica de Luján', 'Mariano Moreno 1460', 1);
SELECT pg_catalog.setval('public.establecimientos_id_seq', 1, false);

INSERT INTO public.estados_civiles VALUES (1, 'Soltero/a');
INSERT INTO public.estados_civiles VALUES (2, 'Casado/a');
INSERT INTO public.estados_civiles VALUES (3, 'Divorciado/a');
SELECT pg_catalog.setval('public.estados_civiles_id_seq', 1, false);

INSERT INTO public.generos VALUES (1, 'Masculino');
INSERT INTO public.generos VALUES (2, 'Femenino');
SELECT pg_catalog.setval('public.generos_id_seq', 1, false);

INSERT INTO public.nacionalidades VALUES (1, 'Argentino');
SELECT pg_catalog.setval('public.nacionalidades_id_seq', 1, false);

INSERT INTO public.obras_sociales VALUES (1, '406', 'swiss medical');
INSERT INTO public.obras_sociales VALUES (2, '106005', 'utedyc');
INSERT INTO public.obras_sociales VALUES (3, '123305', 'medife');
INSERT INTO public.obras_sociales VALUES (4, '125707', 'union personal');
INSERT INTO public.obras_sociales VALUES (5, '113809', 'osde');
INSERT INTO public.obras_sociales VALUES (6, '106005', 'ospedyc');
INSERT INTO public.obras_sociales VALUES (7, '104306', 'galeno');
INSERT INTO public.obras_sociales VALUES (8, '3801', 'osde inmigrantes españoles');
SELECT pg_catalog.setval('public.obras_sociales_id_seq', 1, false);

INSERT INTO public.regimenes VALUES (1, 'Reparto');
INSERT INTO public.regimenes VALUES (2, 'Sipa');
INSERT INTO public.regimenes VALUES (3, 'Capitalización');
SELECT pg_catalog.setval('public.regimenes_id_seq', 1, false);

INSERT INTO public.tareas VALUES (1, 'ay.sub area');
INSERT INTO public.tareas VALUES (2, 'facturacion');
INSERT INTO public.tareas VALUES (3, 'convenios');
INSERT INTO public.tareas VALUES (4, 'maestr.y serv.');
INSERT INTO public.tareas VALUES (5, 'ioma');
INSERT INTO public.tareas VALUES (6, 'Encargada');
INSERT INTO public.tareas VALUES (7, 'sub area ioma');
INSERT INTO public.tareas VALUES (8, 'fact.ioma');
INSERT INTO public.tareas VALUES (9, 'Area Contable');
INSERT INTO public.tareas VALUES (10, 'Secretaria');
INSERT INTO public.tareas VALUES (11, 'Responsable');
INSERT INTO public.tareas VALUES (12, 'Ad./Jefa de Personal');
SELECT pg_catalog.setval('public.tareas_id_seq', 1, false);

INSERT INTO public.tipos_conceptos VALUES (1, 'HABERES');
INSERT INTO public.tipos_conceptos VALUES (2, 'DEDUCCIONES');
INSERT INTO public.tipos_conceptos VALUES (3, 'ASIGNACIONES F.');
SELECT pg_catalog.setval('public.tipos_conceptos_id_seq', 1, false);

INSERT INTO public.tipos_contratos VALUES (1, 'a tiempo comp.');
INSERT INTO public.tipos_contratos VALUES (2, 'a tiempo parcial');
SELECT pg_catalog.setval('public.tipos_contratos_id_seq', 1, false);

INSERT INTO public.tipos_documentos VALUES (1, 'DNI');
INSERT INTO public.tipos_documentos VALUES (2, 'CI');
INSERT INTO public.tipos_documentos VALUES (3, 'LE');
INSERT INTO public.tipos_documentos VALUES (4, 'LC');
SELECT pg_catalog.setval('public.tipos_documentos_id_seq', 1, false);



/* Vistas */
create view v_localidades as
select l.*,p.nombre as provincia,p.id_pais,pa.nombre as pais from localidades l
inner join provincias p ON p.id=l.id_provincia
inner join paises pa ON pa.id=p.id_pais;

create view v_establecimientos as
select e.*, l.nombre as localidad,cp,id_provincia,provincia,id_pais
from establecimientos e
inner join v_localidades l ON e.id_localidad=l.id

alter table datos_laborales add column legajo integer not null;

alter table datos_laborales add id_tipo_contrato integer not null;
alter table datos_laborales add CONSTRAINT fk_datos_laborales__tipos_contratos FOREIGN KEY (id_tipo_contrato) REFERENCES tipos_contratos(id);
alter table personas add column activo boolean not null default true;


CREATE OR REPLACE VIEW public.v_personas AS 
SELECT dl.legajo,a.*,domicilio,
  g.descripcion as genero,
  td.descripcion as tipo_documento,
  da.id_localidad,loc.nombre as localidad,loc.cp,provincia,pais,n.descripcion as nacionalidad,
  telefono_particular, telefono_celular,email,
  id_estado_civil,ec.descripcion as estado_civil,
  id_categoria,c.descripcion as categoria,
  id_establecimiento,es.descripcion as establecimiento,
  id_obra_social,os.descripcion as obra_social,os.codigo as codigo_obra_social,
  sueldo_basico,valor_hora,dl.id_tipo_contrato,tc.descripcion as tipo_contrato
FROM personas a 
LEFT JOIN datos_actuales da ON a.id = da.id_persona
LEFT JOIN datos_laborales dl ON a.id = dl.id_persona
LEFT JOIN datos_salud ds ON a.id = ds.id_persona     
LEFT JOIN estados_civiles ec ON ec.id=da.id_estado_civil     
LEFT JOIN categorias c ON c.id = dl.id_categoria
LEFT JOIN establecimientos es ON es.id=dl.id_establecimiento
LEFT JOIN obras_sociales os ON os.id=ds.id_obra_social
LEFT JOIN v_localidades loc ON loc.id = da.id_localidad
LEFT JOIN nacionalidades n ON n.id=a.id_nacionalidad
LEFT JOIN tipos_documentos td  ON td.id=a.id_tipo_documento
left join generos g ON g.id=a.id_genero
left join tipos_contratos tc ON tc.id=dl.id_tipo_contrato;

alter table conceptos add column formula text;

create table v_conceptos as 
select c.*,tc.descripcion as tipo_concepto 
from conceptos c
inner join tipos_conceptos tc ON tc.id=c.id_tipo_concepto;

--agrego codigo a las categorias
alter table categorias add column codigo text;
update categorias SET codigo = id;
alter table categorias ALTER COLUMN codigo SET NOT NULL;

create table tipos_empleadores(
  id serial not null,
  descripcion text not null,
  constraint pk_tipos_empleadores primary key(id)
);
alter table establecimientos add column cuit text;
alter table establecimientos add column actividad text;
alter table establecimientos add column id_tipo_empleador integer;
alter table establecimientos add constraint fk_establecimientos__tipo_empleador foreign key (id_tipo_empleador) references tipos_empleadores(id);


create table vacaciones(
  id serial not null,
  fecha_desde date not null,
  fecha_hasta date not null,
  observaciones text,
  id_persona integer not null,
  constraint pk_vacaciones primary key(id),
  constraint fk_vacaciones__personas foreign key(id_persona) references personas(id)
);