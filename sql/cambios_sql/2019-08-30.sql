create table liquidaciones_historico(
	id integer not null,
	descripcion text NOT NULL,
	periodo date NOT NULL,
	fecha_desde date,
	fecha_hasta date,
	id_tipo_liquidacion integer NOT NULL,
	id_establecimiento integer NOT NULL DEFAULT 1,
	id_banco integer NOT NULL,
	fecha_pago date NOT NULL,
	periodo_depositado character varying(10),
	lugar_pago text,
	fecha_deposito date,
	id_estado integer NOT NULL DEFAULT 1,
	mes integer,
	anio integer,
	nro_recibo_inicial integer NOT NULL,
	/* descripciones */
	banco text,
	estado text,
	tipo_liquidacion text,
	establecimiento text,
	direccion_establecimiento text,
	localidad_establecimiento text,
	cp_establecimiento text,
	provincia_establecimiento text,
	CONSTRAINT pk_liquidaciones_historico PRIMARY KEY (id),
	constraint fk_liquidaciones_historico__liquidaciones foreign key(id) references liquidaciones(id)
);

CREATE TABLE public.liquidaciones_conceptos_historico
(
  id integer NOT NULL,
  id_concepto integer NOT NULL,
  id_liquidacion integer NOT NULL,
  valor_fijo numeric(10,2),
  /* descripciones */
  concepto text,
  codigo text,
  formula text,
  tipo_concepto text,
  CONSTRAINT pk_liquidaciones_conceptos_historico PRIMARY KEY (id),
  CONSTRAINT fk_liquidaciones_conceptos_h__liquidacionesh foreign key (id_liquidacion) references liquidaciones_historico(id)
);

CREATE TABLE public.recibos_historico
(
  id integer NOT NULL,
  nro_recibo integer,
  id_persona integer NOT NULL,
  total_remunerativos numeric(10,2),
  total_no_remunerativos numeric(10,2),
  total_deducciones numeric(10,2),
  total_neto numeric(10,2),
  total_basico numeric(10,2),
  id_liquidacion integer NOT NULL,
  /* descripciones */
  apellido text,
  nombre text,
  legajo integer,
  tipo_documento text,
  nro_documento integer,
  genero text,
  id_estado_civil integer,
  estado_civil text,
  fecha_nacimiento date,
  edad integer,
  regimen text,
  cuil text,
  id_categoria integer,
  categoria text,
  tarea text,
  sueldo_basico numeric(10,2),
  fecha_ingreso date,
  fecha_egreso date,
  id_tipo_contrato integer,
  tipo_contrato text,
  id_obra_social integer,
  obra_social text,
  obra_social_codigo text,
  id_localidad integer,
  localidad text,
  cp integer,
  domicilio text,
  id_nacionalidad integer,
  nacionalidad text,
  pais text,
  provincia text,
  CONSTRAINT pk_recibos_historico PRIMARY KEY (id),  
  CONSTRAINT fk_recibos_historico__liquidacionesh foreign key (id_liquidacion) references liquidaciones_historico(id),
  CONSTRAINT uk_recibosh UNIQUE (id_liquidacion, id_persona)
);

CREATE TABLE public.recibos_acumuladores_historico
(
  id integer NOT NULL,
  id_acumulador integer NOT NULL,
  importe numeric(10,2) NOT NULL,
  id_recibo integer NOT NULL,
  /* descripciones */
  nombre text,
  descripcion text,
  id_tipo_concepto integer,
  tipo_concepto text,
  CONSTRAINT pk_recibos_acumuladores_historico PRIMARY KEY (id),  
  CONSTRAINT fk_recibos_acumuladoresh__reciboh FOREIGN KEY (id_recibo) REFERENCES public.recibos_historico (id),
  CONSTRAINT uk_recibos_acumuladoresh UNIQUE (id_recibo, id_acumulador)
);

CREATE TABLE public.recibos_conceptos_historico
(
  id integer NOT NULL,
  id_concepto integer NOT NULL,
  importe numeric(10,2),
  id_recibo integer NOT NULL,
  /* descripciones */
  concepto text,
  codigo text,
  formula text,
  id_tipo_concepto integer,
  tipo_concepto text,
  mostrar_en_recibo boolean,
  mostrar_si_cero boolean,
  totaliza boolean,
  valor_fijo numeric(10,2),
  remunerativo boolean,
  retencion boolean,
  CONSTRAINT pk_recibos_conceptos_historico PRIMARY KEY (id),  
  CONSTRAINT fk_recibos_conceptos__reciboh FOREIGN KEY (id_recibo) REFERENCES public.recibos_historico (id),
  CONSTRAINT uk_recibos_conceptosh UNIQUE (id_concepto, id_recibo)
);
