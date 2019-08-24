<?php  

/**
* 
*/
class Reservada extends Model
{
	protected $list;
	protected $id;
	protected $id_persona;
	protected $id_liquidacion;
	protected $table ='reservadas';
	protected $schema = 'sistema';

	function __construct($id)
	{
		parent::__construct();
		$this->id = $id;
		$this->load($id);
	}

	function calcular_valor(){		
		if( !is_null($this->valor_fijo) ){
			$resultado = $this->valor_fijo;								//si hay un valor fijo tomo ese valor
		}else{
			$this->reemplazar_variables();
			$resultado = $this->ejecutar_query();			
			if( !isset($resultado) ){									//si la query trae resultados
				$err = '<br>No se pudo crear '.$this->nombre;
				throw new Exception("Error al cargar palabras reservadas".$err, 1);	
			}
		}
		return $resultado;
	}
	function reemplazar_variables(){
		
		$query = (isset($this->id_persona)) ? str_replace("{ID_PERSONA}", $this->id_persona, $this->query) : $this->query;
		$query = str_replace("{ID_LIQUIDACION}", $this->id_liquidacion, $query);		
		$this->query = $query;		
	}
	function ejecutar_query(){
		if( strlen($this->query)>0 ){
			try {
			$datos = toba::db()->consultar( $this->query );			
			} catch (toba_error_db $e) {
				toba::notificacion()->error('Error al generar la palabra reservada '.$this->nombre);
			}	
		}					
		if(isset($datos[0]['resultado'])){
			Logger::grabar($this->nombre . '='. $datos[0]['resultado'] .'(Usa valor query)',Logger::INFO);
			return $datos[0]['resultado'];
		}else{
			Logger::grabar($this->nombre . '='. $this->defecto .'(Usa valor defecto)',Logger::INFO);			
			return $this->defecto;
		}
	}
	function setIdLiquidacion($id_liquidacion){
		$this->id_liquidacion = $id_liquidacion;
	}
	function setIdPersona($id_persona){
		$this->id_persona = $id_persona;	
	}
}
