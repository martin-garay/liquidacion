<?php
class form_js extends asociacion_ei_formulario
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		//---- Procesamiento de EFs --------------------------------
		
		{$this->objeto_js}.evt__anio__procesar = function(es_inicial)
		{
			this.procesar_periodo(es_inicial);
		}
		
		{$this->objeto_js}.evt__mes__procesar = function(es_inicial)
		{
			this.procesar_periodo(es_inicial);
		}

		{$this->objeto_js}.procesar_periodo = function(es_inicial)
		{
			if(!es_inicial){
				if(this.ef('anio').tiene_estado() && this.ef('mes').tiene_estado()){
					var anio = this.ef('anio').get_estado();
					var mes = this.ef('mes').get_estado();
					var mes = mes -1; 								//por que js el rango es de 0..11 y en la app 1..12

					if(!this.ef('fecha_desde').tiene_estado()){
						var firstDay = new Date(anio, mes, 1);
						this.ef('fecha_desde').set_fecha(firstDay);
					}					
					if(!this.ef('fecha_hasta').tiene_estado()){
						var lastDay = new Date(anio, mes + 1, 0); 	//ver que le paso  mes y no mes-1 por que es el mes siguiente						
						this.ef('fecha_hasta').set_fecha(lastDay);
					}										
				}
			}
		}
		";
	}

}

?>