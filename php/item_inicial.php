<?php
	echo '<div class="logo">';
	echo toba_recurso::imagen_proyecto('logo_grande.gif', true);
	echo '</div>';

	$calculadas = toba::consulta_php('reservadas')->generar_reservadas(1,1);
	ei_arbol($calculadas);
?>