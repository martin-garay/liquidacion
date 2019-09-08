<?php
class form_liquidacion_js extends asociacion_ei_formulario
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		const meses = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','agosto','Septiembre','Octubre','Noviembre','Diciembre'];

		//---- Procesamiento de EFs --------------------------------
		
		{$this->objeto_js}.evt__mes__procesar = function(es_inicial)
		{
			this.procesar_periodo(es_inicial);
		}
		
		{$this->objeto_js}.evt__anio__procesar = function(es_inicial)
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
					var mes_descripcion = $('#ef_form_18000783_form_liquidacionmes>option:selected').html();					

					//cargo descripcion 
					if(!this.ef('descripcion').tiene_estado()){
						this.ef('descripcion').set_estado('Liquidacion ' + mes_descripcion + ' ' + anio);	
					}
					if(!this.ef('fecha_desde').tiene_estado()){
						var firstDay = new Date(anio, mes, 1);
						this.ef('fecha_desde').set_fecha(firstDay);
					}					
					if(!this.ef('fecha_hasta').tiene_estado()){
						var lastDay = new Date(anio, mes + 1, 0); 	//ver que le paso  mes y no mes-1 por que es el mes siguiente						
						this.ef('fecha_hasta').set_fecha(lastDay);
					}
					// if(!this.ef('fecha_pago').tiene_estado()){
					// 	var firstDayNextMonth = new Date(anio, mes + 1, 1); 	//ver que le paso  mes y no mes-1 por que es el mes siguiente			
					// 	this.ef('fecha_pago').set_fecha(firstDayNextMonth);
					// }
					// if(!this.ef('fecha_deposito').tiene_estado()){
					// 	var firstDayNextMonth = new Date(anio, mes + 1, 1); 	//ver que le paso  mes y no mes-1 por que es el mes siguiente			
					// 	this.ef('fecha_deposito').set_fecha(firstDayNextMonth);
					// }
					if(!this.ef('periodo_depositado').tiene_estado()){
						var mes2 = this.ef('mes').get_estado();						
						if( mes2<10 ){
							mes2 = '0'+mes2;
						}
						this.ef('periodo_depositado').set_estado( mes2 + ' ' + anio );
					}
					
				}
			}
		}
		{$this->objeto_js}.evt__fecha_carga_social__procesar = function(es_inicial)
		{
			if(!es_inicial){
				if(this.ef('fecha_carga_social').tiene_estado()){
					var fecha = this.ef('fecha_carga_social').fecha();
					var nombreMes = meses[fecha.getMonth()];
					this.ef('mes_carga_social').set_estado(nombreMes);
				}				
			}
		}

		";
	}

}
?>