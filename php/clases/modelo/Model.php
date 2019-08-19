<?php 

class Model{

	protected $persistor;
	protected $table;
	protected $schema = 'public';
	private $properties = array();
	private $writable = array();
	protected $columns;
	protected $obligatory_columns = array();

	function __construct(){		
		$this->persistor = new PersistorPostgresql();		
		$this->columns = $this->persistor->getColumns($this->table(),$this->schema);		
	}

	//getter magico. Acceder a las properties $model->propertie
	function __get($name) {				
		//Por ej. numero_dias llamar al metodo getNumeroDias dentro del objeto
        $dynamicMethod = 'get' . Inflector::studly($name); 			//cadena en formato CamelCase                 

        if (method_exists($this, $dynamicMethod))					//Si existe lo llamamos     
            return $this->$dynamicMethod();

        return array_key_exists($name, $this->properties) ? $this->properties[$name] : null;
	}

	//setter magico
	//guardo directamente en la propertie como si existiese
	function __set($prop, $val) {
				
        $dynamicMethod = 'set' . Inflector::studly($prop);
	    if(method_exists($this, $dynamicMethod))
	    {
	        $this->$dynamicMethod($prop, $val);
	    }else{
	    	if(in_array($prop, $this->columns))	    		
	    		$this->properties[$prop] = $val;          		
	    }
    }
    
	function add($row){
		$this->fill($row);
		if($this->validate_obligatory())
			$this->persistor->insert($this->schema.'.'.$this->table(),$this->properties);		
		return $this->validate_obligatory();
	}
	function get($id){				
		return $this->persistor->select($this->schema.'.'.$this->table(),"id=$id");
	}
	function getAll(){
		return $this->persistor->select($this->schema.'.'.$this->table());
	}
	function del($id){
		$this->persistor->delete($this->schema.'.'.$this->table(),'id='.$id);
	}	
	function upd($row){
		$this->fill($row);
		if($this->validate_obligatory())
			$this->persistor->update($this->schema.'.'.$this->table(),$this->properties,'id='.$row['id']);
	}
	//guarda el objeto con lo cargado en las properties
	function save(){
		if($this->validate_obligatory()){
			if(isset($this->properties['id'])){					
				$this->persistor->update($this->schema.'.'.$this->table(),$this->properties,'id='.$this->properties['id']);		
			}else{
				$this->persistor->insert($this->schema.'.'.$this->table(),$this->properties);
			}
		}			
	}
	function load($id){		
		$data = $this->get($id);				
		foreach ($data[0] as $key => $value) {
			//if(in_array($key, $this->columns))
			if(in_array($key, $this->getColumns()))
				$this->properties[$key] = $value;
		}
		return $this;
	}
	function fill($row){
		//cargo los campos		
		foreach ($row as $key => $value) {			
			//if(in_array($key, $this->getColumns())){
			if(in_array($key, $this->columns)){			
				$this->properties[$key] = $value;
			}
		}		
	}
	function find($where){
		return $this->persistor->select($this->schema.'.'.$this->table(),$where);
	}
	function table(){
		if(isset($this->table) && !empty($this->table) && $this->table!=""){			
			return $this->table;
		}
		else{
			$path = explode('\\', get_class($this));										//saco el namespace
			$classname = array_pop($path);							
			return strtolower($classname);
		}		
	}
	
	function getColumns(){				
		$datos = (isset($this->columns)&&!empty($this->columns)) ? $this->columns : $this->persistor->getColumns($this->table(),$this->schema);
		return $datos;
	}

	function validate_obligatory(){
		$ok = true;
		foreach ($this->obligatory_columns as $key => $value) {
			if(!in_array($value, array_keys($this->properties))){				
				$ok = false;
			}else{
				if($this->properties[$value]==""){
					$ok = false;
				}
			}
		}
		return $ok;
	}
        
    function maxId(){
        return $this->persistor->maxId($this->table());
    }
}
?>