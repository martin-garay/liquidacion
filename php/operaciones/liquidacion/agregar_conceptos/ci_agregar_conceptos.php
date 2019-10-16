<?php
class ci_agregar_conceptos extends asociacion_ci
{
	protected $s__filtro;
	protected $s__seleccion;
	protected $s__datos_form;
	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function evt__procesar()
	{
		//verifico que se seleccionaron recibos
		if(count($this->s__seleccion)>0){
			$id_concepto = $this->s__datos_form['id_concepto'];
			$importe_fijo = (isset($this->s__datos_form['id_concepto'])) ? $this->s__datos_form['id_concepto'] : null;
			$recibos = array_column($this->s__seleccion,'id');
			$nuevos_conceptos = array();

			foreach ($recibos as $key => $id_recibo) {
				//verifico que no exista el concepto en el recibo
				if( !$this->existe_concepto($id_recibo,$id_concepto) ){					
					$nuevos_conceptos[] = array('id_concepto'=>$id_concepto,'id_recibo'=>$id_recibo,
												'importe_fijo'=>$importe_fijo,'apex_ei_analisis_fila'=>'A');
				}else{
					$recibo = toba::consulta_php('liquidacion')->get_recibo("id=$id_recibo");
					$descripcion_recibo = $recibo[0]['nro_documento'] . ' ' . $recibo[0]['apellido'] . ' ' .$recibo[0]['nombre'];
					toba::notificacion()->agregar('El concepto ya existe en el recibo de :'.$descripcion_recibo);
				}
			}
			//ei_arbol($nuevos_conceptos);
			// if(count($nuevos_conceptos)>0){
			// 	$this->dep('recibos_conceptos')->procesar_filas($nuevos_conceptos);
			// }	
		}else{
			throw new toba_error_usuario("Debe seleccionar al menos un recibo");			
		}
	}

	function existe_concepto($id_recibo,$id_concepto){
		$sql = "SELECT 1 FROM recibos_conceptos where id_recibo = $id_recibo AND id_concepto=$id_concepto";
		$datos = toba::db()->consultar($sql);
		return (count($datos)>0);
	}

	function evt__cancelar()
	{
		$this->set_pantalla('pant_inicial');
	}

	function evt__siguiente()
	{
		$this->set_pantalla('pant_generacion');
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		if($this->get_id_pantalla()=='pant_inicial'){			
			if( isset($this->s__filtro) ){
				$where = $this->dep('filtro')->get_sql_where();
				return toba::consulta_php('liquidacion')->get_recibos($where,'apellido,nombre');
			}	
		}else{
			if(count($this->s__seleccion)>0){
				$ids_recibos = implode(',',array_column($this->s__seleccion,'id'));
				$where = "id IN ($ids_recibos)";
				return toba::consulta_php('liquidacion')->get_recibos($where,'apellido,nombre');				
			}			
		}
		
	}
	               
	function evt__cuadro__seleccionar($datos)
	{
		$this->s__seleccion = $datos;
	}

	function conf_evt__cuadro__seleccionar(toba_evento_usuario $evento, $fila)
	{
		if($this->get_id_pantalla()=='pant_generacion')
			$evento->anular();
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

	function evt__filtro__cancelar()
	{
		unset($this->s__filtro);
	}

	//-----------------------------------------------------------------------------------
	//---- form -------------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form(asociacion_ei_formulario $form)
	{
		if(isset($this->s__datos_form))
			return $this->s__datos_form;
	}

	function evt__form__modificacion($datos)
	{
		$this->s__datos_form = $datos;
	}

	function get_conceptos($id_tipo_concepto){
		$where = "id_tipo_concepto=$id_tipo_concepto";
		return toba::consulta_php('parametrizacion')->get_conceptos($where);
	}

	function extender_objeto_js(){
		if($this->get_id_pantalla()=='pant_inicial')
			echo "
			$('.ei-cuadro-barra-sup').append(\"<div style='float:right'>Seleccionar Todos <input type='checkbox' id='seleccionar_todos'/></div>\");
			$('#seleccionar_todos').click(function(){
	            if($('#seleccionar_todos').is(':checked')){
					{$this->dep('cuadro')->objeto_js}.seleccionar_todos('seleccionar');
	            }else{
					{$this->dep('cuadro')->objeto_js}.deseleccionar_todos('seleccionar');
	            }
			});
			";

	}

}
?>