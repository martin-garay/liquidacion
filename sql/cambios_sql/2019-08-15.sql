insert into bancos(id,descripcion) values(1,'Galicia');

update sistema.reservadas set nombre = lower(nombre);


/* Trabajado a la noche */
--#1
	/* Borro las dependencias*/
	delete from datos_salud;
	delete from datos_laborales;
	delete from datos_actuales;
	delete from fichajes;
	delete from persona_tareas;
	delete from recibos;
	delete from personas;

	/* Creo las columnas */
	alter table personas add column legajo integer not null;
	alter table personas add column id_estado_civil integer not null;
	alter table personas add column id_categoria integer not null;
	alter table personas add column id_tipo_contrato integer not null;
	alter table personas add column id_establecimiento integer not null;
	alter table personas add column email text;
	alter table personas add column fecha_ingreso date not null;
	alter table personas add column fecha_egreso date not null;
	alter table personas add column hora_entrada time without time zone not null;
	alter table personas add column hora_salida time without time zone not null;
	alter table personas add column id_localidad integer not null;
	alter table personas add column domicilio text not null;
	alter table personas add column piso char(2);
	alter table personas add column departamento char(10) ;
	alter table personas add column telefono_particular character varying(30) not null;
	alter table personas add column telefono_celular character varying(30) not null;
	alter table personas add column id_obra_social integer not null;
	alter table personas add column cuil character varying(15) not null;

	drop view v_personas;
	CREATE OR REPLACE VIEW public.v_personas AS 
	 SELECT a.legajo,
		a.id,
		a.nombre,
		a.apellido,
		a.fecha_nacimiento,
		a.id_tipo_documento,
		a.nro_documento,
		a.cuil,
		a.id_genero,
		a.id_nacionalidad,
		a.activo,
		a.domicilio,
		g.descripcion AS genero,
		td.descripcion AS tipo_documento,
		a.id_localidad,
		loc.nombre AS localidad,
		loc.cp,
		loc.provincia,
		loc.pais,
		n.descripcion AS nacionalidad,
		a.telefono_particular,
		a.telefono_celular,
		a.email,
		a.id_estado_civil,
		ec.descripcion AS estado_civil,
		a.id_categoria,
		c.descripcion AS categoria,
		a.id_establecimiento,
		es.descripcion AS establecimiento,
		a.id_obra_social,
		os.descripcion AS obra_social,
		os.codigo AS codigo_obra_social,
		c.sueldo_basico,
		c.valor_hora,
		a.id_tipo_contrato,
		tc.descripcion AS tipo_contrato
	FROM personas a
	LEFT JOIN estados_civiles ec ON ec.id = a.id_estado_civil
	LEFT JOIN categorias c ON c.id = a.id_categoria
	LEFT JOIN establecimientos es ON es.id = a.id_establecimiento
	LEFT JOIN obras_sociales os ON os.id = a.id_obra_social
	LEFT JOIN v_localidades loc ON loc.id = a.id_localidad
	LEFT JOIN nacionalidades n ON n.id = a.id_nacionalidad
	LEFT JOIN tipos_documentos td ON td.id = a.id_tipo_documento
	LEFT JOIN generos g ON g.id = a.id_genero
	LEFT JOIN tipos_contratos tc ON tc.id = a.id_tipo_contrato;

	/* Cambio los query de las reservadas */
	UPDATE sistema.reservadas
	SET query = 'SELECT edad(fecha_ingreso)  as resultado FROM personas WHERE id={ID_PERSONA}'
	WHERE id = '2';
	
	UPDATE sistema.reservadas
	SET query = 'SELECT sueldo_basico as resultado FROM categorias WHERE id=(SELECT id_categoria FROM personas WHERE id={ID_PERSONA})'
	WHERE id = '1';

	UPDATE sistema.reservadas
	SET query = 'SELECT (id_tipo_contrato=1) as resultado FROM personas WHERE id={ID_PERSONA}'
	WHERE id = '5';

	UPDATE sistema.reservadas
	SET query = 'SELECT (id_tipo_contrato=2) as resultado FROM personas WHERE id={ID_PERSONA}'
	WHERE id = '6';


alter table liquidaciones RENAME mes to periodo_depositado;

create table feriados(
	id serial not null,
	fecha date not null,
	descripcion text not null,
	hora_desde time without time zone,
	hora_hasta time without time zone,	
	constraint pk_feriados primary key (id)
);

--crear las siguientes palabras reservadas:
--dias_laborables
--dias_no_laborables
--dias_trabajados
--dias_justificados
--inasistencias