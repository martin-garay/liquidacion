<?php 
include_once 'comunes.php';

class liquidacion extends comunes
{
	function get_liquidaciones($where=null, $order_by=null){
		return $this->get_generico('v_liquidaciones',$where,$order_by);
	}
}