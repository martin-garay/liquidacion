<?php
class form_js extends asociacion_ei_formulario
{

	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		//---- Procesamiento de EFs --------------------------------
		{$this->objeto_js}.ef('periodo').ocultar();
		
		{$this->objeto_js}.evt__anio__procesar = function(es_inicial)
		{
			this.actualizar_periodo();			
		}
		
		{$this->objeto_js}.evt__mes__procesar = function(es_inicial)
		{
			this.actualizar_periodo();
		}

		{$this->objeto_js}.actualizar_periodo = function(){
			if( this.ef('anio').tiene_estado() && this.ef('mes').tiene_estado() ){
				var anio = this.ef('anio').get_estado();
				var mes = this.ef('mes').get_estado()-1;

				this.ef('periodo').set_fecha(new Date(anio,mes,1));
			}
		}
		";
	}

}
?>