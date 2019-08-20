<?php
class dt_recibos_conceptos extends asociacion_datos_tabla
{
	function get_descripcion_concepto($id_concepto){
		$datos = toba::consulta_php('parametrizacion')->get_conceptos("id=$id_concepto");
		$datos[0]['concepto'] = $datos[0]['descripcion'];
		return $datos[0];
	}
}

?>