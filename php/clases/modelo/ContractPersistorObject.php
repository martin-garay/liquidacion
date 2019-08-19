<?php 
namespace core;

Interface ContractPersistorObject{
	
	function select($table, $where=null,$order_by=null, $columns='*');

	/**
	* Inserta un registro y devuelve el id del nuevo registro
	* @param string $table : nombre de la tabla
	* @param array $values : array asociativo con los valores del registro array('key'=>'value')	
	* @return int
	*/
	function insert($table,$values);

	/**
	* actualiza un registro
	* @param string $table : nombre de la tabla
	* @param array $values : array asociativo con los valores del registro array('key'=>'value')	
	* @param string $where : condicion de la consulta
	* @return void
	*/
	function update($table,$values,$where=null);

	/**
	* borra un registro
	* @param string  : array asociativo con los valores del registro array('key'=>'value')	
	* @return bool
	*/
	function delete($table,$where);

	function getColumns($table);
}

?>