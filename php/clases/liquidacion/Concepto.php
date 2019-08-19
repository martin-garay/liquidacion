<?php
/**
* 
*/
class Concepto extends Model
{
	protected $id;
	protected $table = "recibos_conceptos";

	function __construct($id)
	{
		parent::__construct();
		$this->id = $id;
		$this->load($id);
	}
	//se puede llamar $concepto->formula
	function getFormula(){
		$datos = $this->persistor->select('conceptos',"id={$this->id_concepto}",null,'formula');		
		return $datos[0]['formula'];
	}
	function getCodigo(){
		$datos = $this->persistor->select('conceptos',"id={$this->id_concepto}",null,'codigo');
		return $datos[0]['codigo'];
	}
	function getNombreVariable(){		
		return 'c'.$this->codigo;	
	}
}