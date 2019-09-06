<?php
	

	//$liquidacion = new Liquidacion(16);
	//$liquidacion->liquidar();
	//$liquidacion->grabar();

	/*
	$archivo_menu = toba::proyecto()->get_parametro('menu_archivo');
	$clase = basename($archivo_menu, ".php");
	echo $clase;
	$menu = new $clase();
	$menu->set_modo_prueba();
	$datos = array('nombre' => 'ATENCION! Abre popup', 'imagen_recurso_origen' => 'toba', 'imagen' => 'warning.gif', 'js' => 'abrir_popup("goggle", "http://www.google.com")');
	$menu->set_datos_opcion('3520', $datos);
	$menu->mostrar();
	*/
	echo '<div class="logo">';
	echo toba_recurso::imagen_proyecto('logo_grande2.png', true);
	echo '</div>';
	
	// $id_menu = 'test';
	// $items = toba::consulta_php('menu')->get_menu($id_menu);
	// //ei_arbol($items);

	// $menu = new MenuGrilla($id_menu);
	// $menu->cargar_items($items);
	// echo $menu->dibujar();

	
?>