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
		try {
			if( $this->cantidad_empleados()>0 && $this->cantidad_conceptos()>0 ){
				$this->relacion()->sincronizar();
				toba::notificacion()->info('Se grabo correctamente');
			}
			else{								
				throw new toba_error_usuario("No se seleccionaron personas o conceptos");				
			}
		} catch (toba_error_db $e) {
			toba::notificacion()->error('Error al grabar <br>'.$e->get_mensaje_motor());
		}
	}
	function desactivar_edicion(){
		$this->desactivar_edicion = true;
	}
	function conf(){
		if( !$this->relacion()->esta_cargada() ){
			$this->pantalla()->tab('pant_recibos')->ocultar();
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
		//if( $this->tabla('liquidacion')->esta_cargada() )
			return $this->tabla('liquidacion')->get();
	}

	function evt__form_liquidacion__modificacion($datos)
	{
		$datos['periodo'] = $datos['anio_periodo'].'-'.$datos['mes_periodo'].'-01';
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
					return toba::consulta_php('liquidacion')->get_conceptos_nueva_liquidacion($where,"codigo");
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

	function liquidar(){		

		//verifico que el estado sea PENDIENTE LIQUIDACION
		if( $this->tabla('liquidacion')->get_columna('id_estado')==1 ){			
			
			$id_liquidacion = $this->tabla('liquidacion')->get_columna('id');
			$liquidador = new LiquidadorNuevo($id_liquidacion);			

			Logger::titulo('Liquidacion '.$id_liquidacion);
			//recorro cada recibo
			$recibos = $this->tabla('recibos')->get_filas(null, true);		
			foreach( $recibos as $key => $recibo ) {
				$this->tabla('recibos')->set_cursor( $key );
				$recibo = $this->tabla('recibos')->get();	//por las dudas
				
				$liquidador->nuevo_recibo($recibo['id_persona']);								//se cargan las reservadas del empleado
				Logger::separador('Generando recibo '.$recibo['id'].' persona '.$recibo['id_persona']);

				$conceptos = $this->tabla('recibos_conceptos')->get_filas(null, true);
				$conceptos_ordenados = $this->ordenar_conceptos($conceptos);				
				
				//traigo los conceptos del recibo ordenados por codigo ascendente				
				//$dt_busqueda = $this->tabla('recibos_conceptos')->nueva_busqueda();
				//$dt_busqueda->set_condicion('id_recibo','===',$recibo['id']);
				//$dt_busqueda->set_columnas_orden(array('codigo' => SORT_ASC)); //$dt_busqueda->set_padre('recibos',$key);			
				//$conceptos = $dt_busqueda->buscar_filas();

				foreach ($conceptos_ordenados as $key2 => $variable) {
					$this->tabla('recibos_conceptos')->set_cursor($key2);					
					$concepto = $this->tabla('recibos_conceptos')->get();

					//si el usuario le puso un valor al concepto le dejo ese, sino lo calcula el liquidador
					if( !isset($concepto['importe']) ){						
						$concepto['importe'] = $liquidador->calcular_concepto($concepto['codigo'], $concepto['formula']);
						$this->tabla('recibos_conceptos')->set($concepto);					
					}
					Logger::grabar($concepto['codigo'].'='.$concepto['importe'],Logger::INFO);
				}
				Logger::separador('Fin recibo persona '.$recibo['id_persona']);
			}
			$this->tabla('liquidacion')->set_columna_valor('id_estado',2);	//paso a liquidada
			//$this->relacion()->dump_contenido();
			$this->guardar();					
		}else{
			throw new toba_error_usuario("Solo se pueden liquidar Liquidaciones con estado: PENDIENTE LIQUIDACION");
		}
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
		if( $this->tabla('recibos')->hay_cursor() )
			return $this->tabla('recibos_conceptos')->get_filas();
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
		
		
	}

}
?>