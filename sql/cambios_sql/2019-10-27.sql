INSERT INTO sistema.reservadas(nombre, descripcion, descripcion_larga, query, valor_fijo, id_tipo_reservada, id_tipo_dato, defecto)
VALUES ('edad', 'Devuelve la edad de la persona', 'Devuelve la edad de la persona', 
'SELECT edad(fecha_nacimiento) as resultado 
FROM personas 
WHERE id={ID_PERSONA};'
, null, 2, 1, null);