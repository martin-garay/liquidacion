------------------------------------------------------------
--[18000829]--  datosABM Conceptos 
------------------------------------------------------------

------------------------------------------------------------
-- apex_objeto
------------------------------------------------------------

--- INICIO Grupo de desarrollo 18
INSERT INTO apex_objeto (proyecto, objeto, anterior, identificador, reflexivo, clase_proyecto, clase, punto_montaje, subclase, subclase_archivo, objeto_categoria_proyecto, objeto_categoria, nombre, titulo, colapsable, descripcion, fuente_datos_proyecto, fuente_datos, solicitud_registrar, solicitud_obj_obs_tipo, solicitud_obj_observacion, parametro_a, parametro_b, parametro_c, parametro_d, parametro_e, parametro_f, usuario, creacion, posicion_botonera) VALUES (
	'asociacion', --proyecto
	'18000829', --objeto
	NULL, --anterior
	NULL, --identificador
	NULL, --reflexivo
	'toba', --clase_proyecto
	'toba_ci', --clase
	'16', --punto_montaje
	'ci_datos_conceptos', --subclase
	'operaciones/parametrizacion/abm_conceptos/ci_datos_conceptos.php', --subclase_archivo
	NULL, --objeto_categoria_proyecto
	NULL, --objeto_categoria
	'datosABM Conceptos', --nombre
	NULL, --titulo
	'0', --colapsable
	NULL, --descripcion
	NULL, --fuente_datos_proyecto
	NULL, --fuente_datos
	NULL, --solicitud_registrar
	NULL, --solicitud_obj_obs_tipo
	NULL, --solicitud_obj_observacion
	'conceptos', --parametro_a
	'codigo::int', --parametro_b
	'v_conceptos', --parametro_c
	NULL, --parametro_d
	NULL, --parametro_e
	NULL, --parametro_f
	NULL, --usuario
	'2019-08-11 20:12:31', --creacion
	'abajo'  --posicion_botonera
);
--- FIN Grupo de desarrollo 18

------------------------------------------------------------
-- apex_objeto_mt_me
------------------------------------------------------------
INSERT INTO apex_objeto_mt_me (objeto_mt_me_proyecto, objeto_mt_me, ev_procesar_etiq, ev_cancelar_etiq, ancho, alto, posicion_botonera, tipo_navegacion, botonera_barra_item, con_toc, incremental, debug_eventos, activacion_procesar, activacion_cancelar, ev_procesar, ev_cancelar, objetos, post_procesar, metodo_despachador, metodo_opciones) VALUES (
	'asociacion', --objeto_mt_me_proyecto
	'18000829', --objeto_mt_me
	NULL, --ev_procesar_etiq
	NULL, --ev_cancelar_etiq
	'100%', --ancho
	NULL, --alto
	NULL, --posicion_botonera
	'tab_h', --tipo_navegacion
	'0', --botonera_barra_item
	'0', --con_toc
	NULL, --incremental
	NULL, --debug_eventos
	NULL, --activacion_procesar
	NULL, --activacion_cancelar
	NULL, --ev_procesar
	NULL, --ev_cancelar
	NULL, --objetos
	NULL, --post_procesar
	NULL, --metodo_despachador
	NULL  --metodo_opciones
);

------------------------------------------------------------
-- apex_objeto_dependencias
------------------------------------------------------------

--- INICIO Grupo de desarrollo 18
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000862', --dep_id
	'18000829', --objeto_consumidor
	'18000825', --objeto_proveedor
	'form', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
--- FIN Grupo de desarrollo 18

--- INICIO Grupo de desarrollo 0
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1771', --dep_id
	'18000829', --objeto_consumidor
	'2911', --objeto_proveedor
	'form_acumuladores', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
--- FIN Grupo de desarrollo 0

--- INICIO Grupo de desarrollo 18
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000863', --dep_id
	'18000829', --objeto_consumidor
	'18000826', --objeto_proveedor
	'form_conceptos', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000864', --dep_id
	'18000829', --objeto_consumidor
	'18000827', --objeto_proveedor
	'form_funciones', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000868', --dep_id
	'18000829', --objeto_consumidor
	'18000830', --objeto_proveedor
	'form_ml_personas', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000865', --dep_id
	'18000829', --objeto_consumidor
	'18000828', --objeto_proveedor
	'form_reservadas', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
--- FIN Grupo de desarrollo 18

--- INICIO Grupo de desarrollo 0
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'1777', --dep_id
	'18000829', --objeto_consumidor
	'2916', --objeto_proveedor
	'form_tablas', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
--- FIN Grupo de desarrollo 0

--- INICIO Grupo de desarrollo 18
INSERT INTO apex_objeto_dependencias (proyecto, dep_id, objeto_consumidor, objeto_proveedor, identificador, parametros_a, parametros_b, parametros_c, inicializar, orden) VALUES (
	'asociacion', --proyecto
	'18000866', --dep_id
	'18000829', --objeto_consumidor
	'18000822', --objeto_proveedor
	'relacion', --identificador
	NULL, --parametros_a
	NULL, --parametros_b
	NULL, --parametros_c
	NULL, --inicializar
	NULL  --orden
);
--- FIN Grupo de desarrollo 18

------------------------------------------------------------
-- apex_objeto_ci_pantalla
------------------------------------------------------------

--- INICIO Grupo de desarrollo 18
INSERT INTO apex_objeto_ci_pantalla (objeto_ci_proyecto, objeto_ci, pantalla, identificador, orden, etiqueta, descripcion, tip, imagen_recurso_origen, imagen, objetos, eventos, subclase, subclase_archivo, template, template_impresion, punto_montaje) VALUES (
	'asociacion', --objeto_ci_proyecto
	'18000829', --objeto_ci
	'18000274', --pantalla
	'pant_concepto', --identificador
	'1', --orden
	'Concepto', --etiqueta
	NULL, --descripcion
	NULL, --tip
	'apex', --imagen_recurso_origen
	NULL, --imagen
	NULL, --objetos
	NULL, --eventos
	NULL, --subclase
	NULL, --subclase_archivo
	'<table>
	<tbody>
		<tr>
			<td style="vertical-align: top;">
				[dep id=form_reservadas] [dep id=form_funciones] [dep id=form_conceptos] [dep id=form_acumuladores] [dep id=form_tablas]</td>
			<td style="vertical-align: top;box-shadow: 0px 0px 1px 1px rgba(0, 0, 0, 0.28);">
				[dep id=form]</td>
		</tr>
	</tbody>
</table>', --template
	NULL, --template_impresion
	'16'  --punto_montaje
);
INSERT INTO apex_objeto_ci_pantalla (objeto_ci_proyecto, objeto_ci, pantalla, identificador, orden, etiqueta, descripcion, tip, imagen_recurso_origen, imagen, objetos, eventos, subclase, subclase_archivo, template, template_impresion, punto_montaje) VALUES (
	'asociacion', --objeto_ci_proyecto
	'18000829', --objeto_ci
	'18000276', --pantalla
	'pant_personas', --identificador
	'2', --orden
	'Empleados', --etiqueta
	'Empleados a las que aplica el concepto. Dejar vacio si se calcula para todos.
<br><br>
<strong>ATENCION SI SE USA EN OTRO CALCULO! </strong> Si otro concepto usa a este en la formula no sera calculado para otras personas que no esten en esta lista y el liquidador puede devolver error de que no existe el concepto ya que no se le genero a la persona. Por ej: El concepto Años de Reconocimiento es usado en la formula Antiguedad que es usado por todas las personas. Si se limita el 1ro a ciertas personas el 2do devolvera error para las personas que no se definieron.', --descripcion
	'Solo para ciertos empleados', --tip
	'apex', --imagen_recurso_origen
	NULL, --imagen
	NULL, --objetos
	NULL, --eventos
	NULL, --subclase
	NULL, --subclase_archivo
	NULL, --template
	NULL, --template_impresion
	'16'  --punto_montaje
);
--- FIN Grupo de desarrollo 18

------------------------------------------------------------
-- apex_objetos_pantalla
------------------------------------------------------------
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'4', --orden
	'1771'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'5', --orden
	'1777'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'3', --orden
	'18000862'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'1', --orden
	'18000863'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'0', --orden
	'18000864'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000274', --pantalla
	'18000829', --objeto_ci
	'2', --orden
	'18000865'  --dep_id
);
INSERT INTO apex_objetos_pantalla (proyecto, pantalla, objeto_ci, orden, dep_id) VALUES (
	'asociacion', --proyecto
	'18000276', --pantalla
	'18000829', --objeto_ci
	'0', --orden
	'18000868'  --dep_id
);
