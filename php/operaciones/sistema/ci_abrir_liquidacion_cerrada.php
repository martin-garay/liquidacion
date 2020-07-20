<?php
class ci_abrir_liquidacion_cerrada extends asociacion_ci
{
	//-----------------------------------------------------------------------------------
	//---- cuadro -----------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function conf__cuadro(asociacion_ei_cuadro $cuadro)
	{
		return toba::consulta_php('liquidacion')->get_liquidaciones('id_estado=3','periodo desc');
	}

	function evt__cuadro__abrir($seleccion)
	{
		toba::db()->consultar("SELECT sp_volver_a_estado_liquidada({$seleccion['id']})");
	}


}
?>