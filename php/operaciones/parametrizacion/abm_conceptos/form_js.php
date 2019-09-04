<?php
class form_js extends asociacion_ei_formulario
{
	//-----------------------------------------------------------------------------------
	//---- JAVASCRIPT -------------------------------------------------------------------
	//-----------------------------------------------------------------------------------

	function extender_objeto_js()
	{
		echo "
		//---- Validacion de EFs -----------------------------------
		
		{$this->objeto_js}.evt__formula__validar = function()
		{
			if( this.ef('formula').tiene_estado() ){
				this.ef('formula').set_error('Error!! Verifique los parentesis.');
				return checkBrackets( this.ef('formula').get_estado() );
			}
			return true;		
		}

		function checkBrackets(str){
		    // depth of the parenthesis
		    // ex : ( 1 ( 2 ) ( 2 ( 3 ) ) )
		    var depth = 0;
		    // for each char in the string : 2 cases
		    for(var i in str){   
		        if(str[i] == '('){
		            // if the char is an opening parenthesis then we increase the depth
		            depth ++;
		        } else if(str[i] == ')') {
		            // if the char is an closing parenthesis then we decrease the depth
		            depth --;
		        }  
		        //  if the depth is negative we have a closing parenthesis 
		        //  before any matching opening parenthesis
		        if (depth < 0) return false;
		    }
		    // If the depth is not null then a closing parenthesis is missing
		    if(depth > 0) return false;
		    // OK !
		    return true;
		}

		// var validator = function(string expression) {
		//     count := 0
		//     for(int i = 0; i < expression.length; i++) {
		//         if(expression[i] == '('){		        	
		//             count++;
		//         }
		//         else{
		//         	if(expression[i] == ')'):
		//             if(count == 0):
		//                 return false
		//             else:
		//                 count--	
		//         } 
		//     }

		//     if(count == 0):
		//         return true

		//     return false
		// }
		";
	}

}

?>