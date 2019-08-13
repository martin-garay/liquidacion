<?php
class form_funciones_js extends asociacion_ei_formulario
{

	function extender_objeto_js(){
		$id_lista = $this->ef('lista')->get_id_form();	//obtengo el id del ef en el html		
		echo "
		$('#$id_lista').dblclick(
			function(){ 
		 		var reservada = ($(this).find('option:selected').val());

		 		var cursorPos = $('#ef_form_2845_formformula').prop('selectionStart');
			    var v = $('#ef_form_2845_formformula').val();
			    var textBefore = v.substring(0,  cursorPos);
			    var textAfter  = v.substring(cursorPos, v.length);

			    $('#ef_form_2845_formformula').val(textBefore + reservada + textAfter);

		});
		";
	}
}

?>