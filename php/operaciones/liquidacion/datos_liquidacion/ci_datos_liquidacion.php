<?php
class ci_datos_liquidacion extends asociacion_ci
{
	protected $desactivar_edicion = false;
	
	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function resetear(){
		$this->relacion()->resetear();
	}
	function set_solo_lectura($solo_lectura=true){
		$this->desactivar_edicion = $solo_lectura;
	}
	function esta_cargada(){
		return $this->relacion()->esta_cargada();
	}
	function get_estado(){
		//si se esta creando una nueva devuelvo null
		if( $this->esta_cargada() )
			return $this->tabla('liquidacion')->get_columna('id_estado');
		else
			return null;
	}	
	function cantidad_empleados(){
		return $this->tabla('recibos')->get_cantidad_filas();
	}
	function cantidad_conceptos(){
		return $this->tabla('liquidacion_conceptos')->get_cantidad_filas();	
	}
	function crear(){
		try {
			if( $this->cantidad_empleados()>0 && $this->cantidad_conceptos()>0 ){
				$this->relacion()->sincronizar();
			}
			else{								
				throw new toba_error_usuario("No se seleccionaron personas o conceptos");				
			}
		} catch (toba_error_db $e) {
			toba::notificacion()->error('Error al grabar <br>'.$e->get_mensaje_motor());
		}
	}
	function guardar(){
		$this->relacion()->persistidor()->desactivar_transaccion(true);
		toba::db()->abrir_transaccion();
		try {
			if( $this->cantidad_empleados()>0 && $this->cantidad_conceptos()>0 ){
				$this->relacion()->sincronizar();
				toba::db()->cerrar_transaccion();
				toba::notificacion()->info('Se grabo correctamente');
			}
			else{								
				throw new toba_error_usuario("No se seleccionaron personas o conceptos");
			}
		} catch (toba_error_db $e) {
			// if($e->get_sqlstate()=="db_23505"){
			// 	/* Clave Duplicada */
			// 	$mensaje ="Ya existe una liquidacion en el periodo";  //NOOOO puede haber varias liquidaciones
			// }else{

			// }
			toba::notificacion()->error('Error al grabar <br>'.$e->get_mensaje_motor());
			toba::db()->abortar_transaccion();
		}
	}
	function borrar($seleccion){        
		$this->relacion()->cargar($seleccion);
		try{
			$this->relacion()->eliminar_todo();
			$this->relacion()->sincronizar();
			toba::notificacion()->info('La liquidacion fue eliminada correctamente!');
		}catch(toba_error_db $e){
			if($e->get_sqlstate()=="db_23503"){
				toba::notificacion()->error('ATENCION! El registro esta siendo utilizado');
			}else{
				throw new toba_error_usuario($e->get_mensaje_motor());
				toba::notificacion()->error('ERROR! El registro No puede eliminarse');
			}
		}
		//$this->relacion()->resetear();
	}
	function desactivar_edicion(){
		$this->desactivar_edicion = true;
	}

	function liquidar(){		

		//verifico que el estado sea PENDIENTE LIQUIDACION
		if( $this->tabla('liquidacion')->get_columna('id_estado')==1 ){			
						
			$id_liquidacion = $this->tabla('liquidacion')->get_columna('id');
			$liquidador = new LiquidadorNuevo($id_liquidacion);			

			Logger::titulo('Liquidacion '.$id_liquidacion);
			//recorro cada recibo
			$recibos = $this->tabla('recibos')->get_filas(null, true);
			$nro_recibo = $this->tabla('liquidacion')->get_columna('nro_recibo_inicial');
			foreach( $recibos as $key => $recibo ) {
				$this->tabla('recibos')->set_cursor( $key );				
				$recibo = $this->tabla('recibos')->get();
				
				$liquidador->nuevo_recibo($recibo['id_persona']);								//se cargan las reservadas del empleado
				Logger::separador('Generando recibo '.$recibo['id'].' persona '.$recibo['id_persona']);

				$conceptos = $this->tabla('recibos_conceptos')->get_filas(null, true);
				$conceptos_ordenados = $this->ordenar_conceptos($conceptos);				

				foreach ($conceptos_ordenados as $key2 => $variable) {
					$this->tabla('recibos_conceptos')->set_cursor($key2);					
					$concepto = $this->tabla('recibos_conceptos')->get();

					//si el usuario le puso un valor al concepto le dejo ese, sino lo calcula el liquidador
					if( !isset($concepto['importe']) ){

						/*aca tengo que pasarle al liquidador el tipo_cocepto y si totaliza para que valla acumulando en las variables que corresponda.
						Por ej. para sueldo_bruto si es acumula si el tipo concepto es HABERRES y totaliza */	
											
						$concepto['importe'] = $liquidador->calcular_concepto($concepto);
						$this->tabla('recibos_conceptos')->set($concepto);					
					}else{

						//si existe un importe fijo igual tengo que cargar el concepto como una variable del liquidador para los siguientes calculos
						$nombre_variable = 'c'.$concepto['codigo'];
						$liquidador->agregar_variable($nombre_variable, $concepto['importe']);
						
					}
					Logger::info($concepto['codigo'].'='.$concepto['importe']);
				}
				//Guardo los acumuladores totalizados
				$acumuladores = $liquidador->get_acumuladores_totalizados();
				$this->tabla('recibos_acumuladores')->procesar_filas($acumuladores);
				//ei_arbol($acumuladores);
				//actualizo los totales del recibo (aunque estan tambien en recibos_acumuladores)
				//si el acumulador hace match con la columna piso el valor
				$columnas_recibo = array_keys( $this->tabla('recibos')->get_columnas() );
				foreach ($acumuladores as $key => $acumulador) {
					//$key = array_search($nombre_columna, array_column($acumuladores, 'nombre'));		//busca la key del array acumuladores
					if( in_array($acumulador['nombre'], $columnas_recibo) )
						$recibo[ $acumulador['nombre'] ] = $acumulador['importe'];
					//if($key)
					//	$recibo[$nombre_columna] = $acumuladores[$key]['importe'];
				}
								
				$recibo['json_variables'] 	= $liquidador->get_variables_json();	 	//Guardo un json con las variables del liquidador
				$recibo['nro_recibo'] 		= $nro_recibo;								//se hacia x trg pero daba error el dt
				$nro_recibo++;

				//total_neto
				$recibo['total_neto'] = $recibo['total_remunerativos'] + $recibo['total_no_remunerativos'] - $recibo['total_deducciones'];

				$this->tabla('recibos')->set($recibo);

				Logger::separador('Fin recibo persona '.$recibo['id_persona']);
			}
			$this->tabla('liquidacion')->set_columna_valor('id_estado',2);	//paso a liquidada
			//$this->relacion()->dump_contenido();
			$this->guardar();
		}else{
			throw new toba_error_usuario("Solo se pueden liquidar Liquidaciones con estado: PENDIENTE LIQUIDACION");
		}
	}
	function cerrar(){
		$this->tabla('liquidacion')->set_columna_valor('id_estado',3);
		$this->guardar();
	}
	function ordenar_conceptos($conceptos){		
		uasort($conceptos, function($a, $b) {
			    if ($a['codigo'] == $b['codigo']) {
			        return 0;
			    }
			    return ($a['codigo'] < $b['codigo']) ? -1 : 1;
		});
		return $conceptos; 
	}


	function conf(){
		if( !$this->relacion()->esta_cargada() ){
			$this->pantalla()->tab('pant_recibos')->ocultar();			
		}else{
			$descripcion = $this->tabla('liquidacion')->get_columna('descripcion');
			$descripcion .= ' - Periodo: ' . $this->tabla('liquidacion')->get_columna('mes') . ' ' .
							$this->tabla('liquidacion')->get_columna('anio'); 
			$this->set_titulo($descripcion);
			//echo $descripcion;
		}
	}
	function post_configurar() {		
		if ( $this->get_estado()>1 ) {        
			//$this->dep('form_liquidacion')->set_solo_lectura();			
			$this->dep('form_ml_conceptos')->set_solo_lectura();
			$this->dep('form_ml_conceptos')->desactivar_agregado_filas();
			$this->dep('form_ml_empleados')->set_solo_lectura();
			$this->dep('form_ml_empleados')->desactivar_agregado_filas();
			$this->dep('form_ml_conceptos_recibo')->set_solo_lectura();
			$this->dep('form_ml_conceptos_recibo')->desactivar_agregado_filas();
		}
	}
	
	//-----------------------------------------------------------------------------------
	//---- form_liquidacion -------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_liquidacion(asociacion_ei_formulario $form)
	{
		$datos = $this->tabla('liquidacion')->get();
		if( !isset($datos['nro_recibo_inicial']) )
			$datos['nro_recibo_inicial'] = toba::consulta_php('liquidacion')->get_ultimo_nro_recibo()+1;					
		return $datos;
	}

	function evt__form_liquidacion__modificacion($datos)
	{
		$datos['periodo'] = $datos['anio'].'-'.$datos['mes'].'-01';
		$this->tabla('liquidacion')->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_conceptos ------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_conceptos(asociacion_ei_formulario_ml $form_ml)
	{
		//if( $this->tabla('liquidacion_conceptos')->esta_cargada() )
			//return $this->tabla('liquidacion_conceptos')->get_filas();

		if( $this->cantidad_conceptos()>0 ){
			return $this->tabla('liquidacion_conceptos')->get_filas();
		}else{
			//si es una nueva liquidacion
			if( !$this->relacion()->esta_cargada() ){					
				//si selecciono el tipo de liquidacion en la primer pantalla, traigo los concetos de ese tipo.
				$id_tipo_liquidacion = $this->tabla('liquidacion')->get_columna('id_tipo_liquidacion');
				if( isset($id_tipo_liquidacion) ){
					$where = "id_tipo_liquidacion=$id_tipo_liquidacion";
					return toba::consulta_php('liquidacion')->get_conceptos_nueva_liquidacion($where,"codigo::int");
				}
			}			
		}
	}

	function evt__form_ml_conceptos__modificacion($datos)
	{
		$this->tabla('liquidacion_conceptos')->procesar_filas($datos);		
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_empleados ------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_empleados(asociacion_ei_formulario_ml $form_ml)
	{
		if( $this->cantidad_empleados()>0 ){
			return $this->tabla('recibos')->get_filas();
		}else{
			//si es una nueva liquidacion
			if( !$this->relacion()->esta_cargada() ){					
				//si no hay empleados cargados, traigo a todos los activos
				return toba::consulta_php('liquidacion')->get_empleados_nueva_liquidacion("activo","apellido, nombre");	
			}			
		}
	}

	function evt__form_ml_empleados__modificacion($datos)
	{
		$this->tabla('recibos')->procesar_filas($datos);
	}

	
//-----------------------------------------------------------------------------------
//---- Pantalla Recibos -------------------------------------------------------------
//-----------------------------------------------------------------------------------

	
	
	//-----------------------------------------------------------------------------------
	//---- cuadro_recibos ---------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro_recibos(asociacion_ei_cuadro $cuadro)
	{		
		return $this->tabla('recibos')->get_filas();
	}

	function evt__cuadro_recibos__seleccion($seleccion)
	{
		$this->tabla('recibos')->set_cursor($seleccion);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_conceptos_recibo -----------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_conceptos_recibo(asociacion_ei_formulario_ml $form_ml)
	{
		if( $this->tabla('recibos')->hay_cursor() ){
			$datos = $this->tabla('recibos_conceptos')->get_filas();
			return $this->ordenar_conceptos($datos);
		}
	}

	function evt__form_ml_conceptos_recibo__modificacion($datos)
	{
		if( $this->tabla('recibos')->hay_cursor() )
			$this->tabla('recibos_conceptos')->procesar_filas($datos);
	}

	function extender_objeto_js(){
		if($this->get_id_pantalla()=='pant_recibos'){
			$form_ml_conceptos_recibo = $this->dep('form_ml_conceptos_recibo')->get_id_objeto_js();
			if( !$this->tabla('recibos')->hay_cursor() ){				
				echo "$form_ml_conceptos_recibo.ocultar();";
			}else{
				echo "$form_ml_conceptos_recibo.mostrar();";
			}			
		}

		//pongo los select desabilitados con ancho 100%
		echo "
		$('select').each(function(){
			var attr = $(this).attr('disabled');
		
			if (typeof attr !== typeof undefined && attr !== false) {	
				$(this).css('width','100%');
			}
		});
			";	
		
		
	}

}
?>