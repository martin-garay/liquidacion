/*
alter table conceptos add column proporcional_vacaciones boolean not null default false;
comment on COLUMN conceptos.proporcional_vacaciones IS 
'Es para calcular el bruto sin proporcional para hacer el calculo de vacaciones. 
Si es true el acumulador aplica la funcion inversa para que el importe sea el total y no el proporcional.';
*/