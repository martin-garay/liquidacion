<?php
class form_funciones_js extends asociacion_ei_formulario
{

	function extender_objeto_js(){
		$id_form = $this->get_id_objeto_js();
		$id_lista = $this->ef('lista')->get_id_form();										//Lista: obtengo el id del ef en el html	
		$id_ef_formula = $this->controlador()->dep('form')->ef('formula')->get_id_form();	//TextArea Formula: obtengo el id del ef en el html	
		echo "
		$('#$id_lista').dblclick(
			function(){ 
		 		var reservada = ($(this).find('option:selected').val());

		 		var cursorPos = $('#$id_ef_formula').prop('selectionStart');
			    var v = $('#$id_ef_formula').val();
			    var textBefore = v.substring(0,  cursorPos);
			    var textAfter  = v.substring(cursorPos, v.length);

			    $('#$id_ef_formula').val(textBefore + reservada + textAfter);

		});
		

		//colapso al iniciar
		{$this->objeto_js}.colapsar();

		/*
		$('img[id^=\"colapsar_boton_\"]').on('click',function(){
		//$('.ei-form-barra-sup').on('click',function(){
			
			

			var id_boton_colapsar = $(this).attr('id');
			//console.log(id_boton_colapsar);
			//console.log('colapsar_boton_'+'$id_form');
			if( id_boton_colapsar !== 'colapsar_boton_'+'$id_form'){
				{$this->objeto_js}.colapsar();				
			}else{
				{$this->objeto_js}.descolapsar();
			}
			
		});
		

		{$this->objeto_js}.cambiar_colapsado = function(){
			$('img[id^=\"colapsar_boton_\"]').click();		//oculta todos y muestra el que hizo click
			{$this->objeto_js}.descolapsar();
		}		
		*/
		//colapso los demas formularios

		";
	}
}

?>