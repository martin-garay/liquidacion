<?php
class form_funciones_js extends asociacion_ei_formulario
{

	function extender_objeto_js(){
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

		
		";
	}
}

?>