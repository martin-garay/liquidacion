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
	function conf(){
		$estado = $this->ci_hijo()->get_estado();		
		if( $this->get_id_pantalla()=='pant_edicion'){
			if( $estado!=1 )
				$this->evento('liquidar')->anular();			
			if($estado>1)				
				$this->evento('procesar')->anular();			
		}		
	}
	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	//pasa una liquidacion de estado PENDIENTE LIQUIDACON a LIQUIDADA
	// function evt__liquidar(){		
	// 	$this->ci_hijo()->liquidar();
	// 	$this->set_pantalla('pant_inicial');	
	// }
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
		$this->ci_hijo()->disparar_limpieza_memoria();
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
		$where = null;
		if(isset($this->s__filtro))
			$where = $this->dep('filtro')->get_sql_where();
			return toba::consulta_php('liquidacion')->get_liquidaciones($where, "anio desc,mes desc");
	}
	function evt__cuadro__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);		
		$this->set_pantalla('pant_edicion');
	}	
	function evt__cuadro__borrar($seleccion)
	{
		$this->ci_hijo()->borrar($seleccion);		
	}
	function evt__cuadro__liquidar($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->ci_hijo()->liquidar();
	}
	function evt__cuadro__cerrar($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->ci_hijo()->cerrar();
	}
	function conf_evt__cuadro__seleccion(toba_evento_usuario $evento, $fila)
	{
		$datos = $this->dep('cuadro')->get_datos();
        if( $datos[$fila]['id_estado']==3 ){   //si el estado es distinto del estado inicial PENDIENTE LIQUIDACION
            $evento->anular();
        }
	}
	function conf_evt__cuadro__borrar(toba_evento_usuario $evento, $fila)
	{
		$datos = $this->dep('cuadro')->get_datos();
        if( $datos[$fila]['id_estado']!==1 ){   //si el estado es distinto del estado inicial PENDIENTE LIQUIDACION
            $evento->anular();
        }
	}
	function conf_evt__cuadro__liquidar(toba_evento_usuario $evento, $fila)
	{
		$datos = $this->dep('cuadro')->get_datos();
        if( $datos[$fila]['id_estado']!==1 ){   //si el estado es distinto del estado inicial PENDIENTE LIQUIDACION
            $evento->anular();
        }
	}	
	function conf_evt__cuadro__cerrar(toba_evento_usuario $evento, $fila)
	{
		$datos = $this->dep('cuadro')->get_datos();
        if( $datos[$fila]['id_estado']!==2 ){   //si el estado es distinto del estado inicial PENDIENTE LIQUIDACION
            $evento->anular();
        }
	}

	//-----------------------------------------------------------------------------------
	//---- Configuraciones --------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	// function conf__pant_edicion(toba_ei_pantalla $pantalla)
	// {
	// 	$descripcion = $t
	// 	$anio =  
	// 	$mes = 
	// 	$descripcion_liquidacion = $this->relacion()
	// 	$pantalla->set_descripcion();
	// }

}
?>