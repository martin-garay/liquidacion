<?php 
include_once 'comunes.php';

class parametrizacion extends comunes
{
	function get_anios(){
		for ($i=0; $i < 20; $i++) { 
			$datos[$i]['anio'] = $i+2019;
		}
		return $datos;
	}
	function get_meses(){		
		$datos[0]['id']  = '1'; 	$datos[0]['descripcion']  = 'Enero';
		$datos[1]['id']  = '2'; 	$datos[1]['descripcion']  = 'Febrero';
		$datos[2]['id']  = '3'; 	$datos[2]['descripcion']  = 'Marzo';
		$datos[3]['id']  = '4'; 	$datos[3]['descripcion']  = 'Abril';
		$datos[4]['id']  = '5'; 	$datos[4]['descripcion']  = 'Mayo';
		$datos[5]['id']  = '6'; 	$datos[5]['descripcion']  = 'Junio';
		$datos[6]['id']  = '7'; 	$datos[6]['descripcion']  = 'Julio';
		$datos[7]['id']  = '8'; 	$datos[7]['descripcion']  = 'Agosto';
		$datos[8]['id']  = '9'; 	$datos[8]['descripcion']  = 'Septiembre';
		$datos[9]['id']  = '10'; 	$datos[9]['descripcion']  = 'Octubre';
		$datos[10]['id'] = '11'; 	$datos[10]['descripcion'] = 'Noviembre';
		$datos[11]['id'] = '12'; 	$datos[11]['descripcion'] = 'Diciembre';
		return $datos;
	}
	function get_mes_actual(){
		return date('n') - 1;
	}
	function get_anio_actual(){
		return date("Y");
	}	
	function get_perfiles($where=null, $order_by=null){
		return $this->get_generico('perfiles',$where,$order_by);
	}	
	function get_perfiles_proyecto_en_toba(){
		$proyecto = toba::proyecto()->get_id();
		$sql = "SELECT usuario_grupo_acc as perfil FROM apex_usuario_grupo_acc WHERE proyecto='$proyecto'";
		return toba::instancia()->get_db()->consultar($sql);
	}
	function get_tipos_documentos($where=null, $order_by=null){
		return $this->get_generico('tipos_documentos',$where,$order_by);
	}
	function get_nacionalidades($where=null, $order_by=null){
		return $this->get_generico('nacionalidades',$where,$order_by);
	}
	function get_obras_sociales($where=null, $order_by=null){
		return $this->get_generico('obras_sociales',$where,$order_by);
	}
	function get_estados_civiles($where=null, $order_by=null){
		return $this->get_generico('estados_civiles',$where,$order_by);
	}
	function get_categorias($where=null, $order_by=null){
		return $this->get_generico('categorias',$where,$order_by);
	}
	function get_establecimientos($where=null, $order_by=null){
		return $this->get_generico('establecimientos',$where,$order_by);
	}
	function get_generos($where=null, $order_by=null){
		return $this->get_generico('generos',$where,$order_by);
	}
	function get_tareas($where=null, $order_by=null){
		return $this->get_generico('tareas',$where,$order_by);
	}
	function get_tipos_contratos($where=null, $order_by=null){
		return $this->get_generico('tipos_contratos',$where,$order_by);
	}
	function get_tipos_conceptos($where=null, $order_by=null){
		return $this->get_generico('tipos_conceptos',$where,$order_by);
	}
	function get_conceptos($where=null, $order_by='codigo::int asc'){
		return $this->get_generico('v_conceptos',$where,$order_by);
	}
	function get_tipos_empleadores($where=null, $order_by=null){
		return $this->get_generico('tipos_empleadores',$where,$order_by);
	}
	function get_bancos($where=null, $order_by=null){
		return $this->get_generico('bancos',$where,$order_by);
	}
	function get_tipos_liquidaciones($where=null, $order_by=null){
		return $this->get_generico('tipos_liquidaciones',$where,$order_by);
	}
	function get_tipos_liquidaciones_activas($where=null, $order_by=null){
		return $this->get_tipos_liquidaciones('activo');
	}
	function get_acumuladores($where=null, $order_by=null){
		return $this->get_generico('v_acumuladores',$where,$order_by);
	}
	function get_tablas($where=null, $order_by=null){
		return $this->get_generico('tabla',$where,$order_by);
	}
	function get_regimenes($where=null, $order_by=null){
		return $this->get_generico('regimenes',$where,$order_by);
	}
}
