<?php  

/**
* 
*/
class MenuGrilla
{
	protected $id_menu;
	protected  $items;
	protected $columnas=3;
	protected $filas=3;

	function __construct($id_menu)
	{
		$this->id_menu = $id_menu;		
	}
	function cargar_items($items){
		$this->items = $items;
	}
	function dibujar_nodo($key){
		$item = $this->items[$key];
		$popup=false;
		$vinculo = toba::vinculador()->get_url($item['proyecto'], $item['item']);
		$js = "onclick=\"toba.ir_a_operacion('{$item['proyecto']}', '{$item['item']}', '{$popup}', true)\"";
		$html = "<a href='#' $js>";

		if(isset($item['parametro_a'])){
			$html .= toba_recurso::imagen_proyecto($item['parametro_a'],true,null,null,$item['nombre']);
		}else{
			if(  isset($item['imagen_recurso_origen']) && isset($item['imagen']) ){
				if($item['imagen_recurso_origen']=="apex"){				
					$html .= toba_recurso::imagen_toba($item['imagen'],true,null,null,$item['nombre']);
				}elseif($item['imagen_recurso_origen']=="proyecto"){									
					$html .= toba_recurso::imagen_proyecto($item['imagen'],true,null,null,$item['nombre']);
				}else{
					$html .= toba_recurso::imagen_toba("descripcion.gif",true,null,null,$item['nombre']);
				}
			}else{
				$html .= toba_recurso::imagen_toba("descripcion.gif",true,null,null,$item['nombre']);
			}	
		}
		
		$html .= 	"<p>".$item['nombre']."</p>";
		$html .= "</a>";
		
		return $html;
	}
	function dibujar(){
		$hmtl = '';
		$hmtl .= '<table class="tabla_menu">';
		$i = 0;
		for ($f=0; $f < $this->filas ; $f++) { 

			$hmtl .= 	'<tr>';
			for ($c=0; $c < $this->columnas ; $c++) { 
				
				$hmtl .= 	'<td>';
				$hmtl .= (isset($this->items[$i])) ? $this->dibujar_nodo($i) : '&nbsp';
				$hmtl .= 	'</td>';	
				$i++;
			}
			$hmtl .= 	'</tr>';			
		}
		$hmtl .= 	'<table>';
		$hmtl .= '</table>';
		return $hmtl;

	}
}

?>