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
		return $this->get_generico('v_tabla_ganancias_detalle',$where,$order_by);	
	}
	function get_tabla_detalle($where=null, $order_by=null){
		return $this->get_generico('v_tabla_detalle',$where,$order_by);	
	}
	function get_tabla_personas($where=null, $order_by=null){
		return $this->get_generico('v_tabla_personas',$where,$order_by);	
	}
	function get_valor_tabla($id_tabla, $periodo){
		$datos = $this->get_generico('v_tabla_detalle',"clave='$id_tabla' AND periodo='$periodo'");
		//return (isset($datos[0]['valor'])) ? $datos[0]['valor'] : 0;
		return (isset($datos[0]['valor'])) ? $datos[0]['valor'] : null;
	}
	function get_tope_tabla($id_tabla, $periodo){
		$datos = $this->get_generico('v_tabla_detalle',"clave='$id_tabla' AND periodo='$periodo'");
		//return (isset($datos[0]['tope'])) ? $datos[0]['tope'] : 0;
		return (isset($datos[0]['tope'])) ? $datos[0]['tope'] : null;
	}
	function get_periodo_liquidacion($id_liquidacion){
		$sql = "SELECT periodo FROM liquidaciones WHERE id=$id_liquidacion";
		$datos = toba::db()->consultar($sql);
		if(isset($datos[0]['periodo']))
			return $datos[0]['periodo'];
		else
			throw new Exception("No se encontro el periodo de la liquidacion", 1);		
	}
	//Trae el valor que informo el empleado en el periodo. Sino informo nada devuelve 0
	function get_deduccion_informada($id_tabla, $periodo, $id_persona){
		$sql = "SELECT valor FROM v_tabla_personas WHERE clave='$id_tabla' and periodo='$periodo' and id_persona='$id_persona'";
		try {
			$datos = toba::db()->consultar($sql);
		} catch (toba_error_db $e) {
			throw new toba_error_db("Error al traer la deduccion informada por el empleado", 1);			
		}
		return (isset($datos[0]['valor'])) ? $datos[0]['valor'] : 0;			 
	}
	function get_detalle_nueva_tabla_deducciones(){
		$anio = toba::consulta_php('parametrizacion')->get_anio_actual();
		$filas = array();
		for ($mes=1; $mes <=12 ; $mes++) { 
			$filas[] = array('mes'=>$mes, 'anio'=>$anio, 'apex_ei_analisis_fila'=>'A');
		}
		return $filas;
	}

	//function get_tabla_ganancias_detalle($where=null, $order_by=null){
	//	return $this->get_generico('v_tabla_ganancias_detalle',$where,$order_by);	
	//}
	//Devuelve el valor de la tabla de ganancias segun el rango que caiga
	function get_valor_tabla_ganancias($valor, $periodo, $id_persona){
		
	}
	function get_ultimo_nro_recibo(){
		$sql = "SELECT COALESCE(max(nro_recibo),0) as nro_recibo FROM recibos";
		$datos = toba::db()->consultar($sql);
		return (isset($datos[0]['nro_recibo'])) ? $datos[0]['nro_recibo'] : 0;
	}
	function get_historico_liquidaciones($where=null, $order_by=null){
		return $this->get_generico('historico_liquidaciones',$where,$order_by);	
	}
	function get_historico_recibos($where=null, $order_by=null){
		return $this->get_generico('historico_recibos',$where,$order_by);	
	}
	/*
		Indica si se cargo la hoja inicial del libro de sueldos
	*/
	function tiene_hoja_inicio($id_liquidacion){
		$datos = self::get_historico_liquidaciones("id=$id_liquidacion AND hoja_inicial is not null");
		return (count($datos)>0);
	}	
}