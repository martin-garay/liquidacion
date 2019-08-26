<?php  

class LiquidadorNuevo extends Evaluator
{
	protected $id_liquidacion;
	protected $variables_liquidacion = array();		//variables a nivel liquidacion, se usan para todos los empleados
	protected $variables_empleado = array();		//se calculan individualmente por cada empleado.
	protected $acumuladores = array();				//carga los acumuladores con los valores iniciales
	//protected $acumuladores_totalizados = array();	//totaliza los acumuladores de un recibo

	function __construct($id_liquidacion)
	{
		$this->id_liquidacion = $id_liquidacion;
		$this->functions = FunctionesLiquidador::get_definicion_funciones();	//cargar funciones del liquidador
		$this->crear_variables_liquidacion($id_liquidacion);
		$this->crear_acumuladores();
	}

	//limpia las variables del liquidador
	function nuevo_recibo($id_persona){
		$this->cargar_variables_liquidacion();				//tambien inicializa los acumuladores
		$this->cargar_acumuladores();						//se inicializan con su valor inicial
		$this->cargar_variables_empleado($id_persona);
	}

	//calcula y guarda el concepto como una nueva variable en el liquidador
	//Si el concepto Totaliza  
	/*function calcular_concepto($codigo, $formula, $id_tipo_concepto, $totaliza){
		$resultado = $this->ejecutar($formula);
		$nombre_variable = 'c'.$codigo;
		$this->agregar_variable($nombre_variable, $resultado);	//agrego el concepto a las variables del liquidador
		return $resultado;
	}*/	
	function calcular_concepto($concepto){
		$resultado = $this->ejecutar($concepto['formula']);
		$nombre_variable = 'c'.$concepto['codigo'];
		$this->agregar_variable($nombre_variable, $resultado);	//agrego el concepto a las variables del liquidador
		$this->actualizar_acumuladores($concepto, $resultado);	//actualiza los acumulares que correspondan
		return $resultado;
	}
	function agregar_variable($variable, $valor){		
		$this->variables = array_merge($this->variables,[ $variable => $valor ]);
	}
	//suma el valor a los totalizadores por tipo_concepto
	function actualizar_acumuladores($concepto, $resultado){
		//$acumuladores_totalizados
		foreach ($this->acumuladores as $key => $acumulador) {
			if( ($acumulador['id_tipo_concepto'] == $concepto['id_tipo_concepto']) && $concepto['totaliza'] ){
				if( !($acumulador['remunerativo'] xor $concepto['remunerativo']) ){	//si tienen el mismo valor
					$this->incrementar_variable($acumulador['nombre'], $resultado);
				}
			}
		}
	}
	function incrementar_variable($nombre, $valor=1){
		$this->variables[$nombre] = $this->variables[$nombre] + $valor; 
	}	
	function ejecutar($formula){
		return $this->execute($formula);
	}
	//las calculo una unica vez al crear el objeto
	function crear_variables_liquidacion(){
		$this->variables_liquidacion = $this->generar_reservadas_liquidacion();
		$this->crear_acumuladores();

	}
	function cargar_variables_liquidacion(){
		$this->variables = $this->variables_liquidacion;		
	}
	function crear_acumuladores(){
		//$this->acumuladores = toba::consulta_php('comunes')->get_generico('acumuladores',$where);
		$this->acumuladores = toba::consulta_php('comunes')->get_generico_sql("SELECT *,id as id_acumulador FROM acumuladores");		
	}
	//carga los acumuladores como variables con los valores iniciales
	function cargar_acumuladores(){
		$nuevas_variables = array();		
		Logger::info('Cargando acumuladores');
		foreach ($this->acumuladores as $key => $acumulador) {
			$nuevas_variables[$acumulador['nombre']] = $acumulador['valor_inicial'];
			Logger::info($acumulador['nombre'].'='.$acumulador['valor_inicial']);
		}
		$this->variables = array_merge($this->variables,$nuevas_variables);		
		//$this->acumuladores_totalizados = $this->$acumuladores;
	}
	function cargar_variables_empleado($id_empleado){
		Logger::info('Creando reservadas empleado '.$id_empleado);
		$reservadas_empleado = $this->generar_reservadas_empleados($id_empleado);
		$this->variables = array_merge($this->variables,$reservadas_empleado);		
		Logger::info('Fin reservadas empleado '.$id_empleado);
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

	//devuelve el valor de los acumuladores luego de ser procesados
	function get_acumuladores_totalizados(){
		Logger::info('Acumuladores totalizados');
		$acumuladores = $this->acumuladores;
		foreach ($acumuladores as $key => $acumulador) {			
			$acumuladores[$key]['importe'] = $this->getVariable($acumulador['nombre']);	//por que nombre esta cargado como una variable
			$acumuladores[$key]['apex_ei_analisis_fila'] = 'A';								//ya se lo doy cocinado al datos tabla

			Logger::info( $acumulador['nombre'] .'='.$acumuladores[$key]['importe'] );
		}
		return $acumuladores;
	}

}
