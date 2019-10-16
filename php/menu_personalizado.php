<?php  

$archivo_menu = toba::proyecto()->get_parametro('menu_archivo');
$clase = basename($archivo_menu, ".php");
$menu = new $clase();
var_dump($menu);

?>