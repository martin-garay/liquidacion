<?php 
include_once 'comunes.php';

class reservadas extends comunes
{
	function get_reservadas_empleado($id_persona){
		
		$sql = "SELECT * FROM test.reservadas";
		$reservadas = toba::db()->consultar($sql);
		$calculadas = array();

		foreach ($reservadas as $key => $value) {
			$query = str_replace("{ID_PERSONA}", $id_persona, $value['query']);			
			$datos = toba::db()->consultar($query);
			$calculadas[ $value['nombre'] ] = $datos[0]['resultado'];
		}
		return $calculadas;       
	}	
}