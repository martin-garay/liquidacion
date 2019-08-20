--2019-08-20
INSERT INTO sistema.reservadas(id, nombre, descripcion, descripcion_larga, query, valor, id_tipo_dato, id_tipo_reservada, defecto)
VALUES (8, 'hsextras', 'Horas ', 'Suma las horas extras del periodo de la liquidacion', 
'select sum(horas_extras) as resultado from fichajes_resumen 
where id_persona = {ID_PERSONA} 
	and periodo=(select periodo from liquidaciones where id={ID_LIQUIDACION})
group by periodo', null, 4, 2, 0);