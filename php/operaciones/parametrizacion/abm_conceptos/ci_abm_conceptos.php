<?php
#$this->get_parametro('a') => tabla
#$this->get_parametro('b') => order by
#$this->get_parametro('c') => vista para cargar el cuadro , si no se pasa se toma 'a'
class ci_abm_conceptos extends asociacion_ci
{
	protected $s__datos_filtro;

	//-----------------------------------------------------------------------------------
	//---- filtro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__filtro(asociacion_ei_filtro $filtro)
	{
		if(isset($this->s__datos_filtro)){
			$filtro->set_datos($this->s__datos_filtro);
		}
	}

	function evt__filtro__filtrar($datos)
	{
		$this->s__datos_filtro = $datos;
	}

	function evt__filtro__cancelar()
	{
		unset($this->s__datos_filtro);
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		$where = (isset($this->s__datos_filtro)) ? $this->dep('filtro')->get_sql_where() : '';
		$tabla = ( null !== $this->get_parametro('c') ) ? $this->get_parametro('c')	: $this->get_parametro('a');	
		$datos = toba::consulta_php('comunes')->get_generico($tabla,$where,$this->get_parametro('b'));
		$cuadro->set_datos($datos);
	}

	function evt__cuadro__seleccion($seleccion)
	{
		$this->dep('datos')->cargar($seleccion);
		$this->set_pantalla("pant_edicion");
	}

	function evt__cuadro__eliminar($seleccion)
	{
		$this->dep('datos')->cargar($seleccion);
		try{
            $this->dep('datos')->eliminar_todo();
            $this->dep('datos')->sincronizar();
		}catch(toba_error_db $e){
			if($e->get_sqlstate()=="db_23503"){
				toba::notificacion()->agregar('ATENCION! El registro esta siendo utilizado');
            }else{
				toba::notificacion()->agregar('ERROR! El registro No puede eliminarse');
            }
		}
        $this->dep('datos')->resetear();
	}

	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if($this->dep('datos')->esta_cargada()){
			$form->set_datos($this->dep('datos')->get());
		}
	}
	function evt__form__modificacion($datos)
	{
		$this->dep('datos')->set($datos);		
	}

	function evt__cancelar()
	{
		$this->dep('datos')->resetear();
		$this->set_pantalla('pant_inicial');
	}

	function evt__nuevo(){
		$this->dep('datos')->resetear();		
		$this->set_pantalla('pant_edicion');
	}
	function evt__procesar(){	
		$this->dep('datos')->sincronizar();
		$this->dep('datos')->resetear();
		$this->set_pantalla("pant_inicial");
	}

	//para cargar la lista de palabras reservadas
	function get_lista_reservadas(){
		$sql = "SELECT *, ' '||nombre||' ' as codigo, nombre||' - '||descripcion as descripcion FROM sistema.reservadas ORDER BY nombre";
		return toba::db()->consultar($sql);
	}

	//para cargar la lista de conceptos
	function get_lista_conceptos(){
		$sql = "SELECT ' c'||codigo||' ' as codigo,codigo||' - '||descripcion as descripcion FROM conceptos ORDER BY codigo asc";
		return toba::db()->consultar($sql);
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

}
?>