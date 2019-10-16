<?php
class ci_historico_sueldo_basico extends asociacion_ci
{
	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}

	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function evt__cancelar()
	{
		$this->dep('personas')->resetear();
		$this->set_pantalla('pant_inicial');
	}

	function evt__nuevo()
	{
		$this->relacion()->resetear();
		$this->set_pantalla('pant_edicion');
	}


	function evt__procesar()
	{
		try {
			$this->relacion()->sincronizar();
			$this->relacion()->resetear();
			toba::notificacion()->info('Se guardaron los sueldos basicos');
			$this->set_pantalla('pant_inicial');
		} catch (toba_error_db $e) {
			toba::notificacion()->info('Error al grabar');
		}
	}

	function evt__restaurar()
	{
		$this->relacion()->persistidor()->desactivar_transaccion(true);
		$this->dep('personas')->persistidor()->desactivar_transaccion(true);
		toba::db()->abrir_transaccion();
		
		try {			

			//-------------------- RESTAURO LOS BASICOS -----------------------
			//datos del historico
			$personas_h = $this->tabla('detalle')->get_filas();				
			$basicos_h = array_column($personas_h, 'basico', 'id_persona');	//Devuelve un array indexado por id_persona y con el valor basico	

			//datos tabla con los datos actuales
			$this->dep('personas')->cargar();
			$personas = $this->dep('personas')->get_filas();
			foreach ($personas as $key => $persona) {
				$this->dep('personas')->set_cursor($key);
				$persona['basico'] = $basicos_h[ $persona['id'] ];
				echo $basicos_h[ $persona['id_persona'] ];
				$this->dep('personas')->set($persona);
			}
			$this->dep('personas')->sincronizar();

			//-------------------- GUARDO ESTADO ACTUAL -----------------------
			$cabecera = $this->tabla('cabecera')->get();
			$cabecera['descripcion'] = 'RESTAURACION DE SUELDOS BASICOS';
			$this->relacion()->resetear();
			$this->tabla('cabecera')->set($cabecera);
			$this->tabla('detalle')->procesar_filas($this->get_personas());
			$this->relacion()->sincronizar();

			toba::db()->cerrar_transaccion();
			toba::notificacion()->info('Se restauraron los sueldos basicos.');
			$this->set_pantalla('pant_inicial');			
		} catch (Exception $e) {
			toba::notificacion()->error('Error al restaurar los sueldos basicos.');
			toba::db()->abortar_transaccion();
		}
	}


	function conf(){
		if($this->get_id_pantalla()=='pant_edicion'){			
			if($this->relacion()->esta_cargada()){				
				$this->evento('procesar')->anular();
			}else{
				$this->evento('restaurar')->anular();
			}
		}
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		return toba::consulta_php('personas')->get_historico_sueldo_basico();
	}

	function evt__cuadro__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if($this->relacion()->esta_cargada())
			return $this->tabla('cabecera')->get();
	}

	function evt__form__modificacion($datos)
	{
		$this->tabla('cabecera')->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		//$form_ml->set_solo_lectura();	
		if($this->relacion()->esta_cargada())
			return $this->tabla('detalle')->get_filas();
		else
			return $this->get_personas();
	}

	function evt__form_ml__modificacion($datos)
	{
		$this->tabla('detalle')->procesar_filas($datos);
	}

	function get_personas(){
		$personas = toba::consulta_php('personas')->get_personas();
		$persona2 = array();
		foreach ($personas as $key => $persona) {			
			$personas2[$key] = array('id_persona'=>$persona['id'],'basico'=>$persona['basico'],'apex_ei_analisis_fila'=>'A');
		}
		return $personas2; 
	}

	function extender_objeto_js(){
		if($this->get_id_pantalla()=='pant_edicion')
			echo "
				$('select[id$=\"ef_form_2926_form_mlid_persona\"]').attr('disabled','disabled');
				$('input[id$=\"ef_form_2926_form_mlbasico\"]').attr('disabled','disabled');
			";
	}

}
?>