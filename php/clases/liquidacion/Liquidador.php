<?php  

/**
* El Liquidador Recibe una lista de objetos Recibo y calcula para cada uno los conceptos
*/
//include_once '../3ros/Matex/Evaluator.php';

class Liquidador extends Evaluator
{
	protected $id_liquidacion;
	protected $conceptos;
	protected $variables_liquidacion;	//variables a nivel liquidacion, se usan para todos los empleados
	protected $variables_empleado;		//se calculan individualmente por cada empleado.
	protected $recibos;					//recibos a liquidar
	

	function __construct($id_liquidacion)
	{
		$this->id_liquidacion = $id_liquidacion;
		Logger::separador('NUEVA LIQUIDACION');		
		$this->functions = FunctionesLiquidador::get_definicion_funciones();	//cargar funciones del liquidador
		$this->crear_variables_liquidacion($id_liquidacion);		
	}

	function cargar_funciones(){

	}
	/* Liquida el recibo del empleado */
	function liquidar($recibos){		
		foreach ($recibos as $key => $recibo) {
			$this->cargar_variables_liquidacion();			
			$this->cargar_variables_empleado($recibo->id_persona);		//se agregan a la de la liquidacion
			$this->calcular_conceptos($recibo);
		}
	}
	function calcular_conceptos($recibo){
		foreach ($recibo->get_conceptos() as $key => $concepto) {
			$resultado = $this->ejecutar($concepto->formula);
			$concepto->importe = $resultado;

			//agrego el concepto a las variables del liquidador
			$this->agregar_variable($concepto->nombre_variable, $resultado);
		}
	}
	function agregar_variable($variable, $valor){
		$this->variables = array_merge($this->variables,[ $variable => $valor ]);
	}

	function ejecutar($formula){
		return $this->execute($formula);
	}
	//las calculo una unica vez al crear el objeto
	function crear_variables_liquidacion(){
		Logger::grabar('Creando Reservadas Liquidacion',Logger::INFO);		
		$this->variables_liquidacion = $this->generar_reservadas_liquidacion();		
		Logger::separador();
	}
	function cargar_variables_liquidacion(){
		$this->variables = $this->variables_liquidacion;		
	}
	function cargar_variables_empleado($id_empleado){
		Logger::grabar('Cargando Reservadas Empleado: '.$id_empleado, Logger::INFO);
		$reservadas_empleado = $this->generar_reservadas_empleados($id_empleado);
		$this->variables = array_merge($this->variables_liquidacion,$reservadas_empleado);		
	}
	function verificar($formula){
		//cargo reservadas y conceptos con valor 1 y ejecuto la formula
		$this->variables = $this->get_variables();
		$this->functions = $this->get_funciones();
	}

	function get_ids_reservadas($where){
		$sql = "SELECT id FROM sistema.reservadas";
		$reservadas = toba::consulta_php('comunes')->get_generico_sql($sql,$where);		
		return array_column($reservadas, 'id');
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
	
}
