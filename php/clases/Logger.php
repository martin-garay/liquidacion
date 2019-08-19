<?php 
class Logger
{
	const INFO 			= '[INFO]';
	const ERROR 		= '[ERROR]';
	const ADVERTENCIA 	= '[ADVERTENCIA]';
	const FATAL 		= '[FATAL]';	
	const SEPARADOR		= ';';

	const LINEA 		= '-------------------------------------------------------------------------';

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
	function separador($titulo_separador=''){
		//$this->grabar($titulo_separador.self::LINEA,self::INFO);
		self::grabar($titulo_separador.self::LINEA,self::INFO);
	}
}

?>