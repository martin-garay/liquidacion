<?php 
include_once 'comunes.php';

class combo_editable extends comunes
{
	function get_ciudades($filtro){
        $sql = "SELECT id, nombre||' (CP: '||cp||')' as descripcion 
                FROM localidades WHERE nombre||' (CP: '||cp||')' ILIKE '%$filtro%'";
        return toba::db()->consultar($sql);
	}
	function get_ciudades_descripcion($id_ciudad){
		$sql = "SELECT nombre||' (CP: '||cp||')' as descripcion FROM localidades WHERE id=$id_ciudad";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
	}
	function get_personas($filtro){
		$sql = "SELECT id, nro_documento||' '||apellido||' '||nombre as descripcion
				FROM v_personas WHERE dni||' '||apellido||' '||nombre ILIKE '%$filtro%' 
				ORDER BY apellido,nombre";
		return toba::db()->consultar($sql);
	}
	function get_personas_descripcion($id){
		$sql = "SELECT dni||' '||apellido||' '||nombre as descripcion FROM v_personas WHERE id=$id";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
	}	

}
?>