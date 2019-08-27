<?php
#$this->get_parametro('a') => tabla
#$this->get_parametro('b') => order by
#$this->get_parametro('c') => vista para cargar el cuadro , si no se pasa se toma 'a'
class ci_datos_conceptos extends asociacion_ci
{
	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function cargar($seleccion){
		$this->relacion()->cargar($seleccion);
	}
	function resetear(){
		$this->relacion()->resetear();	
	}
	function guardar(){
		try {
			$this->relacion()->sincronizar();
		} catch (toba_error_db $e) {
			toba::notificacion()->agregar('ERROR! No se pudo guardar');
		}
	}
	function eliminar($seleccion){
		$this->cargar($seleccion);
		try{
            $this->relacion()->eliminar_todo();
            $this->relacion()->sincronizar();
		}catch(toba_error_db $e){
			if($e->get_sqlstate()=="db_23503"){
				toba::notificacion()->agregar('ATENCION! El registro esta siendo utilizado');
            }else{
				toba::notificacion()->agregar('ERROR! El registro No puede eliminarse');
            }
		}
        $this->resetear();
	}
	
	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if($this->relacion()->esta_cargada()){
			$form->set_datos($this->tabla('concepto')->get());
		}
	}
	function evt__form__modificacion($datos)
	{
		$this->tabla('concepto')->set($datos);		
	}
	//para cargar la lista de acumuladores
	function get_lista_acumuladores(){
		$sql = "SELECT *, ' '||nombre||' ' as codigo, nombre||' - '||descripcion as descripcion FROM acumuladores ORDER BY nombre";
		return toba::db()->consultar($sql);
	}

	//para cargar la lista de palabras reservadas
	function get_lista_reservadas(){
		$sql = "SELECT *, ' '||nombre||' ' as codigo, nombre||' - '||descripcion as descripcion FROM sistema.reservadas ORDER BY nombre";
		return toba::db()->consultar($sql);
	}

	//para cargar la lista de conceptos
	function get_lista_conceptos(){
		$sql = "SELECT ' c'||codigo||' ' as codigo,codigo||' - '||descripcion as descripcion FROM conceptos ORDER BY codigo::int asc";
		return toba::db()->consultar($sql);
	}

	//para cargar la lista de tablas
	function get_lista_tablas(){
		$lista = array();
		$sql = "SELECT * FROM tabla ORDER BY descripcion";
		$tablas = toba::db()->consultar($sql);		
		foreach ($tablas as $key => $tabla) {
			$codigo = 'tabla("' . $tabla['clave'] . '")';			
			$lista[] = array('codigo'=>$codigo, 'descripcion'=>$tabla['descripcion'] . '. Valor Tabla');
			$codigo = 'tope("' . $tabla['clave'] . '")';
			$lista[] = array('codigo'=>$codigo, 'descripcion'=>$tabla['descripcion'] . '. Tope Tabla');
			$codigo = 'informado("' . $tabla['clave'] . '")';
			$lista[] = array('codigo'=>$codigo, 'descripcion'=>$tabla['descripcion'] . '. Valor Informado');
		}		
		return $lista;
	}

	//para cargar la lista de funciones definidas en Matex
	function get_lista_funciones(){
		$funciones = [		
			['codigo' => ' si(  ,  ,  ) '			, 'descripcion' => 'si'],
			['codigo' => ' igual(  ,  ) '			, 'descripcion' => 'igual'],
			['codigo' => ' distinto(  ,  ) '		, 'descripcion' => 'distinto'],
			['codigo' => ' mayor(  ,  ) '			, 'descripcion' => 'mayor'],
			['codigo' => ' menor(  ,  ) '			, 'descripcion' => 'menor'],
			['codigo' => ' mayor_igual(  ,  ) '		, 'descripcion'	=> 'mayor_igual'],
			['codigo' => ' menor_igual(  ,  ) '		, 'descripcion'	=> 'menor_igual'],
			['codigo' => ' y(  ,  ) '				, 'descripcion' => 'y'],
			['codigo' => ' o(  ,  ) '				, 'descripcion' => 'o'],
			['codigo' => ' entre(  ,  ,  ,) '		, 'descripcion' => 'entre'],
			['codigo' => ' fuera(  ,  ,  ,) '		, 'descripcion' => 'fuera'],
			['codigo' => ' max(  ,  ) '				, 'descripcion' => 'max'],
			['codigo' => ' min(  ,  ) '				, 'descripcion' => 'min'],
			['codigo' => ' redondear(  ) '			, 'descripcion' => 'redondear'],
		];
		return $funciones;
	}

	/*	para validar la function cargo una instancia de matex con todas las reservadas y los concetos con valor 1 asi 
		el Matex->exceute() encuentra las variables y si me devuelve un valor es por que la expresion es correcta.

		Sino puede ser que tire error por que no use correctamente las funciones (que esta bien)
		o algun error de sintaxis		
	*/
	function ejecutar_formula($formula){
		$evaluator = new Evaluator();
		$evaluator->functions = $funciones;
		$evaluator->variables = 

		$valor_concepto = $evaluator->execute($formula);

	}

	function ajax__validar(){

	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_personas -------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_personas(asociacion_ei_formulario_ml $form_ml)
	{
		return $this->tabla('concepto_personas')->get_filas();
	}

	function evt__form_ml_personas__modificacion($datos)
	{
		$this->tabla('concepto_personas')->procesar_filas($datos);
	}

}
?>