<?php
class ci_datos_liquidacion extends asociacion_ci
{
	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	//-----------------------------------------------------------------------------------
	//---- form_liquidacion -------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_liquidacion(asociacion_ei_formulario $form)
	{
		//if( $this->tabla('liquidacion')->esta_cargada() )
			return $this->tabla('liquidacion')->get();
	}

	function evt__form_liquidacion__modificacion($datos)
	{
		$datos['periodo'] = $datos['anio_periodo'].'-'.$datos['mes_periodo'].'-01';
		$this->tabla('liquidacion')->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_conceptos ------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_conceptos(asociacion_ei_formulario_ml $form_ml)
	{
		//if( $this->tabla('liquidacion_conceptos')->esta_cargada() )
			return $this->tabla('liquidacion_conceptos')->get_filas();
	}

	function evt__form_ml_conceptos__modificacion($datos)
	{
		$this->tabla('liquidacion_conceptos')->procesar_filas($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml_empleados ------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml_empleados(asociacion_ei_formulario_ml $form_ml)
	{
		//if( $this->tabla('recibos')->esta_cargada() )
			return $this->tabla('recibos')->get_filas();
	}

	function evt__form_ml_empleados__modificacion($datos)
	{
		$this->tabla('recibos')->procesar_filas($datos);
	}

	function cantidad_empleados(){
		return $this->tabla('recibos')->get_cantidad_filas();
	}
	function cantidad_conceptos(){
		return $this->tabla('liquidacion_conceptos')->get_cantidad_filas();	
	}
}
?>