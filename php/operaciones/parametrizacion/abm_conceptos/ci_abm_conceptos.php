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
		$this->dep('datos_conceptos')->cargar($seleccion);
		$this->set_pantalla("pant_edicion");
	}

	function evt__cuadro__eliminar($seleccion)
	{
		$this->dep('datos_conceptos')->eliminar($seleccion);		
	}

	function evt__cancelar()
	{
		$this->dep('datos_conceptos')->resetear();
		$this->set_pantalla('pant_inicial');
	}

	function evt__nuevo(){
		$this->dep('datos_conceptos')->resetear();		
		$this->set_pantalla('pant_edicion');
	}
	function evt__procesar(){	
		$this->dep('datos_conceptos')->guardar();
		$this->dep('datos_conceptos')->resetear();
		$this->set_pantalla("pant_inicial");
	}
	
}
?>