<?php
class form_ml_js extends asociacion_ei_formulario_ml
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{		
		if(!toba::consulta_php('comunes')->navegador_es_IE())
			echo "
			//deshabilito el select del id_tipo_contrato		
				$('select[id$=\"ef_form_2889_form_mlid_tipo_contrato\"]').on('mousedown', function(e) {
					e.preventDefault();
					this.blur();
					window.focus();				
				});			
				//deshabilito el select del id_posicion
				$('select[id$=\"ef_form_2889_form_mlid_tipo_contrato\"]').attr('disabled','disabled');
				
			";

			echo "								
				$('th').css({
					'width':'20px',
					'font-size':'1.1em',
					'font-weight':'bold',
					'text-align':'center'
				});

				//le doy el estilo de excel
				var css = {
				  	'border-bottom': '0px',
					'border-top': '0px',
					'margin-right': '0px',
					'padding': '0px 0px 0px 0px',
					'padding-top': '0px',
					'padding-bottom': '0px',
					'border': '0px !important'
				};
				$('.ei-ml-fila').css(css);
				$('.ei-ml-fila-selec').css(css);
				$('.ei-filtro-fila').css(css);
				$('.ei-filtro-fila-selec').css(css);
				$('select,input').css({'border': '0px !important'});

				//acomodo los tamaños de las celdas
				$('input').attr('size','7');


				//acomodo el tamaño de la pantalla acorde al encabezado
				$('tbody').css('margin-top','200px');


				/*
				//corrijo el tamaño de las celdas del header
				$('.ei-ml-grilla > thead > tr').children().each(function(i, v) {
				    $(v).width($(this).width());
				});
				$('.ei-ml-grilla').width($('.ei-ml-grilla').width());
				//fijo la cabecera
				$('.ei-ml-grilla > thead').css({'position':'fixed'});
				*/

				//deshabilito las flechas izquierda y derecha en los selects
				$('select').on('keydown', function( e ){
				    switch(e.keyCode) { 
				       case 37:
				       case 39:
				           var val = $(this).val();
				           var slt = $(this).one('change', function(){
				               slt.val( val ).change();
				           });
				       break;
				    }
				});

				//navegacion con flechas
				$('.ei-ml-grilla').keydown(function(e){
					//armo el nombre del ml
					var formulario = {$this->objeto_js}['_instancia'];
					formulario = formulario.split('_').slice(-1)[0];					
					//tomo el campo que tiene el foco
					var focused = $(':focus').attr('id');
					var selector_id = '#ID > div';
					var selector_ab = '#ID > td > div';
					switch(e.keyCode){
		    			case 37: //Left
		    				id = $(':focus').closest('td').prev().attr('id');
		    				//esto es para que no puedan modificar el id_posicion
		    				if(id.indexOf('ef_form_9000059_form_mlid_posicion') == -1){
		    					//fix para los ef_fijo
								if(id.indexOf('ant') != -1){
									anterior = $(':focus').closest('td').prev().prev().attr('id');
									if(anterior != null){
										id = anterior;
									}
								}
								cambio = selector_id.replace('ID',id);
								$(cambio).children().focus();
		    				}
		    				break;
						case 38: //Up
							id_tr = $(':focus').closest('tr').prev().attr('id');
							//fix para los cortes de control
							if(id_tr == null){
								anterior = $(':focus').closest('tr').prev().prev().attr('id');
								if(anterior != null){
									id_tr = anterior;
								}
							}
							cambio = selector_ab.replace('ID',id_tr);
							campo = focused.split(formulario).slice(-1)[0];
							var find = 'input[id$=\"'+campo+'\"]';
							$(cambio).find(find).focus();

							//selecciono la fila a la que me muevo 

							//fila_nueva = id_tr.replace('js_form_9000059_form_ml_fila','');
							var nombre_fila = {$this->objeto_js}['_instancia'] + '_fila';
							var fila_nueva = id_tr.replace(nombre_fila,'');													
							{$this->objeto_js}.seleccionar(fila_nueva);
							break;
						case 39: //Right
							id = $(':focus').closest('td').next().attr('id');
							//fix para los ef_fijo
							if(id.indexOf('ant') != -1){
								siguiente = $(':focus').closest('td').next().next().attr('id');
								if(siguiente != null){
									id = siguiente;
								}
							}
							cambio = selector_id.replace('ID',id);
							$(cambio).children().focus();
							break;
						case 40: //Down
							id_tr = $(':focus').closest('tr').next().attr('id');							
							//fix para los cortes de control
							if(id_tr == null){
								siguiente = $(':focus').closest('tr').next().next().attr('id');
								if(siguiente != null){
									id_tr = siguiente;
								}
							}
							cambio = selector_ab.replace('ID',id_tr);
							campo = focused.split(formulario).slice(-1)[0];
							var find = 'input[id$=\"'+campo+'\"]';
							$(cambio).find(find).focus();

							//selecciono la fila a la que me muevo 
							var nombre_fila = {$this->objeto_js}['_instancia'] + '_fila';							
							//fila_nueva = id_tr.replace('js_form_9000059_form_ml_fila','');
							var fila_nueva = id_tr.replace(nombre_fila,'');														
							{$this->objeto_js}.seleccionar(fila_nueva);
							break;
				    }
				});
	                        
	            $('.ef_fijo_moneda').each(function(){
	                if( $(this).text().length!==0 ){
	                    $(this).text(  currency( $(this).text() )  );                                
	                }
	            });
	            
	            function currency(value, decimals, separators) {
	                decimals = decimals >= 0 ? parseInt(decimals, 0) : 2;
	                separators = separators || ['.', \"'\", ','];
	                var number = (parseFloat(value) || 0).toFixed(decimals);
	                if (number.length <= (4 + decimals))
	                    return number.replace('.', separators[separators.length - 1]);
	                var parts = number.split(/[-.]/);
	                value = parts[parts.length > 1 ? parts.length - 2 : 0];
	                var result = value.substr(value.length - 3, 3) + (parts.length > 1 ?
	                    separators[separators.length - 1] + parts[parts.length - 1] : '');
	                var start = value.length - 6;
	                var idx = 0;
	                while (start > -3) {
	                    result = (start > 0 ? value.substr(start, 3) : value.substr(0, 3 + start))
	                        + separators[idx] + result;
	                    idx = (++idx) % 2;
	                    start -= 3;
	                }
	                return (parts.length == 3 ? '-' : '') + result;
	            }
			";
	}
}
?>