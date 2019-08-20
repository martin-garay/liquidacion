<?php 
class Logger
{
	const INFO 			= '[INFO]';
	const ERROR 		= '[ERROR]';
	const ADVERTENCIA 	= '[ADVERTENCIA]';
	const FATAL 		= '[FATAL]';	
	const SEPARADOR		= ';';

	const LINEA 		= '-------------------------------------------------------------------------';
	const CENTRADO		= STR_PAD_BOTH;
	const IZQUIERDA		= STR_PAD_RIGHT;
	const DERECHA		= STR_PAD_LEFT;

	//private $filename;

	// function __construct($filename){
	// 	$this->filename = $filename;
	// }

	function grabar($text, $level=self::ERROR){
		$archivo_log = toba::proyecto()->get_path() . '/log/liquidacion.txt';
		$file=fopen($archivo_log,'ab'); //creación o apertura del archivo log
		//$file=fopen($this->filename,'ab'); //creación o apertura del archivo log
		if (!($file))
			 throw new toba_error('No se pudo abrir el archivo de Logs');			 	
		$date = date("Y-m-d H:i:s");
		$ip=$_SERVER['REMOTE_ADDR'];
		$row = $ip . self::SEPARADOR . $date . self::SEPARADOR . $text ."\n";
		$save= fwrite($file,$row); //grabación del archivo log
		if (!($save))
			 throw new toba_error('No se pudo grabar el registro');			 	
		fclose($file);
	}
	function info($text){
		self::grabar($text,self::INFO);
	}
	function error($text){
		self::grabar($text,self::ERROR);
	}
	function advertencia($text){
		self::grabar($text,self::ADVERTENCIA);
	}
	function fatal($text){
		self::grabar($text,self::FATAL);
	}
	function separador($titulo_separador='',$caracter='-',$largo=60,$posicion_titulo=self::DERECHA){
		//$this->grabar($titulo_separador.self::LINEA,self::INFO);		
		$separador = str_pad($titulo_separador, $largo, $caracter, $posicion_titulo);		
		self::info($separador);

	}
	function linea($caracter='-',$largo=70){		
		$linea = str_pad('', $largo, $caracter, STR_PAD_LEFT);		
		self::info($linea);
	}
	function titulo($titulo, $caracter='*',$largo=70, $posicion=self::CENTRADO){
		self::linea($caracter,$largo);
		$titulo = str_pad($titulo, $largo, $caracter, $posicion);
		self::grabar($titulo);
		self::linea($caracter,$largo);
	}
	function subtitulo($subtitulo, $caracter='-',$largo=60, $posicion=self::CENTRADO){
		self::linea($caracter,$largo);		
		$subtitulo = str_pad($subtitulo, $largo, $caracter, $posicion);
		self::grabar($subtitulo);
		self::linea($caracter,$largo);
	}
}

?>