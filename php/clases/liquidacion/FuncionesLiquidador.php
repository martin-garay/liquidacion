<?php 

/**
* 
*/
class FunctionesLiquidador
{
	function get_definicion_funciones($liquidador){
		$funciones = [
			/* Logicas */
			'si' 			=> 	['ref' => 'FunctionesLiquidador::si'				, 'arc' => null],
			'igual' 		=> 	['ref' => 'FunctionesLiquidador::igual'				, 'arc' => null],
			'distinto' 		=> 	['ref' => 'FunctionesLiquidador::distinto'			, 'arc' => null],
			'mayor' 		=> 	['ref' => 'FunctionesLiquidador::mayor'				, 'arc' => null],
			'menor' 		=> 	['ref' => 'FunctionesLiquidador::menor'				, 'arc' => null],
			'mayor_igual'	=> 	['ref' => 'FunctionesLiquidador::mayor_igual'		, 'arc' => null],
			'menor_igual'	=>	['ref' => 'FunctionesLiquidador::menor_igual'		, 'arc' => null],
			'y'				=>	['ref' => 'FunctionesLiquidador::y'					, 'arc' => null],
			'o'				=>	['ref' => 'FunctionesLiquidador::o'					, 'arc' => null],
			'entre'			=>	['ref' => 'FunctionesLiquidador::entre'				, 'arc' => null],
			'fuera'			=>	['ref' => 'FunctionesLiquidador::fuera'				, 'arc' => null],
			'max'			=>	['ref' => 'FunctionesLiquidador::max'				, 'arc' => null],		//usa la function max de php
			'min'			=>	['ref' => 'FunctionesLiquidador::min'				, 'arc' => null],		//usa la function min de php
			'redondear'		=>	['ref' => 'FunctionesLiquidador::redondear'			, 'arc' => null],
			'tabla'			=>	['ref' => [$liquidador, 'get_valor_tabla']			, 'arc' => null],		//llama al metodo de la instancia
			'tope'			=>	['ref' => [$liquidador, 'get_valor_toppe']			, 'arc' => null],		//llama al metodo de la instancia
			'informado'		=>	['ref' => [$liquidador,'get_deduccion_informada']	, 'arc' => null],		//llama al metodo de la instancia
			'ganancias'		=>	['ref' => [$liquidador,'ganancias']					, 'arc' => null],		//llama al metodo de la instancia
		];
		return $funciones;
	}
	function si($condicion, $valor_si, $valor_no) {	
		return ( $condicion!=0 ) ? $valor_si : $valor_no;
	}
	function igual($valor1, $valor2){
		return (int)($valor1==$valor2);
	}
	function distinto($valor1,$valor2){
		return (int)($valor1 !== $valor2);
	}
	function mayor($valor1,$valor2){
		return (int)($valor1  > $valor2);
	}
	function menor($valor1,$valor2){
		return (int)($valor1  < $valor2);
	}
	function mayor_igual($valor1,$valor2){
		return (int)($valor1  >= $valor2);
	}
	function menor_igual($valor1,$valor2){
		return (int)($valor1  <= $valor2);
	}
	function y($valor1,$valor2){
		return (int)($valor1 && $valor2);
	}
	function o($valor1,$valor2){
		return (int)($valor1 || $valor2);
	}
	function entre($valor1, $valor_desde, $valor_hasta){
		return (int)($valor1>=$valor_desde && $valor1<=$valor_hasta);
	}
	//not in
	function fuera($valor1, $valor_desde, $valor_hasta){
		return (int)($valor1>=$valor_desde && $valor1<=$valor_hasta);
	}
	function redondear($numero, $decimales=0){
		return round($numero,$$decimales);
	}
	
}