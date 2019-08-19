<?php  

require_once('ContractPersistorObject.php');
/**
* 
*/
class PersistorPostgresql implements \core\ContractPersistorObject
{		
	
	function insert($table,$values){
		$keys = implode(',',array_keys($values));
		foreach ($values as $key => $value) {
			$values[$key] = "'$value'";
		}
		$values = implode(',',array_values($values));
        
        $query = "INSERT INTO $table($keys) VALUES ($values) RETURNING id;";

        toba::db()->consultar($query);
	}

	function select($table, $where=null,$order_by=null, $columns='*'){
		$where = ($where) ?" WHERE $where ":"";
		$order_by = ($order_by) ? " ORDER BY $order_by " : "";		
        $query = "SELECT $columns FROM $table $where $order_by;";                               
        return toba::db()->consultar($query);
	}

	function update($table,$values,$where=null){
		$where = ($where) ?" WHERE $where ":"";		
		$str_values = '';
		foreach ($values as $key => $value) {
			if(isset($value))
				$str_values .= " $key='$value',";
		}
		$str_values = rtrim($str_values,",");				
        $query = "UPDATE $table SET $str_values $where";
     	toba::db()->ejecutar($query);
	}
	function delete($table,$where){
		$con = $this->openConnection();
		$where = ($where) ?" WHERE $where ":"";
		$query = "DELETE FROM $table $where";
        //$rs = pg_query($con, $query) or die("Cannot execute query: $query\n");
        toba::db()->ejecutar($query);
	}

	public function getColumns($table,$schema='public'){
        $query = "SELECT column_name FROM information_schema.columns WHERE table_schema = '$schema' AND table_name   = '$table'";        
        $rows = toba::db()->consultar($query);                
        return (count($rows)>0) ? array_column($rows, 'column_name') : null;
	}

}

?>