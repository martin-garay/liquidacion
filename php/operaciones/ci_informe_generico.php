<?php
#$this->get_parametro('a') => tabla
#$this->get_parametro('b') => order by

class ci_informe_generico extends asociacion_ci
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
		//$where = (isset($this->s__datos_filtro)) ? $this->dep('filtro')->get_sql_where() : null;
		if( isset($this->s__datos_filtro) ){
			$where = $this->dep('filtro')->get_sql_where();			
			$tabla = $this->get_parametro('a');
			$datos = toba::consulta_php('comunes')->get_generico($tabla,$where,$this->get_parametro('b'));
			$cuadro->set_datos($datos);	
		}		
	}	
	
}
?>