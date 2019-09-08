------------------------------------------------------------
--[2860]--  Datos Liquidacion - relacion 
------------------------------------------------------------

------------------------------------------------------------
-- apex_objeto
------------------------------------------------------------

--- INICIO Grupo de desarrollo 0
INSERT INTO apex_objeto (proyecto, objeto, anterior, identificador, reflexivo, clase_proyecto, clase, punto_montaje, subclase, subclase_archivo, objeto_categoria_proyecto, objeto_categoria, nombre, titulo, colapsable, descripcion, fuente_datos_proyecto, fuente_datos, solicitud_registrar, solicitud_obj_obs_tipo, solicitud_obj_observacion, parametro_a, parametro_b, parametro_c, parametro_d, parametro_e, parametro_f, usuario, creacion, posicion_botonera) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	NULL, --anterior
	NULL, --identificador
	NULL, --reflexivo
	'toba', --clase_proyecto
	'toba_datos_relacion', --clase
	'16', --punto_montaje
	NULL, --subclase
	NULL, --subclase_archivo
	NULL, --objeto_categoria_proyecto
	NULL, --objeto_categoria
	'Datos Liquidacion - relacion', --nombre
	NULL, --titulo
	NULL, --colapsable
	NULL, --descripcion
	'asociacion', --fuente_datos_proyecto
	'asociacion', --fuente_datos
	NULL, --solicitud_registrar
	NULL, --solicitud_obj_obs_tipo
	NULL, --solicitud_obj_observacion
	NULL, --parametro_a
	NULL, --parametro_b
	NULL, --parametro_c
	NULL, --parametro_d
	NULL, --parametro_e
	NULL, --parametro_f
	NULL, --usuario
	'2019-08-13 23:23:17', --creacion
	NULL  --posicion_botonera
);
--- FIN Grupo de desarrollo 0

------------------------------------------------------------
-- apex_objeto_datos_rel
------------------------------------------------------------
INSERT INTO apex_objeto_datos_rel (proyecto, objeto, debug, clave, ap, punto_montaje, ap_clase, ap_archivo, sinc_susp_constraints, sinc_orden_automatico, sinc_lock_optimista) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'0', --debug
	NULL, --clave
	'2', --ap
	'16', --punto_montaje
	NULL, --ap_clase
	NULL, --ap_archivo
	'0', --sinc_susp_constraints
	'1', --sinc_orden_automatico
	'1'  --sinc_lock_optimista
);

------------------------------------------------------------
-- apex_objeto_dependencias
------------------------------------------------------------

--- INICIO Grupo de desarrollo 0
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1716', --dep_id
	'2860', --objeto_consumidor
	'2857', --objeto_proveedor
	'liquidacion', --identificador
	'0', --parametros_a
	'1', --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	'1'  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1720', --dep_id
	'2860', --objeto_consumidor
	'2862', --objeto_proveedor
	'liquidacion_conceptos', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	'2'  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1717', --dep_id
	'2860', --objeto_consumidor
	'2858', --objeto_proveedor
	'recibos', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	'3'  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1772', --dep_id
	'2860', --objeto_consumidor
	'2910', --objeto_proveedor
	'recibos_acumuladores', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	'5'  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1738', --dep_id
	'2860', --objeto_consumidor
	'2859', --objeto_proveedor
	'recibos_conceptos', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	'4'  --orden
);
--- FIN Grupo de desarrollo 0

------------------------------------------------------------
-- apex_objeto_datos_rel_asoc
------------------------------------------------------------

--- INICIO Grupo de desarrollo 0
INSERT INTO apex_objeto_datos_rel_asoc (proyecto, objeto, asoc_id, identificador, padre_proyecto, padre_objeto, padre_id, padre_clave, hijo_proyecto, hijo_objeto, hijo_id, hijo_clave, cascada, orden) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'93', --asoc_id
	NULL, --identificador
	'asociacion', --padre_proyecto
	'2857', --padre_objeto
	'liquidacion', --padre_id
	NULL, --padre_clave
	'asociacion', --hijo_proyecto
	'2858', --hijo_objeto
	'recibos', --hijo_id
	NULL, --hijo_clave
	NULL, --cascada
	'1'  --orden
);
INSERT INTO apex_objeto_datos_rel_asoc (proyecto, objeto, asoc_id, identificador, padre_proyecto, padre_objeto, padre_id, padre_clave, hijo_proyecto, hijo_objeto, hijo_id, hijo_clave, cascada, orden) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'94', --asoc_id
	NULL, --identificador
	'asociacion', --padre_proyecto
	'2857', --padre_objeto
	'liquidacion', --padre_id
	NULL, --padre_clave
	'asociacion', --hijo_proyecto
	'2862', --hijo_objeto
	'liquidacion_conceptos', --hijo_id
	NULL, --hijo_clave
	NULL, --cascada
	'2'  --orden
);
INSERT INTO apex_objeto_datos_rel_asoc (proyecto, objeto, asoc_id, identificador, padre_proyecto, padre_objeto, padre_id, padre_clave, hijo_proyecto, hijo_objeto, hijo_id, hijo_clave, cascada, orden) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'95', --asoc_id
	NULL, --identificador
	'asociacion', --padre_proyecto
	'2858', --padre_objeto
	'recibos', --padre_id
	NULL, --padre_clave
	'asociacion', --hijo_proyecto
	'2859', --hijo_objeto
	'recibos_conceptos', --hijo_id
	NULL, --hijo_clave
	NULL, --cascada
	'3'  --orden
);
INSERT INTO apex_objeto_datos_rel_asoc (proyecto, objeto, asoc_id, identificador, padre_proyecto, padre_objeto, padre_id, padre_clave, hijo_proyecto, hijo_objeto, hijo_id, hijo_clave, cascada, orden) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'101', --asoc_id
	NULL, --identificador
	'asociacion', --padre_proyecto
	'2858', --padre_objeto
	'recibos', --padre_id
	NULL, --padre_clave
	'asociacion', --hijo_proyecto
	'2910', --hijo_objeto
	'recibos_acumuladores', --hijo_id
	NULL, --hijo_clave
	NULL, --cascada
	'4'  --orden
);
--- FIN Grupo de desarrollo 0

------------------------------------------------------------
-- apex_objeto_rel_columnas_asoc
------------------------------------------------------------
INSERT INTO apex_objeto_rel_columnas_asoc (proyecto, objeto, asoc_id, padre_objeto, padre_clave, hijo_objeto, hijo_clave) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'93', --asoc_id
	'2857', --padre_objeto
	'1471', --padre_clave
	'2858', --hijo_objeto
	'1491'  --hijo_clave
);
INSERT INTO apex_objeto_rel_columnas_asoc (proyecto, objeto, asoc_id, padre_objeto, padre_clave, hijo_objeto, hijo_clave) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'94', --asoc_id
	'2857', --padre_objeto
	'1471', --padre_clave
	'2862', --hijo_objeto
	'1497'  --hijo_clave
);
INSERT INTO apex_objeto_rel_columnas_asoc (proyecto, objeto, asoc_id, padre_objeto, padre_clave, hijo_objeto, hijo_clave) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'95', --asoc_id
	'2858', --padre_objeto
	'1483', --padre_clave
	'2859', --hijo_objeto
	'1536'  --hijo_clave
);
INSERT INTO apex_objeto_rel_columnas_asoc (proyecto, objeto, asoc_id, padre_objeto, padre_clave, hijo_objeto, hijo_clave) VALUES (
	'asociacion', --proyecto
	'2860', --objeto
	'101', --asoc_id
	'2858', --padre_objeto
	'1483', --padre_clave
	'2910', --hijo_objeto
	'1603'  --hijo_clave
);
