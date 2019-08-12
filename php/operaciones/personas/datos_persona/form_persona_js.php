<?php
class form_persona_js extends asociacion_ei_formulario
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		//---- Validacion de EFs -----------------------------------
		
		{$this->objeto_js}.evt__dni__validar = function()
		{			
			if(this.ef('dni').tiene_estado()){
				var dni = this.ef('dni').get_estado();
				var id_tipo_documento = this.ef('id_tipo_documento').get_estado();

				if(id_tipo_documento==1){
					console.log(esNumerico(dni));					
					console.log(dni.length);
					if( !esNumerico(dni) || (dni.length<6 || dni.length>8) ){
						this.ef('dni').set_error('El dni no es correcto');
						return false;
					}else{
						return true;
					}
				}else{
					return true;
				}
			}else{
				return true;
			}
			
		}

		var esNumerico = function(cadena){
			return /^\d+$/.test(cadena);
		}
		";
	}

}
?>