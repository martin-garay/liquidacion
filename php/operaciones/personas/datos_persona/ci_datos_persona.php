<?php
class ci_datos_persona extends asociacion_ci
{

	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function conf(){
		if( $this->relacion()->esta_cargada() ){
			$descripcion = 'Legajo: ' . $this->tabla('personas')->get_columna('legajo') . ' - ';
			$descripcion .= $this->tabla('personas')->get_columna('nro_documento') . ' ' .
							$this->tabla('personas')->get_columna('apellido').' '. $this->tabla('personas')->get_columna('nombre'); 
			$this->set_titulo($descripcion);	
		}		
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

	//-----------------------------------------------------------------------------------
	//---- form_ml_conceptos ------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_conceptos(asociacion_ei_formulario_ml $form_ml)
	{
		if( $this->relacion()->tabla("personas_conceptos")->esta_cargada() )
			return $this->relacion()->tabla("personas_conceptos")->get_filas();
	}

	function evt__form_ml_conceptos__modificacion($datos)
	{
		$this->relacion()->tabla("personas_conceptos")->procesar_filas($datos);
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
		
		$this->dep('form_ml_tareas')->vista_pdf($salida);
		
	}
	function get_datos_generales(){
		return $this->tabla('personas')->get();
	}
	/* ------------------------------- FIN API --------------------------------- */	
	

    function vista_jasperreports(toba_vista_jasperreports $report)
    {           	
        $persona = $this->tabla("personas")->get();
		$nombre = 'legajo_' . $persona['legajo'] . '.pdf';
    	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/datos_persona.jasper');
		$report->set_parametro('id_persona','E',$persona['id']);			               
        $report->set_parametro('proyecto_path','S',toba::proyecto()->get_path());
        
        $report->set_nombre_archivo($nombre);
        $report->set_tipo_descarga('browser');  
        $db = toba::db('asociacion','asociacion');
        $report->set_conexion($db);
        		
	}
	
}
?>