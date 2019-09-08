<?php
class ci_planilla_personal extends asociacion_ci
{
	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		return $this->get_personas();			
	}

	function get_personas(){
		$this->dep('personas')->cargar();
		$personas = $this->dep('personas')->get_filas();

		uasort($personas, function($a, $b) {
			    if ($a['legajo'] == $b['legajo']) {
			        return 0;
			    }
			    return ($a['legajo'] < $b['legajo']) ? -1 : 1;
		});
		return $personas; 
	}


	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function evt__cancelar()
	{
		$this->dep('personas')->resetear();
	}

	function evt__procesar()
	{
		try {
			$this->dep('personas')->sincronizar();
			$this->dep('personas')->resetear();
			toba::notificacion()->info('Los cambios se registraron correctamente');
		} catch (toba_error_db $e) {
			toba::notificacion()->info('Error al grabar');
		}
	}

	function evt__form_ml__modificacion($datos)
	{
		$this->dep('personas')->procesar_filas($datos);
	}

	    //-----------------------------------------------------------------------------------
    //---- Exportacion ------------------------------------------------------------------
    //-----------------------------------------------------------------------------------    
    function vista_excel(toba_vista_excel $salida){
        
        //ob_clean();        
        //$salida->set_hoja_nombre('Informe');
        //$salida->set_nombre_archivo('informe.xls');
        $this->dep('form_ml')->vista_excel($salida);
    }	

}
?>