<?php
class ci_amb_personas extends asociacion_ci
{
	protected $s__filtro;
	//-----------------------------------------------------------------------------------
	//---- Eventos ----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------
	function evt__nuevo()
	{
		$this->dep('datos_alumno')->relacion()->resetear();
		$this->set_pantalla('pant_edicion');
	}
	function evt__cancelar()
	{
		$this->set_pantalla('pant_inicial');	
	}
	function evt__guardar(){
		$this->dep('datos_alumno')->guardar(); //consumo la api de datos_alumno
		$this->set_pantalla('pant_inicial');
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------
	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		//$where = (isset($this->s__filtro)) ? $this->dep('filtro')->get_sql_where() : null;
		$where = null;
		if(isset($this->s__filtro)){
			$clausulas = $this->dep('filtro')->get_sql_clausulas();
			if(isset($clausulas['id_tipo_persona'])){
				$tipo_personas = implode(',',$this->s__filtro['id_tipo_persona']['valor']);
				$where_tipo_persona = "exists(select id_tipo_persona from personas_tipo where id_persona=v_personas.id and id_tipo_persona IN ($tipo_personas))";
				unset($clausulas['id_tipo_persona']);
				$where = $this->dep('filtro')->get_sql_where('AND',$clausulas);
				$where = ($where) ? "$where AND $where_tipo_persona " : $where_tipo_persona; 
			}else{
				$where = $this->dep('filtro')->get_sql_where();
			}				
		}
		$datos = toba::consulta_php('personas')->get_personas($where, 'apellido, nombre');
		$cuadro->set_datos($datos);
		
	}
	function evt__cuadro__seleccion($seleccion)
	{
		$this->dep('datos_alumno')->relacion()->cargar($seleccion);
		$this->set_pantalla('pant_edicion');
	}

	//-----------------------------------------------------------------------------------
	//---- filtro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__filtro(asociacion_ei_filtro $filtro)
	{
		if(isset($this->s__filtro))
			$filtro->set_datos($this->s__filtro);
	}

	function evt__filtro__filtrar($datos)
	{
		$this->s__filtro = $datos;
	}

	function evt__filtro__cancelar()
	{
		unset($this->s__filtro);
	}

	function vista_pdf(toba_vista_pdf $salida){
		$fecha = date('d-m-Y H:i:s');
        $salida->separacion(10);
        $salida->mensaje('Fecha de Impresion: '.$fecha);
        
		$salida->titulo('Datos de la persona');
		$this->dep('datos_alumno')->imprimir($salida);

		$datos_generales = $this->dep('datos_alumno')->tabla('personas')->get();
		$salida->set_nombre_archivo($datos_generales['dni'].'_'.date('d-m-Y').'.pdf');
	}

	function vista_jasperreports(toba_vista_jasperreports $report)
    {           	
  //       $persona = $this->tabla("personas")->get();
		// $nombre = 'legajo_' . $persona['legajo'] . '.pdf';
  //   	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/datos_persona.jasper');
		// $report->set_parametro('id_persona','E',$persona['id']);			               
  //       $report->set_parametro('proyecto_path','S',toba::proyecto()->get_path());
        
  //       $report->set_nombre_archivo($nombre);
  //       $report->set_tipo_descarga('browser');  
  //       $db = toba::db('asociacion','asociacion');
  //       $report->set_conexion($db);
    	$this->dep('datos_alumno')->vista_jasperreports($report);
        		
	}
}
?>