<?php
class ci_planilla_periodo extends asociacion_ci
{
	protected $s__filtro;

	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function es_edicion(){
		return $this->relacion()->esta_cargada();
	}
	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------
	function evt__nuevo()
	{
		$this->relacion()->resetear();
		$this->set_pantalla('pant_edicion');
	}
	function evt__cancelar()
	{
		$this->relacion()->resetear();
		$this->set_pantalla('pant_inicial');
	}
	function evt__procesar()
	{
		try {
			$this->relacion()->sincronizar();
			$this->relacion()->resetear();
			$this->set_pantalla('pant_inicial');
			toba::notificacion()->info('Los cambios se registraron correctamente');
		} catch (toba_error_db $e) {
			toba::notificacion()->error('Error al grabar');
		}
	}
//--------------------------------------------------------------------------------------
//---- Pant Inicial --------------------------------------------------------------------
//--------------------------------------------------------------------------------------

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

	function evt__filtro__cancelar()
	{
		unset($this->s__filtro);
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro_periodos --------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro_periodos(asociacion_ei_cuadro $cuadro)
	{
		$where = null;
		if(isset($this->s__filtro))
			$where = $this->dep('filtro')->get_sql_where();
		return toba::consulta_php('liquidacion')->get_periodos($where, 'periodo desc');
	}

	function evt__cuadro_periodos__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	function conf_evt__cuadro_periodos__seleccion(toba_evento_usuario $evento, $fila)
	{
	}

//--------------------------------------------------------------------------------------
//---- Pant Edicion --------------------------------------------------------------------
//--------------------------------------------------------------------------------------

	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if( $this->es_edicion() )
			return $this->tabla('periodo')->get();
	}

	function evt__form__modificacion($datos)
	{
		$datos['periodo'] = $datos['anio'].'-'.$datos['mes'].'-01';
		$this->tabla('periodo')->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		//si es edicion traigo los datos grabados
		if( $this->es_edicion() )
			return $this->cargar_personas();			
		else
			return toba::consulta_php('personas')->get_personas_nueva_planilla_periodo('activo','legajo');		
	}
	function evt__form_ml__modificacion($datos)
	{
		$this->tabla('periodo_detalle')->procesar_filas($datos);
	}
	
	function cargar_personas(){
		$personas = $this->tabla('periodo_detalle')->get_filas();		
		uasort($personas, function($a, $b) {
			    if ($a['legajo'] == $b['legajo']) {
			        return 0;
			    }
			    return ($a['legajo'] < $b['legajo']) ? -1 : 1;
		});
		return $personas; 
	}



}
?>