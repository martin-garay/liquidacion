<?php 
include_once 'comunes.php';

class menu extends comunes
{
	function get_menu($id_menu){
		$proyecto = toba::proyecto()->get_id();
		$sql = "SELECT 	
						amo.carpeta,
						amo.proyecto,
						amo.item,
						amo.descripcion as nombre,
						ai.orden as orden,
						ai.imagen,
						ai.imagen_recurso_origen,		
						ai.parametro_a
				FROM apex_menu_operaciones amo 
				JOIN apex_item ai ON ai.item=amo.item 
				WHERE amo.menu_id='$id_menu' and ai.proyecto='$proyecto'";
		try {
			return toba::db('toba')->consultar($sql);
		} catch (toba_error_db $e) {
			throw new toba_error_usuario('Error Interno');
		}
	}
}
?>