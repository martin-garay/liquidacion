<?php 
include_once 'comunes.php';

class reservadas extends comunes
{
	function get_reservadas($where=null, $order_by=null){
		$sql = "SELECT *, nombre as codigo, nombre||' - '||descripcion as descripcion FROM sistema.reservadas";
		return $this->get_generico_sql($sql,$where,$order_by);
		//return $this->get_generico('sistema.reservadas',$where,$order_by);
	}
	function get_reservadas_liquidacion(){

	}

	
	function generar_reservadas($id_persona,$id_liquidacion){
		//verifico que exista la liquidacion
		
		//$sql = "SELECT *,lower(nombre) as clave FROM test.reservadas";
		$sql = "SELECT *,lower(nombre) as clave FROM sistema.reservadas";
		$reservadas = toba::db()->consultar($sql);
		$calculadas = array();

		foreach ($reservadas as $key => $value) {
			$query = str_replace("{ID_PERSONA}", $id_persona, $value['query']);
			$query = str_replace("{ID_LIQUIDACION}", $id_liquidacion, $query);			
			$datos = toba::db()->consultar($query);			
			if(isset($datos[0]['resultado'])){
				$clave = strtolower($value['nombre']);
				$calculadas[ $clave ] = $datos[0]['resultado'];				
			}else{
				$err = '<br>No se pudo crear '.$value['nombre'];
				throw new Exception("Error al cargar palabras reservadas".$err, 1);				
			}			
		}	
		return $calculadas;       
	}
	function get_conceptos($where=null, $order_by=null){	
		return $this->get_generico('conceptos',$where,$order_by);
	}
	function get_conceptos_lista($where=null, $order_by=null){
		$sql = "SELECT ' c'||codigo||' ' as codigo,descripcion FROM conceptos";
		return $this->get_generico_sql($sql,$where,$order_by);
		//return $this->get_generico('conceptos',$where,$order_by);
	}
	function get_tipos_reservadas($where=null, $order_by=null){
		return $this->get_generico('sistema.tipos_reservadas',$where,$order_by);
	}
	function get_tipos_datos($where=null, $order_by=null){
		return $this->get_generico('sistema.tipos_datos',$where,$order_by);
	}

	function get_funciones_liquidador(){
		$funciones = [		
			['codigo' => 'si(  ,  ,  )'			, 'descripcion' => 'si'],
			['codigo' => 'igual(  ,  )'			, 'descripcion' => 'igual'],
			['codigo' => 'distinto(  ,  )'		, 'descripcion' => 'distinto'],
			['codigo' => 'mayor(  ,  )'			, 'descripcion' => 'mayor'],
			['codigo' => 'menor(  ,  )'			, 'descripcion' => 'menor'],
			['codigo' => 'mayor_igual(  ,  )'	, 'descripcion'	=> 'mayor_igual'],
			['codigo' => 'menor_igual(  ,  )'	, 'descripcion'	=> 'menor_igual'],
			['codigo' => 'y(  ,  )'				, 'descripcion' => 'y'],
			['codigo' => 'o(  ,  )'				, 'descripcion' => 'o'],
			['codigo' => 'entre(  ,  ,  ,)'		, 'descripcion' => 'entre'],
			['codigo' => 'fuera(  ,  ,  ,)'		, 'descripcion' => 'fuera'],
			['codigo' => 'max(  ,  )'			, 'descripcion' => 'max'],
			['codigo' => 'min(  ,  )'			, 'descripcion' => 'min'],
			['codigo' => 'redondear(  )'		, 'descripcion' => 'redondear'],
		];
		return $funciones;
	}
}