<?php  

function si($condicion, $valor_si, $valor_no) {	
	return ( $condicion==1 ) ? $valor_si : $valor_no;
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

$funciones = [
	/* Logicas */
	'si' 			=> 	['ref' => 'si'			, 'arc' => null],
	'igual' 		=> 	['ref' => 'igual'		, 'arc' => null],
	'distinto' 		=> 	['ref' => 'distinto'	, 'arc' => null],
	'mayor' 		=> 	['ref' => 'mayor'		, 'arc' => null],
	'menor' 		=> 	['ref' => 'menor'		, 'arc' => null],
	'mayor_igual'	=> 	['ref' => 'mayor_igual'	, 'arc' => null],
	'menor_igual'	=>	['ref' => 'menor_igual'	, 'arc' => null],
	'y'				=>	['ref' => 'y'			, 'arc' => null],
	'o'				=>	['ref' => 'o'			, 'arc' => null],
	'entre'			=>	['ref' => 'entre'		, 'arc' => null],
	'fuera'			=>	['ref' => 'fuera'		, 'arc' => null],
	'max'			=>	['ref' => 'max'			, 'arc' => null],		//usa la function max de php
	'min'			=>	['ref' => 'min'			, 'arc' => null],		//usa la function min de php
	'redondear'		=>	['ref' => 'redondear'	, 'arc' => null],
];

$conceptos = toba::consulta_php('reservadas')->get_conceptos(null,'codigo asc');
ei_arbol($conceptos);

	
$evaluator = new Evaluator();
$evaluator->functions = $funciones;

$calculadas = toba::consulta_php('reservadas')->generar_reservadas(1,9);
$evaluator->variables = $calculadas; //cargo todas las palabras reservadas

$recibos = array( 1=>'');
//recorro cada recibo de la liquidacion
foreach ($recibos as $key => $recibo) {
	$id_liquidacion=0;
	$id_persona = 0;
	
	foreach ($conceptos as $key => $concepto) {
		
		//calculo el valor de cada concepto
		$valor_concepto = $evaluator->execute( $concepto['formula'] );
		$clave_concepto = 'c'.$concepto['codigo'];

		//agrego el concepto a las variables ya cargadas. Ahora ya lo puedo usar en los siguientes conceptos
		$evaluator->variables = array_merge($evaluator->variables,[ $clave_concepto => $valor_concepto ]);	

		//me guardo un array con los valores fuera de la clase para devolver
		$conceptos_calculados[$clave_concepto] = $valor_concepto;
	}
}

ei_arbol($conceptos_calculados);



//$c = $evaluator->execute('basico');
//echo '<br>'.$c;
// var_dump($c);
 //$evaluator->variables = array_merge($evaluator->variables,['c' => $c]);

 //echo $evaluator->execute('c');

/*
echo $evaluator->execute('si( igual(1,1), -2+1, 3+1)');

echo $evaluator->execute('max(1,2,3)');
echo '<br>';
echo $evaluator->execute('si( igual(max(1,2),2), 10, 20 )');
*/


?>



