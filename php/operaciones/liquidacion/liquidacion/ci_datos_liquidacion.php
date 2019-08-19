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

	function post_configurar() {
		if ($this->desactivar_edicion) {
            //FB::info("Se desactivan los componentes");
			// $this->dep('salud_disc')->set_solo_lectura();
			// $this->dep('salud_disc')->desactivar_agregado_filas();			
		}
	}
	function conf(){
		if( !$this->relacion()->esta_cargada() ){
			$this->pantalla()->tab('pant_recibos')->ocultar();
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
			return $this->tabla('liquidacion_conceptos')->get_filas();
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
				return toba::consulta_php('liquidacion')->get_empleados_nueva_liquidacion(null,"apellido, nombre");	
			}			
		}
	}

	function evt__form_ml_empleados__modificacion($datos)
	{
		$this->tabla('recibos')->procesar_filas($datos);
	}

	
	//cargo los conceptos de la liquidacion a cada recibo
	// function cargar_conceptos_en_recibos(){
	// 	if( $this->cantidad_empleados()>0 && $this->cantidad_conceptos()>0 ){				
			
	// 		$recibos = $this->tabla('recibos')->get_filas(null, true);
	// 		$conceptos = $this->tabla('liquidacion_conceptos')->get_filas(null, true);
	// 		foreach ($conceptos as $key => $value) {
	// 			$conceptos[$key]['apex_ei_analisis_fila'] = 'A';
	// 		}

	// 		foreach( $recibos as $key => $recibo ) {					//recorro cada recibo				
	// 			$this->tabla('recibos')->set_cursor( $key );
	// 			$this->tabla('recibos_conceptos')->procesar_filas($conceptos);				
	// 		}
	// 	}
	// }
	function liquidar(){
		ei_arbol($this->tabla('recibos_conceptos')->get_filas());
	}
	function liquidar2(){
		//verifico que el estado sea PENDIENTE LIQUIDACION
		if( $this->tabla('liquidacion')->get_columna_valor('id_estado')==1 ){

			$id_liquidacion = $this->tabla('liquidacion')->get_columna_valor('id');
			$liquidador = new Liquidador($id_liquidacion);			

			//recorro cada recibo
			$recibos = $this->tabla('recibos')->get_filas(null, true);		
			foreach( $recibos as $key => $recibo ) {
				
				$this->tabla('recibos')->set_cursor( $key );

				//recorro cada concepto del recibo (un trigger los guarda ordenandolos por codigo)
				$conceptos = $this->tabla('recibos_conceptos')->get_filas(null, true);
				foreach ($conceptos as $key2 => $variable) {
					$this->tabla('recibos_conceptos')->set_cursor($key2);					
					$concepto = $this->tabla('recibos_conceptos')->get();
					if( !isset($concepto['valor']) )
						$concepto['valor'] = $liquidador->ejecutar_concepto();
				}

			}

			try {
				$liquidacion->liquidar();

				//guardo los valores que genero Liquidacion en la base
				// $this->tabla('recibos')->get_cantidad_filas
				// foreach ($variable as $key => $value) {
				// 	# code...
				// }


			} catch (Exception $e) {
					
			}
			

		}else{
			throw new toba_error_usuario("Solo se pueden liquidar Liquidaciones con estado: PENDIENTE LIQUIDACION");
		}
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