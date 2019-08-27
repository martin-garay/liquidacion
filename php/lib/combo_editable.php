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
		$sql = "SELECT id, legajo||'. '||tipo_documento||' '||nro_documento||' '||apellido||' '||nombre as descripcion
				FROM v_personas WHERE nro_documento||' '||apellido||' '||nombre||' '||legajo ILIKE '%$filtro%' 
				ORDER BY apellido,nombre";
		return toba::db()->consultar($sql);
	}
	function get_personas_descripcion($id){
		$sql = "SELECT legajo||'. '||tipo_documento||' '||nro_documento||' '||apellido||' '||nombre as descripcion FROM v_personas WHERE id=$id";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
	}	
	function get_conceptos($filtro){
        $sql = "SELECT id, codigo||' '||descripcion||' ('||tipo_concepto||')' as descripcion 
                FROM v_conceptos WHERE codigo||' '||descripcion||' ('||tipo_concepto||')' ILIKE '%$filtro%'
                ORDER BY codigo::int";
        return toba::db()->consultar($sql);
	}	
	function get_conceptos_descripcion($id_concepto){
		$sql = "SELECT codigo||' '||descripcion||' ('||tipo_concepto||')' as descripcion FROM v_conceptos WHERE id=$id_concepto";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
	}
	function get_liquidaciones($filtro){
		$sql = "SELECT id, descripcion FROM v_liquidaciones WHERE descripcion ILIKE '%$filtro%'";
        return toba::db()->consultar($sql);
	}	
	function get_liquidaciones_descripcion($id_liquidacion){
		$sql = "SELECT descripcion FROM v_liquidaciones WHERE id=$id_liquidacion";
        $datos = toba::db()->consultar($sql);
        return $datos[0]['descripcion'];
	}
}
?>