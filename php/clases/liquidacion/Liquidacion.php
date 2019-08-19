<?php  

/**
* 
*/
class Liquidacion extends Model
{
	protected $id;	
	protected $recibos;
	protected $liquidador;	
	protected $table = 'liquidaciones';
	
	const PENDIENTE=1, LIQUIDADA=2;

	function __construct($id)
	{		
		parent::__construct();
		$this->id = $id;
		$this->liquidador = new Liquidador($id);
		$this->cargar_recibos();
		$this->load($id);
	}
	function cargar_recibos(){
		$ids_recibos = $this->get_ids_recibos();
		//recorre cada uno de los empleados creando los recibos		
		foreach ($ids_recibos as $key => $id_recibo) {			
			$recibo = new Recibo($id_recibo);
			$this->recibos[] = $recibo;
		}
	}
	function liquidar(){		
		$this->liquidador->liquidar( $this->get_recibos() );
		$this->id_estado = self::LIQUIDADA;
	}
	function get_recibos(){
		return $this->recibos;
	}
	function get_ids_recibos(){
		$datos = $this->persistor->select("recibos", "id_liquidacion={$this->id}","id ASC", "id");
		return array_column($datos, 'id');
	}
	function grabar(){
		//actualizo los conceptos con el valor calculado
		foreach ($this->get_recibos() as $key => $recibo) {			
			foreach ($recibo->get_conceptos() as $key => $concepto) {				
				$concepto->save();
			}
		}
		$this->save();
	}
	function mostrar_liquidacion(){
		foreach ($this->get_recibos() as $key => $recibo) {
			echo 'Id Recibo: '.$recibo->id . '<br>';
			foreach ($recibo->get_conceptos() as $key => $concepto) {
				echo 'Concepto: '.$concepto->nombre_variable . '=' . $concepto->importe .'<br>';				
			}
		}
	}
}
