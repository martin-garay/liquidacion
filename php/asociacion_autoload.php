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
		'Evaluator' => '3ros/Matex/Evaluator.php',
		'asociacion_autoload' => 'asociacion_autoload.php',
		'Logger' => 'clases/Logger.php',
		'dt_recibos' => 'clases/datos_tabla/dt_recibos.php',
		'Concepto' => 'clases/liquidacion/Concepto.php',
		'FunctionesLiquidador' => 'clases/liquidacion/FuncionesLiquidador.php',
		'Liquidacion' => 'clases/liquidacion/Liquidacion.php',
		'Liquidador' => 'clases/liquidacion/Liquidador.php',
		'Recibo' => 'clases/liquidacion/Recibo.php',
		'Reservada' => 'clases/liquidacion/Reservada.php',
		'ContractPersistorObject' => 'clases/modelo/ContractPersistorObject.php',
		'Inflector' => 'clases/modelo/Inflector.php',
		'Model' => 'clases/modelo/Model.php',
		'PersistorPostgresql' => 'clases/modelo/PersistorPostgresql.php',
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
		'ciudades' => 'lib/ciudades.php',
		'combo_editable' => 'lib/combo_editable.php',
		'comunes' => 'lib/comunes.php',
		'liquidacion' => 'lib/liquidacion.php',
		'parametrizacion' => 'lib/parametrizacion.php',
		'personas' => 'lib/personas.php',
		'reservadas' => 'lib/reservadas.php',
		'ci_login' => 'login/ci_login.php',
		'cuadro_autologin' => 'login/cuadro_autologin.php',
		'pant_login' => 'login/pant_login.php',
		'ci_generico_dos_pantallas_relacion' => 'operaciones/ci_generico_dos_pantallas_relacion.php',
		'ci_generico_una_pantalla' => 'operaciones/ci_generico_una_pantalla.php',
		'ci_informe_generico' => 'operaciones/ci_informe_generico.php',
		'ci_liquidacion' => 'operaciones/liquidacion/ci_liquidacion.php',
		'ci_datos_liquidacion' => 'operaciones/liquidacion/liquidacion/ci_datos_liquidacion.php',
		'ci_recibos' => 'operaciones/liquidacion/recibos/ci_recibos.php',
		'ci_abm_conceptos' => 'operaciones/parametrizacion/abm_conceptos/ci_abm_conceptos.php',
		'form_funciones_js' => 'operaciones/parametrizacion/abm_conceptos/form_funciones_js.php',
		'ci_generico' => 'operaciones/parametrizacion/ci_generico.php',
		'ci_amb_personas' => 'operaciones/personas/ci_amb_personas.php',
		'ci_datos_persona' => 'operaciones/personas/datos_persona/ci_datos_persona.php',
		'form_persona_js' => 'operaciones/personas/datos_persona/form_persona_js.php',
	);
}
?>