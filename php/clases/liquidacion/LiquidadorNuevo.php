<?php  

class LiquidadorNuevo extends Evaluator
{
	protected $id_liquidacion;
	protected $variables_liquidacion;	//variables a nivel liquidacion, se usan para todos los empleados
	protected $variables_empleado;		//se calculan individualmente por cada empleado.

	function __construct($id_liquidacion)
	{
		$this->id_liquidacion = $id_liquidacion;
		$this->functions = FunctionesLiquidador::get_definicion_funciones();	//cargar funciones del liquidador
		$this->crear_variables_liquidacion($id_liquidacion);		
	}

	//limpia las variables del liquidador
	function nuevo_recibo($id_persona){
		$this->cargar_variables_liquidacion();			
		$this->cargar_variables_empleado($id_persona);
	}

	//calcula y guarda el concepto como una nueva variable en el liquidador
	function calcular_concepto($codigo, $formula){
		$resultado = $this->ejecutar($formula);
		$nombre_variable = 'c'.$codigo;
		$this->agregar_variable($nombre_variable, $resultado);	//agrego el concepto a las variables del liquidador
		//Logger::grabar("Calculo Concepto $nombre_variable=$resultado",Logger::INFO);
		return $resultado;
	}
	function agregar_variable($variable, $valor){
		$this->variables = array_merge($this->variables,[ $variable => $valor ]);
	}	
	function ejecutar($formula){
		return $this->execute($formula);
	}
	//las calculo una unica vez al crear el objeto
	function crear_variables_liquidacion(){
		$this->variables_liquidacion = $this->generar_reservadas_liquidacion();		
	}
	function cargar_variables_liquidacion(){
		$this->variables = $this->variables_liquidacion;		
	}
	function cargar_variables_empleado($id_empleado){
		Logger::grabar('Creando reservadas empleado '.$id_empleado, Logger::INFO);
		$reservadas_empleado = $this->generar_reservadas_empleados($id_empleado);
		$this->variables = array_merge($this->variables_liquidacion,$reservadas_empleado);		
		Logger::grabar('Fin reservadas empleado '.$id_empleado, Logger::INFO);
	}
	
	function generar_reservadas_empleados($id_persona){
		return $this->generar_reservadas($this->id_liquidacion,$id_persona,'id_tipo_reservada=2');
	}
	function generar_reservadas_liquidacion(){		
		return $this->generar_reservadas($this->id_liquidacion,null,'id_tipo_reservada=1');
	}
	function generar_reservadas($id_liquidacion,$id_persona=null,$where=null){		
		$ids_reservadas = $this->get_ids_reservadas($where);
		$calculadas = array();

		foreach ($ids_reservadas as $key => $id) {			
			$reservada = new Reservada($id);
			$reservada->setIdLiquidacion($id_liquidacion);
			$reservada->setIdPersona($id_persona);
			
			$valor = $reservada->calcular_valor();
			$nombre = $reservada->nombre;
			$calculadas[$nombre] = $valor;			
		}		
		return $calculadas;       
	}
	function get_ids_reservadas($where){
		$sql = "SELECT id FROM sistema.reservadas";
		$reservadas = toba::consulta_php('comunes')->get_generico_sql($sql,$where);		
		return array_column($reservadas, 'id');
	}
}
