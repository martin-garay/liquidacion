<?php 
include_once 'comunes.php';

class personas extends comunes
{
	function get_personas($where=null, $order_by=null){
		return $this->get_generico("v_personas",$where,$order_by);
	}
	function get_tipos_personas($where=null, $order_by=null){
		return $this->get_generico('tipo_persona', $where, $order_by);
	}
	function get_grupos_sanguineos($where=null, $order_by=null){
		return $this->get_generico("grupos_sanguineos",$where,$order_by);
	}
	function get_profesiones($where=null, $order_by=null){
		return $this->get_generico("profesiones",$where,$order_by);
	}
	function get_personas_nueva_planilla_periodo($where=null, $order_by=null){
		$sql = "SELECT *,id as id_persona,'A' as apex_ei_analisis_fila FROM v_personas";
		return $this->get_generico_sql($sql,$where,$order_by);
	}
	function get_historico_sueldo_basico($where=null, $order_by=null){
		return $this->get_generico('historico_sueldo_basico',$where,$order_by);	
	}
}
?>