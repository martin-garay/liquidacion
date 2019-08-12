<?php
#$this->get_parametro('a') => tabla cuadro
#$this->get_parametro('b') => order by
#$this->get_parametro('c') => nombre de la tabla cabecera 
#$this->get_parametro('d') => nombre de la tabla detalle

class ci_generico_dos_pantallas_relacion extends asociacion_ci
{
	protected $s__datos_filtro;

	function relacion(){
		return $this->dep('relacion');
	}
	function tabla($nombre){
		return $this->relacion()->tabla($nombre);
	}
	function tabla_cabecera(){
		return $this->tabla($this->get_parametro('c'));
	}
	function tabla_detalle(){
		return $this->tabla($this->get_parametro('d'));
	}

	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function evt__procesar()
	{
		try {
			$this->relacion()->sincronizar();
		} catch (toba_error_db $e) {
			toba::notificacion()->error('Error al guardar');
		}
		$this->relacion()->resetear();
		$this->set_pantalla('pant_inicial');
	}
	
	function evt__cancelar()
	{
		$this->relacion()->resetear();
		$this->set_pantalla('pant_inicial');
	}

	function evt__nuevo()
	{
		$this->relacion()->resetear();
		$this->set_pantalla('pant_edicion');	
	}


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
		$tabla = $this->get_parametro('a');	
		$datos = toba::consulta_php('comunes')->get_generico($tabla,$where,$this->get_parametro('b'));
		$cuadro->set_datos($datos);
	}

	function evt__cuadro__seleccion($seleccion)
	{
		$this->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	function evt__cuadro__eliminar($seleccion)
	{
		//$this->relacion()->get_persistidor()->desactivar_transaccion();
		//toba::db()->abrir_transaccion();		
		try{
			$this->relacion()->cargar($seleccion);
            $this->relacion()->eliminar_todo();
            //toba::db()->cerrar_transaccion();
		}catch(toba_error_db $e){
			//toba::db()->abortar_transaccion();
			if($e->get_sqlstate()=="db_23503"){
				toba::notificacion()->agregar('ATENCION! El registro esta siendo utilizado');
            }else{
				toba::notificacion()->agregar('ERROR! El registro No puede eliminarse');
            }
		}
        $this->relacion()->resetear();
	}

	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if( $this->tabla_cabecera()->esta_cargada() ){
			return $this->tabla_cabecera()->get();
		}
	}

	function evt__form__modificacion($datos)
	{
		$this->tabla_cabecera()->set($datos);
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		return $this->tabla_detalle()->get_filas();
	}

	function evt__form_ml__modificacion($datos)
	{
		$this->tabla_detalle()->procesar_filas($datos);
	}

}

?>