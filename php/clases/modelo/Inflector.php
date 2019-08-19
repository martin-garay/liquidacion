<?php 

class Inflector {
    public static function studly($snakedString)
    {
        $array = explode('_', $snakedString);
        $array = array_map('ucfirst', $array);
        return implode('', $array);
    }
}
?>