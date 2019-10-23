<?php  

class LiquidadorNuevo extends Evaluator
{
	protected $id_liquidacion;
	protected $periodo;
	protected $id_persona;							//id del empleado al que se le esta liquidando
	protected $variables_liquidacion = array();		//variables a nivel liquidacion, se usan para todos los empleados
	protected $variables_empleado = array();		//se calculan individualmente por cada empleado.
	protected $acumuladores = array();				//carga los acumuladores con los valores iniciales

	//protected $acumuladores_totalizados = array();	//totaliza los acumuladores de un recibo

	function __construct($id_liquidacion)
	{
		$this->id_liquidacion = $id_liquidacion;
		$this->periodo = $this->get_periodo();										//lo cargo para no hacer la consulta varias veces
		$this->functions = FunctionesLiquidador::get_definicion_funciones($this);	//cargar funciones del liquidador
		$this->onVariable = [$this, 'doVariable'];									//para devolver cero si no existe la variable
		$this->crear_variables_liquidacion($id_liquidacion);
		$this->crear_acumuladores();
		$this->cargar_tabla_ganancias();											//carga la tabla de ganancias del periodo					
	}
	public function doVariable($name, &$value) {
		$value = 0;	//si no existe la variable le clavo un cero para que no tire un exception.(VER SI AFECTA ALGUN CALCULO)
	}

	//limpia las variables del liquidador
	function nuevo_recibo($id_persona){
		$this->cargar_variables_liquidacion();				//tambien inicializa los acumuladores
		$this->cargar_acumuladores();						//se inicializan con su valor inicial
		$this->cargar_variables_empleado($id_persona);		
		$this->id_persona = $id_persona;
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
				if( !($acumulador['remunerativo'] xor $concepto['remunerativo']) ){	//si tienen el mismo valor (No es lo mismo con un igual? GIL)
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

	/* VER SI LOS VALORES DE LAS TABLAS LOS CARGO AL INICIO PARA NO HACER CONSULTAS EN CADA RECIBO */

	//devuelve el valor de la tabla dinamica de deducciones
	function get_valor_tabla($id_tabla){
		$valor = toba::consulta_php('liquidacion')->get_valor_tabla($id_tabla, $this->periodo);
		if(isset($valor) && !empty($valor))
			return $valor;
		else
			throw new Exception('No se definio el valor de la tabla en el perídodo. Tabla : '.$id_tabla);
		
	}
	//devuelve el tope de la tabla dinamica de deducciones
	function get_tope_tabla($id_tabla){
		//return toba::consulta_php('liquidacion')->get_tope_tabla($id_tabla, $this->periodo);	
		$tope = toba::consulta_php('liquidacion')->get_tope_tabla($id_tabla, $this->periodo);		
		if(isset($tope) && !empty($tope))
			return $tope;
		else
			throw new Exception('No se definio el tope de la tabla en el perídodo. Tabla : '.$id_tabla);
	}	
	function get_periodo(){
		return toba::consulta_php('liquidacion')->get_periodo_liquidacion($this->id_liquidacion);
	}

	/* VER SI LO PUEDO CARGAR CON LAS RESERVADA. AUNQUE NO SERIA DINAMICO!!! */
	function get_deduccion_informada($id_tabla){
		return toba::consulta_php('liquidacion')->get_deduccion_informada($id_tabla, $this->periodo, $this->id_persona);
	}

	function cargar_tabla_ganancias(){
		$where = "periodo='{$this->periodo}'";
		$this->tabla_ganancias = toba::consulta_php('liquidacion')->get_tabla_ganancias_detalle($where,"desde asc");
	}
	/* Para evitar consultas traigo la tabla del periodo y realizo los calculos en PHP */
	function ganancias($ganancia_neta_imponible){
		if($ganancia_neta_imponible>0){
			$rango=array();
			Logger::info( "Calculando Ganancias con Ganancia neta imponible = $ganancia_neta_imponible");
			$minimo_imponible = $this->tabla_ganancias[0]['desde'];
			$valor = $ganancia_neta_imponible - $minimo_imponible;

			foreach ($this->tabla_ganancias as $key => $value) {
				if( $valor >= $value['desde'] && $valor <= $value['hasta']){
					$rango = $value;
					Logger::info( 'Rango Ganancias =' . ($key+1) . ' fijo='.$rango['fijo'] .' porcentaje='.$rango['porcentaje']);
					break;
				}
			}				
			
			//calculo con el rango correspondiente			
			return (count($rango)>0) ?  $rango['fijo'] + ( ($valor-$rango['desde']) * ($rango['porcentaje']/100) )  :  0;	
		}else{
			return 0;
		}
					
	}
	function get_variables_json(){
		return json_encode($this->variables);
	}
	//NO FUNCIONA POR QUE PRIMERO HACE EL CALCULO DE LA EXPRESION nombre
	//devuelve 1 si existe la variable en el liquidador
	function existe($nombre,$valor_si_no_existe=null){
		if(is_null($valor_si_no_existe)){
			return (isset($this->variables[$nombre])) ? 1: 0;
		}else{
			return (isset($this->variables[$nombre])) ? $this->variables[$nombre]: $valor_si_no_existe;
		}

	}

	/*Devuelve el valor total haciendo el proceso inverso que se hizo cuando se saco el proporcional*/
	function sin_proporcional($importe_proporcional){
		/*el proporcional se calcula haciendo importe_proporcional=importe_total/30*dias_trabajados 
		despejo el importe_total : importe_total = (importe_proporcional/dias_trabajados)*30*/
		$dias_trabajados = 30-$this->variables['diasvacac'];
		return ($dias_trabajados==0) ? 0 : ($importe_proporcional/$dias_trabajados)*30;
	}
}
