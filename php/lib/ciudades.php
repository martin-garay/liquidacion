<?php 
include_once 'comunes.php';

class ciudades extends comunes
{
	function get_ciudad_detallado($where=null, $order_by=null){		
		return $this->get_generico('v_ciudades', $where, $order_by);
	}
	function get_codigo_postal($id_ciudad){
		$datos = self::get_ciudad_detallado("id=$id_ciudad");
		return $datos[0]['cp'];
	}
	function get_provincia($id_ciudad){
		$datos = self::get_ciudad_detallado("id=$id_ciudad");
		return $datos[0]['provincia'];
	}
	function get_pais($id_ciudad){
		$datos = self::get_ciudad_detallado("id=$id_ciudad");
		return $datos[0]['pais'];
	}
	function get_provincias($where=null, $order_by=null){
		return $this->get_generico('provincias',$where, $order_by);
	}
	function get_paises($where=null, $order_by=null){
		return $this->get_generico('paises',$where, $order_by);	
	}
}

?>