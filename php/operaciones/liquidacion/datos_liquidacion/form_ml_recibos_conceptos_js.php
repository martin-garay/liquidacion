<?php
class form_ml_recibos_conceptos_js extends asociacion_ei_formulario_ml
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		
		//---- Procesamiento de EFs --------------------------------
		
		{$this->objeto_js}.evt__sumar__procesar = function(es_inicial, fila)
		{
			var total_suma = 0;
			var form_suma = {$this->controlador->dep('form_suma')->objeto_js};

			var filas = this.filas()
				for (id_fila in filas) {
				if( this.ef('sumar').ir_a_fila(filas[id_fila]).chequeado() ){
					total_suma += this.ef('importe').ir_a_fila(filas[id_fila]).get_estado();				
				}			  
			}

			form_suma.ef('tota_suma').set_estado(total_suma);
		}
		";
	}

}

?>