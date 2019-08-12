<?php
/**
 * Esta clase fue y será generada automáticamente. NO EDITAR A MANO.
 * @ignore
 */
class asociacion_autoload 
{
	static function existe_clase($nombre)
	{
		return isset(self::$clases[$nombre]);
	}

	static function cargar($nombre)
	{
		if (self::existe_clase($nombre)) { 
			 require_once(dirname(__FILE__) .'/'. self::$clases[$nombre]); 
		}
	}

	static protected $clases = array(
		'asociacion_comando' => 'extension_toba/asociacion_comando.php',
		'asociacion_modelo' => 'extension_toba/asociacion_modelo.php',
		'asociacion_ci' => 'extension_toba/componentes/asociacion_ci.php',
		'asociacion_cn' => 'extension_toba/componentes/asociacion_cn.php',
		'asociacion_datos_relacion' => 'extension_toba/componentes/asociacion_datos_relacion.php',
		'asociacion_datos_tabla' => 'extension_toba/componentes/asociacion_datos_tabla.php',
		'asociacion_ei_arbol' => 'extension_toba/componentes/asociacion_ei_arbol.php',
		'asociacion_ei_archivos' => 'extension_toba/componentes/asociacion_ei_archivos.php',
		'asociacion_ei_calendario' => 'extension_toba/componentes/asociacion_ei_calendario.php',
		'asociacion_ei_codigo' => 'extension_toba/componentes/asociacion_ei_codigo.php',
		'asociacion_ei_cuadro' => 'extension_toba/componentes/asociacion_ei_cuadro.php',
		'asociacion_ei_esquema' => 'extension_toba/componentes/asociacion_ei_esquema.php',
		'asociacion_ei_filtro' => 'extension_toba/componentes/asociacion_ei_filtro.php',
		'asociacion_ei_firma' => 'extension_toba/componentes/asociacion_ei_firma.php',
		'asociacion_ei_formulario' => 'extension_toba/componentes/asociacion_ei_formulario.php',
		'asociacion_ei_formulario_ml' => 'extension_toba/componentes/asociacion_ei_formulario_ml.php',
		'asociacion_ei_grafico' => 'extension_toba/componentes/asociacion_ei_grafico.php',
		'asociacion_ei_mapa' => 'extension_toba/componentes/asociacion_ei_mapa.php',
		'asociacion_servicio_web' => 'extension_toba/componentes/asociacion_servicio_web.php',
	);
}
?>