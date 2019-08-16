<?php
class ci_datos_persona extends asociacion_ci
{

	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	//-----------------------------------------------------------------------------------
	//---- form_persona ------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_persona(asociacion_ei_formulario $form)
	{        
		return $this->relacion()->tabla("personas")->get();    
	}
	function evt__form_persona__modificacion($datos)
	{        
		$this->relacion()->tabla("personas")->set($datos);        
	}
	
	//-----------------------------------------------------------------------------------
	//---- form_ml_tareas ---------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_tareas(asociacion_ei_formulario_ml $form_ml)
	{
		if( $this->relacion()->tabla("personas_tareas")->esta_cargada() )
			return $this->relacion()->tabla("personas_tareas")->get_filas();
	}

	function evt__form_ml_tareas__modificacion($datos)
	{
		$this->relacion()->tabla("personas_tareas")->procesar_filas($datos);	
	}

/* --------------------------------------------------------------------------- */
/* --------------------------- API para Consumidores -------------------------- */
/* --------------------------------------------------------------------------- */

	function guardar(){
		try {
			$this->relacion()->sincronizar();
		} catch (toba_error_db $e) {
			toba::notificacion()->error("Error. No se pueden guardar los datos");
		}
	}
	function borrar(){        
		try{
			$this->dep('datos')->eliminar_todo();
			$this->dep('datos')->sincronizar();
		}catch(toba_error_db $e){
			if($e->get_sqlstate()=="db_23503"){
				toba::notificacion()->agregar('ATENCION! El registro esta siendo utilizado');
			}else{
				toba::notificacion()->agregar('ERROR! El registro No puede eliminarse');
			}
		}
		$this->dep('datos')->resetear();
	}
	function imprimir(toba_vista_pdf $salida){
		$salida->subtitulo('Datos Generales');
		$this->dep('form_persona')->vista_pdf($salida);

		$salida->subtitulo('Datos Actuales');
		$this->dep('form_datos_actuales')->vista_pdf($salida);

		$salida->subtitulo('Datos Salud');
		$this->dep('form_salud')->vista_pdf($salida);

		$salida->subtitulo('Datos Laborales');
		$this->dep('form_laboral')->vista_pdf($salida);
		
		$this->dep('form_ml_tareas')->vista_pdf($salida);
		
	}
	function get_datos_generales(){
		return $this->tabla('personas')->get();
	}
	/* ------------------------------- FIN API --------------------------------- */	

}
?>