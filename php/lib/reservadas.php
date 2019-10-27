<?php 
include_once 'comunes.php';

class reservadas extends comunes
{

	function get_reservadas($where=null, $order_by=null){
		$sql = "SELECT *, nombre as codigo, nombre||' - '||descripcion as descripcion FROM sistema.reservadas";
		return $this->get_generico_sql($sql,$where,$order_by);
		//return $this->get_generico('sistema.reservadas',$where,$order_by);
	}

	function get_ids_reservadas($where){
		$sql = "SELECT id FROM sistema.reservadas";
		$reservadas = $this->get_generico_sql($sql,$where);
		return array_column($reservadas, 'id');
	}
	function generar_reservadas_empleados($id_liquidacion,$id_persona){
		return $this->generar_reservadas($id_liquidacion,$id_persona,'id_tipo_reservada=2');
	}

	function generar_reservadas_liquidacion($id_liquidacion){
		return $this->generar_reservadas($id_liquidacion,null,'id_tipo_reservada=1');
	}
	function generar_reservadas($id_liquidacion,$id_persona=null,$where=null){		
		$ids_reservadas = $this->get_ids_reservadas($where);
		$calculadas = array();

		foreach ($ids_reservadas as $key => $id) {			
			$reservada = new Reservada($id);
			$reservada->setIdLiquidacion($id_liquidacion);
			$reservada->setIdPersona($id_persona);
			
			$valor = $reservada->calcular_valor();	
			$nombre = $reservada->nombre;
			$calculadas[$nombre] = $valor;
		}			
		return $calculadas;       
	}
	
	function get_conceptos($where=null, $order_by=null){	
		return $this->get_generico('conceptos',$where,$order_by);
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
			['codigo' => 'sin_proporcional(  )'	, 'descripcion' => 'sin_proporcional'],
			['codigo' => 'historico( nombre, anio, mes)'	, 'descripcion' => 'historico'],
		];
		return $funciones;
	}

	/*----------------------------------------------------------------------------*/
	function generar_reservadas_liquidacion_back($id_liquidacion){
		//traigo solo las de la liquidacion(no del empleado)
		$sql = "SELECT *,lower(nombre) as clave FROM sistema.reservadas WHERE id_tipo_reservada=1";	
		$reservadas = toba::db()->consultar($sql);
		$calculadas = array();
		foreach ($reservadas as $key => $value) {			
			$query = str_replace("{ID_LIQUIDACION}", $id_liquidacion, $value['query']);
			try {
				$datos = toba::db()->consultar($query);			
				if(isset($datos[0]['resultado'])){				
					$calculadas[ $value['nombre'] ] = $datos[0]['resultado'];				
				}else{
					$err = '<br>No se pudo crear '.$value['nombre'];
					throw new toba_error_db("Error al cargar palabras reservadas".$err, 1);				
				}	
			} catch (toba_error_db $e) {
				toba::notificacion()->error('error al genenerar reservada '.$value['nombre']);
			}					
		}	

		return $calculadas;       	
	}
}