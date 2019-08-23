<?php 
include_once 'comunes.php';

class liquidacion extends comunes
{
	function get_liquidaciones($where=null, $order_by=null){
		return $this->get_generico('v_liquidaciones',$where,$order_by);
	}
	function get_recibos($where=null, $order_by=null){
		return $this->get_generico('v_recibos',$where,$order_by);
	}
	function get_empleados_nueva_liquidacion($where=null, $order_by=null){
		$sql = "SELECT id as id_persona,'A' as apex_ei_analisis_fila FROM v_personas";
		return $this->get_generico_sql($sql,$where,$order_by);
	}
	function get_conceptos_nueva_liquidacion($where=null, $order_by=null){
		$sql = "SELECT id_concepto,valor_fijo,'A' as apex_ei_analisis_fila FROM v_tipo_liquidacion_conceptos";
		return $this->get_generico_sql($sql,$where,$order_by);
	}
	//devuelve la cabecera de la tabla periodos.
	function get_periodos($where=null, $order_by=null){
		return $this->get_generico('periodos',$where,$order_by);
	}
	function get_tabla_ganancias_cabecera($where=null, $order_by=null){
		return $this->get_generico('tabla_ganancias',$where,$order_by);	
	}
	function get_tabla_ganancias_detalle($where=null, $order_by=null){
		return $this->get_generico('tabla_ganancias_detalle',$where,$order_by);	
	}
}