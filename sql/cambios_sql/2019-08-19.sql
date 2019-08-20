alter table sistema.reservadas add column defecto text;
CREATE OR REPLACE VIEW sistema.v_reservadas AS 
	SELECT r.id,
	r.nombre,
	r.descripcion,
	r.descripcion_larga,
	r.query,
	r.valor,
	r.id_tipo_reservada,
	r.id_tipo_dato,
	tr.descripcion AS tipo_reservada,
	td.descripcion AS tipo_dato,
	r.defecto
FROM sistema.reservadas r
 LEFT JOIN sistema.tipos_reservadas tr ON tr.id = r.id_tipo_reservada
 LEFT JOIN sistema.tipos_datos td ON td.id = r.id_tipo_dato;


alter table conceptos add column mostrar_si_cero boolean not null default false;
CREATE OR REPLACE VIEW public.v_conceptos AS 
SELECT c.id,
	c.descripcion,
	c.codigo,
	c.id_tipo_concepto,
	c.formula,
	tc.descripcion AS tipo_concepto,
	c.mostrar_en_recibo,
	c.totaliza,
	c.mostrar_si_cero
FROM conceptos c
JOIN tipos_conceptos tc ON tc.id = c.id_tipo_concepto;


--tuve que sacar la obligatoriedad para cargar
alter table personas alter column domicilio drop not null;
alter table personas alter column telefono_particular drop not null;
alter table personas alter column id_obra_social drop not null;
INSERT INTO personas(apellido, nombre, legajo, nro_documento,cuil,fecha_nacimiento,fecha_ingreso,id_categoria,id_tipo_contrato,id_estado_civil,
id_genero,id_nacionalidad,id_establecimiento,id_localidad,hora_entrada,hora_salida,id_tipo_documento,horas_jornada) VALUES 			
('Zeppa','Silvio',40,'26563056','20265630562','1978-05-20','2017-04-03',4,1,2,1,1,1,1,'08:00:00','15:00:00',1,7),
('Acosta','Claudio Daniel',29,'26823601','20268236016','1978-07-18','2011-04-06',4,1,2,1,1,1,1,'08:00:00','15:00:00',1,7),
('Becaj','Ivan Guillermo',31,'26583833','20265838333','1978-05-01','2013-06-03',2,1,1,1,1,1,1,'08:00:00','15:00:00',1,7),
('Cano','Silvia Marina',5,'14490100','27144901008','1960-12-22','1988-12-01',2,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Cespedes Ramirez','Teresita',8,'92727141','27927271414','1965-05-20','2010-03-01',5,2,3,2,1,1,1,'08:00:00','15:00:00',1,7),
('Dandrilli','Gisela Elizabeth',34,'30939944','27309399442','1984-08-04','2014-02-03',4,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Delgado','Noemi Severa',7,'12904169','27129041698','1956-10-27','1986-07-14',2,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Echenique','Cesar Anibal',37,'27113644','20271136448','1978-12-24','2015-06-01',3,2,1,1,1,1,1,'08:00:00','15:00:00',1,7),
('Ferrari','Maria Cecilia',26,'29594863','27295948634','1982-07-25','2008-02-20',3,2,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Ferreyra' ,'Rodrigo Raul',32,'34831908','20348319087','1989-10-10','2013-10-07',4,1,1,1,1,1,1,'08:00:00','15:00:00',1,7),
('Frascaroli','Micaela Noemi',19,'29233345','27292333450','1982-02-27','2003-10-01',2,1,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Gallesio','Betiana Nazareth',21,'26167199','27261671994','1978-01-04','2006-11-01',2,1,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Herrera','Claudia Fabiana',10,'16833436','27168334368','1965-04-28','1984-08-01',3,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Lombardo','Norma Elizabeth',27,'14097779','27140977794','1960-11-25','2009-08-03',2,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Paccor','Maria Soledad',35,'27033687','27270336871','1979-03-05','2014-11-03',3,1,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Paris','Alejandra',39,'30939775','23309397754','1984-05-06','2016-07-01',3,1,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Parra' ,'Jorgelina',23,'25048843','27250488438','1976-05-11','2007-07-02',3,1,1,2,1,1,1,'08:00:00','15:00:00',1,7),
('Poletti','Norma',2,'18601061','27186010618','1967-11-07','1986-09-01',2,1,2,2,1,1,1,'08:00:00','15:00:00',1,7),
('Riccardo','Lautaro',33,'32378152','20323781525','1986-05-29','2013-10-07',3,1,1,1,1,1,1,'08:00:00','15:00:00',1,7),
('Romero','Ana Gladys',3,'18148598','27181485987','1966-05-04','1986-11-01',1,1,3,2,1,1,1,'08:00:00','15:00:00',1,7);


CREATE OR REPLACE VIEW public.v_tipo_liquidacion_conceptos AS 
SELECT tlc.id,
	tlc.id_concepto,
	tlc.id_tipo_liquidacion,
	(('['::text || c.codigo) || '] '::text) || c.descripcion AS concepto,
	tl.descripcion AS tipo_liquidacion,
	c.codigo
FROM tipo_liquidacion_conceptos tlc
JOIN conceptos c ON c.id = tlc.id_concepto
JOIN tipos_liquidaciones tl ON tl.id = tlc.id_tipo_liquidacion;

--creo una nueva reservada
INSERT INTO sistema.reservadas ( id,id_tipo_dato, defecto, nombre, descripcion, descripcion_larga, query, valor, id_tipo_reservada ) 
 VALUES (7,'4', '0', 'diastrab', 'Dias Trabajados en el mes', '', 'SELECT sistema.dias_trabajados_periodo({ID_LIQUIDACION}, {ID_PERSONA}) as resultado;', DEFAULT, '2');


--posible tabla de resumen
create table fichajes_resumen(
	id serial not null,
	id_persona integer not null,	
	fecha_desde date not null,
	fecha_hasta date not null,
	anio integer,
	mes integer,
	dias_trabajados numeric(10,2),
	horas_comunes numeric(10,2),
	horas_extras numeric(10,2),
	inasistencias_justificadas numeric(10,2),
	inasistencias_injustificadas numeric(10,2),
	constraint pk_fichajes_resumen primary key(id),
	constraint fk_fichajes_resumen__personas foreign key(id_persona) references personas(id)
 ); 