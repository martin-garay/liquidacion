<?php
class dt_recibos extends asociacion_datos_tabla
{
	function get_descripcion_persona($id_persona){
		$datos = toba::consulta_php('personas')->get_personas("id=$id_persona");
		return $datos[0];
	}	
}

?>