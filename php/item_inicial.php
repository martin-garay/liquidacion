<?php
	echo '<div class="logo">';
	echo toba_recurso::imagen_proyecto('logo_grande.gif', true);
	echo '</div>';

	$liquidacion = new Liquidacion(16);
	$liquidacion->liquidar();
	$liquidacion->grabar();
?>