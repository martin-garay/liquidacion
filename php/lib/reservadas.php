<?php 
include_once 'comunes.php';

class reservadas extends comunes
{
	function get_reservadas($where=null, $order_by=null){
		$sql = "SELECT *, nombre as codigo, nombre||'-'||descripcion as descripcion FROM test.reservadas";
		return $this->get_generico_sql($sql,$where,$order_by);
		//return $this->get_generico('test.reservadas',$where,$order_by);
	}

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
	function get_conceptos($where=null, $order_by=null){
		$sql = "SELECT '['||codigo||']' as codigo, codigo||'-'||descripcion as descripcion FROM conceptos";
		return $this->get_generico_sql($sql,$where,$order_by);
	}
}