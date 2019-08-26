<?php
class ci_tablas extends ci_generico_dos_pantallas_relacion
{	
	protected $s__form;

	function conf__form(asociacion_ei_formulario $form)
	{		
		if( !isset($this->s__form) ){
			if( $this->tabla_cabecera()->esta_cargada() )
				$this->s__form = $this->tabla_cabecera()->get();
		}

		if( !isset($this->s__form['anio']) ){
			$anio_actual = toba::consulta_php('parametrizacion')->get_anio_actual();
			$this->s__form['anio'] = $anio_actual;
		}
		
		return $this->s__form;
	}

	function evt__form__modificacion($datos)
	{		
		$this->tabla_cabecera()->set($datos);
		$this->s__form = $datos;
	}

	//-----------------------------------------------------------------------------------
	//---- form_ml ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__form_ml(asociacion_ei_formulario_ml $form_ml)
	{
		if( isset($this->s__form['anio']) ){
			$condicion = array(
				'anio'		=>	$this->s__form['anio']
				//'id_tabla'	=>	$this->tabla_cabecera()->get_columna()
			);
			$form_ml->limpiar_interface();

			$datos = $this->tabla_detalle()->get_filas($condicion);
			ei_arbol($datos );
			return $datos;
		}		
	}

	function evt__form_ml__modificacion($datos)
	{
		foreach ($datos as $key => $fila) {
			$datos[$key]['anio'] = $this->s__form['anio'];
			$datos[$key]['periodo'] = $datos[$key]['anio'] . '-' .$datos[$key]['mes'] . '-01';
		}
		//$this->tabla_detalle()->resetear();
		$this->tabla_detalle()->procesar_filas($datos);
	}

	function extender_objeto_js(){
		if($this->get_id_pantalla()=='pant_edicion'){
			echo "
			{$this->dep('form')->objeto_js}.evt__anio__procesar = function(es_inicial){
				if(!es_inicial){
					if (this.ef('anio').tiene_estado()) {
   						this.set_evento(new evento_ei('modificacion',true,''));
   					}  
				}
			}
			";	
		}		
	}
}

?>