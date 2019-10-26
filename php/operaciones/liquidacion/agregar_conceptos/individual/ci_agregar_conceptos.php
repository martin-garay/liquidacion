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
		try {			
			$this->dep('recibos_conceptos')->sincronizar();	
			$this->dep('recibos_conceptos')->resetear();
			$this->set_pantalla('pant_inicial');
			unset($this->s__filtro);
			unset($this->s__seleccion);
			unset($this->s__datos_form);
			toba::notificacion()->info('Se crearon los conceptos!');
		} catch (toba_error_db $e) {
			throw new toba_error_usuario("Error al procesar");					
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
		if(count($this->s__seleccion)>0){
			$this->dep('recibos_conceptos')->resetear();
			unset($this->s__datos_form);
			$this->set_pantalla('pant_generacion');			
		}else{
			toba::notificacion()->error("Debe seleccionar al menos un recibo");
		}
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
		if($this->get_id_pantalla()=='pant_generacion'){
			$evento->anular();
		}else{
			$clave = $this->dep('cuadro')->get_clave_fila_array($fila);                                
         	
			#controlo si estaba guardado y lo tildo
			if(in_array($clave['id'], array_column($this->s__seleccion, 'id'))){
				$evento->set_check_activo(true);
			}else{
				$evento->set_check_activo(false);
			}
		}
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
		unset($this->s__seleccion);
	}

	function evt__filtro__cancelar()
	{
		unset($this->s__filtro);
		unset($this->s__seleccion);
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
		//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		return $this->get_nuevos_conceptos();
	}

	function evt__form_ml__modificacion($datos)
	{
		$this->dep('recibos_conceptos')->procesar_filas($datos);
	}

	function get_conceptos($id_tipo_concepto){
		$where = "id_tipo_concepto=$id_tipo_concepto";
		return toba::consulta_php('parametrizacion')->get_conceptos($where);
	}
	function get_liquidaciones(){
		return toba::consulta_php('liquidacion')->get_liquidaciones("id_estado=1","periodo desc");
	}
	function get_nuevos_conceptos(){
		if(isset($this->s__datos_form['id_concepto']) && (count($this->s__seleccion)>0) ){
			$id_concepto = $this->s__datos_form['id_concepto'];			
			$importe_fijo = (isset($this->s__datos_form['importe_fijo'])) ? $this->s__datos_form['importe_fijo'] : null;
			$recibos = array_column($this->s__seleccion,'id');
			$nuevos_conceptos = array();

			foreach ($recibos as $key => $id_recibo) {
				//verifico que no exista el concepto en el recibo
				if( !$this->existe_concepto($id_recibo,$id_concepto) ){					
					$nuevos_conceptos[] = array('id_concepto'=>$id_concepto,
												'id_recibo'=>$id_recibo,
												'importe_fijo'=>$importe_fijo,
												'apex_ei_analisis_fila'=>'A');
				}else{
					$recibo = toba::consulta_php('liquidacion')->get_recibos("id=$id_recibo");
					$descripcion_recibo = $recibo[0]['nro_documento'] . ' ' . $recibo[0]['apellido'] . ' ' .$recibo[0]['nombre'];
					toba::notificacion()->agregar('El concepto ya existe en el recibo de :'.$descripcion_recibo);
				}
			}
			return $nuevos_conceptos;
		}else{
			return null;
		}
	}
	function get_recibos($filtro){
		$ids_recibos = implode(',',array_column($this->s__seleccion,'id'));		
		$sql = "SELECT id, legajo||' '||apellido||' '||nombre as descripcion FROM v_recibos 
		WHERE legajo||' '||apellido||' '||nombre ILIKE '%$filtro%' and id IN ($ids_recibos)";
        return toba::db()->consultar($sql);
	}	
	function get_recibos_descripcion($id_recibo){
		$sql = "SELECT legajo||' '||apellido||' '||nombre as descripcion FROM v_recibos WHERE id=$id_recibo";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
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

		if($this->get_id_pantalla()=='pant_generacion'){
			echo "
			
			{$this->dep('form')->objeto_js}.evt__id_concepto__procesar = function(es_inicial){
				if(!es_inicial && this.ef('id_concepto').tiene_estado() ){
					this.set_evento(new evento_ei('modificacion',true,''));
				}
			}
			{$this->dep('form')->objeto_js}.evt__importe_fijo__procesar = function(es_inicial){
				if(!es_inicial && this.ef('importe_fijo').tiene_estado() ){
					var filas = {$this->dep('form_ml')->objeto_js}.filas();
					var importe_fijo = this.ef('importe_fijo').get_estado();
					for (id_fila in filas) {						
						if(!{$this->dep('form_ml')->objeto_js}.ef('importe_fijo').ir_a_fila(filas[id_fila]).tiene_estado()){
							{$this->dep('form_ml')->objeto_js}.ef('importe_fijo').ir_a_fila(filas[id_fila]).set_estado(importe_fijo);
						}					
					}

				}
			}			
			$(document).ready(function(){
				if( {$this->dep('form_ml')->objeto_js}.filas().length>0 ){
					//$('td[id$=\"ef_form_2937_form_mlid_concepto\"]').find('input').attr('disabled',true);
					//$('td[id$=\"ef_form_2937_form_mlid_recibo\"]').find('input').attr('disabled',true);	
					$('td[id$=\"ef_form_2937_form_mlid_concepto\"]').find('input').attr('readonly',true);
					$('td[id$=\"ef_form_2937_form_mlid_recibo\"]').find('input').attr('readonly',true);	
				}								
			});			
			
			";
		}

	}

}
?>