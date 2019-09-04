<?php
class form_generar_filas_js extends asociacion_ei_formulario
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		//---- Validacion de EFs -----------------------------------
		
		{$this->objeto_js}.evt__desde__validar = function()
		{
			if( this.ef('desde').tiene_estado() && this.ef('hasta').tiene_estado()){
				this.ef('desde').set_error('El Mes Desde debe ser mayor o igual al Mes Hasta');
				return ( this.ef('desde').get_estado() <= this.ef('hasta').get_estado() );	
			}else{
				return true;	
			}
			
		}    
		{$this->objeto_js}.evt__hasta__validar = function()
		{
			if( this.ef('desde').tiene_estado() && this.ef('hasta').tiene_estado()){
				this.ef('hasta').set_error('El Mes Desde debe ser mayor o igual al Mes Hasta');
				return ( this.ef('hasta').get_estado() >= this.ef('desde').get_estado() );	
			}else{
				return true;	
			}
		}
		";
	}

}
?>