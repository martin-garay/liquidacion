<?php
class ci_liquidacion extends asociacion_ci
{
	const RECIBO = 1, RECIBOS=2, LIBRO_SUELDO=3;

	protected $s__filtro;
	protected $s__id_liquidacion;
	protected $s__fila_imprimir;
	protected $s__reporte_imprimir;

	function evt__volver(){
		$this->set_pantalla('pant_inicial');
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

	//-----------------------------------------------------------------------------------
	//---- Configuraciones --------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__pant_edicion(toba_ei_pantalla $pantalla)
	{
		$pantalla->set_descripcion( $this->get_descripcion_liquidacion() );
	}

	function get_descripcion_liquidacion(){
		$datos = toba::consulta_php('liquidacion')->get_historico_liquidaciones("id={$this->s__id_liquidacion}", "periodo DESC");
		return $datos[0]['mes'] . '-' . $datos[0]['anio'] . '. ' . $datos[0]['descripcion'];
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		if(isset($this->s__filtro)){
			$where = $this->dep('filtro')->get_sql_where();
			return toba::consulta_php('liquidacion')->get_historico_liquidaciones($where, "periodo DESC");
		}
	}

	function evt__cuadro__seleccion($seleccion)
	{		
		$this->s__id_liquidacion = $seleccion['id'];
		$this->set_pantalla('pant_edicion');
	}

	function evt__cuadro__imprimir_libro($seleccion)
	{
	}

	//-----------------------------------------------------------------------------------
	//---- cuadro_recibos ---------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro_recibos(asociacion_ei_cuadro $cuadro)
	{
		if(isset($this->s__id_liquidacion)){
			$where = "id_liquidacion=".$this->s__id_liquidacion;
			return toba::consulta_php('liquidacion')->get_historico_recibos($where, "apellido,nombre"); 
		}
	}
	function ajax__imprimir_libro($fila, toba_ajax_respuesta $respuesta){
        $this->s__fila_imprimir = $fila;
        $this->s__reporte_imprimir = self::LIBRO_SUELDO;
        $respuesta->set($fila);
    }

    function ajax__imprimir_recibo($fila, toba_ajax_respuesta $respuesta){
        $this->s__fila_imprimir = $fila;
        $this->s__reporte_imprimir = self::RECIBO;
        $respuesta->set($fila);
    }
    function ajax__imprimir_listado_recibos($fila, toba_ajax_respuesta $respuesta){
        $this->s__fila_imprimir = $fila;
        $this->s__reporte_imprimir = self::RECIBOS;
        $respuesta->set($fila);
    }


	function extender_objeto_js()
	{
		if($this->get_id_pantalla()=='pant_inicial'){
			echo "
	    	{$this->dep('cuadro')->objeto_js}.evt__imprimir_libro = function(nro_fila){                        
	                this.controlador.ajax('imprimir_libro', nro_fila , this.controlador, this.controlador.respuesta);
	                return false;
	        };

	        {$this->dep('cuadro')->objeto_js}.evt__imprimir_recibos = function(nro_fila){                        
	                this.controlador.ajax('imprimir_listado_recibos', nro_fila , this.controlador, this.controlador.respuesta);
	                return false;
	        };	        
	        
	        {$this->objeto_js}.respuesta = function(resultado){
	            console.log(resultado);
	            var params;                    
	            location.href = vinculador.get_url(null, null, 'vista_jasperreports', {'path': params});
	        }
	        ";
		}

		if($this->get_id_pantalla()=='pant_edicion'){
			echo "
	    	{$this->dep('cuadro_recibos')->objeto_js}.evt__imprimir_recibo = function(nro_fila){                        
	                this.controlador.ajax('imprimir_recibo', nro_fila , this.controlador, this.controlador.respuesta);
	                return false;
	        };	        
	        {$this->objeto_js}.respuesta = function(resultado){
	            console.log(resultado);
	            var params;                    
	            location.href = vinculador.get_url(null, null, 'vista_jasperreports', {'path': params});
	        }
	        ";
		}
	}

	function vista_jasperreports(toba_vista_jasperreports $report)
    {           	
        $fecha = date("d/m/Y");
        switch ($this->s__reporte_imprimir) {

        	case self::RECIBO:
        		$datos = $this->dep('cuadro_recibos')->get_datos();
	        	$recibo = $datos[$this->s__fila_imprimir];

				$nombre = 'recibo_' . $recibo['nro_recibo'] . '_' . $recibo['nro_documento'] . '.pdf';
	        	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/recibo_historico.jasper');
				$report->set_parametro('id_recibo','E',$recibo['id']);	
        		break;

        	case self::RECIBOS:
        		$datos = $this->dep('cuadro')->get_datos();
	        	$liquidacion = $datos[$this->s__fila_imprimir];

	        	$nombre = 'recibos-liquidacion-' . $liquidacion['anio'] . '-' . $liquidacion['mes'] . '.pdf';
	        	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/liquidacion_recibos_historico.jasper');
				$report->set_parametro('id_liquidacion','E',$liquidacion['id']);
        		break;
        	
    		case self::LIBRO_SUELDO:
    			$datos = $this->dep('cuadro')->get_datos();
	        	$liquidacion = $datos[$this->s__fila_imprimir];

	        	$nombre = 'liquidacion-' . $liquidacion['anio'] . '-' . $liquidacion['mes'] . '.pdf';
	        	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/libro.jasper');
				$report->set_parametro('id_liquidacion','E',$liquidacion['id']);        	        	
    			break;
        	
        }
   //      if($this->get_id_pantalla=='pant_inicial'){					//libro de sueldos

			// $datos = $this->dep('cuadro')->get_datos();
			// $liquidacion = $datos[$this->s__fila_imprimir];

			// $nombre = 'liquidacion-' . $liquidacion['anio'] . '-' . $liquidacion['mes'] . '.pdf';
			// $report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/libro_sueldo_historico.jasper');
			// $report->set_parametro('id_liquidacion','E',$liquidacion['id']);        	        	

   //      }else{														//recibo

   //  		$datos = $this->dep('cuadro_recibos')->get_datos();
   //      	$recibo = $datos[$this->s__fila_imprimir];

			// $nombre = 'recibo_' . $recibo['nro_recibo'] . '_' . $recibo['nro_documento'] . '.pdf';
   //      	$report->set_path_reporte(toba::proyecto()->get_path_php().'/jasper/recibo_historico.jasper');
			// $report->set_parametro('id_recibo','E',$recibo['id']);	
			
   //      }
        
        $report->set_nombre_archivo($nombre);               
        $report->set_parametro('proyecto_path','S',toba::proyecto()->get_path());
        $report->set_tipo_descarga('browser');  
        $db = toba::db('asociacion','asociacion');
        $report->set_conexion($db);

        
                        		       
    }

}

?>