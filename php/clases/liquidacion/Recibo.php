<?php
/**
* 
*/
class Recibo extends Model
{
	protected $conceptos;	
	protected $lazy = false;

	protected $table = "recibos";

	function __construct($id)
	{
		parent::__construct();
		$this->id = $id;
		$this->cargar($id);
		$this->cargar_conceptos();
	}
	function cargar($id){		
		$this->load($id);
	}

	function cargar_conceptos(){
		$ids_conceptos = $this->get_ids_conceptos();
		//recorre cada uno de los empleados creando los recibos		
		foreach ($ids_conceptos as $key => $id_concepto) {
			$concepto = new Concepto($id_concepto);
			$this->conceptos[] = $concepto;
		}
	}
	function get_ids_conceptos(){
		$datos = $this->persistor->select("v_recibos_conceptos", "id_recibo={$this->id}","codigo ASC", "id");
		return array_column($datos, 'id');
	}
	function get_conceptos(){
		return $this->conceptos;
	}
}
