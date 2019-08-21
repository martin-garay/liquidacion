--2019-08-20
INSERT INTO sistema.reservadas(id, nombre, descripcion, descripcion_larga, query, valor, id_tipo_dato, id_tipo_reservada, defecto)
VALUES (8, 'hsextras', 'Horas ', 'Suma las horas extras del periodo de la liquidacion', 
'select sum(horas_extras) as resultado from fichajes_resumen 
where id_persona = {ID_PERSONA} 
	and periodo=(select periodo from liquidaciones where id={ID_LIQUIDACION})
group by periodo', null, 4, 2, 0);

INSERT INTO sistema.reservadas (id, id_tipo_dato, defecto, nombre, descripcion, descripcion_larga, query, valor, id_tipo_reservada ) 
 VALUES (9,'4', '0', 'bruto', 'BRUTO', 'Este se carga con el mismo valor que el sueldo basico pero el liquidador se encarga de ir sumandole los conceptos que sean de haberes y que tengan el tilde totaliza.
El bruto se puede usar en cualquier momento de la liquidacion, pero  se tiene que tener en cuenta que hasta no termine todo el calculo de haberes este valor puede cambiar', 'SELECT sueldo_basico as resultado FROM personas WHERE id={ID_PERSONA}', DEFAULT, '2'); -- toba_log: 60556

 