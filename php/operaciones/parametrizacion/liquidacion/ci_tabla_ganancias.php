<?php
class ci_tabla_ganancias extends asociacion_ci
{
	protected $s__filtro;
	protected $nueva_tabla = array();		//tabla que genera el formulario de generacion de filas

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
	//---- Configuraciones --------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__pant_edicion(toba_ei_pantalla $pantalla)
	{		
		//si el formulario ya cargo la variable para cargar el ml lo oculto
		if( count($this->nueva_tabla)>0 || $this->tabla('detalle')->get_cantidad_filas()>0){
			$pantalla->eliminar_dep('form_generar_filas');
		}
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

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		$where = null;
		if(isset($this->s__filtro))
			$where = $this->dep('filtro')->get_sql_where();
		return toba::consulta_php('liquidacion')->get_tabla_ganancias_cabecera($where, 'anio DESC');
	}

	function evt__cuadro__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	function conf_evt__cuadro__seleccion(toba_evento_usuario $evento, $fila)
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
		if( $this->tabla('cabecera')->get_cantidad_filas()>0 )
			return $this->tabla('cabecera')->get();
	}

	function evt__form__modificacion($datos)
	{
		$this->tabla('cabecera')->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		//si es edicion traigo los datos grabados
		if( $this->es_edicion() ){			
			return $this->get_detalle();
		}else{
			if( $this->tabla('detalle')->get_cantidad_filas()==0 && count($this->nueva_tabla)>0 ){
				return $this->nueva_tabla;
			}
		}
	}
	function evt__form_ml__modificacion($datos)
	{
		$this->tabla('detalle')->procesar_filas($datos);
	}
	
	function get_detalle(){
		$filas = $this->tabla('detalle')->get_filas();		
		uasort($filas, function($a, $b) {
			    if ($a['mes'] == $b['mes']) {
			        return ($a['desde'] < $b['desde']) ? -1 : 1;
			    }
			    return ($a['mes'] < $b['mes']) ? -1 : 1;
		});
		return $filas; 
	}



	//-----------------------------------------------------------------------------------
	//---- form_generar_filas -----------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_generar_filas(asociacion_ei_formulario $form){}

	function evt__form_generar_filas__generar($datos)
	{
		$cant_meses = $datos['meses'];
		$cant_filas = $datos['filas'];
		$tabla = array();

		for ($mes=1; $mes <=$cant_meses ; $mes++) { 
			for ($i=0; $i <$cant_filas ; $i++) { 
				$fila['mes'] = $mes;
				$fila['apex_ei_analisis_fila'] = 'A';
				$tabla[] = $fila;
			}
		}
		return $this->nueva_tabla = $tabla;
	}

	function extender_objeto_js(){
		if($this->get_id_pantalla()=='pant_edicion'){
			echo "
			//corrijo campo descripcion de form
			$('#ef_form_2895_formdescripcion').attr('size','40');

			$('#form_2902_form_generar_filas_notificacion').closest('table').css({
				'position' : 'fixed',
				'top' : '90px',
				'left' : '10px'
			});					 
			";	
		}
			
	}


}
?>