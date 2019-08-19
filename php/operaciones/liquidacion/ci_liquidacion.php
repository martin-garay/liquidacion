<?php
class ci_liquidacion extends asociacion_ci
{
	protected $s__filtro;

	function relacion(){
		return $this->dep('datos_liquidacion')->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function ci_hijo(){
		return $this->dep('datos_liquidacion');
	}

	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	//pasa una liquidacion de estado PENDIENTE LIQUIDACON a LIQUIDADA
	function evt__liquidar(){
		$this->ci_hijo()->liquidar();
	}

	function evt__procesar()
	{
		$this->ci_hijo()->crear();
		$this->set_pantalla('pant_inicial');	
	}

	function evt__cancelar()
	{
		$this->ci_hijo()->resetear();
		$this->set_pantalla('pant_inicial');
	}

	function evt__nueva()
	{
		$this->ci_hijo()->relacion()->resetear();
		$this->set_pantalla('pant_edicion');
	}

	//-----------------------------------------------------------------------------------
	//---- filtro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__filtro(asociacion_ei_filtro $filtro)
	{
		if(isset($this->s__filtro))
			return $this->s__filtro;
	}
	function evt__filtro__filtrar($datos)
	{
		$this->s__filtro = $datos;
	}

	function evt__filtro__limpiar($datos)
	{
		unset($this->s__filtro);
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		//if(isset($this->s__filtro))
			return toba::consulta_php('liquidacion')->get_liquidaciones();
	}

	function evt__cuadro__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	function conf_evt__cuadro__seleccion(toba_evento_usuario $evento, $fila)
	{
	}

	
	
	

}
?>